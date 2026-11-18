extends RefCounted
## Shared full-body art for ordinary walking. Scene-specific action poses live
## with their own presenters.
const Facing := preload("res://scripts/character_facing.gd")
const ROOT := "res://assets/native/library_animation_20261105/"
const WALK_PATH := "res://assets/native/player_locomotion/player_walk_and_idle.png"
const FEMALE_PREVIEW_PATH := "res://art_source/player_locomotion_20261116/female_preview/walk_and_idle.png"
const FEMALE_PREVIEW_FRAMES := 8
const WALK_DIRECTIONS := ["side", "down", "up"]
const WALK_FRAMES := 16
const CYCLE_MS := 800.0
const WALK_CELL := Vector2i(120, 160)

var ready := false
var frame_count := WALK_FRAMES
var walks: Dictionary = {}
var idles: Dictionary = {}
static var _shared: RefCounted

static func shared() -> RefCounted:
	if _shared == null:
		_shared = load("res://scripts/player_walk_art.gd").new()
	return _shared

static func female_preview() -> RefCounted:
	var sheet := Image.load_from_file(FEMALE_PREVIEW_PATH)
	var art: RefCounted = load("res://scripts/player_walk_art.gd").new()
	return art if art._read_sheet(sheet, FEMALE_PREVIEW_FRAMES) else null

static func walk_region(direction_index: int, frame: int) -> Rect2i:
	return Rect2i(Vector2i(frame, direction_index) * WALK_CELL, WALK_CELL)

static func atlas_size() -> Vector2i:
	return WALK_CELL * Vector2i(WALK_FRAMES + 1, WALK_DIRECTIONS.size())

func ensure_loaded() -> bool:
	if ready:
		return true
	if not ResourceLoader.exists(WALK_PATH):
		return false
	var atlas: Texture2D = load(WALK_PATH)
	if atlas == null or atlas.get_size() != Vector2(atlas_size()):
		return false
	return _read_sheet(atlas.get_image(), WALK_FRAMES)

func _read_sheet(sheet: Image, count: int) -> bool:
	var dimensions := WALK_CELL * Vector2i(count + 1, WALK_DIRECTIONS.size())
	if sheet == null or sheet.is_empty() or sheet.is_compressed() or sheet.get_size() != dimensions:
		return false
	var pending_walks := {}
	var pending_idles := {}
	for row in WALK_DIRECTIONS.size():
		var direction: String = WALK_DIRECTIONS[row]
		pending_idles[direction] = ImageTexture.create_from_image(sheet.get_region(walk_region(row, count)))
		var frames: Array[Texture2D] = []
		for index in count:
			frames.append(ImageTexture.create_from_image(sheet.get_region(walk_region(row, index))))
		pending_walks[direction] = frames
	walks = pending_walks
	idles = pending_idles
	frame_count = count
	ready = true
	return true

static func frame_at(elapsed_ms: float, count: int = WALK_FRAMES) -> int:
	return int(fmod(maxf(0.0, elapsed_ms), CYCLE_MS) / (CYCLE_MS / count))

static func texture(direction: String, elapsed_ms: float = 0.0, moving := false) -> Texture2D:
	var art := shared()
	if not art.ensure_loaded():
		return null
	return art.actor(direction, false, elapsed_ms, moving).texture

func actor(direction: String, flip: bool, elapsed_ms: float, moving: bool) -> Dictionary:
	var key := "side" if direction == "left" else direction
	if not ready or not walks.has(key):
		return {}
	var frames: Array = walks[key]
	var index := frame_at(elapsed_ms, frame_count)
	return {
		"texture": frames[index] if moving else idles[key],
		"flip_h": direction == "left" or (key == "side" and flip),
		"direction": direction,
		"motion_frame": index if moving else -1,
		"frame_count": frame_count,
		"cycle_ms": CYCLE_MS,
		"animation": "shared_player_walk",
		"angle": 0.0,
	}

func sample(facing: String, flip: bool, turn: Dictionary, elapsed_seconds: float) -> Dictionary:
	var pose := Facing.turn_pose(turn) if not turn.is_empty() else {"facing": facing, "flip": flip, "angle": 0.0}
	var visual := actor(pose.facing, pose.flip, elapsed_seconds * 1000.0, elapsed_seconds > 0.0 and turn.is_empty())
	if not visual.is_empty():
		visual.angle = pose.angle
	return visual

static func advance_clock(elapsed: float, motion: Vector2, delta: float) -> float:
	return elapsed + maxf(0.0, delta) if motion.is_finite() and not motion.is_zero_approx() else 0.0
