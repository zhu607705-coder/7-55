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
	# Export canonical code-native artwork directly, not a screenshot crop or
	# background-removal pass. The source generator's contract is 64x50.
	var export_view := SubViewport.new()
	export_view.size=Vector2i(64,50)
	export_view.transparent_bg=true
	export_view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	export_view.canvas_item_default_texture_filter=Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	root.add_child(export_view)
	var export_paper: Node2D=load("res://scripts/objects/dorm_practice_paper.gd").new()
	export_view.add_child(export_paper)
	export_paper.position=Vector2(32,25)
	export_paper.set_process(false)
	for frame in [-1,0,1,2,3]:
		export_paper.frame=frame
		export_paper.queue_redraw()
		for i in range(3):await process_frame
		await RenderingServer.frame_post_draw
		var sprite: Image=export_view.get_texture().get_image()
		if sprite.get_size()!=Vector2i(64,50) or sprite.get_pixel(0,0).a!=0 or sprite.get_pixel(25,20).a<.9:
			push_error("Canonical paper export size/alpha failed")
			quit(1);return
		if sprite.save_png(output.path_join("canonical-paper-"+str(frame)+".png"))!=OK:
			push_error("Canonical paper export write failed")
			quit(1);return
	print("DORM_CANONICAL_ALPHA_EXPORT 5 poses 64x50")
	print("DORM_CAPTURE_COMPLETE")
	quit(0)
