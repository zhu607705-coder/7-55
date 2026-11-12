extends RefCounted

const PlayerMetrics := preload("res://scripts/player_metrics.gd")
const LAYOUT_PATH := "res://data/native/canteen-object-layout.json"
const EXIT_TARGET_ID := "southeast_exit"
static var _layout: Dictionary = {}

static func data() -> Dictionary:
	if _layout.is_empty():
		_layout = JSON.parse_string(FileAccess.get_file_as_string(LAYOUT_PATH))
	return _layout

static func exit_threshold() -> Rect2:
	var threshold: Dictionary = data().side_exit.threshold
	return Rect2(threshold.left, threshold.top, threshold.right - threshold.left, threshold.bottom - threshold.top)

static func exit_contains_player(anchor: Vector2) -> bool:
	return exit_threshold().encloses(PlayerMetrics.foot_rect(anchor, "canteen_interior"))

static func x_on_floor(source_x: float, asset: String) -> float:
	return source_x + float(data().dining_offsets_x[asset])

static func seated_x(placement: Dictionary, extra: bool) -> float:
	# In both source atlases, the left-facing seat group precedes the right group.
	var left_pairs := 3 if extra else 4
	var bench := "bench_left" if int(placement.framePair) < left_pairs else "bench_right"
	return x_on_floor(float(placement.x), bench)
