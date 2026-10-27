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
var paint_record: Callable
var record_canvas: Control
var frame_canvas: Control

func _ready() -> void:
	clip_contents = true
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_MOVE
	accessibility_name = "过去的观察窗，只读。拖动或用方向键移动。"
	tooltip_text = "拖动观察窗；焦点在窗上时，用方向键移动"
	# Control.clip_contents clips children, not this Control's own draw commands.
	# Keep recorded geometry in a real clipped child; no past pixel escapes.
	record_canvas = Control.new()
	record_canvas.name = "ClippedRecording"
	record_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	record_canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	record_canvas.draw.connect(func() -> void:
		if paint_record.is_valid(): paint_record.call(record_canvas))
	add_child(record_canvas)
	frame_canvas = Control.new()
	frame_canvas.name = "GlassRim"
	frame_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame_canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame_canvas.draw.connect(_draw_frame)
	add_child(frame_canvas)

func _draw() -> void:
	if record_canvas: record_canvas.queue_redraw()
	if frame_canvas: frame_canvas.queue_redraw()

func _draw_frame() -> void:
	# One functional edge separates the read-only layer; no nested decorative rim.
	var ink := Color("9db8c8")
	frame_canvas.draw_rect(Rect2(Vector2.ZERO,size),Color(0.20,0.32,0.42,0.14))
	frame_canvas.draw_rect(Rect2(Vector2.ONE,size-Vector2.ONE*2),ink,false,1.5)
	frame_canvas.draw_arc(Vector2(17,17),7,0,TAU,24,ink,1.5,true)
	frame_canvas.draw_line(Vector2(17,17),Vector2(17,12),ink,1.5)
	frame_canvas.draw_line(Vector2(17,17),Vector2(13,19),ink,1.5)

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
