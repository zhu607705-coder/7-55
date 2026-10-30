extends Control
const ApparatusStyle=preload("res://campuses/future_learning_center/scripts/apparatus_style.gd")
signal closed
const Model=preload("res://campuses/future_learning_center/scripts/puzzles/access_model.gd")
const INK=ApparatusStyle.INK
const PAPER=ApparatusStyle.PAPER
const COVER_TRAY:=Vector2(770,223)
const SUPPORT_TRAYS:=[Vector2(230,446),Vector2(335,446)]
const HINTS:=["盖片能被拿起，与盖片绕轴开合，哪里不同？","保持其他零件不动，比较盖在场与移开时的侧安装口。","对照爆炸图，检查轴的末端是否真正穿过两只轴孔。"]
var model=Model.new()
var font:Font
var touch_id:=-1
var action:=""
var support:=-1
var pointer:=Vector2.ZERO
var origin:=Vector2.ZERO
var shaft_origin:=0.0
var notebook:=false
var hint_level:=0
var feedback:=""
func _ready()->void:
	ApparatusStyle.configure_exit(self,close)
	font=ApparatusStyle.font();size=Vector2(960,540)
	mouse_filter=Control.MOUSE_FILTER_STOP;hide()
func open()->void:show();queue_redraw()
func close()->void:cancel_pointer();hide();closed.emit()
func cancel_pointer()->void:model.cancel_pointer();touch_id=-1;action="";support=-1;queue_redraw()
func _notification(what:int)->void:
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_APPLICATION_PAUSED]:cancel_pointer()
func point(x:float,y:=285.0)->Vector2:return Vector2(model.screen_x(x),y)
func lid_drop()->float:
	var end:Vector2=model.lid_section()
	return end.x*.4-end.y*.8
func cover_handle()->Vector2:return Vector2(440,285+lid_drop()-(9 if model.loose else 0))
func cover_tab()->Vector2:return Vector2(551,285+lid_drop()*.65)
func shaft_handle()->Vector2:return point(model.shaft_rect().position.x-20)
func support_at(i:int)->Vector2:return point(Model.HOLES[i]) if model.supports[i] else SUPPORT_TRAYS[i]
func _local(at:Vector2)->Vector2:return get_global_transform_with_canvas().affine_inverse()*at
func _input(event:InputEvent)->void:
	if ApparatusStyle.navigation_event(self,event):return
	if not visible:return
	if event is InputEventScreenTouch:
		if event.canceled and event.index==touch_id:cancel_pointer()
		elif event.pressed and touch_id<0:touch_id=event.index;press(_local(event.position))
		elif not event.pressed and event.index==touch_id:release(_local(event.position));touch_id=-1
	elif event is InputEventScreenDrag:
		if event.index==touch_id:motion(_local(event.position))
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		if touch_id>=0 or event.device==InputEvent.DEVICE_ID_EMULATION:return
		if event.pressed:press(_local(event.position))
		else:release(_local(event.position))
	elif event is InputEventMouseMotion:
		if touch_id>=0 or event.device==InputEvent.DEVICE_ID_EMULATION:return
		motion(_local(event.position))
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_ESCAPE:close()
	else:return
	get_viewport().set_input_as_handled();queue_redraw()
func press(at:Vector2)->void:
	pointer=at;origin=at;action="";feedback=""
	if notebook:action="page" if Rect2(645,418,220,40).has_point(at) else "paper";return
	if Rect2(44,420,135,85).has_point(at):action="paper";return
	if at.distance_to(Vector2(430,460))<27:action="undo";return
	if at.distance_to(shaft_handle())<23:action="shaft";shaft_origin=model.insertion;model.begin_gesture();return
	if at.distance_to(cover_tab() if model.cover else COVER_TRAY)<28:action="cover";return
	if model.cover and at.distance_to(cover_handle())<27:action="lid";model.begin_gesture();return
	for i:int in 2:
		if at.distance_to(support_at(i))<22:action="support";support=i;return
	if at.distance_to(point(315,385))<25:action="side";return
func motion(at:Vector2)->void:
	pointer=at
	if action=="shaft":model.slide_to(shaft_origin+(at.x-origin.x)*(1 if model.side==0 else -1))
	elif action=="lid":
		var ratio:float=clampf((at.y-285)/(180*sqrt(.8)), -1,1)
		model.swing_to(clampf(acos(ratio)-atan2(.8,.4),0,PI/2))
	queue_redraw()
func release(at:Vector2)->void:
	pointer=at
	if action in ["shaft","lid"]:model.end_gesture()
	elif action=="cover":
		if at.distance_to(COVER_TRAY)<85:model.set_cover(false)
		elif Rect2(325,225,240,150).has_point(at):model.set_cover(true)
	elif action=="support" and support>=0:
		if at.distance_to(SUPPORT_TRAYS[support])<42:model.set_support(support,false)
		elif at.distance_to(point(Model.HOLES[support]))<34:model.set_support(support,true)
	elif action=="side":
		var wanted:=0 if at.x<440 else 1
		if not model.set_side(wanted):feedback="先移开盖片，把轴退出侧安装口。"
	elif origin.distance_to(at)<18:
		match action:
			"close":close()
			"undo":model.undo()
			"paper":notebook=not notebook
			"page":hint_level=mini(3,hint_level+1)
	action="";support=-1;queue_redraw()
func text(value:String,at:Vector2,sz:=17,color:=INK)->void:draw_string(font,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,sz,color)
func slab(rect:Rect2,color:Color,depth:=7.0)->void:
	draw_rect(Rect2(rect.position+Vector2(0,depth),rect.size),color.darkened(.3));draw_rect(rect,color);draw_rect(rect,INK,false,1.5)
	draw_line(rect.position+Vector2(2,2),Vector2(rect.end.x-2,rect.position.y+2),color.lightened(.24),2)
func _support(i:int,at:Vector2)->void:
	slab(Rect2(at-Vector2(12,18),Vector2(24,50)),Color("8b9b98"),6)
	draw_circle(at,10,INK);draw_circle(at,6,PAPER)
	draw_circle(at+Vector2(0,23),3,INK)
func _cover()->void:
	if not model.cover:
		var at:Vector2=pointer if action=="cover" else COVER_TRAY
		slab(Rect2(at-Vector2(85,35),Vector2(170,70)),Color("a6b4a6"),6)
		draw_rect(Rect2(at-Vector2(62,22),Vector2(124,43)),Color("d1d7c5"),false,2)
		text("盖片托盘",Vector2(725,285),14);return
	var d:=lid_drop()
	var offset:=-9.0 if model.loose else 0.0
	var corners:=PackedVector2Array([Vector2(350,285+offset),Vector2(530,285+offset+ (5 if model.loose else 0)),Vector2(530,285+d+offset),Vector2(350,285+d+offset)])
	draw_colored_polygon(corners,Color(.62,.71,.68,.42))
	draw_polyline(corners+PackedVector2Array([corners[0]]),Color("6e8984"),4)
	var handle:=cover_handle()
	draw_line(handle-Vector2(20,0),handle+Vector2(20,0),INK,9);draw_line(handle-Vector2(17,2),handle+Vector2(17,2),PAPER,3)
	var tab:=cover_tab();slab(Rect2(tab-Vector2(10,9),Vector2(20,18)),Color("9aab9e"),3)
	# This side lip lies outside the final shaft but intersects the insertion corridor.
	var left:float=model.screen_x(Model.ENTRY_LIP.position.x)
	var right:float=model.screen_x(Model.ENTRY_LIP.end.x)
	slab(Rect2(minf(left,right),276,absf(right-left),18),Color("899e92"),4)
func _draw()->void:
	if font==null:return
	draw_rect(Rect2(0,0,960,540),Color("c5c8bd"))
	for y:int in range(85,540,35):draw_line(Vector2(0,y),Vector2(960,y+9),Color("b7bcaf"),1)
	text("团队工作室 4 · 透明铰链盒",Vector2(32,37),23)
	text("零件装好之后，让盒盖真正打开，再合上。",Vector2(33,65),16)
	slab(Rect2(100,368,755,38),Color("8f7a5e"),24)
	# Transparent shell: axis and both bores remain visible in the same live view.
	draw_colored_polygon(PackedVector2Array([Vector2(350,285),Vector2(530,285),Vector2(530,365),Vector2(350,365)]),Color(.62,.75,.75,.3))
	draw_rect(Rect2(350,285,180,80),Color("6c8787"),false,3)
	draw_line(Vector2(350,365),Vector2(530,365),INK,5)
	for i:int in 2:
		var at:=support_at(i)
		if action=="support" and support==i:at=pointer
		_support(i,at)
	var rod:Rect2=model.shaft_rect()
	var left:float=model.screen_x(rod.position.x);var right:float=model.screen_x(rod.end.x)
	draw_line(Vector2(left,285),Vector2(right,285),INK,9);draw_line(Vector2(left,283),Vector2(right,283),Color("d5d3bb"),4)
	var grip:=shaft_handle();draw_line(grip,Vector2(left,285),INK,5)
	slab(Rect2(grip-Vector2(9,13),Vector2(18,26)),Color("b99d74"),4)
	for i:int in 2:
		if model.through_hole(i):draw_arc(point(Model.HOLES[i]),12,0,TAU,20,Color("7e9b81"),2)
	_cover()
	if model.contact.is_finite():
		var mark:=point(model.contact.x,285+model.contact.y)
		draw_arc(mark,17,0,TAU,24,Color("a5694d"),3)
	text("侧安装通道",point(220,322)-Vector2(37,0),14)
	for x:float in [315,565]:draw_rect(Rect2(x-19,373,38,24),Color("89978e"),false,2)
	var mount:Vector2=pointer if action=="side" else point(315,385)
	slab(Rect2(mount-Vector2(17,10),Vector2(34,20)),Color("9a8a6d"),4)
	text("换侧定位块",Vector2(390,410),14)
	slab(Rect2(44,425,135,77),PAPER,5);text("局部爆炸图",Vector2(58,456),18);text("按需翻看",Vector2(72,481),14)
	for i:int in 2:
		draw_arc(SUPPORT_TRAYS[i],27,0,TAU,24,Color("7a8276"),1)
		text("支撑托盘",SUPPORT_TRAYS[i]+Vector2(-29,48),14)
	draw_arc(Vector2(430,460),20,.2,TAU-.5,24,INK,4);text("撤回",Vector2(414,500),14)
	if not feedback.is_empty():text(feedback,Vector2(495,488),16)
	elif not model.outcome.is_empty():text(model.outcome,Vector2(495,488),16)
	if notebook:
		slab(Rect2(105,104,750,352),PAPER,8)
		text("支撑、轴与盖片",Vector2(132,140),23)
		text("轴从侧面穿孔；握住盖前缘的横柄开合。",Vector2(132,183),17)
		text("拖动侧边小耳把盖移到托盘，支撑也可单独装卸。",Vector2(132,218),17)
		for i:int in hint_level:text(HINTS[i],Vector2(132,265+i*39),17)
		text("翻下一页提示",Vector2(670,443),17)
