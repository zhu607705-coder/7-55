extends Control
signal closed
const Model = preload("res://campuses/future_learning_center/scripts/puzzles/flex_model.gd")
const INK := Color("344452")
const PAPER := Color("ede9df")
const COPPER := Color("b88a58")
const PORT_Y := [232.0, 302.0, 372.0]
const ROLE_LABEL := ["源", "分", "收"]
var model = Model.new()
var font: Font
var dragging := -1
var pointer := Vector2.ZERO
var touch_id := -1
var held_board := false
var selected := -1
var hint_level := 0
var notebook := false
var feedback := ""
var fade := 0.0
const HINTS := ["底座换位后，哪些标记跟着它一起转了？", "固定一个输入，在两个工位分别追踪它到达的端点。", "对照功能草图和端点测试，检查端口角色与线长。"]

func _ready() -> void:
	font = load("res://scripts/ui/native_typography.gd").body_font()
	mouse_filter = Control.MOUSE_FILTER_STOP
	hide()
func open() -> void:
	show(); fade = 0; queue_redraw()
func close() -> void:
	model.cancel(); _clear_drag(); hide(); closed.emit()
func _clear_drag() -> void:
	dragging = -1; held_board = false; touch_id = -1; selected = -1
func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED]:
		model.pause(); _clear_drag(); queue_redraw()
func _process(dt: float) -> void:
	if not visible: return
	fade = minf(1, fade + dt * 5)
	model.step(minf(dt, .1)); queue_redraw()
func _input(event: InputEvent) -> void:
	if not visible: return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE: close()
		else: return
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if touch_id >= 0 or event.device == InputEvent.DEVICE_ID_EMULATION: return
		if event.pressed: press(event.position)
		else: release(event.position)
	elif event is InputEventMouseMotion:
		if touch_id >= 0 or event.device == InputEvent.DEVICE_ID_EMULATION: return
		pointer = event.position
	elif event is InputEventScreenTouch:
		if event.canceled and event.index == touch_id: _clear_drag()
		elif event.pressed and touch_id < 0: touch_id = event.index; press(event.position)
		elif not event.pressed and event.index == touch_id: release(event.position); touch_id = -1
	elif event is InputEventScreenDrag:
		if event.index == touch_id: pointer = event.position
	else: return
	get_viewport().set_input_as_handled(); queue_redraw()

func press(at: Vector2) -> void:
	pointer = at
	if Rect2(865,15,70,45).has_point(at): close(); return
	if notebook:
		if Rect2(635,400,220,54).has_point(at): hint_level = mini(3,hint_level+1)
		else: notebook = false
		return
	if Rect2(48,438,130,65).has_point(at): notebook = true; return
	if Rect2(190,435,110,65).has_point(at): model.set_short(not model.short_cable); return
	if model.paused: model.resume(); return
	if model.running: return
	if Rect2(385,94,190,56).has_point(at): held_board = true; return
	for i: int in 3:
		if at.distance_to(Vector2(350,PORT_Y[i])) < 29: dragging = i; selected = i; return
		if at.distance_to(Vector2(610,PORT_Y[i])) < 29:
			if selected >= 0: _connect(selected,i); selected = -1
			else:
				var cable: int = model.connections.find(i)
				if cable >= 0: dragging = cable; model.edit(cable,-1); selected = cable
			return
		if at.distance_to(Vector2(450,PORT_Y[i])) < 23: model.route_cable(i,not model.outer[i]); return
	if at.distance_to(Vector2(275,164)) < 34: model.rotate_adapter(); return
	if at.distance_to(Vector2(730,300)) < 40: model.start(); feedback = ""; return
	for station: int in 2:
		if Rect2(730,115+station*66,128,48).has_point(at):
			if held_board: model.move_to(station)

func _connect(channel: int, port: int) -> void:
	feedback = "" if model.edit(channel,port) else "这个插孔已有插头，先拔下。"
func release(at: Vector2) -> void:
	if held_board:
		for station: int in 2:
			if Rect2(710,104+station*66,160,60).has_point(at): model.move_to(station)
		held_board = false
	if dragging >= 0:
		for i: int in 3:
			if at.distance_to(Vector2(610,PORT_Y[i])) < 35: _connect(dragging,i); selected = -1
		dragging = -1
	queue_redraw()
func _txt(value: String, at: Vector2, size_px := 18, color := INK) -> void:
	draw_string(font,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size_px,color)
func _block(rect: Rect2, color: Color, depth := 8.0) -> void:
	draw_rect(Rect2(rect.position+Vector2(0,depth),rect.size),color.darkened(.28))
	draw_rect(rect,color); draw_rect(rect,INK,false,2)
	draw_line(rect.position+Vector2(2,2),Vector2(rect.end.x-2,rect.position.y+2),color.lightened(.18),2)
func _symbol(at: Vector2, role: int, color := INK) -> void:
	match role:
		0: draw_colored_polygon(PackedVector2Array([at+Vector2(0,-8),at+Vector2(9,7),at+Vector2(-9,7)]),color)
		1: draw_rect(Rect2(at-Vector2(7,7),Vector2(14,14)),color)
		2: draw_circle(at,8,color)
func _cable(i: int) -> PackedVector2Array:
	return model.cable_path(i)
func _point_on(line: PackedVector2Array, fraction: float) -> Vector2:
	return model.point_at_distance(line,model.path_length(line)*fraction)
func _visible_cable(line: PackedVector2Array) -> PackedVector2Array:
	var result := PackedVector2Array([line[0]])
	var remaining: float = model.cable_length()
	for i: int in range(1,line.size()):
		var length := line[i-1].distance_to(line[i])
		if remaining < length:
			result.append(line[i-1].lerp(line[i],remaining/maxf(length,.001))); break
		result.append(line[i]); remaining -= length
	return result
func _draw() -> void:
	if font == null: return
	draw_rect(Rect2(0,0,960,540),Color("c6c7c3"))
	for y: int in range(80,540,42): draw_line(Vector2(0,y),Vector2(960,y),Color("b7bab7"),1)
	_block(Rect2(32,76,880,375),Color("a17c56"),22)
	_block(Rect2(190,151,494,259),Color("d0d1c5"),12)
	_txt("流动工位",Vector2(36,38),24)
	_txt("同一件底座，在两个工位都传到正确端点。",Vector2(36,64),17)
	_txt("返回",Vector2(877,43),18)
	_block(Rect2(385,94,190,56),Color("d1c6aa"),6)
	draw_arc(Vector2(480,120),28,PI,TAU,20,INK,5)
	_txt("便携底座 · 01",Vector2(402,143),16)
	if held_board:
		draw_rect(Rect2(pointer-Vector2(40,20),Vector2(80,40)),Color(.85,.80,.68,.7)); _txt("01",pointer,18)
	for s: int in 2:
		_block(Rect2(730,115+s*66,128,48),Color("e0d6bd") if s==model.station else Color("bfbab0"),5)
		_txt("工位 "+("甲" if s==0 else "乙"),Vector2(743,145+s*66),19)
		if model.station_proofs[s]: draw_circle(Vector2(841,130+s*66),5,INK)
	_txt("搬起把手换工位",Vector2(719,257),14)
	# Fixed fixture occupies the crossover conduit. Outer loops go around it.
	_block(Model.PILLAR,Color("747d7b"),10)
	for i: int in 3:
		var line := _cable(i)
		draw_polyline(_visible_cable(line),INK,8); draw_polyline(_visible_cable(line),COPPER.lightened(i*.09),4)
		if model.running:
			var pulse: Vector2 = model.point_at_distance(line,minf(model.path_length(line)*model.progress,model.failure_distance(i)))
			draw_circle(pulse,6,PAPER); _symbol(pulse,model.source_role(i),INK)
		if model.outcomes[i] in ["blocked","short"]:
			var collision: Vector2 = model.point_at_distance(line,model.failure_distance(i))
			draw_line(collision-Vector2(9,9),collision+Vector2(9,9),Color("915443"),3)
			draw_line(collision+Vector2(-9,9),collision+Vector2(9,-9),Color("915443"),3)
		_block(Rect2(423,PORT_Y[i]-15,54,30),Color("c5b693"),3)
		_txt("外" if model.outer[i] else "内",Vector2(442,PORT_Y[i]+6),15)
		for side: int in 2:
			var at := Vector2(350 if side==0 else 610,PORT_Y[i])
			draw_circle(at,22,INK); draw_circle(at,16,PAPER)
			var role: int = model.source_role(i) if side==0 else Model.ROLES[model.station][i]
			_symbol(at,role)
			_txt(ROLE_LABEL[role],at+Vector2(-48 if side==0 else 31,6),17)
		if model.received[i] >= 0:
			_txt(str(model.received[i]),Vector2(832,329+i*25),20)
	if dragging >= 0: draw_polyline(PackedVector2Array([Vector2(350,PORT_Y[dragging]),pointer]),COPPER,5)
	draw_circle(Vector2(275,164),28,INK); draw_circle(Vector2(275,164),22,Color("b8c3bd"))
	_symbol(Vector2(275,164),model.orientation)
	_txt("适配定位环",Vector2(222,126),15)
	draw_circle(Vector2(730,300),34,INK); draw_circle(Vector2(730,300),26,COPPER)
	_draw_knob()
	_txt("源信号",Vector2(700,355),17)
	_txt("接收",Vector2(813,304),16)
	_block(Rect2(48,438,130,65),PAPER,4); _txt("试验手册",Vector2(64,470),18); _txt("按需翻阅",Vector2(72,491),14)
	_block(Rect2(190,438,110,62),Color("c2b699"),4)
	draw_arc(Vector2(214,469),13,0,TAU,24,INK,3); _txt("短线" if model.short_cable else "长线",Vector2(237,476),18)
	if model.completed: _txt("两工位接收已核对",Vector2(637,474),20)
	elif model.paused: _txt("已暂停 · 触碰装置继续",Vector2(530,474),18)
	elif not feedback.is_empty(): _txt(feedback,Vector2(323,474),17)
	if notebook:
		_block(Rect2(105,104,750,350),PAPER,8)
		_txt("连接记录",Vector2(132,140),23)
		_txt("三角 → 源端    方形 → 分配    圆形 → 接收",Vector2(132,179),18)
		_txt("搬动底座不会复制作品；有效的旧连接无需重插。",Vector2(132,214),17)
		for i: int in hint_level: _txt(HINTS[i],Vector2(132,260+i*41),17)
		_txt("翻下一页提示",Vector2(665,433),18)
		_txt("点空白合上",Vector2(132,433),16)
func _draw_knob() -> void:
	var at := Vector2(730,300)
	draw_line(at,at+Vector2(0,-20).rotated(model.pattern*PI),PAPER,5)
