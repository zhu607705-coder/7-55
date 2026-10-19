extends RefCounted
## Non-destructive source regions. The original PNG is never rewritten.
const TEXTURE=preload("res://assets/rpg/interiors/finale/chapter4-755/props/chapter4_a3_archive_film_v01.png")
const SIZE:=Vector2(96,82)
const FILM_OUTLINE: Array[Vector2]=[Vector2(52,32),Vector2(57,32),Vector2(69,35),Vector2(70,38),Vector2(68,46),Vector2(49,46),Vector2(50,40),Vector2(51,35)]
static func region(canvas:CanvasItem,where:Rect2,part:Rect2,offset:=Vector2.ZERO,tint:=Color.WHITE)->void:
	var scale_value:=where.size.x/SIZE.x
	canvas.draw_texture_rect_region(TEXTURE,Rect2(where.position+(part.position+offset)*scale_value,part.size*scale_value),part,tint,false,true)
static func render(canvas:CanvasItem,where:Rect2,pull:float,film_alpha:float,film_offset:=Vector2.ZERO,tint:=Color.WHITE)->void:
	# Fixed chassis, source paper cover, original amber film, and moving front
	# are separate registered pieces. The source's aspect ratio stays intact.
	region(canvas,where,Rect2(0,0,96,48),Vector2.ZERO,tint)
	var scale_value:=where.size.x/SIZE.x
	# A polygon follows only the existing amber sleeve silhouette. Sample the
	# adjacent source card at the same Y, preserving every outer cabinet pixel.
	_film_polygon(canvas,where,Vector2.ZERO,Vector2(-24,0),tint)
	if film_alpha>0:_film_polygon(canvas,where,film_offset,Vector2.ZERO,Color(tint,film_alpha))
	if pull>0:
		# A recessed wood cavity and two source edge rails keep the tray joined
		# to its chassis while the front moves; never expose a floating gap.
		canvas.draw_rect(Rect2(where.position+Vector2(14,47)*scale_value,Vector2(64,pull+2)*scale_value),Color("28180c"))
		for y in range(int(ceil(pull))+1):
			for x in [13,74]:
				canvas.draw_texture_rect_region(TEXTURE,Rect2(where.position+Vector2(x,48+y)*scale_value,Vector2(4,1)*scale_value),Rect2(x,45,4,1),tint,false,true)
	region(canvas,where,Rect2(0,48,96,34),Vector2(0,pull),tint)
static func _film_polygon(canvas:CanvasItem,where:Rect2,offset:Vector2,uv_offset:Vector2,tint:Color)->void:
	var points:=PackedVector2Array();var uvs:=PackedVector2Array();var colors:=PackedColorArray()
	for point:Vector2 in FILM_OUTLINE:
		points.append(where.position+(point+offset)*where.size.x/SIZE.x)
		uvs.append((point+uv_offset)/SIZE);colors.append(tint)
	canvas.draw_polygon(points,colors,uvs,TEXTURE)
