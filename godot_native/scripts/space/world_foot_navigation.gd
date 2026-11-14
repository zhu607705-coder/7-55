extends RefCounted
## Plans on an exact scene surface. Every edge uses the same full-foot checks
## for touch routing, held-key campus slides and scripted walking.
const PlayerMetrics = preload("res://scripts/player_metrics.gd")
const SpatialRules = preload("res://scripts/space/spatial_rules.gd")
const MobileFloorRoute = preload("res://scripts/mobile_floor_route.gd")
const CampusFloorRoute = preload("res://scripts/space/campus_floor_route.gd")

var planner := MobileFloorRoute.new()
var roads := CampusFloorRoute.new()
var _scene := ""
var _campus: RefCounted
var _mask := PackedByteArray()
var _mask_meta: Dictionary
var _can_stand: Callable

func configure(scene: String, campus: RefCounted, mask: PackedByteArray, mask_meta: Dictionary, can_stand: Callable) -> void:
	_scene = scene
	_campus = campus
	_mask = mask
	_mask_meta = mask_meta
	_can_stand = can_stand

func set_furniture_budget(separated_library: bool) -> void:
	planner.corner_limit = 320 if separated_library else MobileFloorRoute.MAX_CORNERS
	planner.edge_limit = 8192 if separated_library else MobileFloorRoute.MAX_EDGES

func campus_detour_nodes(start: Vector2, goal: Vector2, bounds: Rect2, local_support_only := false) -> Array[Vector2]:
	var points:Array[Vector2]=[]
	if _scene!="campus_bootstrap" or not _campus.ready:return points
	var feet := PlayerMetrics.foot_rect(Vector2.ZERO, _scene)
	var corridor := Rect2(start, Vector2.ZERO).expand(goal).grow(32.0)
	for polygon:PackedVector2Array in _campus.solid_polygons:
		if polygon.is_empty():continue
		var polygon_bounds := Rect2(polygon[0], Vector2.ZERO)
		for vertex: Vector2 in polygon: polygon_bounds = polygon_bounds.expand(vertex)
		var box := SpatialRules.obstacle_for_foot_anchor(polygon_bounds, feet).grow(MobileFloorRoute.CORNER_CLEARANCE)
		if not box.intersects(bounds):continue
		# Only objects in the local start/goal corridor contribute candidates.
		# Remote viewport trees otherwise create quadratic, long support scans.
		# A blocking building still contributes all its outer corners, even
		# when the needed detour extends beyond this corridor.
		if not box.intersects(corridor):continue
		# Bounding corners propose detours only. They are NOT inserted into
		# the obstacle list: concave polygons never become new air-wall boxes.
		for point:Vector2 in [box.position,Vector2(box.end.x,box.position.y),box.end,Vector2(box.position.x,box.end.y)]:
			if not points.has(point):points.append(point)
	# Reviewed path points contribute graph candidates only. They do not
	# grant floor, pre-approve an edge, mutate the player, or bypass a gate.
	# The first attempt keeps support candidates near this tap. A failed local
	# graph retries all visible bends of relevant supports, preserving U-shaped
	# routes without paying for every remote path point on ordinary short taps.
	var support_corridor := PlayerMetrics.foot_rect(start,_scene).merge(PlayerMetrics.foot_rect(goal,_scene)).grow(32.0)
	for support: Dictionary in _campus.walk_supports:
		if not support.bounds.intersects(support_corridor): continue
		for foot_center: Vector2 in support.get("routeCandidateFootCenters", PackedVector2Array()):
			if local_support_only and not support_corridor.has_point(foot_center): continue
			var point := PlayerMetrics.anchor_from_foot_center(foot_center,_scene)
			if bounds.has_point(point) and not points.has(point): points.append(point)
	return points

func campus_road_foot_centers(start: Vector2, goal: Vector2, obstacles: Array, stand: Callable) -> Array[Vector2]:
	var grid: Dictionary = _campus.manifest.get("routeGrid",{})
	if grid.is_empty() or not roads.configure(grid,PlayerMetrics.foot_size(_scene)): return []
	if not stand.call(start) or not stand.call(goal): return []
	var foot_offset := PlayerMetrics.foot_center_offset(_scene)
	var clear_centers := func(a: Vector2,b: Vector2) -> bool:
		var from := a - foot_offset
		var to := b - foot_offset
		return stand.call(from) and stand.call(to) and segment_clear(from, to, obstacles)
	return roads.plan(start + foot_offset,goal + foot_offset,clear_centers,_mask,_mask_meta)

func plan(start: Vector2, goal: Vector2, bounds: Rect2, obstacles: Array)->Array[Vector2]:
	var clear:Callable=func(a:Vector2,b:Vector2)->bool:return segment_clear(a, b, obstacles)
	var stand := func(point: Vector2) -> bool: return bounds.has_point(point) and _can_stand.call(point)
	if _scene=="campus_bootstrap" and _campus.ready:
		if not stand.call(start) or not stand.call(goal): return []
		var centers := campus_road_foot_centers(start,goal,obstacles,stand)
		if not centers.is_empty():
			var foot_offset := PlayerMetrics.foot_center_offset(_scene)
			for index in centers.size(): centers[index] -= foot_offset
			centers[-1] = goal
			return centers
		# Both attempts are synchronous against one unchanged collision state.
		# Reuse exact directed-edge proofs across retries, but never across taps
		# or movement frames. Combined real checks retain the existing budget.
		var edge_cache: Dictionary = {}
		var cached_clear: Callable = func(a:Vector2,b:Vector2)->bool:
			var key := Vector4(a.x,a.y,b.x,b.y)
			if edge_cache.has(key): return bool(edge_cache[key])
			if edge_cache.size() >= MobileFloorRoute.MAX_EDGES: return false
			var result := bool(clear.call(a,b))
			edge_cache[key] = result
			return result
		var local_candidates := campus_detour_nodes(start, goal, bounds, true)
		var route := planner.plan_with_candidates(start,goal,obstacles,bounds,stand,cached_clear,local_candidates)
		if not route.is_empty(): return route
		var all_candidates := campus_detour_nodes(start, goal, bounds)
		if all_candidates == local_candidates: return route
		return planner.plan_with_candidates(start,goal,obstacles,bounds,stand,cached_clear,all_candidates)
	return planner.plan(start,goal,obstacles,bounds,stand,clear)

func campus_sweep_clear(a: Vector2,b: Vector2) -> bool:
	if _scene!="campus_bootstrap" or not _campus.ready: return true
	# Source-mask cell crossings do not describe the new measured polygon
	# boundaries. Sweep the entire foot rectangle, including sub-pixel corners,
	# rather than hoping a 4px mask sampling interval intersects the solid.
	var local_feet:=PlayerMetrics.foot_rect(Vector2.ZERO,_scene)
	var swept_bounds:=PlayerMetrics.foot_rect(a,_scene).merge(PlayerMetrics.foot_rect(b,_scene))
	for region: Dictionary in _campus.water_regions:
		if not swept_bounds.intersects(region.bounds): continue
		for water: Rect2 in region.rects:
			var blocked_anchor:=SpatialRules.obstacle_for_foot_anchor(water, local_feet)
			if MobileFloorRoute.segment_hits(a,b,blocked_anchor): return false
	var corners:=PackedVector2Array()
	for anchor: Vector2 in [a,b]:
		var feet:=PlayerMetrics.foot_rect(anchor,_scene)
		corners.append_array(PackedVector2Array([feet.position,Vector2(feet.end.x,feet.position.y),feet.end,Vector2(feet.position.x,feet.end.y)]))
	var swept:=Geometry2D.convex_hull(corners)
	return not _campus.solid_intersects(swept, swept_bounds)

func segment_clear(a: Vector2, b: Vector2, obstacles: Array) -> bool:
	var segment_bounds := Rect2(a.min(b), (b-a).abs())
	for obstacle: Rect2 in obstacles:
		if segment_bounds.intersects(obstacle, true) and MobileFloorRoute.segment_hits(a,b,obstacle): return false
	if not campus_sweep_clear(a,b): return false
	if _mask.is_empty(): return true
	# Exact conservative fast path: if the ENTIRE swept bounding rectangle
	# is supported and hazard-free, every intermediate whole foot is too.
	# Nonrectangular corridors fall through to the unchanged pixel-edge sweep.
	# Real polygon/water sweeps and legacy/story obstacles were checked above.
	if _scene=="campus_bootstrap" and _campus.ready:
		var envelope:=PlayerMetrics.foot_rect(a,_scene).merge(PlayerMetrics.foot_rect(b,_scene))
		if not _campus.source_floor_override_intersects(envelope) and SpatialRules.mask_allows_rect(envelope,_mask,_mask_meta): return true
		if _campus.reviewed_support_covers(envelope,_mask,_mask_meta):return true
	# Full footprint occupancy only changes as a foot edge crosses a cell edge.
	# Test every such interval, including narrow holes between the old samples.
	var cuts: Array[float]=[0.0,1.0]
	var feet:=PlayerMetrics.foot_rect(Vector2.ZERO,_scene)
	var change:=b-a
	var cell:=float(_mask_meta.cellSize)
	for offset: Vector2 in [feet.get_center(),feet.position,Vector2(feet.end.x,feet.position.y),Vector2(feet.position.x,feet.end.y),feet.end]:
		for axis in [0,1]:
			if absf(change[axis])<.000001: continue
			var first: float=(a+offset)[axis]
			var last: float=(b+offset)[axis]
			for index in range(int(floor(minf(first,last)/cell))+1,int(floor(maxf(first,last)/cell))+1):
				var fraction: float=(index*cell-first)/change[axis]
				if fraction>0 and fraction<1: cuts.append(fraction)
	# Refine only paths crossing the reviewed 1px support domain. The old
	# source-cell spacing alone can skip a one-pixel unsupported hole.
	if _scene == "campus_bootstrap" and _campus.walk_support_intersects(PlayerMetrics.foot_rect(a,_scene).merge(PlayerMetrics.foot_rect(b,_scene))):
		for offset: Vector2 in [feet.position,Vector2(feet.end.x,feet.position.y),Vector2(feet.position.x,feet.end.y),feet.end]:
			for axis in [0,1]:
				if absf(change[axis]) < .000001: continue
				var first: float = (a+offset)[axis]
				var last: float = (b+offset)[axis]
				for edge in range(floori(minf(first,last))+1,floori(maxf(first,last))+1):
					var fraction: float = (float(edge)-first)/change[axis]
					if fraction > 0 and fraction < 1: cuts.append(fraction)
	cuts.sort()
	var previous_cut := cuts[0]
	for index in range(1,cuts.size()):
		var current_cut := cuts[index]
		# The same foot-edge event appears for paired corners and source/1px
		# grids. Only exact duplicates are redundant; keep every unique endpoint
		# and interval midpoint, including arbitrarily narrow unsupported strips.
		if current_cut == previous_cut: continue
		if not _can_stand.call(a.lerp(b,current_cut)) or not _can_stand.call(a.lerp(b,(previous_cut+current_cut)*.5)): return false
		previous_cut = current_cut
	return true

func campus_edge_slide(start: Vector2, motion: Vector2, axis_result: Vector2, obstacles: Array) -> Vector2:
	if motion.is_zero_approx(): return axis_result
	var forward := motion.normalized()
	var progress := (axis_result - start).dot(forward)
	# Project onto the nearest direction that can sweep the whole foot.
	# Progress decreases with the turn angle, so a steeper turn cannot win.
	for angle: float in [15.0, 30.0, 45.0, 60.0, 75.0]:
		for side: float in [-1.0, 1.0]:
			var tangent := forward.rotated(deg_to_rad(angle * side))
			var candidate := start + tangent * motion.dot(tangent)
			if (candidate - start).dot(forward) <= progress + .001: continue
			if _can_stand.call(candidate) and segment_clear(start, candidate, obstacles): return candidate
	# A source-pixel step can require a short sideways move before the next
	# forward segment clears it. Check that continuation before sliding, so
	# holding a key into a straight wall cannot make the player drift.
	var remaining := motion.length() - start.distance_to(axis_result)
	if remaining <= .01: return axis_result
	var lateral := forward.orthogonal()
	for distance: float in [1.0, 2.0, 3.0, 4.0]:
		for side: float in [-1.0, 1.0]:
			var corner := axis_result + lateral * distance * side
			var continuation := corner + forward * 2.0
			if _can_stand.call(corner) and _can_stand.call(continuation) and segment_clear(axis_result, corner, obstacles) and segment_clear(corner, continuation, obstacles):
				return axis_result.move_toward(corner, remaining)
	return axis_result
