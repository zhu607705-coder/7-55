extends SceneTree
## Actual normal gameplay followed by fixed-camera GPU pixel/short-motion proof.
var campus: Node2D
var lake: Node2D
var out := ""
var failures: Array[String] = []
var checks := 0
var records: Dictionary = {}

func _initialize() -> void: run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:failures.append(label);push_error(label)
func frame() -> void:
	await process_frame; await process_frame; await RenderingServer.frame_post_draw
func tick() -> void:await physics_frame;await process_frame
func save(name: String) -> void:
	await frame()
	check(root.get_texture().get_image().save_png(out.path_join(name)) == OK, "Save GPU frame " + name)

func run() -> void:
	out = OS.get_environment("BUCT_LIUHU_OUTPUT")
	if out.is_empty():push_error("GPU proof requires an explicit workspace evidence directory");quit(2);return
	campus = load("res://campuses/buct_changping/scenes/playable.tscn").instantiate();root.add_child(campus);await frame()
	lake = campus.lake_surface
	check(is_instance_valid(lake), "Actual GPU production water object installed")
	if not is_instance_valid(lake):quit(1);return
	# Use the unchanged real guide for the normal game screenshot. No position
	# write or synthetic speed is used in this source-to-library travel segment.
	campus.start_guide()
	var deadline := Time.get_ticks_msec() + 22000
	var illegal := 0; var travel_frames := 0
	while campus.guide_active and Time.get_ticks_msec() < deadline:
		await tick(); travel_frames += 1
		if not campus.is_walkable(campus.visitor.position):illegal += 1
	check(not campus.guide_active and campus.visitor.position.distance_to(Vector2(566,816)) < 8, "Actual guide reaches original library endpoint")
	check(campus.visited.size() == 3 and illegal == 0, "Only original POIs, no water entry")
	campus.close_info();campus.current_path.clear();campus.zoom_level = 2.1
	await create_timer(0.5).timeout;await save("gameplay-liuhu-library-view.png")
	records.normal_gameplay = {"actual_feet":[campus.visitor.position.x,campus.visitor.position.y],"travel_physics_frames":travel_frames,"illegal_feet_frames":illegal,"visits":campus.visited.duplicate(),"position_writes_during_guide":0}
	# Fixed camera is a local visual fixture, clearly distinct from normal play.
	campus.visitor.set_physics_process(false);campus.visitor.hide();campus.set_process(false)
	campus.ui.hide();campus.pin_layer.hide();campus.canopy_locator.hide();campus.route_visual.hide()
	campus.camera.position_smoothing_enabled = false
	campus.camera.zoom = Vector2.ONE * 4.0
	campus.camera.position = Vector2(420,805);campus.camera.reset_smoothing()
	lake.set_process(false);lake.set_animation_enabled(false);lake.set_selected(false)
	await frame()
	var transform: Transform2D = campus.get_canvas_transform()
	records.viewport = [root.size.x,root.size.y]
	records.source_to_screen = {"x":[transform.x.x,transform.x.y],"y":[transform.y.x,transform.y.y],"origin":[transform.origin.x,transform.origin.y]}
	var material: Material = lake.static_ground.material
	lake.hide();lake.static_ground.material = null
	await save("gpu-original-baseline.png")
	lake.show();lake.static_ground.material = material
	await save("gpu-static-reconstructed.png")
	for repeat in range(3):
		lake.set_animation_enabled(true);lake.set_wave_time(1.25 + repeat * 1.7);await frame()
		lake.set_animation_enabled(false)
		await save("gpu-static-toggle-%d.png" % repeat)
	lake.hide();await save("gpu-water-hidden-real-cutout.png");lake.show()
	lake.set_animation_enabled(true)
	for phase in [0.0,1.7,4.2,6.8]:
		lake.set_wave_time(phase)
		await save("gpu-motion-%.1f.png" % phase)
	var crop_start: Vector2 = transform * Vector2(300,742)
	var crop_end: Vector2 = transform * Vector2(498,875)
	var crop := Rect2i(Vector2i(crop_start),Vector2i(crop_end-crop_start))
	check(Rect2i(Vector2i.ZERO, root.size).encloses(crop), "Local water recording fully inside actual viewport")
	DirAccess.make_dir_recursive_absolute(out.path_join("water-motion-frames"))
	var capture_frames := 105
	for index in range(capture_frames):
		lake.set_wave_time(index / 15.0)
		await frame()
		var image: Image = root.get_texture().get_image().get_region(crop)
		if image.save_png(out.path_join("water-motion-frames/frame-%03d.png" % index)) != OK:
			check(false,"Cannot save bounded motion recording frame");break
	records.local_video = {"frames":capture_frames,"fps":15,"seconds":7,"source_roi":[300,742,198,133],"screen_crop":[crop.position.x,crop.position.y,crop.size.x,crop.size.y],"method":"Actual Godot GPU shader at deterministic 1/15-second phases. Fixed local camera, source art unchanged. No simulated/repainted water video."}
	records.checks = checks;records.failures = failures
	var file := FileAccess.open(out.path_join("gpu-capture.json"),FileAccess.WRITE)
	if file == null:check(false,"Cannot write GPU capture metadata")
	else:file.store_string(JSON.stringify(records,"  ") + "\n");file.close()
	print("BUCT_LIUHU_GPU_CAPTURE checks=%d failures=%d" % [checks,failures.size()])
	campus.queue_free();await process_frame;await process_frame
	quit(0 if failures.is_empty() else 1)
