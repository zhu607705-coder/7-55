extends "res://scripts/world.gd"
## Frozen pre-dedup cut loop; only footprint selection follows current scene metrics.
var stand_calls := 0
func can_stand(point: Vector2, kayak_heading: float=NAN) -> bool:
	stand_calls += 1
	return super.can_stand(point,kayak_heading)

func _floor_segment_clear(a: Vector2,b: Vector2,planned_obstacles: Array=[],validated_nodes: bool=false) -> bool:
	# Planning is synchronous and has already checked each graph node. Walking
	# always takes the default branch and reads current collisions every frame.
	if not validated_nodes and (not _floor_stand(a) or not _floor_stand(b)): return false
	if not _floor_campus_sweep_clear(a,b): return false
	for obstacle: Rect2 in (planned_obstacles if validated_nodes else _floor_obstacles()):
		if MobileFloorRoute.segment_hits(a,b,obstacle): return false
	if mask.is_empty(): return true
	# Exact conservative fast path: if the ENTIRE swept bounding rectangle
	# is supported and hazard-free, every intermediate whole foot is too.
	# Nonrectangular corridors fall through to the unchanged pixel-edge sweep.
	# Real polygon/water sweeps and legacy/story obstacles were checked above.
	if scene_id=="campus_bootstrap" and campus_layers.ready:
		var envelope:=PlayerMetrics.foot_rect(a,scene_id).merge(PlayerMetrics.foot_rect(b,scene_id))
		if campus_layers.reviewed_support_covers(envelope,mask,mask_meta):return true
	# Full footprint occupancy only changes as a foot edge crosses a cell edge.
	# Test every such interval, including narrow holes between the old samples.
	var cuts: Array[float]=[0.0,1.0]
	var feet:=PlayerMetrics.foot_rect(Vector2.ZERO,scene_id)
	var change:=b-a
	var cell:=float(mask_meta.cellSize)
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
	if scene_id == "campus_bootstrap" and campus_layers.walk_support_intersects(PlayerMetrics.foot_rect(a,scene_id).merge(PlayerMetrics.foot_rect(b,scene_id))):
		for offset: Vector2 in [feet.position,Vector2(feet.end.x,feet.position.y),Vector2(feet.position.x,feet.end.y),feet.end]:
			for axis in [0,1]:
				if absf(change[axis]) < .000001: continue
				var first: float = (a+offset)[axis]
				var last: float = (b+offset)[axis]
				for edge in range(floori(minf(first,last))+1,floori(maxf(first,last))+1):
					var fraction: float = (float(edge)-first)/change[axis]
					if fraction > 0 and fraction < 1: cuts.append(fraction)
	cuts.sort()
	for index in range(1,cuts.size()):
		if not can_stand(a.lerp(b,cuts[index])) or not can_stand(a.lerp(b,(cuts[index-1]+cuts[index])*.5)): return false
	return true
