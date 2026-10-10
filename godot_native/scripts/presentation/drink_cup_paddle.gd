extends RefCounted
## Generated rigid lever. Raster registration is distinct from physical motion.
const PATH="res://assets/native/canteen_animation/drink_cup_paddle.png"
const TEXTURE=preload(PATH)
const IMAGE_PIVOT:=Vector2(627,240)
const IMAGE_CONTACT:=Vector2(733,950) # Visible metal rim, excluding the black shadow fringe.
const REGION:=Rect2(488,150,280,960)
const SCALE:float=66.0/710.0
const CONTACT_LOCAL:Vector2=(IMAGE_CONTACT-IMAGE_PIVOT)*SCALE
static func sprite()->Sprite2D:
	var s:=Sprite2D.new()
	s.name="GeneratedCupPushPaddle";s.texture=TEXTURE;s.centered=false
	s.region_enabled=true;s.region_rect=REGION
	s.position=(REGION.position-IMAGE_PIVOT)*SCALE
	s.scale=Vector2.ONE*SCALE;s.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	return s
