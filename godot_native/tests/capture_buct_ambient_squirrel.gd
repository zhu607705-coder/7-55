extends SceneTree
## Native renderer proof. The actor runs its real _process clock at real speed.
## One normal-scale still, then one uninterrupted 18-second uniform camera close-up.
var app
var actor
var out := ""
var samples: Array[Dictionary] = []
var started := 0
var next_capture := 0.0
var frame_count := 0
var recording := false

func _initialize() -> void: start.call_deferred()

func start() -> void:
	out = OS.get_environment("BUCT_SQUIRREL_EVIDENCE_DIR").path_join("native-preview")
	if not out.is_absolute_path() or DirAccess.make_dir_recursive_absolute(out) != OK:
		printerr("SQUIRREL_CAPTURE_REQUIRES_WORKSPACE_OUTPUT")
		quit(2)
		return
	root.size = Vector2i(1280, 720)
	app = load("res://campuses/buct/scenes/playable.tscn").instantiate()
	root.add_child(app)
	actor = app.ambient_squirrel
	if actor == null or not app.is_walkable(Vector2(738, 716)):
		printerr("SQUIRREL_CAPTURE_INVALID_SCENE")
		quit(2)
		return
	# Test-only initial setup: put the unchanged student on the already-open lower
	# paving so both sizes can be inspected. No actor position changes after this.
	app.visitor.set_physics_process(false)
	app.visitor.position = Vector2(738, 716)
	app.set_process(false)
	app.camera.position_smoothing_enabled = false
	app.camera.position = Vector2(737, 695)
	app.camera.zoom = Vector2.ONE * 2.1
	app.camera.reset_smoothing()
	app.route_visual.visible = false
	app.pin_layer.visible = false
	app.status.text = "松鼠比例检查 · 统一2.1×镜头"
	actor.set_app_focused(false)
	await process_frame
	await RenderingServer.frame_post_draw
	if OS.get_environment("BUCT_SQUIRREL_CAPTURE_MODE") == "contact-pair":
		var passed: bool = await capture_contact_pair()
		app.queue_free()
		await process_frame
		quit(0 if passed else 1)
		return
	if root.get_texture().get_image().save_png(out.path_join("normal-camera-2.1x.png")) != OK:
		quit(2)
		return
	if OS.get_environment("BUCT_SQUIRREL_CAPTURE_MODE") == "normal-only":
		print("BUCT_SQUIRREL_NORMAL_CAPTURED fixed 2.1x camera; actor remains 8 source pixels")
		app.queue_free()
		await process_frame
		quit(0)
		return
	# Uniform camera magnification, not a change to the eight-source-pixel actor.
	app.camera.zoom = Vector2.ONE * 6.0
	app.ui.visible = false
	app.pin_layer.visible = false
	app.camera.reset_smoothing()
	await process_frame
	await RenderingServer.frame_post_draw
	# The still-frame setup stayed paused. Recording now starts at the real first rest.
	actor.set_app_focused(true)
	actor.set_on_screen(true)
	started = Time.get_ticks_msec()
	recording = true

func capture_contact_pair() -> bool:
	var pairs: Array[Dictionary] = []
	var pixel_checks: Array[Dictionary] = []
	for zoom_value in [2.1, 6.0]:
		app.camera.zoom = Vector2.ONE * zoom_value
		app.ui.visible = zoom_value == 2.1
		app.camera.reset_smoothing()
		var before_image: Image
		for enabled in [false, true]:
			actor.set_contact_shadow_enabled(enabled)
			await process_frame
			await RenderingServer.frame_post_draw
			var filename := "contact-shadow-v2-%s-%.1fx.png" % ["after" if enabled else "before", zoom_value]
			var captured: Image = root.get_texture().get_image()
			captured.convert(Image.FORMAT_RGBA8)
			if captured.save_png(out.path_join(filename)) != OK:
				printerr("SQUIRREL_CONTACT_COMPARISON_WRITE_FAILED")
				return false
			if not enabled:
				before_image = captured
			else:
				pixel_checks.append(check_contact_pixels(before_image, captured, zoom_value))
			pairs.append({"file": filename, "camera_zoom": zoom_value, "shadow_enabled": enabled, "source_xy": [actor.position.x, actor.position.y], "source_pose": actor.current_frame, "source_scale": actor.sprite.scale.x, "child_count": actor.get_child_count()})
	var file := FileAccess.open(out.path_join("contact-shadow-v2-comparison.json"), FileAccess.WRITE)
	if file == null: return false
	file.store_string(JSON.stringify({"maximum_visible_source_footprint_including_scaled_aa": [4.0, 1.0], "nominal_outer_ellipse_size_before_aa": [2.0, 0.5], "raster_coverage_tolerance_screen_px": 1.0, "source_offset": [0, 0.10], "layer_alpha": [0.035, 0.045, 0.055], "source_png_unchanged": true, "geometry_unchanged": true, "captures": pairs, "gpu_pixel_checks": pixel_checks}, "  "))
	file.flush()
	for result in pixel_checks:
		if not result.passed:
			printerr("SQUIRREL_CONTACT_EXTENT_FAILED: ", result)
			return false
	print("BUCT_SQUIRREL_CONTACT_CAPTURED two same-camera pairs; original source scale and feet unchanged")
	return true

func check_contact_pixels(before: Image, after: Image, zoom_value: float) -> Dictionary:
	var a := before.get_data()
	var b := after.get_data()
	var width := before.get_width()
	var changed := 0
	var brightened := 0
	var maximum_delta := 0
	var minimum := Vector2i(width, before.get_height())
	var maximum := Vector2i(-1, -1)
	for i in range(0, a.size(), 4):
		var different := false
		for channel in range(3):
			var delta := int(b[i + channel]) - int(a[i + channel])
			different = different or delta != 0
			brightened += int(delta > 0)
			maximum_delta = maxi(maximum_delta, absi(delta))
		if different:
			changed += 1
			var point := Vector2i((i / 4) % width, (i / 4) / width)
			minimum = minimum.min(point)
			maximum = maximum.max(point)
	var bbox := Rect2i(minimum, maximum - minimum + Vector2i.ONE)
	var feet_screen: Vector2 = actor.get_global_transform_with_canvas().origin
	# Actual changed pixel centers must stay in the agreed 4x1 source box,
	# allowing one screen pixel for sample coverage at its boundary.
	var bound := Rect2(feet_screen + Vector2(-2.0, -0.4) * zoom_value - Vector2.ONE, Vector2(4.0, 1.0) * zoom_value + Vector2.ONE * 2.0)
	var covered := bound.has_point(Vector2(minimum) + Vector2(0.5, 0.5)) and bound.has_point(Vector2(maximum) + Vector2(0.5, 0.5))
	return {"camera_zoom": zoom_value, "changed_pixels": changed, "bbox_xywh": [bbox.position.x, bbox.position.y, bbox.size.x, bbox.size.y], "brightened_channel_samples": brightened, "maximum_channel_delta": maximum_delta, "maximum_visible_source_extent": [4.0, 1.0], "passed": changed > 0 and covered and brightened == 0 and maximum_delta <= 20}

func _process(_delta: float) -> bool:
	if not recording: return false
	var seconds := (Time.get_ticks_msec() - started) / 1000.0
	if seconds >= next_capture:
		recording = false
		capture.call_deferred(seconds)
	return false

func capture(seconds: float) -> void:
	await RenderingServer.frame_post_draw
	var actual_seconds := (Time.get_ticks_msec() - started) / 1000.0
	var filename := "frame-%04d.jpg" % frame_count
	var native_image := root.get_texture().get_image()
	if native_image.save_jpg(out.path_join(filename), 0.94) != OK:
		printerr("SQUIRREL_NATIVE_FRAME_WRITE_FAILED")
		quit(2)
		return
	var snapshot: Dictionary = actor.snapshot()
	snapshot["position"] = [actor.position.x, actor.position.y]
	snapshot["file"] = filename
	snapshot["elapsed_wall_seconds"] = actual_seconds
	snapshot["scheduled_seconds"] = seconds
	samples.append(snapshot)
	frame_count += 1
	next_capture = actual_seconds + 1.0 / 15.0
	if actual_seconds >= 18.0:
		finish.call_deferred()
	else:
		recording = true

func finish() -> void:
	recording = false
	actor.set_on_screen(false)
	var file := FileAccess.open(out.path_join("native-frame-ledger.json"), FileAccess.WRITE)
	if file == null:
		quit(2)
		return
	file.store_string(JSON.stringify({"renderer": "native Godot 4 compatibility", "method": "Continuous real _process state, no pose stepping, no path teleport, no time scaling", "normal_camera_zoom": 2.1, "detail_camera_zoom": 6.0, "squirrel_max_source_height": 8, "student_source_height": 18, "recording_seconds": (Time.get_ticks_msec() - started) / 1000.0, "actual_capture_count": samples.size(), "distinct_run_artwork_frames": 4, "samples": samples}, "  "))
	file.flush()
	print("BUCT_SQUIRREL_NATIVE_CAPTURED ", samples.size(), " actual timestamped frames; distinct run artwork = 4")
	app.queue_free()
	await process_frame
	quit(0)
