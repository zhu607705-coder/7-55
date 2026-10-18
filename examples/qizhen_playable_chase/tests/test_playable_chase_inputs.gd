extends SceneTree
## Independent automated headless audit. Event injection is not a human playthrough.
## Explicitly marked geometry/end-state fixtures set position or route flags; they are not playthrough evidence.
const Model = preload("res://scripts/games/qizhen_playable_chase.gd")
const View = preload("res://scripts/presentation/qizhen_playable_chase_view.gd")
var failures: Array[String] = []
var checks: int = 0
var view: Control

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures.append(label)
		push_error(label)

func advance(model: RefCounted, duration: float) -> void:
	for unused: int in range(ceili(duration * 120.0)):
		model.step(1.0 / 120.0)

func frames(count: int) -> void:
	for unused: int in range(count):
		view._process(1.0 / 60.0)

func key(code: Key, pressed: bool, echo: bool = false) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = pressed
	event.echo = echo
	view._unhandled_key_input(event)

func touch(point: Vector2, pressed: bool, index: int = 0) -> void:
	var event := InputEventScreenTouch.new()
	event.position = point
	event.pressed = pressed
	event.index = index
	view._gui_input(event)

func drag(point: Vector2, index: int = 0) -> void:
	var event := InputEventScreenDrag.new()
	event.position = point
	event.index = index
	view._gui_input(event)

func mouse(point: Vector2, pressed: bool, device: int = 0) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = point
	event.pressed = pressed
	event.device = device
	view._gui_input(event)

func refresh_layout(dimensions: Vector2i) -> void:
	root.size = dimensions
	view.queue_redraw()
	for unused: int in range(3):
		await process_frame

func run() -> void:
	_test_model_input_authority()
	_test_route_checkpoint_edges()
	view = View.new()
	root.add_child(view)
	view.set_process(false)
	view.restart(true)
	await refresh_layout(Vector2i(1280, 720))
	_test_intro_to_hold()
	_test_paused_intro_gates()
	_test_keyboard_hold_and_heading()
	_test_pause_focus_and_reset()
	_test_touch_and_mouse()
	_test_touch_reverse()
	_test_terminal_and_story_contract()
	await _test_responsive_controls()
	view.queue_free()
	print(JSON.stringify({"suite": "AUTOMATED independent playable input audit", "checks": checks, "failures": failures}))
	quit(0 if failures.is_empty() else 1)

func _test_model_input_authority() -> void:
	var model = Model.new()
	check(not model.stroke("left"), "intro rejects input")
	advance(model, 10.0)
	check(model.tick == 0 and model.position == Model.PLAYER_START, "intro does not simulate player movement")
	model.begin()
	advance(model, 60.0)
	check(model.position == Model.PLAYER_START and model.accepted_inputs.is_empty(), "idle cannot propel kayak")
	check(model.outcome == "lost" and model.result().next_story == "", "idle cannot win or award story")
	check(not model.stroke("right"), "terminal model rejects input")
	model.reset(true)
	model.stroke("left")
	var heading: float = model.heading
	var origin: Vector2 = model.position
	advance(model, 0.1)
	check(absf(angle_difference((model.position - origin).angle(), heading)) < 0.0001, "forward displacement follows model heading")
	check(absf(angle_difference(heading, PI)) > 0.1, "left input changes model heading")
	model.reset(true)
	model.stroke("right", true)
	heading = model.heading
	origin = model.position
	advance(model, 0.1)
	check(absf(angle_difference((model.position - origin).angle(), heading + PI)) < 0.0001, "reverse displacement opposes model heading")
	check(absf(angle_difference(heading, PI)) > 0.1, "reverse input changes actual yaw")

func _test_keyboard_hold_and_heading() -> void:
	view.restart(true)
	key(KEY_SPACE, true)
	frames(120)
	var sides: Array[String] = []
	for input: Dictionary in view.game.accepted_inputs:
		sides.append(input.side)
	check(sides == ["left", "right", "left", "right", "left"], "held cruise alternates five cadence strokes in two seconds")
	check(view.game.position.distance_to(Model.PLAYER_START) > 30.0, "held cruise moves actual kayak")
	check(view.rig.position.distance_to(view.screen(view.game.position)) < 0.001, "rig follows actual model position")
	key(KEY_SPACE, false)
	frames(30)
	check(view.game.accepted_inputs.size() == 5, "release stops new stroke impulses")
	key(KEY_A, true, true)
	check(view.game.accepted_inputs.size() == 5, "keyboard repeat echo cannot create strokes")
	view.restart(true)
	key(KEY_SPACE, true)
	frames(18)
	key(KEY_D, true)
	frames(72)
	var all_right: bool = true
	for index: int in range(1, view.game.accepted_inputs.size()):
		all_right = all_right and view.game.accepted_inputs[index].side == "right"
	check(all_right and view.game.accepted_inputs.size() >= 4, "single-side steering takes priority while cruise remains held")
	key(KEY_D, false)
	key(KEY_SPACE, false)
	view.restart(true)
	key(KEY_S, true)
	key(KEY_A, true)
	check(view.game.accepted_inputs.size() == 1 and view.game.accepted_inputs[0].reverse and view.game.speed < 0.0, "S plus A applies immediate reverse impulse")
	key(KEY_S, false)
	key(KEY_A, false)

func _test_pause_focus_and_reset() -> void:
	view.restart(true)
	key(KEY_SPACE, true)
	frames(60)
	var before: Dictionary = view.game.result()
	var bird: Vector2 = view.game.swan_position
	var effects_clock: float = view.rig.effects_clock
	view.set_paused(true)
	key(KEY_D, true)
	frames(120)
	check(view.game.result() == before and view.game.swan_position == bird, "pause freezes player, swan and simulation clock")
	check(view.rig.effects_clock == effects_clock and view.keys.is_empty() and view.fingers.is_empty(), "pause freezes rig and clears controls")
	view.set_paused(false)
	frames(15)
	check(view.game.accepted_inputs.size() == before.input_count, "resume cannot replay a held key")
	view.set_paused(true)
	view.restart(true)
	check(not view.game.paused and not view.rig.motion.paused, "restart from pause unpauses model and rig")
	check(view.game.tick == 0 and view.game.speed == 0.0 and view.game.accepted_inputs.is_empty() and view.game.position == Model.PLAYER_START, "restart clears previous attempt")
	check(view.rig.motion.phase() == "rest" and view.rig.spray.is_empty(), "restart clears animation queue and spray")
	var point: Vector2 = view.controls.cruise.get_center()
	touch(point, true)
	view._notification(Control.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(view.game.paused and view.fingers.is_empty(), "focus loss pauses and clears pending touch")
	view.set_paused(false)
	touch(point, false)
	frames(30)
	check(view.game.accepted_inputs.is_empty(), "late release after focus loss cannot produce phantom stroke")

func _test_touch_and_mouse() -> void:
	view.restart(true)
	var point: Vector2 = view.controls.cruise.get_center()
	touch(point, true)
	mouse(point, true, -1)
	check(view.game.accepted_inputs.is_empty() and view.fingers.size() == 1, "touch plus emulated mouse deduplicates pending press")
	touch(point, false)
	mouse(point, false, -1)
	check(view.game.accepted_inputs.size() == 1 and view.fingers.is_empty(), "quick tap emits exactly one stroke on release")
	frames(40)
	check(view.game.accepted_inputs.size() == 1, "touch release leaves no stuck hold")
	view.restart(true)
	mouse(point, true)
	frames(6)
	mouse(point, false)
	check(view.game.accepted_inputs.size() == 1 and view.fingers.is_empty(), "physical mouse click emits one stroke")
	view.restart(true)
	touch(point, true)
	frames(60)
	var sides: Array[String] = []
	for input: Dictionary in view.game.accepted_inputs:
		sides.append(input.side)
	check(sides == ["left", "right"], "held touch waits for classification then alternates cadence")
	touch(point, false)
	frames(30)
	check(view.game.accepted_inputs.size() == 2, "held-touch release does not append an extra stroke")

func _test_touch_reverse() -> void:
	view.restart(true)
	var point: Vector2 = view.controls.cruise.get_center()
	touch(point, true)
	frames(6)
	drag(point + Vector2(0, 40))
	touch(point + Vector2(0, 40), false)
	frames(30)
	check(view.game.accepted_inputs.size() == 1 and view.game.accepted_inputs[0].reverse, "quick downward swipe is reverse without a prior forward kick")
	check(view.game.speed < 0.0 and view.game.position.x > Model.PLAYER_START.x, "touch reverse moves model backward")
	view.restart(true)
	touch(point, true)
	frames(12)
	check(view.game.accepted_inputs.size() == 1 and not view.game.accepted_inputs[0].reverse, "long hold sends initial forward stroke")
	drag(point + Vector2(0, 40))
	check(view.fingers[0].get("pending_reverse", false), "reverse inside cadence window is retained while held")
	frames(12)
	check(view.game.accepted_inputs.size() == 2 and view.game.accepted_inputs[1].reverse, "pending reverse is accepted at next legal interval")
	for unused: int in range(8):
		drag(point + Vector2(0, 41))
	check(view.game.accepted_inputs.size() == 2, "repeated drag events do not duplicate reverse impulse")
	touch(point + Vector2(0, 41), false)
	frames(30)
	check(view.game.accepted_inputs.size() == 2, "reverse release clears cadence hold")
	view.restart(true)
	touch(point, true)
	view.set_paused(true)
	touch(point, false)
	view.set_paused(false)
	frames(30)
	check(view.game.accepted_inputs.is_empty(), "pause cancels undecided touch gesture")

func _test_terminal_and_story_contract() -> void:
	view.restart(true)
	frames(60 * 30)
	check(view.game.outcome == "lost" and view.game.result().next_story == "", "idle failure has no success story")
	key(KEY_P, true)
	check(not view.game.paused, "terminal outcome cannot be hidden by pause")
	key(KEY_A, true)
	check(view.game.accepted_inputs.is_empty(), "terminal key press cannot paddle")
	key(KEY_R, true)
	check(view.game.outcome == "running" and not view.game.intro and view.game.tick == 0, "R restarts directly into interactive play")
	# Isolated end-state fixture; this is not route completion or playthrough evidence.
	view.game.position = Vector2(170, 475)
	view.game.heading = PI
	view.game.gate_passed = true
	view.game.raft_passed = true
	frames(40)
	check(view.game.outcome == "won" and view.game.result().next_story == "3.5", "valid low-speed dwell returns local story 3.5 contract")
	check(view.keys.is_empty() and view.fingers.is_empty() and view.rig.motion.phase() == "rest", "success clears controls and stroke animation")
	key(KEY_P, true)
	check(not view.game.paused, "success panel cannot be replaced by pause")
	var before: Dictionary = view.game.result()
	frames(60)
	check(view.game.result() == before, "terminal model cannot continue moving or awarding")

func _test_responsive_controls() -> void:
	view.restart(true)
	for dimensions: Vector2i in [Vector2i(320, 720), Vector2i(390, 844), Vector2i(720, 900), Vector2i(1280, 720)]:
		await refresh_layout(dimensions)
		for action: String in ["left", "cruise", "right", "pause", "retry"]:
			var rect: Rect2 = view.controls[action]
			check(rect.position.x >= 0.0 and rect.position.y >= 0.0 and rect.end.x <= dimensions.x and rect.end.y <= dimensions.y, "control %s inside %dx%d viewport" % [action, dimensions.x, dimensions.y])
		for action: String in ["left", "cruise", "right"]:
			check(view.controls[action].size.x >= 44.0, "paddle target %s remains usable at width %d" % [action, dimensions.x])

func _test_route_checkpoint_edges() -> void:
	# Isolated legal-water fixture, driven only by strokes after initialization.
	var model = Model.new()
	model.begin()
	model.position = Vector2(800, 600)
	model.heading = PI - 0.0775
	model.route_history.clear()
	model.route_history.append(model.position)
	var input_index: int = 0
	while model.outcome == "running" and model.position.x >= 400.0 and model.elapsed < 15.0:
		if model.tick % 24 == 0:
			model.stroke("left" if input_index % 2 == 0 else "right")
			input_index += 1
		model.step(1.0 / 120.0)
	check(model.position.x < 410.0 and model.collisions == 0, "lower y600 corridor is physically traversable without collision")
	check(model.raft_passed and model.raft_route == "lower", "legal lower water cannot miss invisible route checkpoint")
	# Isolated simultaneous finish/contact fixture, matching the original priority.
	model.reset(true)
	model.position = Vector2(170, 475)
	model.heading = PI
	model.gate_passed = true
	model.raft_passed = true
	model.berth_dwell = 0.595
	model.tick = 1200
	model.swan_position = model.position + Vector2(47, 0)
	model.swan_heading = PI
	model.swan_phase = "recovery"
	model.swan_phase_time = 0.0
	model.step(1.0 / 120.0)
	check(model.outcome == "won", "completed berth wins before catch on the same simulation tick")

func _test_intro_to_hold() -> void:
	view.restart(false)
	check(view.game.intro and view.game.accepted_inputs.is_empty(), "view begins in inactive intro")
	key(KEY_SPACE, true)
	check(not view.game.intro and view.keys.has("cruise"), "intro Space begins play and retains held cruise")
	check(view.game.accepted_inputs.size() == 1 and view.game.accepted_inputs[0].tick == 0 and view.game.accepted_inputs[0].side == "left", "intro Space immediately emits exactly one first stroke")
	for unused: int in range(8):
		key(KEY_SPACE, true, true)
	check(view.game.accepted_inputs.size() == 1, "intro key echo does not duplicate first stroke")
	frames(1)
	check(view.game.accepted_inputs.size() == 1, "first process frame does not duplicate intro stroke")
	frames(119)
	var sides: Array[String] = []
	for input: Dictionary in view.game.accepted_inputs:
		sides.append(input.side)
	check(sides == ["left", "right", "left", "right", "left"], "intro to continuous hold produces exactly L R L R L")
	check(view.game.position.distance_to(Model.PLAYER_START) > 30.0, "intro hold continuously propels actual model")
	print("INTRO HOLD ", JSON.stringify({"input_count": view.game.accepted_inputs.size(), "inputs": view.game.accepted_inputs, "position": view.game.position, "elapsed": view.game.elapsed}))
	key(KEY_SPACE, false)
	frames(30)
	check(view.game.accepted_inputs.size() == 5 and not view.keys.has("cruise"), "release after intro hold stops new strokes")

func _test_paused_intro_gates() -> void:
	view.restart(false)
	view.set_paused(true)
	var initial_clock: float = view.intro_clock
	key(KEY_SPACE, true)
	check(view.game.intro and view.keys.is_empty() and view.rig.motion.paused, "paused intro Space preserves intro and pause state")
	view.restart(false)
	view.set_paused(true)
	key(KEY_ENTER, true)
	check(view.game.intro and view.rig.motion.paused, "paused intro Enter cannot begin play")
	view.restart(false)
	view.set_paused(true)
	view.begin_play()
	check(view.game.intro and view.rig.motion.paused, "shared begin handler rejects paused intro button intent")
	frames(120)
	check(view.intro_clock == initial_clock and view.game.tick == 0 and view.game.accepted_inputs.is_empty(), "paused intro freezes clock and rejects propulsion")
	view.set_paused(false)
	key(KEY_SPACE, true)
	check(not view.game.intro and view.game.accepted_inputs.size() == 1 and view.keys.has("cruise"), "resume then Space starts normally with one stroke")
