extends Control
## Image-led native press. Controller authority and pointer ownership stay here.
signal press_event_requested(event:Dictionary)
signal press_requested
signal motion_finished
const Model=preload("res://scripts/objects/room201_press_model.gd")
const Art=preload("res://scripts/objects/room201_press_art.gd")
const CONTACTS=[Vector2(0,-66),Vector2(-76,30),Vector2(75,30)]
var art:Node2D
var checkpoint:Dictionary=Model.initial()
var touch_mode:=false
var plate_available:=true
var interactive:=true
var reduced:=false
var completed:=false
var motion:=""
var motion_time:=0.0
var press_outcome:=""
var displayed_stage:="insert"
var old_calibration:Dictionary={"horizontal":0,"vertical":0,"pressure":0}
var dent:=false
var fit:=1.0
var origin:=Vector2.ZERO
var play_area:=Rect2()
var design_size:=Vector2(1536,1024)
var center:=Vector2(630,488)
var wheel:=Vector2(1173,450)
var lever_pivot:=Vector2(936,116)
var loose_center:=Vector2(1367,766)
var plate_size:=Vector2(239,205)*.98
var narrow:=false
var dragging:=false
var pointer_kind:=""
var pointer_index:=-1
var pointer_device:=0
var gesture:=""
var drag_start:=Vector2.ZERO
var drag_current:=Vector2.ZERO
var last_touch_at:=-10000
var crank_angle:=0.0
func _ready()->void:
	mouse_filter=Control.MOUSE_FILTER_STOP
	art=Art.new();art.view=self;add_child(art)
	resized.connect(_layout);_layout()
func layout_scene(rect:Rect2)->void:
	if play_area!=rect:cancel_gesture()
	play_area=rect;_layout()
func _layout()->void:
	if not play_area.has_area():play_area=Rect2(Vector2.ZERO,size)
	narrow=size.y>size.x
	design_size=Vector2(750,1320) if narrow else Vector2(1536,1024)
	center=Vector2(350,580) if narrow else Vector2(630,488)
	wheel=Vector2(566,1110) if narrow else Vector2(1173,450)
	lever_pivot=Vector2(470,150) if narrow else Vector2(936,116)
	loose_center=Vector2(180,1140) if narrow else Vector2(1367,766)
	plate_size=Vector2(239,205)*sheet_art_scale()
	fit=minf(play_area.size.x/design_size.x,play_area.size.y/design_size.y)
	origin=play_area.position+(play_area.size-design_size*fit)/2
	queue_redraw()
func present(value:Dictionary,already_recorded:bool,event:Dictionary={},reduce_motion:=false)->void:
	var previous:Dictionary=checkpoint.duplicate(true)
	checkpoint=value.duplicate(true);completed=already_recorded;reduced=reduce_motion
	displayed_stage=Model.stage(checkpoint,completed)
	if motion=="press":queue_redraw();return
	if previous!=checkpoint and not reduced and str(event.get("kind","")) in ["insert","step","reset"]:
		motion=str(event.kind);motion_time=0;old_calibration=previous.calibration.duplicate()
	else:motion=""
	queue_redraw()
func begin_press()->void:
	cancel_gesture();motion="press";motion_time=0;press_outcome="";queue_redraw()
func show_feedback(kind:String)->void:
	if kind in ["success","imprint","imprinted","calibrated","press_success"]:
		press_outcome="success";dent=false
		if motion!="press":motion="press";motion_time=0
	elif kind in ["bounce","rebound","hiccup","wrong","press_bounce"]:
		press_outcome="bounce";dent=true
		if motion!="press":motion="press";motion_time=0
	queue_redraw()
func _process(delta:float)->void:
	if not motion.is_empty():
		motion_time+=minf(maxf(delta,0),.06)
		var duration:float=.3 if reduced else (.48 if motion=="insert" else .24)
		if motion=="press":duration=.24 if reduced else 1.1
		if motion_time>=duration and (motion!="press" or not press_outcome.is_empty()):
			motion="";motion_finished.emit()
		queue_redraw()
func _press_depth()->float:
	if gesture=="lever":return clampf((drag_current.y-drag_start.y)/(75*fit),0,.62)
	if motion!="press":return 0
	if reduced:return 1 if motion_time<.12 else 0
	if motion_time<.34:return smoothstep(0,.34,motion_time)
	if motion_time<.51:return 1
	return 1-smoothstep(.51,.98,motion_time)
func _visual_calibration()->Vector3:
	var target:=Vector3(float(checkpoint.calibration.horizontal),float(checkpoint.calibration.vertical),float(checkpoint.calibration.pressure))
	if motion in ["step","reset"]:
		var old:=Vector3(float(old_calibration.horizontal),float(old_calibration.vertical),float(old_calibration.pressure))
		return old.lerp(target,smoothstep(0,.24,motion_time))
	return target
func carriage_art_scale()->float:return 1.08 if narrow else .85
func sheet_art_scale()->float:return 1.25 if narrow else .98
func lever_art_scale()->float:return .46 if narrow else 1.0
func carriage_center()->Vector2:
	var a:=_visual_calibration()
	var at:=center+Vector2(a.x,a.y)*22
	if gesture=="carriage":
		var offset:Vector2=(drag_current-drag_start)/maxf(.01,fit)
		at+=Vector2(clampf(offset.x,-12,12),clampf(offset.y,-12,12))
	return at
func carriage_rect()->Rect2:return Rect2(carriage_center()-plate_size/2,plate_size)
func loose_plate_rect()->Rect2:return Rect2(loose_center-plate_size/2,plate_size)
func slot_rect()->Rect2:return Rect2(center-Vector2(155,140),Vector2(310,280))
func rail_handles()->Array:
	var a:=_visual_calibration()
	return [{"point":Vector2(674,580)+Vector2(a.x*9,0) if narrow else Vector2(262,477)+Vector2(a.x*9,0),"axis":"horizontal"},{"point":Vector2(350,941)+Vector2(0,a.y*9) if narrow else Vector2(620,886)+Vector2(0,a.y*9),"axis":"vertical"}]
func lever_handle()->Vector2:
	return lever_pivot+Vector2(476,119).rotated(_press_depth()*.79)*lever_art_scale()
func ram_center()->Vector2:
	var idle:Vector2=lever_pivot+Vector2(-145,250)*(.90 if narrow else 1.0)
	return idle.lerp(center+Vector2(-44,11 if narrow else 15),_press_depth())
func cancel_gesture()->void:
	dragging=false;pointer_kind="";pointer_index=-1;pointer_device=0;gesture="";drag_current=Vector2.ZERO;queue_redraw()
func _notification(what:int)->void:
	if what==NOTIFICATION_WM_WINDOW_FOCUS_OUT or what==NOTIFICATION_EXIT_TREE or (what==NOTIFICATION_VISIBILITY_CHANGED and not is_visible_in_tree()):cancel_gesture()
func _owned_pointer(kind:String,index:int,pressed:bool,point:Vector2,canceled:=false,device:=0)->bool:
	if canceled:
		if pointer_kind==kind and pointer_index==index and pointer_device==device:cancel_gesture();return true
		return false
	if pressed:
		if not pointer_kind.is_empty():return false
		if not _pointer_down(point):return false
		pointer_kind=kind;pointer_index=index;pointer_device=device;return true
	if pointer_kind!=kind or pointer_index!=index or pointer_device!=device:return false
	_pointer_up(point);cancel_gesture();return true
func _near(point:Vector2,target:Vector2,radius:=23.0)->bool:return point.distance_to(origin+target*fit)<=maxf(24,radius*fit)
func _pointer_down(point:Vector2)->bool:
	if not interactive or not motion.is_empty() or fit<=0:return false
	var source:Vector2=(point-origin)/fit
	var next:=""
	if not checkpoint.inserted:
		if plate_available and loose_plate_rect().grow(8).has_point(source):next="plate"
	else:
		if _near(point,lever_handle(),25):next="lever"
		elif art!=null and art.pressure_wheel_contains(point):next="crank"
		else:
			for handle:Dictionary in rail_handles():
				if _near(point,handle.point,48):next=str(handle.axis);break
			if next.is_empty() and carriage_rect().grow(6).has_point(source):next="carriage"
	if next.is_empty():return false
	gesture=next;dragging=true;drag_start=point;drag_current=point
	crank_angle=((point-origin)/fit-wheel).angle();queue_redraw();return true
func _pointer_move(point:Vector2)->void:
	if not dragging:return
	drag_current=point;queue_redraw()
func _pointer_up(point:Vector2)->bool:
	if not dragging:return false
	var active:String=gesture
	var delta:Vector2=point-drag_start
	var source:Vector2=(point-origin)/maxf(.01,fit)
	# Clear presentation before dispatch. The authority callback may be synchronous.
	cancel_gesture()
	if not interactive or not motion.is_empty():return true
	if active=="plate":
		if delta.length()<16 or slot_rect().grow(18).has_point(source):press_event_requested.emit({"kind":"insert"})
	elif active=="lever":
		if delta.length()<16 or delta.y>=20:press_requested.emit()
	elif active=="crank":
		var turn:float=wrapf((source-wheel).angle()-crank_angle,-PI,PI)
		var amount:int=1 if turn>=0 else -1
		if delta.length()<16:amount=1 if source.x>=wheel.x else -1
		elif absf(turn)<.16:return true
		press_event_requested.emit({"kind":"step","axis":"pressure","delta":amount})
	elif active in ["carriage","horizontal","vertical"]:
		if delta.length()<18:
			# A rail grip is also a large two-sided touch control.
			if active=="carriage":return true
			var handles:Array=rail_handles()
			var handle:Vector2=handles[0].point if active=="horizontal" else handles[1].point
			var amount:int=1 if (source.x>=handle.x if active=="horizontal" else source.y>=handle.y) else -1
			press_event_requested.emit({"kind":"step","axis":active,"delta":amount});return true
		var axis:String=active if active!="carriage" else ("horizontal" if absf(delta.x)>=absf(delta.y) else "vertical")
		var amount:int=1 if (delta.x if axis=="horizontal" else delta.y)>0 else -1
		press_event_requested.emit({"kind":"step","axis":axis,"delta":amount})
	return true
func _gui_input(event:InputEvent)->void:
	if event is InputEventScreenTouch:
		last_touch_at=Time.get_ticks_msec()
		if _owned_pointer("touch",event.index,event.pressed,event.position,event.canceled,event.device):accept_event()
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		if event.device<0 and Time.get_ticks_msec()-last_touch_at<500:return
		if _owned_pointer("mouse",0,event.pressed,event.position,false,event.device):accept_event()
	elif event is InputEventScreenDrag and pointer_kind=="touch" and event.index==pointer_index and event.device==pointer_device:_pointer_move(event.position);accept_event()
	elif event is InputEventMouseMotion and pointer_kind=="mouse" and event.device==pointer_device:_pointer_move(event.position);accept_event()
func _draw()->void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("282622"))
