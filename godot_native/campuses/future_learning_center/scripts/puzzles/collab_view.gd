extends Control
const ApparatusStyle=preload("res://campuses/future_learning_center/scripts/apparatus_style.gd")
## Direct manipulation of a physical apparatus; all acceptance lives in Model.
signal closed
const Model=preload("res://campuses/future_learning_center/scripts/puzzles/collab_model.gd")
const CENTER:=Vector2(480,282)
const TRAY:=[Vector2(245,454),Vector2(355,454)]
const HINTS:=["每次改摆法后，哪些记录还对应现在这套装配？","保持装配不动，比较两侧来光与送料结果。","对照交接卡、试拍和装置开口，查看失败记录的具体路径。"]
var model=Model.new()
var hints:Array=HINTS.duplicate()
var apparatus_title:="两侧来光"
var apparatus_goal:="保持同一套装配，核对两侧试拍与送料。"
var font:Font
var drag:=-1
var selected:=-1
var pointer:=Vector2.ZERO
var pressed_at:=Vector2.ZERO
var touch_id:=-1
var hint_level:=-1
var show_records:=false
var action:=""
var feedback:=""
var pulse:=0.0
func _ready()->void:
	ApparatusStyle.configure_exit(self,close)
	mouse_filter=Control.MOUSE_FILTER_STOP
	font=ApparatusStyle.font()
	hide()
func open()->void:show();queue_redraw()
func close()->void:
	model.cancel();_cancel_pointer();hide();closed.emit()
func _cancel_pointer()->void:drag=-1;selected=-1;touch_id=-1;action=""
func _notification(what:int)->void:
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_APPLICATION_PAUSED]:model.pause();_cancel_pointer();queue_redraw()
func _process(dt:float)->void:
	if not visible:return
	model.step(dt);pulse+=minf(dt,.1);queue_redraw()
func projected(local:Vector2)->Vector2:return CENTER+Vector2(local.x,local.y*.66)
func position_of(i:int)->Vector2:
	return TRAY[i] if model.slots[i]<0 else projected(Model.SLOT_POINTS[model.slots[i]])
func lamp_at(side:int)->Vector2:return projected(model.rotate_point(Vector2(-210 if side==0 else 210,0)))
func camera_at()->Vector2:return projected(model.rotate_point(Vector2(0,-210)))
func lever_at()->Vector2:return Vector2(715,422)
func _input(event:InputEvent)->void:
	if ApparatusStyle.navigation_event(self,event):return
	if not visible:return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_ESCAPE:close();get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		if touch_id>=0 or event.device==InputEvent.DEVICE_ID_EMULATION:return
		if event.pressed:_press(get_global_transform_with_canvas().affine_inverse()*event.position)
		else:_release(get_global_transform_with_canvas().affine_inverse()*event.position)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and touch_id<0:pointer=get_global_transform_with_canvas().affine_inverse()*event.position;queue_redraw()
	elif event is InputEventScreenTouch:
		if event.index==touch_id and event.canceled:_cancel_pointer()
		elif event.pressed and not event.canceled and touch_id<0:touch_id=event.index;_press(get_global_transform_with_canvas().affine_inverse()*event.position)
		elif not event.pressed and event.index==touch_id:
			if event.canceled:_cancel_pointer()
			else:_release(get_global_transform_with_canvas().affine_inverse()*event.position);touch_id=-1
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and event.index==touch_id:pointer=get_global_transform_with_canvas().affine_inverse()*event.position;queue_redraw();get_viewport().set_input_as_handled()
func _press(at:Vector2)->void:
	pressed_at=at;pointer=at;action=""
	if Rect2(38,407,142,88).has_point(at):action="hint";return
	if Rect2(792,110,145,270).has_point(at):action="records";return
	if model.paused:action="resume";return
	if model.running:return
	for i:int in 2:
		if at.distance_to(position_of(i))<42:drag=i;selected=i;return
	for side:int in 2:
		if at.distance_to(lamp_at(side))<36:action="lamp_%d"%side;return
	if at.distance_to(camera_at())<36:action="camera";return
	if at.distance_to(lever_at())<40:action="feed";return
	if at.distance_to(Vector2(650,452))<34:action="rotate";return
	if selected>=0:
		for slot:int in 4:
			if at.distance_to(projected(Model.SLOT_POINTS[slot]))<40:action="slot_%d"%slot;return
func _release(at:Vector2)->void:
	pointer=at
	if drag>=0:
		var part:=drag;drag=-1
		if at.distance_to(pressed_at)<8:return # Selected part can next be placed by tapping a slot.
		var placed:=false
		for slot:int in 4:
			if at.distance_to(projected(Model.SLOT_POINTS[slot]))<42:placed=model.place(part,slot);break
		if not placed and Rect2(185,410,230,95).has_point(at):placed=model.place(part,-1)
		feedback="" if placed else "挡片回到原位；插槽被占用或未对齐。"
		selected=-1;queue_redraw();return
	if at.distance_to(pressed_at)>16:action="";return
	if action=="close":close()
	elif action=="hint":hint_level=(hint_level+1)%4;if_hint()
	elif action=="records":show_records=not show_records
	elif action=="resume":model.resume()
	elif action.begins_with("lamp_"):model.set_condition(int(action.right(1)))
	elif action=="camera":model.start("photo");feedback=""
	elif action=="feed":model.start("feed");feedback=""
	elif action=="rotate":model.rotate_fixture();feedback="夹具转过一格，旧记录保留。"
	elif action.begins_with("slot_") and selected>=0:
		model.place(selected,int(action.right(1)));selected=-1;feedback=""
	action="";queue_redraw()
func if_hint()->void:
	if hint_level==3:hint_level=-1
func text(value:String,at:Vector2,size_value:=16,color:=Color("ddd7c8"))->void:
	draw_string(font,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size_value,color)
func box(rect:Rect2,color:Color,height:=8.0)->void:
	draw_rect(Rect2(rect.position+Vector2(0,height),rect.size),Color("252d32"))
	draw_rect(rect,color);draw_rect(rect,Color("21292d"),false,2)
	draw_line(rect.position+Vector2(2,2),rect.position+Vector2(rect.size.x-2,2),color.lightened(.12),2)
func _baffle(i:int,at:Vector2,slot:int)->void:
	var horizontal:=slot<0 or slot%2==1
	var w:=76.0 if horizontal else 17.0
	var h:=15.0 if horizontal else 48.0
	draw_ellipse_shadow(at+Vector2(0,8),Vector2(w*.6,10))
	box(Rect2(at-Vector2(w/2,h/2+20),Vector2(w,h)),Color("767d79"),20)
	for screw:float in [-1.0,1.0]:draw_circle(at+Vector2(screw*(w/2-5),-h/2-15),2,Color("c5c8bb"))
	ApparatusStyle.grip(self,at,"drag",selected==i)
	if selected==i:draw_arc(at,44,0,TAU,32,Color("d1bc83"),2)
func draw_ellipse_shadow(at:Vector2,r:Vector2)->void:
	var poly:=PackedVector2Array()
	for i:int in 24:poly.append(at+Vector2(cos(TAU*i/24)*r.x,sin(TAU*i/24)*r.y))
	draw_colored_polygon(poly,Color(0,0,0,.18))
func _draw()->void:
	if font==null:return
	draw_rect(Rect2(0,0,960,540),Color("192329"))
	text(apparatus_title,Vector2(32,42),22)
	if hint_level>=0:text(apparatus_goal,Vector2(32,68),16)
	box(Rect2(185,111,590,302),Color("716750"),22)
	for x:int in range(200,770,24):draw_line(Vector2(x,115),Vector2(x,407),Color(0,0,0,.025),1)
	# The fixture is a square in its own plane, shown in the same oblique projection.
	var corners:=PackedVector2Array([projected(Vector2(-128,-128)),projected(Vector2(128,-128)),projected(Vector2(128,128)),projected(Vector2(-128,128))])
	draw_colored_polygon(corners,Color("aaa898"));draw_polyline(corners+PackedVector2Array([corners[0]]),Color("343c3d"),3)
	for slot:int in 4:
		var ends:=model.slot_segment(slot)
		draw_line(projected(ends[0]),projected(ends[1]),Color("444c4c"),7)
		draw_line(projected(ends[0])+Vector2(0,2),projected(ends[1])+Vector2(0,2),Color("c2c2b0"),2)
		if drag>=0:ApparatusStyle.target(self,Rect2(projected(Model.SLOT_POINTS[slot])-Vector2(24,24),Vector2(48,48)),true)
	_draw_apparatus_extra()
	# Lamps and direct light rays show the actual first obstruction.
	for side:int in 2:
		var source:=model.rotate_point(Vector2(-210 if side==0 else 210,0))
		var end:=Vector2.ZERO;var hit:=model.path_blocker(source,end)
		if hit>=0:
			var segment:=model.slot_segment(model.slots[hit]);end=Geometry2D.segment_intersects_segment(source,end,segment[0],segment[1])
		var lp:=projected(source)
		if side==model.condition:
			draw_line(lp,projected(end),Color("e0c989"),4)
			draw_circle(projected(end),7,Color(0.94,.83,.52,.4))
		box(Rect2(lp-Vector2(18,20),Vector2(36,30)),Color("434e54"),8)
		draw_circle(lp,10,Color("e0c989") if side==model.condition else Color("74766c"))
		text("甲" if side==0 else "乙",lp+Vector2(-8,35),14)
	var camera:=camera_at()
	draw_dashed_line(camera,CENTER,Color("7fa1aa"),2,8)
	box(Rect2(camera-Vector2(23,20),Vector2(46,30)),Color("34464c"),12);draw_circle(camera,12,Color("172831"));draw_circle(camera,5,Color("78959a"))
	var feed_start:=model.rotate_point(Vector2(0,210));var feed_end:=Vector2.ZERO
	for edge:float in [-20.0,20.0]:draw_line(projected(feed_start+model.rotate_point(Vector2(edge,0))),projected(feed_end+model.rotate_point(Vector2(edge,0))),Color("414b4d"),5)
	var carriage:=projected(feed_start.lerp(feed_end,model.travel))
	box(Rect2(carriage-Vector2(19,14),Vector2(38,25)),Color("9b7555"),12)
	box(Rect2(CENTER-Vector2(18,16),Vector2(36,30)),Color("c5c8b5"),4)
	draw_line(CENTER-Vector2(12,0),CENTER+Vector2(12,0),Color("48575a"),2);draw_line(CENTER-Vector2(0,9),CENTER+Vector2(0,9),Color("48575a"),2)
	for i:int in 2:
		if drag!=i:_baffle(i,position_of(i),model.slots[i])
	box(Rect2(185,423,230,62),Color("4b514d"),8)
	for i:int in 2:
		if model.slots[i]<0 and drag!=i:_baffle(i,TRAY[i],-1)
	var lever:=lever_at()
	draw_circle(lever+Vector2(0,13),26,Color("303b40"));draw_line(lever+Vector2(0,13),lever+Vector2(0,-21 if model.running else -8),Color("b4b6aa"),8);draw_circle(lever+Vector2(0,-21 if model.running else -8),11,Color("6a5145"));text("送料",lever+Vector2(-17,51),14)
	draw_arc(Vector2(650,452),23,-PI*.7,PI*.7,32,Color("a5aaa0"),6);draw_circle(Vector2(650,452)+Vector2(17,17),8,Color("bda16c"));text("夹具",Vector2(631,493),14)
	ApparatusStyle.grip(self,camera,"press",model.running)
	ApparatusStyle.grip(self,lever,"press",model.running)
	ApparatusStyle.grip(self,Vector2(650,452),"press")
	# Physical paper cards, opened only on request.
	box(Rect2(38,417,132,70),Color("c9b992"),3);text("交接卡",Vector2(63,448),16,Color("343a3a"))
	box(Rect2(798,123,130,240),Color("c6c1aa"),4)
	text("试拍记录",Vector2(811,149),17,Color("303e40"))
	var row:=0
	for key:String in ["photo_a","photo_b","feed"]:
		var y:=190+row*48;box(Rect2(810,y,106,36),Color("d7d2be"),2)
		var r:Dictionary=model.receipts.get(key,{})
		text({"photo_a":"甲侧","photo_b":"乙侧","feed":"送料"}[key],Vector2(816,y+23),14,Color("374447"))
		if not r.is_empty():
			if r.passed:draw_circle(Vector2(894,y+17),7,Color("526b60"));draw_line(Vector2(888,y+17),Vector2(892,y+21),Color("dfdfcb"),2);draw_line(Vector2(892,y+21),Vector2(900,y+12),Color("dfdfcb"),2)
			else:draw_line(Vector2(889,y+11),Vector2(901,y+23),Color("875f4c"),3);draw_line(Vector2(901,y+11),Vector2(889,y+23),Color("875f4c"),3)
		row+=1
	if show_records:
		box(Rect2(468,74,450,100),Color("d3c5a5"),3)
		text("装配 %d · 夹具 %d · 旧记录 %d"%[model.configuration_revision,model.fixture_revision,model.history.size()],Vector2(482,153),14,Color("3c4746"))
		var last:Dictionary=model.history.back() if not model.history.is_empty() else {}
		text("没有历史试验" if last.is_empty() else "%s · 装配 %d / 夹具 %d · %s"%[last.kind,last.configuration_revision,last.fixture_revision,"成立" if last.passed else "未成立"],Vector2(482,113),16,Color("3c4746"))
	if hint_level>=0:
		box(Rect2(36,333,712,65),Color("d3c5a5"),3);text("H%d  %s"%[hint_level+1,hints[hint_level]],Vector2(50,371),16,Color("3c4746"))
	var status:String=feedback if not feedback.is_empty() else model.outcome
	if model.current_passed():status="同一装配下，两侧试拍与送料均成立。"
	if model.paused:status="试验暂停 · 轻触装置继续"
	if not status.is_empty():text(status,Vector2(32,524),16)
	if drag>=0:_baffle(drag,pointer,-1)
func _draw_apparatus_extra()->void:pass
