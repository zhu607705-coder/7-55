extends SceneTree

const Timeline = preload("res://timeline.gd")
const Scene = preload("res://transition.tscn")
var checks := 0
var failures := 0
var reasons: Array[String] = []

func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + label)

func _initialize() -> void:
	call_deferred("run_tests")

func run_tests() -> void:
	var start := Timeline.sample(0.0)
	check(start.flat and start.scale.z < 0.02, "starts as a thin planar icon")
	check(is_equal_approx(start.rotation.x, -PI / 2.0), "icon lies on phone screen")
	var standing := Timeline.sample(2.5)
	check(standing.scale.is_equal_approx(Vector3.ONE) and standing.rotation.is_zero_approx(), "same mesh becomes upright volume")
	check(Timeline.sample(3.5).position.y > 1.5, "real 3D jump above the phone")
	check(Timeline.sample(4.075).scale.y < 0.8, "landing squash is present")
	check(Timeline.sample(4.3).position.y >= Timeline.LANDING.y, "rebound never passes through the floor")
	check(Timeline.sample(Timeline.DURATION).position == Timeline.ARRIVAL, "ends at the miniature gate")
	check(Timeline.sample(-100.0).time == 0.0 and Timeline.sample(100.0).time == Timeline.DURATION, "seek clamps to bounds")
	for second in [0.0, 2.0, 4.0, 8.0]:
		check(Timeline.sample(second, true).position == Timeline.ARRIVAL, "reduced motion is a static endpoint")
	for boundary in Timeline.PHASE_ENDS:
		var before := Timeline.sample(boundary - 0.0001)
		var after := Timeline.sample(boundary + 0.0001)
		check(before.position.distance_to(after.position) < 0.002, "position continuity at %s" % boundary)
		check(before.camera_position.distance_to(after.camera_position) < 0.002, "camera continuity at %s" % boundary)
		check(before.camera_target.distance_to(after.camera_target) < 0.002, "look continuity at %s" % boundary)
	for frame in range(613):
		var pose := Timeline.sample(frame / 60.0)
		check(pose.position.is_finite() and pose.camera_position.is_finite() and pose.scale.is_finite(), "finite timeline frame %d" % frame)
		check(pose.scale.x > 0 and pose.scale.y > 0 and pose.scale.z > 0, "non-singular mesh frame %d" % frame)
	# Sampling is independent of frame rate or previous state.
	for rate in [24, 30, 60, 120]:
		check(Timeline.sample(float(rate * 5) / rate) == Timeline.sample(5.0), "same pose at %d fps" % rate)
	var scene = Scene.instantiate()
	scene.autoplay = false
	root.add_child(scene)
	await process_frame
	scene.ended.connect(func(reason: String): reasons.append(reason))
	check(scene.get_node("PhoneUI430x860").size == Vector2i(430, 860), "phone keeps canonical 1:2 texture")
	check(root.get_node_or_null("State") == null, "no story State autoload")
	check(not ProjectSettings.has_setting("autoload/State"), "isolated project has no save authority")
	check(ProjectSettings.get_setting("rendering/renderer/rendering_method") == "gl_compatibility", "Compatibility renderer preserved")
	check(scene._camera.attributes == null, "no unsupported depth-of-field dependency")
	scene.set_time(4.0)
	var path_top: float = scene.get_node("MiniaturePath").position.y + scene.get_node("MiniaturePath").mesh.size.y / 2.0
	check(scene._shadow.position.y > path_top, "soft contact shadow sits above the opaque receiving surface")
	scene.play()
	check(scene.running and scene.playhead == 0.0, "replay starts from zero")
	scene.set_paused(true)
	var frozen: float = scene.playhead
	await create_timer(0.06).timeout
	check(scene.playhead == frozen and scene.paused, "pause freezes the only clock")
	scene.set_paused(false)
	await create_timer(0.06).timeout
	check(scene.playhead > frozen, "explicit resume advances clock")
	scene._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(scene.paused, "losing focus pauses without automatic restart")
	var replay_button: Button = scene.find_children("*", "Button", true, false)[0]
	replay_button.grab_focus()
	var space := InputEventKey.new()
	space.keycode = KEY_SPACE
	space.pressed = true
	Input.parse_input_event(space)
	await process_frame
	check(not scene.paused and scene.playhead > 0.0, "Space resumes, not replays, with Replay button focused")
	Input.parse_input_event(space)
	await process_frame
	check(scene.paused, "Space pauses with Replay button focused")
	space.pressed = false
	Input.parse_input_event(space)
	scene.play()
	scene.play()
	scene.play()
	check(get_processed_tweens().filter(func(tween): return tween.is_valid()).size() == 1, "repeated replay leaves one live tween")
	scene.skip()
	scene.skip()
	check(reasons == ["skipped"], "repeated skip completes once")
	check(scene.playhead == Timeline.DURATION and not scene.running, "skip restores settled endpoint")
	check(get_processed_tweens().filter(func(tween): return tween.is_valid()).is_empty(), "skip kills pending timeline")
	await process_frame
	check(get_processed_tweens().is_empty(), "killed timelines leave the tree on next frame")
	scene.play()
	scene.cancel()
	scene.cancel()
	check(reasons == ["skipped", "cancelled"], "cancel emits once")
	frozen = scene.playhead
	await create_timer(0.06).timeout
	check(scene.playhead == frozen, "cancel blocks stale callbacks")
	scene.play()
	scene.set_reduced_motion(true)
	check(reasons.back() == "reduced_motion" and not scene.running, "reduce motion interrupts safely")
	check(scene._actor.position == Timeline.ARRIVAL, "reduce motion skips movement")
	scene.set_reduced_motion(false)
	check(scene.playhead == Timeline.DURATION and not scene.running, "disabling reduced motion keeps settled frame")
	var reduced_count := reasons.size()
	scene.skip()
	check(scene.playhead == Timeline.DURATION and reasons.size() == reduced_count, "OFF then Skip remains a settled idempotent endpoint")
	scene.play()
	# Advance the actual bound Tween without a ten-second wall-clock delay.
	scene._tween.custom_step(Timeline.DURATION + 0.01)
	check(reasons.back() == "completed" and not scene.running, "normal tween completes exactly once")
	var count := reasons.size()
	scene.skip()
	check(reasons.size() == count, "skip after completion cannot emit twice")
	for dimensions in [Vector2i(1280, 720), Vector2i(390, 844), Vector2i(844, 390)]:
		root.size = dimensions
		await process_frame
		await process_frame
		var controls: Array[Node] = scene.find_children("*", "Button", true, false)
		check(root.get_visible_rect().size == Vector2(dimensions), "actual unscaled viewport matches window %s" % dimensions)
		for control in controls:
			var rect: Rect2 = control.get_global_rect()
			check(rect.size.y >= 44.0, "touch target height %s" % dimensions)
			check(rect.position.x >= 0.0 and rect.end.x <= dimensions.x + 1.0, "controls within width %s" % dimensions)
			check(rect.position.y >= 0.0 and rect.end.y <= dimensions.y + 1.0, "controls within height %s" % dimensions)
	scene.play()
	scene.queue_free()
	await process_frame
	await process_frame
	check(get_processed_tweens().is_empty(), "freeing scene cleans all tweens")
	check(reasons.size() == count, "teardown never emits stale completion")
	print("PHONE_CAMPUS_TESTS checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
