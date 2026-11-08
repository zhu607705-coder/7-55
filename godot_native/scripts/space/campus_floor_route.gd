extends RefCounted
## The compiler samples the campus foot-center domain. This graph proposes
## waypoints only. World still owns collision, arrival, and interaction.
const ROAD := 2
const LOCAL_DISTANCE := 64.0
const SWEEP_LENGTH := 96.0
const CONNECTOR_CELLS := 4
const WebRoadPath := preload("res://scripts/space/campus_web_road_path.gd")

var _grid: AStarGrid2D
var _terrain := PackedByteArray()
var _minor_runs: Array[Rect2i] = []
var _cell := 0
var _web_roads := WebRoadPath.new()

func clear() -> void:
	_grid = null
	_terrain = PackedByteArray()
	_minor_runs.clear()
	_cell = 0
	_web_roads.clear()

func configure(spec: Dictionary, foot_size: Vector2) -> bool:
	if _grid != null: return true
	var dimensions: Array = spec.get("size", [])
	var baked_foot: Array = spec.get("footSize", [])
	if dimensions.size() != 2 or baked_foot.size() != 2 or Vector2(baked_foot[0], baked_foot[1]) != foot_size: return false
	var extent := Vector2i(int(dimensions[0]), int(dimensions[1]))
	_cell = int(spec.get("cellSize", 0))
	if extent.x <= 0 or extent.y <= 0 or _cell <= 0: return false
	var count := extent.x * extent.y
	_terrain = Marshalls.base64_to_raw(str(spec.terrainDeflateBase64)).decompress(count, FileAccess.COMPRESSION_DEFLATE)
	if _terrain.size() != count: return false
	_grid = AStarGrid2D.new()
	_grid.region = Rect2i(Vector2i.ZERO, extent)
	_grid.offset = Vector2.ONE * _cell * 0.5
	_grid.cell_size = Vector2.ONE * _cell
	_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	_grid.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	_grid.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	_grid.update()
	_grid.fill_solid_region(_grid.region)
	for y in range(extent.y):
		var x := 0
		while x < extent.x:
			var first := x
			var kind := _terrain[y * extent.x + x]
			x += 1
			while x < extent.x and _terrain[y * extent.x + x] == kind: x += 1
			if kind == 0: continue
			var run := Rect2i(first, y, x - first, 1)
			_grid.fill_solid_region(run, false)
			if kind < ROAD:
				_minor_runs.append(run)
				_grid.fill_weight_scale_region(run, 9.0)
			elif kind == ROAD:
				_grid.fill_weight_scale_region(run, 2.75)
	return true

func plan(start: Vector2, goal: Vector2, clear_edge: Callable, source_mask: PackedByteArray, source_definition: Dictionary) -> Array[Vector2]:
	var web_ready := _web_roads.configure(source_mask, source_definition)
	if web_ready and _is_road(_cell_at(start)) and _is_road(_cell_at(goal)):
		var main_roads := _plan_web_roads(start, goal, clear_edge)
		if not main_roads.is_empty(): return main_roads
	var a := _connect(start, clear_edge)
	var b := _connect(goal, clear_edge)
	if a.x < 0 or b.x < 0: return []
	var ids := _grid.get_id_path(a, b)
	if ids.is_empty(): return []
	var preserve_roads := start.distance_to(goal) > LOCAL_DISTANCE
	var preferred := _prefer_contiguous_roads(ids) if preserve_roads else ids
	var route := _fit_corridors(preferred, start, goal, clear_edge, preserve_roads)
	if route.is_empty() and preferred != ids:
		route = _fit_corridors(ids, start, goal, clear_edge, preserve_roads)
	return route

func _plan_web_roads(start: Vector2, goal: Vector2, clear_edge: Callable) -> Array[Vector2]:
	var proposed := _web_roads.plan(start, goal)
	if proposed.is_empty(): return []
	# A coarse-cell snap is unnecessary when the actual clicked endpoints
	# share a clear road and the Web path has no turns between them.
	if proposed.size() <= 2 and _segment_in_corridor(start, goal, ROAD, clear_edge): return [goal]
	if proposed.back() != goal: proposed.append(goal)
	var route: Array[Vector2] = []
	var previous := start
	for point in proposed:
		if point == previous: continue
		if not _segment_in_corridor(previous, point, ROAD, clear_edge): return []
		route.append(point)
		previous = point
	return route if not route.is_empty() else [goal]

func _connect(point: Vector2, clear_edge: Callable) -> Vector2i:
	var seed := Vector2i((point / _cell).floor())
	for radius in range(CONNECTOR_CELLS + 1):
		var nearest := Vector2i(-1, -1)
		var distance := INF
		for y in range(seed.y - radius, seed.y + radius + 1):
			for x in range(seed.x - radius, seed.x + radius + 1):
				if maxi(absi(x - seed.x), absi(y - seed.y)) != radius: continue
				var id := Vector2i(x, y)
				if not _grid.is_in_boundsv(id) or _grid.is_point_solid(id): continue
				var center := _grid.get_point_position(id)
				var d := point.distance_squared_to(center)
				if d < distance and clear_edge.call(point, center):
					nearest = id
					distance = d
		if nearest.x >= 0: return nearest
	return Vector2i(-1, -1)

func _prefer_contiguous_roads(ids: Array[Vector2i]) -> Array[Vector2i]:
	var first := -1
	var last := -1
	var gap := false
	var width := _grid.region.size.x
	for i in range(ids.size()):
		if _terrain[ids[i].y * width + ids[i].x] < ROAD: continue
		if first < 0: first = i
		elif i > last + 1: gap = true
		last = i
	if not gap: return ids
	# Prefer one continuous main-road leg when the entry and exit are on the
	# same road network. Disconnected roads can still use a legal connector.
	for run: Rect2i in _minor_runs: _grid.fill_solid_region(run)
	var main_leg := _grid.get_id_path(ids[first], ids[last])
	for run: Rect2i in _minor_runs: _grid.fill_solid_region(run, false)
	if main_leg.is_empty(): return ids
	var route := ids.slice(0, first)
	route.append_array(main_leg)
	route.append_array(ids.slice(last + 1))
	return route

func _fit_corridors(ids: Array[Vector2i], start: Vector2, goal: Vector2, clear_edge: Callable, preserve_roads: bool) -> Array[Vector2]:
	if start == goal: return [goal]
	var points: Array[Vector2] = [start]
	for id: Vector2i in ids:
		var point := _grid.get_point_position(id)
		if point != points.back(): points.append(point)
	if goal != points.back(): points.append(goal)
	var road_edges := PackedByteArray()
	for i in range(points.size() - 1):
		road_edges.append(int(preserve_roads and _is_road(_cell_at(points[i])) and _is_road(_cell_at(points[i + 1]))))
	# Keep the search's road entrances and exits. Resolve each chosen corridor
	# into continuous segments before the actor takes its first step.
	var route: Array[Vector2] = []
	var first := 0
	while first < road_edges.size():
		var last := first + 1
		while last < road_edges.size() and road_edges[last] == road_edges[first]: last += 1
		var minimum := ROAD if road_edges[first] == 1 else 0
		var web_leg: Array[Vector2] = []
		if minimum == ROAD and (first > 0 or last < points.size() - 1):
			web_leg = _plan_web_roads(points[first], points[last], clear_edge)
		if not web_leg.is_empty():
			route.append_array(web_leg)
		elif not _append_corridor(route, points, first, last, minimum, clear_edge):
			return []
		first = last
	return route

func _append_corridor(route: Array[Vector2], points: Array[Vector2], first: int, last: int, min_road: int, clear_edge: Callable) -> bool:
	# Match the original Web smoothing: take the farthest visible waypoint
	# in the selected corridor. Road weights guide the search, not lane changes.
	while first < last:
		var next := last
		while not _segment_in_corridor(points[first], points[next], min_road, clear_edge):
			if next == first + 1: return false
			next -= 1
		route.append(points[next])
		first = next
	return true

func _segment_in_corridor(a: Vector2, b: Vector2, min_road: int, clear_edge: Callable) -> bool:
	if min_road > 0 and not _on_road_for_segment(a, b, min_road): return false
	# Split collision queries, while keeping one continuous movement segment.
	var checks := maxi(1, ceili(a.distance_to(b) / SWEEP_LENGTH))
	var previous := a
	for i in range(1, checks + 1):
		var point := b if i == checks else a.lerp(b, float(i) / checks)
		if not clear_edge.call(previous, point): return false
		previous = point
	return true

func _cell_at(point: Vector2) -> Vector2i:
	return Vector2i((point / _cell).floor())

func _is_road(id: Vector2i, minimum: int = ROAD) -> bool:
	return _grid.is_in_boundsv(id) and _terrain[id.y * _grid.region.size.x + id.x] >= minimum

func _on_road_for_segment(a: Vector2, b: Vector2, minimum: int) -> bool:
	# Visit every grid cell the line actually enters. The physical foot sweep
	# separately tests solids and water, including contact at a cell corner.
	var cell := _cell_at(a)
	var destination := _cell_at(b)
	var motion := b - a
	var step := Vector2i(motion.sign())
	var next_crossing := Vector2.INF
	var interval := Vector2.INF
	for axis in range(2):
		if step[axis] == 0: continue
		var edge := float(cell[axis] + int(step[axis] > 0)) * _cell
		next_crossing[axis] = (edge - a[axis]) / motion[axis]
		interval[axis] = float(_cell) / absf(motion[axis])
	while _is_road(cell, minimum):
		if cell == destination: return true
		var cross_x := cell.x != destination.x and (cell.y == destination.y or next_crossing.x <= next_crossing.y)
		var cross_y := cell.y != destination.y and (cell.x == destination.x or next_crossing.y <= next_crossing.x)
		if cross_x:
			cell.x += step.x
			next_crossing.x += interval.x
		if cross_y:
			cell.y += step.y
			next_crossing.y += interval.y
	return false
