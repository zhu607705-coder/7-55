extends Node2D
## One physical prop. Its original pixels are ordered at their ground contact.
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
var part_pool:Array[Dictionary]=[]
var render_parent:Node2D
var base_position:=Vector2.ZERO
var sort_depth:=0.0
var slice_signature:=""
var last_cuts:Array=[]
var slice_updates:=0
var surface_cache:Array=[]
var surface_cache_revision:=-1
static func draw_layer(source_depth:float)->int:
	return 0 if source_depth<=0 else clampi(int(floor(source_depth/40.0))+1,1,50)
func configure(row:Dictionary,source:Dictionary,tex:Texture2D)->void:
	definition=row.duplicate(true);asset=source;texture=tex;object_id=str(row.id);name=object_id
	position=Vector2(row.position[0],row.position[1]);base_position=position;scale_value=float(row.scale);sort_depth=float(row.depth);ids=row.get("targets",[]).duplicate()
	var b:Array=source.get("source_bounds",source.alpha_bounds);source_region=Rect2(b[0],b[1],b[2]-b[0],b[3]-b[1]);dimensions=source_region.size*scale_value;top_left=Vector2(-dimensions.x/2,-dimensions.y)
	for p:Array in row.get("footprint",[]):footprint.append(Vector2(p[0],p[1]))
	if not footprint.is_empty():
		local_foot_bounds=Rect2(footprint[0],Vector2.ZERO)
		for point:Vector2 in footprint:local_foot_bounds=local_foot_bounds.expand(point)
		body=StaticBody2D.new();body.name="VisibleFootprint";body.collision_layer=0;body.collision_mask=0;add_child(body)
		var shape:=CollisionPolygon2D.new();shape.polygon=footprint;body.add_child(shape)
	set_actor_planes([])
func attach_surfaces(parent:Node2D)->void:
	# Separate siblings let an actor sit between surface pieces even inside one
	# coarse z bucket. The prop still owns geometry, collisions and interaction.
	render_parent=parent
	for part:Dictionary in part_pool:_attach_part(part)
func _attach_part(part:Dictionary)->void:
	if part.has("draw_root"):return
	var sprite:Sprite2D=part.sprite
	sprite.reparent(render_parent,false);sprite.name=object_id+"_"+str(part_pool.find(part))
	sprite.position+=position;part["base_position"]=sprite.position;part["draw_root"]=sprite
func _slice(first:float,last:float,depth:float)->Dictionary:
	return {"region":Rect2(source_region.position+Vector2(0,first),Vector2(source_region.size.x,last-first)),"position":top_left+Vector2(0,first*scale_value),"depth":depth}
func support_depth(projected_y:float)->float:
	if not asset.has("long_surface_end"):return sort_depth
	var rear:float=position.y+local_foot_bounds.position.y
	var progress:=clampf((projected_y-position.y-top_left.y)/(float(asset.long_surface_end)*scale_value),0,1)
	return lerpf(rear,sort_depth,progress)
func _surface_cuts(actors:Array)->Array:
	var split:float=float(asset.long_surface_end)
	var rear:float=position.y+local_foot_bounds.position.y
	var cuts:Array=[0.0,split]
	var visual:=Rect2(position+top_left,dimensions)
	for actor:Dictionary in actors:
		var feet_y:float=float(actor.depth)
		if feet_y<=rear or feet_y>=sort_depth or not visual.intersects(actor.rect):continue
		# Adjacent pieces share an exact integer source row; never alpha blends.
		var cut:=clampf(roundf((feet_y-rear)/(sort_depth-rear)*split),1,split-1)
		if not cuts.has(cut):cuts.append(cut)
	cuts.sort()
	return cuts
func _long_slices(cuts:Array)->Array:
	var split:float=float(asset.long_surface_end)
	var rear:float=position.y+local_foot_bounds.position.y
	var result:Array=[]
	for i in range(cuts.size()-1):
		var middle:float=(float(cuts[i])+float(cuts[i+1]))*.5
		result.append(_slice(cuts[i],cuts[i+1],lerpf(rear,sort_depth,middle/split)))
	result.append(_slice(split,source_region.size.y,sort_depth))
	return result
func depth_slices(actors:Array)->Array:
	var height:=source_region.size.y
	if definition.get("ground_plane",false):return [_slice(0,height,0)]
	if asset.has("long_surface_end"):return _long_slices(_surface_cuts(actors))
	if asset.get("wall_back",false):
		var split:=floorf(height*float(definition.front_slice))
		return [_slice(0,split,1),_slice(split,height,sort_depth)]
	# Upright cabinets are opaque at their floor contact. They do not become
	# see-through merely because the player walks behind them.
	return [_slice(0,height,sort_depth)]
func set_actor_planes(actors:Array)->void:
	if not asset.has("long_surface_end") and not slice_signature.is_empty():
		_sync_part_roots()
		return
	var cuts:Array=_surface_cuts(actors) if asset.has("long_surface_end") else []
	if not cuts.is_empty() and cuts==last_cuts:
		_sync_part_roots()
		return
	last_cuts=cuts
	var slices:Array=_long_slices(cuts) if not cuts.is_empty() else depth_slices(actors)
	var signature:=""
	for spec:Dictionary in slices:signature+=str(spec.region.position.y)+":"+str(spec.region.size.y)+":"+str(spec.depth)+";"
	if signature!=slice_signature:
		slice_signature=signature;slice_updates+=1;parts.clear()
		for i in range(slices.size()):
			if i>=part_pool.size():
				var sprite:=Sprite2D.new();sprite.name="Surface"+str(i);sprite.texture=texture;sprite.region_enabled=true;sprite.centered=false;sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;add_child(sprite)
				var part:Dictionary={"sprite":sprite};part_pool.append(part)
				if render_parent!=null:_attach_part(part)
			var part:Dictionary=part_pool[i];var spec:Dictionary=slices[i];var sprite:Sprite2D=part.sprite
			sprite.region_rect=spec.region;sprite.position=spec.position+(position if render_parent!=null else Vector2.ZERO);sprite.scale=Vector2.ONE*scale_value;sprite.z_index=draw_layer(spec.depth);sprite.show()
			part.merge({"region":spec.region,"depth":spec.depth,"local_position":spec.position,"base_position":sprite.position,"base_scale":sprite.scale},true);parts.append(part)
		for i in range(slices.size(),part_pool.size()):part_pool[i].sprite.hide()
	_sync_part_roots()
func _sync_part_roots()->void:
	for i in range(part_pool.size()):
		var part:Dictionary=part_pool[i]
		if not part.has("draw_root"):continue
		var painter:Sprite2D=part.sprite
		var at:Vector2=position+part.local_position
		if painter.position!=at:painter.position=at;part.base_position=at
		var paint_visible:bool=visible and i<parts.size()
		if painter.visible!=paint_visible:painter.visible=paint_visible
		if painter.modulate!=modulate:painter.modulate=modulate
func set_active(active:bool)->void:
	if body!=null:body.collision_layer=1 if active and visible else 0
	for i in range(part_pool.size()):
		if part_pool[i].has("draw_root"):part_pool[i].sprite.visible=visible and i<parts.size()
func geometry()->Dictionary:
	return {"rect":Rect2(position+top_left,dimensions),"texture":texture,"source":source_region}
func surfaces()->Array:
	var result:Array=[]
	if not visible:return result
	if surface_cache_revision!=slice_updates:
		surface_cache.clear();surface_cache_revision=slice_updates
		for part:Dictionary in parts:
			var sprite:Sprite2D=part.sprite
			surface_cache.append({"node":sprite,"depth":part.depth,"canvas_z":sprite.z_index,"ids":ids,"geometry":{"rect":Rect2(position+part.local_position,part.region.size*sprite.scale),"texture":texture,"source":part.region}})
	for surface:Dictionary in surface_cache:
		var sprite:Sprite2D=surface.node
		if not sprite.visible:continue
		surface["root_order"]=sprite.get_index() if render_parent!=null else get_index()
		surface["part_order"]=0 if render_parent!=null else sprite.get_index()
		result.append(surface)
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
	for part:Dictionary in depth_slices([{"depth":actor_feet_y,"rect":geometry().rect}]):
		if (float(part.depth)>actor_feet_y)!=front:continue
		canvas.draw_texture_rect_region(texture,Rect2(position+part.position,part.region.size*scale_value),part.region,Color(1,1,1,alpha))
func _notification(what:int)->void:
	if what!=NOTIFICATION_PREDELETE:return
	# Surface siblings belong to this prop even though depth sorting puts them
	# in the shared coordinate space. Removing one prop must remove its pixels.
	for part:Dictionary in part_pool:
		if not is_instance_valid(part.get("draw_root")):continue
		var draw_root:Node=part.draw_root
		if not draw_root.is_queued_for_deletion():draw_root.queue_free()
