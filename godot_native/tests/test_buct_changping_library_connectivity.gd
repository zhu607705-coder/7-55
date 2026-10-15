extends SceneTree
# Production regression. Reconstruct the previous internal guard in an isolated
# first scene, then verify the unmodified production scene and real physics.
var output:=""
const CANDIDATE=preload("res://campuses/buct_changping/scripts/playable_campus.gd")
const HD=preload("res://campuses/buct_changping/scripts/registered_hd_region.gd")
var checks:=0
var failures:Array[String]=[]
var report:Dictionary={}
var campus:Node2D
var physics_ticks:=0
var illegal_ticks:=0
var max_speed:=0.0
var trace:Array=[]
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures.append(label);push_error(label)
func tick()->void:await physics_frame;await process_frame
func settle()->void:await process_frame;await tick();await process_frame
func point(p:Vector2)->Array:return [p.x,p.y]
func snapshot(map:Node2D)->Dictionary:
 var physics:Array=[];collect(map,map,physics)
 return {"physics":HD._sha(var_to_bytes(physics)),"physics_records":physics.size(),"walk_polys":HD._sha(var_to_bytes(map.walk_polys)),"blockers":HD._sha(var_to_bytes(map.blockers)),"source_data":HD._sha(var_to_bytes(map.data)),"foot_radius":map.visitor.get_node("FeetCollision").shape.radius,"speed":map.visitor.speed,"height":map.visitor.display_height}
func collect(map:Node,node:Node,out:Array)->void:
 var pieces:Array[String]=[];var cur:Node=node
 while cur!=map:
  var label:=str(cur.name)
  if label.begins_with("@"):label=cur.get_class()+"[%d]"%cur.get_index()
  pieces.push_front(label);cur=cur.get_parent()
 var path:="/".join(pieces)
 if node is CollisionObject2D:out.append([path,node.get_class(),node.collision_layer,node.collision_mask,node.global_transform])
 if node is CollisionPolygon2D:out.append([path,node.polygon,node.global_transform,node.disabled])
 if node is CollisionShape2D:
  var shape:Variant=null
  if node.shape is CircleShape2D:shape=node.shape.radius
  elif node.shape is RectangleShape2D:shape=node.shape.size
  out.append([path,shape,node.global_transform,node.disabled])
 for child in node.get_children():collect(map,child,out)
func cells(map:Node2D)->Dictionary:
 var result:Dictionary={}
 for cell in map.walk_cells:result[Vector2i(cell)]=true
 return result
func targets(map:Node2D)->Array:
 var result:Array=[]
 for target in [Vector2(566,836),Vector2(566,816),Vector2(565,833),Vector2(559,848),Vector2(731,676),Vector2(666,548),Vector2(759,861)]:
  var path:PackedVector2Array=map.grid.get_point_path(map.nearest_cell(Vector2(515,1510)),map.nearest_cell(target))
  result.append({"target":point(target),"reachable":not path.is_empty(),"path_nodes":path.size()})
 return result
func legacy_paving(p:Vector2)->bool:
 for offset in [Vector2.ZERO,Vector2(3,0),Vector2(-3,0),Vector2(0,3),Vector2(0,-3)]:
  var inside:=false
  for raw in campus.data.walkable_polygons:
   if Geometry2D.is_point_in_polygon(p+offset,campus.pts(raw)):inside=true;break
  if not inside:return false
 return true
func run()->void:
 output=OS.get_environment("BUCT_LIBRARY_ROUTE_QA_DIR")
 if output.is_empty():output=ProjectSettings.globalize_path("user://library-route-gap")
 DirAccess.make_dir_recursive_absolute(output)
 var source_sha:=FileAccess.get_sha256("res://campuses/buct_changping/assets/approved-changping.png")
 check(source_sha=="f92a8de6ef703bab4b2e471a49acc082dd4d128d264d99d3ed1818fdb0c93707","Approved 950x1656 source identity preserved")
 var baseline=load("res://campuses/buct_changping/scenes/playable.tscn").instantiate();root.add_child(baseline);await settle()
 baseline.visitor.set_physics_process(false)
 # Reproduce the removed internal boundary without changing production files.
 baseline.east_road_extension.exposed_edges.append(PackedVector2Array([Vector2(700,856),Vector2(700,870)]))
 baseline.walk_cells.clear();baseline._build_grid()
 report.before={"authority":snapshot(baseline),"targets":targets(baseline),"walkable_grid_cells":baseline.walk_cells.size()}
 var before_cells:=cells(baseline)
 check(not baseline.path_to(Vector2(566,816)),"Reconstructed prior internal guard reproduces unreachable library from actual spawn")
 check(baseline.path_to(Vector2(731,676)),"Baseline east-to-north remains reachable")
 check(not baseline.is_walkable(Vector2(699,863)) and baseline._in_paving(Vector2(699,863)),"Baseline false x700 guard blocks existing paving")
 var before:Dictionary=report.before.authority
 baseline.queue_free();baseline=null;await settle()
 campus=CANDIDATE.new();root.add_child(campus);await settle();campus.visitor.set_physics_process(false)
 check(campus.initialized,"Unmodified production scene initializes")
 report.after={"authority":snapshot(campus),"targets":targets(campus),"walkable_grid_cells":campus.walk_cells.size()}
 check(report.after.authority==before,"Every actual collision, blocker, paving polygon, source waypoint, speed, height and radius is identical")
 check(campus.walk_polys.size()==83,"No paving polygon added or removed")
 var after_cells:=cells(campus);var added:Array=[];var removed:Array=[]
 for cell in after_cells:
  if not before_cells.has(cell):
   var p:Vector2=campus.grid.get_point_position(cell);added.append(point(p));check(legacy_paving(p),"Restored cell was already authored legacy paving: "+str(p))
 for cell in before_cells:
  if not after_cells.has(cell):removed.append(point(campus.grid.get_point_position(cell)))
 report.grid_delta={"restored_legacy_cells":added,"removed_cells":removed}
 check(removed.is_empty() and not added.is_empty(),"Only blocked legacy cells restored; no prior legal cell lost")
 for item in report.after.targets:check(item.reachable,"Spawn reaches original requested target "+str(item.target))
 var broken:Array=[];var last:Vector2i=campus.nearest_cell(Vector2(515,1510))
 for raw in campus.data.route_waypoints:
  var cell:Vector2i=campus.nearest_cell(Vector2(raw[0],raw[1]))
  if campus.grid.get_id_path(last,cell).is_empty():broken.append(raw)
  last=cell
 report.after.broken_guide_legs=broken
 check(broken.is_empty(),"All 41 original guide waypoints connected without changing any waypoint")
 # Visual unload, failed visual reload and display-disabled fresh startup must
 # not revoke logical roads. The independent explicit road uninstall is tested last.
 var full_cells:=cells(campus);var road=campus.north_road_extension
 campus.set_west_hd_resident(false)
 campus.north_hd_region.uninstall();campus.north_hd_region=null
 campus.wenli_hd_region.uninstall();campus.wenli_hd_region=null
 await settle()
 check(is_instance_valid(road) and road==campus.north_road_extension,"All HD unloading keeps campus-owned north road")
 check(cells(campus)==full_cells and snapshot(campus)==before,"All HD unloading preserves full navigation and original physics authority")
 check(HD.install(campus,"res://campuses/buct_changping/data/missing_hd_fixture.json")==null,"Missing HD resource rejects without mutating scene")
 check(cells(campus)==full_cells and campus.path_to(Vector2(666,548)),"Missing visual resource cannot revoke north road or library route")
 report.visual_residency={"all_hd_unloaded_navigation_identical":cells(campus)==full_cells,"missing_hd_rejected":true}
 # Continuous real default CharacterBody2D route. No position assignment,
 # speed overrides, manual physics calls or teleports occur in this proof.
 campus.current_path.clear();campus.visitor.set_physics_process(true)
 var arrivals:Array=[]
 for target in [Vector2(566,816),Vector2(666,548),Vector2(566,816),Vector2(515,1510)]:
  check(campus.path_to(target),"Continuous route path exists to "+str(target))
  var endpoint:Vector2=campus.current_path[-1]
  var count:=0
  while campus.path_index<campus.current_path.size() and count<2500:
   await tick();count+=1;physics_ticks+=1
   var p:Vector2=campus.visitor.position
   if not campus.is_walkable(p):illegal_ticks+=1
   max_speed=maxf(max_speed,campus.visitor.last_motion.length()*Engine.physics_ticks_per_second)
   if physics_ticks%4==0:trace.append(point(p))
  check(campus.visitor.position.distance_to(endpoint)<=2.5 and campus.visitor.position.distance_to(target)<=2.5+sqrt(2.0),"Real student continuously arrives under unchanged snapped-endpoint contract "+str(target))
  arrivals.append({"target":point(target),"actual":point(campus.visitor.position),"snapped_endpoint":point(endpoint),"endpoint_distance":campus.visitor.position.distance_to(endpoint),"ticks":count})
  if count>=2500:break
 campus.current_path.clear();await tick()
 check(illegal_ticks==0,"Continuous default physics never places feet outside legal pavement")
 check(max_speed<=88.05,"Continuous walking respects unchanged speed88")
 report.continuous={"arrivals":arrivals,"physics_ticks":physics_ticks,"illegal_ticks":illegal_ticks,"max_actual_speed":max_speed,"position_writes_after_spawn":0,"trace_every_4_ticks":trace}
 # Separate authored guide regression. Its existing explicit reset is recorded.
 campus.start_guide();var guide_ticks:=0
 while campus.guide_active and guide_ticks<1800:await tick();guide_ticks+=1
 check(not campus.guide_active and campus.visitor.position.distance_to(Vector2(566,816))<8,"Original guide genuinely completes at library")
 check(campus.visited.size()==3,"Original guide credits exactly original three POIs")
 report.guide={"ticks":guide_ticks,"feet":point(campus.visitor.position),"visited":campus.visited.duplicate(),"index":campus.guide_index,"start_guide_reset_count":1}
 campus.close_info();campus.guide_active=false;campus.current_path.clear()
 # Isolated held-key adversarial fixtures are explicitly separate from travel.
 var fixtures:Array=[]
 for item in [{"name":"library_wall","start":Vector2(566,816),"key":KEY_UP},{"name":"toward_lake","start":Vector2(559,848),"key":KEY_LEFT},{"name":"road_east_edge","start":Vector2(769,807),"key":KEY_RIGHT},{"name":"north_road_grass","start":Vector2(707,620),"key":KEY_LEFT}]:
  campus.visitor.position=item.start;campus.visitor.velocity=Vector2.ZERO;await tick()
  key(item.key,true);var illegal:=0
  for i in range(90):
   await tick()
   if not campus.is_walkable(campus.visitor.position):illegal+=1
  var stop:Vector2=campus.visitor.position
  check(illegal==0 and campus.is_walkable(stop),"Held key never enters wall/water/grass: "+item.name)
  check(campus.visitor.last_motion.length()<.001,"Held key stops against protected boundary: "+item.name)
  key(item.key,false);await tick();var released:Vector2=campus.visitor.position
  for i in range(5):await tick()
  check(campus.visitor.position.distance_to(released)<.001 and campus.visitor.manual_input.length()<.001,"Key release has no drift: "+item.name)
  fixtures.append({"name":item.name,"fixture_start":point(item.start),"stop":point(stop),"illegal_ticks":illegal,"drift":campus.visitor.position.distance_to(released)})
 campus.visitor.set_physics_process(false);campus.visitor.position=Vector2(550,814);await tick()
 check(campus.visitor.move_and_collide(Vector2(0,-40),true)!=null,"Actual native radius3 library collider still rejects wall crossing")
 for p in [Vector2(559,744),Vector2(600,790),Vector2(510,850),Vector2(700,900),Vector2(763.25,881)]:check(not campus.is_walkable(p),"Roof, unapproved ground/water and original full-circle counterexample stay blocked "+str(p))
 report.boundary_fixtures=fixtures
 campus.queue_free();campus=null;await settle()
 var disabled=CANDIDATE.new();disabled.enable_wenli_hd_region=false;disabled.enable_north_hd_region=false;disabled.enable_west_hd_regions=false;root.add_child(disabled);await settle();disabled.visitor.set_physics_process(false)
 check(cells(disabled)==full_cells,"Fresh startup with every HD display disabled keeps identical authored navigation")
 check(disabled.path_to(Vector2(566,816)) and disabled.path_to(Vector2(666,548)),"Display-disabled startup reaches library and north from real spawn")
 disabled.north_road_extension.uninstall();await settle()
 check(disabled.walk_polys.size()==82 and not disabled.is_walkable(Vector2(731,670)),"Only explicit logical-road uninstall controls north road lifecycle")
 check(disabled.path_to(Vector2(566,816)),"Explicit north road removal cannot recreate library air wall")
 disabled.queue_free();await settle()
 report.checks=checks;report.failures=failures;report.source_sha256=source_sha;report.scope="Production scene with reconstructed prior-guard regression fixture; actual headless physics. No visual acceptance, source edit, speed/radius weakening or new terrain rights."
 var file:=FileAccess.open(output.path_join("runtime-result.json"),FileAccess.WRITE);file.store_string(JSON.stringify(report,"  ")+"\n");file.close()
 print("LIBRARY_ROUTE_GAP checks=%d failures=%d physics_ticks=%d"%[checks,failures.size(),physics_ticks]);quit(0 if failures.is_empty() else 1)
func key(code:int,pressed:bool)->void:
 var ev:=InputEventKey.new();ev.keycode=code;ev.physical_keycode=code;ev.pressed=pressed;Input.parse_input_event(ev)
