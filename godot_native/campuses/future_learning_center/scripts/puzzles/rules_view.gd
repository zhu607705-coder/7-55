extends Control
signal closed
const Model=preload("res://campuses/future_learning_center/scripts/puzzles/rules_model.gd")
const INK:=Color("29343c")
const PAPER:=Color("e9e5d6")
const TILE:=Color("b4b9aa")
const SLOTS:=[Vector2(370,225),Vector2(470,225),Vector2(660,225),Vector2(760,225)]
const HANDLES:=[Vector2(425,338),Vector2(715,338)]
const HINTS:=["旧例中的形状与填纹，是否总是一起变化？","固定一种属性，只改变另一种，再比较结果。","对照两份预测草图，找出它们判断不同的配对。"]
var model=Model.new()
var font:Font
var selected:=-1
var drag:=-1
var touch_id:=-1
var pointer:=Vector2.ZERO
var origin:=Vector2.ZERO
var paper_open:=false
var hint_level:=0
var focus_index:=0
func _ready()->void:
	mouse_filter=Control.MOUSE_FILTER_STOP;focus_mode=Control.FOCUS_ALL
	font=load("res://scripts/ui/native_typography.gd").body_font();size=Vector2(960,540);hide()
func open()->void:cancel_pointer();show();grab_focus();queue_redraw()
func close()->void:model.cancel();cancel_pointer();hide();closed.emit()
func cancel_pointer()->void:selected=-1;drag=-1;touch_id=-1;queue_redraw()
func _notification(what:int)->void:
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_APPLICATION_PAUSED]:model.pause();cancel_pointer()
func _process(dt:float)->void:
	if visible:model.step(minf(dt,.1));queue_redraw()
func tile_position(tile:int)->Vector2:
	var slot:int=model.slots.find(tile)
	return SLOTS[slot] if slot>=0 else Vector2(110+(tile%2)*90,182+(tile/2)*102)
func _gui_input(event:InputEvent)->void:
	if not visible:return
	if event is InputEventScreenTouch:
		if event.pressed and touch_id<0:touch_id=event.index;press_at(event.position)
		elif not event.pressed and touch_id==event.index:
			if event.canceled:cancel_pointer()
			else:release_at(event.position)
			touch_id=-1
		accept_event()
	elif event is InputEventScreenDrag and event.index==touch_id:pointer=event.position;queue_redraw();accept_event()
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and touch_id<0:
		if event.pressed:press_at(event.position)
		else:release_at(event.position)
		accept_event()
	elif event is InputEventMouseMotion and touch_id<0:pointer=event.position;queue_redraw()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode==KEY_ESCAPE:close()
		elif event.keycode==KEY_TAB:focus_index=posmod(focus_index+(-1 if event.shift_pressed else 1),10)
		elif event.keycode in [KEY_ENTER,KEY_SPACE]:
			if focus_index<6:selected=focus_index
			elif focus_index<8:_handle(focus_index-6)
			elif focus_index==8:_paper()
			else:model.undo()
		elif selected>=0 and event.keycode in [KEY_1,KEY_2,KEY_3,KEY_4]:model.place(selected,int(event.keycode)-int(KEY_1));selected=-1
		queue_redraw();accept_event()
func press_at(at:Vector2)->void:
	pointer=at;origin=at
	if Rect2(880,16,58,48).has_point(at):close();return
	if Rect2(55,447,160,59).has_point(at):_paper();return
	if Rect2(224,450,60,47).has_point(at):model.undo();return
	for i:int in 2:
		if at.distance_to(HANDLES[i])<32:_handle(i);return
	for i:int in 6:
		if at.distance_to(tile_position(i))<37:drag=i;selected=i;return
	if selected>=0:
		for i:int in 4:
			if at.distance_to(SLOTS[i])<42:model.place(selected,i);selected=-1;return
func release_at(at:Vector2)->void:
	if drag<0:return
	var tile:=drag;drag=-1
	if origin.distance_to(at)<9:selected=tile;return
	selected=-1
	for i:int in 4:
		if at.distance_to(SLOTS[i])<42:model.place(tile,i);queue_redraw();return
	if Rect2(60,125,210,305).has_point(at):model.place(tile,-1)
	queue_redraw()
func _handle(which:int)->void:
	if model.paused:model.resume()
	else:model.start(which)
func _paper()->void:
	if not paper_open:paper_open=true;hint_level=maxi(1,hint_level)
	elif hint_level<3:hint_level+=1
	else:paper_open=false
	queue_redraw()
func _text(value:String,at:Vector2,size_value:=16,color:=INK)->void:draw_string(font,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size_value,color)
func _shape(at:Vector2,shape_value:int,filled:bool,scale_value:=1.0)->void:
	var poly:=PackedVector2Array()
	var count:=32 if shape_value==0 else (3 if shape_value==1 else 4)
	for i:int in count:
		var angle:float=TAU*i/count-PI/2+(PI/4 if shape_value==2 else 0)
		poly.append(at+Vector2(cos(angle)*23,sin(angle)*23)*scale_value)
	if filled:draw_colored_polygon(poly,INK)
	else:
		poly.append(poly[0]);draw_polyline(poly,INK,3)
func _tile(tile:int,at:Vector2)->void:
	draw_rect(Rect2(at-Vector2(33,30)+Vector2(0,5),Vector2(66,60)),INK)
	draw_rect(Rect2(at-Vector2(33,30),Vector2(66,60)),TILE)
	draw_line(at-Vector2(31,28),at+Vector2(31,-28),PAPER,2)
	_shape(at,model.shape(tile),model.fill(tile)==1)
	if selected==tile or (has_focus() and focus_index==tile):draw_rect(Rect2(at-Vector2(37,34),Vector2(74,68)),PAPER,false,2)
func _draw()->void:
	if font==null:return
	draw_rect(Rect2(0,0,960,540),Color("28323a"))
	_text("研讨间 1 · 找一个能区分猜想的例子",Vector2(32,36),22,PAPER)
	_text("先做一次有区分力的试验，再用一组新磁片验证",Vector2(33,64),16,Color("bcc5c1"))
	draw_line(Vector2(898,30),Vector2(919,51),PAPER,3);draw_line(Vector2(919,30),Vector2(898,51),PAPER,3)
	draw_rect(Rect2(36,106,890,410),INK);draw_rect(Rect2(36,98,890,410),Color("a18c6d"))
	for y:int in range(119,500,30):draw_line(Vector2(46,y),Vector2(915,y),Color("927c61"),1)
	draw_rect(Rect2(59,116,212,312),Color("726956"));_text("磁片托盘",Vector2(108,137),15,PAPER)
	# Two apparatus bays retain their actual tested pairs and result stamp.
	for side:int in 2:
		var x:=310+side*290
		draw_rect(Rect2(x,143,250,241),Color("d1d0bd"))
		_text("区分试验" if side==0 else "新例验证",Vector2(x+80,177),17)
		for slot:int in 2:draw_rect(Rect2(SLOTS[side*2+slot]-Vector2(38,35),Vector2(76,70)),INK)
		var handle:Vector2=HANDLES[side]
		draw_circle(handle,24,INK);draw_circle(handle+Vector2(0,-4 if model.running and model.station==side else -13),18,Color("b48459"))
		var line_y:=295.0
		if model.running and model.station==side:draw_line(Vector2(x+23,line_y),Vector2(x+23+204*model.elapsed,line_y),Color("688c99"),4)
		var latest:Dictionary={}
		for row:Dictionary in model.evidence:
			if row.station==side:latest=row
		if not latest.is_empty():
			_text("○" if latest.accepted else "×",Vector2(x+210,336),26)
			_shape(Vector2(x+35,361),model.shape(latest.a),model.fill(latest.a)==1,.48)
			_shape(Vector2(x+70,361),model.shape(latest.b),model.fill(latest.b)==1,.48)
		if model.paused and model.station==side:_text("Ⅱ",Vector2(x+205,300),20)
	for tile:int in 6:
		if drag!=tile:_tile(tile,tile_position(tile))
	# Old examples physically show both attributes together; no rule name is marked true.
	draw_rect(Rect2(300,394,550,41),PAPER)
	_text("旧例",Vector2(312,421),14)
	_shape(Vector2(382,414),0,false,.58);_shape(Vector2(418,414),0,false,.58);_text("○",Vector2(449,423),20)
	_shape(Vector2(520,414),1,true,.58);_shape(Vector2(556,414),1,true,.58);_text("○",Vector2(587,423),20)
	_shape(Vector2(660,414),0,false,.58);_shape(Vector2(696,414),2,true,.58);_text("×",Vector2(727,423),20)
	draw_rect(Rect2(61,449,151,49),PAPER);_text("观察笔记",Vector2(96,479),16)
	draw_line(Vector2(235,484),Vector2(270,459),Color("a9b7b5"),7);draw_arc(Vector2(270,458),10,.3,5,20,Color("a9b7b5"),5)
	if paper_open:_text(HINTS[hint_level-1],Vector2(307,477),16,PAPER)
	elif model.outcome=="empty":_text("实验槽里还缺一枚磁片。",Vector2(307,477),16,INK)
	elif model.outcome=="repeated":_text("这是已经试过的同一组磁片。",Vector2(307,477),16,INK)
	elif model.outcome=="no_contrast":_text("旧例还支持两种解释。",Vector2(307,477),16,INK)
	elif model.completed:_text("反例与新例都留在实验板上。",Vector2(307,477),16,INK)
	if drag>=0:_tile(drag,pointer)
