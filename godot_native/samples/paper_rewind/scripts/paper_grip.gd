extends Control
## A generous hit surface attached to the actual paper (or its last visible trace).
signal pressed_at(screen_point: Vector2)
signal dragged_to(screen_point: Vector2)
signal released(cancelled: bool)
signal nudged(seconds: float)
signal activated
var held := false
var touch_held := false

func _ready() -> void:
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_DRAG
	accessibility_name = "纸张。按住后沿飞行轨迹往回拖；松手继续。落稳后点击收起。"
	tooltip_text = "纸张"

func _draw() -> void:
	# Keyboard focus gets a small open underline, not another enclosing frame.
	if has_focus() and not held and not touch_held:
		var p := size*0.5+Vector2(0,28)
		draw_line(p-Vector2(12,0),p+Vector2(12,0),Color("eee0b6"),2,true)

func _gui_input(event: InputEvent) -> void:
	if touch_held and (event is InputEventMouseButton or event is InputEventMouseMotion):
		accept_event()
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			held = true
			grab_focus()
			pressed_at.emit(event.global_position)
		elif held:
			held = false
			released.emit(not get_viewport_rect().has_point(event.global_position))
		accept_event()
	elif event is InputEventMouseMotion and held:
		dragged_to.emit(event.global_position)
		accept_event()
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_LEFT: nudged.emit(-0.5)
			KEY_RIGHT: nudged.emit(0.5)
			KEY_ENTER, KEY_SPACE: activated.emit()
			_: return
		accept_event()

func cancel_grip() -> void:
	if held:
		held = false
		touch_held = false
		released.emit(true)

func begin_touch(point: Vector2) -> void:
	held = true
	touch_held = true
	grab_focus()
	pressed_at.emit(point)

func move_touch(point: Vector2) -> void:
	if touch_held:
		dragged_to.emit(point)

func end_touch(cancelled: bool) -> void:
	if touch_held:
		held = false
		touch_held = false
		released.emit(cancelled)
