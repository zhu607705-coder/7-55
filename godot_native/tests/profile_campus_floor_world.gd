extends "res://scripts/world.gd"
var profile: Dictionary = {"standCalls":0,"standUsec":0,"segmentCalls":0,"segmentUsec":0,"hazardSweepCalls":0,"hazardSweepUsec":0,"edges":[]}
func can_stand(point: Vector2, kayak_heading: float=NAN) -> bool:
	var tick := Time.get_ticks_usec()
	var result := super.can_stand(point,kayak_heading)
	profile.standCalls += 1
	profile.standUsec += Time.get_ticks_usec()-tick
	return result
func _floor_campus_sweep_clear(a: Vector2,b: Vector2) -> bool:
	var tick := Time.get_ticks_usec()
	var result := super._floor_campus_sweep_clear(a,b)
	profile.hazardSweepCalls += 1
	profile.hazardSweepUsec += Time.get_ticks_usec()-tick
	return result
func _floor_segment_clear(a: Vector2,b: Vector2,obstacles: Array=[],validated: bool=false) -> bool:
	var tick := Time.get_ticks_usec()
	var result := super._floor_segment_clear(a,b,obstacles,validated)
	var micros := Time.get_ticks_usec()-tick
	profile.segmentCalls += 1
	profile.segmentUsec += micros
	profile.edges.append({"a":[a.x,a.y],"b":[b.x,b.y],"clear":result,"usec":micros})
	return result
