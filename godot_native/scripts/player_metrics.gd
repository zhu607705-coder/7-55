extends RefCounted
## Default formulas from src/scenes/rpg/RpgPlayerTextures.ts.
## The reviewed campus collision profile is independent of sprite/depth placement.
const FRAME := Vector2(96,128)
const DISPLAY_SCALE := 0.65
const GROUND_OFFSET := 41.6
const FOOT_SIZE := Vector2(19.5,14.625)
const FOOT_BOTTOM_INSET := 2.6
const FOOT_CENTER_OFFSET := Vector2(0,31.6875)
const CAMPUS_FOOT_SIZE := Vector2(16,10)
# The campus sprite is rendered at .325 with its top at the anchor. The
# original walking frames end at +40.95. The user moved the initial +39
# trial upward by one third of its +7.3125 shift, leaving a +4.875 shift.
const CAMPUS_FOOT_CENTER_OFFSET := Vector2(0,36.5625)
static func frame_at(elapsed_ms: float) -> int:
	return int(floor(maxf(0,elapsed_ms)/110.0)) % 8
static func frame_for_count(elapsed_ms:float,frames:int)->int:
	# Extra drawing samples keep the existing 8*110 ms stride cycle.
	return int(floor(maxf(0,elapsed_ms)/(880.0/maxi(1,frames))))%maxi(1,frames)
static func visual_rect(anchor: Vector2,display_scale: float=DISPLAY_SCALE) -> Rect2:
	var dimensions := FRAME*maxf(.01,display_scale)
	return Rect2(anchor-Vector2(dimensions.x/2,dimensions.y-GROUND_OFFSET),dimensions)
static func foot_size(scene: String="") -> Vector2:
	return CAMPUS_FOOT_SIZE if scene=="campus_bootstrap" else FOOT_SIZE
static func foot_center_offset(scene: String="") -> Vector2:
	return CAMPUS_FOOT_CENTER_OFFSET if scene=="campus_bootstrap" else FOOT_CENTER_OFFSET
static func foot_center(anchor: Vector2,scene: String="") -> Vector2:
	return anchor+foot_center_offset(scene)
static func anchor_from_foot_center(center: Vector2,scene: String="") -> Vector2:
	return center-foot_center_offset(scene)
static func foot_rect(anchor: Vector2,scene: String="") -> Rect2:
	var dimensions:=foot_size(scene)
	return Rect2(foot_center(anchor,scene)-dimensions/2,dimensions)
static func depth_y(anchor: Vector2) -> float:
	# Campus foreground calibration predates the physical-foot change. Never
	# move that rendering threshold when changing collision dimensions/offsets.
	return anchor.y+FOOT_CENTER_OFFSET.y
static func scale_at(scene: String,world_y: float,perspective: Dictionary={}) -> float:
	if scene=="campus_bootstrap": return DISPLAY_SCALE*.5
	if scene=="library_interior": return DISPLAY_SCALE*.8
	if scene!="campus_qizhen_loop" or perspective.is_empty(): return DISPLAY_SCALE
	var progress := clampf((world_y-float(perspective.farY))/(float(perspective.nearY)-float(perspective.farY)),0,1)
	return DISPLAY_SCALE*float(perspective.baseMultiplier)*lerpf(float(perspective.farMultiplier),float(perspective.nearMultiplier),progress)
