extends SceneTree
## Human input starts at the real chooser, with --fresh and separate workspace user data.
func _initialize():call_deferred("start")
func start():
 if not OS.get_cmdline_user_args().has("--fresh"):
  printerr("Manual campus QA requires isolated --fresh session");quit(2);return
 root.set_meta("entry_arguments_consumed",true)
 change_scene_to_file("res://scenes/entry.tscn")
