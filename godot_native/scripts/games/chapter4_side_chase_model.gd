extends RefCounted
## Reconstructed isolated chase physics, 2026-10-10. Not recovered original bytes.
## Route coordinates are metres; y is the actor's feet and increases upwards.
## No controller, chapter state, save, rendering, or wall-clock dependency.

const LEFT := 1
const RIGHT := 2
const JUMP := 4
const TICK_RATE := 60
const DT := 1.0 / TICK_RATE
const PLAYER_SPEED := 3.25
const GUARD_SPEED := 2.71875
const GRAVITY := 20.0
const JUMP_SPEED := 7.6
const BODY_WIDTH := 0.5
const HALF_WIDTH := BODY_WIDTH / 2.0
const BODY_HEIGHT := 1.45
const EPS := 0.00001
const MAX_TICKS := 7200

var geometry: Dictionary = {}
var player := Vector2.ZERO
var guard := Vector2.ZERO
var player_velocity := Vector2.ZERO
var guard_velocity := Vector2.ZERO
var player_grounded := false
var guard_grounded := false
var guard_fell := false
var status := "running"
var failure_reason := ""
var tick := 0
var gates_passed := 0
var input_log: Array = []
var last_input := 0
var _boxes: Array[Rect2] = []

func _init(custom_geometry: Dictionary = {}) -> void:
	geometry = (_default_geometry() if custom_geometry.is_empty() else custom_geometry).duplicate(true)
	_build_boxes()
	reset()

func _default_geometry() -> Dictionary:
	return {
		"spawn": {"player": [1.0, 0.0], "guard": [-3.4, 0.0]},
		"bounds": [-6.0, 65.9], "killY": -5.0, "fallDepth": 2.4,
		"floors": [{"x": -6.0, "y": -0.3, "width": 71.9, "height": 0.3}],
		"obstacles": [], "gates": [], "exit": {"x": 65.5, "minY": -0.05, "maxY": 0.05}
	}

func _build_boxes() -> void:
	_boxes.clear()
	for group: String in ["floors", "obstacles"]:
		for raw: Dictionary in geometry.get(group, []):
			if raw.has("rect"):
				var r: Array = raw.rect
				_boxes.append(Rect2(float(r[0]), float(r[1]), float(r[2]), float(r[3])))
			else:
				_boxes.append(Rect2(float(raw.x), float(raw.y), float(raw.width), float(raw.height)))

func reset() -> void:
	player = Vector2(float(geometry.spawn.player[0]), float(geometry.spawn.player[1]))
	guard = Vector2(float(geometry.spawn.guard[0]), float(geometry.spawn.guard[1]))
	player_velocity = Vector2.ZERO
	guard_velocity = Vector2.ZERO
	player_grounded = _has_support(player)
	guard_grounded = _has_support(guard)
	guard_fell = false
	status = "running"
	failure_reason = ""
	tick = 0
	gates_passed = 0
	input_log.clear()
	last_input = 0

func actor_open(at: Vector2) -> bool:
	for box: Rect2 in _boxes:
		if at.x + HALF_WIDTH > box.position.x + EPS and at.x - HALF_WIDTH < box.end.x - EPS \
		and at.y + BODY_HEIGHT > box.position.y + EPS and at.y < box.end.y - EPS:
			return false
	return true

func _has_support(at: Vector2) -> bool:
	for box: Rect2 in _boxes:
		if absf(at.y - box.end.y) <= EPS and at.x + HALF_WIDTH > box.position.x + EPS \
		and at.x - HALF_WIDTH < box.end.x - EPS:
			return true
	return false

func _max_step_height() -> float:
	return 0.0

func _horizontal_limit(at: Vector2, target_x: float) -> float:
	var result := target_x
	for box: Rect2 in _boxes:
		if at.y >= box.end.y - EPS or at.y + BODY_HEIGHT <= box.position.y + EPS:
			continue
		if target_x > at.x and at.x + HALF_WIDTH <= box.position.x + EPS \
		and target_x + HALF_WIDTH > box.position.x:
			result = minf(result, box.position.x - HALF_WIDTH)
		elif target_x < at.x and at.x - HALF_WIDTH >= box.end.x - EPS \
		and target_x - HALF_WIDTH < box.end.x:
			result = maxf(result, box.end.x + HALF_WIDTH)
	return result

func _horizontal_move(at: Vector2, target_x: float, grounded: bool) -> Vector2:
	var limited_x := _horizontal_limit(at, target_x)
	if absf(limited_x - target_x) <= EPS:
		return Vector2(target_x, at.y)
	if grounded and _max_step_height() > 0.0:
		var step_y := at.y
		for box: Rect2 in _boxes:
			if target_x + HALF_WIDTH > box.position.x + EPS and target_x - HALF_WIDTH < box.end.x - EPS \
			and box.end.y > at.y + EPS and box.end.y <= at.y + _max_step_height() + EPS:
				step_y = maxf(step_y, box.end.y)
		var stepped := Vector2(target_x, step_y)
		# Re-sweep the whole horizontal span at the proposed height. A taller wall
		# or low ceiling cannot be bypassed by finding a small step somewhere else.
		if step_y > at.y + EPS and actor_open(stepped) \
		and absf(_horizontal_limit(Vector2(at.x, step_y), target_x) - target_x) <= EPS:
			return stepped
	return Vector2(limited_x, at.y)

func _move_actor(at: Vector2, velocity: Vector2, grounded: bool, dt: float = DT) -> Dictionary:
	var bounds: Array = geometry.get("bounds", [-10000.0, 10000.0])
	var target_x := clampf(at.x + velocity.x * dt, float(bounds[0]) + HALF_WIDTH, float(bounds[1]) - HALF_WIDTH)
	var moved := _horizontal_move(at, target_x, grounded)
	if absf(moved.x - target_x) > EPS:
		velocity.x = 0.0
	velocity.y -= GRAVITY * dt
	var target_y := moved.y + velocity.y * dt
	var result_y := target_y
	var landed := false
	var ceiling := false
	for box: Rect2 in _boxes:
		if moved.x + HALF_WIDTH <= box.position.x + EPS or moved.x - HALF_WIDTH >= box.end.x - EPS:
			continue
		if velocity.y <= 0.0 and moved.y >= box.end.y - EPS and target_y <= box.end.y + EPS:
			# Highest crossed top wins, independent of rectangle iteration order.
			result_y = maxf(result_y, box.end.y)
			landed = true
		elif velocity.y > 0.0 and moved.y + BODY_HEIGHT <= box.position.y + EPS \
		and target_y + BODY_HEIGHT >= box.position.y - EPS:
			# Lowest crossed ceiling wins, likewise independent of order.
			result_y = minf(result_y, box.position.y - BODY_HEIGHT)
			ceiling = true
	if landed or ceiling:
		velocity.y = 0.0
	return {"position": Vector2(moved.x, result_y), "velocity": velocity, "grounded": landed}

func _floor_height_at(x: float, max_y: float) -> float:
	var height := -INF
	for box: Rect2 in _boxes:
		if x >= box.position.x - EPS and x <= box.end.x + EPS and box.end.y <= max_y + EPS:
			height = maxf(height, box.end.y)
	return height

func floor_height_at(progress: float) -> float:
	return _floor_height_at(progress, INF)

func needs_jump(at: Vector2, direction: float, speed: float) -> bool:
	if is_zero_approx(direction):
		return false
	for box: Rect2 in _boxes:
		var face := box.position.x if direction > 0 else box.end.x
		var distance := (face - at.x) * direction - HALF_WIDTH
		if distance >= -EPS and distance <= 0.56 + EPS and box.end.y > at.y + 0.18 + EPS \
		and box.position.y < at.y + BODY_HEIGHT - EPS:
			return true
	var probe_x := at.x + direction * (HALF_WIDTH + speed * 0.10)
	return _floor_height_at(probe_x, at.y + 0.18) < at.y - 0.20 - EPS

func route_surface_height(_progress: float) -> float:
	return 0.0

func _contact() -> bool:
	return absf(player.x - guard.x) <= BODY_WIDTH + EPS and absf(player.y - guard.y) <= BODY_HEIGHT + EPS

func _fallen(at: Vector2) -> bool:
	return at.y < float(geometry.get("killY", -5.0)) \
	or at.y < route_surface_height(at.x) - float(geometry.get("fallDepth", 2.4))

func _fail(reason: String) -> void:
	status = "failed"
	failure_reason = reason

func step(mask: int) -> void:
	if status != "running":
		return
	if mask < 0 or mask > 7:
		_fail("invalid_input")
		return
	if tick >= MAX_TICKS:
		_fail("timeout")
		return
	var old_x := player.x
	var direction := float(int(bool(mask & RIGHT)) - int(bool(mask & LEFT)))
	player_velocity.x = direction * PLAYER_SPEED
	if mask & JUMP and not (last_input & JUMP) and player_grounded:
		player_velocity.y = JUMP_SPEED
		player_grounded = false
	var next: Dictionary = _move_actor(player, player_velocity, player_grounded)
	player = next.position
	player_velocity = next.velocity
	player_grounded = next.grounded
	var chase_direction := signf(player.x - guard.x)
	guard_velocity.x = chase_direction * GUARD_SPEED
	if guard_grounded and needs_jump(guard, chase_direction, GUARD_SPEED):
		guard_velocity.y = JUMP_SPEED
		guard_grounded = false
	next = _move_actor(guard, guard_velocity, guard_grounded)
	guard = next.position
	guard_velocity = next.velocity
	guard_grounded = next.grounded
	tick += 1
	input_log.append(mask)
	last_input = mask
	guard_fell = guard_fell or _fallen(guard)
	if guard_fell:
		_fail("guard_fell")
		return
	if _fallen(player):
		_fail("player_fell")
		return
	if _contact():
		_fail("caught")
		return
	var gates: Array = geometry.get("gates", [])
	if gates_passed < gates.size():
		var gate: Dictionary = gates[gates_passed]
		if old_x <= float(gate.x) + EPS and player.x >= float(gate.x) - EPS \
		and player.y >= float(gate.minY) - EPS and player.y <= float(gate.maxY) + EPS:
			gates_passed += 1
	var exit: Dictionary = geometry.exit
	if gates_passed == gates.size() and player_grounded and player.x >= float(exit.x) - EPS \
	and player.y >= float(exit.minY) - EPS and player.y <= float(exit.maxY) + EPS:
		status = "finished"
	elif tick >= MAX_TICKS:
		_fail("timeout")

func reference_input() -> int:
	var mask := RIGHT
	# This suppression belongs only to the demonstration driver, never physics.
	if player_grounded and not (last_input & JUMP) and player.x < float(geometry.exit.x) - 1.0 \
	and needs_jump(player, 1.0, PLAYER_SPEED):
		mask |= JUMP
	return mask
