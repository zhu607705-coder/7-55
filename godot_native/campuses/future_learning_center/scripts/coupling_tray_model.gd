extends RefCounted
## The tray owns geometry and circuit validation; presentation never grants success.
const BOUNDS := Rect2(52,156,610,282)
const HALF := Vector2(24,24)
const LINK_DISTANCE := 60.0
const TRIAL_SECONDS := 1.15
var level := 0
var positions: Array[Vector2] = [Vector2(156,274),Vector2(156,334)]
var linked := true
var completed: Array[bool] = [false,false]
var running := false
var powered := false
var elapsed := 0.0
var outcome := ""
var blocked := false
var collision_point := Vector2.ZERO
var history: Array[Dictionary] = []
var drag_start: Dictionary = {}

func walls() -> Array[Rect2]:
	if level == 0: return [Rect2(324,156,20,112),Rect2(324,336,20,102)]
	return [Rect2(324,156,20,182),Rect2(324,406,20,32),Rect2(344,280,206,20),Rect2(618,280,44,20)]

func targets() -> Array[Vector2]:
	return [Vector2(568,274),Vector2(568,334)] if level == 0 else [Vector2(474,218),Vector2(534,218)]

func snapshot() -> Dictionary:
	return {"positions":positions.duplicate(),"linked":linked}

func restore(value: Dictionary) -> void:
	positions.assign(value.positions); linked = value.linked

func invalidate() -> void:
	running = false; powered = false; elapsed = 0; outcome = ""; blocked = false

func remember(value: Dictionary) -> void:
	if value == snapshot(): return
	if history.size() >= 64: history.pop_front()
	history.append(value)

func begin_drag() -> bool:
	if running or not drag_start.is_empty(): return false
	drag_start = snapshot(); return true

func end_drag(cancelled := false) -> void:
	if drag_start.is_empty(): return
	if cancelled: restore(drag_start)
	else: remember(drag_start)
	drag_start = {}; blocked = false

func bridge_rect(points: Array[Vector2]) -> Rect2:
	var low := Vector2(minf(points[0].x,points[1].x),minf(points[0].y,points[1].y))
	var high := Vector2(maxf(points[0].x,points[1].x),maxf(points[0].y,points[1].y))
	return Rect2(low-Vector2(5,5),high-low+Vector2(10,10))

func clear_rect(area: Rect2) -> bool:
	if not BOUNDS.encloses(area): return false
	for wall: Rect2 in walls():
		if wall.intersects(area): return false
	return true

func legal(points: Array[Vector2], connection: bool) -> bool:
	for point: Vector2 in points:
		if not point.is_finite() or not clear_rect(Rect2(point-HALF,HALF*2)): return false
	if Rect2(points[0]-HALF,HALF*2).intersects(Rect2(points[1]-HALF,HALF*2)): return false
	if connection:
		var delta := (points[1]-points[0]).abs()
		if not ((absf(delta.x-LINK_DISTANCE)<.01 and delta.y<.01) or (absf(delta.y-LINK_DISTANCE)<.01 and delta.x<.01)): return false
		if not clear_rect(bridge_rect(points)): return false
	return true

func move_block(index: int, destination: Vector2) -> bool:
	if index not in [0,1] or running or drag_start.is_empty() or not destination.is_finite(): return false
	var delta := (destination-positions[index]).limit_length(1400)
	var steps := maxi(1,ceili(delta.length()/2.0))
	var part := delta/float(steps)
	var moved := false
	blocked = false
	for n: int in steps:
		var candidate: Array[Vector2] = positions.duplicate()
		candidate[index] += part
		if linked: candidate[1-index] += part
		if not legal(candidate,linked):
			blocked = true; collision_point = positions[index]+part.normalized()*24
			break
		if not moved and part.length_squared()>.000001: invalidate()
		positions = candidate; moved = moved or part.length_squared()>.000001
	return moved

func detach_bridge() -> bool:
	if running or not linked or not drag_start.is_empty(): return false
	var before := snapshot(); linked = false; invalidate(); remember(before); return true

func attach_bridge() -> bool:
	if running or linked or not drag_start.is_empty(): return false
	var delta := positions[1]-positions[0]
	var axis := Vector2(signf(delta.x),0) if absf(delta.x)>absf(delta.y) else Vector2(0,signf(delta.y))
	if axis == Vector2.ZERO or delta.distance_to(axis*LINK_DISTANCE)>10: return false
	var candidate: Array[Vector2] = positions.duplicate()
	candidate[1] = candidate[0]+axis*LINK_DISTANCE
	if not legal(candidate,true): return false
	# Snapping the last few pixels is subject to the same collision sweep.
	var change := candidate[1]-positions[1]
	for n: int in 10:
		var intermediate: Array[Vector2] = positions.duplicate()
		intermediate[1] += change*float(n+1)/10.0
		if not legal(intermediate,false): return false
	var before := snapshot(); positions = candidate; linked = true; invalidate(); remember(before); return true

func contact(index: int) -> bool:
	for point: Vector2 in positions:
		if point.distance_to(targets()[index])<=10: return true
	return false

func ready() -> bool:
	return legal(positions,linked) and linked and contact(0) and contact(1)

func trial() -> bool:
	if running or not drag_start.is_empty(): return false
	invalidate()
	if not contact(0) or not contact(1): outcome = "contacts"; return false
	if not linked: outcome = "bridge"; return false
	if not ready(): outcome = "geometry"; return false
	running = true; outcome = "testing"; return true

func step(dt: float) -> void:
	if not running or not is_finite(dt) or dt<=0: return
	if not ready(): cancel(); return
	elapsed += minf(dt,.1)
	if elapsed >= TRIAL_SECONDS:
		running = false; powered = true; completed[level] = true; outcome = "passed"

func cancel() -> void:
	end_drag(true)
	if running: running = false; elapsed = 0; outcome = "paused"

func undo() -> bool:
	if running or not drag_start.is_empty() or history.is_empty(): return false
	restore(history.pop_back()); invalidate(); return true

func reset() -> void:
	cancel(); positions = [Vector2(156,274),Vector2(156,334)]
	linked = true; history.clear(); invalidate()

func next_tray() -> bool:
	if level != 0 or not completed[0] or running or not drag_start.is_empty(): return false
	level = 1; reset(); return true
