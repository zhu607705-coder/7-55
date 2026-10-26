extends Control

const Model = preload("res://scripts/paper_rewind_model.gd")
const HistoryWindow = preload("res://scripts/paper_history_window.gd")
const PaperGrip = preload("res://scripts/paper_grip.gd")
const PAPER = preload("res://assets/paper.png")
const FLIGHT = [PAPER, preload("res://assets/paper_flight_1.png"), preload("res://assets/paper_flight_2.png"), preload("res://assets/paper_flight_3.png"), preload("res://assets/paper_flight_4.png")]
var model: RefCounted
var reduced_motion := false
var folder_button: Button
var paper_grip: Control
var history_window: Control
var grip_preview: Control
var history_rect := Rect2(540, 78, 360, 160)
var history_time := 4.8
var environment_time := 0.0
var broadcast_quiet := false
var folder_drag_preview := 0.0
var folder_open_amount := 0.0
var collection_amount := -1.0
var _was_collected := false
var _projection := Vector2.ONE
var _world_offset := Vector2.ZERO
var _world_scale := 1.0

func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	folder_button = Button.new()
	folder_button.name = "Folder"
	folder_button.accessibility_name = "文件夹；撑开夹层"
	folder_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state: String in ["normal", "hover", "pressed", "disabled", "focus"]:
		folder_button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	add_child(folder_button)
	paper_grip = PaperGrip.new()
	paper_grip.name = "PaperGrip"
	add_child(paper_grip)
	history_window = HistoryWindow.new()
	history_window.name = "HistoryWindow"
	history_window.moved.connect(move_history)
	history_window.paint_record = _paint_record
	add_child(history_window)
	grip_preview = Control.new()
	grip_preview.name = "ThumbSafePreview"
	grip_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grip_preview.z_index = 10
	grip_preview.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	grip_preview.draw.connect(_draw_grip_preview)
	add_child(grip_preview)
	resized.connect(_layout)
	_layout()

func _layout() -> void:
	# Perspective is composed for the device, not a letterboxed landscape panel.
	_projection = Vector2(size.x / 960.0, size.y / 540.0)
	_world_scale = minf(_projection.x, _projection.y)
	_world_offset = Vector2.ZERO
	if folder_button:
		folder_button.position = world_to_local(Model.FOLDER_RECT.position)
		folder_button.size = (Model.FOLDER_RECT.size * _projection).max(Vector2(44,44))
		_layout_grip()
		_layout_history()
		grip_preview.queue_redraw()
	queue_redraw()

func _layout_history() -> void:
	history_window.position = world_to_local(history_rect.position)
	history_window.size = history_rect.size * _projection
	history_window.world_rect = history_rect
	history_window.queue_redraw()

func _layout_grip() -> void:
	if not paper_grip or not model: return
	var point: Vector2 = model.paper_position()
	if model.catch_time < 0.0 and model.time > 7.8: point = Model.free_position(7.8)
	var extent := Vector2.ONE * maxf(64.0, 78.0 * _world_scale)
	paper_grip.size = extent
	paper_grip.position = world_to_local(point) - extent * 0.5
	paper_grip.visible = not model.paper_collected and model.mode != "cancelled"
	paper_grip.queue_redraw()

func project_paper_time(screen_point: Vector2) -> float:
	var world_point := (screen_point - global_position - _world_offset) / _projection
	var best_time := 0.0
	var best_distance := INF
	for index: int in range(391):
		var at_time := index * 0.02
		var distance: float = (Model.free_position(at_time) * _projection).distance_squared_to(world_point * _projection)
		if distance < best_distance:
			best_distance = distance; best_time = at_time
	return best_time

func move_history(screen_delta: Vector2) -> void:
	history_rect.position += screen_delta / _projection
	history_rect.position.x = clampf(history_rect.position.x, 0, 960 - history_rect.size.x)
	history_rect.position.y = clampf(history_rect.position.y, 0, 540 - history_rect.size.y)
	_layout_history()

func reset_history() -> void:
	history_rect = Rect2(540, 78, 360, 160)
	history_time = 4.8
	folder_open_amount = 0
	folder_drag_preview = 0
	collection_amount = -1
	_was_collected = false
	_layout_history()

func animate(delta: float) -> void:
	var target := 1.0 if model.folder_open else folder_drag_preview
	folder_open_amount = move_toward(folder_open_amount, target, delta * 1.8)
	if model.paper_collected and not _was_collected: collection_amount = 0.0
	if not model.paper_collected: collection_amount = -1.0
	_was_collected = model.paper_collected
	if collection_amount >= 0: collection_amount = minf(1.0, collection_amount + delta / 0.72)

func refresh() -> void:
	if folder_button and model:
		folder_button.disabled = model.folder_open or model.mode in ["solved", "cancelled"]
		_layout_grip()
		history_window.visible = model.mode != "cancelled"
		history_window.record_time = history_time
		history_window.reduced_motion = reduced_motion
		history_window.queue_redraw()
		grip_preview.queue_redraw()
	queue_redraw()

func world_to_local(point: Vector2) -> Vector2:
	return _world_offset + point * _projection

func _poly(c: CanvasItem, points: Array, color: Color, shift: Vector2) -> void:
	var mapped := PackedVector2Array()
	for p: Vector2 in points: mapped.append(world_to_local(p) - shift)
	c.draw_colored_polygon(mapped, color)

func _line(c: CanvasItem, a: Vector2, b: Vector2, color: Color, width: float, shift: Vector2) -> void:
	c.draw_line(world_to_local(a) - shift, world_to_local(b) - shift, color, width, true)

func _rect(c: CanvasItem, rect: Rect2, color: Color, shift: Vector2) -> void:
	c.draw_rect(Rect2(world_to_local(rect.position) - shift, rect.size * _projection), color)

func _environment(c: CanvasItem, shift: Vector2, past: bool) -> void:
	# Soft campus-window light and a close, deep tabletop. No explanatory labels.
	for i: int in range(54):
		var tone := Color("243c43").lerp(Color("4f6661"), float(i)/54.0)
		_rect(c, Rect2(0,i*10,960,11), tone, shift)
	_rect(c, Rect2(25,-30,370,240), Color("172d35"), shift)
	_rect(c, Rect2(43,-22,335,213), Color("a8c8bf"), shift)
	for i: int in range(12):
		var x := 50.0 + i * 29
		_rect(c, Rect2(x, 105 + sin(i * 2.4)*28, 24, 89), Color("748f89"), shift)
	_rect(c, Rect2(198,-25,12,220), Color("3b5356"), shift)
	_rect(c, Rect2(41,74,340,9), Color("3b5356"), shift)
	_rect(c, Rect2(23,191,384,18), Color("708278"), shift)
	_line(c,Vector2(23,191),Vector2(407,191),Color("c2c5a2"),3,shift)
	# Radio grille and lamp: feedback lives on the object, not in a status row.
	_rect(c, Rect2(690,28,181,58), Color("263338"), shift)
	_rect(c, Rect2(703,34,145,43), Color("464b45"), shift)
	for i: int in range(14):
		_line(c,Vector2(711+i*9,39),Vector2(711+i*9,69),Color("252e30"),2,shift)
	c.draw_circle(world_to_local(Vector2(854,57))-shift,4,Color("83bda6") if broadcast_quiet else Color("ecc48b"))
	# Continuous bevel, plank grain, worn edge and long contact shadows.
	_poly(c,[Vector2(-100,193),Vector2(1000,178),Vector2(1110,540),Vector2(-150,540)],Color("473b31"),shift)
	_poly(c,[Vector2(-100,187),Vector2(1000,172),Vector2(1060,493),Vector2(-130,493)],Color("98724e"),shift)
	for i: int in range(92):
		var y := 190.0 + i*3.25
		var col := Color(0.25,0.17,0.10,0.08 + 0.035*sin(i*1.3))
		var points := PackedVector2Array()
		for j: int in range(17): points.append(world_to_local(Vector2(j*64-24,y+2.0*sin(j*0.8+i*1.7)))-shift)
		c.draw_polyline(points,col,1.3,true)
	for y: float in [242.0, 318.0, 405.0, 489.0]:
		_line(c,Vector2(-20,y),Vector2(990,y-5),Color(0.27,0.17,0.10,0.25),1.2,shift)
	_line(c,Vector2(0,493),Vector2(960,493),Color("d2ae75"),3,shift)
	_line(c,Vector2(0,502),Vector2(960,502),Color("382d29"),4,shift)
	# Glancing light stays in the present even when the page reverses.
	_poly(c,[Vector2(80,189),Vector2(320,186),Vector2(680,492),Vector2(310,492)],Color(0.99,0.91,0.60,0.09),shift)
	# A small stack of ruled notebooks at the edge establishes scale/depth.
	_poly(c,[Vector2(90,397),Vector2(330,408),Vector2(306,464),Vector2(69,452)],Color("253b40"),shift)
	_poly(c,[Vector2(88,388),Vector2(328,399),Vector2(307,452),Vector2(68,441)],Color("d4c5a1"),shift)
	for i: int in range(4): _line(c,Vector2(72,442+i*2),Vector2(307,453+i*2),Color("887a60"),1,shift)
	_poly(c,[Vector2(90,380),Vector2(331,391),Vector2(310,444),Vector2(69,433)],Color("3b6263"),shift)
	_line(c,Vector2(110,381),Vector2(89,434),Color("8aa094"),2,shift)
	# Wind is always environmental; its rhythm does not run on the paper clock.
	if not reduced_motion:
		for i: int in range(3):
			var x := 65.0 + fmod(environment_time*60+i*77,310.0)
			_line(c,Vector2(x,200+i*17),Vector2(x+52,196+i*17),Color(0.9,0.96,0.88,0.19),1.2,shift)
	if past: _rect(c,Rect2(0,0,960,540),Color(0.10,0.25,0.34,0.27),shift)

func _folder(c: CanvasItem, shift: Vector2, opened: float, front: bool) -> void:
	# Hinge projects continuously from the closed cover to its raised catch plane.
	var hinge := 344.0
	var top := hinge - 84.0 * cos(opened * PI * 0.45)
	var lift := 110.0 * sin(opened * PI * 0.45)
	var top_y := top - lift
	if not front:
		_poly(c,[Vector2(474,276),Vector2(726,280),Vector2(735,373),Vector2(482,378)],Color(0.14,0.10,0.07,0.35),shift)
		_poly(c,[Vector2(485,274),Vector2(711,278),Vector2(719,365),Vector2(485,369)],Color("9c713d"),shift)
		_poly(c,[Vector2(491,278),Vector2(704,282),Vector2(710,357),Vector2(491,360)],Color("c4a16a"),shift)
		for i: int in range(3): _line(c,Vector2(490,361+i*2),Vector2(713,358+i*2),Color("e1c590"),1,shift)
		# Back leaf can stand upright while the receiving face remains on the desk.
		_poly(c,[Vector2(485,hinge),Vector2(715,hinge),Vector2(701,top_y),Vector2(496,top_y-4)],Color("b98e54").lerp(Color("e1c28a"),opened),shift)
		_line(c,Vector2(496,top_y-4),Vector2(701,top_y),Color("f0d7a4"),2,shift)
		_line(c,Vector2(490,hinge-3),Vector2(711,hinge-3),Color("705333"),2,shift)
		for x: float in [520.0,677.0]:
			_line(c,Vector2(x,hinge-5),Vector2(x,hinge+7),Color("d7d5b1"),3,shift)
	else:
		# Shallow lip, not an opaque bar over the whole collected page.
		_poly(c,[Vector2(486,334),Vector2(715,334),Vector2(719,365),Vector2(485,369)],Color("c39b60"),shift)
		_line(c,Vector2(486,334),Vector2(715,334),Color("eed3a0"),2,shift)
		_line(c,Vector2(485,369),Vector2(719,365),Color("765333"),2,shift)

func _paper(c: CanvasItem, shift: Vector2, point: Vector2, paper_time: float, grounded: bool, tint: Color = Color.WHITE, collect: float = -1.0) -> void:
	var center := world_to_local(point) - shift
	var scale := clampf(size.x / 520.0, 0.95, 1.5)
	var extent := Vector2(64,74)*scale
	if collect >= 0:
		center += Vector2(-size.x*0.12, size.y*0.48) * collect*collect
		extent *= 1.0 + collect*0.7
		tint.a *= 1.0-collect
	var shadow_center := center + Vector2(7,15 if grounded else 43)
	for ring: int in range(4):
		c.draw_set_transform(shadow_center,0,Vector2(1,0.22))
		c.draw_circle(Vector2.ZERO,24.0*scale+ring*4,Color(0.12,0.09,0.07,(0.12 if grounded else 0.04)*tint.a))
	c.draw_set_transform(Vector2.ZERO)
	var frame := 0 if grounded or reduced_motion or paper_grip.held else posmod(int(paper_time*7.0),5)
	var angle := 0.0 if grounded or reduced_motion else sin(paper_time*2.8)*0.12
	c.draw_set_transform(center,angle)
	c.draw_texture_rect(FLIGHT[frame],Rect2(-extent*0.5,extent),false,tint)
	c.draw_set_transform(Vector2.ZERO)

func _paint_record(canvas: CanvasItem) -> void:
	var shift := history_window.position
	_environment(canvas,shift,true)
	_folder(canvas,shift,0.0,false)
	_paper(canvas,shift,Model.free_position(history_time),history_time,false,Color(0.66,0.86,0.98,0.9))
	_folder(canvas,shift,0.0,true)

func _draw() -> void:
	if not model: return
	_environment(self,Vector2.ZERO,false)
	_folder(self,Vector2.ZERO,folder_open_amount,false)
	if paper_grip.held or model.mode == "failed":
		var path := PackedVector2Array()
		for i: int in range(40): path.append(world_to_local(Model.free_position(i*7.8/39.0)))
		draw_polyline(path,Color(0.72,0.91,0.85,0.48),2,true)
		for i: int in range(1,8):
			var p := world_to_local(Model.free_position(i*0.95))
			draw_line(p+Vector2(5,-4),p-Vector2(2,0),Color(0.76,0.94,0.86,0.65),1.5,true)
	if not model.paper_collected:
		_paper(self,Vector2.ZERO,model.paper_position(),model.time,model.catch_time>=0)
	if model.catch_time < 0.0 and model.time > 7.8 and model.mode != "cancelled":
		_paper(self,Vector2.ZERO,Model.free_position(7.8),7.8,false,Color(0.66,0.91,0.89,0.36))
	_folder(self,Vector2.ZERO,folder_open_amount,true)
	if collection_amount >= 0 and collection_amount < 1:
		_paper(self,Vector2.ZERO,Model.REST_POINT,0,true,Color.WHITE,collection_amount)

func thumb_preview_rect() -> Rect2:
	var point := world_to_local(model.paper_position())
	var preview := point-Vector2(0,84)
	if preview.y<35: preview=point+Vector2(76,0)
	preview.x=clampf(preview.x,28,maxf(28,size.x-28))
	preview.y=clampf(preview.y,28,maxf(28,size.y-28))
	return Rect2(preview-Vector2(20,24),Vector2(40,48))

func _draw_grip_preview() -> void:
	if not paper_grip.held or model.paper_collected: return
	# A wireframe echo, not a second solid sheet above the finger.
	var r := thumb_preview_rect()
	grip_preview.draw_line(world_to_local(model.paper_position()),r.get_center(),Color(0.74,0.94,0.86,0.35),1,true)
	grip_preview.draw_rect(r,Color(0.74,0.94,0.86,0.6),false,1.5)
