extends RefCounted
## Registered tray keyposes only. The existing controller owns pickup and return facts.
## No local clock, tray count, scene references, saved state, or completion callback.
const SOURCE_ASSET := "res://assets/native/chapter3/tray_clean.svg"
const ATLAS_ASSET := "res://assets/native/canteen_animation/tray_tilt_8f.png"
const FRAME_SIZE := Vector2(128, 128)
const ATLAS_COLUMNS := 4
const ATLAS_ROWS := 2
const FRAME_COUNT := 8
const SOURCE_REGION := Rect2(0, 0, 28, 28)
const CONTACT_T := .3125
const IMPACT_T := .5625
const ALIGNED_T := .80

# Each cue selects a separately drawn pose. No runtime shear, squash, or tilt.
# Pickup comes back to the original carried silhouette before the controller handoff.
const PICKUP_CUES := [0.0, .08, .18, .30, .42, .58, .70, .82, .92]
const PICKUP_FRAMES := [0, 1, 2, 3, 4, 3, 2, 1, 0]
const REDUCED_PICKUP_CUES := [0.0, .25, .75]
const REDUCED_PICKUP_FRAMES := [0, 1, 0]
const RETURN_CUES := [0.0, .07, .14, .22, CONTACT_T, .4375, IMPACT_T, ALIGNED_T]
const RETURN_FRAMES := [0, 1, 2, 3, 4, 5, 6, 7]
const REDUCED_RETURN_CUES := [0.0, .15, CONTACT_T, IMPACT_T]
const REDUCED_RETURN_FRAMES := [0, 1, 5, 7]

static func pickup_duration_ms(reduced: bool) -> float:
	return 100.0 if reduced else 360.0

static func return_duration(reduced: bool) -> float:
	return .16 if reduced else .32

static func atlas_region(frame: int) -> Rect2:
	var index: int = clampi(frame, 0, FRAME_COUNT - 1)
	var row: int = floori(float(index) / float(ATLAS_COLUMNS))
	return Rect2(Vector2(index % ATLAS_COLUMNS, row) * FRAME_SIZE, FRAME_SIZE)

static func _frame_at(progress: float, cues: Array, frames: Array) -> int:
	var index := 0
	for i in range(1, cues.size()):
		if progress < float(cues[i]):
			break
		index = i
	return int(frames[index])

static func _paint(frame: int, position: Vector2, size: float, alpha: float) -> Dictionary:
	# Frame zero always paints the source SVG, including the pickup and carried endpoints.
	# The atlas frame-zero registration remains useful for art QA, not idle replacement.
	return {
		"frame": frame,
		"asset": SOURCE_ASSET if frame == 0 else ATLAS_ASSET,
		"source": SOURCE_REGION if frame == 0 else atlas_region(frame),
		"position": position,
		"size": size,
		"angle": 0.0,
		"alpha": alpha,
		"use_atlas": frame != 0,
	}

static func pickup_sample(age_ms: float, start: Vector2, hand: Vector2, reduced: bool) -> Dictionary:
	var t: float = clampf(age_ms / pickup_duration_ms(reduced), 0.0, 1.0)
	var frame: int = _frame_at(t, REDUCED_PICKUP_CUES if reduced else PICKUP_CUES,
		REDUCED_PICKUP_FRAMES if reduced else PICKUP_FRAMES)
	var at: Vector2 = start.lerp(hand, smoothstep(0.0, 1.0, t))
	# Preserve the native pickup's existing 18px / reduced 3px flight arc.
	if t > 0.0 and t < 1.0:
		at.y -= sin(t * PI) * (3.0 if reduced else 18.0)
	var pose: Dictionary = _paint(frame, at, 24.0, 1.0)
	pose["progress"] = t
	pose["settled"] = t >= 1.0
	return pose

static func return_sample(age: float, hand: Vector2, anchor: Vector2, height: float,
		reduced: bool) -> Dictionary:
	var t: float = clampf(age / return_duration(reduced), 0.0, 1.0)
	var frame: int = _frame_at(t, REDUCED_RETURN_CUES if reduced else RETURN_CUES,
		REDUCED_RETURN_FRAMES if reduced else RETURN_FRAMES)
	# The return stack is rigid throughout. Only the one transient tray can settle.
	var contact: Vector2 = anchor + Vector2(0.0, -height * .67)
	var corner_offset := Vector2(-1.0, 0.0 if reduced else -2.0)
	var at: Vector2 = contact
	if t < CONTACT_T:
		var approach: float = smoothstep(0.0, CONTACT_T, t)
		at = hand.lerp(contact + corner_offset, approach)
		if not reduced:
			at.y -= sin(approach * PI) * 8.0
	elif t < IMPACT_T:
		at += corner_offset * (1.0 - smoothstep(CONTACT_T, IMPACT_T, t))
	elif t < ALIGNED_T and not reduced:
		# A 1.2px top-tray rebound, never a deformation of the pile beneath it.
		at.y -= sin(smoothstep(IMPACT_T, ALIGNED_T, t) * PI) * 1.2
	var alpha: float = 1.0 - smoothstep(.75, 1.0, t)
	var size: float = lerpf(24.0, 28.0, smoothstep(0.0, CONTACT_T, t))
	var pose: Dictionary = _paint(frame, at, size, alpha)
	pose["progress"] = t
	pose["pressure"] = 0.0
	pose["contact"] = contact
	pose["settled"] = t >= 1.0
	pose["phase"] = "approach" if t < CONTACT_T else (
		"contact" if t < IMPACT_T else ("weight" if t < ALIGNED_T else "settle"))
	return pose
