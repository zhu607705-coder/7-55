extends RefCounted
## A single portable patch board. Stations permute roles, never cable identity.
const ROLES = [[0, 1, 2], [2, 0, 1]]
const PORT_Y := [232.0, 302.0, 372.0]
const PILLAR := Rect2(475,244,34,100)
const CABLE_RADIUS := 4.0
const SHORT_LENGTH := 430.0
const LONG_LENGTH := 800.0
const PATTERNS = [[1, 0, 1], [0, 1, 0]]
var station := 0
var orientation := 0
var connections: Array[int] = [0, 1, 2]
var outer: Array[bool] = [true, true, true]
var short_cable := false
var revision := 0
var running := false
var paused := false
var progress := 0.0
var pattern := 0
var received: Array[int] = [-1, -1, -1]
var outcomes: Array[String] = ["", "", ""]
var records: Array[Dictionary] = []
var station_proofs: Array[bool] = [false, false]
var completed := false
var _seen: Dictionary = {}
var _trial_revision := -1

func cable_path(channel: int) -> PackedVector2Array:
	var port: int = connections[channel]
	var start := Vector2(350,PORT_Y[channel])
	if port < 0: return PackedVector2Array([start,start+Vector2(45,30)])
	var finish := Vector2(610,PORT_Y[port])
	var direct := PackedVector2Array([start,Vector2(450,start.y),Vector2(530,finish.y),finish])
	if outer[channel] and (channel != port or obstruction_distance(direct) >= 0):
		# Same-level middle lead uses the nearest upper channel; transverse leads use perimeter clips.
		var y := PILLAR.position.y-20 if channel == port else 180.0-channel*12.0
		return PackedVector2Array([start,Vector2(380+channel*8,start.y),Vector2(380+channel*8,y),Vector2(580-channel*8,y),Vector2(580-channel*8,finish.y),finish])
	return direct

func path_length(path: PackedVector2Array) -> float:
	var length := 0.0
	for i: int in range(1,path.size()): length += path[i-1].distance_to(path[i])
	return length

func point_at_distance(path: PackedVector2Array, distance: float) -> Vector2:
	var remaining := maxf(0,distance)
	for i: int in range(1,path.size()):
		var length := path[i-1].distance_to(path[i])
		if remaining <= length: return path[i-1].lerp(path[i],remaining/maxf(length,.001))
		remaining -= length
	return path[-1]

func obstruction_distance(path: PackedVector2Array) -> float:
	var rect := PILLAR.grow(CABLE_RADIUS)
	var corners := [rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)]
	var traveled := 0.0
	for i: int in range(1,path.size()):
		if rect.has_point(path[i-1]): return traveled
		var nearest := INF
		for edge: int in 4:
			var hit = Geometry2D.segment_intersects_segment(path[i-1],path[i],corners[edge],corners[(edge+1)%4])
			if hit != null: nearest = minf(nearest,path[i-1].distance_to(hit))
		if is_finite(nearest): return traveled+nearest
		traveled += path[i-1].distance_to(path[i])
	return -1.0

func cable_length() -> float: return SHORT_LENGTH if short_cable else LONG_LENGTH
func failure_distance(channel: int) -> float:
	var path := cable_path(channel)
	var obstruction := obstruction_distance(path)
	return minf(cable_length(),obstruction) if obstruction >= 0 else minf(cable_length(),path_length(path))
func cable_status(channel: int) -> String:
	if connections[channel] < 0: return "unplugged"
	var path := cable_path(channel)
	var obstruction := obstruction_distance(path)
	if obstruction >= 0 and obstruction <= cable_length(): return "blocked"
	if path_length(path) > cable_length(): return "short"
	return "clear"

func edit(channel: int, endpoint: int) -> bool:
	if channel < 0 or channel > 2 or endpoint < -1 or endpoint > 2: return false
	if endpoint >= 0:
		for i: int in 3:
			if i != channel and connections[i] == endpoint: return false
	if connections[channel] == endpoint: return true
	connections[channel] = endpoint
	_changed()
	return true

func route_cable(channel: int, use_outer: bool) -> bool:
	if channel < 0 or channel > 2: return false
	if outer[channel] != use_outer:
		outer[channel] = use_outer
		_changed()
	return true

func rotate_adapter() -> void:
	orientation = (orientation + 1) % 3
	_changed()

func move_to(value: int) -> bool:
	if value < 0 or value > 1 or running: return false
	if value == station: return true
	station = value
	_changed()
	return true

func set_short(value: bool) -> void:
	if short_cable == value: return
	short_cable = value
	_changed()

func source_role(channel: int) -> int: return (channel + orientation) % 3

func _changed() -> void:
	revision += 1
	running = false
	paused = false
	progress = 0
	received = [-1, -1, -1]
	outcomes = ["", "", ""]
	_seen.clear()

func start() -> bool:
	if running: return false
	pattern = 1 - pattern
	progress = 0
	running = true
	paused = false
	_trial_revision = revision
	received = [-1, -1, -1]
	outcomes = ["", "", ""]
	return true

func step(dt: float) -> void:
	if not running or paused: return
	progress = minf(1, progress + maxf(0, dt) / 1.5)
	if progress < 1: return
	running = false
	if revision != _trial_revision: return
	var valid := true
	for i: int in 3:
		var port := connections[i]
		if port < 0: outcomes[i] = "unplugged"; valid = false; continue
		var status := cable_status(i)
		if status != "clear": outcomes[i] = status; valid = false; continue
		var role: int = ROLES[station][port]
		received[role] = PATTERNS[pattern][source_role(i)]
		outcomes[i] = "arrived" if role == source_role(i) else "wrong_role"
		valid = valid and role == source_role(i)
	records.append({"station": station, "revision": revision, "pattern": pattern, "valid": valid, "received": received.duplicate(), "outcomes": outcomes.duplicate()})
	if records.size() > 24: records.pop_front()
	if valid: _seen[pattern] = true
	if _seen.size() == 2: station_proofs[station] = true
	completed = completed or (station_proofs[0] and station_proofs[1])

func pause() -> void:
	if running: paused = true
func resume() -> void: paused = false
func cancel() -> void:
	running = false
	paused = false
	progress = 0
