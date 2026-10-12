extends RefCounted
## Presentation-only pin placement. No input, route, or progression ownership.
static func student_screen_bounds(visitor: Node2D) -> Rect2:
	var visual: Node2D=visitor.get_node("StudentVisual")
	var local: Rect2=visual.get_meta("landmark_pin_local_bounds",Rect2())
	if not local.has_area():
		# Union the registered artwork rectangles once, avoiding walk-frame edge jitter.
		# Every rectangle comes from the real StudentVisual's texture, scale and foot offset.
		for direction in visual.registered_frames.values():
			for state in direction.values():
				for frame in state:
					var rect:=Rect2(frame.offset,frame.texture.get_size()*float(frame.scale))
					local=local.merge(rect) if local.has_area() else rect
		visual.set_meta("landmark_pin_local_bounds",local)
	var transform:=visual.get_global_transform_with_canvas()
	var bounds:=Rect2(transform*local.position,Vector2.ZERO)
	for corner in [Vector2(local.end.x,local.position.y),local.end,Vector2(local.position.x,local.end.y)]:
		bounds=bounds.expand(transform*corner)
	return bounds.grow(8.0)

static func place(anchor: Vector2,size: Vector2,body: Rect2,area: Rect2) -> Vector2:
	var original:=anchor.clamp(area.position,area.end-size)
	if not Rect2(original,size).intersects(body):return original
	# Recompute from the original map anchor every frame; never offset yesterday's result.
	var candidates: Array[Vector2]=[
		Vector2(original.x,body.position.y-size.y-6),
		Vector2(body.end.x+6,original.y),
		Vector2(body.position.x-size.x-6,original.y),
		Vector2(original.x,body.end.y+6)]
	var best:=original
	var minimum_overlap:=Rect2(original,size).intersection(body).get_area()
	for candidate in candidates:
		var fitted:=candidate.clamp(area.position,area.end-size)
		var overlap:=Rect2(fitted,size).intersection(body).get_area()
		if overlap<=0:return fitted
		if overlap<minimum_overlap:best=fitted;minimum_overlap=overlap
	return best
