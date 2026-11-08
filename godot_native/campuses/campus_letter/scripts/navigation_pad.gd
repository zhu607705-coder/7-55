extends Control
signal direction_changed(direction: Vector2)
var finger:int=-2
var value:=Vector2.ZERO
func _ready() -> void:
	custom_minimum_size=Vector2(132,132)
	mouse_default_cursor_shape=Control.CURSOR_DRAG
func _draw() -> void:
	var c:=size/2
	draw_circle(c,54,Color("22474a55"));draw_arc(c,54,0,TAU,64,Color("eff3e7aa"),2,true)
	draw_circle(c+value*38,21,Color("e5e8dcdd"));draw_circle(c+value*38,7,Color("446664"))
func reset() -> void:
	finger=-2;value=Vector2.ZERO;direction_changed.emit(value);queue_redraw()
func update_value(p:Vector2) -> void:
	value=((p-size/2)/38).limit_length(1);direction_changed.emit(value);queue_redraw()
func _gui_input(event:InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		if event.pressed and finger==-2:finger=-1;update_value(event.position)
		elif not event.pressed and finger==-1:reset()
		accept_event()
	elif event is InputEventMouseMotion and finger==-1:update_value(event.position);accept_event()
	elif event is InputEventScreenTouch:
		if event.pressed and finger==-2:finger=event.index;update_value(event.position)
		elif not event.pressed and finger==event.index:reset()
		accept_event()
	elif event is InputEventScreenDrag and event.index==finger:update_value(event.position);accept_event()
