extends RefCounted
## Road selection from src/scenes/rpg/CampusPathfinder.ts. Both runtimes use
## the same conservative 24-pixel merge of the source walkability mask.

const SAMPLE_CELL_SIZE := 24.0
const SNAP_RADIUS := 96.0
const DIAGONAL_COST := 1.4142135623730951
const SEARCH_LIMIT := 60000

var _cells := PackedByteArray()
var _size := Vector2i.ZERO
var _cell := 0.0
var _world_size := Vector2.ZERO

func clear() -> void:
	_cells = PackedByteArray()

func configure(bits: PackedByteArray, source: Dictionary) -> bool:
	if not _cells.is_empty(): return true
	var source_cell := int(source.get("cellSize", 0))
	var width := int(source.get("gridWidth", 0))
	var height := int(source.get("gridHeight", 0))
	if source_cell <= 0 or width <= 0 or height <= 0 or bits.size() * 8 < width * height: return false
	var merge := maxi(1, roundi(SAMPLE_CELL_SIZE / float(source_cell)))
	_cell = float(source_cell * merge)
	_world_size = Vector2(width * source_cell, height * source_cell)
	_size = Vector2i(ceili(float(width) / merge), ceili(float(height) / merge))
	_cells.resize(_size.x * _size.y)
	for y in _size.y:
		for x in _size.x:
			var top := y * merge
			var left := x * merge
			var covered := Rect2i(left, top, mini(merge, width - left), mini(merge, height - top))
			_cells[_index(Vector2i(x, y))] = int(_source_allows(bits, width, covered))
	return true

func _source_allows(bits: PackedByteArray, width: int, covered: Rect2i) -> bool:
	for y in range(covered.position.y, covered.end.y):
		for x in range(covered.position.x, covered.end.x):
			var index := y * width + x
			if (bits[index >> 3] & (1 << (index & 7))) == 0: return false
	return true

func plan(start: Vector2, goal: Vector2) -> Array[Vector2]:
	if _cells.is_empty(): return []
	var from := _walkable_point(start)
	var to := _walkable_point(goal)
	if not from.is_finite() or not to.is_finite(): return []
	var first := _cell_at(from)
	var last := _cell_at(to)
	if first == last: return [to]
	var cells := _search(first, last)
	if cells.is_empty(): return []
	var route: Array[Vector2] = [from]
	var anchor := 0
	while anchor < cells.size() - 1:
		var next := cells.size() - 1
		while next > anchor + 1 and not _has_line_of_sight(cells[anchor], cells[next]):
			next -= 1
		route.append(to if next == cells.size() - 1 else _center(cells[next]))
		anchor = next
	return route

func _cell_at(point: Vector2) -> Vector2i:
	return Vector2i((point / _cell).floor()).clamp(Vector2i.ZERO, _size - Vector2i.ONE)

func _index(cell: Vector2i) -> int:
	return cell.y * _size.x + cell.x

func _position(index: int) -> Vector2i:
	return Vector2i(index % _size.x, floori(float(index) / _size.x))

func _center(cell: Vector2i) -> Vector2:
	return (Vector2(cell) + Vector2(.5, .5)) * _cell

func _walkable(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < _size.x and cell.y < _size.y and _cells[_index(cell)] == 1

func _walkable_point(point: Vector2) -> Vector2:
	if not point.is_finite(): return Vector2.INF
	var seed := _cell_at(point)
	if Rect2(Vector2.ZERO, _world_size).has_point(point) and _walkable(seed): return point
	for radius in range(ceili(SNAP_RADIUS / _cell) + 1):
		var nearest := Vector2.INF
		var distance := INF
		for y in range(seed.y - radius, seed.y + radius + 1):
			for x in range(seed.x - radius, seed.x + radius + 1):
				if maxi(absi(x - seed.x), absi(y - seed.y)) != radius: continue
				var cell := Vector2i(x, y)
				if not _walkable(cell): continue
				var center := _center(cell)
				var candidate := center.distance_squared_to(point)
				if candidate <= SNAP_RADIUS * SNAP_RADIUS and candidate < distance:
					nearest = center
					distance = candidate
		if nearest.is_finite(): return nearest
	return Vector2.INF

func _octile(from: Vector2i, to: Vector2i) -> float:
	var delta := (to - from).abs()
	return maxi(delta.x, delta.y) + (DIAGONAL_COST - 1.0) * mini(delta.x, delta.y)

func _search(first: Vector2i, last: Vector2i) -> Array[Vector2i]:
	var count := _cells.size()
	var costs := PackedFloat64Array()
	var scores := PackedFloat64Array()
	var previous := PackedInt32Array()
	var closed := PackedByteArray()
	costs.resize(count)
	costs.fill(INF)
	scores.resize(count)
	previous.resize(count)
	closed.resize(count)
	var start := _index(first)
	var goal := _index(last)
	var open: Array[int] = [start]
	costs[start] = 0.0
	scores[start] = _octile(first, last)
	var iterations := 0
	while not open.is_empty() and iterations < SEARCH_LIMIT:
		iterations += 1
		var current := _pop(open, scores)
		if closed[current] == 1: continue
		closed[current] = 1
		if current == goal:
			var path: Array[Vector2i] = [last]
			while current != start:
				current = previous[current]
				path.append(_position(current))
			path.reverse()
			return path
		var cell := _position(current)
		# Preserve the Web neighbor order and heap tie behavior. Both affect
		# which equal-cost path is chosen through a broad intersection.
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				if dx == 0 and dy == 0: continue
				var next := cell + Vector2i(dx, dy)
				if not _walkable(next): continue
				var index := _index(next)
				if closed[index] == 1: continue
				var diagonal := dx != 0 and dy != 0
				if diagonal and not _walkable(Vector2i(next.x, cell.y)) and not _walkable(Vector2i(cell.x, next.y)):
					continue
				var cost := costs[current] + (DIAGONAL_COST if diagonal else 1.0)
				if cost < costs[index]:
					previous[index] = current
					costs[index] = cost
					scores[index] = cost + _octile(next, last)
					_push(open, scores, index)
	return []

func _push(heap: Array[int], scores: PackedFloat64Array, item: int) -> void:
	heap.append(item)
	var index := heap.size() - 1
	while index > 0:
		var parent := (index - 1) >> 1
		if scores[heap[parent]] <= scores[heap[index]]: break
		heap[index] = heap[parent]
		heap[parent] = item
		index = parent

func _pop(heap: Array[int], scores: PackedFloat64Array) -> int:
	var top := heap[0]
	var tail: int = heap.pop_back()
	if heap.is_empty(): return top
	heap[0] = tail
	var index := 0
	while true:
		var left := index * 2 + 1
		var right := left + 1
		var best := index
		if left < heap.size() and scores[heap[left]] < scores[heap[best]]: best = left
		if right < heap.size() and scores[heap[right]] < scores[heap[best]]: best = right
		if best == index: break
		heap[index] = heap[best]
		heap[best] = tail
		index = best
	return top

func _has_line_of_sight(from: Vector2i, to: Vector2i) -> bool:
	var cell := from
	var delta := (to - from).abs()
	var step := (to - from).sign()
	var error := delta.x - delta.y
	while _walkable(cell):
		if cell == to: return true
		var doubled := error * 2
		if doubled > -delta.y:
			error -= delta.y
			cell.x += step.x
		if doubled < delta.x:
			error += delta.x
			cell.y += step.y
	return false
