extends SceneTree
## Real viewport capture only. Never manufacture screenshots with the dummy renderer.

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	if DisplayServer.get_name() == "headless" or RenderingServer.get_video_adapter_name().is_empty():
		push_error("A real graphical renderer is required; headless is not visual evidence.")
		quit(1)
		return
	var directory := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):
			directory = arg.trim_prefix("--output=")
	if directory.is_empty() or DirAccess.make_dir_recursive_absolute(directory) != OK:
		push_error("Provide a writable --output directory.")
		quit(1)
		return
	var scene = load("res://transition.tscn").instantiate()
	scene.autoplay = false
	root.add_child(scene)
	var captures: Array[Dictionary] = []
	for dimensions in [Vector2i(1280, 720), Vector2i(390, 844), Vector2i(844, 390)]:
		root.size = dimensions
		for second in [0.0, 2.5, 3.5, 4.15, 7.0, 10.2]:
			scene.set_time(second)
			await process_frame
			await process_frame
			await RenderingServer.frame_post_draw
			var frame := root.get_texture().get_image()
			if frame == null or frame.is_empty() or frame.get_size() != dimensions:
				push_error("Renderer returned no pixels or the wrong actual viewport dimensions.")
				quit(1)
				return
			var filename := "%dx%d_%05.2f.png" % [dimensions.x, dimensions.y, second]
			if frame.save_png(directory.path_join(filename)) != OK:
				quit(1)
				return
			captures.append({"file": filename, "seconds": second, "width": frame.get_width(), "height": frame.get_height()})
	var manifest := {"engine": Engine.get_version_info().string, "display": DisplayServer.get_name(),
		"adapter": RenderingServer.get_video_adapter_name(), "renderer": RenderingServer.get_current_rendering_method(),
		"kind": "actual Godot viewport; not physical-device acceptance", "captures": captures}
	var file := FileAccess.open(directory.path_join("capture.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest, "\t"))
	quit(0)
