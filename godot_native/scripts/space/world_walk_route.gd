extends RefCounted
## One transient walking request. The caller owns input, collision queries,
## movement side effects and dispatch of any arrived interaction.
var waypoints: Array[Vector2] = []
var goal := Vector2.INF
var status := ""
var bounds := Rect2()
var _feedback_left := 0.0
var view_key := ""
var view_size := Vector2.ZERO
var view_zoom := 0.0
var expected_camera := Vector2.ZERO
var pending: Dictionary = {}
var _intent_state: Dictionary = {}

func remember_view(world_key: String, viewport_size: Vector2, zoom: float, camera: Vector2) -> void:
	view_key = world_key
	view_size = viewport_size
	view_zoom = zoom
	expected_camera = camera

func view_is_current(world_key: String, viewport_size: Vector2, zoom: float, camera: Vector2, full_map: bool) -> bool:
	return view_key == world_key and (full_map or (viewport_size == view_size
		and is_equal_approx(zoom, view_zoom) and camera.is_equal_approx(expected_camera)))

func start(path: Array[Vector2], marker: Vector2) -> void:
	waypoints = path
	goal = marker
	status = "moving"

func cancel() -> void:
	waypoints.clear()
	goal = Vector2.INF
	status = ""
	_feedback_left = 0
	clear_interaction()

func block() -> void:
	waypoints.clear()
	status = "blocked"
	_feedback_left = .9
	clear_interaction()

func tick_feedback(delta: float) -> void:
	if _feedback_left <= 0: return
	_feedback_left = maxf(0, _feedback_left - delta)
	if _feedback_left == 0 and waypoints.is_empty():
		goal = Vector2.INF
		status = ""

func remember_interaction(target: Dictionary, state: Dictionary, phase: Array) -> void:
	_intent_state = state
	pending = {"target": target.duplicate(true), "phase": phase}

func matching_interaction(state: Dictionary, phase: Array, targets: Array) -> Dictionary:
	if pending.is_empty() or not is_same(_intent_state, state) or pending.phase != phase: return {}
	for target: Dictionary in targets:
		if str(target.get("id", "")) == str(pending.target.get("id", "")):
			return target if target == pending.target else {}
	return {}

func clear_interaction() -> void:
	pending.clear()
	_intent_state = {}

func advance(anchor: Vector2, distance: float, clear: Callable, spend_across_waypoints: bool, wait_for_gate: bool) -> Vector2:
	while not waypoints.is_empty():
		var next := anchor.move_toward(waypoints[0], distance)
		if not clear.call(anchor, next):
			if not wait_for_gate or waypoints.size() != 1: block()
			break
		distance -= anchor.distance_to(next)
		anchor = next
		# Retire only exact waypoints, including a zero-length first step.
		if anchor != waypoints[0]: break
		waypoints.pop_front()
		if waypoints.is_empty():
			status = "arrived"
			_feedback_left = .45
		if not spend_across_waypoints or distance <= 0.0: break
	return anchor
