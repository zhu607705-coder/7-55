extends CharacterBody2D

signal position_changed(world_position: Vector2)

const FRAME_COUNT := 4
const DISPLAY_SCALE := 0.325
const WALK_FPS := 11.0

@export var walk_speed := 150.0
@export var run_speed := 220.0

var world_size := Vector2(4516.0, 3420.0)
var input_enabled := true
var _virtual_direction := Vector2.ZERO
var _sprite: AnimatedSprite2D
var _facing := "down"
var _last_emitted_position := Vector2.INF


func _ready() -> void:
	_build_sprite()
	_build_collision()


func configure(next_world_size: Vector2, spawn_position: Vector2) -> void:
	world_size = next_world_size
	global_position = spawn_position
	_last_emitted_position = Vector2.INF


func set_input_enabled(enabled: bool) -> void:
	input_enabled = enabled
	if not enabled:
		velocity = Vector2.ZERO
		_virtual_direction = Vector2.ZERO


func set_virtual_direction(direction: Vector2) -> void:
	_virtual_direction = direction.limit_length(1.0)


func _physics_process(_delta: float) -> void:
	var direction := Vector2.ZERO
	if input_enabled:
		direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		direction = (direction + _virtual_direction).limit_length(1.0)
	var speed := run_speed if Input.is_action_pressed("move_run") else walk_speed
	velocity = direction * speed
	move_and_slide()
	global_position = Vector2(
		clamp(global_position.x, 0.0, world_size.x),
		clamp(global_position.y, 0.0, world_size.y)
	)
	_update_animation(direction)
	if global_position.distance_squared_to(_last_emitted_position) >= 1.0:
		_last_emitted_position = global_position
		position_changed.emit(global_position)


func _build_sprite() -> void:
	_sprite = AnimatedSprite2D.new()
	_sprite.name = "AnimatedSprite2D"
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.scale = Vector2.ONE * DISPLAY_SCALE
	_sprite.position = Vector2(0.0, -20.8)
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for direction in ["down", "up", "side"]:
		frames.add_animation(direction)
		frames.set_animation_loop(direction, true)
		frames.set_animation_speed(direction, WALK_FPS)
		for frame_index in range(FRAME_COUNT):
			var path := "res://assets/generated/rpg/player/player_%s_%d.png" % [direction, frame_index]
			var texture := load(path) as Texture2D
			if texture != null:
				frames.add_frame(direction, texture)
	_sprite.sprite_frames = frames
	_sprite.animation = "down"
	_sprite.play()
	add_child(_sprite)


func _build_collision() -> void:
	var collision := CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	var shape := RectangleShape2D.new()
	shape.size = Vector2(20.0, 12.0)
	collision.shape = shape
	collision.position = Vector2(0.0, -6.0)
	add_child(collision)


func _update_animation(direction: Vector2) -> void:
	if direction.length_squared() <= 0.0001:
		_sprite.pause()
		_sprite.frame = 0
		return
	var next_facing := _facing
	var flip_h := false
	if abs(direction.x) > abs(direction.y):
		next_facing = "side"
		flip_h = direction.x < 0.0
	else:
		next_facing = "up" if direction.y < 0.0 else "down"
	_sprite.flip_h = flip_h
	if _sprite.animation != next_facing:
		_sprite.play(next_facing)
	elif not _sprite.is_playing():
		_sprite.play()
	_facing = next_facing
