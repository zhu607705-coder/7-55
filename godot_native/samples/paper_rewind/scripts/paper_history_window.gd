extends Control
## A movable read-only view of recorded motion. It never owns a physical paper.
signal moved(screen_delta: Vector2)

const Model = preload("res://scripts/paper_rewind_model.gd")
const PAPER = preload("res://assets/paper.png")
var record_time := 0.0
var world_rect := Rect2(580, 40, 330, 190)
var world_scale := 1.0
var reduced_motion := false
var _dragging := false

func _ready() -> void:
	clip_contents = true
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_MOVE
	accessibility_name = "过去的观察窗，只读。拖动或用方向键移动。"
	tooltip_text = "拖动观察窗；焦点在窗上时，用方向键移动"

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("344f62"))
	# A faded old desktop, seen through the window rather than moved with it.
	var table := Rect2(Vector2(70, 286) - world_rect.position, Vector2(806, 176))
	draw_rect(Rect2(table.position * world_scale, table.size * world_scale), Color("536574"))
	var old_folder := Rect2((Vector2(485, 279) - world_rect.position) * world_scale, Vector2(230, 69) * world_scale)
	draw_rect(old_folder, Color("7e8988"))
	var point: Vector2 = (Model.free_position(record_time) - world_rect.position) * world_scale
	draw_texture_rect(PAPER, Rect2(point - Vector2(24, 29) * world_scale, Vector2(48, 58) * world_scale), false, Color(0.65, 0.85, 1.0, 0.75))
	if not reduced_motion:
		for index: int in range(5):
			var p := Vector2(125 + index * 85.0, 185 + index * 12.0)
			draw_line((p - world_rect.position) * world_scale, (p + Vector2(46, 0) - world_rect.position) * world_scale, Color("91b7c7"), 1.5)
	draw_rect(Rect2(0, 0, size.x, 26), Color("203644"))
	draw_string(get_theme_default_font(), Vector2(8, 19), "过去 · 只读", HORIZONTAL_ALIGNMENT_LEFT, size.x - 16, 16, Color("d4e9e6"))
	draw_rect(Rect2(Vector2.ONE, size - Vector2.ONE * 2), Color("c1e0d9") if has_focus() else Color("7fa8b9"), false, 2)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_dragging = event.pressed
		if event.pressed:
			grab_focus()
		accept_event()
	elif event is InputEventMouseMotion and _dragging:
		moved.emit(event.relative)
		accept_event()
	elif event is InputEventKey and event.pressed and not event.echo:
		var delta := Vector2.ZERO
		match event.keycode:
			KEY_LEFT: delta.x = -32
			KEY_RIGHT: delta.x = 32
			KEY_UP: delta.y = -32
			KEY_DOWN: delta.y = 32
			_: return
		moved.emit(delta)
		accept_event()

func cancel_drag() -> void:
	_dragging = false
