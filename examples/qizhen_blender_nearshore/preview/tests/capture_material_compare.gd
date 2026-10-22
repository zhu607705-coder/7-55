extends SceneTree
var view: Node2D
var output: String
func _initialize() -> void:
 output=ProjectSettings.globalize_path("res://../outputs/")
 for a in OS.get_cmdline_user_args():
  if a.begins_with("--comparison-output="):output=a.trim_prefix("--comparison-output=").trim_suffix("/")+"/"
 DirAccess.make_dir_recursive_absolute(output);call_deferred("run")
func run() -> void:
 view=load("res://scenes/blender_lake_sample.tscn").instantiate();root.add_child(view);view.set_process(false);view.title_open=false;view.touch_mode=true
 for scene in [{"label":"dock","point":Vector2(6000,2850),"goal":0},{"label":"pickup","point":Vector2(5810,3655),"goal":1}]:
  view.game.position=scene.point;view.game.progress=scene.goal;view.game.heading=-PI/2;view.game.speed=0;view.clock=12;view._sync(0,true)
  for n in range(4):await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png(output+"material-"+scene.label+".png")
 print("SAME_CAMERA_MATERIAL_COMPARISON_COMPLETE");quit()
