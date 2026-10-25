extends Node2D
## One named exhibit object. Its source silhouette, pivot and footprint travel
## together; the parent adapter only schedules depth around the shared player.
const Layout=preload("res://scripts/objects/room301_exhibit_layout.gd")
var definition:Dictionary={}
var silhouette:=PackedVector2Array()
var drawer:Sprite2D
var drawer_rest:=Vector2.ZERO
var film:Sprite2D
var film_rest:=Vector2.ZERO
var cavity:Polygon2D
var generated:Sprite2D

class SourcePatch extends Node2D:
	var texture:Texture2D
	var area:=Rect2()
	var source:=Rect2()
	func _draw()->void:
		var y:float=area.position.y
		while y<area.end.y:
			var h:float=minf(source.size.y,area.end.y-y)
			var x:float=area.position.x
			while x<area.end.x:
				var w:float=minf(source.size.x,area.end.x-x)
				draw_texture_rect_region(texture,Rect2(x,y,w,h),Rect2(source.position,Vector2(w,h)))
				x+=w
			y+=h

static func corners(area:Rect2)->PackedVector2Array:
	return PackedVector2Array([area.position,Vector2(area.end.x,area.position.y),area.end,Vector2(area.position.x,area.end.y)])

func configure(row:Dictionary,plate:Texture2D,case_texture:Texture2D,film_texture:Texture2D)->void:
	definition=row;name=str(row.id)
	var bounds:=Layout.rect(row.rect)
	position=Vector2(bounds.get_center().x,float(row.baselineY))
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	if row.has("polygon"):
		for point:Array in row.polygon:silhouette.append(Vector2(float(point[0]),float(point[1])))
	else:silhouette=corners(bounds)
	set_meta("source_rect",bounds);set_meta("footprints",row.solids);set_meta("source_pivot",position)
	match str(row.get("kind","source")):
		"north_wall":
			patch("Coping",plate,Rect2(43,43,465,16),Rect2(43,43,465,16))
			# Plain plaster is a broad material surface, not a repeated sliver
			# of a frame's baked shadow. Original documents remain separate.
			var pixels:Image=plate.get_image()
			if pixels.is_compressed():pixels.decompress()
			var plaster:=Polygon2D.new();plaster.name="Plaster"
			plaster.polygon=corners(Rect2(Vector2(58,59)-position,Vector2(433,73)))
			var top:Color=pixels.get_pixel(461,83);var bottom:Color=pixels.get_pixel(461,119)
			plaster.vertex_colors=PackedColorArray([top,top,bottom,bottom]);add_child(plaster)
			patch("TimberSkirting",plate,Rect2(58,132,433,15),Rect2(432,132,34,15))
		"archive_case":_build_case(bounds,case_texture,film_texture)
		"entrance":
			# The room has no door-lock gate. Keep the original jambs and expose
			# the floor between them instead of a painted board across the exit.
			source_piece("LeftJamb",plate,corners(Rect2(248,373,16,33)))
			source_piece("RightJamb",plate,corners(Rect2(299,373,16,33)))
		_:source_piece("Appearance",plate,silhouette)

func patch(id:String,plate:Texture2D,area:Rect2,donor:Rect2)->void:
	var part:=SourcePatch.new();part.name=id;part.texture=plate
	part.area=Rect2(area.position-position,area.size);part.source=donor;add_child(part)

func source_piece(id:String,plate:Texture2D,source_polygon:PackedVector2Array)->void:
	var piece:=Polygon2D.new();piece.name=id;piece.texture=plate;piece.uv=source_polygon
	var vertices:=PackedVector2Array()
	for point:Vector2 in source_polygon:vertices.append(point-position)
	piece.polygon=vertices;add_child(piece)

func _sprite(id:String,texture:Texture2D,source:Rect2,origin:Vector2,factor:float)->Sprite2D:
	var sprite:=Sprite2D.new();sprite.name=id;sprite.texture=texture;sprite.centered=false
	sprite.region_enabled=true;sprite.region_rect=source;sprite.region_filter_clip_enabled=true
	sprite.position=origin;sprite.scale=Vector2.ONE*factor;add_child(sprite);return sprite

func _build_case(bounds:Rect2,art:Texture2D,film_art:Texture2D)->void:
	var source:=Layout.rect(Layout.data().generatedCase.trim)
	var factor:float=bounds.size.x/source.size.x
	generated=_sprite("GlassAndTimberCase",art,source,bounds.position-position,factor)
	var cut:=Layout.rect(Layout.data().generatedCase.drawerSource)
	drawer_rest=bounds.position-position+(cut.position-source.position)*factor
	cavity=Polygon2D.new();cavity.name="RecessBehindDrawer"
	cavity.polygon=corners(Rect2(drawer_rest,cut.size*factor));cavity.color=Color("241b12");add_child(cavity)
	drawer=_sprite("MovingIndexDrawer",art,cut,drawer_rest,factor)
	film_rest=Vector2(bounds.get_center().x,bounds.end.y-16)-position
	film=_sprite("AcceptedFilm",film_art,Rect2(53,30,18,17),film_rest,.65);film.hide()

func present_drawer(pose:Dictionary)->void:
	if drawer==null:return
	var pull:float=float(pose.pull)
	drawer.position=drawer_rest+Vector2(0,pull)
	cavity.visible=pull>.01
	film.visible=pose.stage=="handoff" and float(pose.film_alpha)>.001
	film.position=film_rest+Vector2(pose.film_offset)
	film.modulate.a=float(pose.film_alpha)

func geometry()->Dictionary:
	if generated!=null:
		return {"rect":Rect2(position+generated.position,generated.region_rect.size*generated.scale),"texture":generated.texture,"source":generated.region_rect}
	return {"polygon":silhouette}
