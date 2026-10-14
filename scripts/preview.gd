extends Control
# Art preview: street scene on top, the boxer's 5 pose frames below (guard / run A / run B / red glove / dark glove)

const BoxerArt = preload("res://scripts/boxer_art.gd")
const SCENE_SCALE := 10
const FRAME_SCALE := 3


func _ready() -> void:
	var size := Vector2i(660, 480)
	DisplayServer.window_set_size(size)
	var screen := DisplayServer.get_primary_screen()
	DisplayServer.window_set_position(
		DisplayServer.screen_get_position(screen) + (DisplayServer.screen_get_size(screen) - size) / 2
	)

	var scene := TextureRect.new()
	scene.texture = ImageTexture.create_from_image(BoxerArt.build_scene())
	scene.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	scene.position = Vector2(10, 10)
	scene.size = Vector2(64 * SCENE_SCALE, 36 * SCENE_SCALE)
	add_child(scene)

	var frames := [
		BoxerArt.make_frame(BoxerArt.LEGS_GUARD),
		BoxerArt.make_frame(BoxerArt.LEGS_RUN_A),
		BoxerArt.make_frame(BoxerArt.LEGS_RUN_B),
		BoxerArt.make_punch_a(),
		BoxerArt.make_punch_b(),
	]
	for i in frames.size():
		var tr := TextureRect.new()
		tr.texture = ImageTexture.create_from_image(frames[i])
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tr.position = Vector2(10 + i * 130, 390)
		tr.size = Vector2(16 * FRAME_SCALE, 18 * FRAME_SCALE)
		add_child(tr)

	if OS.get_environment("HUD_SCREENSHOT") != "":
		_debug_screenshot()


func _debug_screenshot() -> void:
	await get_tree().create_timer(1.2).timeout
	var img := get_viewport().get_texture().get_image()
	img.save_png(OS.get_environment("HUD_SCREENSHOT"))
	get_tree().quit()
