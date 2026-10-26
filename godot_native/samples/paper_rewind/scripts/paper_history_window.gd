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

func _ready() -> void:
	clip_contents = true
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_MOVE
	accessibility_name = "过去的观察窗，只读。拖动或用方向键移动。"
	tooltip_text = "拖动观察窗；焦点在窗上时，用方向键移动"

func _draw() -> void:
	if paint_record.is_valid(): paint_record.call(self)
	draw_rect(Rect2(Vector2.ZERO,size),Color(0.13,0.36,0.43,0.22))
	for y: int in range(0,int(size.y),5): draw_line(Vector2(0,y),Vector2(size.x,y),Color(0.70,0.88,0.85,0.04),1)
	draw_rect(Rect2(Vector2.ONE*3,size-Vector2.ONE*6),Color("263f46"),false,6)
	draw_rect(Rect2(Vector2.ONE*2,size-Vector2.ONE*4),Color("a8c9bd"),false,1.5)
	# An etched clock and backward tick distinguish the recorded layer without a label.
	draw_arc(Vector2(18,18),8,0,TAU,24,Color("c0d7cc"),1.5,true)
	draw_line(Vector2(18,18),Vector2(18,12),Color("c0d7cc"),1.5)
	draw_line(Vector2(18,18),Vector2(13,20),Color("c0d7cc"),1.5)

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
