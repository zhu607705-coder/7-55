extends Control
signal lamp_pressed(index:int)
signal motion_finished
signal studio_event_requested(event:Dictionary)
signal check_requested
const Shade=preload("res://scripts/objects/room302_shade_prop.gd")
const Scanner=preload("res://scripts/objects/room302_scanner_prop.gd")
const Model=preload("res://scripts/objects/room302_studio_model.gd")
var stage_root:Node2D
var projection:Control
var curtain:Sprite2D
var check_station:Node2D
var touch_mode:=false
var film_available:=true
var dragging:=false
var pointer_kind:=""
var pointer_index:=-1
var pointer_device:=0
var drag_start:=Vector2.ZERO
var last_touch_at:=-10000
var lamps:Array[Node2D]=[]
var checkpoint:Dictionary=Model.initial()
var displayed_stage:="wardrobe"
var selected:=-1
var interactive:=true
var reduced:=false
var motion:=""
var motion_time:=0.0
var motion_event:Dictionary={}
var old_hats:Array=[]
var old_alignment:Dictionary={}
var fit:=1.0
var origin:=Vector2.ZERO
var hiccup:=0.0
var lamp_positions:Array=[Vector2(105,376),Vector2(310,376),Vector2(515,376)]
var shadow_positions:Array=[Vector2(216,139),Vector2(310,139),Vector2(404,139)]
var design_size:=Vector2(620,410)
var play_area:=Rect2()
var curtain_width:=455.0
func _ready()->void:
	mouse_filter=Control.MOUSE_FILTER_STOP
	custom_minimum_size=Vector2(0,320)
	stage_root=Node2D.new();add_child(stage_root)
	curtain=Sprite2D.new();curtain.texture=load("res://assets/objectized/chapter4/room302/media-green-backdrop.png")
	curtain.region_enabled=true;curtain.region_rect=Rect2(127,80,1419,771);curtain.region_filter_clip_enabled=true
	curtain.scale=Vector2.ONE*(curtain_width/1419);curtain.position=Vector2(310,136);stage_root.add_child(curtain)
	for i in range(3):
		var lamp:Node2D=Shade.new();stage_root.add_child(lamp);lamp.position=lamp_positions[i]
		lamp.configure(load("res://assets/objectized/chapter4/room302/media-light-tripod.png"));lamps.append(lamp)
	check_station=Scanner.new();stage_root.add_child(check_station)
	check_station.configure("studio_check_scanner",{"path":"res://assets/objectized/chapter4/room302/alignment-scanner.png","trim":Rect2(80,156,1134,868),"width":130.0,"position":Vector2(770,428),"foot":Rect2()})
	resized.connect(_layout);_layout();_settle()
func layout_scene(rect:Rect2)->void:
	if play_area!=rect:cancel_gesture()
	play_area=rect;_layout()
func _layout()->void:
	if not play_area.has_area():play_area=Rect2(Vector2.ZERO,size)
	var narrow:bool=touch_mode and size.y>size.x
	design_size=Vector2(360,660) if narrow else Vector2(880,460)
	lamp_positions=[Vector2(65,500),Vector2(180,430),Vector2(295,500)] if narrow else [Vector2(140,376),Vector2(345,376),Vector2(550,376)]
	shadow_positions=[Vector2(104,144),Vector2(180,105),Vector2(256,144)] if narrow else [Vector2(251,139),Vector2(345,139),Vector2(439,139)]
	curtain_width=340 if narrow else 455
	fit=minf(play_area.size.x/design_size.x,play_area.size.y/design_size.y);origin=play_area.position+(play_area.size-design_size*fit)/2
	if stage_root!=null:
		stage_root.position=origin;stage_root.scale=Vector2.ONE*fit
		curtain.position=Vector2(180,142) if narrow else Vector2(345,136)
		curtain.scale=Vector2.ONE*(curtain_width/1419)
		for i in range(lamps.size()):lamps[i].position=lamp_positions[i]
		if check_station!=null:check_station.position=Vector2(180,642) if narrow else Vector2(770,428)
	queue_redraw()
func present(value:Dictionary,already_recorded:bool,event:Dictionary={},reduce_motion:=false)->void:
	var previous:Dictionary=checkpoint.duplicate(true)
	checkpoint=value.duplicate(true);reduced=reduce_motion
	var changed:bool=previous!=checkpoint
	if not reduced and changed and str(event.get("kind","")) in ["swap","step","reset_alignment"]:
		motion=str(event.kind);motion_event=event.duplicate();motion_time=0
		old_hats=previous.hats.duplicate();old_alignment=previous.alignment.duplicate()
		displayed_stage=Model.stage(previous,already_recorded)
	else:
		motion="";displayed_stage=Model.stage(checkpoint,already_recorded);_settle()
	queue_redraw()
func show_feedback(kind:String)->void:
	if kind=="hiccup" and not reduced:hiccup=.34
	queue_redraw()
func choose(index:int)->void:
	selected=index
	for i in range(lamps.size()):lamps[i].selected=i==selected;lamps[i].queue_redraw()
	queue_redraw()
func _settle()->void:
	for i in range(lamps.size()):lamps[i].hat_id=checkpoint.hats[i];lamps[i].settle();lamps[i].queue_redraw()
	if curtain!=null:curtain.scale=Vector2.ONE*(curtain_width/1419);curtain.rotation=0
	if check_station!=null:check_station.settle(film_available,displayed_stage=="recorded",checkpoint.alignment,reduced)
func _process(delta:float)->void:
	if hiccup>0:hiccup=maxf(0,hiccup-delta)
	if check_station!=null:
		check_station.synchronize(film_available,displayed_stage=="recorded",checkpoint.alignment,reduced);check_station.advance_feedback(delta)
	if not motion.is_empty():
		motion_time+=minf(maxf(0,delta),.06)
		var duration:=.42 if motion=="swap" else .3
		var t:=clampf(motion_time/duration,0,1)
		if motion=="swap":
			for i in range(lamps.size()):
				var lamp:Node2D=lamps[i];lamp.hat_id=old_hats[i];lamp.settle()
				if i==int(motion_event.a) or i==int(motion_event.b):
					var other:int=int(motion_event.b) if i==int(motion_event.a) else int(motion_event.a)
					var f:=smoothstep(0,1,t)
					lamp.cap.position=lamp.rest_position()+(lamp_positions[other]-lamp_positions[i])*f+Vector2(0,(-76 if i==int(motion_event.a) else -24)*sin(PI*t))
					lamp.cap.rotation=(.16 if i==int(motion_event.a) else -.16)*sin(PI*t)
				lamp.queue_redraw()
		else:
			curtain.scale=Vector2(curtain_width/1419,(curtain_width/1419)*(1-.17*sin(PI*t)))
			curtain.rotation=.025*sin(TAU*t) if str(motion_event.get("axis",""))=="rotationQuarterTurns" else 0
		if t>=1:
			motion="";displayed_stage=Model.stage(checkpoint,displayed_stage=="recorded");_settle();motion_finished.emit()
	queue_redraw()
	if projection!=null:projection.queue_redraw()
func curtain_rect()->Rect2:
	var h:float=curtain_width*771/1419
	return Rect2(curtain.position-Vector2(curtain_width,h)/2,Vector2(curtain_width,h))
func handle_definitions()->Array:
	if curtain==null:return []
	var rect:=curtain_rect()
	var left:=clampf(rect.position.x-12,16,design_size.x-16)
	var right:=clampf(rect.end.x+12,16,design_size.x-16)
	return [{"point":Vector2(left,rect.end.y-18),"axis":"xOffset","delta":-1,"mark":"left"},{"point":Vector2(right,rect.end.y-18),"axis":"xOffset","delta":1,"mark":"right"},{"point":Vector2(rect.get_center().x,rect.position.y+10),"axis":"yOffset","delta":-1,"mark":"up"},{"point":Vector2(rect.get_center().x,rect.end.y-12),"axis":"yOffset","delta":1,"mark":"down"},{"point":Vector2(rect.position.x+16,rect.position.y+10),"axis":"rotationQuarterTurns","delta":-1,"mark":"turn_left"},{"point":Vector2(rect.end.x-16,rect.position.y+10),"axis":"rotationQuarterTurns","delta":1,"mark":"turn_right"}]
func cancel_gesture()->void:
	dragging=false;pointer_kind="";pointer_index=-1;pointer_device=0
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
func _pointer_down(point:Vector2)->bool:
	if not interactive or not motion.is_empty() or fit<=0:return false
	var source:Vector2=(point-origin)/fit
	if check_station!=null and check_station.contains_source_point(source):check_requested.emit();return true
	if displayed_stage=="wardrobe":
		for i in range(3):
			var center:Vector2=origin+(lamp_positions[i]+Vector2(0,-110))*fit
			var hit:=Rect2(center-Vector2(maxf(28,68*fit),110*fit),Vector2(maxf(56,136*fit),maxf(56,220*fit)))
			if hit.has_point(point):lamp_pressed.emit(i);return true
	elif displayed_stage=="curtain":
		for handle:Dictionary in handle_definitions():
			if point.distance_to(origin+Vector2(handle.point)*fit)<=maxf(24,13*fit):
				studio_event_requested.emit({"kind":"step","axis":handle.axis,"delta":handle.delta});return true
		if curtain_rect().has_point(source):drag_start=point;dragging=true;return true
	return false
func _pointer_up(point:Vector2)->bool:
	if not dragging:return false
	dragging=false
	var delta:=point-drag_start
	if delta.length()<24:return true
	var axis:="xOffset" if absf(delta.x)>=absf(delta.y) else "yOffset"
	var amount:=1 if (delta.x if axis=="xOffset" else delta.y)>0 else -1
	if interactive and motion.is_empty():studio_event_requested.emit({"kind":"step","axis":axis,"delta":amount})
	return true
func _gui_input(event:InputEvent)->void:
	if event is InputEventScreenTouch:
		last_touch_at=Time.get_ticks_msec()
		if _owned_pointer("touch",event.index,event.pressed,event.position,event.canceled,event.device):accept_event()
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		if event.device<0 and Time.get_ticks_msec()-last_touch_at<500:return
		if _owned_pointer("mouse",0,event.pressed,event.position,false,event.device):accept_event()
	elif event is InputEventScreenDrag and pointer_kind=="touch" and event.index==pointer_index and event.device==pointer_device:accept_event()
	elif event is InputEventMouseMotion and pointer_kind=="mouse" and event.device==pointer_device:accept_event()
func _draw()->void:
	if stage_root==null:return
	draw_rect(Rect2(Vector2.ZERO,size),Color("c4b594"))
	var step:=maxf(24,32*fit)
	for x in range(0,int(size.x)+1,int(step)):draw_line(Vector2(x,0),Vector2(x,size.y),Color("aa9b7e",.25),1)
	for y in range(0,int(size.y)+1,int(step)):draw_line(Vector2(0,y),Vector2(size.x,y),Color("aa9b7e",.2),1)
func draw_projection(canvas:CanvasItem)->void:
	canvas.draw_set_transform(origin,0,Vector2.ONE*fit)
	if displayed_stage=="wardrobe":
		for i in range(3):
			var hat:String=old_hats[i] if motion=="swap" else checkpoint.hats[i]
			var from:Vector2=lamp_positions[i]+Vector2(0,-160)
			var to:Vector2=shadow_positions[i]
			var points:=PackedVector2Array([from+Vector2(-6,0),from+Vector2(6,0),to+Vector2(32,31),to+Vector2(-32,31)])
			canvas.draw_colored_polygon(points,Color(.95,.88,.63,.09 if motion=="swap" else .18))
			var angle:float=PI/2 if i==1 else 0
			var mirror:float=-1 if i==0 else 1
			Shade.draw_symbol(canvas,Model.HATS[i],to,Color("dbecdb"),2,true,angle,mirror)
			Shade.draw_symbol(canvas,hat,to+Vector2(0,7 if hat!=Model.HATS[i] else 0),Color("f1c168") if hat!=Model.HATS[i] else Color("f8e8bd"),3,false,angle,mirror)
	else:
		var a:Dictionary=checkpoint.alignment
		var point:=Vector2(float(a.xOffset)*16,float(a.yOffset)*16)
		var angle:=float(a.rotationQuarterTurns)*PI/2
		if motion=="step" or motion=="reset_alignment":
			var t:=smoothstep(0,.3,motion_time)
			point=Vector2(float(old_alignment.xOffset)*16,float(old_alignment.yOffset)*16).lerp(point,t)
			angle=lerp_angle(float(old_alignment.rotationQuarterTurns)*PI/2,angle,t)
		var registration:Dictionary=Model.source().registration.media
		var target:Vector2=curtain.position+Vector2(float(registration.xOffset)*16,float(registration.yOffset)*16)
		var center:Vector2=curtain.position+point+Vector2(0,-6*sin(hiccup/.34*PI))
		for i in range(3):
			var local:=Vector2((i-1)*50,0)
			Shade.draw_symbol(canvas,Model.HATS[i],target+local.rotated(float(registration.rotationQuarterTurns)*PI/2),Color("d2e9dc"),2,true,float(registration.rotationQuarterTurns)*PI/2)
			Shade.draw_symbol(canvas,Model.HATS[i],center+local.rotated(angle),Color("f6cf7f"),3,false,angle)
		for handle:Dictionary in handle_definitions():
			var at:Vector2=handle.point
			if handle.mark in ["left","right"]:
				canvas.draw_line(Vector2(at.x,curtain_rect().position.y+25),at,Color("675c43"),4)
				canvas.draw_line(Vector2(at.x,curtain_rect().position.y+25),at,Color("d7c7a3"),2)
			canvas.draw_circle(at,11,Color("5d513b"));canvas.draw_arc(at,11,0,TAU,24,Color("d7c7a3"),2)
			var direction:Vector2=Vector2.LEFT if handle.mark=="left" else Vector2.RIGHT if handle.mark=="right" else Vector2.UP if handle.mark=="up" else Vector2.DOWN
			if str(handle.mark).begins_with("turn"):
				canvas.draw_arc(at,6,.3,TAU-.7,16,Color("f4e4b2"),2)
				canvas.draw_line(at+Vector2(-6,-2),at+Vector2(-2,-5) if handle.mark=="turn_left" else at+Vector2(-9,-5),Color("f4e4b2"),2)
			else:
				canvas.draw_line(at-direction*5,at+direction*5,Color("f4e4b2"),2)
				canvas.draw_line(at+direction*5,at+direction.rotated(2.5)*3,Color("f4e4b2"),2)
				canvas.draw_line(at+direction*5,at+direction.rotated(-2.5)*3,Color("f4e4b2"),2)
	canvas.draw_set_transform(Vector2.ZERO)
	if check_station!=null:
		var caption:=origin+(check_station.position+Vector2(-35,18))*fit
		canvas.draw_string(get_theme_default_font(),caption,"点扫描台核对",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("26372b"))
class ProjectionCanvas extends Control:
	var owner_view:Control
	func _draw()->void:
		if is_instance_valid(owner_view):owner_view.draw_projection(self)
func _enter_tree()->void:
	projection=ProjectionCanvas.new();projection.owner_view=self;projection.mouse_filter=Control.MOUSE_FILTER_IGNORE;projection.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child.call_deferred(projection)
	set_process(true)
