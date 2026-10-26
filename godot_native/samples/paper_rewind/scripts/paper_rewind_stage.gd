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
var history_rect := Rect2(430, 180, 430, 75)
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
	_projection = Vector2(size.x / 960.0, size.y * 0.30 / 133.0)
	_world_scale = minf(_projection.x, _projection.y)
	_world_offset = Vector2(0, size.y * 0.35 - 170.0 * _projection.y)
	if folder_button:
		folder_button.position = folder_leaf_rect().position
		folder_button.size = folder_leaf_rect().size
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
	history_rect = Rect2(430, 180, 430, 75)
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

func art_scale() -> float:
	return clampf(size.x / 390.0, 0.82, 1.6)

func folder_leaf_rect() -> Rect2:
	var extent := Vector2(116,154) * art_scale()
	return Rect2(world_to_local(Model.REST_POINT) - extent*0.5,extent)

func _environment(c: CanvasItem, shift: Vector2, past: bool) -> void:
	# Camera remains isotropic for every physical object. Layout changes positions,
	# never the shape of a folder, notebook, window or sheet.
	var unit := art_scale()
	var top := size.y * 0.29
	c.draw_rect(Rect2(-shift,size),Color("243b3d"))
	var window := Rect2(Vector2(-18,18)*unit-shift,Vector2(178,190)*unit)
	c.draw_rect(window.grow(6*unit),Color("14292e"))
	c.draw_rect(window,Color("acc7bd"))
	for i: int in range(7):
		var p := window.position+Vector2(i*27,125+sin(i*2.2)*15)*unit
		c.draw_colored_polygon(PackedVector2Array([p+Vector2(-12,0)*unit,p+Vector2(8,-22)*unit,p+Vector2(32,0)*unit,p+Vector2(32,65)*unit,p+Vector2(-12,65)*unit]),Color("718f81"))
	c.draw_rect(Rect2(window.position+Vector2(81,0)*unit,Vector2(7,190)*unit),Color("465e58"))
	c.draw_rect(Rect2(window.position+Vector2(0,78)*unit,Vector2(178,7)*unit),Color("465e58"))
	c.draw_rect(Rect2(window.position+Vector2(-3,190)*unit,Vector2(190,10)*unit),Color("839188"))
	var radio := Rect2(Vector2(size.x-116*unit,84*unit)-shift,Vector2(88,42)*unit)
	c.draw_rect(radio.grow(3),Color("1b282b"))
	c.draw_rect(radio,Color("4c5145"))
	for i: int in range(16): c.draw_line(radio.position+Vector2(6+i*4,7)*unit,radio.position+Vector2(6+i*4,34)*unit,Color("273536"),unit,true)
	c.draw_circle(radio.position+Vector2(79,20)*unit,3.5*unit,Color("83bda6") if broadcast_quiet else Color("ecc48b"))
	# Close tabletop extends out of the camera; a bevel retains believable thickness.
	for i: int in range(80):
		var y := top + (size.y-top)*i/80.0
		var col := Color("94704c").lerp(Color("ae8556"),float(i)/80.0)
		c.draw_rect(Rect2(Vector2(0,y)-shift,Vector2(size.x,(size.y-top)/80.0+1)),col)
	for i: int in range(72):
		var y := top + (size.y-top)*i/72.0
		var points := PackedVector2Array()
		for j: int in range(18): points.append(Vector2(j*size.x/17.0,y+2.0*sin(j*0.8+i*1.7)*unit)-shift)
		c.draw_polyline(points,Color(0.26,0.15,0.08,0.10),unit,true)
	for f: float in [0.25,0.57,0.9]:
		var y := lerpf(top,size.y,f)
		c.draw_line(Vector2(0,y)-shift,Vector2(size.x,y-8*unit)-shift,Color(0.29,0.18,0.10,0.24),unit,true)
	c.draw_rect(Rect2(Vector2(0,size.y-34*unit)-shift,Vector2(size.x,34*unit)),Color("5b4432"))
	c.draw_line(Vector2(0,size.y-34*unit)-shift,Vector2(size.x,size.y-34*unit)-shift,Color("d6b380"),3*unit)
	c.draw_colored_polygon(PackedVector2Array([Vector2(18,top)-shift,Vector2(143*unit,top)-shift,Vector2(size.x*0.77,size.y-35*unit)-shift,Vector2(size.x*0.36,size.y-35*unit)-shift]),Color(0.98,0.91,0.65,0.09))
	var book := Vector2(31*unit,size.y-134*unit)-shift
	var book_points := PackedVector2Array([book,book+Vector2(117,9)*unit,book+Vector2(107,77)*unit,book+Vector2(-8,64)*unit])
	c.draw_colored_polygon(book_points,Color("dbca9d"))
	for i: int in range(3): c.draw_line(book+Vector2(-7,66+i*2)*unit,book+Vector2(107,79+i*2)*unit,Color("8d7e60"),unit)
	c.draw_colored_polygon(PackedVector2Array([book-Vector2(0,5)*unit,book+Vector2(117,4)*unit,book+Vector2(108,70)*unit,book+Vector2(-8,58)*unit]),Color("416360"))
	c.draw_line(book+Vector2(11,-4)*unit,book+Vector2(3,60)*unit,Color("92a18b"),2*unit)
	if not reduced_motion:
		for i: int in range(3):
			var p := Vector2(20+fmod(environment_time*27+i*32,120),top+22+i*12)-shift
			c.draw_line(p,p+Vector2(30,-4)*unit,Color(0.92,0.97,0.86,0.20),unit,true)
	if past: c.draw_rect(Rect2(-shift,size),Color(0.10,0.25,0.34,0.18))

func _folder(c: CanvasItem, shift: Vector2, opened: float, front: bool) -> void:
	var base := folder_leaf_rect()
	base.position -= shift
	var unit := art_scale()
	var hinge_x := base.position.x
	var angle := opened*PI
	var edge_x := hinge_x + base.size.x*cos(angle)
	var lift := sin(angle)*34*unit
	if not front:
		c.draw_rect(base.grow(7*unit),Color(0.15,0.10,0.06,0.18))
		c.draw_rect(Rect2(base.position+Vector2(2,5)*unit,base.size),Color("6f5134"))
		c.draw_rect(base,Color("c8a06a"))
		c.draw_rect(base.grow(-5*unit),Color("ddc08a"))
		for i: int in range(3): c.draw_line(base.position+Vector2(3,base.size.y-3+i*2),base.end+Vector2(-2,-3+i*2),Color("eed3a0"),unit)
		# Genuine two-leaf folder: the cover turns around its long spine, not a
		# shape-swap or a vertically stretched rectangle.
		var cover := PackedVector2Array([Vector2(hinge_x,base.position.y),Vector2(edge_x,base.position.y-lift),Vector2(edge_x,base.end.y-lift),Vector2(hinge_x,base.end.y)])
		c.draw_colored_polygon(cover,Color("b58a51").lerp(Color("d6b67d"),opened))
		c.draw_line(cover[1],cover[2],Color("ead09b"),2*unit,true)
		c.draw_line(cover[0],cover[1],Color("ead09b"),unit,true)
		c.draw_line(cover[3],cover[2],Color("775330"),2*unit,true)
		c.draw_line(Vector2(hinge_x,base.position.y),Vector2(hinge_x,base.end.y),Color("765631"),4*unit,true)
		if opened>0.45:
			# Metal clip and folded hinge make the accepting page unambiguous.
			var clip := Rect2(base.position+Vector2(8,12)*unit,Vector2(18,base.size.y/unit-24)*unit)
			c.draw_rect(clip,Color("6f7770"))
			c.draw_line(clip.position+Vector2(3,2)*unit,Vector2(clip.position.x+3*unit,clip.end.y-2*unit),Color("d5d9ba"),3*unit,true)
			for f: float in [0.2,0.8]: c.draw_circle(Vector2(clip.get_center().x,lerpf(clip.position.y,clip.end.y,f)),3*unit,Color("344746"))
	else:
		# A thin retaining pocket occludes only the lower part of the resting page.
		var y := base.position.y+base.size.y*0.64
		c.draw_colored_polygon(PackedVector2Array([Vector2(base.position.x,y+6*unit),Vector2(base.end.x,y),base.end,Vector2(base.position.x,base.end.y)]),Color("c29a60"))
		c.draw_line(Vector2(base.position.x,y+6*unit),Vector2(base.end.x,y),Color("ead09e"),1.5*unit,true)

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
