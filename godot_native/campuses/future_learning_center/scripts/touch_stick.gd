extends Control
## A single pointer owns the analog stick until release/cancel; no four-button D-pad.
signal moved(value: Vector2)
const CENTER := Vector2(78,78)
const RADIUS := 52.0
var pointer_owner := -2
var value := Vector2.ZERO

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	visibility_changed.connect(func()->void: if not is_visible_in_tree(): cancel())

func cancel() -> void:
	pointer_owner=-2; value=Vector2.ZERO; moved.emit(value); queue_redraw()

func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_APPLICATION_PAUSED]: cancel()

func _local(at:Vector2)->Vector2:return get_global_transform_with_canvas().affine_inverse()*at
func _input(event: InputEvent) -> void:
	if not is_visible_in_tree(): return
	if event is InputEventMouse and event.device==InputEvent.DEVICE_ID_EMULATION:return
	var handled:=false
	if event is InputEventScreenTouch:
		var at: Vector2=_local(event.position)
		if event.canceled and event.index==pointer_owner:cancel();handled=true
		elif event.pressed and not event.canceled and pointer_owner==-2 and at.distance_to(CENTER)<RADIUS+12:
			pointer_owner=event.index; _move(at); handled=true
		elif not event.pressed and pointer_owner==event.index: cancel(); handled=true
	elif event is InputEventScreenDrag and event.index==pointer_owner:
		_move(_local(event.position)); handled=true
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		var at: Vector2=_local(event.position)
		if event.pressed and pointer_owner==-2 and at.distance_to(CENTER)<RADIUS+12:
			pointer_owner=-1; _move(at); handled=true
		elif not event.pressed and pointer_owner==-1: cancel(); handled=true
	elif event is InputEventMouseMotion and pointer_owner==-1:
		_move(_local(event.position)); handled=true
	if handled: get_viewport().set_input_as_handled()

func _move(at: Vector2) -> void:
	var displacement: Vector2=((at-CENTER)/RADIUS).limit_length()
	value=Vector2.ZERO if displacement.length()<.16 else displacement
	moved.emit(value); queue_redraw()

func _draw() -> void:
	draw_circle(CENTER,RADIUS+7,Color(.07,.11,.14,.5))
	draw_arc(CENTER,RADIUS,0,TAU,48,Color(.72,.8,.81,.8),3)
	var knob: Vector2=CENTER+value*RADIUS
	draw_circle(knob+Vector2(0,3),23,Color(.07,.11,.14,.55))
	draw_circle(knob,22,Color(.55,.66,.71,.9))
	draw_arc(knob,21,PI,TAU,24,Color("e8e0c8"),2)
