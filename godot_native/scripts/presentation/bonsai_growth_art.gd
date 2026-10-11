extends RefCounted
## Lossless runtime crops from the recovered, approved 6x4 opening atlas.
## The source PNGs stay unchanged. Original bloom is the exact resting endpoint.
const POT_REGION := Rect2i(280, 930, 370, 360)
const ATLAS_PATH := "res://assets/native/bonsai/flower_opening_24.png"
const BACKING_PATH := "res://assets/native/bonsai/flower_clean_backing.png"
const CLOSED_PATH := "res://assets/native/bonsai/flower_closed_reference.png"
const BLOOM_PATH := "res://assets/ui/bonsai_bloom.png"
const REGIONS := [Rect2i(388, 437, 225, 159), Rect2i(232, 557, 190, 180), Rect2i(586, 665, 160, 169), Rect2i(365, 704, 210, 187)]
const ANCHORS := [Vector2(497, 587), Vector2(338, 713), Vector2(654, 817), Vector2(473, 875)]
const ANGLES := [0.0, -0.30, 0.32, 0.0]
const SCALES := [1.10, 0.94, 0.83, 1.04]
const FRAME_RECT := Rect2i(45, 20, 208, 164)
const FRAME_ANCHOR := Vector2(143, 160) - Vector2(45, 20)
const CLOSED_RECT := Rect2i(441, 516, 115, 122)
const CLOSED_ANCHOR := Vector2(56, 109)
static var frames: Array[Texture2D] = []
static var closed_frame: Texture2D
static var endpoint_parts: Array[Texture2D] = []
static var clean_plate: Texture2D
static var source_bloom: Texture2D
static var source_bud: Texture2D
static var bloom_background: Texture2D
static var bud_background: Texture2D
static var bloom_pot: Texture2D
static var bud_pot: Texture2D

static func purple(color: Color) -> bool:
	return color.b - color.g > 0.025 and color.r - color.g > 0.01

static func petal_mask(image: Image) -> PackedByteArray:
	var w := image.get_width(); var h := image.get_height()
	var mask := PackedByteArray(); mask.resize(w * h)
	for y in range(h):
		for x in range(w):
			if purple(image.get_pixel(x, y)): mask[y * w + x] = 1
	# The supplied sheet is a scene crop, not a transparent sprite atlas. Ignore
	# the neighboring flower/bud pieces in the corners of each cell. Only the
	# largest connected purple component is the central animated corolla.
	var seen := PackedByteArray(); seen.resize(w * h)
	var largest := PackedInt32Array()
	for seed in range(w * h):
		if mask[seed] == 0 or seen[seed] == 1: continue
		var component := PackedInt32Array([seed]); seen[seed] = 1
		var cursor := 0
		while cursor < component.size():
			var i := component[cursor]; cursor += 1
			var x := i % w; var y := i / w
			for next in [i - 1 if x > 0 else -1, i + 1 if x < w - 1 else -1, i - w if y > 0 else -1, i + w if y < h - 1 else -1]:
				if next >= 0 and mask[next] == 1 and seen[next] == 0:
					seen[next] = 1; component.append(next)
		if component.size() > largest.size(): largest = component
	mask.fill(0)
	for i in largest: mask[i] = 1
	# Fill enclosed stamens, keeping gaps between separate petal tips transparent.
	var exterior := PackedByteArray(); exterior.resize(w * h)
	var queue := PackedInt32Array()
	for y in range(h):
		for x in range(w):
			if (x == 0 or y == 0 or x == w - 1 or y == h - 1) and mask[y * w + x] == 0:
				var i := y * w + x
				exterior[i] = 1; queue.append(i)
	var head := 0
	while head < queue.size():
		var i := queue[head]; head += 1
		var x := i % w; var y := i / w
		for next in [i - 1 if x > 0 else -1, i + 1 if x < w - 1 else -1, i - w if y > 0 else -1, i + w if y < h - 1 else -1]:
			if next >= 0 and mask[next] == 0 and exterior[next] == 0:
				exterior[next] = 1; queue.append(next)
	for i in range(mask.size()):
		if exterior[i] == 0: mask[i] = 1
	return mask

static func cutout(image: Image, mask: PackedByteArray) -> Image:
	var result := Image.create(image.get_width(), image.get_height(), false, Image.FORMAT_RGBA8)
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if mask[y * image.get_width() + x] == 1: result.set_pixel(x, y, image.get_pixel(x, y))
	return result

static func ensure_ready() -> void:
	if clean_plate != null: return
	source_bloom = load(BLOOM_PATH); source_bud = load("res://assets/ui/bonsai_bud.png")
	var closed_image := (load(CLOSED_PATH) as Texture2D).get_image().get_region(CLOSED_RECT)
	closed_frame = ImageTexture.create_from_image(cutout(closed_image, petal_mask(closed_image)))
	var atlas := (load(ATLAS_PATH) as Texture2D).get_image()
	for i in range(24):
		var cell := Vector2i(roundi(float(i % 6) * atlas.get_width() / 6.0), (i / 6) * 232)
		var local := atlas.get_region(Rect2i(cell + FRAME_RECT.position, FRAME_RECT.size))
		frames.append(ImageTexture.create_from_image(cutout(local, petal_mask(local))))
	var final_image := source_bloom.get_image()
	var backing := (load(BACKING_PATH) as Texture2D).get_image()
	var plate := final_image.duplicate()
	# Only the four bounded blossom areas use the generated flower-free backing.
	# All pot, shelf, UI, window and other foliage pixels remain original. Full
	# original local patches are restored independently at each blossom endpoint.
	for rect: Rect2i in REGIONS:
		var part := final_image.get_region(rect)
		endpoint_parts.append(ImageTexture.create_from_image(part))
		plate.blit_rect(backing, rect, rect.position)
	clean_plate = ImageTexture.create_from_image(plate)

	# The original pot/root-base patch is a separate native Sprite2D resource.
	# Remove it from the room layer so hiding/moving that object never leaves a
	# duplicate pot underneath. These lossless partitions reconstruct the source.
	bloom_pot = ImageTexture.create_from_image(plate.get_region(POT_REGION))
	var bloom_room := plate.duplicate()
	bloom_room.convert(Image.FORMAT_RGBA8)
	bloom_room.fill_rect(POT_REGION, Color.TRANSPARENT)
	bloom_background = ImageTexture.create_from_image(bloom_room)
	var bud_room := source_bud.get_image().duplicate()
	bud_room.convert(Image.FORMAT_RGBA8)
	bud_pot = ImageTexture.create_from_image(bud_room.get_region(POT_REGION))
	bud_room.fill_rect(POT_REGION, Color.TRANSPARENT)
	bud_background = ImageTexture.create_from_image(bud_room)
