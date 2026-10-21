extends SceneTree
func _initialize() -> void:call_deferred("run")
func capture(path: String) -> void:
	for i in range(5):await process_frame
	await RenderingServer.frame_post_draw
	var image:=root.get_texture().get_image()
	if image.is_empty() or image.save_png(path)!=OK:
		push_error("Screenshot failed: "+path)
		quit(1)
func run() -> void:
	if DisplayServer.get_name()=="headless":quit(2);return
	var output:=OS.get_environment("DORM_CAPTURE_DIR")
	if output.is_empty():quit(2);return
	DirAccess.make_dir_recursive_absolute(output)
	DisplayServer.window_set_size(Vector2i(1440,1080));root.size=Vector2i(1440,1080)
	var view: Node2D=load("res://scenes/dorm_modular_preview.tscn").instantiate()
	root.add_child(view)
	await capture(output.path_join("01-source-candidate.png"))
	view.set_exploded(true)
	await capture(output.path_join("02-separated-objects.png"))
	view.set_exploded(false)
	# Close views inspect four true source poses, not separately generated paper art.
	view.reference.hide();view.candidate.hide()
	var paper: Node2D=load("res://scripts/objects/dorm_practice_paper.gd").new()
	root.add_child(paper);paper.position=Vector2(720,550);paper.scale=Vector2.ONE*8
	paper.set_process(false)
	for frame in [-1,0,1,2,3]:
		paper.frame=frame;paper.queue_redraw()
		await capture(output.path_join("paper-"+str(frame)+".png"))
	print("DORM_CAPTURE_COMPLETE")
	quit(0)
