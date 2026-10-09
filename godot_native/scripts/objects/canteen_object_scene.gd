extends Node2D
## Independent furniture, original Chapter3 state-owned actors and deterministic picking.
const Prop=preload("res://scripts/objects/canteen_scene_object.gd")
const Metrics=preload("res://scripts/player_metrics.gd")
const TrayFrames=preload("res://scripts/presentation/c3_tray_frames.gd")
class Feature extends Node2D:
	var owner_scene:Node2D
	var role:String
	func _draw()->void:owner_scene.draw_feature(self,role)
class Tail extends Node2D:
	var owner_scene:Node2D
	func _draw()->void:
		if owner_scene.world==null or not owner_scene.is_active():return
		owner_scene.world._draw_floor_route(owner_scene._origin,self)
		owner_scene.world._draw_tail_pass(self,owner_scene.world._render_context())
var world:Control
var layout:Dictionary
var objects:Dictionary={}
var textures:Dictionary={}
var structures:Array=[]
var source_space:Node2D
var floor_sprite:Sprite2D
var floor_patches:Array[Sprite2D]=[]
var player_sprite:Sprite2D
var player_shadow:Polygon2D
var entities:Dictionary={}
var entity_surfaces:Array=[]
var feature_surfaces:Array=[]
var features:Array[Node2D]=[]
var dynamic_bodies:Dictionary={}
var dynamic_collisions:Array=[]
var sorted_parts:Array=[]
var state:Dictionary={}
var layers:RefCounted
var mixer_performance:Node2D
var drink_performance:Node2D
var _active:=false
var _origin:=Vector2.ZERO
var _zoom:=1.0
var _player:=Vector2.ZERO
var font:Font
var return_age:=10.0
var previous_returns:=0
var bound_state:Dictionary={}
var return_start:=Vector2.ZERO
var last_surface_ids:Dictionary={}
var glow_entries:Array=[]
var floor_pixels:Image
var navigation_cache:Array=[]
var navigation_signature:=""
var story_layer_leases:Dictionary={}
func setup(owner_world:Control)->void:
	world=owner_world;name="CanteenIndependentObjects"
	layout=JSON.parse_string(FileAccess.get_file_as_string("res://data/native/canteen-object-layout.json"))
	font=load("res://assets/rpg/fonts/fusion_pixel_12px_proportional_zh_hans.ttf")
	if world!=null:layers=world.chapter3_layers
	source_space=Node2D.new();source_space.name="SourceCoordinates";add_child(source_space)
	for key:String in layout.assets:textures[key]=load(layout.assets[key].texture)
	floor_pixels=textures.empty_floor.get_image()
	if floor_pixels.is_compressed():floor_pixels.decompress()
	floor_sprite=Sprite2D.new();floor_sprite.name="EmptyFloor";floor_sprite.texture=textures.empty_floor;floor_sprite.centered=false;floor_sprite.z_index=0
	var fr:Array=layout.background.region;floor_sprite.region_enabled=true;floor_sprite.region_rect=Rect2(fr[0],fr[1],fr[2],fr[3]);floor_sprite.position=Vector2(fr[0],fr[1]);source_space.add_child(floor_sprite)
	for opening:Dictionary in layout.get("floor_openings",[]):
		var patch:=Sprite2D.new();patch.name=str(opening.id);patch.texture=textures.empty_floor;patch.centered=false;patch.region_enabled=true;patch.z_index=0
		var src:Array=opening.source;var dst:Array=opening.destination
		patch.region_rect=Rect2(src[0],src[1],src[2],src[3]);patch.position=Vector2(dst[0],dst[1]);patch.scale=Vector2(dst[2]/float(src[2]),dst[3]/float(src[3]));source_space.add_child(patch);floor_patches.append(patch)
	for row:Dictionary in layout.objects:
		var prop:=Prop.new();prop.configure(row,layout.assets[row.asset],textures[row.asset]);source_space.add_child(prop);objects[row.id]=prop
		for part:Dictionary in prop.parts:sorted_parts.append({"object":prop,"part":part,"depth":part.depth})
	for row:Dictionary in layout.structures:
		var poly:=PackedVector2Array()
		for point:Array in row.polygon:poly.append(Vector2(point[0],point[1]))
		var body:=StaticBody2D.new();body.name=row.id;body.collision_layer=0;body.collision_mask=0;source_space.add_child(body)
		var shape:=CollisionPolygon2D.new();shape.polygon=poly;body.add_child(shape)
		structures.append({"id":row.id,"polygon":poly,"body":body,"navigation_group":row.get("navigation_group",row.id)})
	sorted_parts.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return a.depth<b.depth)
	player_shadow=Polygon2D.new();player_shadow.name="OriginalPlayerFootShadow";player_shadow.color=Color(0,0,0,.25)
	var shadow_points:=PackedVector2Array()
	for i in range(24):shadow_points.append(Vector2(cos(i*TAU/24)*19,sin(i*TAU/24)*6))
	player_shadow.polygon=shadow_points
	source_space.add_child(player_shadow)
	player_sprite=Sprite2D.new();player_sprite.name="OriginalPlayer";player_sprite.centered=false;source_space.add_child(player_sprite)
	for role:String in ["pickup_slots","mixer","drink_screens","return_contact","promo_glow","door_opening"]:
		var feature:=Feature.new();feature.name=role;feature.role=role;feature.owner_scene=self;var depth:float={"pickup_slots":244,"mixer":818,"drink_screens":230,"return_contact":615,"promo_glow":1699,"door_opening":0}[role];feature.set_meta("source_depth",depth);feature.z_index=0 if role=="door_opening" else Prop.draw_layer(depth);source_space.add_child(feature);features.append(feature)
		if role=="return_contact":feature.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	mixer_performance=load("res://scripts/objects/canteen_mixer_performance.gd").new();source_space.add_child(mixer_performance);mixer_performance.setup(world)
	drink_performance=load("res://scripts/objects/canteen_drink_performance.gd").new();source_space.add_child(drink_performance);drink_performance.setup(world)
	var tail:=Tail.new();tail.owner_scene=self;tail.name="CanteenInterface";tail.z_index=60;add_child(tail)
	hide();set_process(world!=null)
func is_active()->bool:return _active
func sync(next_state:Dictionary,scene_id:String)->void:
	var was:=_active;_active=scene_id=="canteen_interior";visible=_active;state=next_state
	if is_instance_valid(mixer_performance):mixer_performance.sync(state,_active)
	if is_instance_valid(drink_performance):drink_performance.sync(state,_active)
	if not is_same(bound_state,state):bound_state=state;previous_returns=state.canteenHunt.returnedTrayIds.size();_reset_feedback()
	if _active and state.canteenHunt.returnedTrayIds.size()>previous_returns:
		return_age=0;return_start=world.player+Vector2(0,-3) if world!=null else Vector2(1497,592)
	previous_returns=state.canteenHunt.returnedTrayIds.size()
	if not _active:_reset_feedback()
	for prop:Node2D in objects.values():
		prop.visible=not(prop.definition.get("decorative_cart",false) and str(state.canteenHunt.phase)=="exit_blocking")
		prop.set_active(_active)
	for entry:Dictionary in structures:entry.body.collision_layer=1 if _active else 0
	if not _active:
		_restore_story_layers()
		for body:StaticBody2D in dynamic_bodies.values():body.collision_layer=0
		return
	if layers!=null:
		layers.sync(state);dynamic_collisions=layers.adjusted_collisions([],state)
		_sync_dynamic_bodies()
func _lease_story_layers()->void:
	if world==null or not is_instance_valid(world.host_node):return
	var shell:Node=world.host_node
	for spec:Array in [["c3_narrative_host","view",70],["c3_narrative_host","effects",55],["c3_scene_host","paper",70]]:
		var host:Node=shell.get(spec[0])
		if not is_instance_valid(host):continue
		var node:CanvasItem=host.get(spec[1])
		if not is_instance_valid(node):continue
		var id:int=node.get_instance_id()
		if not story_layer_leases.has(id):story_layer_leases[id]={"node":weakref(node),"original":node.z_index,"assigned":int(spec[2])}
		node.z_index=int(spec[2])
func _restore_story_layers()->void:
	for lease:Dictionary in story_layer_leases.values():
		var node:CanvasItem=lease.node.get_ref()
		if is_instance_valid(node) and node.z_index==lease.assigned:node.z_index=lease.original
	story_layer_leases.clear()
func _exit_tree()->void:_restore_story_layers()
func _sort_source(a:Dictionary,b:Dictionary)->bool:
	return a.depth<b.depth if a.depth!=b.depth else a.order<b.order
func _sort_painted(a:Dictionary,b:Dictionary)->bool:
	if a.canvas_z!=b.canvas_z:return a.canvas_z<b.canvas_z
	if a.root_order!=b.root_order:return a.root_order<b.root_order
	return a.get("part_order",0)<b.get("part_order",0)
func _apply_draw_order()->void:
	# Native world geometry stays below existing Main modal100/toast110.
	# Source depth remains exact within each coarse z bucket by sibling order.
	var ordered:Array=[]
	for prop:Node2D in objects.values():ordered.append({"node":prop,"depth":prop.sort_depth})
	for surface:Dictionary in entity_surfaces:
		if surface.has("node"):ordered.append({"node":surface.node,"depth":surface.depth})
	for feature:Node2D in features:ordered.append({"node":feature,"depth":float(feature.get_meta("source_depth"))})
	if is_instance_valid(mixer_performance):ordered.append({"node":mixer_performance,"depth":818.0})
	if is_instance_valid(drink_performance):ordered.append({"node":drink_performance,"depth":197.0})
	ordered.append({"node":player_shadow,"depth":float(player_sprite.get_meta("source_depth",0))-1})
	ordered.append({"node":player_sprite,"depth":float(player_sprite.get_meta("source_depth",0))})
	for i in range(ordered.size()):ordered[i]["order"]=i
	ordered.sort_custom(_sort_source)
	var offset:int=source_space.get_child_count()-ordered.size()
	for i in range(ordered.size()):
		var node:Node=ordered[i].node
		if node.get_index()!=i+offset:source_space.move_child(node,i+offset)
func _reset_feedback()->void:
	return_age=10
	if not objects.has("return_stack"):return
	for part:Dictionary in objects.return_stack.parts:
		part.sprite.scale=part.base_scale;part.sprite.position=part.base_position
func _process(delta:float)->void:
	if _active and return_age<1:
		return_age+=minf(maxf(delta,0),.05)
		for feature:Node2D in features:feature.queue_redraw()
func return_pose()->Dictionary:
	var stack:Node2D=objects.return_stack
	return TrayFrames.return_sample(return_age,return_start,stack.position,float(stack.dimensions.y),bool(state.native.settings.reduced_motion))
func _configure_return_depth()->void:
	var feature:Node2D=source_space.get_node("return_contact")
	var depth:float=615
	if return_age<TrayFrames.return_duration(bool(state.native.settings.reduced_motion)):
		var pose:Dictionary=return_pose();var side:float=float(pose.size)
		var painted:Rect2=Transform2D(float(pose.angle),Vector2(pose.position))*Rect2(Vector2.ONE*(-side/2),Vector2.ONE*side)
		depth=float(objects.return_stack.sort_depth)+1
		if player_sprite.visible and painted.intersects(Metrics.visual_rect(_player,world.display_scale_at(_player))):
			depth=maxf(depth,float(player_sprite.get_meta("source_depth",0))+1)
	feature.set_meta("source_depth",depth);feature.z_index=Prop.draw_layer(depth)
func _return_surface()->Dictionary:
	if return_age>=TrayFrames.return_duration(bool(state.native.settings.reduced_motion)):return {}
	var pose:Dictionary=return_pose()
	if float(pose.alpha)<=.05:return {}
	var feature:Node2D=source_space.get_node("return_contact");var side:float=float(pose.size)
	var tex:Texture2D=layers.texture(str(pose.asset))
	return {"depth":float(feature.get_meta("source_depth")),"canvas_z":feature.z_index,"root_order":feature.get_index(),"ids":[],"geometry":{"rect":Rect2(Vector2.ONE*(-side/2),Vector2.ONE*side),"texture":tex,"source":pose.source,"transform":Transform2D(float(pose.angle),Vector2(pose.position))}}
func _sync_dynamic_bodies()->void:
	for body:StaticBody2D in dynamic_bodies.values():body.collision_layer=0
	for row:Dictionary in dynamic_collisions:
		var id:=str(row.id);var rect:=Rect2(row.left,row.top,row.right-row.left,row.bottom-row.top)
		if not dynamic_bodies.has(id):
			var body:=StaticBody2D.new();body.name=id;body.collision_mask=0;var shape:=CollisionShape2D.new();shape.shape=RectangleShape2D.new();body.add_child(shape);source_space.add_child(body);dynamic_bodies[id]=body
		var body:StaticBody2D=dynamic_bodies[id];body.position=rect.get_center();body.get_child(0).shape.size=rect.size;body.collision_layer=1
func configure_view(origin:Vector2,zoom:float,player:Vector2)->void:
	if not _active:return
	_lease_story_layers();_origin=origin;_zoom=zoom;_player=player;source_space.position=origin;source_space.scale=Vector2.ONE*zoom
	var tint:=Color.WHITE.lerp(Color(.03,.15,.26),float(world.mode_mix)*.3);floor_sprite.modulate=tint
	for patch:Sprite2D in floor_patches:patch.modulate=tint
	var reduced:bool=bool(state.native.settings.reduced_motion)
	for prop:Node2D in objects.values():prop.modulate=tint;prop.set_front_reveal(Metrics.foot_rect(player),Metrics.visual_rect(player),reduced)
	var frames:Array=world.player_frames.get(world.facing,[])
	if not frames.is_empty():
		player_sprite.texture=world.player_side_idle if world.facing=="side" and world.walk_clock<=0 else frames[Metrics.frame_at(world.walk_clock*1000)]
	var visual:=Metrics.visual_rect(player,world.display_scale_at(player));player_sprite.position=visual.position;player_sprite.scale=visual.size/Metrics.FRAME;player_sprite.flip_h=world.player_flip and world.facing=="side";player_sprite.set_meta("source_depth",Metrics.foot_rect(player).end.y);player_sprite.z_index=Prop.draw_layer(Metrics.foot_rect(player).end.y);player_sprite.visible=not world.presentation_actor_hidden
	player_shadow.position=player+Vector2(0,39);player_shadow.z_index=Prop.draw_layer(Metrics.foot_rect(player).end.y-1);player_shadow.visible=player_sprite.visible
	_update_entities();_update_door();_configure_return_depth();_apply_draw_order();record_surfaces()
	for feature:Node2D in features:feature.queue_redraw()
	get_node("CanteenInterface").queue_redraw()
func _entity(id:String)->Sprite2D:
	if not entities.has(id):
		var sprite:=Sprite2D.new();sprite.name=id;sprite.centered=false;sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;source_space.add_child(sprite);entities[id]=sprite
	return entities[id]
func _place_entity(id:String,tex:Texture2D,region:Rect2,rect:Rect2,depth:float,ids:Array,alpha:float=1,angle:float=0,pivot:Vector2=Vector2(.5,.5))->void:
	var sprite:=_entity(id);sprite.show();sprite.texture=tex;sprite.region_enabled=true;sprite.region_rect=region;sprite.position=rect.position+rect.size*pivot;sprite.offset=-region.size*pivot;sprite.scale=rect.size/region.size;sprite.rotation=angle;sprite.modulate=Color(1,1,1,alpha);sprite.set_meta("source_depth",depth);sprite.z_index=Prop.draw_layer(depth)
	if alpha>.05:entity_surfaces.append({"node":sprite,"depth":depth,"canvas_z":sprite.z_index,"ids":ids,"geometry":{"rect":Rect2(-region.size*pivot,region.size),"texture":tex,"source":region,"transform":sprite.transform}})
func _update_entities()->void:
	entity_surfaces.clear();glow_entries.clear()
	for sprite:Sprite2D in entities.values():sprite.hide()
	if layers==null:return
	for e:Dictionary in layers.entries(state):
		if e.kind=="crop":continue
		if e.kind=="sprite":
			var tex:Texture2D=layers.texture(e.asset)
			if tex==null:continue
			var region:=Rect2(Vector2.ZERO,tex.get_size())
			if e.has("frameSize"):
				var columns:=maxi(1,int(tex.get_width()/e.frameSize.x));region=Rect2(Vector2((int(e.frame)%columns)*e.frameSize.x,int(int(e.frame)/columns)*e.frameSize.y),e.frameSize)
			var dims:Vector2=e.get("size",region.size)*float(e.get("scale",1));var anchor:Vector2=e.get("anchor",Vector2(.5,.5))
			var ids:Array=layers._pick_ids(e,world.targets)
			if str(e.id) in ["queue_6","queue_turn"]:ids.push_front("queue-column-three-front")
			var depth:float=float(e.depth) if str(e.id).begins_with("promo") or str(e.id).begins_with("queue_prompt") else e.point.y
			_place_entity(str(e.id),tex,region,Rect2(e.point-dims*anchor,dims),depth,ids,float(e.get("alpha",1)),deg_to_rad(float(e.get("angle",0))),anchor)
		elif e.kind=="glow":glow_entries.append(e)
		elif e.kind=="tray":
			var to:Vector2=_player+Vector2(0,-3)
			var age_ms:float=layers.pickup_ms if e.id=="tray_pickup" else INF
			var pose:Dictionary=TrayFrames.pickup_sample(age_ms,layers.pickup_start,to,layers.reduced(state))
			var tex:Texture2D=layers.texture(str(pose.asset));var side:float=float(pose.size)
			_place_entity(str(e.id),tex,pose.source,Rect2(pose.position-Vector2.ONE*(side/2),Vector2.ONE*side),_player.y+43,[],float(pose.alpha),float(pose.angle))
	for t:Dictionary in world.targets:
		var id:=str(t.id)
		if not id.begins_with("tray_"):continue
		var tex:Texture2D=layers.texture(str(t.art));var at:=Vector2(t.position[0],t.position[1]);var dims:=Vector2(28,28)
		_place_entity(id,tex,Rect2(Vector2.ZERO,tex.get_size()),Rect2(at-dims/2,dims),at.y+10,[id])
func _update_door()->void:
	var door:Node2D=objects.southeast_door;var progress:float=layers.doors.visual_progress if layers.doors.scene_id=="canteen_interior" else 0
	for part:Dictionary in door.parts:part.sprite.visible=false
	var tex:Texture2D=door.texture;var region:Rect2=door.source_region;var dims:Vector2=door.dimensions;var left_top:Vector2=door.position+door.top_left
	# Independent source halves follow the original sensor/timing; no collision gate.
	for side in range(2):
		var full_width:=dims.x/2;var width:=full_width*lerpf(1,.18,progress)
		var at:=left_top+Vector2(0 if side==0 else dims.x-width,0)
		_place_entity("southeast_leaf_"+str(side),tex,Rect2(region.position+Vector2(region.size.x/2*side,0),Vector2(region.size.x/2,region.size.y)),Rect2(at,Vector2(width,dims.y)),900,["southeast_exit"],1-progress)
func owns_target(id:String)->bool:
	return _active and (id.begins_with("initial-") or id.begins_with("tray_") or id.begins_with("drink-machine-") or id.begins_with("pickup_window_") or id in ["ordering_kiosk","queue-column-three-front","drink-bottle-shelf","canteen-mixer","canteen-promo-board","auntie","southeast_exit"])
func target_geometry(id:String)->Dictionary:
	return last_surface_ids.get(id,{})
func record_surfaces()->void:
	if world==null or not _active:return
	world.object_picker.clear();last_surface_ids.clear()
	# The open, visible doorway remains the exit affordance after its leaves fold.
	world.object_picker.add(["southeast_exit"],{"rect":Rect2(1305,795,88,105)},false)
	var ordered:Array=[]
	for prop:Node2D in objects.values():ordered.append_array(prop.surfaces())
	for surface:Dictionary in entity_surfaces:surface["root_order"]=surface.node.get_index()
	ordered.append_array(entity_surfaces)
	feature_surfaces.clear()
	for i in range(5):
		var x:float=[346,595,835,1080,1235][i]
		feature_surfaces.append({"depth":244.0,"canvas_z":Prop.draw_layer(244),"root_order":source_space.get_node("pickup_slots").get_index(),"ids":["pickup_window_"+str(i+1)],"geometry":{"rect":Rect2(x-19,209,38,20)}})
	if is_instance_valid(mixer_performance) and is_instance_valid(mixer_performance.glass_back):
		feature_surfaces.append({"depth":818.0,"canvas_z":mixer_performance.z_index,"root_order":mixer_performance.get_index(),"ids":["canteen-mixer"],"geometry":{"polygon":mixer_performance.glass_back.polygon,"transform":mixer_performance.transform*mixer_performance.glass_root.transform}})
	var return_surface:Dictionary=_return_surface()
	if not return_surface.is_empty():feature_surfaces.append(return_surface)
	ordered.append_array(feature_surfaces)
	var actor_ids:Array=[]
	for t:Dictionary in world.targets:
		if t.get("follow_player",false):actor_ids.append(str(t.id))
	if player_sprite.visible:ordered.append({"depth":float(player_sprite.get_meta("source_depth",0)),"canvas_z":player_sprite.z_index,"root_order":player_sprite.get_index(),"ids":actor_ids,"geometry":{"rect":Metrics.visual_rect(_player,world.display_scale_at(_player)),"texture":player_sprite.texture,"flip_h":player_sprite.flip_h}})
	ordered.sort_custom(_sort_painted)
	for surface:Dictionary in ordered:
		world.object_picker.add(surface.ids,surface.geometry)
		for id:String in surface.ids:last_surface_ids[id]=surface.geometry
func blocks_feet(feet:Rect2)->bool:
	if not _active:return false
	for point:Vector2 in [feet.position,Vector2(feet.end.x,feet.position.y),feet.end,Vector2(feet.position.x,feet.end.y),feet.get_center()]:
		if point.x<0 or point.y<0 or point.x>=floor_pixels.get_width() or point.y>=floor_pixels.get_height() or floor_pixels.get_pixel(int(point.x),int(point.y)).a<.5:return true
	var box:=PackedVector2Array([feet.position,Vector2(feet.end.x,feet.position.y),feet.end,Vector2(feet.position.x,feet.end.y)])
	for row:Dictionary in structures:
		if not Geometry2D.intersect_polygons(box,row.polygon).is_empty():return true
	for prop:Node2D in objects.values():
		if prop.blocks_feet(feet):return true
	for row:Dictionary in dynamic_collisions:
		if Rect2(row.left,row.top,row.right-row.left,row.bottom-row.top).intersects(feet):return true
	return false
func navigation_rects()->Array:
	var groups:Dictionary={};var result:Array=[]
	for prop:Node2D in objects.values():
		var rect:Rect2=prop.footprint_bounds()
		if not rect.has_area():continue
		var key:String=prop.definition.get("navigation_group",prop.object_id)
		groups[key]=groups[key].merge(rect) if groups.has(key) else rect
	for row:Dictionary in structures:result.append_array(_polygon_rectangles(row.polygon))
	result.append_array(groups.values())
	for row:Dictionary in dynamic_collisions:result.append(Rect2(row.left,row.top,row.right-row.left,row.bottom-row.top))
	return result
func _polygon_rectangles(poly:PackedVector2Array)->Array:
	# Orthogonal wall legs remain separate. A concave frame never becomes a room box.
	var ys:Array=[];var result:Array=[]
	for point:Vector2 in poly:
		if not ys.has(point.y):ys.append(point.y)
	ys.sort()
	for i in range(ys.size()-1):
		var low:float=ys[i];var high:float=ys[i+1]
		var left:Array=_polygon_crossings(poly,low+.00001);var right:Array=_polygon_crossings(poly,high-.00001)
		for j in range(0,mini(left.size(),right.size())-1,2):
			var x0:float=minf(left[j],right[j]);var x1:float=maxf(left[j+1],right[j+1])
			result.append(Rect2(x0,low,x1-x0,high-low))
	return result
func _polygon_crossings(poly:PackedVector2Array,y:float)->Array:
	var xs:Array=[]
	for i in range(poly.size()):
		var a:Vector2=poly[i];var b:Vector2=poly[(i+1)%poly.size()]
		if (a.y>y)!=(b.y>y):xs.append(a.x+(y-a.y)*(b.x-a.x)/(b.y-a.y))
	xs.sort();return xs
func navigation_obstacles(foot:Rect2)->Array:
	var signature:=JSON.stringify(dynamic_collisions)+str(state.canteenHunt.phase)+str(foot)
	if signature==navigation_signature:return navigation_cache
	navigation_signature=signature
	var expanded:Array=[]
	for rect:Rect2 in navigation_rects():expanded.append(Rect2(rect.position-foot.end,rect.size+foot.size))
	navigation_cache=_rect_union(expanded);return navigation_cache
func _rect_union(rects:Array)->Array:
	# Keep an exact overlapping cover instead of splitting every intersection
	# into strips: strip seam corners waste the unchanged planner corner budget.
	var result:Array=rects.duplicate()
	var changed:=true
	while changed:
		changed=false
		for i in range(result.size()):
			if changed:break
			var a:Rect2=result[i]
			for j in range(i+1,result.size()):
				var b:Rect2=result[j]
				if a.encloses(b):result.remove_at(j);changed=true;break
				if b.encloses(a):result.remove_at(i);changed=true;break
				var same_x:bool=is_equal_approx(a.position.x,b.position.x) and is_equal_approx(a.end.x,b.end.x)
				var same_y:bool=is_equal_approx(a.position.y,b.position.y) and is_equal_approx(a.end.y,b.end.y)
				if (same_x and a.position.y<=b.end.y and b.position.y<=a.end.y) or (same_y and a.position.x<=b.end.x and b.position.x<=a.end.x):
					result[i]=a.merge(b);result.remove_at(j);changed=true;break
	return result
func collision_rects()->Array:
	var result:Array=[]
	for rect:Rect2 in navigation_rects():result.append({"id":"canteen_native_"+str(result.size()),"left":rect.position.x,"top":rect.position.y,"right":rect.end.x,"bottom":rect.end.y})
	return result
func draw_feature(canvas:CanvasItem,role:String,force:bool=false)->void:
	if not _active and not force:return
	if role=="pickup_slots":
		for i in range(5):
			var x:float=[346,595,835,1080,1235][i];canvas.draw_rect(Rect2(x-19,209,38,20),Color("7c6742"));canvas.draw_rect(Rect2(x-15,213,30,8),Color("152525"));canvas.draw_string(font,Vector2(x-3,228),str(i+1),HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("f5e6b8"))
	elif role=="mixer":
		var at:=Vector2(260,758)
		canvas.draw_line(at+Vector2(5,5),at+Vector2(20,-40),Color("d4bf8b"),3);canvas.draw_rect(Rect2(226,783,68,19),Color("314e48"));canvas.draw_string(font,Vector2(232,797),"混合台",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("ecdeb5"))
	elif role=="drink_screens":
		var colors:Array=[Color("477bbd"),Color("ded8b1"),Color("3c3130")]
		for i in range(3):
			var x:float=[1421,1473,1525][i];canvas.draw_rect(Rect2(x-8,127,16,32),colors[i]);canvas.draw_rect(Rect2(x-5,135,10,19),Color("dee8dc",.6));canvas.draw_rect(Rect2(x-3,132,6,4),Color("29372f"))
	elif role=="promo_glow":
		for e:Dictionary in glow_entries:canvas.draw_rect(Rect2(e.point-e.size/2,e.size),Color("9af4ff",e.alpha))
	elif role=="door_opening":canvas.draw_rect(Rect2(1305,795,88,105),Color("172020"))
	elif role=="return_contact" and return_age<TrayFrames.return_duration(bool(state.native.settings.reduced_motion)):
		var pose:Dictionary=return_pose()
		var tex:Texture2D=layers.texture(str(pose.asset))
		canvas.draw_set_transform(pose.position,float(pose.angle))
		var side:float=float(pose.size)
		canvas.draw_texture_rect_region(tex,Rect2(Vector2.ONE*(-side/2),Vector2.ONE*side),pose.source,Color(1,1,1,float(pose.alpha)))
		canvas.draw_set_transform(Vector2.ZERO)
func paint_defense(canvas:CanvasItem,front:bool,feet_y:float)->void:
	# Same manifest on the existing deterministic defense board; model untouched.
	if not front:
		canvas.draw_texture_rect_region(textures.empty_floor,Rect2(11,1,1659,940),Rect2(11,1,1659,940))
		for opening:Dictionary in layout.get("floor_openings",[]):
			var src:Array=opening.source;var dst:Array=opening.destination
			canvas.draw_texture_rect_region(textures.empty_floor,Rect2(dst[0],dst[1],dst[2],dst[3]),Rect2(src[0],src[1],src[2],src[3]))
	for entry:Dictionary in sorted_parts:
		var prop:Node2D=entry.object
		if prop.definition.get("decorative_cart",false):continue
		if prop.definition.has("door"):
			if not front:canvas.draw_rect(Rect2(prop.position+prop.top_left,prop.dimensions),Color("172020"))
			continue
		if (float(entry.depth)>feet_y)!=front:continue
		var part:Dictionary=entry.part;var sprite:Sprite2D=part.sprite
		canvas.draw_texture_rect_region(prop.texture,Rect2(prop.position+sprite.position,part.region.size*sprite.scale),part.region)

	if front:
		for prop:Node2D in objects.values():
			if prop.definition.has("front_slice") and prop.sort_depth>feet_y:canvas.draw_texture_rect_region(prop.texture,Rect2(prop.position+prop.top_left,prop.dimensions),prop.source_region)
	for role:String in ["pickup_slots","mixer","drink_screens"]:
		var depth:float={"pickup_slots":244,"mixer":818,"drink_screens":230}[role]
		if (depth>feet_y)==front:draw_feature(canvas,role,true)
