extends RefCounted
## Shared walking geometry for the native player. Depth keeps its source calibration.
const FRAME := Vector2(96,128)
const DISPLAY_SCALE := 0.65
const GROUND_OFFSET := 41.6
const FOOT_SIZE := Vector2(16,10)
const FOOT_CENTER_OFFSET := Vector2(0,36.5625)
# Hair, shoulders and arms stay within 27 frame pixels of the center
# in the walking poses. This width is used at solid furniture sides.
const UPPER_BODY_HALF_WIDTH := 18.0
const DEPTH_CENTER_OFFSET := Vector2(0,31.6875)
const GROUND_DEPTH_OFFSET := 39.0
# Old saves store the sprite anchor. Align the lower edge if that pose is blocked.
const FOOT_BOTTOM_SHIFT := FOOT_CENTER_OFFSET.y+FOOT_SIZE.y/2-GROUND_DEPTH_OFFSET
static func frame_at(elapsed_ms: float) -> int:
	return int(floor(maxf(0,elapsed_ms)/110.0)) % 8
static func frame_for_count(elapsed_ms:float,frames:int)->int:
	# Extra drawing samples keep the existing 8*110 ms stride cycle.
	return int(floor(maxf(0,elapsed_ms)/(880.0/maxi(1,frames))))%maxi(1,frames)
static func visual_rect(anchor: Vector2,display_scale: float=DISPLAY_SCALE) -> Rect2:
	var dimensions := FRAME*maxf(.01,display_scale)
	return Rect2(anchor-Vector2(dimensions.x/2,dimensions.y-GROUND_OFFSET),dimensions)
static func foot_size(scene: String="") -> Vector2:
	return Vector2(UPPER_BODY_HALF_WIDTH*2,FOOT_SIZE.y) if scene=="library_interior" else FOOT_SIZE
static func foot_center_offset(_scene: String="") -> Vector2:
	return FOOT_CENTER_OFFSET
static func foot_center(anchor: Vector2,_scene: String="") -> Vector2:
	return anchor+FOOT_CENTER_OFFSET
static func anchor_from_foot_center(center: Vector2,_scene: String="") -> Vector2:
	return center-FOOT_CENTER_OFFSET
static func foot_rect(anchor: Vector2,scene: String="") -> Rect2:
	var dimensions:=foot_size(scene)
	return Rect2(foot_center(anchor)-dimensions/2,dimensions)
static func depth_y(anchor: Vector2) -> float:
	return anchor.y+DEPTH_CENTER_OFFSET.y
static func ground_depth_y(anchor: Vector2) -> float:
	return anchor.y+GROUND_DEPTH_OFFSET
static func scale_at(scene: String,world_y: float,perspective: Dictionary={}) -> float:
	if scene=="campus_bootstrap": return DISPLAY_SCALE*.5
	if scene!="campus_qizhen_loop" or perspective.is_empty(): return DISPLAY_SCALE
	var progress := clampf((world_y-float(perspective.farY))/(float(perspective.nearY)-float(perspective.farY)),0,1)
	return DISPLAY_SCALE*float(perspective.baseMultiplier)*lerpf(float(perspective.farMultiplier),float(perspective.nearMultiplier),progress)
