extends Control
const ApparatusStyle=preload("res://campuses/future_learning_center/scripts/apparatus_style.gd")
signal closed
const Model=preload("res://campuses/future_learning_center/scripts/puzzles/machinery_model.gd")
const INK=ApparatusStyle.INK
const PAPER=ApparatusStyle.PAPER
const CLAMP_TRAY:=Vector2(170,400)
const BLANKS:=[Vector2(710,450),Vector2(840,450)]
const HINTS:=["碰停发生在刀路上，还是抽出通道里？","保持夹具不动，比较切断连接桥前后试件是否还保持定位。","将本次偏槽与轮廓片叠看，再看看夹具压住了哪一侧。"]
var model=Model.new()
var font:Font
var touch_id:=-1
var action:=""
var selected:=-1
var pointer:=Vector2.ZERO
var origin:=Vector2.ZERO
var part_origin:=0.0
var notebook:=false
var hint_level:=0
func _ready()->void:
	ApparatusStyle.configure_exit(self,close)
	font=ApparatusStyle.font();size=Vector2(960,540);mouse_filter=Control.MOUSE_FILTER_STOP;hide()
func open()->void:show();queue_redraw()
func close()->void:model.cancel();cancel_pointer();hide();closed.emit()
func cancel_pointer()->void:model.end_gesture();touch_id=-1;action="";selected=-1;queue_redraw()
func _notification(what:int)->void:
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_APPLICATION_PAUSED]:model.cancel();cancel_pointer()
func _process(dt:float)->void:
	if visible:model.step(minf(dt,.1));queue_redraw()
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
func path_distance(at:Vector2,line:PackedVector2Array)->float:
	var result:=INF
	for i:int in range(1,line.size()):result=minf(result,at.distance_to(Geometry2D.get_closest_point_to_segment(at,line[i-1],line[i])))
	return result
func press(at:Vector2)->void:
	origin=at;pointer=at;action=""
	if notebook:action="page" if Rect2(640,418,220,40).has_point(at) else "paper";return
	if Rect2(40,438,145,70).has_point(at):action="paper";return
	if at.distance_to(Vector2(262,464))<28:action="undo";return
	if model.running:
		if at.distance_to(model.cutter)<32:action="stop"
		return
	if at.distance_to(CLAMP_TRAY if model.clamp_slot<0 else model.clamp_rect().get_center())<40:action="clamp";return
	for i:int in 2:
		if at.distance_to(BLANKS[i])<43:action="blank";selected=i;return
	var nearest:=17.0
	for i:int in 3:
		if model.progress[i]>=1:continue
		var distance:=path_distance(at,model.path(i))
		if distance<nearest:nearest=distance;selected=i;action="cut"
	if action=="cut":return
	if model.part_rect().has_point(at):action="part";part_origin=model.part_rect().position.x;model.begin_gesture()
func motion(at:Vector2)->void:
	pointer=at
	if action=="part":model.extract_to(part_origin+at.x-origin.x)
	queue_redraw()
func release(at:Vector2)->void:
	if action=="clamp":
		if at.distance_to(CLAMP_TRAY)<42:model.place_clamp(-1)
		else:
			for i:int in 3:
				if at.distance_to(model.mirrored_rect(Model.CLAMPS[i]).get_center())<45:model.place_clamp(i);break
	elif action=="part":model.end_gesture()
	elif action=="blank" and Model.FRAME.has_point(at):model.reset(selected)
	elif action=="cut" and at.distance_to(origin)<14:model.start_cut(selected)
	elif at.distance_to(origin)<18:
		match action:
			"close":close()
			"undo":model.undo()
			"stop":model.cancel()
			"paper":notebook=not notebook
			"page":hint_level=mini(3,hint_level+1)
	action="";selected=-1;queue_redraw()
func text(value:String,at:Vector2,sz:=17,color:=INK)->void:draw_string(font,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,sz,color)
func slab(rect:Rect2,color:Color,depth:=7.0)->void:
	draw_rect(Rect2(rect.position+Vector2(0,depth),rect.size),color.darkened(.3));draw_rect(rect,color);draw_rect(rect,INK,false,1.5)
	draw_line(rect.position+Vector2(2,2),Vector2(rect.end.x-2,rect.position.y+2),color.lightened(.22),2)
func _piece()->void:
	var at:Vector2=model.part_rect().position
	if model.valid_cut(1):
		var polygon:=PackedVector2Array([Vector2(0,0),Vector2(105,0),Vector2(105,25),Vector2(120,25),Vector2(120,80),Vector2(0,80)])
		for i:int in polygon.size():
			if model.variant==1:polygon[i].x=120-polygon[i].x
			polygon[i]+=at
		draw_colored_polygon(polygon,Color("b4bb9a"));draw_polyline(polygon+PackedVector2Array([polygon[0]]),INK,2)
	else:slab(model.part_rect(),Color("b4bb9a"),5)
	for i:int in 3:
		if model.kerfs[i].size()<2:continue
		var line:=PackedVector2Array()
		for p:Vector2 in model.kerfs[i]:line.append(p+at)
		draw_polyline(line,Color("7e5343") if model.progress[i]>=1 and not model.valid_cut(i) else Color("44564d"),4)
	# The engraved handle remains on the physical part, not a UI extraction button.
	var handle:=at+Vector2(60,64)
	draw_line(handle-Vector2(15,0),handle+Vector2(15,0),INK,5)
func _draw()->void:
	if font==null:return
	draw_rect(Rect2(0,0,960,540),Color("c1c7bb"))
	for y:int in range(85,540,34):draw_line(Vector2(0,y),Vector2(960,y+8),Color("b3bdad"),1)
	text("机加工区 · 泡沫加工演示盒",Vector2(32,36),23);text("沿轮廓试切，再从通道里抽出同一件样品。",Vector2(33,65),16)
	slab(Rect2(74,134,812,270),Color("776e5e"),20)
	slab(Model.TRAY,Color("b7b69b"),4)
	# Outer frame supports the datum; a genuine opening exists only on the selected exit side.
	slab(Rect2(300,180,360,50),Color("a4b48f"),5)
	slab(Rect2(300,355,360,25),Color("a4b48f"),5)
	slab(model.mirrored_rect(Rect2(300,230,20,125)),Color("a4b48f"),5)
	var bridge:Rect2=model.mirrored_rect(Rect2(540 if model.bridge_intact() else 544,282,60 if model.bridge_intact() else 56,16))
	slab(bridge,Color("a4b48f"),4)
	_piece()
	for i:int in 3:
		var line:=model.path(i)
		for j:int in range(1,line.size()):draw_dashed_line(line[j-1],line[j],Color("e7e0bd"),2,5)
		if action=="cut" and selected==i:draw_polyline(line,Color(.88,.79,.48,.65),9)
	for i:int in 3:draw_rect(model.mirrored_rect(Model.CLAMPS[i]),Color("7d8979"),false,2)
	var clamp:Rect2=Rect2(CLAMP_TRAY-Vector2(18,34),Vector2(36,68)) if model.clamp_slot<0 else model.clamp_rect()
	if action=="clamp":clamp.position=pointer-clamp.size/2
	slab(clamp,Color("6c7b75"),8)
	var screw:=clamp.get_center();draw_circle(screw,12,INK);draw_line(screw-Vector2(17,0),screw+Vector2(17,0),Color("c8c8b2"),6)
	if model.cutter.is_finite():
		var p:Vector2=model.cutter
		draw_line(Vector2(p.x,133),p-Vector2(0,10),Color("78908c"),7)
		slab(Rect2(p-Vector2(15,37),Vector2(30,26)),Color("8fa49b"),6)
		draw_circle(p,7,Color("e3d4a3"));draw_circle(p,3,INK)
	if model.contact.is_finite():draw_arc(model.contact,17,0,TAU,24,Color("a2684c"),3)
	# Closed transparent guard, with all pieces still observable behind it.
	draw_rect(Rect2(270,145,425,244),Color(.65,.79,.75,.035));draw_rect(Rect2(270,145,425,244),Color("99b5a7"),false,2)
	text("封闭模拟 · 非真实机床控制",Vector2(308,123),14)
	text("夹具托盘",Vector2(135,448),14)
	for i:int in 2:
		var at:Vector2=pointer if action=="blank" and selected==i else BLANKS[i]
		slab(Rect2(at-Vector2(45,24),Vector2(90,48)),Color("b8bd9d"),5)
		draw_line(at+Vector2(-25 if i==0 else 25,0),at+Vector2(25 if i==0 else -25,0),INK,3)
		var tip:=at+Vector2(25 if i==0 else -25,0)
		draw_line(tip,tip+Vector2(-8 if i==0 else 8,-7),INK,3);draw_line(tip,tip+Vector2(-8 if i==0 else 8,7),INK,3)
		text("替换样坯",BLANKS[i]+Vector2(-30,45),14)
	slab(Rect2(40,443,145,65),PAPER,5);text("加工草片",Vector2(75,472),18);text("翻看失败件",Vector2(68,495),14)
	draw_arc(Vector2(262,464),21,.2,TAU-.5,24,INK,4);text("撤回",Vector2(246,502),14)
	if not model.outcome.is_empty():text(model.outcome,Vector2(318,475),16)
	if notebook:
		slab(Rect2(105,104,750,352),PAPER,8)
		text("轮廓片与本次切口",Vector2(132,140),23)
		text("轻触实际虚线刀路，观察刀头沿这段移动。",Vector2(132,183),17)
		text("抓夹具换夹持面；抓样件下缘横槽，沿通道抽出。",Vector2(132,218),17)
		for i:int in hint_level:text(HINTS[i],Vector2(132,265+i*39),17)
		text("翻下一页提示",Vector2(670,443),17)
