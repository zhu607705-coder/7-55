extends RefCounted

const Track = preload("res://scripts/games/virtual_run_motion.gd")

static func target(motion: RefCounted, look_ahead: float = 13.0) -> Vector2:
	var start: float = motion.start_distance()
	var end: float = motion.end_distance()
	var ahead: float = minf(end, lerpf(start, end, motion.fraction()) + look_ahead)
	return Track.at_distance(ahead)
