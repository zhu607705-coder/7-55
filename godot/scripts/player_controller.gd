extends CharacterBody2D

signal position_changed(world_position: Vector2)
signal navigation_finished()
signal navigation_cancelled()

const FRAME_COUNT := 4
const DISPLAY_SCALE := 0.325
const WALK_FPS := 11.0
const PATH_TOLERANCE := 10.0

@export var walk_speed := 150.0
@export var run_speed := 220.0

var world_size := Vector2(4516.0, 3420.0)
var input_enabled := true
var _virtual_direction := Vector2.ZERO
var _sprite: AnimatedSprite2D
var _facing := "down"
var _last_emitted_position := Vector2.INF
var _movement_validator := Callable()
var _navigation_path := PackedVector2Array()
var _navigation_index := 0


func _ready() -> void:
	_build_sprite()
	_build_collision()


func configure(next_world_size: Vector2, spawn_position: Vector2, movement_validator: Callable = Callable()) -> void:
	world_size = next_world_size
	global_position = spawn_position
	_movement_validator = movement_validator
	_last_emitted_position = Vector2.INF
	clear_navigation_path(false)


func set_movement_validator(validator: Callable) -> void:
	_movement_validator = validator


func set_input_enabled(enabled: bool) -> void:
	input_enabled = enabled
	if not enabled:
		velocity = Vector2.ZERO
		_virtual_direction = Vector2.ZERO


func set_virtual_direction(direction: Vector2) -> void:
	_virtual_direction = direction.limit_length(1.0)


func set_navigation_path(points: PackedVector2Array) -> bool:
	if points.is_empty():
		clear_navigation_path(false)
		return false
	_navigation_path = points
	_navigation_index = 0
	while _navigation_index < _navigation_path.size() and global_position.distance_to(_navigation_path[_navigation_index]) <= PATH_TOLERANCE:
		_navigation_index += 1
	if _navigation_index >= _navigation_path.size():
		clear_navigation_path(false)
		navigation_finished.emit()
		return true
	return true


func clear_navigation_path(emit_cancelled: bool = true) -> void:
	var had_path := is_following_path()
	_navigation_path = PackedVector2Array()
	_navigation_index = 0
	if had_path and emit_cancelled:
		navigation_cancelled.emit()


func is_following_path() -> bool:
	return _navigation_index < _navigation_path.size()


func navigation_path_size() -> int:
	return _navigation_path.size()


func navigation_path() -> PackedVector2Array:
	return _navigation_path.duplicate()


func _physics_process(delta: float) -> void:
	var manual_direction := Vector2.ZERO
	if input_enabled:
		manual_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		manual_direction = (manual_direction + _virtual_direction).limit_length(1.0)
	if manual_direction.length_squared() > 0.0001 and is_following_path():
		clear_navigation_path()

	var direction := manual_direction
	if input_enabled and direction.length_squared() <= 0.0001 and is_following_path():
		direction = _navigation_direction()
	var speed := run_speed if Input.is_action_pressed("move_run") else walk_speed
	var previous_position := global_position
	_try_move(direction * speed * delta)
	velocity = (global_position - previous_position) / maxf(delta, 0.0001)
	_update_animation(direction if velocity.length_squared() > 0.01 else Vector2.ZERO)
	z_index = clampi(roundi(global_position.y + 30.0), RenderingServer.CANVAS_ITEM_Z_MIN, RenderingServer.CANVAS_ITEM_Z_MAX)
	if global_position.distance_squared_to(_last_emitted_position) >= 1.0:
		_last_emitted_position = global_position
		position_changed.emit(global_position)


func _navigation_direction() -> Vector2:
	while _navigation_index < _navigation_path.size():
		var target := _navigation_path[_navigation_index]
		if global_position.distance_to(target) > PATH_TOLERANCE:
			return global_position.direction_to(target)
		_navigation_index += 1
	if not _navigation_path.is_empty():
		_navigation_path = PackedVector2Array()
		_navigation_index = 0
		navigation_finished.emit()
	return Vector2.ZERO


func _try_move(delta_position: Vector2) -> void:
	if delta_position.length_squared() <= 0.000001:
		return
	var target := _clamp_to_world(global_position + delta_position)
	if _can_stand_at(target):
		global_position = target
		return
	var horizontal := _clamp_to_world(global_position + Vector2(delta_position.x, 0.0))
	if absf(delta_position.x) > 0.0001 and _can_stand_at(horizontal):
		global_position = horizontal
		return
	var vertical := _clamp_to_world(global_position + Vector2(0.0, delta_position.y))
	if absf(delta_position.y) > 0.0001 and _can_stand_at(vertical):
		global_position = vertical


func _can_stand_at(point: Vector2) -> bool:
	if not _movement_validator.is_valid():
		return true
	return bool(_movement_validator.call(point.x, point.y))


func _clamp_to_world(point: Vector2) -> Vector2:
	return Vector2(
		clampf(point.x, 0.0, world_size.x),
		clampf(point.y, 0.0, world_size.y)
	)


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
