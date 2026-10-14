# Pixel art data: boxer pose frames + layered street scene (seamless horizontal scrolling)
# Palette char -> color; each boxer frame is 16x18; scene height 36, street line at y=22

const PALETTE := {
	"k": Color("1a1a22"),  # outline
	"h": Color("4a3123"),  # hair
	"s": Color("eab586"),  # skin
	"t": Color("cf9468"),  # skin shadow
	"g": Color("e04a3f"),  # glove
	"d": Color("b23228"),  # glove shadow / rear hand
	"w": Color("f7f7f7"),  # highlight
	"b": Color("3b6ee0"),  # shorts
	"o": Color("e8e4da"),  # boots
}

const SCENE_H := 36
const SCENE_W := 64
const STREET_Y := 22

# Upper body (head / gloves / torso / shorts, rows 0-13), side view facing right, both hands guarding
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

# Lower body (rows 14-17): stance / running stride / running recovery
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

# Red lead straight: rows 5-9 (glove extended forward, rear hand guarding)
const PUNCH_A_MID := [
	"..khssssss..kkkk",
	"....kkkkksskgggk",
	"......dddkkkgggk",
	"......dddkkkkkkk",
	"..ksssddkk......",
]

# Dark rear heavy: rows 7-10 (glove lowered to body height, lead hand still guarding)
const PUNCH_B_MID := [
	"......ssskgwgk..",
	"......ssskgggk..",
	"..kssssssttkdddk",
	"..ksssssskkkkkkk",
]


static func _rows_to_image(rows: Array) -> Image:
	assert(rows.size() == 18, "boxer frame must be 18 rows")
	var img := Image.create(16, 18, false, Image.FORMAT_RGBA8)
	for y in rows.size():
		var row: String = rows[y]
		assert(row.length() == 16, "boxer pixel row must be 16 wide")
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


# Sky (width w, rows 0-21 only; below row 22 it is transparent and the road covers it)
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


# Building silhouette layer, 128 wide (two 64 tiles, seamless join)
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


# Road layer (street line + asphalt + dashes), 128 wide seamless
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


# 64-wide static preview scene (used by the old preview)
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
