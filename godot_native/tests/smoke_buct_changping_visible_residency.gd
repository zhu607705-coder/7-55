extends SceneTree
## Four display-only camera transitions, no new matrix or physical route rights.
var fails:Array[String]=[]
func _initialize()->void:run.call_deferred()
func collect(root_map:Node,node:Node,items:Array)->void:
 if node is CollisionObject2D:items.append([str(root_map.get_path_to(node)),node.get_class(),node.collision_layer,node.collision_mask,node.global_transform])
 if node is CollisionPolygon2D:items.append([str(root_map.get_path_to(node)),node.polygon,node.global_transform,node.disabled])
 if node is CollisionShape2D:items.append([str(root_map.get_path_to(node)),node.shape.get_class(),node.global_transform,node.disabled])
 for child in node.get_children():collect(root_map,child,items)
func authority(map:Node2D)->Dictionary:
 var items:Array=[];collect(map,map,items)
 var digest:=HashingContext.new();digest.start(HashingContext.HASH_SHA256);digest.update(var_to_bytes([items,map.walk_polys,map.blockers,map.data,map.visitor.position,map.visitor.scale]));return {"physical_records":items.size(),"paving_polygons":map.walk_polys.size(),"digest":digest.finish().hex_encode()}
func check(ok:bool,label:String)->void:
 if not ok:fails.append(label);push_error(label)
func at(map:Node2D,p:Vector2,zoom:float)->void:
 map.camera.position=p;map.camera.zoom=Vector2.ONE*zoom;map.camera.reset_smoothing();map.camera.force_update_scroll();await create_timer(.4).timeout
func run()->void:
 var viewport:=SubViewport.new();viewport.size=Vector2i(1280,720);root.add_child(viewport)
 var map=load("res://campuses/buct_changping/scenes/playable.tscn").instantiate();map.enable_hd_visible_residency=true;viewport.add_child(map);await process_frame;await process_frame
 map.set_process(false);map.visitor.set_physics_process(false);map.camera.position_smoothing_enabled=false;map.camera.limit_left=-100000;map.camera.limit_top=-100000;map.camera.limit_right=100000;map.camera.limit_bottom=100000
 var original:=authority(map);var policy=map.hd_visible_residency;var records:Array=[]
 check(is_instance_valid(policy) and original.physical_records==150 and original.paving_polygons==83,"Optional camera policy initializes without new physics")
 await at(map,Vector2(475,1400),2.8);var south:Dictionary=policy.get_diagnostics();records.append(south)
 check(south.resident_groups.is_empty() and authority(map)==original and is_instance_valid(map.wenli_hd_region),"Offscreen registered grounds/bodies release while original geometry and legacy Wenli persist")
 await at(map,Vector2(242,300),2.8);var north:Dictionary=policy.get_diagnostics();records.append(north)
 check("north_west_upper" in north.resident_groups and "north_large" in north.resident_groups and "west_pair" in north.resident_groups and is_instance_valid(map.north_west_upper_hd_region) and map.north_west_upper_hd_region.bodies.has("dorm_nw_02") and authority(map)==original,"Visible upper/conditional lower dependency groups and new body reenter with original geometry")
 await at(map,Vector2(475,828),.43);var full:Dictionary=policy.get_diagnostics();records.append(full)
 check(full.resident_groups.size()==4 and full.visible_groups_budget_fallback.is_empty() and authority(map)==original,"Current six-region overview restores all within unchanged layer/slot caps")
 var result:={"status":"passed" if fails.is_empty() else "failed","failures":fails,"checks":4,"records":records,"original_authority":original,"production_flag_default":false,"scope":"Opt-in display camera release/reentry smoke only; no GPU/driver memory or gameplay claim; no seventh region fabricated"}
 var out:=OS.get_environment("BUCT_RESIDENCY_QA_DIR");if out.is_absolute_path():
  var file:=FileAccess.open(out.path_join("visible-residency-smoke-result.json"),FileAccess.WRITE);if file!=null:file.store_string(JSON.stringify(result,"  "));file.close()
 print("BUCT_VISIBLE_RESIDENCY_SMOKE "+JSON.stringify(result));map.queue_free();await process_frame;quit(0 if fails.is_empty() else 1)
