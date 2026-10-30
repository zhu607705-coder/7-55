extends Control
## One captured touch drives an analog stick; other fingers remain available.
signal changed(value:Vector2)
var pointer_id:=-1
var value:=Vector2.ZERO
const CENTER:=Vector2(70,70)
const RADIUS:=52.0
func _ready()->void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	size=Vector2(140,140)
func release()->void:
	pointer_id=-1;value=Vector2.ZERO;changed.emit(value);queue_redraw()
func _notification(what:int)->void:
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_APPLICATION_PAUSED]:release()
func _input(event:InputEvent)->void:
	if not is_visible_in_tree():return
	if event is InputEventScreenTouch:
		var at:Vector2=get_global_transform().affine_inverse()*event.position
		if event.pressed and pointer_id<0 and at.distance_to(CENTER)<=RADIUS+12:
			pointer_id=event.index;_move(at);get_viewport().set_input_as_handled()
		elif event.index==pointer_id and (not event.pressed or event.canceled):
			release();get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and event.index==pointer_id:
		_move(get_global_transform().affine_inverse()*event.position);get_viewport().set_input_as_handled()
func _move(at:Vector2)->void:
	value=((at-CENTER)/RADIUS).limit_length()
	if value.length()<.12:value=Vector2.ZERO
	changed.emit(value);queue_redraw()
func _draw()->void:
	draw_circle(CENTER,RADIUS,Color(.12,.16,.18,.32))
	draw_arc(CENTER,RADIUS,0,TAU,48,Color(.82,.84,.78,.6),2)
	draw_circle(CENTER+value*RADIUS*.65,23,Color(.76,.77,.68,.86))
	draw_arc(CENTER+value*RADIUS*.65,23,0,TAU,32,Color("344452"),2)
