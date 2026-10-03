extends RefCounted
## Bounded nearest full-foot placement for the canteen's exact rectangles.
## No path planning, target selection, geometry edits, or state writes.
const PIXEL_RADIUS := 6.0
const MAX_CANDIDATES := 4096
var candidate_count := 0

func nearest(goal: Vector2,radius: float,boxes: Array,stand: Callable,eligible: Callable) -> Vector2:
	candidate_count=0
	var xs: Array[float]=[goal.x]
	var ys: Array[float]=[goal.y]
	var neighborhood:=Rect2(goal-Vector2.ONE*radius,Vector2.ONE*radius*2)
	for box: Rect2 in boxes:
		if not box.intersects(neighborhood,true): continue
		for x: float in [box.position.x,box.end.x]:
			if absf(x-goal.x)<=radius and not xs.has(x): xs.append(x)
		for y: float in [box.position.y,box.end.y]:
			if absf(y-goal.y)<=radius and not ys.has(y): ys.append(y)
	if xs.size()*ys.size()>MAX_CANDIDATES: return goal
	var nearest_point:=goal
	var best:=INF
	for x in xs:
		for y in ys:
			candidate_count+=1
			var point:=Vector2(x,y)
			var dx: float=point.x-goal.x;var dy: float=point.y-goal.y
			var distance:=dx*dx+dy*dy
			if distance>radius*radius or not stand.call(point): continue
			if distance<best or (distance==best and (point.x<nearest_point.x or (point.x==nearest_point.x and point.y<nearest_point.y))):
				best=distance;nearest_point=point
	# Ownership vetoes the nearest legal location; never seek a farther target.
	return nearest_point if best<INF and eligible.call(nearest_point) else goal
