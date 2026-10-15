extends Control
## Presentation-only geometry built from the current draft; no answer judging.
const GOLD := Color("f2c26a")
const PALE := Color("c0e0df")
const GRID := Color("547077")
const INK := Color("19343d")
const NODES := {"hall":Vector2(150,42),"west_corridor":Vector2(60,112),"east_corridor":Vector2(240,112),"bakery_back_area":Vector2(75,220),"classroom_zone":Vector2(225,220)}
const NODE_LABELS := {"hall":"大厅","west_corridor":"西侧走廊","east_corridor":"东侧走廊","bakery_back_area":"后区","classroom_zone":"教室区"}
const CONTACTS := [Vector2(-24,-17),Vector2(24,-17),Vector2(0,19)]
var session: RefCounted
var display_model: Dictionary = {}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func setup(value: RefCounted) -> void:
	session = value
	custom_minimum_size = Vector2(0,280)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	refresh()

func refresh() -> void:
	display_model = project(session.puzzle_id,session.draft,session.source)
	queue_redraw()

static func signed(value: int) -> String:
	return ("+" if value > 0 else "") + str(value)

static func project(id: String, draft: Dictionary, source: Dictionary) -> Dictionary:
	var model := {"puzzleId":id}
	match id:
		"media_alignment":
			var a: Dictionary = draft.mediaAlignment
			model["position"] = Vector2(150 + int(a.xOffset)*20,140 + int(a.yOffset)*20)
			model["rotation"] = int(a.rotationQuarterTurns)*90
			model["caption"] = "横向 %s 格 · 纵向 %s 格 · 顺时针 %d°" % [signed(a.xOffset),signed(a.yOffset),int(a.rotationQuarterTurns)*90]
		"positioning_calibration":
			var a: Dictionary = draft.calibration
			model["position"] = Vector2(110 + int(a.horizontal)*16,137 + int(a.vertical)*16)
			model["pressure"] = int(a.pressure)
			model["pressY"] = 65 + int(a.pressure)*23
			model["caption"] = "滑台 X %s · Y %s · 压头 %d / 4 档" % [signed(a.horizontal),signed(a.vertical),int(a.pressure)]
		"power_topology":
			model["edges"] = draft.powerEdges.duplicate()
			model["caption"] = "已接 %d / 5 条 · 实线为当前接线，虚线为未接" % draft.powerEdges.size()
		"archive_index":
			model["rows"] = [str(draft.archiveYearBand).replace("_","–"),draft.archiveFloor,source.labels.get(draft.archivePurpose,"")]
			var count := 0
			for item: String in model.rows:
				if not item.is_empty(): count += 1
			model["caption"] = "索引卡已填写 %d / 3 项" % count
		_:
			model["order"] = draft["dutyOrder" if id == "duty_board" else "evacuationOrder"].duplicate()
			var labels: PackedStringArray = []
			for index in range(model.order.size()): labels.append("%d %s" % [index+1,source.labels[model.order[index]]])
			model["caption"] = " → ".join(labels)
	return model

func _draw() -> void:
	if session == null or display_model.is_empty(): return
	var scale_factor := minf(size.x/300.0,size.y/280.0)
	var origin := (size-Vector2(300,280)*scale_factor)/2.0
	draw_set_transform(origin,0,Vector2.ONE*scale_factor)
	draw_rect(Rect2(0,0,300,280),Color("142c35"))
	match session.puzzle_id:
		"media_alignment": _film()
		"positioning_calibration": _calibration()
		"power_topology": _power()
		"archive_index": _archive()
		_: _order()
	draw_set_transform(Vector2.ZERO)

func _text(at: Vector2, value: String, color: Color = PALE, font_size: int = 14) -> void:
	draw_string(get_theme_default_font(),at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)

func _dash(a: Vector2, b: Vector2, color: Color = PALE, width: float = 2.0) -> void:
	draw_dashed_line(a,b,color,width,4.0,true)

func _grid(rect: Rect2, gap: int) -> void:
	draw_rect(rect,Color("172e36"))
	for x in range(int(rect.position.x),int(rect.end.x)+1,gap): draw_line(Vector2(x,rect.position.y),Vector2(x,rect.end.y),GRID,1)
	for y in range(int(rect.position.y),int(rect.end.y)+1,gap): draw_line(Vector2(rect.position.x,y),Vector2(rect.end.x,y),GRID,1)
	draw_rect(rect,PALE,false,3)

func _landmarks(center: Vector2, angle: float, reference: bool) -> void:
	var paths := [[Vector2(-42,12),Vector2(-42,-15),Vector2(-25,-15),Vector2(-25,12)],[Vector2(-9,15),Vector2(-9,7),Vector2(-1,7),Vector2(-1,-1),Vector2(7,-1),Vector2(7,-9),Vector2(15,-9)],[Vector2(29,-15),Vector2(29,15)],[Vector2(36,-15),Vector2(36,15)],[Vector2(43,-15),Vector2(43,15)]]
	for path: Array in paths:
		for index in range(path.size()-1):
			var a: Vector2 = center + path[index].rotated(angle)
			var b: Vector2 = center + path[index+1].rotated(angle)
			if reference: _dash(a,b)
			else: draw_line(a,b,GOLD,3)

func _film() -> void:
	_grid(Rect2(10,10,280,260),20)
	_dash(Vector2(150,25),Vector2(150,255),GRID)
	_dash(Vector2(25,140),Vector2(275,140),GRID)
	var center: Vector2 = display_model.position
	var angle := deg_to_rad(float(display_model.rotation))
	var corners: PackedVector2Array = []
	for point: Vector2 in [Vector2(-62,-37),Vector2(62,-37),Vector2(62,37),Vector2(-62,37)]: corners.append(center+point.rotated(angle))
	draw_colored_polygon(corners,Color("80572d",0.55))
	corners.append(corners[0])
	draw_polyline(corners,GOLD,3)
	_landmarks(center,angle,false)
	var registration: Dictionary = session.source.registration.media
	_landmarks(Vector2(150+registration.xOffset*20,140+registration.yOffset*20),deg_to_rad(registration.rotationQuarterTurns*90),true)
	_text(Vector2(30,43),"金色胶片 / 浅色虚线参照")
	_text(Vector2(30,236),"入口 · 楼梯 · 荣誉墙")
	_text(Vector2(30,256),"一格 = 一次平移")

func _calibration() -> void:
	_grid(Rect2(14,35,194,204),16)
	var center: Vector2 = display_model.position
	draw_rect(Rect2(center-Vector2(39,31),Vector2(78,62)),Color("6b725e",0.65))
	draw_rect(Rect2(center-Vector2(39,31),Vector2(78,62)),GOLD,false,3)
	draw_circle(center,15,INK)
	for contact: Vector2 in CONTACTS: draw_circle(center+contact,4,GOLD)
	var r: Dictionary = session.source.registration.calibration
	for contact: Vector2 in CONTACTS: draw_arc(Vector2(110+r.horizontal*16,137+r.vertical*16)+contact,7,0,TAU,24,PALE,2)
	draw_line(Vector2(247,47),Vector2(247,190),GRID,6)
	draw_rect(Rect2(223,191,49,12),Color("acac8b"))
	_dash(Vector2(214,89+r.pressure*23),Vector2(275,89+r.pressure*23))
	draw_rect(Rect2(227,display_model.pressY,40,24),GOLD)
	for n in range(5): _text(Vector2(280,90+n*23),str(n),GOLD if n == display_model.pressure else PALE)
	_text(Vector2(22,24),"滑台俯视 · 一次一格")
	_text(Vector2(214,24),"压头侧视",PALE,13)
	_text(Vector2(22,260),"左 −X / 右 +X · 上 −Y / 下 +Y")

func _power() -> void:
	for edge: String in session.source.edges:
		var ends := edge.split("__")
		if edge in display_model.edges: draw_line(NODES[ends[0]],NODES[ends[1]],GOLD,4)
		else: _dash(NODES[ends[0]],NODES[ends[1]],GRID,1.5)
	for id: String in NODES:
		var at: Vector2 = NODES[id]
		draw_rect(Rect2(at-Vector2(39,15),Vector2(78,30)),INK)
		draw_rect(Rect2(at-Vector2(39,15),Vector2(78,30)),PALE,false,2)
		_text(at-Vector2(get_theme_default_font().get_string_size(NODE_LABELS[id],HORIZONTAL_ALIGNMENT_LEFT,-1,14).x/2,-5),NODE_LABELS[id])
	_text(Vector2(73,266),"点同一条线路可拆下")

func _archive() -> void:
	draw_rect(Rect2(25,25,250,230),Color("d7ccac"))
	_text(Vector2(45,54),"档案抽屉 · 当前检索卡",INK)
	for index in range(3):
		_text(Vector2(46,95+index*63),["年代","楼层","用途"][index],INK)
		draw_rect(Rect2(94,75+index*63,156,34),Color("e9dfc4"))
		_text(Vector2(104,97+index*63),display_model.rows[index] if not display_model.rows[index].is_empty() else "尚未选择",INK)

func _order() -> void:
	var order: Array = display_model.order
	var gap := 74 if order.size() == 3 else 58
	draw_line(Vector2(43,35),Vector2(43,248),PALE,3)
	for index in range(order.size()):
		draw_rect(Rect2(63,27+index*gap,215,44),Color("6b654a"))
		draw_rect(Rect2(63,27+index*gap,215,44),GOLD,false,2)
		draw_circle(Vector2(43,49+index*gap),13,GOLD)
		_text(Vector2(38,54+index*gap),str(index+1),INK)
		_text(Vector2(77,54+index*gap),session.source.labels[order[index]])
	_text(Vector2(48,272),"夹板顺序 · 从上到下" if session.puzzle_id == "duty_board" else "当前路线 · 按编号依次经过")
