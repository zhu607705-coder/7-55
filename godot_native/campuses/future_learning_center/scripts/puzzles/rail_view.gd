extends Control
const ApparatusStyle=preload("res://campuses/future_learning_center/scripts/apparatus_style.gd")
signal closed
const Model=preload("res://campuses/future_learning_center/scripts/puzzles/rail_model.gd")
const INK=ApparatusStyle.INK
const PAPER=ApparatusStyle.PAPER
const COLORS:=[Color("688986"),Color("a78b65")]
var model=Model.new()
var font:Font
const TRAILER_TRAY:=Vector2(790,470)
var trailer_drag:=false
var trailer_selected:=false
var trailer_origin:=Vector2.ZERO
var coupling_blocked:=false
var selected:=-1
var drag:=-1
var touch_action_pending:=false
var touch_action_origin:=Vector2.ZERO
var touch_id:=-1
var pointer:=Vector2.ZERO
var origin:=Vector2.ZERO
var grab_offset:=Vector2.ZERO
var paper_open:=false
var hint_level:=0
var focus_index:=0
const HINTS:=["两辆车相遇时，哪段轨道同时被占住了？","停进侧线后，车尾是否还占着主轨？","对照车辆长度、支线刻度和接触边，留出通路。"]
func _ready()->void:
	ApparatusStyle.configure_exit(self,close)
	mouse_filter=Control.MOUSE_FILTER_STOP;focus_mode=Control.FOCUS_ALL
	font=ApparatusStyle.font();size=Vector2(960,540);hide()
func open()->void:cancel_pointer();show();grab_focus();queue_redraw()
func close()->void:model.cancel();cancel_pointer();hide();closed.emit()
func cancel_pointer()->void:touch_action_pending=false;model.cancel_drag();trailer_drag=false;trailer_selected=false;selected=-1;drag=-1;touch_id=-1;queue_redraw()
func _notification(what:int)->void:
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_APPLICATION_PAUSED]:model.pause();cancel_pointer()
func _process(dt:float)->void:
	if visible:model.step(minf(dt,.1));queue_redraw()
func cell_position(cell:int)->Vector2:return Model.point(cell)
func cart_position(id:int)->Vector2:
	var at:Vector2=model.pose(id)
	if model.running and model.cart==id:
		var next:int=model.next_cell(model.positions[id],model.destination)
		if model.auto_return:at=cell_position(model.edge_to[id]).lerp(cell_position(model.positions[id]),clampf(model.elapsed/.3,0,1))
		elif model.can_move(id,next):at=cell_position(model.positions[id]).lerp(cell_position(next),clampf(model.elapsed/.3,0,1))
	return at
func _gui_input(event:InputEvent)->void:
	if not visible:return
	if event is InputEventMouse and event.device==InputEvent.DEVICE_ID_EMULATION:return
	if event is InputEventScreenTouch:
		if event.canceled and event.index==touch_id:cancel_pointer();accept_event();return
		if event.pressed and not event.canceled and touch_id<0:touch_id=event.index;_touch_begin(event.position)
		elif not event.pressed and touch_id==event.index:
			if event.canceled:cancel_pointer()
			else:_touch_finish(event.position)
			touch_id=-1
		accept_event()
	elif event is InputEventScreenDrag and event.index==touch_id:motion_at(event.position);accept_event()
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and touch_id<0:
		if event.pressed:press_at(event.position)
		else:release_at(event.position)
		accept_event()
	elif event is InputEventMouseMotion and touch_id<0:motion_at(event.position)
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode==KEY_ESCAPE:close()
		elif event.keycode==KEY_TAB:focus_index=posmod(focus_index+(-1 if event.shift_pressed else 1),6)
		elif event.keycode in [KEY_ENTER,KEY_SPACE]:
			if focus_index<2:selected=focus_index
			elif focus_index==2:model.toggle_switch()
			elif focus_index==3:model.undo()
			elif focus_index==4:_paper()
			else:coupling_blocked=not model.couple_trailer(not model.extension)
		elif selected>=0:
			if event.keycode==KEY_LEFT:model.dispatch(selected,maxi(0,model.positions[selected]-1))
			elif event.keycode==KEY_RIGHT:model.dispatch(selected,mini(8,model.positions[selected]+1))
			elif event.keycode==KEY_UP:model.dispatch(selected,9)
			elif event.keycode==KEY_DOWN:model.dispatch(selected,4)
		queue_redraw();accept_event()
func press_at(at:Vector2)->void:
	pointer=at;origin=at
	if Rect2(52,442,164,65).has_point(at):_paper();return
	if Rect2(235,448,64,54).has_point(at):model.undo();return
	if at.distance_to(trailer_position())<36:
		if not model.running:trailer_drag=true;trailer_selected=true;trailer_origin=at
		return
	if trailer_selected and not model.extension and at.distance_to(cart_position(0))<42:
		coupling_blocked=not model.couple_trailer(true);trailer_selected=false;return
	if trailer_selected and model.extension and at.distance_to(TRAILER_TRAY)<45:
		model.couple_trailer(false);trailer_selected=false;return
	if switch_hit(at):model.toggle_switch();return
	for i:int in 2:
		if at.distance_to(cart_position(i))<36:
			if model.paused and model.cart==i:model.resume();return
			if model.running:model.pause();return
			if model.begin_drag(i):drag=i;selected=i;grab_offset=at-cart_position(i)
			return
	if selected>=0:_dispatch_at(selected,at)
func trailer_position()->Vector2:
	return model.tail_pose(0) if model.extension else TRAILER_TRAY
func motion_at(at:Vector2)->void:
	pointer=at
	if drag>=0:model.drag_to(at-grab_offset)
	queue_redraw()
func release_at(at:Vector2)->void:
	if trailer_drag:
		trailer_drag=false
		if trailer_origin.distance_to(at)<9:return
		var target:=TRAILER_TRAY if model.extension else cart_position(0)
		if at.distance_to(target)<46:coupling_blocked=not model.couple_trailer(not model.extension)
		trailer_selected=false;queue_redraw();return
	if drag<0:return
	var id:=drag;drag=-1
	model.end_drag();selected=id if origin.distance_to(pointer)<9 else -1;queue_redraw()
func _dispatch_at(id:int,at:Vector2)->void:
	for i:int in 10:
		if at.distance_to(cell_position(i))<38:
			model.dispatch(id,i);selected=-1;queue_redraw();return
	selected=-1;queue_redraw()
func _paper()->void:
	if not paper_open:paper_open=true;hint_level=maxi(1,hint_level)
	elif hint_level<3:hint_level+=1
	else:paper_open=false
	queue_redraw()
func _text(value:String,at:Vector2,sz:=16,color:=INK)->void:draw_string(font,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,sz,color)
func _track(a:Vector2,b:Vector2)->void:
	var normal:Vector2=(b-a).normalized().orthogonal()
	for i:int in 12:
		var p:=a.lerp(b,float(i)/11);draw_line(p-normal*23,p+normal*23,Color("8d806c"),7)
	for side:int in [-1,1]:
		draw_line(a+normal*side*15,b+normal*side*15,INK,5)
		draw_line(a+normal*side*15-Vector2(0,1),b+normal*side*15-Vector2(0,1),Color("bdc2bb"),2)
func _cart(id:int,at:Vector2)->void:
	if model.lengths[id]==2:
		var tail:Vector2=model.tail_pose(id)
		if model.running and model.cart==id:
			var next:int=model.next_cell(model.positions[id],model.destination)
			if model.auto_return:tail=cell_position(model.occupied(id,model.edge_to[id])[1]).lerp(cell_position(model.occupied(id)[1]),clampf(model.elapsed/.3,0,1))
			elif model.can_move(id,next):tail=cell_position(model.occupied(id)[1]).lerp(cell_position(model.occupied(id,next)[1]),clampf(model.elapsed/.3,0,1))
		draw_line(tail,at,INK,8);_body(id,tail,true)
	_body(id,at,false)
func _body(id:int,at:Vector2,tail:bool)->void:
	for x:int in [-21,21]:
		for y:int in [-20,20]:draw_rect(Rect2(at+Vector2(x-5,y),Vector2(10,9)),INK)
	draw_rect(Rect2(at-Vector2(33,20),Vector2(66,49)),INK)
	draw_rect(Rect2(at-Vector2(33,26),Vector2(66,44)),COLORS[id])
	draw_line(at-Vector2(31,24),at+Vector2(31,-24),PAPER,2)
	if tail:draw_rect(Rect2(at-Vector2(23,13),Vector2(46,23)),PAPER)
	elif id==0:
		draw_circle(at-Vector2(0,4),12,PAPER);draw_circle(at-Vector2(0,4),5,INK)
	else:draw_rect(Rect2(at-Vector2(12,16),Vector2(24,24)),PAPER)
func _draw()->void:
	if font==null:return
	draw_rect(Rect2(0,0,960,540),Color("c9c8b9"))
	draw_rect(Rect2(36,91,888,431),Color("4b514b"))
	draw_rect(Rect2(36,81,888,427),Color("b4aa92"))
	for y:int in range(100,506,18):draw_line(Vector2(39,y),Vector2(920,y+4),Color("b0a58d"),1)
	_text("研讨间 2 · 双向运输",Vector2(44,49),23)
	if paper_open:_text("让两辆车带着原零件交换终点",Vector2(44,73),15)
	_track(cell_position(0)-Vector2(38,0),cell_position(8)+Vector2(38,0));_track(cell_position(4),cell_position(9))
	for i:int in 9:
		_text(str(i),cell_position(i)+Vector2(-4,51),12)
		if selected>=0:draw_circle(cell_position(i),5,Color("e8e5d7"))
	_text("1 格",Vector2(460,133),14)
	for i:int in [0,8]:
		draw_line(cell_position(i)+Vector2((-42 if i==0 else 42),-27),cell_position(i)+Vector2((-42 if i==0 else 42),27),INK,7)
	_text("■",Vector2(148,395),23,COLORS[1]);_text("●",Vector2(790,395),23,COLORS[0])
	# The switch blade and its lever are physical track parts.
	draw_line(Vector2(480,310),Vector2(480,275) if model.siding else Vector2(515,310),Color("deded0"),6)
	draw_circle(Vector2(580,210),22,INK)
	draw_line(Vector2(580,210),Vector2(559,181) if model.siding else Vector2(603,181),PAPER,7)
	draw_circle(Vector2(559,181) if model.siding else Vector2(603,181),10,Color("76664e"))
	for i:int in 2:
		_cart(i,cart_position(i))
		ApparatusStyle.grip(self,cart_position(i)+Vector2(0,15),"horizontal",drag==i)
		if selected==i or (model.paused and model.cart==i):draw_arc(cart_position(i),42,0,TAU,32,PAPER,2)
	ApparatusStyle.grip(self,Vector2(559,181) if model.siding else Vector2(603,181),"press")
	if drag>=0:
		for cell:int in 10:ApparatusStyle.target(self,Rect2(cell_position(cell)-Vector2(25,24),Vector2(50,48)),pointer.distance_to(cell_position(cell))<30)
	if model.blocked>=0:
		var p:=cell_position(model.blocked);draw_line(p-Vector2(13,13),p+Vector2(13,13),Color("944f44"),4);draw_line(p+Vector2(-13,13),p+Vector2(13,-13),Color("944f44"),4)
	draw_rect(Rect2(55,446,155,54),PAPER);_text("试用者笔记",Vector2(70,479),16)
	draw_line(Vector2(249,478),Vector2(278,458),INK,8);draw_arc(Vector2(280,456),12,.4,5,16,INK,5)
	# The spare wagon occupies a shallow loading cradle, not an action button.
	for x:int in [-45,45]:draw_line(TRAILER_TRAY+Vector2(x,-27),TRAILER_TRAY+Vector2(x,29),INK,4)
	draw_line(TRAILER_TRAY+Vector2(-45,29),TRAILER_TRAY+Vector2(45,29),INK,4)
	if not model.extension and not trailer_drag:_body(0,TRAILER_TRAY,true)
	if trailer_drag:_body(0,pointer,true)
	ApparatusStyle.grip(self,pointer if trailer_drag else trailer_position(),"drag",trailer_drag)
	if trailer_selected and not trailer_drag:draw_arc(trailer_position(),39,0,TAU,32,PAPER,2)
	if coupling_blocked:
		var tail:=cart_position(0)-Vector2(80,0)
		draw_line(tail-Vector2(12,12),tail+Vector2(12,12),Color("944f44"),3)
		draw_line(tail+Vector2(-12,12),tail+Vector2(12,-12),Color("944f44"),3)
	if model.completed:_text("已完成运输" + (" · 长载荷" if model.extension_completed else ""),Vector2(350,482),17)
	if paper_open:
		draw_rect(Rect2(58,100,340,120),PAPER)
		_text("试用者笔记 · "+str(hint_level),Vector2(73,126),16)
		var text_value:String=HINTS[hint_level-1]
		_text(text_value.substr(0,18),Vector2(73,159),16);_text(text_value.substr(18),Vector2(73,186),16)

func _touch_begin(at:Vector2)->void:
	touch_action_origin=at;touch_action_pending=Rect2(52,442,164,65).has_point(at) or Rect2(235,448,64,54).has_point(at) or switch_hit(at) or (model.running and (at.distance_to(cart_position(0))<36 or at.distance_to(cart_position(1))<36)) or (selected>=0 and at.distance_to(cart_position(0))>=36 and at.distance_to(cart_position(1))>=36 and at.distance_to(trailer_position())>=36)
	if not touch_action_pending:press_at(at)
func _touch_finish(at:Vector2)->void:
	if touch_action_pending:
		touch_action_pending=false
		if at.distance_to(touch_action_origin)>18:return
		press_at(touch_action_origin)
	release_at(at)

func switch_hit(at:Vector2)->bool:
	var knob:=Vector2(559,181) if model.siding else Vector2(603,181)
	return at.distance_to(knob)<27 or at.distance_to(Vector2(580,210))<38
