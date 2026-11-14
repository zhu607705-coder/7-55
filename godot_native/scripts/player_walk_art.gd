extends RefCounted
## Shared full-body art for ordinary walking. Scene-specific action poses live
## with their own presenters.
const Metrics := preload("res://scripts/player_metrics.gd")
const Facing := preload("res://scripts/character_facing.gd")
const ActorTexture := preload("res://scripts/objects/library_actor_texture.gd")
const ROOT := "res://assets/native/library_animation_20261105/"
const WALK_PATH := ROOT + "player_walk_full.png"
const WALK_DIRECTIONS := ["side", "down", "up"]
const WALK_FRAMES := 8
const WALK_CELL := Vector2i(120, 160)

var ready := false
var walks: Dictionary = {}
var idles: Dictionary = {}
static var _shared: RefCounted

static func shared() -> RefCounted:
	if _shared == null:
		_shared = load("res://scripts/player_walk_art.gd").new()
	return _shared

static func walk_region(direction_index: int, frame: int) -> Rect2i:
	return Rect2i(Vector2i(frame, direction_index) * WALK_CELL, WALK_CELL)

static func atlas_size() -> Vector2i:
	return WALK_CELL * Vector2i(WALK_FRAMES, WALK_DIRECTIONS.size())

func ensure_loaded() -> bool:
	if ready:
		return true
	if not ResourceLoader.exists(WALK_PATH):
		return false
	var atlas: Texture2D = load(WALK_PATH)
	if atlas == null or atlas.get_size() != Vector2(atlas_size()):
		return false
	var sheet := atlas.get_image()
	if sheet == null or sheet.is_empty() or sheet.is_compressed():
		return false
	var pending_walks := {}
	var pending_idles := {}
	for row in WALK_DIRECTIONS.size():
		var direction: String = WALK_DIRECTIONS[row]
		var idle_path := ROOT + "player_" + direction + "_idle.png"
		if not ResourceLoader.exists(idle_path):
			return false
		var idle: Texture2D = load(idle_path)
		if idle == null or idle.get_size() != Metrics.FRAME:
			return false
		pending_idles[direction] = ActorTexture.prepare_player(idle)
		var frames: Array[Texture2D] = []
		for index in WALK_FRAMES:
			frames.append(ImageTexture.create_from_image(sheet.get_region(walk_region(row, index))))
		pending_walks[direction] = frames
	walks = pending_walks
	idles = pending_idles
	ready = true
	return true

func actor(direction: String, flip: bool, elapsed_ms: float, moving: bool) -> Dictionary:
	var key := "side" if direction == "left" else direction
	if not ready or not walks.has(key):
		return {}
	var frames: Array = walks[key]
	var index := Metrics.frame_at(elapsed_ms)
	return {
		"texture": frames[index] if moving else idles[key],
		"flip_h": direction == "left" or (key == "side" and flip),
		"direction": direction,
		"motion_frame": index if moving else -1,
		"frame_count": WALK_FRAMES,
		"animation": "shared_player_walk",
		"angle": 0.0,
	}

func sample(facing: String, flip: bool, turn: Dictionary, elapsed_seconds: float) -> Dictionary:
	var pose := Facing.turn_pose(turn) if not turn.is_empty() else {"facing": facing, "flip": flip}
	return actor(pose.facing, pose.flip, elapsed_seconds * 1000.0, elapsed_seconds > 0.0 and turn.is_empty())

static func advance_clock(elapsed: float, motion: Vector2, delta: float) -> float:
	return elapsed + maxf(0.0, delta) if motion.is_finite() and not motion.is_zero_approx() else 0.0
