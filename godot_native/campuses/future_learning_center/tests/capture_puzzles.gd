extends SceneTree
var output:=""
var view:Control
const NAMES=["flex","collab","focus","storage","assembly","rail","rules"]
func _initialize()->void:call_deferred("run")
func run()->void:
 root.size=Vector2i(960,540)
 output=OS.get_environment("FLC_CAPTURE_DIR")
 if output.is_empty():output=OS.get_user_data_dir().path_join("flc-4f-captures")
 DirAccess.make_dir_recursive_absolute(output)
 for name:String in NAMES:
  var script=load("res://campuses/future_learning_center/scripts/puzzles/%s_view.gd"%name)
  view=script.new();view.size=Vector2(960,540);root.add_child(view);view.open()
  await process_frame
  await process_frame
  await RenderingServer.frame_post_draw
  var result=root.get_texture().get_image().save_png(output.path_join("%s.png"%name))
  print("CAPTURE ",name," ",result)
  view.close();view.queue_free();await process_frame
 quit()
