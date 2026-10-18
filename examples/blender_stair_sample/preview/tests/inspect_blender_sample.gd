extends SceneTree
const View=preload("res://scripts/presentation/chapter4_endless_stair_view.gd")
var v
func _initialize():run.call_deferred()
func run():
 root.size=Vector2i(1280,720)
 v=View.new();root.add_child(v)
 await process_frame
 v.set_process(false);v.set_physics_process(false);v._start();v.demo_mode=true
 DirAccess.make_dir_recursive_absolute("user://inspection")
 print("IMPORTED_GLB ",v.imported_scene.scene_file_path," meshes=",v.imported_mesh_count," triangles=",v.imported_triangle_count," blockers=",v.blocker_cache.size())
 for tick in 680:
  v._physics_process(1.0/60);v._present(1.0/60)
  if tick in [150,330,465,570,610]:
   await process_frame
   await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png("user://inspection/frame_%04d.png"%tick)
   print("SAMPLE_FRAME ",tick," progress=",v.model.player.x," gap=",v.model.player.x-v.model.guard.x," status=",v.model.status)
 print("SAMPLE_END ",v.model.status," x=",v.model.player.x," gates=",v.model.gates_passed)
 v.queue_free();await process_frame;quit()
