extends Node2D
## One source-art chest, inspected from directly above. The four native parts
## partition the same source pixels; the open pose reconstructs the original
## image, while only the lid moves about the far hinge. No gameplay state lives here.
const ART_PATH: String="res://assets/native/theater_chest_20261023/prop_chest_overhead_body_v2.png"
# The image has sub-1-percent alpha specks outside its visible subject. These
# measured bounds include every subject pixel at or above 1 percent alpha.
const ART_BOUNDS:=Rect2(93,63,1262,945)
const BOTTOM_RECT:=Rect2(270,383,908,501)
const INNER_RECT:=Rect2(224,333,1000,584)
const HINGE_Y:=264.0
const CLOSED_RECT:=Rect2(93,246,1262,762)
const LID_RECT:=Rect2(93,63,1262,201)
# The top-down lid is only a short band when opened a little past vertical.
# Its physical length still reaches the front rim at y=985 when closed.
const CLOSED_LID_DEPTH:=721.0
const OPEN_ANGLE:=acos(-LID_RECT.size.y/CLOSED_LID_DEPTH)

class SourcePart:
	extends Node2D
	var source_texture: Texture2D
	var regions: Array[Rect2]=[]
	var is_lid:=false
	var open_amount:=1.0

	func _draw() -> void:
		if source_texture==null:return
		var lid_cosine:=cos(open_amount*OPEN_ANGLE)
		if is_lid and lid_cosine>=0.0:
			_draw_outer_lid(lid_cosine)
			return
		for region: Rect2 in regions:
			if not is_lid:
				draw_texture_rect_region(source_texture,region,region)
				continue
			var source:=PackedVector2Array([region.position,Vector2(region.end.x,region.position.y),region.end,Vector2(region.position.x,region.end.y)])
			var projected:=PackedVector2Array()
			var uv:=PackedVector2Array()
			var cosine: float=cos(open_amount*OPEN_ANGLE)/absf(cos(OPEN_ANGLE))
			for point: Vector2 in source:
				# Orthographic projection of a rigid lid rotating around its rear
				# hinge. Its physical length is constant; nodes never scale by axis.
				var screen: Vector2=point if open_amount>=1.0 else Vector2(point.x,HINGE_Y+(HINGE_Y-point.y)*cosine)
				projected.append(screen);uv.append(point/source_texture.get_size())
			# At 90 degrees the board is edge-on, with the fixed hinge still visible.
			if absf(projected[0].y-projected[3].y)<.25:continue
			draw_polygon(projected,PackedColorArray([Color.WHITE]),uv,source_texture)

	func _draw_outer_lid(cosine: float) -> void:
		# The inner-face artwork is already foreshortened. Reversing that
		# projection would stretch its rivets and wood grain on the closed face.
		# Instead assemble a flat outer face from the same source pixels at 1:1
		# density, then rotate that entire rigid plane around the shared hinge.
		_tile_plane(Rect2(400,415,600,440),Rect2(93,0,1262,721),cosine)
		_tile_plane(Rect2(405,281,600,45),Rect2(93,0,1262,55),cosine)
		_tile_plane(Rect2(225,923,400,50),Rect2(93,666,1262,55),cosine)
		_tile_plane(Rect2(155,359,51,521),Rect2(93,0,51,721),cosine)
		_tile_plane(Rect2(1242,359,52,521),Rect2(1303,0,52,721),cosine)
		_plane_patch(Rect2(132,264,92,88),Rect2(93,0,92,88),cosine)
		_plane_patch(Rect2(1224,264,92,88),Rect2(1263,0,92,88),cosine)
		_plane_patch(Rect2(132,885,92,98),Rect2(93,623,92,98),cosine)
		_plane_patch(Rect2(1224,885,92,98),Rect2(1263,623,92,98),cosine)
		_plane_patch(Rect2(659,63,128,122),Rect2(660,599,128,122),cosine)

	func _tile_plane(source: Rect2, plane: Rect2, cosine: float) -> void:
		var y:=0.0
		while y<plane.size.y:
			var height:=minf(source.size.y,plane.size.y-y)
			var x:=0.0
			while x<plane.size.x:
				var width:=minf(source.size.x,plane.size.x-x)
				var patch_size:=Vector2(width,height)
				_plane_patch(Rect2(source.position,patch_size),Rect2(plane.position+Vector2(x,y),patch_size),cosine)
				x+=width
			y+=height

	func _plane_patch(source: Rect2, plane: Rect2, cosine: float) -> void:
		if plane.size.y*cosine<.25:return
		var source_corners:=PackedVector2Array([source.position,Vector2(source.end.x,source.position.y),source.end,Vector2(source.position.x,source.end.y)])
		var plane_corners:=PackedVector2Array([plane.position,Vector2(plane.end.x,plane.position.y),plane.end,Vector2(plane.position.x,plane.end.y)])
		var projected:=PackedVector2Array()
		var uv:=PackedVector2Array()
		for index: int in range(4):
			projected.append(Vector2(plane_corners[index].x,HINGE_Y+plane_corners[index].y*cosine))
			uv.append(source_corners[index]/source_texture.get_size())
		draw_polygon(projected,PackedColorArray([Color.WHITE]),uv,source_texture)

var open_amount:=1.0
var closed_inspection:=false
var body: Node2D
var inner_walls: Node2D
var bottom: Node2D
var lid: Node2D
var source_texture: Texture2D

func _ready() -> void:
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	# Normal builds use the imported texture. The direct-image path permits a
	# freshly generated local asset to be inspected before the editor imports it.
	if FileAccess.file_exists(ART_PATH+".import"):
		source_texture=load(ART_PATH)
	else:
		var image:=Image.load_from_file(ART_PATH)
		if not image.is_empty():source_texture=ImageTexture.create_from_image(image)
	if source_texture==null:
		push_error("Theater chest source artwork is unavailable: "+ART_PATH)
		return
	# Body, walls and floor partition the lower image without duplicate
	# translucent edge draws, so the fully open composition stays pixel-aligned.
	body=_part("Body",[
		Rect2(286,246,116,18),
		Rect2(1044,246,114,18),
		Rect2(93,264,1262,69),
		Rect2(93,333,131,584),
		Rect2(1224,333,131,584),
		Rect2(93,917,1262,91)])
	bottom=_part("Bottom",[BOTTOM_RECT])
	inner_walls=_part("InnerWalls",[
		Rect2(224,333,1000,50),
		Rect2(224,383,46,501),
		Rect2(1178,383,46,501),
		Rect2(224,884,1000,33)])
	# Keep the two hinge barrels attached to the body as the lid rotates.
	lid=_part("Lid",[
		Rect2(93,63,1262,183),
		Rect2(93,246,193,18),
		Rect2(402,246,642,18),
		Rect2(1158,246,197,18)],true)
	set_open_amount(open_amount)

func _part(part_name: String, regions: Array[Rect2], hinged:=false) -> SourcePart:
	var part:=SourcePart.new()
	part.name=part_name;part.source_texture=source_texture;part.regions=regions
	part.is_lid=hinged;part.open_amount=open_amount
	part.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(part)
	return part

func set_open_amount(value: float) -> void:
	open_amount=clampf(value,0.0,1.0)
	if is_instance_valid(lid):
		lid.open_amount=open_amount;lid.queue_redraw()

func set_closed_inspection(value: bool) -> void:
	closed_inspection=value
	if value:set_open_amount(0.0)
