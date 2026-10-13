extends SceneTree
## Short actual production-view review before any additional cleanup art request.
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var out := OS.get_environment("BUCT_COURT_NORTH_EVIDENCE_DIR").path_join("normal-first")
	if DisplayServer.get_name() == "headless" or not out.is_absolute_path():
		push_error("Actual renderer required")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(out)
	var app = load("res://campuses/buct/scenes/playable.tscn").instantiate()
	root.add_child(app)
	await process_frame
	if not is_instance_valid(app.court_north) or not app.court_north.body_texture.get_image().has_mipmaps():
		push_error("Production body/import unavailable")
		quit(3)
		return
	app.visitor.set_physics_process(false)
	app.visitor.position = Vector2(612,478)
	if not app.is_walkable(app.visitor.position):
		push_error("Initial normal view is outside the accepted road")
		quit(4)
		return
	app.camera.position = app._walking_camera_position()
	app.camera.reset_smoothing()
	for i in range(5):
		await process_frame
		await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join("normal-east-road.png"))
	app.visitor.position = Vector2(419,478)
	app.camera.position = app._walking_camera_position()
	app.camera.reset_smoothing()
	for i in range(4):
		await process_frame
		await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join("normal-west-road.png"))
	app.toggle_overview()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join("full-map-overview.png"))
	print("COURT_NORTH_FIRST_NORMAL_CAPTURED three production frames")
	app.queue_free()
	await process_frame
	quit()
