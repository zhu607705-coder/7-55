extends RefCounted
## Screen-space heading for top-down 2D actors. Camera pan/zoom do not change it.
## Prefer actual movement after collision; a blocked actor may still turn in place.
static func pose(motion: Vector2,intent: Vector2,previous: String="down",flipped: bool=false) -> Dictionary:
	var heading:=motion if motion.is_finite() and not motion.is_zero_approx() else intent
	if not heading.is_finite() or heading.is_zero_approx():
		return {"facing":previous,"flip":flipped}
	var horizontal:=absf(heading.x)>absf(heading.y)
	# Keep the current axis for exact diagonals instead of jittering between poses.
	if is_equal_approx(absf(heading.x),absf(heading.y)):horizontal=previous=="side"
	return {"facing":"side" if horizontal else "up" if heading.y<0 else "down","flip":heading.x<0 if horizontal else flipped}

## RpgPlayerTextures.ts / RpgPlayerAnimator source turn timings and whole poses.
static func turn_duration(from:String,from_flip:bool,to:String,to_flip:bool) -> float:
	if from=="side" and to=="side" and from_flip!=to_flip:return 150.0
	if from!="side" and to!="side" and from!=to:return 170.0
	return 132.0

static func turn_pose(turn:Dictionary) -> Dictionary:
	var progress:=clampf(float(turn.elapsed_ms)/float(turn.duration_ms),0,1)
	if progress<.3:return {"facing":turn.from_facing,"flip":turn.from_flip,"angle":0.0}
	if progress<.68:
		if turn.from_facing=="side" and turn.to_facing=="side" and turn.from_flip!=turn.to_flip:
			return {"facing":"down","flip":false,"angle":0.0}
		var flip:bool=turn.to_flip if turn.to_facing=="side" else turn.from_flip if turn.from_facing=="side" else false
		return {"facing":"side","flip":flip,"angle":-6.0 if flip else 6.0}
	return {"facing":turn.to_facing,"flip":turn.to_flip,"angle":0.0}
