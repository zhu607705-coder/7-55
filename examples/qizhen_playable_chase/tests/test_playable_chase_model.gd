extends SceneTree
## Automated simulation only. This is not footage or evidence of a human playthrough.
const Model = preload("res://scripts/games/qizhen_playable_chase.gd")
var failures: Array[String] = []
var checks: int = 0

func _initialize() -> void:
	_test_inputs_pause_reset()
	_test_steering_balance()
	_test_idle_and_no_time_win()
	_test_collisions()
	_test_charge_lock()
	_test_route_edges()
	_test_berth_and_territory()
	_test_replay_arguments()
	print(JSON.stringify({"suite": "AUTOMATED playable chase model", "checks": checks, "failures": failures}))
	quit(0 if failures.is_empty() else 1)

func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures.append(label)
		push_error(label)

func advance(model: RefCounted, duration: float) -> void:
	for unused: int in range(ceili(duration * 120.0)):
		model.step(1.0 / 120.0)

func _test_inputs_pause_reset() -> void:
	var m = Model.new()
	check(m.hull_collision(m.position, m.heading) == "", "legal spawn")
	check(not m.stroke("left"), "intro rejects input")
	advance(m, 2.0)
	check(m.elapsed == 0.0 and m.position == Model.PLAYER_START, "intro has no simulated movement")
	m.begin()
	check(m.stroke("left"), "first stroke accepted")
	check(not m.stroke("right"), "simultaneous duplicate rejected")
	advance(m, 0.19)
	check(not m.stroke("right"), "global cadence enforced")
	advance(m, 0.02)
	check(m.stroke("right"), "next cadence accepted")
	check(m.accepted_inputs.size() == 2, "only accepted inputs logged")
	m.set_paused(true)
	var before: Dictionary = m.result()
	var bird: Vector2 = m.swan_position
	check(not m.stroke("left"), "pause rejects input")
	advance(m, 5.0)
	check(m.result() == before and m.swan_position == bird, "pause freezes both bodies and clock")
	m.set_paused(false)
	advance(m, 0.5)
	check(m.elapsed > before.elapsed, "resume advances")
	m.reset(true)
	check(m.elapsed == 0.0 and m.accepted_inputs.is_empty() and m.collisions == 0 and m.outcome == "running" and m.position == Model.PLAYER_START and not m.intro, "reset clears prior attempt")
	check(m.next_story == "3.5", "story contract")

func _test_steering_balance() -> void:
	var m = Model.new()
	m.begin()
	check(not m.stroke("invalid") and m.accepted_inputs.is_empty(), "invalid stroke side has no effects")
	for unused: int in range(5):
		m.stroke("left")
		advance(m, 0.21)
	check(m.outcome == "running" and m.repeat_count == 5, "steering beyond four same-side strokes stays playable")
	check(m.hint.contains("倾斜"), "repeated strokes give readable warning")
	m.stroke("right")
	check(m.outcome == "running" and m.repeat_count == 1 and absf(m.roll) < 0.4, "changing side restores balance")
	m.reset(true)
	for unused: int in range(m.repeat_fail_count):
		m.stroke("left")
		advance(m, 0.21)
	check(m.outcome == "lost" and m.hint.contains("失去平衡"), "sustained configured imbalance eventually fails")

func _test_idle_and_no_time_win() -> void:
	var m = Model.new()
	m.begin()
	advance(m, 30.0)
	check(m.outcome == "lost", "idle is caught")
	check(m.position == Model.PLAYER_START and m.accepted_inputs.is_empty(), "idle never moves kayak")
	check(m.elapsed < 20.0, "idle caught within a readable attempt")
	check(not m.stroke("right"), "finished attempt rejects input")
	# Isolated victory-contract test: placing a fixture in berth is insufficient.
	m.reset(true)
	m.position = Vector2(170.0, 495.0)
	advance(m, 2.0)
	check(m.outcome != "won" and not m.gate_passed, "berth requires real gate and route crossings")

func _test_collisions() -> void:
	var m = Model.new()
	m.begin()
	check(m.source_obstacles.size() == 28, "all 28 original collision rectangles retained")
	check(m.hull_collision(Vector2(747.0, 450.0), PI) == "floating_raft", "bow collides before center crosses raft")
	check(m.hull_collision(Vector2(520.0, 360.0), PI * 0.5) == "raft_mooring_nw", "rotated full hull detects mooring")
	check(m.hull_collision(Vector2(240.0, 395.0), PI) == "final_gate_north", "cannot bypass final gate above gap")
	check(m.hull_collision(Vector2(240.0, 610.0), PI) == "final_gate_south", "cannot bypass final gate below gap")
	check(m.hull_collision(Vector2(240.0, 495.0), PI) == "", "aligned gate center is open")
	# Deliberate fixtures exercise swept movement, not route-success evidence.
	m.position = Vector2(780.0, 450.0)
	m.heading = PI
	m.speed = 100.0
	advance(m, 0.5)
	check(m.position.x >= 750.0 and m.collisions > 0 and m.speed == 0.0, "swept hull stops on raft")
	var contact: Vector2 = m.position
	check(m.stroke("left", true), "reverse accepted at a collision")
	advance(m, 0.25)
	check(m.position.x > contact.x, "reverse clears collision without sticky latch")
	check(m.hull_collision(m.position, m.heading) == "", "reverse keeps hull legal")

func _test_charge_lock() -> void:
	var m = Model.new()
	m.begin()
	var locked: Vector2 = Vector2.ZERO
	var warned: bool = false
	var charged: bool = false
	var charge_angle: float = 0.0
	for index: int in range(1800):
		if index % 48 == 0:
			m.stroke("left" if (index / 48) % 2 == 0 else "right")
		m.step(1.0 / 120.0)
		if m.swan_phase == "charge_warning":
			if not warned:
				warned = true
				locked = m.swan_aim
			check(m.swan_aim == locked, "warning aim stays locked")
		if m.swan_phase == "charge":
			if not charged:
				charged = true
				charge_angle = m.swan_heading
			check(absf(angle_difference(m.swan_heading, charge_angle)) < 0.00001, "charge cannot retarget")
		if charged and m.swan_phase == "recovery":
			break
		if m.outcome != "running":
			break
	check(warned and charged, "readable warning followed by actual charge")

func _test_route_edges() -> void:
	# Isolated navigation fixtures: bird recovery is held to test exact legal
	# raft-corridor edges. These do not claim complete live-chase playthroughs.
	var geometry = Model.new()
	check(geometry.hull_collision(Vector2(600.0, 351.5), PI) == "", "upper edge above raft is legal")
	check(geometry.hull_collision(Vector2(700.0, 595.0), PI) == "", "lower edge below mooring is legal")
	for y: float in [340.0, 600.0]:
		var m = Model.new()
		m.begin()
		m.position = Vector2(800.0, y)
		m.heading = PI - 0.0775
		m.swan_phase = "recovery"
		m.swan_phase_time = -1000.0
		m.swan_position = Vector2(1500.0, 300.0)
		var index: int = 0
		while m.elapsed < 20.0 and m.position.x >= 400.0 and m.outcome == "running":
			if index % 48 == 0:
				m.stroke("left" if (index / 48) % 2 == 0 else "right")
			m.step(1.0 / 120.0)
			index += 1
		check(m.raft_passed and m.collisions == 0, "legal corridor edge " + str(y) + " records physical crossing")
		check(m.raft_route == ("upper" if y < 470.0 else "lower"), "corridor label matches route")

func _test_berth_and_territory() -> void:
	var m = Model.new()
	m.begin()
	# Explicit local fixtures independently test all docking requirements.
	m.position = Vector2(170.0, 495.0)
	m.raft_passed = true
	m.gate_passed = true
	m.speed = 40.0
	advance(m, 0.1)
	check(m.outcome == "running" and m.berth_dwell == 0.0, "high speed cannot finish berth")
	m.position = Vector2(170.0, 495.0)
	m.speed = 0.0
	m.heading = PI * 0.5
	advance(m, 0.7)
	check(m.outcome == "running" and m.berth_dwell == 0.0, "wrong heading cannot finish berth")
	m.heading = PI
	advance(m, 0.5)
	check(m.outcome == "running", "berth requires full dwell")
	advance(m, 0.12)
	check(m.outcome == "won" and m.result().next_story == "3.5", "slow aligned physical berth completes")
	var finish: Dictionary = m.result()
	advance(m, 2.0)
	check(m.result() == finish and not m.stroke("left"), "victory is immutable to later input")
	m.reset(true)
	m.position = Vector2(260.0, 495.0)
	m.swan_position = Vector2(440.0, 495.0)
	m.swan_heading = PI
	m.swan_phase = "charge"
	m.swan_speed = Model.CHARGE_SPEED
	m._charge_heading = PI
	m.swan_attack_heading = PI
	var old: Vector2 = m.swan_position
	var no_jump: bool = true
	for unused: int in range(1200):
		m.step(1.0 / 120.0)
		no_jump = no_jump and m.swan_position.distance_to(old) <= Model.CHARGE_SPEED / 120.0 + 0.01
		old = m.swan_position
	check(m.swan_position.x >= Model.SWAN_WEST_LIMIT + Model.SWAN_RADIUS, "bird full body stays east of territorial rope")
	check(m.outcome == "running" and no_jump, "safe inlet is not caught and territory braking never teleports")
	check(m.hull_collision(Vector2(170.0, 495.0), PI) == "", "bird territory does not restrict kayak berth")
	# Completion ordering fixture: already-earned dwell completes this tick.
	m.reset(true)
	m.position = Vector2(170.0, 495.0)
	m.raft_passed = true
	m.gate_passed = true
	m.berth_dwell = Model.BERTH_DWELL - Model.FIXED_STEP * 0.5
	m.swan_position = m.position
	m.step(Model.FIXED_STEP)
	check(m.outcome == "won", "completed berth wins on simultaneous contact tick")

func _test_replay_arguments() -> void:
	# Optional real-input fixture: --replay=/absolute/path/to/result.json
	# Replays ONLY recorded strokes and elapsed ticks, never player coordinates.
	var replay_arguments: Array[String] = ["--replay=res://tests/fixtures/playable_upper_manual_input.json", "--replay=res://tests/fixtures/playable_lower_automated_input.json"]
	replay_arguments.append_array(OS.get_cmdline_user_args())
	for argument: String in replay_arguments:
		if not argument.begins_with("--replay="):
			continue
		var path: String = argument.trim_prefix("--replay=")
		var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		check(value is Dictionary, "replay fixture is a JSON object")
		if not value is Dictionary:
			continue
		var events: Array = value.get("inputs", value.get("accepted_inputs", []))
		var m = Model.new()
		m.begin()
		for event: Dictionary in events:
			var at_tick: int = int(event.get("tick", roundf(float(event.get("time", 0.0)) * 120.0)))
			while m.tick < at_tick and m.outcome == "running":
				m.step(Model.FIXED_STEP)
			check(m.stroke(str(event.side), bool(event.get("reverse", false))), "replay stroke accepted")
		var ticks: int = int(value.get("ticks", roundf(float(value.get("elapsed", 0.0)) * 120.0)))
		while m.tick < ticks and m.outcome == "running":
			m.step(Model.FIXED_STEP)
		print("RECORDED INPUT REPLAY ", JSON.stringify(m.result()))
		check(m.outcome == "won", "recorded stroke-only full chase succeeds")
