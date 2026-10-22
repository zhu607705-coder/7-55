extends SceneTree
## B3 rhythm checks. --baseline-signature may run this file in the unchanged B2 project.
const Model = preload("res://scripts/games/chapter4_endless_stair_model.gd")
const SideModel = preload("res://scripts/games/chapter4_endless_stair_physics.gd")
const B1_LAYOUT_HASH := "069fc178fb92f578114ebe62a3a57bd2772fbd49da85aedba66c64906bcdcb84"
const B2_PLAYER_TRACE_HASH := "3d48528af32e48f2817af4c5154b96d614fdcd10666a81d862720446c9df1e81"
const TRACE_PATH := "user://endless_stair_b3/B3_pursuit_trace.json"
var checks := 0
var failures := 0
var bounded_travel := true
var bounded_acceleration := true
var bounded_speed := true
var continuous_world := true
var bounded_player := true
var measured_ticks := 0
var max_guard_step := 0.0
var max_world_step := 0.0
var max_speed_change := 0.0
var min_speed := INF
var max_speed := -INF

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, note: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("B3 pursuit: " + note)

func gap(m) -> float:
	return m.player.x - m.guard.x

func player_record(m) -> Array:
	return [m.tick, m.player.x, m.player.y, m.player_velocity.x,
		m.player_velocity.y, m.player_grounded, m.last_input, m.gates_passed]

func baseline_signature() -> void:
	var m = Model.new()
	var player_trace: Array = []
	while m.status == "running":
		m.step(m.reference_input())
		player_trace.append(player_record(m))
	print("BASELINE_SIGNATURE " + JSON.stringify({"geometryId": Model.data().id,
		"status": m.status, "ticks": m.tick,
		"playerTraceHash": JSON.stringify(player_trace, "", true).sha256_text()}))
	quit(0 if m.status == "finished" else 1)

func profile_signature() -> void:
	var times: Array = []
	var worst: Dictionary = {"microseconds": 0}
	for replay in 4:
		var m = Model.new()
		while m.status == "running":
			var mask: int = m.reference_input()
			var started := Time.get_ticks_usec()
			m.step(mask)
			var elapsed := Time.get_ticks_usec() - started
			if replay > 0:
				times.append(elapsed)
				if elapsed > int(worst.microseconds):
					worst = {"microseconds": elapsed, "tick": m.tick}
					if m.has_method("pursuit_state"):
						worst.pursuit = m.pursuit_state()
	times.sort()
	print("PROFILE_SIGNATURE " + JSON.stringify({"geometryId": Model.data().id,
		"measuredTicks": times.size(), "medianUs": times[times.size() / 2],
		"p95Us": times[ceili(times.size() * 0.95) - 1],
		"p99Us": times[ceili(times.size() * 0.99) - 1], "worst": worst,
		"method": "headless model.step only; first full replay warmup, then three replays"}))
	quit()

func sample(m) -> Dictionary:
	var p: Vector3 = m.route_position(m.player.x, m.player.y)
	var g: Vector3 = m.route_position(m.guard.x, m.guard.y)
	return {"tick": m.tick, "seconds": float(m.tick) / Model.TICK_RATE,
		"playerProgress": m.player.x, "guardProgress": m.guard.x,
		"playerWorld": [p.x, p.y, p.z], "guardWorld": [g.x, g.y, g.z],
		"routeGap": gap(m), "guardSpeed": m.guard_pursuit_speed,
		"route": m.route_section(m.player.x).id, "status": m.status,
		"pursuit": m.pursuit_state()}

func step_checked(m, mask: int) -> void:
	if m.status != "running":
		return
	var old_x: float = m.guard.x
	var old_player_x: float = m.player.x
	var old_world: Vector3 = m.route_position(m.guard.x, m.guard.y)
	var old_speed: float = m.guard_pursuit_speed
	m.step(mask)
	var profile: Dictionary = m.geometry.pursuit
	var travel := absf(m.guard.x - old_x)
	var world_travel := old_world.distance_to(m.route_position(m.guard.x, m.guard.y))
	var acceleration := absf(m.guard_pursuit_speed - old_speed)
	bounded_travel = bounded_travel and travel <= float(profile.maxSpeed) * Model.DT + 0.00002
	bounded_acceleration = bounded_acceleration and acceleration <= float(profile.acceleration) * Model.DT + 0.000001
	bounded_speed = bounded_speed and m.guard_pursuit_speed >= float(profile.minSpeed) - 0.000001 \
		and m.guard_pursuit_speed <= float(profile.maxSpeed) + 0.000001
	continuous_world = continuous_world and world_travel < 0.20
	bounded_player = bounded_player and absf(m.player.x - old_player_x) <= Model.PLAYER_SPEED * Model.DT + 0.00002
	max_guard_step = maxf(max_guard_step, travel)
	max_world_step = maxf(max_world_step, world_travel)
	max_speed_change = maxf(max_speed_change, acceleration)
	min_speed = minf(min_speed, m.guard_pursuit_speed)
	max_speed = maxf(max_speed, m.guard_pursuit_speed)
	measured_ticks += 1

func finish_reference(m) -> void:
	while m.status == "running":
		step_checked(m, m.reference_input())

func run() -> void:
	DirAccess.make_dir_recursive_absolute("user://endless_stair_b3")
	if OS.get_cmdline_user_args().has("--baseline-signature"):
		baseline_signature()
		return
	if OS.get_cmdline_user_args().has("--profile-signature"):
		profile_signature()
		return
	var data: Dictionary = Model.data()
	check(data.id == "chapter4-endless-stair-chase-B-v3" and data.version == 3, "separate B3 identity")
	check(Model.PHYSICS_VERSION == 4, "changed pursuit has physics version 4")
	check(Model.PLAYER_SPEED == 3.25 and Model.TICK_RATE == 60 and Model.DT == 1.0 / 60, "original player speed and fixed timestep")
	check(Model.GUARD_SPEED == 2.71875 and SideModel.GUARD_SPEED == 2.71875, "base guard constant unchanged")
	check(Model.GRAVITY == 20.0 and Model.JUMP_SPEED == 7.6 and Model.BODY_WIDTH == 0.5 \
		and Model.BODY_HEIGHT == 1.45 and Model.MAX_TICKS == 7200, "original jump/collision/runtime constants")
	var layout := data.duplicate(true)
	for key in ["id", "version", "pursuit"]:
		layout.erase(key)
	check(JSON.stringify(layout, "", true).sha256_text() == B1_LAYOUT_HASH, "all route/collision/spawn/lighting geometry exactly equals B1/B2")
	check(data.routes.size() == 25 and data.gates.size() == 12 and data.floors.size() == 247 \
		and data.obstacles.size() == 3, "finite twelve-flight course preserved")
	check(not data.pursuit.has("targetGap") and not data.pursuit.has("gapResponse"), "no target-gap controller in B3 manifest")
	var base = SideModel.new()
	for i in 60:
		base.step(SideModel.RIGHT)
	check(absf(base.guard_velocity.x - SideModel.GUARD_SPEED) < 0.000001, "side model still uses its constant guard speed")
	var no_profile := data.duplicate(true)
	no_profile.erase("pursuit")
	var legacy = Model.new(no_profile)
	check(legacy.guard_pursuit_speed == Model.GUARD_SPEED, "folded geometry without profile keeps constant fallback")

	var m = Model.new()
	check(m.guard_pursuit_speed == float(data.pursuit.initialSpeed), "first run initializes profile speed")
	var samples: Array = [sample(m)]
	var transitions: Array = []
	var player_trace: Array = []
	var rhythm_trace: Array = []
	var minimum_gap := gap(m)
	var maximum_gap := gap(m)
	var player_matches_legacy := true
	var jumps := 0
	var last_grounded: bool = m.player_grounded
	var phase_start_tick := 1
	var last_phase := "chase"
	var last_pattern := "fast"
	var fast_windups: Array = []
	var slow_windups: Array = []
	var phase_durations: Array = []
	var bursts: Dictionary = {"fast": 0, "slow": 0}
	var first_burst: Dictionary = {}
	var burst_start_gap := 0.0
	var burst_closures: Array = []
	var current_recovery_start := 0.0
	var recovery_gains: Array = []
	var slow_approach_speed := 0.0
	var slow_pause_speed := INF
	var reference_aborts := 0
	while m.status == "running":
		var mask: int = m.reference_input()
		step_checked(m, mask)
		legacy.step(mask)
		player_matches_legacy = player_matches_legacy and m.player == legacy.player \
			and m.player_velocity == legacy.player_velocity and m.player_grounded == legacy.player_grounded
		player_trace.append(player_record(m))
		rhythm_trace.append([m.tick, m.guard.x, m.guard.y, m.guard_pursuit_speed, m.pursuit_phase,
			m.pursuit_pattern, m.pursuit_phase_ticks, m.pursuit_event_serial])
		minimum_gap = minf(minimum_gap, gap(m))
		maximum_gap = maxf(maximum_gap, gap(m))
		if last_grounded and not m.player_grounded and m.player_velocity.y > 0:
			jumps += 1
		last_grounded = m.player_grounded
		if m.pursuit_pattern == "slow" and m.pursuit_phase == "windup":
			if m.pursuit_phase_ticks <= 24:
				slow_approach_speed = maxf(slow_approach_speed, m.guard_pursuit_speed)
			else:
				slow_pause_speed = minf(slow_pause_speed, m.guard_pursuit_speed)
		if not m.pursuit_event.is_empty():
			transitions.append(sample(m))
			var elapsed: int = m.tick - phase_start_tick
			phase_durations.append({"phase": last_phase, "pattern": last_pattern, "ticks": elapsed})
			if last_phase == "windup":
				if last_pattern == "fast": fast_windups.append(elapsed)
				else: slow_windups.append(elapsed)
			if last_phase == "burst":
				burst_closures.append(burst_start_gap - gap(m))
			if last_phase == "recovery":
				recovery_gains.append(gap(m) - current_recovery_start)
			if m.pursuit_phase == "burst":
				bursts[m.pursuit_pattern] += 1
				burst_start_gap = gap(m)
				if not first_burst.has(m.pursuit_pattern): first_burst[m.pursuit_pattern] = m.tick
			if m.pursuit_phase == "recovery":
				current_recovery_start = gap(m)
				if m.pursuit_burst_aborted: reference_aborts += 1
			phase_start_tick = m.tick
			last_phase = m.pursuit_phase
			last_pattern = m.pursuit_pattern
		if m.tick in [60, 120] or m.tick % 120 == 0 or m.status != "running":
			samples.append(sample(m))
	check(m.status == "finished" and m.tick == 3485, "reference still finishes at 3485 ticks / 58.083 seconds")
	check(m.gates_passed == 12 and m.player_grounded and not m.guard_fell, "all gates, grounded exit and safe guard traversal")
	check(jumps == 6, "all six obstacle/damaged-step jumps remain necessary")
	check(player_matches_legacy and legacy.status == "finished", "every player tick matches unchanged legacy movement")
	check(minimum_gap > 2.0 and maximum_gap < 6.0 and gap(m) < 3.0, "reference stays threatening but safe without target-gap feedback")
	check(bursts.fast >= 4 and bursts.slow >= 4, "both attack patterns recur across the complete ascent")
	check(first_burst.fast < 1800 and first_burst.slow < 1800, "both patterns are visible in the first thirty seconds")
	check(reference_aborts == 0 and m.pursuit_terrain_delays > 0, "terrain postpones attacks before windup, with no aborted reference bursts")
	check(fast_windups.size() >= 4 and fast_windups.all(func(n): return n == 30), "every complete fast windup is exactly 30 ticks")
	check(slow_windups.size() >= 4 and slow_windups.all(func(n): return n == 66), "every complete slow windup is exactly 66 ticks")
	check(slow_approach_speed >= 3.59 and slow_pause_speed <= 0.81, "slow windup approaches first, then visibly pauses")
	check(burst_closures.all(func(n): return n > 0.85), "each reference burst closes at least 0.85 metres")
	check(recovery_gains.all(func(n): return n > 0.15), "each completed recovery gives measurable breathing room")
	var phase_order_ok := true
	var pattern_order_ok := true
	var last_transition_phase := "chase"
	var last_transition_pattern := "fast"
	var next_phase := {"chase": "windup", "windup": "burst", "burst": "recovery", "recovery": "chase"}
	for transition: Dictionary in transitions:
		var current: Dictionary = transition.pursuit
		phase_order_ok = phase_order_ok and current.phase == next_phase[last_transition_phase]
		var expected_pattern := last_transition_pattern
		if current.phase == "chase": expected_pattern = "slow" if last_transition_pattern == "fast" else "fast"
		pattern_order_ok = pattern_order_ok and current.pattern == expected_pattern
		last_transition_phase = current.phase
		last_transition_pattern = current.pattern
	check(phase_order_ok, "every reference attack has a visible windup before burst and a recovery after")
	check(pattern_order_ok, "fast and slow cycles alternate strictly without randomness")
	var duration_ok := true
	for phase: Dictionary in phase_durations:
		if phase.phase in ["burst", "recovery"]:
			duration_ok = duration_ok and phase.ticks == data.pursuit.patterns[phase.pattern][phase.phase + "Ticks"]
	check(duration_ok, "all completed burst and recovery durations equal their declared tick counts")
	var player_trace_hash := JSON.stringify(player_trace, "", true).sha256_text()
	check(player_trace_hash == B2_PLAYER_TRACE_HASH, "every player state/input/gate tick hash equals an actual unchanged B2 project replay")
	var rhythm_trace_hash := JSON.stringify(rhythm_trace, "", true).sha256_text()
	var reference_inputs: Array = m.input_log.duplicate()
	var reference_end: Vector2 = m.player
	var reference_guard: Vector2 = m.guard
	var reference_state: Dictionary = m.pursuit_state()
	var proof: Dictionary = m.proof()
	check(Model.validate_proof(proof), "compressed B3 proof validates by complete replay")
	check(Model.validate_proof(m.proof(false)), "raw B3 proof validates by complete replay")
	for version in [2, 3]:
		var old_proof := proof.duplicate(true)
		old_proof.physicsVersion = version
		check(not Model.validate_proof(old_proof), "physics-v%d proof cannot certify B3" % version)
	var old_proof := proof.duplicate(true)
	old_proof.geometryId = "chapter4-endless-stair-chase-B-v2"
	check(not Model.validate_proof(old_proof), "B2 identity cannot certify B3")
	old_proof = proof.duplicate(true)
	old_proof.geometryHash = "changed-pursuit"
	check(not Model.validate_proof(old_proof), "changed pursuit manifest invalidates proof hash")
	m.step(Model.LEFT)
	check(m.tick == 3485 and m.player == reference_end and m.guard == reference_guard \
		and m.pursuit_state() == reference_state, "finished actors and rhythm state freeze")
	var reference_summary := {"status": m.status, "ticks": m.tick, "durationSeconds": float(m.tick) / 60.0,
		"gates": m.gates_passed, "jumps": jumps, "minGap": minimum_gap, "maxGap": maximum_gap,
		"finalGap": gap(m), "playerMatchesLegacyEveryTick": player_matches_legacy,
		"playerTraceHash": player_trace_hash, "rhythmTraceHash": rhythm_trace_hash,
		"B2Baseline": {"project": "stair-endless-B-lightperf-20261016/playable",
			"geometryId": "chapter4-endless-stair-chase-B-v2", "ticks": 3485,
			"playerTraceHash": B2_PLAYER_TRACE_HASH, "matchesEveryTick": player_trace_hash == B2_PLAYER_TRACE_HASH},
		"samples": samples, "transitions": transitions, "phaseDurations": phase_durations,
		"bursts": bursts, "firstBurstTicks": first_burst, "burstGapClosures": burst_closures,
		"recoveryGapGains": recovery_gains, "terrainDelayTicks": m.pursuit_terrain_delays,
		"proof": proof}

	m.reset()
	check(m.tick == 0 and m.gates_passed == 0 and m.status == "running" and m.input_log.is_empty() \
		and m.guard_velocity == Vector2.ZERO and m.guard_pursuit_speed == float(data.pursuit.initialSpeed), "restart clears movement and log")
	check(m.pursuit_phase == "chase" and m.pursuit_pattern == "fast" and m.pursuit_phase_ticks == 0 \
		and m.pursuit_event_serial == 0 and m.pursuit_cycle == 0 and m.pursuit_event.is_empty() \
		and m.pursuit_last_event.is_empty() and m.pursuit_last_event_tick == 0 \
		and m.pursuit_terrain_delays == 0 and not m.pursuit_burst_aborted, "restart clears all rhythm and presentation state")
	var repeated_trace: Array = []
	for mask: int in reference_inputs:
		step_checked(m, mask)
		repeated_trace.append([m.tick, m.guard.x, m.guard.y, m.guard_pursuit_speed, m.pursuit_phase,
			m.pursuit_pattern, m.pursuit_phase_ticks, m.pursuit_event_serial])
	check(m.status == "finished" and m.player == reference_end and m.guard == reference_guard \
		and m.pursuit_state() == reference_state, "same inputs reproduce exact terminal coordinates and phase")
	check(JSON.stringify(repeated_trace, "", true).sha256_text() == rhythm_trace_hash, "deterministic pursuit matches at every tick, not only the exit")
	check(m.proof() == proof, "restart produces identical proof")

	m.reset()
	while m.status == "running":
		step_checked(m, 0)
	check(m.failure_reason == "caught" and m.tick < 90 and not m.guard_fell, "idle caught physically within 1.5 seconds")
	var idle_summary := {"tick": m.tick, "seconds": float(m.tick) / 60.0, "reason": m.failure_reason, "gap": gap(m)}
	m.reset()
	while m.status == "running":
		step_checked(m, Model.RIGHT)
	check(m.failure_reason == "caught" and m.tick < 800 and not m.guard_fell, "missing obstacle jump causes physical catch")
	var missed_jump_summary := {"tick": m.tick, "seconds": float(m.tick) / 60.0, "reason": m.failure_reason, "gap": gap(m)}

	var hesitations: Array = []
	for start_tick: int in [126, 156, 222, 300, 405, 471, 600, 900, 1200, 1800, 2400, 3000]:
		m.reset()
		while m.tick < start_tick and m.status == "running":
			step_checked(m, m.reference_input())
		var before := sample(m)
		for i in 30:
			step_checked(m, 0)
		var after := sample(m)
		check(m.status == "running" and float(before.routeGap) - float(after.routeGap) > 0.90,
			"0.5 second hesitation consumes real distance at tick %d" % start_tick)
		finish_reference(m)
		check(m.status == "finished" and not m.guard_fell, "single 0.5 second fumble remains recoverable at tick %d" % start_tick)
		hesitations.append({"before": before, "after": after, "finalStatus": m.status, "finalTick": m.tick, "finalGap": gap(m)})
	m.reset()
	while m.tick < 3000:
		step_checked(m, m.reference_input())
	var stop_tick: int = m.tick
	for i in 60:
		step_checked(m, 0)
	check(m.failure_reason == "caught", "one-second hesitation during a late burst is caught")
	var prolonged_summary := {"startTick": stop_tick, "caughtTick": m.tick,
		"stationarySeconds": float(m.tick - stop_tick) / 60.0, "reason": m.failure_reason}
	m.reset()
	finish_reference(m)
	check(m.status == "finished" and m.guard == reference_guard, "successful retry after a caught run")

	var fresh = Model.new()
	var fresh_state: Dictionary = fresh.pursuit_state()
	for reset_phase: String in ["windup", "burst", "recovery"]:
		m.reset()
		while m.status == "running" and m.pursuit_phase != reset_phase:
			m.step(m.reference_input())
		m.reset()
		check(m.pursuit_state() == fresh_state and m.guard == fresh.guard and m.player == fresh.player,
			"restart during %s resets the exact first-run state" % reset_phase)

	# The same phase commands the same speed at different distances. Geometry
	# can postpone a future attack, but distance never changes phase targets.
	var near = Model.new()
	var far = Model.new()
	far.player.x += 1.0
	var same_commands := true
	for i in 90:
		near.step(Model.RIGHT)
		far.step(Model.RIGHT)
		same_commands = same_commands and near.guard_pursuit_speed == far.guard_pursuit_speed
	check(same_commands and near.guard == far.guard, "different route gaps do not alter chase speed or snap guard coordinates")
	m.reset()
	while m.pursuit_event_serial == 0:
		m.step(m.reference_input())
	var event: String = m.pursuit_event
	var serial: int = m.pursuit_event_serial
	m.step(m.reference_input())
	check(m.pursuit_event.is_empty() and m.pursuit_last_event == event and m.pursuit_event_serial == serial,
		"last transition remains available if a presentation frame spans multiple physics ticks")
	check(m.pursuit_phase_progress() >= 0.0 and m.pursuit_phase_progress() <= 1.0, "presentation progress is normalized")

	check(bounded_travel, "every measured guard step obeys maxSpeed / 60; no progress snap")
	check(bounded_acceleration, "every commanded speed change obeys 6 m/s² at 60 Hz")
	check(bounded_speed, "all commanded speeds stay in 0.80–5.20 m/s")
	check(continuous_world, "all guard world-space steps stay below 0.20 m, including turn/jump seams")
	check(bounded_player, "all player progress steps obey unchanged 3.25 m/s bound")
	var result := {"checks": checks, "failures": failures, "physicsVersion": Model.PHYSICS_VERSION,
		"geometryId": data.id, "geometryHash": Model.geometry_hash(), "unchangedB1B2LayoutHash": B1_LAYOUT_HASH,
		"pursuit": data.pursuit, "reference": reference_summary, "idle": idle_summary,
		"missedJump": missed_jump_summary, "halfSecondHesitations": hesitations,
		"prolongedHesitation": prolonged_summary,
		"bounds": {"measuredTicks": measured_ticks, "maxGuardProgressPerTick": max_guard_step,
			"maxGuardWorldStep": max_world_step, "maxSpeedChangePerTick": max_speed_change,
			"minimumCommandedSpeed": min_speed, "maximumCommandedSpeed": max_speed},
		"profileComparison": {
			"measuredAtUTC": "2026-10-16T13:27:24Z",
			"method": "headless model.step only; one warmup replay, then three full replays per actual project",
			"B2": {"measuredTicks": 10455, "medianUs": 139, "p95Us": 265, "p99Us": 392, "maxUs": 5272},
			"B3": {"measuredTicks": 10455, "medianUs": 136, "p95Us": 313, "p99Us": 1071, "maxUs": 4288},
			"scope": "CPU model physics only; native presentation benchmark is separate"},
		"inputSource": "deterministic simulated fixed-tick input; not human play"}
	var file := FileAccess.open(TRACE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Cannot save B3 pursuit trace: " + str(FileAccess.get_open_error()))
		quit(1)
		return
	file.store_string(JSON.stringify(result, "  "))
	file.close()
	print("B3 PURSUIT: %d checks, %d failures; reference 3485 ticks / 58.083s; gap %.3f..%.3fm; idle caught %dt; %.2f..%.2fm/s; %d bounded ticks; player trace %s" \
		% [checks, failures, minimum_gap, maximum_gap, idle_summary.tick, min_speed, max_speed, measured_ticks, player_trace_hash])
	quit(1 if failures else 0)
