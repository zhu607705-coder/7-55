extends Control
signal closed
const Model=preload("res://campuses/future_learning_center/scripts/puzzles/storage_model.gd")
const INK:=Color("344452")
const PAPER:=Color("ede9df")
const BOX_COLORS:=[Color("b89361"),Color("93a59d"),Color("a19b88")]
var model=Model.new()
var font:Font
var drag:=-1
var drag_offset:=Vector2.ZERO
var touch_id:=-1
var door_drag:=false
var notebook:=false
var hint_level:=0
var contact_time:=0.0
var pointer:=Vector2.ZERO
const HINTS:=["抽拉时最先接触的是短箱、柜门，还是门前物件？","保持长箱不动，只移动一只短箱到合法支撑位，再比较接触点。","对照归位轮廓和失败痕迹，查看柜门需要的活动范围。"]

func _ready()->void:
	font=load("res://scripts/ui/native_typography.gd").body_font()
	mouse_filter=Control.MOUSE_FILTER_STOP
	hide()
func open()->void:show();queue_redraw()
func close()->void:_cancel();hide();closed.emit()
func _cancel()->void:
	model.cancel_gesture();drag=-1;door_drag=false;touch_id=-1
func _notification(what:int)->void:
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_APPLICATION_PAUSED]:_cancel()
func _process(dt:float)->void:
	if visible:contact_time=maxf(0,contact_time-dt);queue_redraw()
func _input(event:InputEvent)->void:
	if not visible:return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode==KEY_ESCAPE:close()
		else:return
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		if touch_id>=0:return
		if event.pressed:press(get_global_transform_with_canvas().affine_inverse()*event.position)
		else:release()
	elif event is InputEventMouseMotion:
		if touch_id>=0:return
		motion(get_global_transform_with_canvas().affine_inverse()*event.position)
	elif event is InputEventScreenTouch:
		if event.canceled and event.index==touch_id:_cancel()
		elif event.pressed and touch_id<0:touch_id=event.index;press(get_global_transform_with_canvas().affine_inverse()*event.position)
		elif not event.pressed and event.index==touch_id:release();touch_id=-1
	elif event is InputEventScreenDrag:
		if event.index==touch_id:motion(get_global_transform_with_canvas().affine_inverse()*event.position)
	else:return
	get_viewport().set_input_as_handled();queue_redraw()
func press(at:Vector2)->void:
	pointer=at
	if Rect2(865,12,75,48).has_point(at):close();return
	if notebook:
		if Rect2(640,405,230,45).has_point(at):hint_level=mini(3,hint_level+1)
		elif Rect2(135,405,120,45).has_point(at):model.reset();notebook=false
		else:notebook=false
		return
	if Rect2(72,422,125,70).has_point(at):notebook=true;return
	if at.distance_to(Vector2(805,432))<32:model.undo();return
	if at.distance_to(model.door_tip())<26:door_drag=true;model.begin_gesture();return
	for i:int in range(2,-1,-1):
		if model.box(i).has_point(at):
			drag=i;drag_offset=at-model.positions[i];model.begin_gesture();return
func motion(at:Vector2)->void:
	pointer=at
	if drag>=0:model.move_box(drag,at-drag_offset)
	elif door_drag:
		var d:=at-Model.HINGE
		model.swing_to(atan2(d.x,d.y))
	if not model.contact_kind.is_empty():contact_time=.7
func release()->void:
	model.end_gesture();drag=-1;door_drag=false;queue_redraw()
func _txt(value:String,at:Vector2,size_px:=18,color:=INK)->void:
	draw_string(font,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size_px,color)
func _block(rect:Rect2,color:Color,depth:=8.0)->void:
	draw_rect(Rect2(rect.position+Vector2(0,depth),rect.size),color.darkened(.3))
	draw_rect(rect,color);draw_rect(rect,INK,false,2)
	draw_line(rect.position+Vector2(2,2),Vector2(rect.end.x-2,rect.position.y+2),color.lightened(.2),2)
func _draw()->void:
	if font==null:return
	draw_rect(Rect2(0,0,960,540),Color("c6c7c3"))
	for y:int in range(90,540,45):draw_line(Vector2(0,y),Vector2(960,y),Color("b6b9b6"),1)
	_txt("设备储藏室",Vector2(35,38),24)
	_txt("取出长箱，给其他箱子留下支撑和归路。",Vector2(35,65),17)
	_txt("返回",Vector2(877,42),18)
	# Cabinet shell and supported surfaces are the same geometry as the model.
	_block(Rect2(204,132,432,234),Color("70503b"),20)
	for rect:Rect2 in Model.SUPPORT:
		_block(rect,Color("c6b694"),7)
		for x:int in range(int(rect.position.x)+12,int(rect.end.x),28):draw_line(Vector2(x,rect.position.y+5),Vector2(x,rect.end.y-5),Color("b6a683"),1)
	# Unusable compartment is visibly raised and cannot support a moving case.
	_block(Rect2(220,150,300,80),Color("70503b"),12)
	for i:int in 3:
		draw_rect(Rect2(Model.STARTS[i],Model.SIZES[i]),Color("8e8066"),false,2)
	_txt("归位轮廓",Vector2(260,343),13,Color("7a715f"))
	_txt("柜侧托盘",Vector2(626,453),15)
	_txt("取用台",Vector2(754,374),16)
	draw_arc(Model.HINGE,Model.DOOR_LENGTH,0,PI/2,30,Color("b09b78"),2)
	# Diagonal hinge leaf has physical width and an attached handle.
	var tip:Vector2=model.door_tip()
	draw_line(Model.HINGE+Vector2(0,7),tip+Vector2(0,7),Color("44332d"),14)
	draw_line(Model.HINGE,tip,Color("a1744e"),12)
	draw_line(Model.HINGE,tip,Color("c79b62"),3)
	draw_circle(Model.HINGE,7,INK);draw_circle(tip,10,Color("b6bdba"));draw_circle(tip,5,INK)
	for i:int in 3:
		var box:Rect2=model.box(i)
		_block(box,BOX_COLORS[i],10)
		var c:=box.get_center()
		draw_rect(Rect2(c-Vector2(19,6),Vector2(38,12)),INK,false,3)
		for edge:float in [box.position.x+12,box.end.x-12]:
			draw_line(Vector2(edge,box.position.y+3),Vector2(edge,box.end.y-3),BOX_COLORS[i].darkened(.2),4)
		_txt("长箱" if i==0 else str(i),Vector2(box.position.x+25,box.position.y+22),15)
	if model.contact.is_finite() and contact_time>0:
		var c:Vector2=model.contact
		draw_arc(c,14,0,TAU,16,Color("9e614a"),3)
		for n:int in 4:
			var direction:=Vector2.RIGHT.rotated(n*PI/2)
			draw_line(c+direction*18,c+direction*25,Color("9e614a"),3)
		var label:String={"support":"边缘没有支撑","box":"箱角碰到了","door":"门扇占住了通路"}.get(model.contact_kind,"")
		_txt(label,Vector2(300,397),17)
	_block(Rect2(72,422,125,70),PAPER,5)
	_txt("借用手册",Vector2(86,453),18);_txt("按需翻阅",Vector2(92,476),14)
	draw_arc(Vector2(805,432),22,.3,TAU-.5,22,INK,5)
	draw_colored_polygon(PackedVector2Array([Vector2(822,412),Vector2(831,430),Vector2(814,427)]),INK)
	_txt("撤回",Vector2(785,479),15)
	if model.returned:_txt("长箱已取用并归位",Vector2(348,475),21)
	elif model.taken:_txt("长箱已取出 · 仍可归还",Vector2(327,475),20)
	if notebook:
		_block(Rect2(104,105,752,350),PAPER,8)
		_txt("借用与归还",Vector2(132,143),24)
		_txt("抓住箱把手抽拉，拖动银色门把手开合。",Vector2(132,182),18)
		_txt("灰色底面承托箱子；门扇转动也需要空间。",Vector2(132,217),18)
		for i:int in hint_level:_txt(HINTS[i],Vector2(132,265+i*40),17)
		_txt("重新摆放",Vector2(137,435),17);_txt("翻下一页提示",Vector2(668,435),17)
