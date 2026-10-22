extends "res://scripts/games/chapter4_endless_stair_physics.gd"
## Specification-based reconstruction, 2026-10-10. Isolated prototype only.
## Canonical manifest and fixed-tick raw inputs are the sole proof authority.

const MANIFEST_PATH := "res://data/native/chapter4-endless-stair-b3.json"
const PROOF_KIND := "folded_stair_input"
const PROOF_VERSION := 1
const PHYSICS_VERSION := 4
static var _canonical_data: Dictionary = {}
var guard_pursuit_speed := GUARD_SPEED
# Public fixed-tick presentation state. No rendering or audio lives in the model.
var pursuit_phase := "chase"
var pursuit_pattern := "fast"
var pursuit_phase_ticks := 0
# Exact duration for attack phases; minimum duration for terrain-gated chase.
var pursuit_phase_duration := 0
var pursuit_event := ""
var pursuit_event_serial := 0
var pursuit_last_event := ""
var pursuit_last_event_tick := 0
var pursuit_cycle := 0
var pursuit_terrain_delays := 0
var pursuit_burst_aborted := false

static func data() -> Dictionary:
	if _canonical_data.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
		if parsed is Dictionary:
			_canonical_data = parsed
	return _canonical_data.duplicate(true)

static func geometry_hash() -> String:
	return JSON.stringify(data(), "", true).sha256_text()

func _default_geometry() -> Dictionary:
	return data()

func _max_step_height() -> float:
	return 0.18

func reset() -> void:
	super.reset()
	var profile: Dictionary = geometry.get("pursuit", {})
	guard_pursuit_speed = float(profile.get("initialSpeed", GUARD_SPEED))
	pursuit_phase = "chase"
	pursuit_pattern = "fast"
	pursuit_phase_ticks = 0
	pursuit_phase_duration = int(profile.get("chaseTicks", 120))
	pursuit_event = ""
	pursuit_event_serial = 0
	pursuit_last_event = ""
	pursuit_last_event_tick = 0
	pursuit_cycle = 0
	pursuit_terrain_delays = 0
	pursuit_burst_aborted = false

func pursuit_phase_progress() -> float:
	return clampf(float(pursuit_phase_ticks) / maxf(1.0, pursuit_phase_duration), 0.0, 1.0)

func pursuit_state() -> Dictionary:
	return {"phase": pursuit_phase, "pattern": pursuit_pattern,
		"phase_ticks": pursuit_phase_ticks, "phase_duration": pursuit_phase_duration,
		"progress": pursuit_phase_progress(), "speed": guard_pursuit_speed,
		"event": pursuit_event, "event_serial": pursuit_event_serial,
		"last_event": pursuit_last_event, "last_event_tick": pursuit_last_event_tick,
		"cycle": pursuit_cycle, "terrain_delays": pursuit_terrain_delays,
		"burst_aborted": pursuit_burst_aborted}

func _pursuit_pattern_data() -> Dictionary:
	return geometry.pursuit.patterns[pursuit_pattern]

func _pursuit_enter(phase: String) -> void:
	pursuit_phase = phase
	pursuit_phase_ticks = 0
	var profile: Dictionary = geometry.pursuit
	if phase == "chase":
		pursuit_cycle += 1
		pursuit_pattern = "fast" if pursuit_cycle % 2 == 0 else "slow"
		pursuit_phase_duration = int(profile.chaseTicks)
		pursuit_burst_aborted = false
	else:
		pursuit_phase_duration = int(_pursuit_pattern_data()[phase + "Ticks"])
	pursuit_event = phase + "_" + pursuit_pattern
	pursuit_event_serial += 1
	pursuit_last_event = pursuit_event
	pursuit_last_event_tick = tick + 1

func _pursuit_clear_ground(at: Vector2, distance: float) -> bool:
	# Sample the authored collision geometry, not the player's route gap.
	# A windup must not slow a guard already approaching a required jump.
	var probe := at
	var samples := ceili(distance / 0.10)
	for i: int in range(1, samples + 1):
		var x := at.x + distance * float(i) / samples
		probe = _horizontal_move(probe, x, true)
		if absf(probe.x - x) > EPS:
			return false
		var height := _floor_height_at(x, probe.y + EPS)
		if not is_finite(height) or height < probe.y - 0.20 - EPS:
			return false
	return true

func _pursuit_can_windup() -> bool:
	if not player_grounded or not guard_grounded or player.x <= guard.x:
		return false
	var windup_seconds := float(_pursuit_pattern_data().windupTicks) * DT
	var expected_player_x := player.x + PLAYER_SPEED * windup_seconds
	var expected_y := _floor_height_at(expected_player_x, INF)
	if not is_finite(expected_y) or str(route_section(expected_player_x).kind) == "turn":
		return false
	return _pursuit_clear_ground(guard, guard_pursuit_speed * windup_seconds + 0.8) \
		and _pursuit_clear_ground(player, 0.9) \
		and _pursuit_clear_ground(Vector2(expected_player_x, expected_y), 1.0)

func _pursuit_can_burst() -> bool:
	# Do not begin a burst at a required jump, on a turn, or during a landing.
	# Neither safety check corrects coordinates or creates invulnerability.
	return guard_grounded and player_grounded and _pursuit_clear_ground(guard, 1.0) \
		and _pursuit_clear_ground(player, 1.0) \
		and str(route_section(player.x).kind) != "turn"

func _guard_chase_speed() -> float:
	var profile: Dictionary = geometry.get("pursuit", {})
	if profile.is_empty():
		guard_pursuit_speed = super._guard_chase_speed()
		return guard_pursuit_speed
	pursuit_event = ""
	# Transitions happen before this tick's speed command. Attack phases
	# consume exactly their declared ticks; chase may wait for safe terrain.
	if pursuit_phase_ticks >= pursuit_phase_duration:
		match pursuit_phase:
			"chase":
				if _pursuit_can_windup():
					_pursuit_enter("windup")
				else:
					pursuit_terrain_delays += 1
			"windup":
				if _pursuit_can_burst():
					_pursuit_enter("burst")
				else:
					pursuit_burst_aborted = true
					_pursuit_enter("recovery")
			"burst": _pursuit_enter("recovery")
			"recovery": _pursuit_enter("chase")
	var pattern: Dictionary = _pursuit_pattern_data()
	var target_speed := float(profile.chaseSpeed)
	match pursuit_phase:
		"windup":
			target_speed = float(pattern.windupSpeed)
			if pursuit_phase_ticks < int(pattern.get("approachTicks", 0)):
				target_speed = float(pattern.get("approachSpeed", profile.chaseSpeed))
		"burst": target_speed = float(pattern.burstSpeed)
		"recovery": target_speed = float(pattern.recoverySpeed)
	# Speeds are authored by phase only. There is no distance rubber band,
	# position correction, player drag, wall-clock input, or random number.
	guard_pursuit_speed = move_toward(guard_pursuit_speed, target_speed,
		float(profile.acceleration) * DT)
	guard_pursuit_speed = clampf(guard_pursuit_speed, float(profile.minSpeed), float(profile.maxSpeed))
	pursuit_phase_ticks += 1
	return guard_pursuit_speed

func route_section(progress: float) -> Dictionary:
	var routes: Array = geometry.routes
	for section: Dictionary in routes:
		if progress < float(section.start) + float(section.length) - EPS:
			return section
	return routes.back()

func route_position(progress: float, y: float) -> Vector3:
	var section := route_section(progress)
	var t := (progress - float(section.start)) / float(section.length)
	var start := Vector2(float(section.fromXZ[0]), float(section.fromXZ[1]))
	var end := Vector2(float(section.toXZ[0]), float(section.toXZ[1]))
	var horizontal := start.lerp(end, t)
	return Vector3(horizontal.x, y, horizontal.y)

func route_heading(progress: float, direction: float = 1.0) -> Vector3:
	var section := route_section(progress)
	var from := Vector3(float(section.fromXZ[0]), 0, float(section.fromXZ[1]))
	var to := Vector3(float(section.toXZ[0]), 0, float(section.toXZ[1]))
	return (to - from).normalized() * signf(direction)

func route_surface_height(progress: float) -> float:
	var section := route_section(progress)
	var t := clampf((progress - float(section.start)) / float(section.length), 0.0, 1.0)
	return lerpf(float(section.fromY), float(section.toY), t)

func screen_direction(progress: float, screen_axis: float, camera_right: Vector3) -> float:
	var right := Vector3(camera_right.x, 0, camera_right.z).normalized()
	return signf(route_heading(progress).dot(right) * screen_axis)

static func visible_facing(heading: Vector3, camera_basis: Basis) -> Dictionary:
	var right := Vector3(camera_basis.x.x, 0, camera_basis.x.z).normalized()
	var away := Vector3(-camera_basis.z.x, 0, -camera_basis.z.z).normalized()
	var side_amount := heading.dot(right)
	var away_amount := heading.dot(away)
	if absf(side_amount) > absf(away_amount):
		return {"facing": "side", "left": side_amount < 0}
	return {"facing": "up" if away_amount > 0 else "down", "left": false}

func torch_pose(hand_anchor: Vector3 = Vector3.INF) -> Dictionary:
	var direction := signf(player.x - guard.x)
	if is_zero_approx(direction): direction = 1.0
	var heading := route_heading(guard.x, direction)
	var section := route_section(guard.x)
	var rise := (float(section.toY)-float(section.fromY))/float(section.length)*direction
	var actor := route_position(guard.x,guard.y)
	var hand := hand_anchor
	if not hand.is_finite():
		hand = actor+heading*.12+Vector3(0,float(geometry.lighting.torchHeight),0)
	var source := hand+heading*.12
	var reach := float(geometry.lighting.torchRange)
	var height := maxf(.2,source.y-actor.y)
	return {"position":source,"target":source+heading*reach+Vector3(0,rise*reach-height,0),
		"case_position":source-heading*.09,"hand_position":hand}

func _contact() -> bool:
	if super._contact():
		return true
	var p := route_position(player.x, player.y)
	var g := route_position(guard.x, guard.y)
	return Vector2(p.x, p.z).distance_to(Vector2(g.x, g.z)) <= BODY_WIDTH + EPS \
	and absf(player.y - guard.y) <= BODY_HEIGHT + EPS

func proof(compress: bool = true) -> Dictionary:
	var inputs: Array = []
	if compress:
		for mask: int in input_log:
			if not inputs.is_empty() and int(inputs.back().mask) == mask:
				inputs.back().ticks += 1
			else:
				inputs.append({"mask": mask, "ticks": 1})
	else:
		inputs = input_log.duplicate()
	return {"kind": PROOF_KIND, "version": PROOF_VERSION, "physicsVersion": PHYSICS_VERSION,
		"geometryId": data().id, "geometryHash": geometry_hash(), "elapsedTicks": tick, "input": inputs}

static func _whole_in_range(value: Variant, low: int, high: int) -> bool:
	if typeof(value) == TYPE_INT:
		return value >= low and value <= high
	if typeof(value) == TYPE_FLOAT:
		return is_finite(value) and value == floor(value) and value >= low and value <= high
	return false

static func validate_proof(value: Variant) -> bool:
	if not value is Dictionary:
		return false
	if value.get("kind") != PROOF_KIND or not _whole_in_range(value.get("version"), 1, 1) \
	or not _whole_in_range(value.get("physicsVersion"), PHYSICS_VERSION, PHYSICS_VERSION):
		return false
	if value.get("geometryId") != data().id or value.get("geometryHash") != geometry_hash():
		return false
	if not _whole_in_range(value.get("elapsedTicks"), 1, MAX_TICKS):
		return false
	var elapsed := int(value.elapsedTicks)
	var raw: Variant = value.get("input")
	if not raw is Array or raw.is_empty() or raw.size() > MAX_TICKS:
		return false
	var expanded: Array = []
	var compressed: bool = raw[0] is Dictionary
	for record: Variant in raw:
		if compressed:
			if not record is Dictionary or not _whole_in_range(record.get("mask"), 0, 7) \
			or not _whole_in_range(record.get("ticks"), 1, MAX_TICKS):
				return false
			var count := int(record.ticks)
			# Bound BEFORE addition or expansion, including an int64-max segment
			# after a valid first entry. Never add untrusted integers to a size.
			if count > MAX_TICKS or count > elapsed - expanded.size():
				return false
			for _i: int in range(count):
				expanded.append(int(record.mask))
		else:
			if not _whole_in_range(record, 0, 7) or expanded.size() >= elapsed:
				return false
			expanded.append(int(record))
	if expanded.size() != elapsed:
		return false
	# Self-load avoids registering another global class in the production game.
	var model = load("res://scripts/games/chapter4_endless_stair_model.gd").new()
	for mask: int in expanded:
		if model.status != "running":
			return false
		model.step(mask)
	return model.status == "finished" and model.player_grounded and not model.guard_fell \
	and model.gates_passed == data().gates.size() and model.tick == elapsed
