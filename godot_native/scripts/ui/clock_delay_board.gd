extends Control
## The visible delay circuit previews a whole drag; only release submits a draft.
signal edited(channel:String,value:int)
const Model=preload("res://scripts/games/chapter4_clock_chain.gd")
const Type=preload("res://scripts/ui/native_typography.gd")
const CHANNELS=["dial","movement","phone"]
const INK=Color("34463c")
const BRASS=Color("ac8247")
var run_id:="1225_bakery"
var trims:Dictionary={}
var selected:=0
var pointer:=-99
var start:=Vector2.ZERO
var initial:=0
var moved:=false
var last_touch:=-1000
func _ready()->void:
	mouse_filter=Control.MOUSE_FILTER_STOP;focus_mode=Control.FOCUS_ALL
	resized.connect(cancel);visibility_changed.connect(cancel)
func scale_factor()->float:return size.x/382.0
func knob(index:int)->Vector2:return Vector2(65+126*index,254)*scale_factor()
func cancel()->void:
	if pointer!=-99:trims[CHANNELS[selected]]=initial
	pointer=-99;moved=false;queue_redraw()
func _notification(what:int)->void:
	if what==NOTIFICATION_WM_WINDOW_FOCUS_OUT:cancel()
func down(id:int,at:Vector2)->void:
	if pointer!=-99:return
	for index:int in 3:
		if at.distance_to(knob(index))<=maxf(24,34*scale_factor()):
			selected=index;pointer=id;start=at;initial=int(trims.get(CHANNELS[index],0));moved=false;grab_focus();queue_redraw();return
func motion(at:Vector2)->void:
	if pointer==-99:return
	var delta:float=(at.x-start.x)/maxf(.01,scale_factor())
	if absf(delta)>=6:moved=true
	trims[CHANNELS[selected]]=clampi(initial+roundi(delta/4),-45,45);queue_redraw()
func up(id:int,at:Vector2,canceled:bool=false)->void:
	if pointer!=id:return
	if canceled:trims[CHANNELS[selected]]=initial;cancel();return
	if not moved:trims[CHANNELS[selected]]=clampi(initial+(-1 if at.x<knob(selected).x else 1),-45,45)
	var value:int=int(trims[CHANNELS[selected]])
	pointer=-99;moved=false;queue_redraw();edited.emit(CHANNELS[selected],value)
func _gui_input(event:InputEvent)->void:
	if event is InputEventScreenTouch:
		last_touch=Time.get_ticks_msec()
		if event.pressed:down(event.index,event.position)
		else:up(event.index,event.position,event.canceled)
		accept_event()
	elif event is InputEventScreenDrag and pointer==event.index:motion(event.position);accept_event()
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and Time.get_ticks_msec()-last_touch>650:
		if event.pressed:down(-1,event.position)
		else:up(-1,event.position)
		accept_event()
	elif event is InputEventMouseMotion and pointer==-1:motion(event.position);accept_event()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_UP,KEY_DOWN]:selected=posmod(selected+(1 if event.keycode==KEY_DOWN else -1),3);queue_redraw();accept_event()
		elif event.keycode in [KEY_LEFT,KEY_RIGHT]:
			var value:int=clampi(int(trims.get(CHANNELS[selected],0))+(1 if event.keycode==KEY_RIGHT else -1),-45,45)
			edited.emit(CHANNELS[selected],value);accept_event()
func words(at:Vector2,text:String,points:int=17)->void:draw_string(Type.body_font(),at,text,HORIZONTAL_ALIGNMENT_LEFT,-1,points,INK)
func _draw()->void:
	draw_set_transform(Vector2.ZERO,0,Vector2.ONE*scale_factor())
	draw_rect(Rect2(0,0,382,322),Color("f3eddd"));words(Vector2(14,25),"延迟轮接线底板",19)
	var offsets:Array=Model.residuals(run_id,trims)
	for index:int in 3:
		var y:float=60+index*49
		words(Vector2(12,y),["钟面","机芯","接收"][index])
		draw_line(Vector2(76,y+8),Vector2(365,y+8),Color("b2b5a7"),1)
		draw_dashed_line(Vector2(210,y-22),Vector2(210,y+12),Color("b16a51"),1,3)
		var x:float=210+float(offsets[index])*1.6
		draw_polyline(PackedVector2Array([Vector2(76,y+8),Vector2(x,y+8),Vector2(x,y-10),Vector2(x+8,y-10),Vector2(x+8,y+8),Vector2(365,y+8)]),INK,2)
		words(Vector2(298,y-14),"%+d 秒"%int(offsets[index]),15)
	# The branching wires are clues, not a list of correct corrections.
	for wire:Array in [[0,0],[0,1],[1,1],[1,2],[2,2]]:
		var x:float=65+126*int(wire[0]);var target:float=65+126*int(wire[1])
		draw_polyline(PackedVector2Array([Vector2(x,221),Vector2(x,203-int(wire[0])*7),Vector2(target,203-int(wire[0])*7),Vector2(target,179)]),BRASS,2)
	for index:int in 3:
		words(Vector2(43+126*index,183),["钟面","机芯","接收"][index],13)
		var at:=Vector2(65+126*index,254);var value:int=int(trims.get(CHANNELS[index],0))
		draw_circle(at,30,Color("d3c5a4"));draw_arc(at,30,0,TAU,40,BRASS,2)
		var direction:=Vector2.from_angle(value*PI/12-PI/2);draw_line(at,at+direction*23,INK,3)
		words(at+Vector2(-24,54),"%+d"%value,20)
		if has_focus() and selected==index:draw_arc(at,34,0,TAU,40,INK,1)
	draw_set_transform(Vector2.ZERO)
