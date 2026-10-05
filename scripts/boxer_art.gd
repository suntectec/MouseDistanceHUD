# 像素美术数据：拳击手各姿态帧 + 分层街道场景（可横向无缝卷动）
# 调色板字符 → 颜色；拳击手每帧 16x18；场景高度 36，街道线在 y=22

const PALETTE := {
	"k": Color("1a1a22"),  # 描边
	"h": Color("4a3123"),  # 头发
	"s": Color("eab586"),  # 皮肤
	"t": Color("cf9468"),  # 皮肤阴影
	"g": Color("e04a3f"),  # 拳套
	"d": Color("b23228"),  # 拳套暗部/后手
	"w": Color("f7f7f7"),  # 高光
	"b": Color("3b6ee0"),  # 短裤
	"o": Color("e8e4da"),  # 拳靴
}

const SCENE_H := 36
const SCENE_W := 64
const STREET_Y := 22

# 上半身（头/拳套/躯干/短裤，行 0-13），侧面朝右、双手护脸
const UPPER_GUARD := [
	"....kkkkk.......",
	"...khhhhhk......",
	"..khhhhhhhk.....",
	"..khhsssssk.....",
	"..khssssksks....",
	"..khsssssskkkk..",
	"....kkkkkkgggk..",
	"......dddkgwgk..",
	"......dddkgggk..",
	"..ksssddkkkkk...",
	"..kssssssk......",
	"..kttttttk......",
	"...kkkkkk.......",
	".kbbbbbbbk......",
]

# 下半身（行 14-17）：站姿 / 跑步迈步 / 跑步收步
const LEGS_GUARD := [
	".kbbk..kbbk.....",
	".kbbk..kbbk.....",
	".koook.kooook...",
	".kkkkk.kkkkkk...",
]
const LEGS_RUN_A := [
	"kbbk......kbbk..",
	"kbbk......kbbk..",
	"koook....kooook.",
	"kkkkk....kkkkkk.",
]
const LEGS_RUN_B := [
	"....kbbk........",
	"....kbbk........",
	"....koook.......",
	"....kkkkk.......",
]

# 红拳前手直拳：行 5-9（拳套伸向前方，后手护脸）
const PUNCH_A_MID := [
	"..khssssss..kkkk",
	"....kkkkksskgggk",
	"......dddkkkgggk",
	"......dddkkkkkkk",
	"..ksssddkk......",
]

# 黑拳后手重拳：行 7-10（拳套压低打向身体高度，前手仍护脸）
const PUNCH_B_MID := [
	"......ssskgwgk..",
	"......ssskgggk..",
	"..kssssssttkdddk",
	"..ksssssskkkkkkk",
]


static func _rows_to_image(rows: Array) -> Image:
	assert(rows.size() == 18, "拳击手帧必须为 18 行")
	var img := Image.create(16, 18, false, Image.FORMAT_RGBA8)
	for y in rows.size():
		var row: String = rows[y]
		assert(row.length() == 16, "拳击手像素行宽度必须为 16")
		for x in 16:
			var ch := row[x]
			if ch != ".":
				img.set_pixel(x, y, PALETTE[ch])
	return img


static func make_frame(legs: Array) -> Image:
	return _rows_to_image(UPPER_GUARD + legs)


static func make_punch_a() -> Image:
	return _rows_to_image(UPPER_GUARD.slice(0, 5) + PUNCH_A_MID + UPPER_GUARD.slice(10, 14) + LEGS_GUARD)


static func make_punch_b() -> Image:
	return _rows_to_image(UPPER_GUARD.slice(0, 7) + PUNCH_B_MID + UPPER_GUARD.slice(11, 14) + LEGS_GUARD)


# 天空（宽 w，仅 0-21 行，22 行以下透明由路面覆盖）
static func build_sky(w: int) -> Image:
	var img := Image.create(w, SCENE_H, false, Image.FORMAT_RGBA8)
	var c_top := Color("1b2340")
	var c_bot := Color("c76b4a")
	for y in STREET_Y:
		var c := c_top.lerp(c_bot, float(y) / float(STREET_Y - 1))
		for x in w:
			img.set_pixel(x, y, c)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 18:
		img.set_pixel(rng.randi_range(1, w - 2), rng.randi_range(0, 7), Color("dfe4ff"))
	for p in [Vector2i(w - 13, 1), Vector2i(w - 12, 1), Vector2i(w - 14, 2), Vector2i(w - 13, 2), Vector2i(w - 12, 2), Vector2i(w - 11, 2), Vector2i(w - 13, 3), Vector2i(w - 12, 3)]:
		img.set_pixel(p.x, p.y, Color("e8ecff"))
	return img


# 楼房剪影层，128 宽（两个 64 平铺单元，接缝无缝）
static func build_buildings() -> Image:
	var img := Image.create(128, SCENE_H, false, Image.FORMAT_RGBA8)
	for off in [0, 64]:
		var rng := RandomNumberGenerator.new()
		rng.seed = 7
		for b in [[1, 11, 4], [13, 9, 7], [23, 12, 3], [37, 9, 6], [48, 13, 4]]:
			for x in range(b[0] + off, b[0] + off + b[1]):
				for y in range(b[2], STREET_Y):
					img.set_pixel(x, y, Color("20263c"))
			for wx in range(b[0] + off + 1, b[0] + off + b[1] - 1, 3):
				for wy in range(b[2] + 2, STREET_Y - 1, 3):
					if rng.randf() < 0.45:
						img.set_pixel(wx, wy, Color("ffd97a"))
	return img


# 路面层（街道线 + 沥青 + 虚线），128 宽无缝
static func build_road() -> Image:
	var img := Image.create(128, SCENE_H, false, Image.FORMAT_RGBA8)
	for off in [0, 64]:
		for x in 64:
			img.set_pixel(off + x, STREET_Y, Color("9aa3b8"))
			for y in range(STREET_Y + 1, SCENE_H):
				img.set_pixel(off + x, y, Color("262630"))
		var dx := 3
		while dx < 58:
			for i in 5:
				img.set_pixel(off + dx + i, 27, Color("c9c9d4"))
			dx += 9
	return img


static func stamp(img: Image, frame: Image, ox: int, oy: int) -> void:
	img.blend_rect(frame, Rect2i(0, 0, 16, 18), Vector2i(ox, oy))


# 64 宽静态预览场景（旧预览用）
static func build_scene() -> Image:
	var img := Image.create(SCENE_W, SCENE_H, false, Image.FORMAT_RGBA8)
	img.blend_rect(build_sky(SCENE_W), Rect2i(0, 0, SCENE_W, SCENE_H), Vector2i.ZERO)
	var bld := build_buildings().get_region(Rect2i(0, 0, 64, SCENE_H))
	img.blend_rect(bld, Rect2i(0, 0, 64, SCENE_H), Vector2i.ZERO)
	var road := build_road().get_region(Rect2i(0, 0, 64, SCENE_H))
	img.blend_rect(road, Rect2i(0, 0, 64, SCENE_H), Vector2i.ZERO)
	for x in range(25, 42):
		img.set_pixel(x, STREET_Y, Color("565b6e"))
	stamp(img, make_frame(LEGS_GUARD), 25, STREET_Y - 17)
	return img
