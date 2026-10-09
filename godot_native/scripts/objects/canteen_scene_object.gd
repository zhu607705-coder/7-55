extends Node2D
## One registered native prop, with optional independent front-face slice.
var definition:Dictionary
var object_id:String
var asset:Dictionary
var source_region:Rect2
var texture:Texture2D
var scale_value:float
var dimensions:=Vector2.ZERO
var top_left:=Vector2.ZERO
var ids:Array=[]
var footprint:=PackedVector2Array()
var local_foot_bounds:=Rect2()
var body:StaticBody2D
var parts:Array[Dictionary]=[]
var player_cover:Sprite2D
var base_position:=Vector2.ZERO
var sort_depth:=0.0
static func draw_layer(source_depth:float)->int:
	return clampi(int(floor(source_depth/40.0))+1,1,50)
func configure(row:Dictionary,source:Dictionary,tex:Texture2D)->void:
	definition=row.duplicate(true);asset=source;texture=tex;object_id=str(row.id);name=object_id
	position=Vector2(row.position[0],row.position[1]);base_position=position;scale_value=float(row.scale);sort_depth=float(row.depth);ids=row.get("targets",[]).duplicate()
	var b:Array=source.get("source_bounds",source.alpha_bounds);source_region=Rect2(b[0],b[1],b[2]-b[0],b[3]-b[1]);dimensions=source_region.size*scale_value;top_left=Vector2(-dimensions.x/2,-dimensions.y)
	if row.has("front_slice"):
		var split:=floorf(source_region.size.y*float(row.front_slice))
		_add_part("Back",Rect2(source_region.position,Vector2(source_region.size.x,split)),top_left,float(row.get("back_depth",1)))
		_add_part("Front",Rect2(source_region.position+Vector2(0,split),Vector2(source_region.size.x,source_region.size.y-split)),top_left+Vector2(0,split*scale_value),sort_depth)
	else:_add_part("Appearance",source_region,top_left,sort_depth)
	if row.has("front_slice"):
		player_cover=Sprite2D.new();player_cover.name="PlayerOcclusionFace";player_cover.texture=texture;player_cover.region_enabled=true;player_cover.region_rect=source_region;player_cover.centered=false;player_cover.position=top_left;player_cover.scale=Vector2.ONE*scale_value;player_cover.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;player_cover.z_index=draw_layer(sort_depth+1);player_cover.modulate.a=.52;player_cover.hide();add_child(player_cover)
	for p:Array in row.get("footprint",[]):footprint.append(Vector2(p[0],p[1]))
	if not footprint.is_empty():
		local_foot_bounds=Rect2(footprint[0],Vector2.ZERO)
		for point:Vector2 in footprint:local_foot_bounds=local_foot_bounds.expand(point)
		body=StaticBody2D.new();body.name="VisibleFootprint";body.collision_layer=0;body.collision_mask=0;add_child(body)
		var shape:=CollisionPolygon2D.new();shape.polygon=footprint;body.add_child(shape)
func _add_part(part_name:String,region:Rect2,at:Vector2,depth:float)->void:
	var sprite:=Sprite2D.new();sprite.name=part_name;sprite.texture=texture;sprite.region_enabled=true;sprite.region_rect=region;sprite.centered=false;sprite.position=at;sprite.scale=Vector2.ONE*scale_value;sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;sprite.z_index=draw_layer(depth);add_child(sprite)
	parts.append({"sprite":sprite,"region":region,"depth":depth,"base_position":at,"base_scale":sprite.scale})
func set_active(active:bool)->void:
	if body!=null:body.collision_layer=1 if active and visible else 0
func set_front_reveal(player_feet:Rect2,player_visual:Rect2,reduced:bool)->void:
	if player_cover!=null:player_cover.visible=sort_depth>player_feet.end.y and Rect2(position+top_left,dimensions).intersects(player_visual)
	for part:Dictionary in parts:
		var sprite:Sprite2D=part.sprite
		var rect:=Rect2(position+sprite.position,part.region.size*sprite.scale)
		var soften:bool=part.depth>player_feet.end.y and rect.intersects(player_visual) and definition.has("front_slice")
		var opacity:=.58 if soften else 1.0
		sprite.modulate.a=opacity if reduced else lerpf(sprite.modulate.a,opacity,.22)
func geometry()->Dictionary:
	return {"rect":Rect2(position+top_left,dimensions),"texture":texture,"source":source_region}
func surfaces()->Array:
	var result:Array=[]
	if not visible:return result
	for part:Dictionary in parts:
		var sprite:Sprite2D=part.sprite
		if not sprite.visible or sprite.modulate.a<=.05:continue
		result.append({"depth":part.depth,"canvas_z":sprite.z_index,"root_order":get_index(),"part_order":sprite.get_index(),"ids":ids,"geometry":{"rect":Rect2(position+sprite.position,part.region.size*sprite.scale),"texture":texture,"source":part.region}})
	if player_cover!=null and player_cover.visible:result.append({"depth":sort_depth+1,"canvas_z":player_cover.z_index,"root_order":get_index(),"part_order":player_cover.get_index(),"ids":ids,"geometry":geometry()})
	return result
func collision_polygon()->PackedVector2Array:
	var result:=PackedVector2Array()
	if not visible:return result
	for p:Vector2 in footprint:result.append(position+p)
	return result
func blocks_feet(feet:Rect2)->bool:
	if not visible or footprint.is_empty():return false
	if not Rect2(position+local_foot_bounds.position,local_foot_bounds.size).intersects(feet):return false
	var box:=PackedVector2Array([feet.position,Vector2(feet.end.x,feet.position.y),feet.end,Vector2(feet.position.x,feet.end.y)])
	return not Geometry2D.intersect_polygons(box,collision_polygon()).is_empty()
func footprint_bounds()->Rect2:
	var poly:=collision_polygon()
	if poly.is_empty():return Rect2()
	var rect:=Rect2(poly[0],Vector2.ZERO)
	for p:Vector2 in poly:rect=rect.expand(p)
	return rect
func paint_on(canvas:CanvasItem,front:bool,actor_feet_y:float,alpha:float=1.0)->void:
	if not visible:return
	for part:Dictionary in parts:
		if (float(part.depth)>actor_feet_y)!=front:continue
		var sprite:Sprite2D=part.sprite
		canvas.draw_texture_rect_region(texture,Rect2(position+sprite.position,part.region.size*sprite.scale),part.region,Color(1,1,1,alpha))
