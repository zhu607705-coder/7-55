extends SceneTree
func _initialize() -> void:call_deferred("run")
func capture(path: String) -> void:
	for i in range(10):await process_frame
	await RenderingServer.frame_post_draw
	var image:=root.get_texture().get_image()
	if image.is_empty() or image.save_png(path)!=OK:push_error("Capture failed: "+path);quit(1)
func run() -> void:
	if DisplayServer.get_name()=="headless":quit(2);return
	var output:=OS.get_environment("KENNEY_CAPTURE_DIR")
	if output.is_empty():quit(2);return
	DirAccess.make_dir_recursive_absolute(output)
	DisplayServer.window_set_size(Vector2i(1280,900));root.size=Vector2i(1280,900)
	var scene=load("res://scenes/kenney_visual_slice.tscn").instantiate();root.add_child(scene)
	await process_frame
	scene.actor.position=Vector2(531,900);scene.logical_camera=scene.actor.position;scene.camera.position=scene.actor.position
	scene.refresh_focus();scene.toggle_feedback()
	await capture(output.path_join("01-baseline.png"))
	scene.toggle_feedback();scene.interact()
	await capture(output.path_join("02-paper-feedback.png"))
	scene.close_note();scene.actor.position=scene.get_object("lamp").stand;scene.logical_camera=scene.actor.position;scene.camera.position=scene.actor.position;scene.refresh_focus();scene.interact()
	await capture(output.path_join("03-lamp-feedback.png"))
	scene.toggle_pixels();await capture(output.path_join("04-480-comparison.png"))
	DisplayServer.window_set_size(Vector2i(390,844));root.size=Vector2i(390,844)
	await capture(output.path_join("05-compact-layout.png"))
	scene.toggle_journal();await capture(output.path_join("06-locked-journal.png"))
	DisplayServer.window_set_size(Vector2i(1280,900));root.size=Vector2i(1280,900)
	await capture(output.path_join("07-locked-journal-desktop.png"))
	print("KENNEY_VISUAL_CAPTURE_COMPLETE");quit(0)
