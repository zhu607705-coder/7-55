extends RefCounted
## Hinge art only. The existing InteriorDoorLayer owns sensors, time and the logical departure/passable threshold.
## No clock, controller writes, saved state, completion callback or scene reference.
const SOURCE_ASSET := "res://assets/native/canteen_objects/canteen_double_door.png"
const FRAME_ASSET := "res://assets/native/canteen_door/southeast_frame.png"
const LEAVES_ASSET := "res://assets/native/canteen_door/southeast_leaves_8f.png"
const SOURCE_REGION := Rect2(244, 232, 766, 791)
const FRAME_SIZE := Vector2(512, 512)
const FRAME_COUNT := 8
const ATLAS_COLUMNS := 4
const ATLAS_ROWS := 2
const SOURCE_OFFSET := Vector2(64, 40)
const CELL_TO_SOURCE_SCALE := 2.0

# Measured centered alpha-free widths, not assumed angles or uniform frame timing.
const CENTERED_CLEAR_WIDTHS := [0.0, 1.6083550914, 9.4203655352, 21.3681462141, 33.7754569191, 41.5874673629, 46.182767624, 48.9399477807]
const VISUAL_CUES := [0.0, 0.02378025877, 0.139284372795, 0.315937723658, 0.623765748012, 0.817583392975, 0.931593772366, 1.0]
const FIRST_PASSABLE_FRAME := 3

static func frame_index(visual_progress: float, passable: bool) -> int:
	var value := clampf(visual_progress, 0.0, 1.0)
	var index := 0
	for i in range(1, FRAME_COUNT):
		if value + .0000001 < float(VISUAL_CUES[i]):
			break
		index = i
	# The original logical departure threshold wins when an interrupted tween starts from a
	# different visual/linear pair. This does not create or modify a collision wall.
	return maxi(index, FIRST_PASSABLE_FRAME) if passable else mini(index, FIRST_PASSABLE_FRAME - 1)

static func atlas_region(frame: int) -> Rect2:
	var index := clampi(frame, 0, FRAME_COUNT - 1)
	return Rect2(Vector2(index % ATLAS_COLUMNS, floori(float(index) / ATLAS_COLUMNS)) * FRAME_SIZE, FRAME_SIZE)

static func canvas_rect(source_top_left: Vector2, uniform_scale: float) -> Rect2:
	return Rect2(source_top_left - SOURCE_OFFSET * uniform_scale * CELL_TO_SOURCE_SCALE, FRAME_SIZE * uniform_scale * CELL_TO_SOURCE_SCALE)

static func sample(visual_progress: float, passable: bool, source_top_left: Vector2, uniform_scale: float) -> Dictionary:
	var frame := frame_index(visual_progress, passable)
	return {
		"frame": frame,
		"closed": frame == 0,
		"source": atlas_region(frame),
		"rect": canvas_rect(source_top_left, uniform_scale),
		"scale": Vector2.ONE * uniform_scale * CELL_TO_SOURCE_SCALE,
		"alpha": 1.0,
		"rotation": 0.0,
	}
