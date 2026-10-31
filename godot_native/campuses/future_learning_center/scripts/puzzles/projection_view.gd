extends Control
const ApparatusStyle=preload("res://campuses/future_learning_center/scripts/apparatus_style.gd")
signal closed
const Model=preload("res://campuses/future_learning_center/scripts/puzzles/projection_model.gd")
const PAPER=ApparatusStyle.PAPER
const INK=ApparatusStyle.INK
const COLORS:=[Color("6f9292"),Color("bb936b")]
var model=Model.new()
var font:Font
var selected:=-1
var drag:=-1
var touch_action_pending:=false
var touch_action_origin:=Vector2.ZERO
var touch_id:=-1
var pointer:=Vector2.ZERO
var origin:=Vector2.ZERO
var original_depth:=0
var original_height:=0
var mask_drag:=false
var drag_kind:=""
var projected_motion:=Vector2.ZERO
var last_motion:=Vector2.ZERO
var focus_index:=0
var paper_open:=false
var hint_level:=0
const HINTS:=["正面轮廓相同，侧面也相同吗？","保持高度不变，只沿前后滑槽移动一片。","对照两个目标的高度边界与前后跨度。"]
func _ready()->void:
	ApparatusStyle.configure_exit(self,close)
	mouse_filter=Control.MOUSE_FILTER_STOP;focus_mode=Control.FOCUS_ALL
	font=ApparatusStyle.font();size=Vector2(960,540);hide()
func open()->void:cancel_pointer();model.resume();show();grab_focus();queue_redraw()
func close()->void:model.cancel();model.pause();cancel_pointer();hide();closed.emit()
func cancel_pointer()->void:touch_action_pending=false;model.cancel_drag();drag=-1;selected=-1;mask_drag=false;touch_id=-1;queue_redraw()
func _notification(what:int)->void:
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_APPLICATION_PAUSED]:model.pause();cancel_pointer()
func _process(dt:float)->void:
	if visible:model.step(dt);queue_redraw()
func project_point(p:Vector3)->Vector2:
	var x:=p.x-1.5;var y:=p.y-1.5
	var right:=x*cos(model.angle)+y*sin(model.angle)
	var depth:=-x*sin(model.angle)+y*cos(model.angle)
	return Vector2(340+right*50,310+depth*18-p.z*47)
func slot_point(piece:int,depth:float)->Vector2:return Vector2(195+depth*65,387+piece*47)
func height_point(piece:int)->Vector2:return Vector2(490+piece*63,430-model.displayed_pose(piece).y*48)
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
	elif event is InputEventScreenDrag and event.index==touch_id:move_at(event.position);accept_event()
	elif event is InputEventMouse and event.device==InputEvent.DEVICE_ID_EMULATION:return
	elif event is InputEventMouseButton and touch_id<0 and event.button_index==MOUSE_BUTTON_LEFT:
		if event.pressed:press_at(event.position)
		else:release_at(event.position)
		accept_event()
	elif event is InputEventMouseMotion and touch_id<0:move_at(event.position)
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode==KEY_ESCAPE:close()
		elif event.keycode==KEY_TAB:focus_index=posmod(focus_index+(-1 if event.shift_pressed else 1),6)
		elif event.keycode in [KEY_ENTER,KEY_SPACE]:
			if focus_index<2:selected=focus_index
			elif focus_index==2:model.rotate_fixture()
			elif focus_index==3:_expose()
			elif focus_index==4:_paper()
			else:model.undo()
		elif selected>=0:
			if event.keycode==KEY_LEFT:model.place(selected,model.depths[selected]-1,model.heights[selected])
			elif event.keycode==KEY_RIGHT:model.place(selected,model.depths[selected]+1,model.heights[selected])
			elif event.keycode in [KEY_UP,KEY_DOWN]:model.place(selected,model.depths[selected],1 if event.keycode==KEY_UP else 0)
		queue_redraw();accept_event()
func press_at(at:Vector2)->void:
	pointer=at;origin=at
	if at.distance_to(Vector2(95,330))<35:model.rotate_fixture();return
	if Rect2(665,350,150,82).has_point(at):_expose();return
	if Rect2(56,461,150,52).has_point(at):_paper();return
	if Rect2(224,461,65,52).has_point(at):model.undo();return
	if Rect2(mask_position()-Vector2(49,22),Vector2(98,44)).has_point(at):mask_drag=true;return
	for i:int in 2:
		if at.distance_to(height_point(i))<24:_select_drag(i,"height");return
	for i:int in 2:
		if at.distance_to(slot_point(i,model.depths[i]))<24:_select_drag(i,"slider");return
	if selected>=0:
		for d:int in 4:
			if at.distance_to(slot_point(selected,d))<24:model.place(selected,d,model.heights[selected]);selected=-1;return
	# Visible solid cells select the same model-owned piece, never a separate sprite.
	for i:int in range(1,-1,-1):
		for cell:Vector3i in model.voxels(i):
			if at.distance_to(project_point(Vector3(cell)+Vector3(.5,.1,.5)))<24:_select_drag(i);return
func _select_drag(piece:int,kind:="body")->void:
	if not model.begin_drag(piece):return
	drag=piece;selected=piece;drag_kind=kind;original_depth=model.depths[piece];original_height=model.heights[piece]
	last_motion=origin;projected_motion=Vector2.ZERO
func move_at(at:Vector2)->void:
	pointer=at
	if drag>=0:
		var delta:=at-origin
		var axis:=Vector2(65,0) if drag_kind=="slider" else (Vector2(0,-48) if drag_kind=="height" else project_point(Vector3(0,1,0))-project_point(Vector3.ZERO))
		var amount:=delta.dot(axis)/axis.length_squared()
		model.update_drag(original_depth+(0 if drag_kind=="height" else amount),original_height+(amount if drag_kind=="height" else 0))
		var pose:=model.displayed_pose(drag)
		projected_motion=axis*((pose.y-original_height) if drag_kind=="height" else (pose.x-original_depth))
		last_motion=at
	queue_redraw()
func release_at(at:Vector2)->void:
	if mask_drag:
		mask_drag=false
		if model.view_side==0 and Rect2(632,148,112,110).has_point(at):model.set_extension(true)
		elif Rect2(765,450,125,62).has_point(at):model.set_extension(false)
		queue_redraw();return
	if drag<0:return
	var pose:=model.displayed_pose(drag)
	var axis:=Vector2(65,0) if drag_kind=="slider" else (Vector2(0,-48) if drag_kind=="height" else project_point(Vector3(0,1,0))-project_point(Vector3.ZERO))
	var snap:=absf((roundf(pose.y)-pose.y) if drag_kind=="height" else (roundf(pose.x)-pose.x))*axis.length()
	# Release cannot move the item; it can only close a small detent gap.
	if at.distance_to(last_motion)<=12 and at.distance_to(origin+projected_motion)<=18 and snap<=12:model.commit_drag()
	else:model.cancel_drag()
	drag=-1;selected=-1;queue_redraw()
func _expose()->void:
	if model.paused:model.resume()
	else:model.start()
func _paper()->void:
	if not paper_open:paper_open=true;hint_level=maxi(1,hint_level)
	elif hint_level<3:hint_level+=1
	else:paper_open=false
func _text(value:String,at:Vector2,pixels:=16,color:=INK)->void:draw_string(font,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,pixels,color)
func _cell(cell:Vector3,piece:int)->void:
	var c:=Vector3(cell);var color:Color=COLORS[piece]
	var face:=PackedVector2Array([project_point(c),project_point(c+Vector3(1,0,0)),project_point(c+Vector3(1,0,1)),project_point(c+Vector3(0,0,1))])
	var side:=PackedVector2Array([project_point(c),project_point(c+Vector3(0,1,0)),project_point(c+Vector3(0,1,1)),project_point(c+Vector3(0,0,1))])
	var top:=PackedVector2Array([project_point(c+Vector3(0,0,1)),project_point(c+Vector3(1,0,1)),project_point(c+Vector3(1,1,1)),project_point(c+Vector3(0,1,1))])
	draw_colored_polygon(face,color);draw_colored_polygon(side,color.darkened(.2));draw_colored_polygon(top,color.lightened(.2))
	if selected==piece:face.append(face[0]);draw_polyline(face,PAPER,2)
func _grid(at:Vector2,cells:Dictionary,side:int,mask:bool)->void:
	for x:int in 4:
		for z:int in 4:
			var cell:=Vector2i(x,z);var r:=Rect2(at+Vector2(x*21,(3-z)*21),Vector2(19,19))
			draw_rect(r,INK if cells.has(cell) else Color("d0cbbb"))
			if mask and not model.visible_cell(side,cell):draw_rect(r,Color("a3957c"));draw_line(r.position,r.end,PAPER,1)
func _draw()->void:
	if font==null:return
	draw_rect(Rect2(0,0,960,540),Color("29353b"));_text("X-Lab · 双向投影",Vector2(32,37),22,PAPER)
	if paper_open:_text("让两面轮廓同时吻合目标片",Vector2(33,65),16,Color("bcc5bd"))
	draw_rect(Rect2(35,96,890,424),Color("a48f70"))
	for y:int in range(112,515,28):draw_line(Vector2(43,y),Vector2(918,y),Color("988263"),1)
	_turntable()
	var cells:Array[Dictionary]=[]
	for i:int in 2:
		# Transparent support post remains under the same translated piece.
		var pose:=model.displayed_pose(i)
		var p:=Vector3(0 if i==0 else 2,pose.x,0)
		draw_line(project_point(p),project_point(p+Vector3(0,0,pose.y+.1)),Color("d0d6c9"),7)
		for cell:Vector3 in model.displayed_voxels(i):cells.append({"cell":cell,"piece":i,"depth":-cell.x*sin(model.angle)+cell.y*cos(model.angle)})
	cells.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return a.depth<b.depth)
	for entry:Dictionary in cells:_cell(entry.cell,entry.piece)
	for i:int in 2:
		draw_line(slot_point(i,0),slot_point(i,3),INK,9)
		for d:int in 4:draw_circle(slot_point(i,d),6,PAPER);_text(str(d),slot_point(i,d)+Vector2(-4,24),12)
		var h:=slot_point(i,model.displayed_pose(i).x);draw_circle(h+Vector2(0,3),17,INK);draw_circle(h,15,COLORS[i])
		_text("A" if i==0 else "B",Vector2(165,h.y+5),16)
		ApparatusStyle.grip(self,h,"horizontal",drag==i and drag_kind=="slider")
		draw_line(Vector2(490+i*63,382),Vector2(490+i*63,430),INK,7);draw_circle(height_point(i),15,COLORS[i])
		ApparatusStyle.grip(self,height_point(i),"vertical",drag==i and drag_kind=="height")
	draw_circle(Vector2(95,330),27,INK);draw_line(Vector2(95,330),Vector2(95,330)+Vector2(cos(model.angle),sin(model.angle))*24,PAPER,6)
	ApparatusStyle.grip(self,Vector2(95,330),"rotate")
	_text("0° / 90°",Vector2(62,378),13)
	draw_rect(Rect2(626,120,254,220),PAPER)
	_text("目标片",Vector2(646,146),16);_text("透光像",Vector2(762,146),16)
	_grid(Vector2(645,162),model.target(model.view_side),model.view_side,true)
	if model.settled() and drag<0:_grid(Vector2(762,162),model.projection(model.view_side),model.view_side,false)
	else:_text("移动中",Vector2(769,205),15)
	_text("正面" if model.view_side==0 else "侧面",Vector2(646,272),16)
	for side:int in 2:
		var r:Dictionary=model.receipts.get(side,{})
		_text(("正 " if side==0 else "侧 ")+("—" if r.is_empty() else ("○" if r.passed else "×")),Vector2(646+side*105,310),16)
	draw_rect(Rect2(665,377,140,47),INK)
	draw_rect(Rect2(676,365,48,14),Color("86938b"))
	draw_circle(Vector2(735,400),25,Color("86938b"));draw_circle(Vector2(735,400),18,INK);draw_circle(Vector2(735,400),10,Color("52747d"))
	draw_line(Vector2(730,392),Vector2(738,392),PAPER,2)
	draw_circle(Vector2(785,374 if model.running else 369),9,COLORS[1])
	ApparatusStyle.grip(self,Vector2(785,369),"press",model.running)
	if model.running:draw_line(Vector2(635,350),Vector2(635+235*model.elapsed/.6,350),PAPER,3)
	elif not model.outcome.is_empty():_text(model.outcome,Vector2(650,357),16)
	draw_rect(Rect2(56,467,150,42),PAPER);_text("观察笔记",Vector2(77,494),16)
	draw_line(Vector2(238,494),Vector2(269,472),PAPER,7);draw_arc(Vector2(272,470),10,.4,5,18,PAPER,5)
	draw_rect(Rect2(769,458,118,49),Color("8a775d"))
	draw_line(Vector2(772,460),Vector2(884,460),PAPER,2)
	_mask(pointer if mask_drag else mask_position())
	ApparatusStyle.grip(self,(pointer if mask_drag else mask_position())+Vector2(34,-6),"drag",mask_drag)
	if paper_open:_text(HINTS[hint_level-1],Vector2(300,494),15,PAPER)
	elif model.current_passed():_text("两面均已验证",Vector2(380,494),16,PAPER)
func _turntable()->void:
	# Fixed tabletop, rotating support geometry; the room camera does not turn.
	var ring:=PackedVector2Array()
	for i:int in 49:
		var a:=TAU*i/48;ring.append(Vector2(340+cos(a)*180,322+sin(a)*66))
	draw_colored_polygon(ring,Color("797d70"));draw_polyline(ring,PAPER,2)
func mask_position()->Vector2:
	if not model.extension:return Vector2(827,482)
	return Vector2(687,171) if model.view_side==0 else Vector2(680,285)
func _mask(at:Vector2)->void:
	# An opaque removable strip and metal clip, not a labelled command control.
	draw_rect(Rect2(at-Vector2(46,10)+Vector2(0,3),Vector2(92,22)),INK)
	draw_rect(Rect2(at-Vector2(46,10),Vector2(92,22)),Color("b2a184"))
	draw_line(at-Vector2(42,8),at+Vector2(42,-8),PAPER,1)
	draw_rect(Rect2(at+Vector2(31,-17),Vector2(9,21)),Color("6b7d79"))
	draw_line(at+Vector2(34,-14),at+Vector2(34,1),PAPER,2)

func _touch_begin(at:Vector2)->void:
	touch_action_origin=at;touch_action_pending=at.distance_to(Vector2(95,330))<35 or Rect2(665,350,150,82).has_point(at) or Rect2(56,461,150,52).has_point(at) or Rect2(224,461,65,52).has_point(at) or _touch_slot(at)
	if not touch_action_pending:press_at(at)
func _touch_finish(at:Vector2)->void:
	if touch_action_pending:
		touch_action_pending=false
		if at.distance_to(touch_action_origin)>18:return
		press_at(touch_action_origin)
	release_at(at)
func _touch_slot(at:Vector2)->bool:
	if selected<0:return false
	for i:int in 2:
		if at.distance_to(height_point(i))<24 or at.distance_to(slot_point(i,model.depths[i]))<24:return false
	for d:int in 4:
		if at.distance_to(slot_point(selected,d))<24:return true
	return false
