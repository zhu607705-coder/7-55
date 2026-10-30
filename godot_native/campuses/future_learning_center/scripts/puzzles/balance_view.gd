extends Control
signal closed
const Model=preload("res://campuses/future_learning_center/scripts/puzzles/balance_model.gd")
const INK:=Color("29373b")
const PAPER:=Color("e9e3d3")
const SOURCE:=Vector2(315,310)
const DESTINATION:=Vector2(750,308)
const TARGET:=Rect2(610,245,290,125)
var model=Model.new()
var font:Font
var drag:=-1
var selected:=-1
var touch_id:=-1
var pointer:=Vector2.ZERO
var origin:=Vector2.ZERO
var tray_drag:=false
var paper_open:=false
var hint_level:=0
var focus_index:=0
const HINTS:=["两边各两杯，托盘还是往哪边偏？","交换一只满杯与半杯，再抓住提手试提。","比较杯垫离支点的距离，不只数左右杯数。"]
func _ready()->void:
	mouse_filter=Control.MOUSE_FILTER_STOP;focus_mode=Control.FOCUS_ALL
	font=load("res://scripts/ui/native_typography.gd").body_font();size=Vector2(960,540);hide()
func open()->void:cancel_pointer();model.resume();show();grab_focus();queue_redraw()
func close()->void:model.cancel();cancel_pointer();hide();closed.emit()
func cancel_pointer()->void:drag=-1;selected=-1;tray_drag=false;touch_id=-1;queue_redraw()
func _notification(what:int)->void:
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_APPLICATION_PAUSED]:model.pause();cancel_pointer()
func _process(dt:float)->void:
	if visible:model.step(dt);queue_redraw()
func tray_center()->Vector2:
	if tray_drag:return SOURCE+(pointer-origin)
	return SOURCE.lerp(DESTINATION,model.travel)-Vector2(0,model.elevation)
func tray_scale()->float:return lerpf(1,.65,model.travel)
func local_point(p:Vector2)->Vector2:return tray_center()+p.rotated(model.tilt)*tray_scale()
func cup_position(slot:int)->Vector2:return local_point(Vector2(Model.ARMS[slot]*70,-18))
func handle_position()->Vector2:return local_point(Vector2(model.pivot*70,-83))
func _gui_input(event:InputEvent)->void:
	if not visible:return
	if event is InputEventScreenTouch:
		if event.pressed and touch_id<0:touch_id=event.index;press_at(event.position)
		elif not event.pressed and event.index==touch_id:
			if event.canceled:model.cancel();cancel_pointer()
			else:release_at(event.position)
			touch_id=-1
		accept_event()
	elif event is InputEventScreenDrag and event.index==touch_id:pointer=event.position;queue_redraw();accept_event()
	elif event is InputEventMouse and event.device==InputEvent.DEVICE_ID_EMULATION:return
	elif event is InputEventMouseButton and touch_id<0 and event.button_index==MOUSE_BUTTON_LEFT:
		if event.pressed:press_at(event.position)
		else:release_at(event.position)
		accept_event()
	elif event is InputEventMouseMotion and touch_id<0:pointer=event.position;queue_redraw()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode==KEY_ESCAPE:close()
		elif event.keycode==KEY_TAB:focus_index=posmod(focus_index+(-1 if event.shift_pressed else 1),8)
		elif event.keycode in [KEY_ENTER,KEY_SPACE]:
			if focus_index<4:selected=model.slots[focus_index]
			elif focus_index==4:_lift()
			elif focus_index==5:model.start_delivery()
			elif focus_index==6:_paper()
			else:model.undo()
		elif selected>=0 and event.keycode in [KEY_1,KEY_2,KEY_3,KEY_4]:model.place(selected,int(event.keycode)-int(KEY_1));selected=-1
		queue_redraw();accept_event()
func press_at(at:Vector2)->void:
	pointer=at;origin=at
	if Rect2(880,16,58,48).has_point(at):close();return
	if Rect2(55,453,150,57).has_point(at):_paper();return
	if Rect2(227,453,64,57).has_point(at):model.undo();return
	if at.distance_to(Vector2(315+model.pivot*70,402))<25:model.set_extension(model.pivot==0);return
	if at.distance_to(handle_position())<34:
		if model.held:tray_drag=true
		else:_lift()
		return
	if selected>=0:
		for slot:int in 4:
			if at.distance_to(cup_position(slot))<31:model.place(selected,slot);selected=-1;return
	for slot:int in 4:
		if at.distance_to(cup_position(slot))<31:drag=model.slots[slot];selected=drag;return
	if model.held and Rect2(tray_center()-Vector2(200,20),Vector2(400,65)).has_point(at):tray_drag=true;return
	if model.held and TARGET.has_point(at):model.start_delivery()
func _lift()->void:
	if model.paused:model.resume()
	elif model.running:model.pause()
	else:model.start_lift()
func release_at(at:Vector2)->void:
	if tray_drag:
		tray_drag=false
		if TARGET.has_point(at):model.start_delivery()
		queue_redraw();return
	if drag<0:return
	var cup:=drag;drag=-1
	if at.distance_to(origin)<9:return
	for slot:int in 4:
		if at.distance_to(cup_position(slot))<34:model.place(cup,slot);selected=-1;queue_redraw();return
	selected=-1;queue_redraw()
func _paper()->void:
	if not paper_open:paper_open=true;hint_level=maxi(1,hint_level)
	elif hint_level<3:hint_level+=1
	else:paper_open=false
func _text(value:String,at:Vector2,pixels:=16,color:=INK)->void:draw_string(font,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,pixels,color)
func _ellipse(at:Vector2,radius:Vector2,color:Color)->void:
	var poly:=PackedVector2Array()
	for i:int in 40:
		var a:=TAU*i/40;poly.append(at+Vector2(cos(a)*radius.x,sin(a)*radius.y))
	draw_colored_polygon(poly,color)
func _cup(cup:int,at:Vector2,scale_value:float,angle:=0.0)->void:
	draw_set_transform(at,angle);at=Vector2.ZERO
	var w:=24*scale_value;var h:=43*scale_value
	draw_arc(at+Vector2(w-2,-h/2),12*scale_value,-PI/2,PI/2,16,PAPER,5*scale_value)
	draw_rect(Rect2(at-Vector2(w,h),Vector2(w*2,h)),Color("c8d2cb"))
	var water_height:=h*(.4 if Model.WEIGHTS[cup]==1 else .8)
	draw_rect(Rect2(at+Vector2(-w+5,-water_height),Vector2(w*2-10,water_height-4)),Color("a77c4c"))
	_ellipse(at-Vector2(0,h),Vector2(w,7*scale_value),PAPER)
	_ellipse(at-Vector2(0,h),Vector2(w-5,4*scale_value),Color("5b6864"))
	draw_line(at-Vector2(w,h),at+Vector2(-w,0),PAPER,2*scale_value)
	if selected==cup:draw_arc(at-Vector2(0,h/2),33*scale_value,0,TAU,32,PAPER,2)
	draw_set_transform(Vector2.ZERO)
func _tray()->void:
	var poly:=PackedVector2Array()
	for p:Vector2 in [Vector2(-202,-26),Vector2(202,-26),Vector2(210,33),Vector2(-210,33)]:poly.append(local_point(p))
	var shadow:=poly.duplicate()
	for i:int in shadow.size():shadow[i]+=Vector2(0,9)
	draw_colored_polygon(shadow,INK);draw_colored_polygon(poly,Color("9d8060"));poly.append(poly[0]);draw_polyline(poly,PAPER,2)
	var scale_value:=tray_scale()
	for slot:int in 4:
		var p:=cup_position(slot)
		_ellipse(p+Vector2(0,5),Vector2(31,11)*scale_value,Color("c4b599"))
		_text(str(int(Model.ARMS[slot])),local_point(Vector2(Model.ARMS[slot]*70,24)),12)
		draw_line(local_point(Vector2(model.pivot*70,-20)),local_point(Vector2(model.pivot*70,28)),Color("e2dbc8"),2)
	# Arch handle shares the tray transform and its actual support point.
	var x:float=model.pivot*70
	draw_polyline(PackedVector2Array([local_point(Vector2(x-23,-10)),local_point(Vector2(x-23,-83)),local_point(Vector2(x+23,-83)),local_point(Vector2(x+23,-10))]),INK,7*scale_value)
	draw_line(local_point(Vector2(x-23,-83)),local_point(Vector2(x+23,-83)),PAPER,5*scale_value)
	for slot:int in 4:
		var cup:int=model.slots[slot]
		if cup!=drag:_cup(cup,cup_position(slot),scale_value,model.tilt)
func _draw()->void:
	if font==null:return
	draw_rect(Rect2(0,0,960,540),Color("29373b"));_text("茶水区 · 把四杯稳稳端过去",Vector2(32,37),22,PAPER)
	_text("移动杯子，抓住提手，再把托盘送到沙发茶几",Vector2(33,65),16,Color("bdc5bd"));_text("×",Vector2(898,47),28,PAPER)
	draw_rect(Rect2(35,97,890,422),Color("a99373"))
	for y:int in range(112,516,30):draw_line(Vector2(43,y),Vector2(916,y),Color("9c8565"),1)
	# Sofa, plant and tea table establish a real destination rather than a delivery button.
	draw_rect(Rect2(622,132,265,72),Color("677c73"));draw_rect(Rect2(608,194,291,46),Color("83978a"))
	for x:int in [608,877]:draw_rect(Rect2(x,171,22,80),Color("52695f"))
	draw_rect(Rect2(632,328,19,67),INK);draw_rect(Rect2(852,328,19,67),INK)
	draw_rect(Rect2(610,255,290,102),Color("7f6d56"));draw_rect(Rect2(610,249,290,98),Color("c1ac8a"))
	_ellipse(DESTINATION,Vector2(119,36),Color("ad9979"))
	draw_rect(Rect2(88,300,457,83),Color("806c51"));draw_rect(Rect2(88,289,457,82),Color("bca17b"))
	_tray()
	draw_line(Vector2(292,402),Vector2(351,402),INK,7)
	for x:float in [315.0,315.0+70.0/6.0]:draw_line(Vector2(x,391),Vector2(x,410),PAPER,2)
	draw_circle(Vector2(315+model.pivot*70,402),11,Color("698a86"))
	_text("支点 0" if model.pivot==0 else "支点 +1/6",Vector2(355,408),14)
	if model.paused:_text("Ⅱ",Vector2(555,300),22,PAPER)
	if drag>=0:_cup(drag,pointer,1)
	draw_rect(Rect2(55,459,150,48),PAPER);_text("备茶便笺",Vector2(77,490),16)
	draw_line(Vector2(239,494),Vector2(272,470),PAPER,7);draw_arc(Vector2(275,468),10,.4,5,18,PAPER,5)
	if paper_open:_text(HINTS[hint_level-1],Vector2(306,491),16,PAPER)
	elif not model.outcome.is_empty():_text(model.outcome,Vector2(360,491),16,PAPER)
