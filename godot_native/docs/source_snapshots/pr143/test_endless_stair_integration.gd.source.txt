extends SceneTree
## Real native autoload, input routing and lifecycle regression checks.
## Run with the XDG isolation used by tools/validate_native.mjs.
const Model = preload("res://scripts/games/chapter4_endless_stair_model.gd")
const SCENE_PATH := "res://scenes/chapter4_endless_stair_preview.tscn"
const SAVE_PATHS := ["user://save.json", "user://save.previous.json", "user://save.json.tmp"]

class CancelRoutingObserver extends Node:
	var received := 0
	func _unhandled_input(event: InputEvent) -> void:
		if event is InputEventScreenTouch and event.canceled:
			received += 1

var checks := 0
var failures := 0
var exits := 0
var completions: Array[Dictionary] = []
var campaign_before: Dictionary
var saves_before: Dictionary

func _initialize() -> void:
	run.call_deferred()

func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error("ENDLESS_STAIR_INTEGRATION: " + label)

func _campaign_snapshot() -> Dictionary:
	var state := root.get_node_or_null("State")
	if state == null:
		return {}
	var progression: Dictionary = state.get("d")
	var formal: Dictionary = state.get("formal_snapshot")
	var result: Dictionary = state.get("last_result")
	return {"instance": state.get_instance_id(), "d": progression.duplicate(true),
		"developer_mode": state.get("developer_mode"),
		"formal_snapshot": formal.duplicate(true), "last_result": result.duplicate(true)}

func _save_snapshot() -> Dictionary:
	var snapshot := {}
	for path: String in SAVE_PATHS:
		var exists := FileAccess.file_exists(path)
		snapshot[path] = {"exists": exists,
			"bytes": FileAccess.get_file_as_bytes(path) if exists else PackedByteArray(),
			"modified": FileAccess.get_modified_time(path) if exists else 0}
	return snapshot

func _check_isolation(label: String) -> void:
	check(_campaign_snapshot() == campaign_before, label + ": full State.d and campaign metadata unchanged")
	check(_save_snapshot() == saves_before, label + ": formal, backup and temporary save bytes unchanged")

func _key(code: Key, pressed: bool) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	return event

func _touch(index: int, point: Vector2, pressed: bool, canceled: bool = false) -> InputEventScreenTouch:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = point
	event.pressed = pressed
	event.canceled = canceled
	return event

func _dispatch(event: InputEvent) -> void:
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func _release_keys() -> void:
	for code: Key in [KEY_A, KEY_D, KEY_LEFT, KEY_RIGHT, KEY_SPACE, KEY_ESCAPE]:
		_dispatch(_key(code, false))

func _fresh(game) -> void:
	_release_keys()
	game.demo_mode = false
	game._start()
	game._present(0.0)
	root.gui_release_focus()

func _test_touch_cancellation(game, host: Node) -> void:
	var observer := CancelRoutingObserver.new()
	host.add_child(observer)
	_fresh(game)
	_dispatch(_touch(90, Vector2(5, 5), false, true))
	check(observer.received == 1, "unowned cancellation remains available to host input routing")
	for canceled_pressed: bool in [false, true]:
		_fresh(game)
		var actor_point: Vector2 = game.camera.unproject_position(game.actor.position)
		actor_point *= game.size / Vector2(game.viewport.size)
		var origin: Vector2 = actor_point + Vector2(110, 25)
		_dispatch(_touch(21, origin, true))
		check(game.primary_touch == 21 and game.touch_axis != 0, "real primary touch acquires steering")
		game.queued_jump = true
		game._adjust_input_mask(Model.RIGHT | Model.JUMP)
		var observed_before: int = observer.received
		_dispatch(_touch(21, origin, canceled_pressed, true))
		check(game.primary_touch == -99 and game.touch_axis == 0 and not game.queued_jump
			and game.held_screen_axis == 0 and game.held_route_direction == 0,
			"primary cancellation clears every queued and held input")
		check(observer.received == observed_before, "owned cancellation is consumed after clearing steering")
		var tick_before: int = game.model.tick
		game._physics_process(Model.DT)
		check(game.model.tick == tick_before + 1 and int(game.model.input_log.back()) == 0
			and game.model.player_grounded, "cancellation produces a neutral tick without a tap-jump")
		_dispatch(_touch(21, origin, false))
		check(not game.queued_jump and game.primary_touch == -99, "late release cannot resurrect a canceled tap")
		game._unhandled_input(_touch(22, origin, true, true))
		check(game.primary_touch == -99 and not game.queued_jump,
			"direct canceled-and-pressed input cannot acquire a new finger")
	_fresh(game)
	var point := Vector2(1000, 400)
	_dispatch(_touch(23, point, true))
	var axis: int = game.touch_axis
	_dispatch(_touch(24, point, true, true))
	check(game.primary_touch == 23 and game.touch_axis == axis and not game.queued_jump,
		"canceled secondary finger cannot steal steering or request a jump")
	_dispatch(_touch(23, point, false, true))
	game._show_menu("Paused fixture", "Continue")
	_dispatch(_touch(25, point, true, true))
	check(game.primary_touch == -99 and not game.queued_jump, "inactive preview ignores canceled presses")
	observer.free()
	_check_isolation("touch cancellation")

func _telegraph_snapshot(game) -> Dictionary:
	var feedback = game.rhythm_feedback
	return {"tick": game.model.tick, "pursuit": game.model.pursuit_state().duplicate(true),
		"walk_phase": feedback.walk_frame_phase, "arm_amount": feedback.arm_amount,
		"lift_angle": feedback.lift_angle, "scheduled_click": feedback.scheduled_click_tick,
		"cues": feedback.cues_played.duplicate(true), "steps": feedback.step_events.duplicate(true)}

func _test_embedded_exit(game, host: Node) -> void:
	_fresh(game)
	while game.model.status == "running" and game.model.tick < 1800:
		game.model.step(game.model.reference_input())
		if game.model.pursuit_phase == "windup" and game.model.pursuit_pattern == "slow":
			break
	game._present(0.0)
	var feedback = game.rhythm_feedback
	check(game.model.pursuit_phase == "windup" and game.model.pursuit_pattern == "slow"
		and feedback.scheduled_click_tick > game.model.tick, "exit fixture has a real queued slow-windup click")
	game._lose_focus()
	var paused := _telegraph_snapshot(game)
	for _index in 20:
		game._physics_process(Model.DT)
		game._present(Model.DT)
	check(not game.active and game.focus_paused and _telegraph_snapshot(game) == paused,
		"focus pause freezes model ticks, telegraph pose, queued cue and event histories")
	# Headless normally suppresses playback. Seed only four short streams so the
	# cancellation test verifies AudioStreamPlayer.stop(), not just an idle flag.
	feedback.breath.stream = feedback.inhale
	var sounds: Array = [feedback.steps[0], feedback.steps[1], feedback.click, feedback.breath]
	for sound in sounds:
		sound.play()
	check(sounds.all(func(sound): return sound.playing), "audio stop fixture contains actual playing streams")
	game.queued_jump = true
	game.touch_axis = 1
	game.held_screen_axis = 1
	game.held_route_direction = 1
	check(game.exited.is_connected(game._exit_standalone_preview), "canonical scene connects its standalone exit handler")
	var exit_button: Button = game.menu.get_child(0).get_child(2)
	exit_button.pressed.emit()
	check(exits == 1 and not game.active and not game.focus_paused,
		"embedded exit emits once and clears both running and resumable-pause state")
	check(not game.queued_jump and game.touch_axis == 0 and game.held_screen_axis == 0
		and game.held_route_direction == 0, "exit clears all local attempt input")
	check(sounds.all(func(sound): return not sound.playing), "exit stops every footstep, click and breath stream")
	check(current_scene == host and is_instance_valid(game), "embedded exit does not quit or free its host")
	check(game.viewport.render_target_update_mode == SubViewport.UPDATE_DISABLED,
		"exited preview disables its private viewport updates")
	var exited_state := _telegraph_snapshot(game)
	_dispatch(_key(KEY_ESCAPE, true))
	_dispatch(_key(KEY_ESCAPE, false))
	for _index in 20:
		game._physics_process(Model.DT)
		game._present(Model.DT)
	check(not game.active and _telegraph_snapshot(game) == exited_state,
		"Esc and later frames cannot resume an exited attempt or advance its telegraph")
	check(exits == 1 and completions.is_empty(), "cancellation cannot emit a completion or a second exit")
	game._start()
	check(game.active and not game.focus_paused and game.model.tick == 0 and game.model.gates_passed == 0,
		"explicit restart begins a fresh local attempt")
	check(feedback.scheduled_click_tick == -1 and feedback.cues_played.is_empty()
		and feedback.step_events.is_empty() and feedback.walk_frame_phase == 0
		and feedback.arm_amount == 0 and feedback.lift_angle == 0,
		"restart clears queued audio, old cue histories and telegraph pose")
	check(sounds.all(func(sound): return not sound.playing), "restart inherits no playing audio")
	_check_isolation("embedded exit and restart")

func _test_terminal_states(game) -> void:
	_fresh(game)
	while game.model.status == "running":
		game.model.step(0)
	game._physics_process(Model.DT)
	game._present(0.0)
	var failed := _telegraph_snapshot(game)
	for _index in 3:
		game._physics_process(Model.DT)
		game._present(Model.DT)
	check(game.model.status == "failed" and not game.active and game.menu.visible,
		"physical failure reaches the local retry menu")
	check(completions.is_empty() and _telegraph_snapshot(game) == failed,
		"failure stays frozen without a completion or new feedback cues")
	_check_isolation("failed attempt")
	_fresh(game)
	while game.model.status == "running" and game.model.tick < 3484:
		game.model.step(game.model.reference_input())
	game._present(0.0)
	# Only the final tick uses the view's reference input mode. This exercises
	# its real terminal signal without enabling diagnostic screenshot capture.
	game.demo_mode = true
	game._physics_process(Model.DT)
	game.demo_mode = false
	game._present(0.0)
	check(game.model.status == "finished" and game.model.tick == 3485 and game.model.gates_passed == 12,
		"native view commits the complete twelve-flight local finish at the expected tick")
	check(completions.size() == 1 and Model.validate_proof(completions[0]),
		"finish emits exactly one replay-valid B3 proof")
	var finished := _telegraph_snapshot(game)
	for _index in 3:
		game._physics_process(Model.DT)
		game._present(Model.DT)
	check(not game.active and completions.size() == 1 and _telegraph_snapshot(game) == finished,
		"finished attempt cannot advance or emit duplicate feedback and completion")
	_check_isolation("successful attempt")

func _standalone_probe() -> void:
	var preview = load(SCENE_PATH).instantiate()
	root.add_child(preview)
	current_scene = preview
	preview.set_process(false)
	preview.set_physics_process(false)
	create_timer(2.0).timeout.connect(func():
		push_error("ENDLESS_STAIR_EXIT_WATCHDOG: standalone exit did not quit")
		quit(1))
	await process_frame
	var exit_button: Button = preview.menu.get_child(0).get_child(2)
	print("ENDLESS_STAIR_STANDALONE_EXIT: dispatching canonical exit button")
	exit_button.pressed.emit()

func run() -> void:
	if OS.get_cmdline_user_args().has("--standalone-exit-probe"):
		await _standalone_probe()
		return
	var user_dir := ProjectSettings.globalize_path("user://").trim_suffix("/")
	var expected := OS.get_environment("GODOT_TEST_USER_DATA_DIR").trim_suffix("/")
	check(user_dir.begins_with("/tmp/") and (expected.is_empty() or expected == user_dir),
		"formal-save probe uses an isolated temporary XDG directory")
	check(root.has_node("State"), "real native State autoload is present")
	if failures:
		quit(1)
		return
	# Sentinels make the no-write claim non-vacuous. They are never created in
	# the user's normal data directory; the guard above must pass first.
	for path: String in SAVE_PATHS:
		if not FileAccess.file_exists(path):
			var file := FileAccess.open(path, FileAccess.WRITE)
			check(file != null, "isolated save sentinel can be created: " + path)
			if file == null:
				quit(1)
				return
			file.store_buffer(("B3 isolation sentinel; preserve exact bytes: " + path + "\n").to_utf8_buffer())
			file.close()
	campaign_before = _campaign_snapshot()
	saves_before = _save_snapshot()
	var previous_accumulation := Input.use_accumulated_input
	Input.use_accumulated_input = false
	root.size = Vector2i(1280, 720)
	var host := Node.new()
	root.add_child(host)
	current_scene = host
	var game = load(SCENE_PATH).instantiate()
	host.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	game.exited.connect(func(): exits += 1)
	game.finished.connect(func(proof: Dictionary): completions.append(proof))
	await process_frame
	await process_frame
	check(not game.active and game.menu.visible, "preview starts at an explicit local menu")
	_check_isolation("preview creation")
	_test_touch_cancellation(game, host)
	_test_embedded_exit(game, host)
	_test_terminal_states(game)
	_release_keys()
	current_scene = null
	host.queue_free()
	await process_frame
	await process_frame
	_check_isolation("preview destruction")
	Input.use_accumulated_input = previous_accumulation
	var output: Array = []
	var status := OS.execute(OS.get_executable_path(), ["--headless", "--path",
		ProjectSettings.globalize_path("res://"), "--script",
		"res://tests/test_endless_stair_integration.gd", "--", "--standalone-exit-probe", "--fresh"], output, true)
	var child_log := "\n".join(output)
	check(status == 0 and child_log.contains("ENDLESS_STAIR_STANDALONE_EXIT:")
		and not child_log.contains("SCRIPT ERROR:") and not child_log.contains("ERROR:"),
		"standalone canonical exit closes its own process before the watchdog")
	if status != 0 or child_log.contains("ERROR:"):
		print(child_log)
	_check_isolation("standalone child exit")
	print("ENDLESS_STAIR_INTEGRATION: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
