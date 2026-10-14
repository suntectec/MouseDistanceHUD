extends Control
## 悬浮拳击训练 HUD：像素拳击手在街道上训练
##   鼠标移动 → 拳击手始终向右奔跑（轨迹长度即里程，不分方向），楼房/路面视差向左卷动
##   敲键盘 → 每次敲击出一拳，左拳右拳交替，punch 计数 +1
##   无操作 → 抱架站姿待机
## 按住画面拖动窗口；右上角"清零"归零，"×"退出；punch 依赖 keyhook.exe

const BoxerArt = preload("res://scripts/boxer_art.gd")
const HOOK_EXE := "keyhook.exe"

const SCALE := 2
const WIN_W := 336
const WIN_H := 72
const TILE_W := 256            # 卷动层贴图宽度（128 场景像素 × 2）
const BOXER_POS := Vector2(36, 10)
const STREET_LINE_Y := 44      # 街道线（2x 后）
const PUNCH_TIME := 0.13       # 每拳动画时长（秒）
const RUN_STRIDE_PX := 5.0     # 鼠标每移动多少像素切换一次跑步帧
const IDLE_MS := 350           # 鼠标停止多久回到抱架
const CHIP_RIGHT := 33         # 统计面板右边缘距窗口右边的间距

var total_px := 0.0
var punches := 0

var _last_mouse := Vector2.ZERO
var _last_move_ms := 0
var _dragging := false
var _drag_win_origin := Vector2.ZERO
var _drag_mouse_origin := Vector2.ZERO

var _udp: PacketPeerUDP

var _frames := {}
var _boxer: TextureRect
var _building_tiles: Array = []
var _road_tiles: Array = []
var _building_off := 0.0
var _road_off := 0.0
var _punch_left := false
var _punch_timer := 0.0
var _run_stride := 0.0
var _run_frame_a := true

var _label: Label
var _sub_label: Label
var _chip: PanelContainer
var _font: SystemFont


func _ready() -> void:
	get_viewport().transparent_bg = true
	DisplayServer.window_set_size(Vector2i(WIN_W, WIN_H))
	var screen := DisplayServer.get_primary_screen()
	var screen_pos := DisplayServer.screen_get_position(screen)
	var screen_size := DisplayServer.screen_get_size(screen)
	DisplayServer.window_set_position(screen_pos + screen_size - Vector2i(WIN_W + 16, WIN_H + 16))

	_font = SystemFont.new()
	_font.font_names = PackedStringArray([
		"Microsoft YaHei UI", "Microsoft YaHei", "SimHei", "Arial",
	])

	_build_frames()
	_build_scene()
	_build_chip()
	_start_hook()

	_last_mouse = Vector2(DisplayServer.mouse_get_position())
	if OS.get_environment("HUD_SCREENSHOT") != "":
		_debug_screenshot()


func _build_frames() -> void:
	for pair in [["guard", BoxerArt.LEGS_GUARD], ["run_a", BoxerArt.LEGS_RUN_A], ["run_b", BoxerArt.LEGS_RUN_B]]:
		_frames[pair[0]] = ImageTexture.create_from_image(BoxerArt.make_frame(pair[1]))
	_frames["punch_a"] = ImageTexture.create_from_image(BoxerArt.make_punch_a())
	_frames["punch_b"] = ImageTexture.create_from_image(BoxerArt.make_punch_b())


func _make_rect(tex: Texture2D, pos: Vector2, size: Vector2) -> TextureRect:
	var tr := TextureRect.new()
	tr.texture = tex
	tr.position = pos
	tr.size = size
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return tr


func _build_scene() -> void:
	add_child(_make_rect(ImageTexture.create_from_image(BoxerArt.build_sky(WIN_W / SCALE)), Vector2.ZERO, Vector2(WIN_W, WIN_H)))
	var b_tex := ImageTexture.create_from_image(BoxerArt.build_buildings())
	var r_tex := ImageTexture.create_from_image(BoxerArt.build_road())
	for i in 3:
		var b := _make_rect(b_tex, Vector2(i * TILE_W, 0), Vector2(TILE_W, WIN_H))
		var r := _make_rect(r_tex, Vector2(i * TILE_W, 0), Vector2(TILE_W, WIN_H))
		_building_tiles.append(b)
		add_child(b)
		_road_tiles.append(r)
		add_child(r)

	var shadow := ColorRect.new()
	shadow.color = Color(0.05, 0.05, 0.08, 0.4)
	shadow.position = Vector2(BOXER_POS.x + 1, STREET_LINE_Y + 1)
	shadow.size = Vector2(30, 2)
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shadow)

	_boxer = _make_rect(_frames["guard"], BOXER_POS, Vector2(32, 36))
	add_child(_boxer)

	# 全窗口拖动层（统计面板在其上方，不影响按钮点击）
	var drag := Control.new()
	drag.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	drag.mouse_default_cursor_shape = Control.CURSOR_MOVE
	drag.gui_input.connect(_on_drag_input)
	add_child(drag)


func _build_chip() -> void:
	var chip := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.09, 0.13, 0.78)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 10.0
	sb.content_margin_right = 8.0
	sb.content_margin_top = 4.0
	sb.content_margin_bottom = 4.0
	chip.add_theme_stylebox_override("panel", sb)
	chip.position = Vector2(146, 4)
	chip.gui_input.connect(_on_drag_input)
	_chip = chip

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	chip.add_child(hbox)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 0)
	hbox.add_child(vbox)

	_label = Label.new()
	_label.text = "0.0 cm"
	_label.add_theme_font_override("font", _font)
	_label.add_theme_font_size_override("font_size", 14)
	_label.add_theme_color_override("font_color", Color(0.93, 0.96, 1.0))
	vbox.add_child(_label)

	_sub_label = Label.new()
	_sub_label.text = "0 px · punches 0"
	_sub_label.add_theme_font_override("font", _font)
	_sub_label.add_theme_font_size_override("font_size", 10)
	_sub_label.add_theme_color_override("font_color", Color(0.72, 0.78, 0.9))
	vbox.add_child(_sub_label)

	hbox.add_child(_make_button("清零", _on_reset))
	hbox.add_child(_make_button("×", func() -> void: get_tree().quit()))
	add_child(chip)


func _make_button(text: String, handler: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_override("font", _font)
	b.add_theme_font_size_override("font_size", 12)
	b.add_theme_color_override("font_color", Color(0.72, 0.80, 0.95))
	b.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	b.add_theme_color_override("font_pressed_color", Color(1, 1, 1))
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(handler)
	return b


func _start_hook() -> void:
	_udp = PacketPeerUDP.new()
	# 端口交给系统分配：写死端口会撞上 Windows 的保留区间（netsh int ipv4 show excludedportrange protocol=udp）
	if _udp.bind(0) != OK:
		_udp = null
		push_warning("无法分配 UDP 端口，punch 计数不可用")
		return
	var exe := ProjectSettings.globalize_path("res://" + HOOK_EXE)
	if FileAccess.file_exists(exe):
		# 传入端口和自己的 PID，keyhook 在 HUD 退出后自动跟随退出
		OS.create_process(exe, [str(_udp.get_local_port()), str(OS.get_process_id())])


func _process(delta: float) -> void:
	var now := Time.get_ticks_msec()
	# 键盘敲击 → 出拳（左右交替）
	if _udp != null:
		while _udp.get_available_packet_count() > 0:
			_udp.get_packet()
			punches += 1
			_punch_left = not _punch_left
			_punch_timer = PUNCH_TIME

	# 鼠标移动 → 距离累计 + 奔跑卷动
	var mouse := Vector2(DisplayServer.mouse_get_position())
	var d := mouse - _last_mouse
	_last_mouse = mouse
	total_px += d.length()
	if d.length() > 0.5:
		_last_move_ms = now

	if _punch_timer <= 0.0:
		_scroll(-d.length() / SCALE)
		_run_stride += d.length()
		if _run_stride >= RUN_STRIDE_PX:
			_run_stride = 0.0
			_run_frame_a = not _run_frame_a

	# 状态机选帧：出拳 > 奔跑 > 抱架
	var frame := "guard"
	if _punch_timer > 0.0:
		frame = "punch_b" if _punch_left else "punch_a"
		_punch_timer -= delta
	elif now - _last_move_ms < IDLE_MS:
		frame = "run_a" if _run_frame_a else "run_b"
	_boxer.texture = _frames[frame]
	_boxer.position.y = BOXER_POS.y - (2.0 if frame == "run_b" else 0.0)

	_label.text = _format_distance(total_px)
	_sub_label.text = "%d px · punches %d" % [int(total_px), punches]
	_layout_chip()


func _layout_chip() -> void:
	# 面板随文字变长自动增宽，这里钉住右边缘让它向左长，
	# 否则大里程数会把「清零」「×」挤出 336 px 宽的窗口
	_chip.reset_size()
	var x := float(WIN_W - CHIP_RIGHT) - _chip.size.x
	if not is_equal_approx(x, _chip.position.x):
		_chip.position.x = x


func _scroll(scene_dx: float) -> void:
	# 拳击手向右跑 → 世界向左卷；楼房慢速、路面全速（视差）
	_building_off = fposmod(_building_off + scene_dx * 0.25, float(TILE_W))
	_road_off = fposmod(_road_off + scene_dx, float(TILE_W))
	for i in 3:
		_building_tiles[i].position.x = _building_off - TILE_W + i * TILE_W
		_road_tiles[i].position.x = _road_off - TILE_W + i * TILE_W


func _on_drag_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			_dragging = mb.pressed
			if _dragging:
				_drag_win_origin = Vector2(DisplayServer.window_get_position())
				_drag_mouse_origin = Vector2(DisplayServer.mouse_get_position())
	elif event is InputEventMouseMotion and _dragging:
		var target := _drag_win_origin + (Vector2(DisplayServer.mouse_get_position()) - _drag_mouse_origin)
		DisplayServer.window_set_position(Vector2i(target))


func _on_reset() -> void:
	total_px = 0.0
	punches = 0
	_last_mouse = Vector2(DisplayServer.mouse_get_position())


func _format_distance(px: float) -> String:
	var cm := px * 2.54 / _screen_dpi()
	if cm < 100.0:
		return "%.1f cm" % cm
	elif cm < 100000.0:
		return "%.2f m" % (cm / 100.0)
	return "%.2f km" % (cm / 100000.0)


func _screen_dpi() -> float:
	var mouse := DisplayServer.mouse_get_position()
	var screen := DisplayServer.get_primary_screen()
	for i in DisplayServer.get_screen_count():
		var rect := Rect2(DisplayServer.screen_get_position(i), DisplayServer.screen_get_size(i))
		if rect.has_point(Vector2(mouse)):
			screen = i
			break
	var dpi := DisplayServer.screen_get_dpi(screen)
	return float(dpi) if dpi > 0 else 96.0


func _debug_screenshot() -> void:
	var delay := float(OS.get_environment("HUD_SCREENSHOT_DELAY"))
	if delay <= 0.0:
		delay = 1.5
	await get_tree().create_timer(delay).timeout
	var img := get_viewport().get_texture().get_image()
	img.save_png(OS.get_environment("HUD_SCREENSHOT"))
	get_tree().quit()
