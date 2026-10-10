extends RefCounted
## Direct formulas from src/scenes/rpg/RpgPlayerTextures.ts.
const FRAME := Vector2(96,128)
const DISPLAY_SCALE := 0.65
const GROUND_OFFSET := 41.6
const FOOT_SIZE := Vector2(19.5,14.625)
const FOOT_BOTTOM_INSET := 2.6
const FOOT_CENTER_OFFSET := Vector2(0,31.6875)
static func frame_at(elapsed_ms: float) -> int:
	return int(floor(maxf(0,elapsed_ms)/110.0)) % 8
static func visual_rect(anchor: Vector2,display_scale: float=DISPLAY_SCALE) -> Rect2:
	var dimensions := FRAME*maxf(.01,display_scale)
	return Rect2(anchor-Vector2(dimensions.x/2,dimensions.y-GROUND_OFFSET),dimensions)
static func foot_rect(anchor: Vector2) -> Rect2:
	return Rect2(anchor+FOOT_CENTER_OFFSET-FOOT_SIZE/2,FOOT_SIZE)
static func scale_at(scene: String,world_y: float,perspective: Dictionary={}) -> float:
	if scene=="campus_bootstrap": return DISPLAY_SCALE*.5
	if scene!="campus_qizhen_loop" or perspective.is_empty(): return DISPLAY_SCALE
	var progress := clampf((world_y-float(perspective.farY))/(float(perspective.nearY)-float(perspective.farY)),0,1)
	return DISPLAY_SCALE*float(perspective.baseMultiplier)*lerpf(float(perspective.farMultiplier),float(perspective.nearMultiplier),progress)
