extends Control
signal closed
const Model=preload("res://campuses/future_learning_center/scripts/puzzles/fold_model.gd")
const INK:=Color("293c43")
const PAPER:=Color("e8e1cf")
const LEAF_COLORS:=[Color("9aada8"),Color("b9ab8f")]
const PLUG:=Vector2(535,318)
const PARKED_PLUG:=Vector2(610,422)
const SWITCH:=Vector2(710,400)
const ATTACH_TRAY:=Vector2(760,467)
const HINTS:=["碰停的盖片正在接触连接带，还是另一片盖？","只改变一件事：换带的路径，或改变两片盖的动作先后。","对照展开草图与碰停照片，查看铰链内侧留下的空间。"]
var model=Model.new()
var font:Font
var touch_id:=-1
var action:=""
var leaf:=-1
var pointer:=Vector2.ZERO
var origin:=Vector2.ZERO
var notebook:=false
var hint_level:=0
var feedback:=""
var glow:=0.0
var contact_flash:=0.0
func _ready()->void:
	font=load("res://scripts/ui/native_typography.gd").body_font()
	mouse_filter=Control.MOUSE_FILTER_STOP;size=Vector2(960,540);hide()
func open()->void:show();queue_redraw()
func close()->void:model.stop();cancel_pointer();hide();closed.emit()
func cancel_pointer()->void:
	model.cancel_pointer();touch_id=-1;action="";leaf=-1;queue_redraw()
func _notification(what:int)->void:
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_APPLICATION_PAUSED]:
		model.stop();cancel_pointer()
func _process(dt:float)->void:
	if not visible:return
	model.step(minf(dt,.1))
	glow=move_toward(glow,1.0 if model.connected and (model.running or model.operated) and not model.cable_pinched() else 0.0,dt*5)
	contact_flash=maxf(0,contact_flash-dt);queue_redraw()
func _local(at:Vector2)->Vector2:return get_global_transform_with_canvas().affine_inverse()*at
func _input(event:InputEvent)->void:
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
func distance_to_path(at:Vector2,path:PackedVector2Array)->float:
	var distance:=INF
	for i:int in range(1,path.size()):distance=minf(distance,at.distance_to(Geometry2D.get_closest_point_to_segment(at,path[i-1],path[i])))
	return distance
func press(at:Vector2)->void:
	pointer=at;origin=at;action="";feedback=""
	if Rect2(860,10,88,48).has_point(at):action="close";return
	if notebook:
		action="page" if Rect2(645,418,230,40).has_point(at) else "paper";return
	if Rect2(45,420,145,85).has_point(at):action="paper";return
	if at.distance_to(Vector2(250,465))<30:action="undo";return
	if at.distance_to(SWITCH)<35:action="test";return
	if at.distance_to(Model.ATTACHMENT.get_center() if model.attachment else ATTACH_TRAY)<25:action="attachment";return
	if at.distance_to(PLUG if model.connected else PARKED_PLUG)<22:action="plug";return
	# The top cover is picked first where projected handles overlap.
	for i:int in [1,0]:
		if at.distance_to(model.tip(i))<25:
			leaf=i;action="leaf";model.begin_gesture();return
	if distance_to_path(at,model.cable_path())<17:action="cable";return
func motion(at:Vector2)->void:
	pointer=at
	if action=="leaf" and leaf>=0:
		var d:Vector2=at-Model.HINGES[leaf]
		var x:float=d.x*(-1 if leaf==0 else 1)
		var angle:=atan2(-d.y,x)
		if angle<0:angle=PI if x<0 else 0.0
		model.swing_to(leaf,angle)
		if not model.contact_kind.is_empty():contact_flash=.8
	queue_redraw()
func release(at:Vector2)->void:
	pointer=at
	if action=="leaf":model.end_gesture()
	elif action=="plug":
		if origin.distance_to(at)<10:model.set_connected(not model.connected)
		elif at.distance_to(PARKED_PLUG)<38:model.set_connected(false)
		elif at.distance_to(PLUG)<30:model.set_connected(true)
	elif action=="cable":
		var best:=-1;var distance:=22.0
		for i:int in 3:
			var candidate:=distance_to_path(at,model.cable_path(i))
			if candidate<distance:distance=candidate;best=i
		if best>=0 and not model.change_route(best):feedback="盖片未展开，走线槽还被遮住。"
	elif action=="attachment":
		var at_slot:=at.distance_to(Model.ATTACHMENT.get_center())<35
		var at_tray:=at.distance_to(ATTACH_TRAY)<42
		if at_slot or at_tray:
			if not model.set_attachment(at_slot):feedback="盖片未展开，附件座还被遮住。"
	elif origin.distance_to(at)<18:
		match action:
			"close":close()
			"paper":notebook=not notebook
			"page":hint_level=mini(3,hint_level+1)
			"undo":model.undo()
			"test":model.start()
	action="";leaf=-1;queue_redraw()
func text(value:String,at:Vector2,sz:=17,color:=INK)->void:draw_string(font,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,sz,color)
func slab(rect:Rect2,color:Color,depth:=7.0)->void:
	draw_rect(Rect2(rect.position+Vector2(0,depth),rect.size),color.darkened(.28));draw_rect(rect,color);draw_rect(rect,INK,false,1.5)
	draw_line(rect.position+Vector2(2,2),Vector2(rect.end.x-2,rect.position.y+2),color.lightened(.2),2)
func leaf_shape(i:int)->void:
	var a:Vector2=Model.HINGES[i];var b:Vector2=model.tip(i)
	var normal:Vector2=(b-a).normalized().orthogonal()*Model.HALF_THICKNESS
	var shape:=PackedVector2Array([a+normal,b+normal,b-normal,a-normal])
	var shadow:=PackedVector2Array()
	for p:Vector2 in shape:shadow.append(p+Vector2(0,9))
	draw_colored_polygon(shadow,Color(0,0,0,.16))
	# Both covers share the same extrusion depth. Their front cross-sections are the collider geometry.
	var depth:=Vector2(15,-24)
	var face:=PackedVector2Array([a-normal,b-normal,b-normal+depth,a-normal+depth])
	draw_colored_polygon(face,LEAF_COLORS[i].lightened(.09))
	draw_polyline(PackedVector2Array([a-normal+depth,b-normal+depth,b-normal]),INK,1.5)
	for fraction:float in [.25,.5,.75]:
		var rib:=a.lerp(b,fraction)
		draw_line(rib-normal+depth*.12,rib-normal+depth*.87,LEAF_COLORS[i].darkened(.12),1)
	draw_colored_polygon(shape,LEAF_COLORS[i])
	draw_polyline(PackedVector2Array([a+normal,b+normal,b-normal,a-normal,a+normal]),INK,1.5)
	draw_line(a-normal*.7,b-normal*.7,LEAF_COLORS[i].lightened(.3),1)
	for fraction:float in [.2,.8]:draw_circle(a.lerp(b,fraction),2,INK)
	draw_circle(a,8,INK);draw_circle(a,4,Color("d6d4c8"))
	draw_circle(b,13,INK);draw_circle(b,9,LEAF_COLORS[i]);draw_arc(b,6,0,TAU,16,PAPER,1)
	text("窄盖" if i==0 else "宽盖",a.lerp(b,.55)+Vector2(-15,-17),14)
func _draw()->void:
	if font==null:return
	draw_rect(Rect2(0,0,960,540),Color("c3c6bc"))
	for y:int in range(80,540,36):draw_line(Vector2(0,y),Vector2(960,y+8),Color("b8bbae"),1)
	text("X-Lab 南区 · 折叠样机",Vector2(32,36),23)
	text("展开使用，再把同一台样机收入模板。",Vector2(33,65),16)
	text("返回",Vector2(878,40),17)
	slab(Rect2(100,362,760,40),Color("8e795d"),24)
	# The transport gauge is fixed; the live covers are never exchanged for a closed sprite.
	draw_rect(Model.TEMPLATE,Color(.89,.87,.77,.18))
	for edge:Array in [[Model.TEMPLATE.position,Vector2(Model.TEMPLATE.end.x,Model.TEMPLATE.position.y)],[Model.TEMPLATE.end,Vector2(Model.TEMPLATE.position.x,Model.TEMPLATE.end.y)]]:
		draw_dashed_line(edge[0],edge[1],Color("7b8276"),2,7)
	text("收纳轮廓",Vector2(566,351),14,Color("606c62"))
	slab(Rect2(296,305,258,41),Color("626e6c"),13)
	for i:int in [1,2,0]:
		var path:=model.cable_path(i)
		draw_polyline(path,Color("435253"),9);draw_polyline(path,Color("adb7a9"),5)
		for n:int in range(1,path.size()-1):draw_circle(path[n],4,Color("c7c4ae"))
	var wire:=model.cable_path()
	if not model.connected:wire[wire.size()-1]=PARKED_PLUG
	draw_polyline(wire,Color("3a3530"),6);draw_polyline(wire,Color("c89960"),3)
	var connector:Vector2=PLUG if model.connected else PARKED_PLUG
	slab(Rect2(connector-Vector2(10,7),Vector2(20,14)),Color("c6bca4"),3)
	draw_circle(Vector2(330,332),7,Color("e3d6a0") if glow>.5 else Color("495451"))
	leaf_shape(0);leaf_shape(1)
	var accessory:Vector2=Model.ATTACHMENT.get_center() if model.attachment else ATTACH_TRAY
	if action=="attachment":accessory=pointer
	slab(Rect2(accessory-Model.ATTACHMENT.size/2,Model.ATTACHMENT.size),Color("75635a"),7)
	draw_line(accessory-Vector2(12,0),accessory+Vector2(12,0),Color("cbbfaf"),3)
	if action=="cable":draw_line(origin,pointer,Color("c89960"),5)
	if action=="plug":slab(Rect2(pointer-Vector2(10,7),Vector2(20,14)),Color("c6bca4"),3)
	if model.contact.is_finite() and (contact_flash>0 or not model.contact_kind.is_empty()):
		draw_arc(model.contact,17,0,TAU,24,Color("a16147"),3)
		text({"leaf":"盖片相碰","cable":"连接带被夹住","attachment":"盖片碰到附件"}.get(model.contact_kind,""),Vector2(350,386),17)
	draw_circle(SWITCH,27,INK);draw_circle(SWITCH,21,Color("b99766"));draw_line(SWITCH,SWITCH+Vector2(0,-15 if not model.running else 15),PAPER,4)
	text("通电试验",SWITCH+Vector2(-34,48),15)
	slab(Rect2(45,425,145,77),PAPER,5);text("结构草图",Vector2(72,454),19);text("与碰停照片",Vector2(66,479),15)
	draw_arc(Vector2(250,465),20,.2,TAU-.5,24,INK,4);text("撤回",Vector2(234,502),14)
	text("附件托盘",Vector2(727,507),14)
	text("连接带停车位",Vector2(562,462),14)
	if not feedback.is_empty():text(feedback,Vector2(310,500),16)
	elif not model.outcome.is_empty():text(model.outcome,Vector2(310,500),16)
	if notebook:
		slab(Rect2(105,104,750,352),PAPER,8)
		text("展开结构与铰链活动范围",Vector2(132,140),23)
		text("抓住盖片端部的圆环转动；把连接带放进可见槽。",Vector2(132,182),17)
		text("插头可拔下，附件可移到托盘。试验灯对应当前样机。",Vector2(132,217),17)
		for i:int in hint_level:text(HINTS[i],Vector2(132,265+i*39),17)
		text("翻下一页提示",Vector2(670,443),17)
