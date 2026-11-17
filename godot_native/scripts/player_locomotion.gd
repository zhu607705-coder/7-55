extends RefCounted
## Per-actor presentation state. The caller supplies displacement after collision.
const Facing := preload("res://scripts/character_facing.gd")
const WalkArt := preload("res://scripts/player_walk_art.gd")

var facing := "down"
var flipped := false
var turn: Dictionary = {}
var elapsed := 0.0
var art := WalkArt.shared()

func advance(motion: Vector2, intent: Vector2, delta: float, face_intent := false, stride_rate := 1.0) -> void:
	var pose := Facing.pose(intent if face_intent else motion, intent, facing, flipped)
	Facing.advance_turn(turn, facing, flipped, pose, delta)
	facing = pose.facing
	flipped = pose.flip
	elapsed = WalkArt.advance_clock(elapsed, motion, delta * stride_rate)

func stop() -> void:
	elapsed = 0.0
	turn.clear()

func active_turn() -> Dictionary:
	if turn.is_empty() or turn.to_facing != facing or (facing == "side" and turn.to_flip != flipped):
		return {}
	return turn

func sample() -> Dictionary:
	return art.sample(facing, flipped, active_turn(), elapsed)

func apply_to_sprite(sprite: Sprite2D) -> void:
	if not art.ensure_loaded():
		return
	var visual := sample()
	sprite.texture = visual.texture
	sprite.flip_h = visual.flip_h
	sprite.rotation_degrees = float(visual.angle)
