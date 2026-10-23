extends RefCounted
## Bounded geometric candidates inside the original interaction radius.
## The world checks the actual body and plans every accepted route.
const MAX_PLANS=8
static func candidates(start:Vector2,area:Rect2,radius:float,anchor_offset:Vector2,authored_stand:Vector2=Vector2.INF)->Array[Vector2]:
	var points:Array[Vector2]=[]
	var actor:Vector2=start+anchor_offset
	var closest:Vector2=actor.clamp(area.position,area.end)
	var toward:Vector2=(actor-closest).normalized()
	if toward.is_zero_approx():toward=Vector2.DOWN
	points.append(closest+toward*maxf(0,radius-4)-anchor_offset)
	for index:int in range(16):
		var direction:=Vector2.from_angle(index*TAU/16)
		var edge:Vector2=(area.get_center()+direction*maxf(1,area.size.length())).clamp(area.position,area.end)
		for ratio:float in [.85,.5,0.0]:
			var point:Vector2=edge+direction*maxf(0,radius)*ratio-anchor_offset
			if not points.has(point):points.append(point)
	points.sort_custom(func(a:Vector2,b:Vector2)->bool:return start.distance_squared_to(a)<start.distance_squared_to(b))
	if authored_stand.is_finite():
		points.erase(authored_stand);points.push_front(authored_stand)
	return points
