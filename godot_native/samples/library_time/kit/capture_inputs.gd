extends RefCounted
## Acceptance/recording only. Events enter the ordinary engine input path.
## This helper cannot change a model, pick an answer or grant completion.
var last: Dictionary = {}
var mouse_position := Vector2.ZERO
var mouse_pressed := false

func touch(id: int, point: Vector2, pressed: bool, canceled: bool = false) -> void:
	assert(id >= 0 and point.is_finite())
	var event := InputEventScreenTouch.new()
	event.index = id
	event.position = point
	event.pressed = pressed
	event.canceled = canceled
	Input.parse_input_event(event)
	if pressed and not canceled:
		last[id] = point
	else:
		last.erase(id)

func drag(id: int, point: Vector2) -> void:
	assert(id >= 0 and point.is_finite())
	assert(last.has(id), "Drag requires a preceding touch down")
	var event := InputEventScreenDrag.new()
	event.index = id
	event.position = point
	event.relative = point - Vector2(last[id])
	Input.parse_input_event(event)
	last[id] = point

func mouse_button(point: Vector2, pressed: bool) -> void:
	assert(point.is_finite())
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = point
	event.global_position = point
	event.pressed = pressed
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	Input.parse_input_event(event)
	mouse_position = point
	mouse_pressed = pressed

func mouse_move(point: Vector2) -> void:
	assert(point.is_finite())
	var event := InputEventMouseMotion.new()
	event.position = point
	event.global_position = point
	event.relative = point - mouse_position
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if mouse_pressed else 0
	Input.parse_input_event(event)
	mouse_position = point
