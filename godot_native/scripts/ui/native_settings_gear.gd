extends TextureRect
## Original 80px fine-grid metal cog. The transparent hub and eight teeth
## remain readable at the existing 48px app size; no font fallback is involved.
## This surface is presentation-only. Its parent owns input and fall proof.
const MASTER_SIZE := 80
static var shared_texture: ImageTexture

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if shared_texture == null:
		shared_texture = ImageTexture.create_from_image(_draw_master())
	texture = shared_texture

static func _solid(x: int, y: int) -> bool:
	var point := Vector2(x + 0.5, y + 0.5) - Vector2.ONE * MASTER_SIZE / 2.0
	var radius := point.length()
	if radius < 12.0: return false
	if radius <= 28.0: return true
	for tooth in range(8):
		var local := point.rotated(-tooth * TAU / 8.0)
		if local.x >= 24.0 and local.x <= 35.0 and absf(local.y) <= 6.0:
			return true
	return false

static func _draw_master() -> Image:
	var image := Image.create(MASTER_SIZE, MASTER_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	for y in range(MASTER_SIZE):
		for x in range(MASTER_SIZE):
			if not _solid(x,y): continue
			var color := Color("c5c1a9")
			if not _solid(x-1,y) or not _solid(x+1,y) or not _solid(x,y-1) or not _solid(x,y+1):
				color = Color("344452")
			elif not _solid(x-3,y-3):
				color = Color("e8e0c8")
			elif not _solid(x+3,y+3):
				color = Color("7993a1")
			image.set_pixel(x,y,color)
	return image
