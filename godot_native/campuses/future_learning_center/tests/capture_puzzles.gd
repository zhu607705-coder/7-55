extends SceneTree
var output:=""
var view:Control
const NAMES=["electrical","koala","machinery","solid_projection","platform","robotics","signal_sync","formula","projection","fold","logic","balance","schedule","recording","access","sync","coupled","perspective","flex","collab","focus","storage","assembly","rail","rules"]
func _initialize()->void:call_deferred("run")
func run()->void:
 if DisplayServer.get_name()=="headless":
  push_error("Capture requires a real graphical renderer, not the dummy headless renderer");quit(2);return
 root.size=Vector2i(960,540)
 output=OS.get_environment("FLC_CAPTURE_DIR")
 if output.is_empty():output=OS.get_user_data_dir().path_join("flc-station-captures")
 DirAccess.make_dir_recursive_absolute(output)
 for name:String in NAMES:
  var path:="res://campuses/future_learning_center/scripts/workbench_view.gd" if name=="electrical" else "res://campuses/future_learning_center/scripts/puzzles/%s_view.gd"%name
  var script=load(path)
  view=script.new();view.size=Vector2(960,540);root.add_child(view);view.open()
  await process_frame
  await process_frame
  await RenderingServer.frame_post_draw
  var result=root.get_texture().get_image().save_png(output.path_join("%s.png"%name))
  print("CAPTURE ",name," ",result)
  view.close();view.queue_free();await process_frame
 quit()
