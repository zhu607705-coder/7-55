extends SceneTree
## Exercise the visible controls through ordinary engine input, not pressed.emit().
const Scene = preload("res://transition.tscn")
const Timeline = preload("res://timeline.gd")
var checks := 0
var failures := 0
var scene: Node3D
var reasons: Array[String] = []
var require_rendering := false
var output := ""

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg == "--require-rendering": require_rendering = true
		if arg.begins_with("--output="): output = arg.trim_prefix("--output=")
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error("TEST FAILED: " + label)
	else: print("PASS ", label)

func frames(count := 2) -> void:
	for i in count: await process_frame

func button(prefix: String) -> Button:
	for node in scene.find_children("*", "Button", true, false):
		if node.text.begins_with(prefix): return node
	return null

func touch(point: Vector2, down: bool, canceled := false) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 0; event.position = point; event.pressed = down; event.canceled = canceled
	Input.parse_input_event(event); await frames()

func tap(control: Control) -> void:
	var point := control.get_global_rect().get_center()
	await touch(point, true); await touch(point, false)

func mouse(control: Control) -> void:
	var point := control.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point; motion.global_position = point
	Input.parse_input_event(motion); await frames()
	for down in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point; event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT; event.pressed = down
		Input.parse_input_event(event); await frames()

func capture(name: String) -> void:
	if not require_rendering or output.is_empty(): return
	await RenderingServer.frame_post_draw
	var pixels := root.get_texture().get_image()
	check(pixels != null and not pixels.is_empty() and pixels.get_size() == root.size, "actual rendered dimensions: " + name)
	if pixels != null and not pixels.is_empty(): check(pixels.save_png(output.path_join(name + ".png")) == OK, "save actual pixels: " + name)

func framing() -> void:
	var heading: Control = scene.find_child("PreviewHeading", true, false)
	var controls: Control = scene.find_child("PreviewControls", true, false)
	var blocked: Array[float] = []
	for sample_index in 103:
		var second := float(sample_index) / 10.0
		scene.set_time(second)
		var bounds := Rect2(); var first := true
		for mesh: MeshInstance3D in scene._actor.find_children("*", "MeshInstance3D", true, false):
			for endpoint in 8:
				var point: Vector3 = mesh.global_transform * mesh.get_aabb().get_endpoint(endpoint)
				var screen: Vector2 = scene._camera.unproject_position(point)
				if first: bounds = Rect2(screen, Vector2.ZERO); first = false
				else: bounds = bounds.expand(screen)
		if bounds.intersects(heading.get_global_rect()) or bounds.intersects(controls.get_global_rect()) or not Rect2(Vector2.ZERO, Vector2(root.size)).encloses(bounds): blocked.append(second)
	check(blocked.is_empty(), "whole actor stays in viewport outside HUD " + str(root.size) + " blocked_seconds=" + str(blocked))
	scene.set_time(Timeline.DURATION)

func run() -> void:
	if require_rendering and (DisplayServer.get_name() == "headless" or RenderingServer.get_video_adapter_name().is_empty()):
		push_error("Real graphical renderer required; no headless visual evidence."); quit(2); return
	if not output.is_empty(): DirAccess.make_dir_recursive_absolute(output)
	print("PHONE_CAMPUS_INPUT_RENDERER display=", DisplayServer.get_name(), " adapter=", RenderingServer.get_video_adapter_name(), " method=", RenderingServer.get_current_rendering_method())
	scene = Scene.instantiate(); scene.autoplay = false; root.add_child(scene); await frames(5)
	scene.ended.connect(func(reason: String): reasons.append(reason))
	for dimensions in [Vector2i(390, 844), Vector2i(844, 390), Vector2i(1280, 720)]:
		root.size = dimensions; await frames(5)
		check(root.get_visible_rect().size == Vector2(dimensions), "actual input viewport " + str(dimensions))
		await tap(button("重播"))
		check(scene.running and not scene.paused and scene.playhead > 0 and scene.playhead < 1, "touch replay starts one ordinary timeline " + str(dimensions))
		await tap(button("暂停")); var frozen: float = scene.playhead
		await create_timer(.08).timeout
		check(scene.paused and scene.playhead == frozen, "touch pause freezes timeline")
		await capture("paused-%dx%d" % [dimensions.x, dimensions.y])
		await tap(button("继续")); await create_timer(.08).timeout
		check(not scene.paused and scene.playhead > frozen, "touch resume advances timeline")
		var before := reasons.size()
		await tap(button("跳过")); await tap(button("跳过"))
		check(not scene.running and scene.playhead == Timeline.DURATION and reasons.size() == before + 1 and reasons.back() == "skipped", "repeated touch skip ends exactly once")
		await tap(button("重播")); await tap(button("减弱"))
		check(scene.reduced_motion and not scene.running and scene._actor.position == Timeline.ARRIVAL, "touch reduced motion settles actual actor")
		await tap(button("减弱"))
		check(not scene.reduced_motion and not scene.running and scene.playhead == Timeline.DURATION, "touch reduced off does not restart")
		await tap(button("重播")); await tap(button("暂停"))
		frozen = scene.playhead; before = reasons.size()
		var point: Vector2 = button("重播").get_global_rect().get_center()
		await touch(point, true); await touch(point, false, true)
		check(scene.paused and scene.playhead == frozen and reasons.size() == before, "cancelled touch cannot activate replay")
		point = button("减弱").get_global_rect().get_center()
		await touch(point, true); await touch(point, false, true)
		check(not scene.reduced_motion and not button("减弱").button_pressed and scene.paused, "cancelled touch cannot change reduced-motion setting")
		await tap(button("跳过"))
		await capture("settled-%dx%d" % [dimensions.x, dimensions.y])
		framing()
	await mouse(button("重播")); check(scene.running and scene.playhead < 1, "ordinary mouse replay")
	await mouse(button("暂停")); check(scene.paused, "ordinary mouse pause")
	await mouse(button("继续")); check(not scene.paused, "ordinary mouse resume")
	await mouse(button("跳过")); check(not scene.running and scene.playhead == Timeline.DURATION, "ordinary mouse skip")
	check(root.get_node_or_null("State") == null, "no campaign State or save authority")
	scene.queue_free(); await frames(3)
	check(get_processed_tweens().is_empty(), "ordinary-input lifecycle leaves no tween")
	print("PHONE_CAMPUS_INPUT checks=%d failures=%d real_input_events=true graphical=%s physical_device=false" % [checks, failures, require_rendering])
	quit(1 if failures else 0)
