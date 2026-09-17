extends CharacterBody2D
## Transient movement only. No progression, inventory or save access.
const ACTIONS: Array[String] = ["port_left", "port_right", "port_up", "port_down"]
var contract: Dictionary
var world_size: Vector2
var speed: float = 220.0 # Rehearsal speed; production movement parity is not claimed.
var visual: Sprite2D
var frames: Dictionary = {}
var facing: String = "down"
var elapsed: float = 0.0
var last_frame: String = ""
var foot_bottom_offset: float

func configure(data: Dictionary, bounds: Vector2) -> void:
	contract = data
	world_size = bounds
	var scale_value: float = float(data.scale)
	var foot: Dictionary = data.foot
	foot_bottom_offset = (float(foot.offsetY) + float(foot.height) - float(data.height) / 2.0) * scale_value
	var collider := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(float(foot.width), float(foot.height)) * scale_value
	collider.shape = shape
	collider.position = Vector2((float(foot.offsetX) + float(foot.width) / 2.0 - float(data.width) / 2.0) * scale_value, -shape.size.y / 2.0)
	add_child(collider)
	visual = Sprite2D.new()
	visual.scale = Vector2.ONE * scale_value
	visual.position.y = -foot_bottom_offset
	add_child(visual)
	for direction in ["down", "up", "side"]:
		for index in range(int(data.frameCount)):
			var key: String = "%s_%d" % [direction, index]
			frames[key] = load("res://generated/player_%s.png" % key)
	frames["side_idle"] = load("res://generated/player_side_idle.png")
	visual.texture = frames["down_0"]
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING

func _ready() -> void:
	var keys: Array = [[KEY_A, KEY_LEFT], [KEY_D, KEY_RIGHT], [KEY_W, KEY_UP], [KEY_S, KEY_DOWN]]
	for index in range(ACTIONS.size()):
		if InputMap.has_action(ACTIONS[index]):
			continue
		InputMap.add_action(ACTIONS[index])
		for key in keys[index]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(ACTIONS[index], event)

func reset_to_legacy_spawn(spawn: Dictionary) -> void:
	position = Vector2(float(spawn.x), float(spawn.y) + foot_bottom_offset)
	velocity = Vector2.ZERO
	elapsed = 0.0

func _physics_process(delta: float) -> void:
	if visual == null:
		return
	var direction := Input.get_vector(ACTIONS[0], ACTIONS[1], ACTIONS[2], ACTIONS[3])
	velocity = direction * speed
	move_and_slide()
	# Keep the full source frame inside the world, in addition to foot collisions.
	var half_size := Vector2(float(contract.width), float(contract.height)) * float(contract.scale) / 2.0
	position.x = clampf(position.x, half_size.x, world_size.x - half_size.x)
	position.y = clampf(position.y, half_size.y + foot_bottom_offset, world_size.y - half_size.y + foot_bottom_offset)
	if direction.length_squared() > 0.0:
		elapsed += delta
		if absf(direction.x) > absf(direction.y):
			facing = "side"
			visual.flip_h = direction.x < 0.0
		else:
			facing = "up" if direction.y < 0.0 else "down"
			visual.flip_h = false
	else:
		elapsed = 0.0
	var frame_index: int = int(elapsed * 1000.0 / float(contract.frameMs)) % int(contract.frameCount)
	var key: String = "side_idle" if direction == Vector2.ZERO and facing == "side" else "%s_%d" % [facing, frame_index]
	if key != last_frame:
		visual.texture = frames[key]
		last_frame = key

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		for action in ACTIONS:
			Input.action_release(action)
		velocity = Vector2.ZERO
