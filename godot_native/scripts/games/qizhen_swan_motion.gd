extends RefCounted
## Small, rendering-independent chase simulation. All coordinates are source pixels.
## Disabled/cinematic time does not consume the player's opening contact protection.
const BODY_RADIUS: float = 22.0
const CATCH_DISTANCE: float = 65.0
const CONTACT_GRACE: float = 3.5
const GRACE_BUFFER: float = CATCH_DISTANCE + 55.0
const WARNING_SECONDS: float = 0.78
const CHARGE_SECONDS: float = 0.65
const RECOVERY_SECONDS: float = 0.85
const NEAR_SPEED: float = 238.0
const FAR_SPEED: float = 440.0
const CHARGE_SPEED: float = 575.0
const MAX_TURN_RATE: float = 2.8
const TURN_ACCELERATION: float = 9.0
const MAX_SUBSTEP: float = 1.0 / 120.0

var position: Vector2 = Vector2.ZERO
var heading: float = 0.0
var speed: float = 0.0
var phase: String = "tracking"
var elapsed: float = 0.0
var phase_time: float = 0.0
var aim: Vector2 = Vector2.ZERO
var caught: bool = false
var just_dodged: bool = false
var charge_count: int = 0
var spawn_valid: bool = false

var _water: Rect2 = Rect2()
var _obstacles: Array[Rect2] = []
var _turn_velocity: float = 0.0
var _charge_heading: float = 0.0
var _avoid_side: float = 1.0
var _was_enabled: bool = true
var _events: Array[String] = []
var _blocked_this_step: bool = false
var _phase_changed_this_step: bool = false

func reset(start: Vector2, start_heading: float, obstacles: Array, water: Rect2) -> void:
	_water = water.abs()
	_obstacles.clear()
	for value: Variant in obstacles:
		if value is Dictionary:
			var rect: Rect2 = Rect2(Vector2(float(value.get("left", 0.0)), float(value.get("top", 0.0))), Vector2(float(value.get("right", 0.0)) - float(value.get("left", 0.0)), float(value.get("bottom", 0.0)) - float(value.get("top", 0.0)))).abs()
			if rect.size.x > 0.0 and rect.size.y > 0.0:
				_obstacles.append(rect)
	position = _safe_spawn(start if start.is_finite() else _water.get_center())
	spawn_valid = _clear(position)
	heading = wrapf(start_heading, -PI, PI) if is_finite(start_heading) else 0.0
	speed = 0.0
	phase = "tracking"
	elapsed = 0.0
	phase_time = 0.0
	aim = position + Vector2.from_angle(heading) * 200.0
	caught = false
	just_dodged = false
	charge_count = 0
	_turn_velocity = 0.0
	_charge_heading = heading
	_avoid_side = 1.0
	_was_enabled = true
	_events.clear()
	_blocked_this_step = false
	_phase_changed_this_step = false

func step(delta: float, player: Vector2, player_velocity: Vector2, enabled: bool = true) -> Dictionary:
	_events.clear()
	just_dodged = false
	_blocked_this_step = false
	_phase_changed_this_step = false
	var was_caught: bool = caught
	var active: bool = enabled and not caught and spawn_valid and player.is_finite()
	if not active and phase != "coasting":
		_change_phase("coasting")
	elif active and not _was_enabled:
		_change_phase("tracking")
	_was_enabled = active
	# Bound exceptional stalls, but split normal frames finely enough that even
	# a thin fishing net cannot be crossed in one charge movement.
	var remaining: float = clampf(delta, 0.0, 0.5) if is_finite(delta) else 0.0
	var velocity: Vector2 = player_velocity if player_velocity.is_finite() else Vector2.ZERO
	while remaining > 0.000001:
		var dt: float = minf(remaining, MAX_SUBSTEP)
		remaining -= dt
		_substep(dt, player, velocity, active and not caught)
	var cue: String = _events[-1] if not _events.is_empty() else "none"
	return {"phase_changed": _phase_changed_this_step, "cue": cue, "events": _events.duplicate(), "caught": caught, "caught_now": caught and not was_caught, "dodged": just_dodged, "blocked": _blocked_this_step, "spawn_valid": spawn_valid, "position": position, "heading": heading, "speed": speed, "phase": phase, "protected": elapsed < CONTACT_GRACE}

func _substep(dt: float, player: Vector2, player_velocity: Vector2, active: bool) -> void:
	if not active:
		_turn_velocity = move_toward(_turn_velocity, 0.0, TURN_ACCELERATION * dt)
		heading = wrapf(heading + _turn_velocity * dt, -PI, PI)
		speed = move_toward(speed, 0.0, 330.0 * dt)
		_move(dt, player, false)
		return
	elapsed += dt
	phase_time += dt
	var gap: float = position.distance_to(player)
	if phase == "tracking" and phase_time >= 1.45 and elapsed >= CONTACT_GRACE - WARNING_SECONDS and gap >= 105.0 and gap <= 470.0 and _line_clear(position, player, BODY_RADIUS):
		aim = player + player_velocity.limit_length(340.0) * 0.22
		if not _line_clear(position, aim, BODY_RADIUS):
			aim = player
		_charge_heading = (aim - position).angle()
		_change_phase("charge_warning")
	elif phase == "charge_warning" and phase_time >= WARNING_SECONDS and absf(angle_difference(heading, _charge_heading)) <= 0.12:
		# Freeze the ACTUAL body direction. There is no facing snap, and player
		# position/velocity cannot alter this direction during the charge.
		_charge_heading = heading
		_turn_velocity = 0.0
		charge_count += 1
		_change_phase("charge")
	elif phase == "charge" and phase_time >= CHARGE_SECONDS:
		_finish_charge()
	elif phase == "recovery" and phase_time >= RECOVERY_SECONDS:
		_change_phase("tracking")

	var target_heading: float = heading
	var target_speed: float = 0.0
	match phase:
		"tracking":
			aim = player + player_velocity.limit_length(340.0) * 0.12
			target_heading = _steering_heading(aim)
			var pressure: float = smoothstep(130.0, 500.0, gap)
			target_speed = lerpf(NEAR_SPEED, FAR_SPEED, pressure)
		"charge_warning":
			target_heading = _charge_heading
			target_speed = 70.0
		"charge":
			target_heading = _charge_heading
			target_speed = CHARGE_SPEED
		"recovery":
			target_heading = _steering_heading(player)
			target_speed = 110.0
	if phase != "charge":
		_turn_toward(target_heading, dt, 1.8 if phase == "recovery" else MAX_TURN_RATE)
		# Tight turns slow the body instead of making the actor slide sideways.
		var alignment: float = maxf(0.0, cos(angle_difference(heading, target_heading)))
		target_speed *= lerpf(0.20, 1.0, alignment * alignment)
	if elapsed < CONTACT_GRACE and Vector2.from_angle(heading).dot(player - position) > 0.0:
		# Keep a physical gap while the opening protection is active. The
		# braking envelope reaches zero at the buffer, before contact can arm.
		var stopping_room: float = maxf(0.0, gap - GRACE_BUFFER)
		var buffer_speed: float = minf(sqrt(2.0 * 650.0 * stopping_room) * 0.85, stopping_room * 4.0)
		target_speed = minf(target_speed, buffer_speed)
	var acceleration: float = 950.0 if phase == "charge" else 360.0
	if target_speed < speed:
		acceleration = 1050.0 if phase in ["charge_warning", "recovery"] else 650.0
	speed = move_toward(speed, target_speed, acceleration * dt)
	_move(dt, player, true)

func _turn_toward(target: float, dt: float, turn_rate: float) -> void:
	var difference: float = angle_difference(heading, target)
	var desired_rate: float = clampf(difference * 4.0, -turn_rate, turn_rate)
	_turn_velocity = move_toward(_turn_velocity, desired_rate, TURN_ACCELERATION * dt)
	var turn: float = _turn_velocity * dt
	if absf(turn) > absf(difference) and signf(turn) == signf(difference):
		turn = difference
		_turn_velocity = 0.0
	heading = wrapf(heading + turn, -PI, PI)

func _move(dt: float, player: Vector2, can_catch: bool) -> void:
	if not spawn_valid:
		speed = 0.0
		return
	var destination: Vector2 = position + Vector2.from_angle(heading) * speed * dt
	var current_gap: float = position.distance_to(player)
	var next_gap: float = destination.distance_to(player)
	if elapsed < CONTACT_GRACE and player.is_finite() and next_gap < GRACE_BUFFER and next_gap < current_gap:
		# Last-resort substep guard for a stall or an unusually fast initial
		# speed. Hold at the current legal point; never push/teleport the swan
		# or the kayak to fabricate separation. Moving away stays available.
		speed = move_toward(speed, 0.0, 1600.0 * dt)
		return
	if _clear(destination):
		position = destination
	else:
		_blocked_this_step = true
		# Never project the body through a bank or make its facing jump.
		speed = move_toward(speed, 0.0, 1600.0 * dt)
		if phase == "charge":
			_finish_charge()
	if can_catch and elapsed >= CONTACT_GRACE and position.distance_to(player) <= CATCH_DISTANCE and _line_clear(position, player, 0.0):
		caught = true
		_events.append("caught")

func _finish_charge() -> void:
	if not caught:
		just_dodged = true
	_change_phase("recovery")

func _change_phase(next: String) -> void:
	_phase_changed_this_step = true
	phase = next
	phase_time = 0.0
	_events.append({"charge_warning": "telegraph", "charge": "surge", "recovery": "recover", "tracking": "track", "coasting": "coast"}.get(next, next))

func _steering_heading(target: Vector2) -> float:
	var offset: Vector2 = target - position
	if offset.length_squared() < 1.0:
		return heading
	var desired: float = offset.angle()
	var lookahead: float = clampf(speed * 0.48 + 60.0, 90.0, 240.0)
	if _line_clear(position, position + Vector2.from_angle(desired) * minf(lookahead, offset.length()), BODY_RADIUS + 4.0):
		return desired
	# Local bank avoidance has a stable side bias, so a blocked nose turns
	# gradually toward clear water instead of alternating left/right every frame.
	var best_heading: float = heading + _avoid_side * PI * 0.5
	var best_score: float = -INF
	for index: int in range(-12, 13):
		var candidate: float = desired + float(index) * PI / 12.0
		var direction: Vector2 = Vector2.from_angle(candidate)
		var free_distance: float = 0.0
		for probe: int in range(1, 9):
			var distance: float = lookahead * float(probe) / 8.0
			if not _clear(position + direction * distance, BODY_RADIUS + 4.0):
				break
			free_distance = distance
		var progress: float = cos(angle_difference(candidate, desired))
		var side: float = signf(angle_difference(heading, candidate))
		var score: float = free_distance / lookahead * 3.0 + progress * 0.9 + cos(angle_difference(heading, candidate)) * 0.25 + (0.18 if side == _avoid_side else 0.0)
		if score > best_score:
			best_score = score
			best_heading = candidate
	var selected_side: float = signf(angle_difference(heading, best_heading))
	if selected_side != 0.0:
		_avoid_side = selected_side
	return best_heading

func _clear(point: Vector2, radius: float = BODY_RADIUS) -> bool:
	if not point.is_finite() or _water.size.x < radius * 2.0 or _water.size.y < radius * 2.0:
		return false
	if point.x < _water.position.x + radius or point.x > _water.end.x - radius or point.y < _water.position.y + radius or point.y > _water.end.y - radius:
		return false
	for rect: Rect2 in _obstacles:
		var closest: Vector2 = Vector2(clampf(point.x, rect.position.x, rect.end.x), clampf(point.y, rect.position.y, rect.end.y))
		if point.distance_squared_to(closest) <= radius * radius + 0.001:
			return false
	return true

func _line_clear(start: Vector2, finish: Vector2, radius: float) -> bool:
	if not _clear(start, radius) or not _clear(finish, radius):
		return false
	# Slab intersection against inflated rectangles is conservative at corners.
	# It also prevents a catch reaching through a thin net between two bodies.
	var direction: Vector2 = finish - start
	for obstacle: Rect2 in _obstacles:
		var rect: Rect2 = obstacle.grow(radius)
		var enter: float = 0.0
		var leave: float = 1.0
		for axis: int in range(2):
			if absf(direction[axis]) < 0.000001:
				if start[axis] < rect.position[axis] or start[axis] > rect.end[axis]:
					enter = 2.0
					break
			else:
				var near: float = (rect.position[axis] - start[axis]) / direction[axis]
				var far: float = (rect.end[axis] - start[axis]) / direction[axis]
				enter = maxf(enter, minf(near, far))
				leave = minf(leave, maxf(near, far))
		if enter <= leave:
			return false
	return true

func _safe_spawn(start: Vector2) -> Vector2:
	if _water.size.x < BODY_RADIUS * 2.0 or _water.size.y < BODY_RADIUS * 2.0:
		return _water.get_center()
	var center: Vector2 = Vector2(clampf(start.x, _water.position.x + BODY_RADIUS + 1.0, _water.end.x - BODY_RADIUS - 1.0), clampf(start.y, _water.position.y + BODY_RADIUS + 1.0, _water.end.y - BODY_RADIUS - 1.0))
	if _clear(center):
		return center
	var maximum: float = _water.size.length()
	var distance: float = 8.0
	while distance <= maximum:
		var samples: int = maxi(16, ceili(TAU * distance / 12.0))
		for index: int in range(samples):
			var candidate: Vector2 = center + Vector2.from_angle(TAU * float(index) / float(samples)) * distance
			if _clear(candidate):
				return candidate
		distance += 8.0
	# An invalid all-solid map is exposed as spawn_valid=false. Never move or
	# catch from an illegal fallback point and never silently erase obstacles.
	return center
