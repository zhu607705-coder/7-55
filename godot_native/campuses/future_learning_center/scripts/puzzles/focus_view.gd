extends Control
const ApparatusStyle=preload("res://campuses/future_learning_center/scripts/apparatus_style.gd")
## A physical patch-board: visible plugs, branch meters and one mode lever.
signal closed
const Model = preload("res://campuses/future_learning_center/scripts/puzzles/focus_model.gd")
const DEVICE_POS := [Vector2(160,160), Vector2(340,160), Vector2(540,160), Vector2(720,160), Vector2(827,350)]
const BRANCH_POS := [Vector2(280,350), Vector2(570,350)]
const LEVER := Vector2(720,385)
const INK=ApparatusStyle.INK
const PAPER=ApparatusStyle.PAPER
const METAL := Color("8d9b9c")
const BLUE := Color("688c99")
const COPPER := Color("b68559")
const HINTS := ["单台与同时运行时，哪条表针先出现不同？", "接线不动，比较待机与工作两栏的总读数。", "核对设备铭牌、支路刻度与辅助模块的两种状态。"]
var model = Model.new()
var font: Font
var selected := -1
var drag := -1
var touch_action_pending:=false
var touch_action_origin:=Vector2.ZERO
var touch_id := -1
var pointer := Vector2.ZERO
var origin := Vector2.ZERO
var phase := 0.0
var needle: Array[float] = [0.0, 0.0]
var hint_level := 0
var paper_open := false
var feedback := ""
var focus_index := 0
func _ready() -> void:
	ApparatusStyle.configure_exit(self,close)
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	font = ApparatusStyle.font()
	size = Vector2(960,540)
	hide()
func open() -> void:
	selected = -1; drag = -1; touch_id = -1; feedback = ""
	show(); grab_focus(); queue_redraw()
func close() -> void:
	model.cancel(); cancel_pointer(); hide(); closed.emit()
func cancel_pointer() -> void:
	touch_action_pending=false
	drag = -1; selected = -1; touch_id = -1
	queue_redraw()
func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED]:
		model.pause(); cancel_pointer()
		feedback = "试验已暂停，轻触操纵杆继续。" if model.paused else ""
func _process(dt: float) -> void:
	if not visible: return
	model.step(minf(dt,.1))
	if not model.paused: phase += minf(dt,.1) * 4.0
	var target: Array[int] = model.displayed_loads()
	for branch: int in 2:
		if model.paused: continue
		needle[branch] = move_toward(needle[branch], float(target[branch]) if model.running or not model.outcome.is_empty() else 0.0, dt * 8.0)
	queue_redraw()
func plug_position(device: int) -> Vector2:
	return DEVICE_POS[device] + Vector2(25,69) if model.assignments[device] < 0 else socket_position(model.assignments[device], device)
func socket_position(branch: int, device: int) -> Vector2:
	return BRANCH_POS[branch] + Vector2(-62 + device * 30, 28)
func _gui_input(event: InputEvent) -> void:
	if not visible: return
	if event is InputEventMouse and event.device == InputEvent.DEVICE_ID_EMULATION: return
	if event is InputEventScreenTouch:
		if event.canceled and event.index == touch_id: cancel_pointer(); accept_event(); return
		if event.pressed and not event.canceled and touch_id < 0:
			touch_id = event.index; _touch_begin(event.position)
		elif not event.pressed and touch_id == event.index:
			if event.canceled: cancel_pointer()
			else: _touch_finish(event.position)
			touch_id = -1
		accept_event()
	elif event is InputEventScreenDrag and event.index == touch_id:
		pointer = event.position; queue_redraw(); accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and touch_id < 0:
		if event.pressed: press_at(event.position)
		else: release_at(event.position)
		accept_event()
	elif event is InputEventMouseMotion and touch_id < 0:
		pointer = event.position; queue_redraw()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE: close()
		elif event.keycode == KEY_TAB: focus_index = posmod(focus_index + (-1 if event.shift_pressed else 1), model.device_count() + 4)
		elif event.keycode in [KEY_ENTER, KEY_SPACE]:
			if focus_index < model.device_count(): selected = focus_index
			elif focus_index == model.device_count(): _operate_lever()
			elif focus_index == model.device_count()+1: model.undo()
			elif focus_index == model.device_count()+2: _paper()
			else: close()
		elif selected >= 0 and event.keycode in [KEY_LEFT,KEY_RIGHT]:
			model.connect_device(selected,0 if event.keycode == KEY_LEFT else 1); selected = -1
		elif selected >= 0 and event.keycode in [KEY_DELETE,KEY_BACKSPACE]: model.connect_device(selected,-1); selected = -1
		queue_redraw(); accept_event()
func press_at(at: Vector2) -> void:
	pointer = at; origin = at
	if Rect2(52,414,150,86).has_point(at): _paper(); return
	if Rect2(216,443,70,46).has_point(at): model.undo(); feedback = ""; return
	if at.distance_to(LEVER) < 46: _operate_lever(); return
	if Rect2(782,311,132,102).has_point(at) and not model.extension:
		model.set_extension(true); feedback = "辅助模块已装入；待机刻度改为 4。"; return
	for i: int in model.device_count():
		if at.distance_to(plug_position(i)) < 22:
			drag = i; selected = i; return
	for i: int in model.device_count():
		if Rect2(DEVICE_POS[i]-Vector2(58,38),Vector2(116,80)).has_point(at):
			model.start(model.mode,i); feedback = "单台试验 D%d"%(i+1); return
	if selected >= 0:
		for branch: int in 2:
			if Rect2(BRANCH_POS[branch]-Vector2(88,0),Vector2(176,65)).has_point(at):
				model.connect_device(selected,branch); selected = -1; feedback = ""; return
func release_at(at: Vector2) -> void:
	if drag < 0: return
	if origin.distance_to(at) < 9:
		selected = drag; drag = -1; queue_redraw(); return
	var device := drag
	drag = -1; selected = -1
	for branch: int in 2:
		if Rect2(BRANCH_POS[branch]-Vector2(88,-2),Vector2(176,63)).has_point(at):
			model.connect_device(device,branch); feedback = ""; queue_redraw(); return
	if at.distance_to(DEVICE_POS[device]+Vector2(25,69)) < 38:
		model.connect_device(device,-1); feedback = ""
	else: feedback = "插头未落入插孔，保留原接线。"
	queue_redraw()
func _operate_lever() -> void:
	if model.paused: model.resume(); feedback = ""
	elif not model.running:
		model.start(1-model.mode); feedback = ""
func _paper() -> void:
	if not paper_open: paper_open = true; hint_level = maxi(1,hint_level)
	elif hint_level < 3: hint_level += 1
	else: paper_open = false
	queue_redraw()
func _text(value: String, at: Vector2, size_value := 16, color := INK) -> void:
	draw_string(font,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size_value,color)
func _plinth(rect: Rect2, top: Color, depth := 9.0) -> void:
	draw_rect(Rect2(rect.position+Vector2(0,depth),rect.size),INK)
	draw_colored_polygon(PackedVector2Array([rect.position+Vector2(0,depth),rect.position+Vector2(11,-8),rect.position+Vector2(rect.size.x+11,-8),rect.end+Vector2(0,depth)]),top.darkened(.15))
	draw_rect(rect,top)
	draw_line(rect.position,rect.position+Vector2(rect.size.x,0),top.lightened(.22),2)
func _device(i: int) -> void:
	var at: Vector2 = DEVICE_POS[i]
	_plinth(Rect2(at-Vector2(65,42),Vector2(130,100)),METAL)
	var color := BLUE if i%2 == 0 else COPPER
	draw_circle(at+Vector2(0,-10),29,INK)
	var branch: int = model.assignments[i]
	var powered: bool = branch >= 0 and model.device_powered(i)
	var angle: float = phase * (2.4 if model.mode == 1 else .7) if powered else 0.0
	for blade: int in 4:
		var p := at+Vector2(0,-10)
		var a := angle+blade*PI/2
		draw_line(p,p+Vector2(cos(a)*22,sin(a)*14),color,7)
	draw_circle(at+Vector2(0,-10),5,PAPER)
	_text("D%d"%(i+1),at+Vector2(-53,-21),13)
	_text("%d / %d"%[Model.IDLE[i],Model.ACTIVE[i]],at+Vector2(-19,39),17)
	draw_circle(at+Vector2(25,59),8,INK)
	if i == focus_index and has_focus(): draw_rect(Rect2(at-Vector2(70,47),Vector2(140,110)),PAPER,false,2)
func _meter(branch: int) -> void:
	var at: Vector2 = BRANCH_POS[branch]
	_plinth(Rect2(at-Vector2(94,77),Vector2(188,140)),Color("aeb4ac"))
	draw_rect(Rect2(at-Vector2(69,66),Vector2(138,66)),PAPER)
	var pivot := at+Vector2(0,-7)
	for tick: int in 9:
		var a := PI+PI*tick/8.0
		draw_line(pivot+Vector2(cos(a),sin(a))*46,pivot+Vector2(cos(a),sin(a))*52,INK,1.5)
	var limit_angle := PI+PI*model.limit(model.mode)/8.0
	draw_line(pivot+Vector2(cos(limit_angle),sin(limit_angle))*41,pivot+Vector2(cos(limit_angle),sin(limit_angle))*55,COPPER,4)
	var angle := PI+PI*minf(needle[branch],8.0)/8.0
	draw_line(pivot,pivot+Vector2(cos(angle),sin(angle))*47,INK,3)
	draw_circle(pivot,4,INK)
	_text("%s  %d / %d"%["A" if branch==0 else "B",model.displayed_loads()[branch],model.limit(model.mode)],at+Vector2(-55,18),16)
	for i: int in 5:
		var p := socket_position(branch,i)
		draw_circle(p,10,INK);draw_circle(p,5,Color("45535b"))
	if (model.running or not model.outcome.is_empty()) and model.displayed_loads()[branch]>model.limit(model.mode):
		draw_line(at+Vector2(71,-55),at+Vector2(78,-42),COPPER,4)
		draw_line(at+Vector2(78,-42),at+Vector2(68,-30),COPPER,4)
func _draw() -> void:
	if font == null: return
	draw_rect(Rect2(0,0,960,540),Color("273039"))
	_plinth(Rect2(35,89,890,414),Color("a88b68"),18)
	for y: int in range(105,490,35): draw_line(Vector2(48,y),Vector2(910,y),Color("947b60"),1)
	_text("专注孵化区",Vector2(32,36),22,PAPER)
	if paper_open:_text("让模型设备在待机和工作时都能运行",Vector2(33,64),16,Color("b8c2c1"))
	for i: int in model.device_count():
		var start: Vector2 = DEVICE_POS[i]+Vector2(25,59)
		var end: Vector2 = pointer if drag == i else plug_position(i)
		var points := PackedVector2Array([start,start+Vector2(0,20),Vector2(end.x,end.y-21),end])
		draw_polyline(points,INK,8);draw_polyline(points,BLUE if i%2==0 else COPPER,4)
	# Leads pass behind the meter housing; its face and numeric scale remain clear.
	for branch: int in 2: _meter(branch)
	for i: int in 4: _device(i)
	if model.extension:
		_plinth(Rect2(782,311,132,102),Color("9caa9e"))
		_text("预热模块",Vector2(794,338),16);_text("2 / 0",Vector2(821,366),18)
		draw_circle(DEVICE_POS[4]+Vector2(25,59),8,INK)
	else:
		# A spare heater cartridge in its storage cradle, not an add button.
		draw_rect(Rect2(782,311,132,102),Color("665b4c"))
		_plinth(Rect2(795,322,106,72),Color("9caa9e"),5)
		for y:int in range(337,376,9):draw_line(Vector2(811,y),Vector2(879,y),INK,3)
		draw_line(Vector2(812,319),Vector2(812,308),INK,4);draw_line(Vector2(885,319),Vector2(885,308),INK,4)
		draw_line(Vector2(812,308),Vector2(885,308),INK,4)
		_text("2 / 0",Vector2(825,410),15,PAPER)
	for i: int in model.device_count():
		var at: Vector2 = pointer if drag == i else plug_position(i)
		draw_circle(at,11,INK);draw_circle(at,7,BLUE if i%2==0 else COPPER)
		ApparatusStyle.grip(self,at,"drag",drag==i)
		if selected == i: draw_arc(at,17,0,TAU,24,PAPER,2)
	if drag>=0 or selected>=0:
		for branch:int in 2:
			ApparatusStyle.target(self,Rect2(BRANCH_POS[branch]+Vector2(-88,2),Vector2(176,63)),Rect2(BRANCH_POS[branch]+Vector2(-88,2),Vector2(176,63)).has_point(pointer))
	_plinth(Rect2(680,311,78,111),METAL)
	_text("待机",Vector2(688,332),14);_text("工作",Vector2(688,409),14)
	draw_line(LEVER,LEVER+Vector2(0,-38 if model.mode==0 else 13),INK,11)
	draw_circle(LEVER+Vector2(0,-38 if model.mode==0 else 13),14,COPPER)
	ApparatusStyle.grip(self,LEVER+Vector2(0,-38 if model.mode==0 else 13),"press",model.running)
	if model.paused: _text("Ⅱ",Vector2(742,356),22)
	# Paper and wrench are optional physical tools, not a permanent help panel.
	draw_colored_polygon(PackedVector2Array([Vector2(58,420),Vector2(183,410),Vector2(196,482),Vector2(70,494)]),PAPER)
	_text("试验记录",Vector2(74,444),15)
	for state: int in 2:
		var r: Dictionary = model.receipts.get(state,{})
		var mark := "—" if r.is_empty() else ("○" if r.passed else "×")
		_text(("待机 " if state==0 else "工作 ")+mark,Vector2(78,464+state*18),13)
	draw_line(Vector2(232,479),Vector2(268,451),METAL,8);draw_arc(Vector2(268,450),11,.4,5.1,20,METAL,6)
	_text("待机 / 工作",Vector2(370,120),13,INK)
	if paper_open:
		draw_rect(Rect2(300,424,480,72),PAPER)
		_text("观察笔记 %d · 再点纸页继续"%hint_level,Vector2(315,446),14)
		_text(HINTS[hint_level-1],Vector2(315,473),16)
	elif not feedback.is_empty(): _text(feedback,Vector2(300,475),16)
	elif model.outcome == "overload": _text("支路超出刻度，保护停机。",Vector2(300,475),16)
	elif model.outcome == "unplugged": _text("有设备的插头尚未接入。",Vector2(300,475),16)
	elif model._current_passed(0) and model._current_passed(1): _text("当前接法的两种状态均已验证。",Vector2(300,475),16)
	if paper_open:_text("低压教学模型",Vector2(795,480),13,INK)

func _touch_begin(at:Vector2)->void:
	touch_action_origin=at;touch_action_pending=Rect2(52,414,150,86).has_point(at) or Rect2(216,443,70,46).has_point(at) or at.distance_to(LEVER)<46 or (Rect2(782,311,132,102).has_point(at) and not model.extension) or _touch_device_body(at) or _touch_branch(at)
	if not touch_action_pending:press_at(at)
func _touch_finish(at:Vector2)->void:
	if touch_action_pending:
		touch_action_pending=false
		if at.distance_to(touch_action_origin)>18:return
		press_at(touch_action_origin)
	release_at(at)
func _touch_device_body(at:Vector2)->bool:
	for i:int in model.device_count():
		if at.distance_to(plug_position(i))<22:return false
		if Rect2(DEVICE_POS[i]-Vector2(58,38),Vector2(116,80)).has_point(at):return true
	return false
func _touch_branch(at:Vector2)->bool:
	if selected<0:return false
	for i:int in model.device_count():
		if at.distance_to(plug_position(i))<22:return false
	for branch:int in 2:
		if Rect2(BRANCH_POS[branch]-Vector2(88,0),Vector2(176,65)).has_point(at):return true
	return false
