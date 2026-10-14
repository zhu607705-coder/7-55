extends SceneTree
## Minimal batch startup, physical authority and visual unload smoke. No new matrix.
var fails:Array[String]=[]
func _initialize()->void:run.call_deferred()
func settle()->void:await process_frame;await physics_frame;await process_frame
func snapshot(map:Node2D)->Dictionary:
 var nodes:Array=[];collect(map,map,nodes)
 return {"physical_records":nodes.size(),"physics_sha":sha(var_to_bytes(nodes)),"walk_sha":sha(var_to_bytes(map.walk_polys)),"blocker_sha":sha(var_to_bytes(map.blockers)),"source_data_sha":sha(var_to_bytes(map.data)),"visitor_position":map.visitor.position,"visitor_scale":map.visitor.scale}
func collect(map:Node,node:Node,result:Array)->void:
 if node is CollisionObject2D:result.append([stable_path(map,node),node.get_class(),node.collision_layer,node.collision_mask,node.global_transform])
 if node is CollisionPolygon2D:result.append([stable_path(map,node),node.polygon,node.global_transform,node.disabled])
 if node is CollisionShape2D:
  var shape:Variant=null
  if node.shape is CircleShape2D:shape=node.shape.radius
  elif node.shape is RectangleShape2D:shape=node.shape.size
  result.append([stable_path(map,node),shape,node.global_transform,node.disabled])
 for child in node.get_children():collect(map,child,result)
func stable_path(map:Node,node:Node)->String:
 var pattern:=RegEx.new();pattern.compile("@([A-Za-z0-9_]+)@[0-9]+")
 return pattern.sub(str(map.get_path_to(node)),"@$1",true)
func sha(bytes:PackedByteArray)->String:
 var hash:=HashingContext.new();hash.start(HashingContext.HASH_SHA256);hash.update(bytes);return hash.finish().hex_encode()
func check(ok:bool,label:String)->void:
 if not ok:fails.append(label);push_error(label)
func run()->void:
 var scene:PackedScene=load("res://campuses/buct_changping/scenes/playable.tscn")
 var old=scene.instantiate();old.enable_north_west_upper_hd_region=false;root.add_child(old);await settle();old.visitor.set_physics_process(false)
 var original:=snapshot(old);old.queue_free();await settle()
 var map=scene.instantiate();root.add_child(map);await settle();map.visitor.set_physics_process(false)
 check(map.initialized and is_instance_valid(map.north_west_upper_hd_region),"Default sixth region initializes")
 var actual:=snapshot(map);check(actual==original and actual.physical_records==150 and map.walk_polys.size()==83,"Original physical records, paths and visitor remain exact")
 var diagnostics:Dictionary={}
 if is_instance_valid(map.north_west_upper_hd_region):
  diagnostics=map.north_west_upper_hd_region.get_diagnostics()
  check(diagnostics.active and diagnostics.new_gpu_texture_bytes==6204069 and diagnostics.independent_bodies==1 and diagnostics.independent_body_gpu_bytes==9967612,"Default sixth layer is active with charged budget and one separately charged original registered body")
  check(map.set_north_west_upper_hd_resident(false) and snapshot(map)==original,"Unloading new visual preserves original physical authority")
  check(map.set_north_west_upper_hd_resident(true) and snapshot(map)==original,"Reentry restores new visual without changing original authority")
 var result:={"status":"passed" if fails.is_empty() else "failed","failures":fails,"authority":actual,"diagnostics":diagnostics,"scope":"Seven minimal startup/physics/body/residency checks; no GPU, full matrix or new playability claim"}
 var out:=OS.get_environment("BUCT_NORTH_WEST_QA_DIR")
 if out.is_absolute_path():
  var file:=FileAccess.open(out.path_join("dorm-nw-02-native-smoke-result.json"),FileAccess.WRITE)
  if file!=null:file.store_string(JSON.stringify(result,"  "));file.close()
 print("BUCT_NORTH_WEST_SMOKE "+JSON.stringify(result));map.queue_free();await settle();quit(0 if fails.is_empty() else 1)
