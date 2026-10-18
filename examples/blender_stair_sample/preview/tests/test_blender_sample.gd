extends SceneTree
const View=preload("res://scripts/presentation/chapter4_endless_stair_view.gd")
const Model=preload("res://scripts/games/chapter4_endless_stair_model.gd")
var checks=0
var errors=0
func _initialize():run.call_deferred()
func check(ok:bool,note:String):
 checks+=1
 if not ok:errors+=1;push_error(note)
func attach_physics(node:Node):
 if node is MeshInstance3D:
  var body=StaticBody3D.new();node.add_child(body)
  var shape=CollisionShape3D.new();shape.shape=node.mesh.create_trimesh_shape();body.add_child(shape)
 for child in node.get_children():
  if not child is StaticBody3D:attach_physics(child)
func count_coarse(node:Node)->int:
 var result=0
 if node is MeshInstance3D and node.mesh is BoxMesh and node.is_visible_in_tree() and node.get_parent()!=v.phone and node not in [v.torch_case,v.torch_lens,v.phone_screen]:result+=1
 for child in node.get_children():result+=count_coarse(child)
 return result
var v
func run():
 root.size=Vector2i(1280,720)
 v=View.new();root.add_child(v);await process_frame
 v.set_process(false);v.set_physics_process(false);v._start()
 check(v.imported_scene.scene_file_path=="res://assets/blender/stairwell_sample.glb","Actual imported GLB scene exists in runtime")
 check(v.imported_mesh_count>=30 and v.imported_mesh_count<=40,"Imported mesh budget 30-40")
 check(v.imported_triangle_count<30000,"Entire two-flight sample triangle budget below 30k")
 check(count_coarse(v.world)==0,"No visible coarse BoxMesh stage scenery survives")
 check(v.torch.shadow_enabled,"Guard flashlight shadows enabled")
 check(v.actor_fill.light_color.b>v.actor_fill.light_color.r,"Blue phone fill preserved")
 check(v.camera.size==6.0,"Approved landscape orthographic size preserved")
 check(is_equal_approx(v.actor.pixel_size,1.7/128.0),"Approved pixel character scale preserved")
 for node in v.imported_scene.get_children():
  for part in node.get_children():
   if part is MeshInstance3D:check(part.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_ON,"Exact GLB mesh casts shadow: "+str(part.name))
 attach_physics(v.imported_scene)
 await physics_frame;await physics_frame
 var space=v.world.get_world_3d().direct_space_state
 var floor_error=0.0
 for section in v.model.geometry.routes:
  var step=.6 if section.kind=="flight" else .35
  var count=int(float(section.length)/step)
  for i in count:
   var progress=float(section.start)+(float(i)+.5)*step
   if progress>32.4 and progress<33.4:continue
   var expected=v.model._floor_height_at(progress,INF)
   var p=v.model.route_position(progress,expected)
   var q=PhysicsRayQueryParameters3D.create(p+Vector3.UP*.10,p-Vector3.UP*.6)
   var hit=space.intersect_ray(q)
   check(not hit.is_empty(),"Render mesh supports route progress %.3f"%progress)
   if not hit.is_empty():
    var error=absf(hit.position.y-expected);floor_error=maxf(floor_error,error)
    check(error<.012,"Render floor matches fixed-tick floor at %.3f: error %.4f"%[progress,error])
 # Recessed glazing stays behind the real opening. Decorative paint must not
 # become a floating opaque face across either side of the window aperture.
 for floor in 3:
  for xx in [.35,1.45]:
   var q=PhysicsRayQueryParameters3D.create(Vector3(xx,floor*3.3+1.5,-4.35),Vector3(xx,floor*3.3+1.5,-5.0))
   var hit=space.intersect_ray(q)
   check(not hit.is_empty(),"Window pane exists behind opening")
   if not hit.is_empty():check(hit.position.z< -4.65,"Decorative wall skirt leaves window aperture open")
 v.near_blockers=v.blocker_cache
 for progress in [5.5,9.7,14.5,20.2,25.0,30.2]:
  var y=v.model._floor_height_at(progress,INF)
  var origin=v.model.route_position(progress,y-.8)
  var distance=v._beam_ray_distance(origin,Vector3.UP,2.0)
  check(distance<.8,"Beam cannot pass upward through stair slab at %.2f"%progress)
 var gap_distance=v._beam_ray_distance(Vector3(-6,6.9,-2.2),Vector3.BACK,1.0)
 check(gap_distance>.99,"Maintenance stand open centre transmits air path")
 var bar_distance=v._beam_ray_distance(Vector3(-6,7.10,-2.2),Vector3.BACK,1.5)
 check(bar_distance<.50,"Maintenance stand solid crossbar blocks air path")
 var m=Model.new();var jumps=0;var min_gap=99.0
 while m.status=="running" and m.tick<3000:
  var input=m.reference_input();if input&Model.JUMP:jumps+=1
  m.step(input);min_gap=minf(min_gap,m.player.x-m.guard.x)
 check(m.status=="finished","Reference fixed-tick input finishes both flights and jump stand")
 check(m.gates_passed==2,"Two flight gates passed")
 check(jumps>0,"Playable sample requires and completes a real jump")
 check(Model.validate_proof(m.proof()),"Successful sample proof replays exactly")
 var n=Model.new()
 while n.status=="running" and n.tick<3000:n.step(Model.RIGHT)
 check(n.status=="failed","Holding forward without jumping does not ghost through stand")
 check(n.player.x<33.1,"Non-jumper stops at real collision rectangle")
 var still=Model.new()
 while still.status=="running" and still.tick<1000:still.step(0)
 check(still.status=="failed","Guard catches an idle player")
 var result={"checks":checks,"failures":errors,"imported_meshes":v.imported_mesh_count,"triangles":v.imported_triangle_count,"visible_coarse_meshes":count_coarse(v.world),"max_render_collision_height_error_m":floor_error,"win_ticks":m.tick,"sample_duration_s":m.tick/60.0,"required_jumps":jumps,"min_gap_m":min_gap,"stand_gap_ray_m":gap_distance,"stand_bar_ray_m":bar_distance,"physics":"Original baseline route + height model; exact GLB ray checks are QA only, not new runtime movement"}
 print("BLENDER_SAMPLE_TEST ",JSON.stringify(result))
 v.queue_free();await process_frame;await process_frame;quit(1 if errors else 0)
