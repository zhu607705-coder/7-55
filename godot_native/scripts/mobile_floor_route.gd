extends RefCounted
## Bounded visibility graph over unchanged player-anchor collision rectangles.
## This helper has no State, targets, saved data, or interaction authority.
const MAX_CORNERS := 192
const MAX_EDGES := 4096
const CORNER_CLEARANCE := 0.25
# Scenes with independently measured furniture may opt into a larger bounded
# graph. The default remains unchanged for all existing planner consumers.
var corner_limit := MAX_CORNERS
var edge_limit := MAX_EDGES
var edge_checks := 0
var corner_count := 0
var _detour_candidates:Array[Vector2]=[]

static func segment_hits(a: Vector2,b: Vector2,box: Rect2) -> bool:
	# Open slabs match Rect2.intersects: tangency alone does not collide.
	var lo := 0.0
	var hi := 1.0
	var direction := b-a
	for axis in [0,1]:
		if absf(direction[axis])<0.000001:
			if a[axis]<=box.position[axis] or a[axis]>=box.end[axis]: return false
		else:
			var first: float=(box.position[axis]-a[axis])/direction[axis]
			var last: float=(box.end[axis]-a[axis])/direction[axis]
			lo=maxf(lo,minf(first,last)); hi=minf(hi,maxf(first,last))
			if lo>=hi: return false
	return lo<hi

func plan(start: Vector2,goal: Vector2,boxes: Array,allowed: Rect2,stand: Callable,clear: Callable) -> Array[Vector2]:
	edge_checks=0; corner_count=0
	var none: Array[Vector2]=[]
	if not allowed.has_point(start) or not allowed.has_point(goal) or not stand.call(start) or not stand.call(goal): return none
	edge_checks+=1
	if clear.call(start,goal): return [goal]
	var nodes: Array[Vector2]=[start,goal]
	for obstacle: Rect2 in boxes:
		if not obstacle.intersects(allowed): continue
		var box:=obstacle.grow(CORNER_CLEARANCE)
		for point: Vector2 in [box.position,Vector2(box.end.x,box.position.y),box.end,Vector2(box.position.x,box.end.y)]:
			if not allowed.has_point(point) or not stand.call(point) or nodes.has(point): continue
			if nodes.size()-2>=corner_limit:
				corner_count=nodes.size()-2
				return none
			nodes.append(point)
	# Extra geometry is only a source of graph candidates, never rectangular
	# collision authority. The original stand/clear callables validate every
	# endpoint and edge against true campus polygons and the full footprint.
	var candidates:=_detour_candidates.duplicate()
	candidates.sort_custom(func(a:Vector2,b:Vector2)->bool: return start.distance_to(a)+a.distance_to(goal)<start.distance_to(b)+b.distance_to(goal))
	for point:Vector2 in candidates:
		if nodes.size()-2>=MAX_CORNERS:break
		if not allowed.has_point(point) or nodes.has(point) or not stand.call(point):continue
		nodes.append(point)
	corner_count=nodes.size()-2
	var costs: Array[float]=[]
	var previous: Array[int]=[]
	var closed: Array[bool]=[]
	for point in nodes: costs.append(INF); previous.append(-1); closed.append(false)
	costs[0]=0.0
	var edges: Dictionary={}
	for iteration in nodes.size():
		var current: int=-1
		var best: float=INF
		for index in nodes.size():
			var estimate: float=costs[index]+nodes[index].distance_to(goal)
			if not closed[index] and estimate<best: current=index; best=estimate
		if current<0: return none
		if current==1:
			var route: Array[Vector2]=[]
			while current>0: route.push_front(nodes[current]); current=previous[current]
			return route
		closed[current]=true
		for next in nodes.size():
			if closed[next]: continue
			var cost:=costs[current]+nodes[current].distance_to(nodes[next])
			if cost>=costs[next]: continue
			var key:=Vector2i(mini(current,next),maxi(current,next))
			if not edges.has(key):
				if edge_checks>=edge_limit: return none
				edge_checks+=1; edges[key]=bool(clear.call(nodes[current],nodes[next]))
			if edges[key]: costs[next]=cost; previous[next]=current
	return none

func plan_with_candidates(start:Vector2,goal:Vector2,boxes:Array,allowed:Rect2,stand:Callable,clear:Callable,candidates:Array[Vector2])->Array[Vector2]:
	# Preserve the existing six-argument virtual plan API and restore local
	# state immediately; non-campus callers/subclasses remain unchanged.
	var previous:=_detour_candidates
	_detour_candidates=candidates
	var result:=plan(start,goal,boxes,allowed,stand,clear)
	_detour_candidates=previous
	return result
