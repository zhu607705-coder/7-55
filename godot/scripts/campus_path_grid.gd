extends RefCounted
class_name CampusPathGrid

const DEFAULT_SNAP_RADIUS_PX := 96.0

var source_cell_size := 4
var source_width := 0
var source_height := 0
var nav_cell_size := 24
var nav_width := 0
var nav_height := 0
var world_size := Vector2.ZERO
var walkable_count := 0

var _cells := PackedByteArray()
var _astar := AStarGrid2D.new()
var _valid := false


func _init(mask: Dictionary, sample_cell_size: int = 24) -> void:
	_configure(mask, sample_cell_size)


func is_valid() -> bool:
	return _valid


func is_walkable_point(x: float, y: float) -> bool:
	if not _valid or not is_finite(x) or not is_finite(y):
		return false
	if x < 0.0 or y < 0.0 or x >= world_size.x or y >= world_size.y:
		return false
	var cell := Vector2i(floori(x / nav_cell_size), floori(y / nav_cell_size))
	return is_walkable_cell(cell)


func is_walkable_cell(cell: Vector2i) -> bool:
	if cell.x < 0 or cell.y < 0 or cell.x >= nav_width or cell.y >= nav_height:
		return false
	return _cells[cell.y * nav_width + cell.x] == 1


func nearest_walkable(x: float, y: float, max_radius_px: float = DEFAULT_SNAP_RADIUS_PX) -> Variant:
	if not _valid or not is_finite(x) or not is_finite(y) or max_radius_px < 0.0:
		return null
	var center := Vector2i(
		clampi(floori(x / nav_cell_size), 0, nav_width - 1),
		clampi(floori(y / nav_cell_size), 0, nav_height - 1)
	)
	var max_ring := ceili(max_radius_px / nav_cell_size)
	var max_distance_squared := max_radius_px * max_radius_px
	for ring in range(max_ring + 1):
		var best: Variant = null
		var best_distance_squared := INF
		for offset_y in range(-ring, ring + 1):
			for offset_x in range(-ring, ring + 1):
				if maxi(absi(offset_x), absi(offset_y)) != ring:
					continue
				var candidate := center + Vector2i(offset_x, offset_y)
				if not is_walkable_cell(candidate):
					continue
				var point := cell_center(candidate)
				var distance_squared := point.distance_squared_to(Vector2(x, y))
				if distance_squared <= max_distance_squared and distance_squared < best_distance_squared:
					best = point
					best_distance_squared = distance_squared
		if best != null:
			return best
	return null


func find_path(from: Vector2, to: Vector2, max_snap_radius_px: float = DEFAULT_SNAP_RADIUS_PX) -> PackedVector2Array:
	var result := PackedVector2Array()
	if not _valid:
		return result
	var start_value: Variant = from if is_walkable_point(from.x, from.y) else nearest_walkable(from.x, from.y, max_snap_radius_px)
	var goal_value: Variant = to if is_walkable_point(to.x, to.y) else nearest_walkable(to.x, to.y, max_snap_radius_px)
	if start_value == null or goal_value == null:
		return result
	var start: Vector2 = start_value
	var goal: Vector2 = goal_value
	var start_cell := point_to_cell(start)
	var goal_cell := point_to_cell(goal)
	if start_cell == goal_cell:
		result.append(goal)
		return result
	var ids := _astar.get_id_path(start_cell, goal_cell)
	if ids.is_empty():
		return result
	for id in ids:
		result.append(cell_center(id))
	result[0] = start
	result[result.size() - 1] = goal
	return _smooth_path(result)


func point_to_cell(point: Vector2) -> Vector2i:
	return Vector2i(
		clampi(floori(point.x / nav_cell_size), 0, nav_width - 1),
		clampi(floori(point.y / nav_cell_size), 0, nav_height - 1)
	)


func cell_center(cell: Vector2i) -> Vector2:
	return Vector2((cell.x + 0.5) * nav_cell_size, (cell.y + 0.5) * nav_cell_size)


func stats() -> Dictionary:
	return {
		"valid": _valid,
		"sourceCellSize": source_cell_size,
		"sourceWidth": source_width,
		"sourceHeight": source_height,
		"navCellSize": nav_cell_size,
		"navWidth": nav_width,
		"navHeight": nav_height,
		"walkableCount": walkable_count
	}


func _configure(mask: Dictionary, sample_cell_size: int) -> void:
	source_cell_size = int(mask.get("cellSize", 0))
	source_width = int(mask.get("gridWidth", 0))
	source_height = int(mask.get("gridHeight", 0))
	var bits_base64 := str(mask.get("bitsBase64", ""))
	if source_cell_size <= 0 or source_width <= 0 or source_height <= 0 or bits_base64.is_empty():
		push_error("CampusPathGrid requires a valid walkability mask.")
		return
	var merge_ratio := maxi(1, roundi(float(sample_cell_size) / source_cell_size))
	nav_cell_size = source_cell_size * merge_ratio
	nav_width = ceili(float(source_width) / merge_ratio)
	nav_height = ceili(float(source_height) / merge_ratio)
	world_size = Vector2(source_width * source_cell_size, source_height * source_cell_size)
	var bytes := Marshalls.base64_to_raw(bits_base64)
	var expected_bytes := ceili(float(source_width * source_height) / 8.0)
	if bytes.size() < expected_bytes:
		push_error("CampusPathGrid bitset is shorter than the declared grid.")
		return

	_cells.resize(nav_width * nav_height)
	walkable_count = 0
	for nav_y in range(nav_height):
		var source_y_start := nav_y * merge_ratio
		var source_y_end := mini(source_y_start + merge_ratio, source_height)
		for nav_x in range(nav_width):
			var source_x_start := nav_x * merge_ratio
			var source_x_end := mini(source_x_start + merge_ratio, source_width)
			var walkable := true
			for source_y in range(source_y_start, source_y_end):
				if not walkable:
					break
				var row_offset := source_y * source_width
				for source_x in range(source_x_start, source_x_end):
					var bit_index := row_offset + source_x
					if (bytes[bit_index >> 3] & (1 << (bit_index & 7))) == 0:
						walkable = false
						break
			var nav_index := nav_y * nav_width + nav_x
			_cells[nav_index] = 1 if walkable else 0
			if walkable:
				walkable_count += 1

	_astar.region = Rect2i(0, 0, nav_width, nav_height)
	_astar.cell_size = Vector2(nav_cell_size, nav_cell_size)
	_astar.offset = Vector2(nav_cell_size * 0.5, nav_cell_size * 0.5)
	_astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	_astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	_astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	_astar.update()
	for nav_y in range(nav_height):
		for nav_x in range(nav_width):
			var cell := Vector2i(nav_x, nav_y)
			if not is_walkable_cell(cell):
				_astar.set_point_solid(cell, true)
	_valid = walkable_count > 0


func _smooth_path(path: PackedVector2Array) -> PackedVector2Array:
	if path.size() <= 2:
		return path
	var smoothed := PackedVector2Array([path[0]])
	var anchor := 0
	while anchor < path.size() - 1:
		var next_index := anchor + 1
		for candidate in range(path.size() - 1, anchor + 1, -1):
			if _has_line_of_sight(path[anchor], path[candidate]):
				next_index = candidate
				break
		smoothed.append(path[next_index])
		anchor = next_index
	return smoothed


func _has_line_of_sight(from: Vector2, to: Vector2) -> bool:
	var distance := from.distance_to(to)
	var steps := maxi(1, ceili(distance / (nav_cell_size * 0.45)))
	for index in range(steps + 1):
		var point := from.lerp(to, float(index) / steps)
		if not is_walkable_point(point.x, point.y):
			return false
	return true
