extends Control
## The original plate with independent hands, gears and crown.
const PLATE=preload("res://assets/rpg/interiors/finale/chapter4-755/sprites/chapter4_clock_states_v01.png")
var hour_angle:=0.0
var minute_angle:=0.0
var recoil:=0.0
var minute_gear_angle:=0.0
var hour_gear_angle:=0.0
var sample_glow:=0.0
var crown:=0.0
var repaired:=false
var reduced:=false
var symbol:="麦"
var repair:="minute_pawl"
var font:Font
var motion:Tween
var active:=true
var input_step:=-1
var input_callback:Callable
var part_controls:Dictionary={}
var locked_axes:Array=[]
var dragging_axis:=""
var drag_angle:=0.0
var drag_remainder:=0.0
var touch_index:=-1
var keyboard_axis:="hour"
var readout:=""
const Ui=preload("res://scripts/ui/native_ui_theme.gd")
const Typography=preload("res://scripts/ui/native_typography.gd")
func _ready()->void:
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;resized.connect(_place_parts);_place_parts()
func fit()->float:return minf(size.x/360.0,size.y/430.0)
func local_point(source:Vector2)->Vector2:return (size-Vector2(360,430)*fit())/2+source*fit()
func gear_point(axis:String)->Vector2:return local_point(Vector2(183 if axis=="hour" else 136,337))
func configure_interaction(step:int,callback:Callable,locks:Array)->Dictionary:
	input_callback=callback;locked_axes=locks.duplicate()
	queue_redraw()
	if input_step==step:return part_controls
	input_step=step;dragging_axis="";touch_index=-1
	for control in part_controls.values():remove_child(control);control.queue_free()
	part_controls={};mouse_filter=Control.MOUSE_FILTER_PASS if step in [3,4,7] else Control.MOUSE_FILTER_IGNORE
	focus_mode=Control.FOCUS_ALL if step==4 else Control.FOCUS_NONE
	if step==3:
		for row in [["minute_pawl","止逆爪"],["hour_clutch","离合"],["backlash","定位槽"]]:
			_hotspot("repair_"+row[0],row[1],func():input_callback.call({"kind":"repair","id":row[0]}))
		_hotspot("probe","拨动转轴",probe)
	elif step==4:
		_hotspot("compare_wheels","合上表冠试转",func():input_callback.call({"kind":"compare_wheels"}))
		for axis in ["hour","minute"]:_hotspot(axis+"_lock","时轮锁扣" if axis=="hour" else "分轮锁扣",func():input_callback.call({"kind":"lock","axis":axis}))
	elif step==7:_hotspot("commit","合上表冠",func():input_callback.call({"kind":"commit"}))
	_place_parts();return part_controls
func _hotspot(id:String,description:String,callback:Callable)->void:
	var part:=Button.new();part.tooltip_text=description;part.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
	part.size=Vector2(44,44);part.custom_minimum_size=part.size
	part.add_theme_stylebox_override("normal",StyleBoxEmpty.new())
	for key in ["hover","pressed","focus"]:part.add_theme_stylebox_override(key,Ui.box(Color(0,0,0,0),Color(.91,.8,.53,.8 if key=="focus" else .3),1,10,Vector2.ZERO))
	part.pressed.connect(callback);add_child(part);part_controls[id]=part
func _place_parts()->void:
	for id in part_controls:
		var point:Vector2={"repair_minute_pawl":Vector2(103,328),"repair_hour_clutch":Vector2(210,337),"repair_backlash":Vector2(299,158),"probe":Vector2(162,160),"minute_lock":Vector2(82,337),"hour_lock":Vector2(246,337),"commit":Vector2(299,158),"compare_wheels":Vector2(299,158)}[id]
		var p:Vector2=local_point(point)-part_controls[id].size/2
		part_controls[id].position=Vector2(clampf(p.x,0,maxf(0,size.x-44)),clampf(p.y,0,maxf(0,size.y-44)))
func _axis_at(point:Vector2)->String:
	var best:="";var distance:=35.0
	for axis in ["hour","minute"]:
		if axis in locked_axes:continue
		var candidate:float=point.distance_to(gear_point(axis))
		if candidate<distance:distance=candidate;best=axis
	return best
func _start_drag(point:Vector2)->void:
	dragging_axis=_axis_at(point);drag_remainder=0
	if not dragging_axis.is_empty():keyboard_axis=dragging_axis;grab_focus();drag_angle=(point-gear_point(dragging_axis)).angle();accept_event()
func _move_drag(point:Vector2)->void:
	if dragging_axis.is_empty():return
	var angle:float=(point-gear_point(dragging_axis)).angle()
	drag_remainder+=angle_difference(drag_angle,angle);drag_angle=angle
	while absf(drag_remainder)>=TAU/12:
		var direction:int=1 if drag_remainder>0 else -1
		drag_remainder-=direction*TAU/12;input_callback.call({"kind":"wheel","axis":dragging_axis,"delta":direction})
	accept_event()
func _gui_input(event:InputEvent)->void:
	if input_step!=4 or not active:return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_UP,KEY_DOWN]:keyboard_axis="minute" if keyboard_axis=="hour" else "hour";accept_event()
		elif event.keycode in [KEY_LEFT,KEY_RIGHT]:input_callback.call({"kind":"wheel","axis":keyboard_axis,"delta":1 if event.keycode==KEY_RIGHT else -1});accept_event()
		elif event.keycode==KEY_SPACE:input_callback.call({"kind":"lock","axis":keyboard_axis});accept_event()
	elif event is InputEventScreenTouch:
		if event.pressed and touch_index==-1:touch_index=event.index;_start_drag(event.position)
		elif not event.pressed and event.index==touch_index:dragging_axis="";touch_index=-1
	elif event is InputEventScreenDrag and event.index==touch_index:_move_drag(event.position)
	elif event is InputEventMouseButton and touch_index==-1:
		if event.button_index==MOUSE_BUTTON_LEFT:
			if event.pressed:_start_drag(event.position)
			else:dragging_axis=""
		elif event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
			var axis:String=_axis_at(event.position)
			if not axis.is_empty():input_callback.call({"kind":"wheel","axis":axis,"delta":1 if event.button_index==MOUSE_BUTTON_WHEEL_UP else -1});accept_event()
	elif event is InputEventMouseMotion and touch_index==-1:_move_drag(event.position)
func show_checkpoint(v:Dictionary,movement:String="")->void:
	if motion:motion.kill()
	repaired=int(v.step)>=4
	readout="%02d:%02d"%[int(v.hour),int(v.minute)]
	var h:float=(float(v.hour)+float(v.minute)/60.0)*TAU/12.0
	var m:float=float(v.minute)*TAU/60.0
	if reduced or not is_inside_tree() or movement.is_empty():hour_angle=h;minute_angle=m;recoil=0;sample_glow=0;queue_redraw();return
	motion=create_tween().set_parallel(true)
	motion.tween_property(self,"hour_angle",hour_angle+angle_difference(hour_angle,h),.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	motion.tween_property(self,"minute_angle",minute_angle+angle_difference(minute_angle,m),.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if movement=="wheel":
		var minute_change:float=angle_difference(minute_angle,m)
		var hour_change:float=angle_difference(hour_angle,h)
		if absf(minute_change)>.1:motion.tween_property(self,"minute_gear_angle",minute_gear_angle+signf(minute_change)*PI/6,.3)
		elif absf(hour_change)>.1:motion.tween_property(self,"hour_gear_angle",hour_gear_angle+signf(hour_change)*PI/6,.3)
	if movement=="sample":sample_glow=1;motion.tween_property(self,"sample_glow",0.0,.65)
	if movement=="repair":crown=1;motion.tween_property(self,"crown",0.0,.45)
	if movement=="rebound":probe()
func probe()->void:
	if motion:motion.kill()
	if reduced:recoil=0;queue_redraw();return
	motion=create_tween();motion.tween_property(self,"recoil",1.0,.28);motion.tween_property(self,"recoil",-.32,.18);motion.tween_property(self,"recoil",.16,.15);motion.tween_property(self,"recoil",0.0,.22)
func _process(_dt:float)->void:
	if active:queue_redraw()
func _notification(what:int)->void:
	if what==NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		dragging_axis="";touch_index=-1
		if motion:motion.pause()
	if what==NOTIFICATION_WM_WINDOW_FOCUS_IN and motion and active:motion.play()
func dispose()->void:
	active=false;dragging_axis="";touch_index=-1
	if motion:motion.kill()
func _draw()->void:
	var factor:float=fit()
	draw_set_transform((size-Vector2(360,430)*factor)/2,0,Vector2.ONE*factor)
	draw_texture_rect_region(PLATE,Rect2(15,12,321,313),Rect2(42,52,321,313))
	# The wheels and latches share a physical housing attached to the clockcase.
	draw_rect(Rect2(67,300,199,105),Color("111916"))
	draw_rect(Rect2(70,296,193,105),Color("514936"))
	draw_rect(Rect2(74,300,185,95),Color("282c25"))
	draw_line(Vector2(76,301),Vector2(257,301),Color("a58d5d"),2,false)
	for screw in [Vector2(79,306),Vector2(254,306),Vector2(79,388),Vector2(254,388)]:
		draw_circle(screw,3,Color("a58d5d"));draw_line(screw-Vector2(2,0),screw+Vector2(2,0),Color("393726"),1,false)
	var center:=Vector2(162,160)
	var h:float=hour_angle;var m:float=minute_angle
	if repair=="minute_pawl":m+=recoil*.30
	elif repair=="hour_clutch":h+=recoil*.03
	else:h+=recoil*.10;m+=recoil*.10
	var hour_length:float=44 if symbol=="麦" else 61
	var ink:=Color("292b29")
	draw_line(center+Vector2(2,3),center+Vector2.from_angle(h-PI/2)*hour_length+Vector2(2,3),Color(0,0,0,.3),8,false)
	draw_line(center,center+Vector2.from_angle(h-PI/2)*hour_length,ink,7,false)
	draw_line(center,center+Vector2.from_angle(m-PI/2)*98,ink,4,false)
	draw_circle(center,7,Color("b78637"));draw_circle(center,3,Color("e4c58c"))
	for i in 2:
		var p:=Vector2(136+i*47,337)
		var angle:float=(minute_gear_angle if i==0 else hour_gear_angle)+recoil*(.7 if repair!="hour_clutch" or i==0 else .04)
		draw_circle(p,21,Color("483d2c"));draw_arc(p,16,0,TAU,32,Color("bc975e"),2,false)
		for tooth in 12:
			var direction:=Vector2.from_angle(tooth*TAU/12+angle)
			draw_line(p+direction*17,p+direction*23,Color("bc975e"),4,false)
		draw_circle(p,4,Color("dfc48c"))
		var axis:String="minute" if i==0 else "hour"
		if input_step==4 and has_focus() and keyboard_axis==axis:draw_arc(p,27,0,TAU,32,Color("d5ba7b"),1,false)
	# Stop pawl and clutch collar visibly move during diagnosis.
	var pawl:=Vector2(103,328)
	draw_line(pawl,pawl+Vector2(16,5+recoil*(8 if repair=="minute_pawl" else 1)),Color("bfa26b"),5,false);draw_circle(pawl,4,Color("dec18a"))
	draw_arc(Vector2(210,337),10,PI/2+recoil*.2,PI*1.5+recoil*.2,16,Color("bfa26b"),5,false)
	for axis in ["minute","hour"]:
		var latch:=Vector2(82 if axis=="minute" else 246,337)
		var locked:bool=axis in locked_axes
		var tip:Vector2=latch+Vector2(31 if axis=="minute" else -31,0) if locked else latch+Vector2(0,23)
		draw_line(latch+Vector2(2,2),tip+Vector2(2,2),Color("101714"),7,false)
		draw_line(latch,tip,Color("a28a58") if locked else Color("6f6952"),5,false);draw_circle(latch,4,Color("cfb681"))
	draw_rect(Rect2(284+crown*8,146,22,25),Color("ad773e"))
	for notch in 5:draw_line(Vector2(287,149+notch*4),Vector2(303,149+notch*4),Color("d5ab63"),1,false)
	if input_step==7:draw_arc(Vector2(298,158),20,-PI*.6,PI*.6,24,Color("d5ba7b"),2,false)
	if sample_glow>0:draw_arc(center,126,0,TAU,96,Color(.65,.8,.55,sample_glow),3,false)
	if font:
		draw_string(font,Vector2(87,383),symbol,HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("b6a680"))
		draw_string(font,Vector2(127,375),"分",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("c8baa2"));draw_string(font,Vector2(178,375),"时",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("c8baa2"))
		if input_step>=4:
			draw_rect(Rect2(123,379,82,17),Color("151c18"));draw_string(font,Vector2(131,392),readout,HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("c8baa2"))
	draw_set_transform(Vector2.ZERO)
