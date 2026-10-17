extends RefCounted
## Independent, input-driven CHANNEL chase. Coordinates are original 1672 x 941 pixels.
## No presentation calls, saves, scripted player travel, or time-based victory.
## SOURCE_OBSTACLES is the complete unchanged channel.kayakCollisions list in data/worlds.json.
const SOURCE_OBSTACLES: Array = [
	{
		"id": "world_left",
		"left": 0,
		"top": 0,
		"right": 28,
		"bottom": 941
	},
	{
		"id": "world_right",
		"left": 1644,
		"top": 0,
		"right": 1672,
		"bottom": 941
	},
	{
		"id": "world_top",
		"left": 0,
		"top": 0,
		"right": 1672,
		"bottom": 28
	},
	{
		"id": "world_bottom",
		"left": 0,
		"top": 913,
		"right": 1672,
		"bottom": 941
	},
	{
		"id": "north_bank_west",
		"left": 0,
		"top": 0,
		"right": 650,
		"bottom": 174
	},
	{
		"id": "north_bank_willow_1",
		"left": 650,
		"top": 0,
		"right": 755,
		"bottom": 198
	},
	{
		"id": "north_bank_center",
		"left": 755,
		"top": 0,
		"right": 1185,
		"bottom": 174
	},
	{
		"id": "north_bank_willow_2",
		"left": 1185,
		"top": 0,
		"right": 1300,
		"bottom": 202
	},
	{
		"id": "north_bank_east",
		"left": 1300,
		"top": 0,
		"right": 1605,
		"bottom": 178
	},
	{
		"id": "right_upper_bank",
		"left": 1605,
		"top": 0,
		"right": 1672,
		"bottom": 438
	},
	{
		"id": "south_bank_west",
		"left": 0,
		"top": 770,
		"right": 1400,
		"bottom": 941
	},
	{
		"id": "south_bank_step_1",
		"left": 1400,
		"top": 730,
		"right": 1500,
		"bottom": 941
	},
	{
		"id": "south_bank_step_2",
		"left": 1500,
		"top": 650,
		"right": 1560,
		"bottom": 941
	},
	{
		"id": "south_bank_step_3",
		"left": 1560,
		"top": 570,
		"right": 1672,
		"bottom": 941
	},
	{
		"id": "floating_raft",
		"left": 555,
		"top": 374,
		"right": 712,
		"bottom": 525
	},
	{
		"id": "west_net",
		"left": 448,
		"top": 432,
		"right": 555,
		"bottom": 532
	},
	{
		"id": "raft_mooring_nw",
		"left": 505,
		"top": 388,
		"right": 528,
		"bottom": 435
	},
	{
		"id": "raft_mooring_se",
		"left": 685,
		"top": 525,
		"right": 708,
		"bottom": 572
	},
	{
		"id": "right_dock",
		"left": 1548,
		"top": 450,
		"right": 1672,
		"bottom": 580
	},
	{
		"id": "rock_west",
		"left": 304,
		"top": 559,
		"right": 339,
		"bottom": 591
	},
	{
		"id": "rock_mid_east_large",
		"left": 1233,
		"top": 530,
		"right": 1272,
		"bottom": 565
	},
	{
		"id": "rock_mid_east_small",
		"left": 1263,
		"top": 553,
		"right": 1296,
		"bottom": 585
	},
	{
		"id": "rock_east",
		"left": 1369,
		"top": 516,
		"right": 1405,
		"bottom": 547
	},
	{
		"id": "buoy_1",
		"left": 80,
		"top": 498,
		"right": 96,
		"bottom": 522
	},
	{
		"id": "buoy_2",
		"left": 365,
		"top": 442,
		"right": 381,
		"bottom": 467
	},
	{
		"id": "buoy_3",
		"left": 936,
		"top": 441,
		"right": 952,
		"bottom": 467
	},
	{
		"id": "buoy_4",
		"left": 1231,
		"top": 445,
		"right": 1247,
		"bottom": 468
	},
	{
		"id": "buoy_5",
		"left": 1481,
		"top": 441,
		"right": 1497,
		"bottom": 467
	}
]
const WORLD_SIZE := Vector2(1672.0, 941.0)
const PLAYER_START := Vector2(1390.0, 350.0)
const SWAN_START := Vector2(1510.0, 320.0)
const HULL_HALF_LENGTH: float = 38.0
const HULL_HALF_WIDTH: float = 22.0
const MAX_SPEED: float = 100.0
const MAX_REVERSE_SPEED: float = 54.0
const DRAG: float = 0.65
const MIN_STROKE_INTERVAL: float = 0.20
const FIXED_STEP: float = 1.0 / 120.0
const GATE_X: float = 240.0
const GATE_GAP := Rect2(230.0, 430.0, 20.0, 130.0)
const BERTH := Rect2(115.0, 450.0, 75.0, 95.0)
const BERTH_SPEED: float = 18.0
const BERTH_HEADING_TOLERANCE: float = 0.32
const BERTH_DWELL: float = 0.6
const SWAN_RADIUS: float = 22.0
# Bird body stays east of the visible territorial rope; kayak uses full map.
const SWAN_WEST_LIMIT: float = 272.0
const CATCH_DISTANCE: float = 48.0
const OPENING_GRACE: float = 3.5
const WARNING_SECONDS: float = 1.25
const CHARGE_SECONDS: float = 1.35
const RECOVERY_SECONDS: float = 3.4
const TRACK_SECONDS: float = 2.0
const CHARGE_SPEED: float = 285.0

# Public state, all mutable runtime state is reset by reset().
var position: Vector2 = PLAYER_START
var heading: float = PI
var speed: float = 0.0
var roll: float = 0.0
var swan_position: Vector2 = SWAN_START
var swan_heading: float = PI
var swan_speed: float = 0.0
var swan_phase: String = "tracking"
var swan_aim: Vector2 = PLAYER_START
var swan_lock_origin: Vector2 = SWAN_START
var swan_attack_heading: float = PI
var swan_phase_time: float = 0.0
var swan_charge_count: int = 0
var swan_dodges: int = 0
var swan_blocked: bool = false
var swan_gap: float = 0.0
var stage: String = "opening"
var intro: bool = true
var paused: bool = false
var outcome: String = "running"
var elapsed: float = 0.0
var tick: int = 0
var collisions: int = 0
var last_collision_id: String = ""
var accepted_inputs: Array[Dictionary] = []
var route_history: Array[Vector2] = []
var next_story: String = "3.5"
var hint: String = "交替划桨向西；留意天鹅锁定的冲刺方向"
var gate_passed: bool = false
var raft_passed: bool = false
var raft_route: String = ""
var berth_dwell: float = 0.0
var alternations: int = 0
var repeat_count: int = 0
var repeat_warn_count: int = 5
var repeat_fail_count: int = 14
var capsize_limit: float = 1.15
var source_obstacles: Array = []
var gate_obstacles: Array = []
var obstacles: Array = []
var gate_hint: Vector2 = Vector2(290.0, 495.0)
var berth_hint: Vector2 = Vector2(170.0, 495.0)

var _last_stroke_time: float = -100.0
var _last_side: String = ""
var _last_reverse: bool = false
var _remainder: float = 0.0
var _record_time: float = 0.0
var _collision_latched: bool = false
var _charge_heading: float = PI
var _swan_turn_velocity: float = 0.0
var _raft_route_entered: String = ""

func _init() -> void:
	reset()

func reset(skip_intro: bool = false) -> void:
	position = PLAYER_START
	heading = PI
	speed = 0.0
	roll = 0.0
	swan_position = SWAN_START
	swan_heading = (PLAYER_START - SWAN_START).angle()
	swan_speed = 0.0
	swan_phase = "tracking"
	swan_aim = PLAYER_START
	swan_lock_origin = SWAN_START
	swan_attack_heading = swan_heading
	swan_phase_time = 0.0
	swan_charge_count = 0
	swan_dodges = 0
	swan_blocked = false
	swan_gap = position.distance_to(swan_position)
	stage = "opening"
	intro = not skip_intro
	paused = false
	outcome = "running"
	elapsed = 0.0
	tick = 0
	collisions = 0
	last_collision_id = ""
	accepted_inputs.clear()
	route_history.clear()
	route_history.append(position)
	next_story = "3.5"
	hint = "交替划桨向西；留意天鹅锁定的冲刺方向"
	gate_passed = false
	raft_passed = false
	raft_route = ""
	berth_dwell = 0.0
	alternations = 0
	repeat_count = 0
	source_obstacles = SOURCE_OBSTACLES.duplicate(true)
	gate_obstacles = [
		{"id": "final_gate_north", "left": 230, "top": 174, "right": 250, "bottom": 430},
		{"id": "final_gate_south", "left": 230, "top": 560, "right": 250, "bottom": 770}
	]
	obstacles = source_obstacles.duplicate(true)
	obstacles.append_array(gate_obstacles)
	obstacles.append({"id": "visible_west_rock", "left": 235, "top": 640, "right": 272, "bottom": 677})
	_last_stroke_time = -100.0
	_last_side = ""
	_last_reverse = false
	_remainder = 0.0
	_record_time = 0.0
	_collision_latched = false
	_charge_heading = swan_heading
	_swan_turn_velocity = 0.0
	_raft_route_entered = ""

func begin() -> void:
	if outcome == "running":
		intro = false

func set_paused(value: bool) -> void:
	paused = value
	# No fractional pre-pause simulation is carried into resumption.
	_remainder = 0.0

func stroke(side: String, reverse: bool = false) -> bool:
	if side not in ["left", "right"] or paused or intro or outcome != "running":
		return false
	if elapsed - _last_stroke_time < MIN_STROKE_INTERVAL - 0.000001:
		return false
	var in_cadence: bool = elapsed - _last_stroke_time <= 1.45
	var alternating: bool = in_cadence and _last_side != "" and side != _last_side and reverse == _last_reverse
	var repeated: bool = in_cadence and side == _last_side and reverse == _last_reverse
	repeat_count = repeat_count + 1 if repeated else 1
	var side_sign: float = 1.0 if side == "left" else -1.0
	var direction: float = -1.0 if reverse else 1.0
	var impulse: float = (23.0 if alternating else 16.0) if reverse else (26.0 if alternating else 17.0)
	speed = clampf(speed + impulse * direction, -MAX_REVERSE_SPEED, MAX_SPEED)
	var turn: float = 0.13 + minf(0.10, float(repeat_count) * 0.025)
	# Sweep the oriented hull while turning; a stroke may brake/reverse even
	# when the adjacent wall blocks its yaw. No collision latch traps the boat.
	_sweep_turn(side_sign * direction * turn)
	if alternating:
		roll *= 0.42
		alternations += 1
	else:
		roll += side_sign * (0.12 + minf(0.05, float(repeat_count) * 0.01))
	accepted_inputs.append({"tick": tick, "time": elapsed, "side": side, "reverse": reverse, "alternating": alternating})
	_last_stroke_time = elapsed
	_last_side = side
	_last_reverse = reverse
	if repeat_count >= repeat_fail_count or absf(roll) >= capsize_limit:
		_lose("连续同侧划桨失去平衡；换侧可稳住船身")
	elif repeat_count >= repeat_warn_count or absf(roll) >= 0.65:
		hint = "船身倾斜：换一侧划桨恢复平衡"
	else:
		_update_hint()
	return true

func step(delta: float) -> void:
	if paused or intro or outcome != "running" or not is_finite(delta) or delta <= 0.0:
		return
	# Long application stalls do not fast-forward a live attack through the player.
	_remainder += minf(delta, 0.25)
	while _remainder >= FIXED_STEP - 0.0000001 and outcome == "running":
		_remainder -= FIXED_STEP
		_substep(FIXED_STEP)

func _substep(dt: float) -> void:
	tick += 1
	elapsed = float(tick) * FIXED_STEP
	speed *= exp(-DRAG * dt)
	roll *= exp(-1.05 * dt)
	if absf(speed) < 0.3:
		speed = 0.0
	var previous: Vector2 = position
	var candidate: Vector2 = position + Vector2.from_angle(heading) * speed * dt
	var blocking: String = hull_collision(candidate, heading)
	if blocking == "":
		position = candidate
		_collision_latched = false
	elif absf(speed) > 0.01:
		_register_collision(blocking)
		speed = 0.0
	_record_time += dt
	if _record_time >= 0.1 and position.distance_to(route_history[-1]) >= 1.0:
		route_history.append(position)
		_record_time = 0.0
	_update_route(previous)
	# A fully completed berth wins on its completion tick before contact is tested.
	var berth_valid: bool = gate_passed and raft_passed and BERTH.has_point(position) and absf(speed) <= BERTH_SPEED and absf(angle_difference(heading, PI)) <= BERTH_HEADING_TOLERANCE and hull_collision(position, heading) == ""
	berth_dwell = berth_dwell + dt if berth_valid else 0.0
	if berth_dwell >= BERTH_DWELL:
		outcome = "won"
		stage = "complete"
		speed = 0.0
		hint = "已穿过窄口并稳稳靠岸；进入剧情 3.5"
	else:
		_update_swan(dt)
		_update_hint()

func _update_route(previous: Vector2) -> void:
	# These are geometric evidence of real crossings, never movement commands.
	if position.x >= 448.0 and position.x <= 730.0 and hull_collision(position, heading) == "":
		# Classify the legal water actually traversed. These labels must not
		# impose a narrower corridor than the physical raft/mooring geometry.
		_raft_route_entered = "upper" if position.y < 470.0 else "lower"
	if previous.x >= 410.0 and position.x < 410.0 and _raft_route_entered != "":
		raft_passed = true
		raft_route = _raft_route_entered
	if previous.x >= GATE_X and position.x < GATE_X and position.y > GATE_GAP.position.y and position.y < GATE_GAP.end.y and hull_collision(position, heading) == "":
		gate_passed = true
	if gate_passed:
		stage = "berth"
	elif position.x < 440.0:
		stage = "gate"
	elif position.x < 830.0:
		stage = "raft"
	elif position.x < 1130.0:
		stage = "wide_water"
	else:
		stage = "opening"

func _update_hint() -> void:
	if outcome != "running":
		return
	if stage == "berth":
		hint = "已进入浮绳内安全区：船头朝西，反划减速并稳稳靠岸"
	elif repeat_count >= repeat_warn_count and elapsed - _last_stroke_time < 1.2:
		hint = "船身倾斜：换一侧划桨恢复平衡"
	elif _collision_latched:
		hint = "船头碰到障碍：反划退出，再换侧转向"
	elif swan_phase == "charge_warning":
		hint = "天鹅已锁定方向！换侧转弯，离开冲刺线"
	elif swan_phase == "charge":
		hint = "冲刺方向已固定；保持侧向避让"
	elif stage == "gate":
		hint = "对准左侧窄口；先转正，再直划穿过"
	elif stage == "raft":
		hint = "绕过浮排：走上方水道或下方宽水面"
	elif swan_phase == "recovery":
		hint = "天鹅正在回转；交替划桨拉开距离"
	else:
		hint = "交替划桨向西；蓄力时换侧避开锁定方向"

func _sweep_turn(amount: float) -> void:
	var count: int = maxi(1, ceili(absf(amount) / 0.02))
	var increment: float = amount / float(count)
	for unused: int in range(count):
		var candidate: float = wrapf(heading + increment, -PI, PI)
		var blocking: String = hull_collision(position, candidate)
		if blocking != "":
			_register_collision(blocking)
			return
		heading = candidate

func _register_collision(id: String) -> void:
	if not _collision_latched or id != last_collision_id:
		collisions += 1
	last_collision_id = id
	_collision_latched = true

# SAT for the full oriented kayak, tested against every original source rectangle.
func hull_collision(center: Vector2, angle: float) -> String:
	if not center.is_finite() or not is_finite(angle):
		return "invalid_position"
	var forward: Vector2 = Vector2.from_angle(angle)
	var lateral: Vector2 = Vector2(-forward.y, forward.x)
	for obstacle: Dictionary in obstacles:
		var rect: Rect2 = _rect(obstacle)
		var half: Vector2 = rect.size * 0.5
		var offset: Vector2 = center - rect.get_center()
		if absf(offset.x) > half.x + HULL_HALF_LENGTH * absf(forward.x) + HULL_HALF_WIDTH * absf(lateral.x):
			continue
		if absf(offset.y) > half.y + HULL_HALF_LENGTH * absf(forward.y) + HULL_HALF_WIDTH * absf(lateral.y):
			continue
		if absf(offset.dot(forward)) > HULL_HALF_LENGTH + half.x * absf(forward.x) + half.y * absf(forward.y):
			continue
		if absf(offset.dot(lateral)) > HULL_HALF_WIDTH + half.x * absf(lateral.x) + half.y * absf(lateral.y):
			continue
		return str(obstacle.id)
	return ""

func _update_swan(dt: float) -> void:
	swan_phase_time += dt
	swan_blocked = false
	swan_gap = swan_position.distance_to(position)
	if swan_phase == "tracking" and swan_phase_time >= TRACK_SECONDS and elapsed >= OPENING_GRACE - WARNING_SECONDS and swan_gap >= 110.0 and swan_gap <= 330.0 and _swan_line_clear(swan_position, position):
		swan_aim = position + Vector2.from_angle(heading) * speed * 0.3
		if not _circle_clear(swan_aim, SWAN_RADIUS):
			swan_aim = position
		_charge_heading = (swan_aim - swan_position).angle()
		swan_attack_heading = _charge_heading
		swan_lock_origin = swan_position
		_set_swan_phase("charge_warning")
	elif swan_phase == "charge_warning" and swan_phase_time >= WARNING_SECONDS and absf(angle_difference(swan_heading, _charge_heading)) <= 0.01:
		_charge_heading = swan_heading
		_swan_turn_velocity = 0.0
		swan_charge_count += 1
		_set_swan_phase("charge")
	elif swan_phase == "charge" and swan_phase_time >= CHARGE_SECONDS:
		_finish_charge()
	elif swan_phase == "recovery" and swan_phase_time >= RECOVERY_SECONDS:
		_set_swan_phase("tracking")
	var target_heading: float = swan_heading
	var target_speed: float = 0.0
	match swan_phase:
		"tracking":
			var target: Vector2 = _swan_navigation_target()
			target_heading = (target - swan_position).angle()
			target_speed = lerpf(45.0, 162.0, smoothstep(110.0, 420.0, swan_gap))
		"charge_warning":
			target_heading = _charge_heading
			target_speed = 16.0
		"charge":
			target_heading = _charge_heading
			target_speed = CHARGE_SPEED
		"recovery":
			target_heading = _charge_heading if swan_phase_time < 0.45 else (_swan_navigation_target() - swan_position).angle()
			target_speed = 8.0
	if swan_phase != "charge":
		var difference: float = angle_difference(swan_heading, target_heading)
		var turn_rate: float = 1.8 if swan_phase == "recovery" else 2.6
		var desired_rate: float = clampf(difference * 4.2, -turn_rate, turn_rate)
		_swan_turn_velocity = move_toward(_swan_turn_velocity, desired_rate, 8.0 * dt)
		var turn: float = _swan_turn_velocity * dt
		if absf(turn) > absf(difference) and signf(turn) == signf(difference):
			turn = difference
			_swan_turn_velocity = 0.0
		swan_heading = wrapf(swan_heading + turn, -PI, PI)
		var alignment: float = maxf(0.0, cos(angle_difference(swan_heading, target_heading)))
		target_speed *= lerpf(0.15, 1.0, alignment * alignment)
	if elapsed < OPENING_GRACE and Vector2.from_angle(swan_heading).dot(position - swan_position) > 0.0:
		# Physical braking, never a grace-period teleport.
		target_speed = minf(target_speed, maxf(0.0, swan_gap - 120.0) * 3.0)
	if cos(swan_heading) < 0.0:
		var bank_room: float = maxf(0.0, swan_position.x - SWAN_WEST_LIMIT - SWAN_RADIUS)
		target_speed = minf(target_speed, minf(sqrt(2.0 * 700.0 * bank_room) * 0.85, bank_room * 4.0))
		if swan_phase == "charge" and bank_room <= 1.0:
			_finish_charge()
	var acceleration: float = 520.0 if swan_phase == "charge" else 210.0
	if target_speed < swan_speed:
		acceleration = 700.0
	swan_speed = move_toward(swan_speed, target_speed, acceleration * dt)
	var candidate: Vector2 = swan_position + Vector2.from_angle(swan_heading) * swan_speed * dt
	if elapsed < OPENING_GRACE and candidate.distance_to(position) < 120.0 and candidate.distance_to(position) < swan_gap:
		swan_speed = 0.0
	elif _circle_clear(candidate, SWAN_RADIUS):
		swan_position = candidate
	else:
		swan_blocked = true
		swan_speed = 0.0
		if swan_phase == "charge":
			_finish_charge()
	swan_gap = swan_position.distance_to(position)
	if elapsed >= OPENING_GRACE and swan_gap <= CATCH_DISTANCE and _swan_line_clear(swan_position, position, 0.0):
		_lose("天鹅追上了船；看清锁向预警，再转向避让")

func _swan_navigation_target() -> Vector2:
	if _swan_line_clear(swan_position, position):
		return position
	# Follow physically recorded player water when direct pursuit is obstructed.
	# The bird still turns and swims continuously. It never jumps to the trail.
	for index: int in range(route_history.size() - 1, -1, -1):
		if route_history[index].distance_to(swan_position) > 24.0 and _swan_line_clear(swan_position, route_history[index]):
			return route_history[index]
	# Local fallback gives a blocked nose a clear turning direction.
	var best: Vector2 = swan_position
	var best_score: float = -INF
	for index: int in range(-8, 9):
		var candidate: Vector2 = swan_position + Vector2.from_angle(swan_heading + float(index) * PI / 8.0) * 70.0
		if _swan_line_clear(swan_position, candidate):
			var score: float = -candidate.distance_to(position)
			if score > best_score:
				best = candidate
				best_score = score
	return best

func _circle_clear(point: Vector2, radius: float) -> bool:
	if point.x < SWAN_WEST_LIMIT + radius or point.y < radius or point.x > WORLD_SIZE.x - radius or point.y > WORLD_SIZE.y - radius:
		return false
	for obstacle: Dictionary in obstacles:
		var rect: Rect2 = _rect(obstacle)
		var closest: Vector2 = Vector2(clampf(point.x, rect.position.x, rect.end.x), clampf(point.y, rect.position.y, rect.end.y))
		if point.distance_squared_to(closest) <= radius * radius:
			return false
	return true

func _swan_line_clear(start: Vector2, finish: Vector2, radius: float = SWAN_RADIUS) -> bool:
	if not _circle_clear(start, radius) or not _circle_clear(finish, radius):
		return false
	var offset: Vector2 = finish - start
	for obstacle: Dictionary in obstacles:
		var rect: Rect2 = _rect(obstacle).grow(radius)
		var enter: float = 0.0
		var leave: float = 1.0
		for axis: int in range(2):
			if absf(offset[axis]) < 0.000001:
				if start[axis] < rect.position[axis] or start[axis] > rect.end[axis]:
					enter = 2.0
					break
			else:
				var near: float = (rect.position[axis] - start[axis]) / offset[axis]
				var far: float = (rect.end[axis] - start[axis]) / offset[axis]
				enter = maxf(enter, minf(near, far))
				leave = minf(leave, maxf(near, far))
		if enter <= leave:
			return false
	return true

func _set_swan_phase(value: String) -> void:
	swan_phase = value
	swan_phase_time = 0.0

func _finish_charge() -> void:
	swan_dodges += 1
	_set_swan_phase("recovery")

func _lose(message: String) -> void:
	outcome = "lost"
	stage = "failed"
	speed = 0.0
	hint = message

static func _rect(value: Dictionary) -> Rect2:
	return Rect2(float(value.left), float(value.top), float(value.right) - float(value.left), float(value.bottom) - float(value.top))

func result() -> Dictionary:
	return {"protocol": "qizhen-playable-chase-v1", "success": outcome == "won", "outcome": outcome, "next_story": next_story if outcome == "won" else "", "elapsed": elapsed, "ticks": tick, "position": position, "heading": heading, "collisions": collisions, "input_count": accepted_inputs.size(), "inputs": accepted_inputs.duplicate(true), "raft_route": raft_route, "gate_passed": gate_passed, "berth_dwell": berth_dwell, "swan_dodges": swan_dodges}
