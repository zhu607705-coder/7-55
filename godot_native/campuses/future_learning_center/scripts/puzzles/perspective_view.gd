extends Control
const ApparatusStyle=preload("res://campuses/future_learning_center/scripts/apparatus_style.gd")
signal closed
const Model=preload("res://campuses/future_learning_center/scripts/puzzles/perspective_model.gd")
const INK=ApparatusStyle.INK
const PAPER=ApparatusStyle.PAPER
const CELLS:=[Vector2(422,230),Vector2(548,230),Vector2(422,337),Vector2(548,337)]
const FEET:=[Vector2(485,126),Vector2(485,431),Vector2(643,282)]
const PHOTOS:=[Vector2(176,185),Vector2(176,361),Vector2(790,185)]
var model=Model.new()
var font:Font
var drag:=-1
var photo_drag:=-1
var selected:=-1
var touch_action_pending:=false
var touch_action_origin:=Vector2.ZERO
var touch_id:=-1
var pointer:=Vector2.ZERO
var origin:=Vector2.ZERO
var paper_open:=false
var hint_level:=0
var focus_index:=0
var camera_position:=Vector2(485,126)
const HINTS:=["两份记录是从同一侧拍的吗？","保持一个模型不动，换到对面看看缺口。","用固定缺口对齐两张纸，行与列都要一起换。"]
func _ready()->void:
	ApparatusStyle.configure_exit(self,close)
	mouse_filter=Control.MOUSE_FILTER_STOP;focus_mode=Control.FOCUS_ALL
	font=ApparatusStyle.font();size=Vector2(960,540);hide()
func open()->void:cancel_pointer();model.resume();show();grab_focus();queue_redraw()
func close()->void:model.cancel();cancel_pointer();hide();closed.emit()
func cancel_pointer()->void:touch_action_pending=false;drag=-1;photo_drag=-1;selected=-1;touch_id=-1;queue_redraw()
func _notification(what:int)->void:
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_APPLICATION_PAUSED]:model.pause();cancel_pointer()
func _process(dt:float)->void:
	if visible:
		if not model.paused:camera_position=camera_position.move_toward(FEET[model.observer],maxf(0,dt)*700)
		model.step(dt);queue_redraw()
func _gui_input(event:InputEvent)->void:
	if not visible:return
	if event is InputEventScreenTouch:
		if event.index==touch_id and event.canceled:model.cancel();cancel_pointer()
		elif event.pressed and not event.canceled and touch_id<0:touch_id=event.index;_touch_begin(event.position)
		elif not event.pressed and event.index==touch_id:
			if event.canceled:model.cancel();cancel_pointer()
			else:_touch_finish(event.position)
			touch_id=-1
		accept_event()
	elif event is InputEventScreenDrag and event.index==touch_id:
		# A selected-piece tap may become a drag of the occupied destination.
		if touch_action_pending and _touch_slot(touch_action_origin) and event.position.distance_to(touch_action_origin)>18:
			touch_action_pending=false;selected=-1;press_at(touch_action_origin)
		pointer=event.position;queue_redraw();accept_event()
	elif event is InputEventMouse and event.device==InputEvent.DEVICE_ID_EMULATION:return
	elif event is InputEventMouseButton and touch_id<0 and event.button_index==MOUSE_BUTTON_LEFT:
		if event.pressed:press_at(event.position)
		else:release_at(event.position)
		accept_event()
	elif event is InputEventMouseMotion and touch_id<0:pointer=event.position;queue_redraw()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode==KEY_ESCAPE:close()
		elif event.keycode==KEY_TAB:focus_index=posmod(focus_index+(-1 if event.shift_pressed else 1),10)
		elif event.keycode in [KEY_ENTER,KEY_SPACE]:
			if focus_index<4:selected=model.slots[focus_index]
			elif focus_index<7:model.observe(focus_index-4)
			elif focus_index==7:_expose()
			elif focus_index==8:_paper()
			else:model.undo()
		elif selected>=0 and event.keycode in [KEY_1,KEY_2,KEY_3,KEY_4]:model.place(selected,int(event.keycode)-int(KEY_1));selected=-1
		queue_redraw();accept_event()
func press_at(at:Vector2)->void:
	pointer=at;origin=at
	if Rect2(55,463,150,48).has_point(at):_paper();return
	if Rect2(225,461,65,50).has_point(at):model.undo();return
	if Rect2(722,365,140,70).has_point(at):_expose();return
	for photo:int in 3:
		if Rect2(PHOTOS[photo]-Vector2(69,64),Vector2(138,128)).has_point(at):
			if photo==2 and not model.extension:model.set_extension(true)
			else:photo_drag=photo
			return
	for side:int in (3 if model.extension else 2):
		if at.distance_to(FEET[side])<31:model.observe(side);return
	for slot:int in 4:
		if at.distance_to(CELLS[slot])<47:
			if selected>=0:model.place(selected,slot);selected=-1
			else:drag=model.slots[slot];selected=drag
			return
func release_at(at:Vector2)->void:
	if photo_drag>=0:
		var photo:=photo_drag;photo_drag=-1
		if at.distance_to(PHOTOS[photo])<115:model.rotate_paper(photo)
		return
	if drag<0:return
	var piece:=drag;drag=-1
	if at.distance_to(origin)<9:return
	for slot:int in 4:
		if at.distance_to(CELLS[slot])<48:model.place(piece,slot);selected=-1;return
	selected=-1
func _expose()->void:
	if model.paused:model.resume()
	elif camera_position.distance_to(FEET[model.observer])<2:model.start()
func _paper()->void:
	if not paper_open:paper_open=true;hint_level=maxi(1,hint_level)
	elif hint_level<3:hint_level+=1
	else:paper_open=false
func _text(value:String,at:Vector2,pixels:=16,color:=INK)->void:draw_string(font,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,pixels,color)
func _shape(piece:int,at:Vector2,s:=1.0)->void:
	var color:=Color("769492") if piece%2==0 else Color("b89269")
	if piece==0:
		draw_circle(at+Vector2(0,4)*s,23*s,INK);draw_circle(at,23*s,color);draw_arc(at,17*s,PI,TAU,16,PAPER,2*s)
	elif piece==1:
		draw_colored_polygon(PackedVector2Array([at+Vector2(-24,20)*s,at+Vector2(24,20)*s,at+Vector2(0,-28)*s]),color)
		draw_line(at+Vector2(0,-28)*s,at+Vector2(-24,20)*s,PAPER,2*s)
	elif piece==2:
		draw_rect(Rect2(at-Vector2(23,21)*s,Vector2(46,47)*s),INK);draw_rect(Rect2(at-Vector2(23,25)*s,Vector2(46,45)*s),color);draw_line(at-Vector2(21,23)*s,at+Vector2(21,-23)*s,PAPER,2*s)
	else:
		draw_rect(Rect2(at-Vector2(10,25)*s,Vector2(20,50)*s),color);draw_rect(Rect2(at-Vector2(25,10)*s,Vector2(50,20)*s),color)
func _notch(turns:int,s:=1.0)->void:
	var p:=Vector2(0,-49).rotated(turns*PI/2)*s
	draw_circle(p,7*s,INK);draw_line(p+Vector2(-4,0),p+Vector2(4,0),PAPER,2*s)
func _photo(id:int)->void:
	draw_set_transform(PHOTOS[id],model.paper_turns[id]*PI/2)
	draw_rect(Rect2(-65,-60,130,120),PAPER)
	for slot:int in 4:
		var at:=Vector2(-28+(slot%2)*56,-24+(slot/2)*51)
		draw_rect(Rect2(at-Vector2(24,23),Vector2(48,46)),Color("cfc8b5"))
		if Model.CONSTRAINTS[id].has(slot):_shape(Model.CONSTRAINTS[id][slot],at,.58)
		else:draw_line(at-Vector2(15,15),at+Vector2(15,15),Color("ac9b7d"),2)
	_notch(Model.TURNS[id]);draw_set_transform(Vector2.ZERO)
func _draw()->void:
	if font==null:return
	draw_rect(Rect2(0,0,960,540),Color("29373b"));_text("团队工作室 · 观察台",Vector2(32,37),22,PAPER)
	if paper_open:_text("让同一摆位符合两侧的局部记录",Vector2(33,65),16,Color("bdc5bd"))
	draw_rect(Rect2(35,94,890,425),Color("a58e6e"))
	for y:int in range(111,516,29):draw_line(Vector2(43,y),Vector2(916,y),Color("978060"),1)
	draw_rect(Rect2(350,170,270,223),INK);draw_rect(Rect2(350,160,270,223),Color("c6b795"))
	draw_circle(Vector2(485,161),10,INK)
	for slot:int in 4:
		draw_rect(Rect2(CELLS[slot]-Vector2(53,43),Vector2(106,86)),Color("b8a987"))
		if model.slots[slot]!=drag:_shape(model.slots[slot],CELLS[slot])
		if drag>=0:ApparatusStyle.target(self,Rect2(CELLS[slot]-Vector2(48,38),Vector2(96,76)),pointer.distance_to(CELLS[slot])<48)
		if selected==model.slots[slot]:draw_rect(Rect2(CELLS[slot]-Vector2(50,41),Vector2(100,82)),PAPER,false,2)
	for side:int in (3 if model.extension else 2):
		var at:Vector2=FEET[side]
		for x:int in [-9,9]:draw_line(at+Vector2(x,-9),at+Vector2(x,10),Color("d1c4a5"),9)
		ApparatusStyle.grip(self,at,"press",model.observer==side)
		if model.observer==side:draw_arc(at,27,0,TAU,24,PAPER,2)
	draw_circle(camera_position,7,INK)
	_photo(0);_photo(1)
	for photo:int in (3 if model.extension else 2):ApparatusStyle.grip(self,PHOTOS[photo]+Vector2(48,43),"rotate",photo_drag==photo)
	if model.extension:_photo(2)
	else:
		draw_rect(Rect2(722,129,136,116),Color("c2b59a"));draw_line(Vector2(722,129),Vector2(790,196),PAPER,2);draw_line(Vector2(858,129),Vector2(790,196),PAPER,2)
	_text("北侧照片",Vector2(143,265),14);_text("南侧手绘",Vector2(143,443),14);_text("短边记录",Vector2(754,265),14)
	# The camera monitor shows the current model through the selected observer transform.
	draw_rect(Rect2(719,285,146,138),INK)
	var observed:Array[int]=model.observed(model.observer)
	for slot:int in 4:_shape(observed[slot],Vector2(756+(slot%2)*68,316+(slot/2)*61),.52)
	draw_rect(Rect2(724,411,135,22),Color("718680"));draw_circle(Vector2(839,412 if model.running else 406),10,Color("b89269"))
	ApparatusStyle.grip(self,Vector2(839,406),"press",model.running)
	if model.running:draw_line(Vector2(725,440),Vector2(725+130*model.elapsed/.55,440),PAPER,3)
	for side:int in (3 if model.extension else 2):
		var r:Dictionary=model.receipts.get(side,{})
		_text("—" if r.is_empty() else ("○" if r.passed else "×"),Vector2(707+side*62,459),20,PAPER)
	draw_rect(Rect2(55,467,150,42),PAPER);_text("观察便笺",Vector2(77,495),16)
	draw_line(Vector2(238,494),Vector2(271,470),PAPER,7);draw_arc(Vector2(274,468),10,.4,5,18,PAPER,5)
	if paper_open:_text(HINTS[hint_level-1],Vector2(305,495),15,PAPER)
	elif not model.outcome.is_empty():_text(model.outcome,Vector2(356,495),16,PAPER)
	if drag>=0:_shape(drag,pointer)

func _touch_begin(at:Vector2)->void:
	touch_action_origin=at;touch_action_pending=Rect2(55,463,150,48).has_point(at) or Rect2(225,461,65,50).has_point(at) or Rect2(722,365,140,70).has_point(at) or (not model.extension and Rect2(PHOTOS[2]-Vector2(69,64),Vector2(138,128)).has_point(at)) or _touch_observer(at) or _touch_slot(at)
	if not touch_action_pending:press_at(at)
func _touch_finish(at:Vector2)->void:
	if touch_action_pending:
		touch_action_pending=false
		if at.distance_to(touch_action_origin)>18:return
		press_at(touch_action_origin)
	release_at(at)
func _touch_observer(at:Vector2)->bool:
	for side:int in (3 if model.extension else 2):
		if at.distance_to(FEET[side])<31:return true
	return false
func _touch_slot(at:Vector2)->bool:
	if selected<0:return false
	for cell:Vector2 in CELLS:
		if at.distance_to(cell)<47:return true
	return false
