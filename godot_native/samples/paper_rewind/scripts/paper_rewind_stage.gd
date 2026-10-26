extends Control

const Model = preload("res://scripts/paper_rewind_model.gd")
const HistoryWindow = preload("res://scripts/paper_history_window.gd")
const PaperGrip = preload("res://scripts/paper_grip.gd")
const WINDOW_CANOPY = preload("res://assets/window_canopy.png")
const PAPER = preload("res://assets/paper.png")
const FLIGHT = [PAPER, preload("res://assets/paper_flight_1.png"), preload("res://assets/paper_flight_2.png"), preload("res://assets/paper_flight_3.png"), preload("res://assets/paper_flight_4.png")]
var model: RefCounted
var reduced_motion := false
# Optional art faces share the exact existing physical rectangle and hinge.
# Supplying/replacing these textures never changes collision or pointer targets.
var folder_cover: Texture2D
var folder_inside: Texture2D
var folder_base: Texture2D
var folder_pocket_start := 0.82
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
var grip_amount := 0.0
var _folder_target := 0.0
var _folder_from := 0.0
var _folder_elapsed := 0.0
const INTERACTION := Color("eee0b6")
const HISTORY := Color("9db8c8")
const FOLDER_LIGHT := Color(1.0,0.98,0.92,1.0)
const PAPER_LIGHT := Color(0.97,0.95,0.89,1.0)
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
	_projection = Vector2(size.x / 960.0, size.y * 0.35 / 133.0)
	_world_scale = minf(_projection.x, _projection.y)
	_world_offset = Vector2(0, size.y * 0.32 - 170.0 * _projection.y)
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
	grip_amount = 0
	_folder_target = 0
	_folder_from = 0
	_folder_elapsed = 0
	_layout_history()

func animate(delta: float) -> void:
	var target := 1.0 if model.folder_open else folder_drag_preview
	if not is_equal_approx(target, _folder_target):
		_folder_from = folder_open_amount
		_folder_target = target
		_folder_elapsed = 0.0
	_folder_elapsed += delta
	# Drag follows the hand quickly; the released cover takes longer to lie flat.
	var duration := 0.56 if model.folder_open else 0.14
	var progress := clampf(_folder_elapsed / duration, 0.0, 1.0)
	var eased := 1.0 - pow(1.0-progress, 3.0)
	folder_open_amount = target if reduced_motion else lerpf(_folder_from,target,eased)
	grip_amount = move_toward(grip_amount, 1.0 if paper_grip.held else 0.0, delta / (0.12 if paper_grip.held else 0.22))
	if model.paper_collected and not _was_collected: collection_amount = 0.0
	if not model.paper_collected: collection_amount = -1.0
	_was_collected = model.paper_collected
	if collection_amount >= 0: collection_amount = minf(1.0, collection_amount + delta / 0.88)

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
	return minf(clampf(size.x / 390.0, 0.82, 1.6), size.y / 650.0)

func paper_extent() -> Vector2:
	return Vector2(72,84) * art_scale()

func folder_leaf_rect() -> Rect2:
	# Align the receiving edge with the very first swept contact, not with an
	# unrelated screen rectangle. Shape stays A4; the model is unchanged.
	var first_time := (Model.CATCH_RECT.position.x - 8.0 - 110.0) / 98.0
	var first := world_to_local(Model.free_position(first_time))
	var rest := world_to_local(Model.REST_POINT)
	var half_height := paper_extent().y * 0.5
	var top := first.y + half_height - 8.0 * art_scale()
	var bottom := rest.y + half_height + 18.0 * art_scale()
	var height := bottom - top
	var width := height / sqrt(2.0)
	return Rect2(Vector2(rest.x-width*0.5,top),Vector2(width,height))

func open_folder_surface_rect() -> Rect2:
	# Both physical leaves can receive the first contact after the cover opens.
	var leaf := folder_leaf_rect()
	return Rect2(leaf.position-Vector2(leaf.size.x,0),Vector2(leaf.size.x*2,leaf.size.y))

func _environment(c: CanvasItem, shift: Vector2, past: bool) -> void:
	# Camera remains isotropic for every physical object. Layout changes positions,
	# never the shape of a folder, notebook, window or sheet.
	var unit := art_scale()
	var top := size.y * 0.25
	c.draw_rect(Rect2(-shift,size),Color("243b3d"))
	var window := Rect2(Vector2(-12,16)*unit-shift,Vector2(154,164)*unit)
	c.draw_rect(window.grow(6*unit),Color("14292e"))
	c.draw_rect(window,Color("849b91"))
	# Existing campus foliage, cropped in the renderer (source bytes untouched).
	# Crop contains no chroma-key pixels and uses the same aspect as this window.
	c.draw_texture_rect_region(WINDOW_CANOPY,window,Rect2(575,340,370,395),Color(0.48,0.52,0.47,1))
	c.draw_rect(window,Color(0.27,0.31,0.29,0.50))
	c.draw_rect(Rect2(window.position+Vector2(71,0)*unit,Vector2(6,164)*unit),Color("465e58"))
	c.draw_rect(Rect2(window.position+Vector2(0,68)*unit,Vector2(154,6)*unit),Color("465e58"))
	c.draw_rect(Rect2(window.position+Vector2(-3,164)*unit,Vector2(166,8)*unit),Color("63756b"))
	var radio := Rect2(Vector2(size.x-116*unit,84*unit)-shift,Vector2(88,42)*unit)
	c.draw_rect(radio.grow(3),Color("1b282b"))
	c.draw_rect(radio,Color("4c5145"))
	for i: int in range(16): c.draw_line(radio.position+Vector2(6+i*4,7)*unit,radio.position+Vector2(6+i*4,34)*unit,Color("273536"),unit,true)
	c.draw_circle(radio.position+Vector2(79,20)*unit,3.5*unit,Color("69766c") if broadcast_quiet else INTERACTION)
	# One continuous wood surface: long, low-contrast fibres, not UI separators.
	# The near edge ends before the frame, exposing thickness and the space below.
	var edge_y := size.y-76*unit
	for i: int in range(72):
		var y := top + (edge_y-top)*i/72.0
		var col := Color("80664d").lerp(Color("9b7b56"),float(i)/72.0)
		c.draw_rect(Rect2(Vector2(0,y)-shift,Vector2(size.x,(edge_y-top)/72.0+1)),col)
	for grain: int in range(12):
		var start_x := -32*unit + fmod(grain*83.0,maxf(1,size.x*0.58))
		var baseline := lerpf(top+18*unit,edge_y-22*unit,grain/12.0)
		var length := minf(size.x-start_x,(110+posmod(grain*37,190))*unit)
		var points := PackedVector2Array()
		for point_index: int in range(18):
			var amount := point_index/17.0
			var y := baseline + (sin(amount*PI*1.3+grain*0.8)*3.0+amount*4.0)*unit
			points.append(Vector2(start_x+length*amount,y).round()-shift)
		c.draw_polyline(points,Color(0.28,0.19,0.13,0.085),unit,false)
	# Broad window light is quiet; the paper, rather than foliage, is the highlight.
	c.draw_colored_polygon(PackedVector2Array([Vector2(8*unit,top)-shift,Vector2(145*unit,top)-shift,Vector2(size.x*0.87,edge_y)-shift,Vector2(size.x*0.30,edge_y)-shift]),Color(0.98,0.91,0.71,0.045))
	var bevel := PackedVector2Array([Vector2(0,edge_y)-shift,Vector2(size.x-12*unit,edge_y)-shift,Vector2(size.x,edge_y-8*unit)-shift,Vector2(size.x,edge_y-4*unit)-shift,Vector2(size.x-12*unit,edge_y+4*unit)-shift,Vector2(0,edge_y+4*unit)-shift])
	c.draw_colored_polygon(bevel,Color("b29670"))
	var front := PackedVector2Array([Vector2(0,edge_y+4*unit)-shift,Vector2(size.x-12*unit,edge_y+4*unit)-shift,Vector2(size.x,edge_y-4*unit)-shift,Vector2(size.x,edge_y+12*unit)-shift,Vector2(size.x-12*unit,edge_y+20*unit)-shift,Vector2(0,edge_y+20*unit)-shift])
	c.draw_colored_polygon(front,Color("66503b"))
	c.draw_line(Vector2(0,edge_y+20*unit)-shift,Vector2(size.x-12*unit,edge_y+20*unit)-shift,Color(0.10,0.13,0.12,0.55),3*unit)
	if not reduced_motion:
		for i: int in range(3):
			var p := Vector2(20+fmod(environment_time*27+i*32,120),top+22+i*12)-shift
			c.draw_line(p,p+Vector2(30,-4)*unit,Color(0.92,0.97,0.86,0.20),unit,true)
	if past: c.draw_rect(Rect2(-shift,size),Color(0.19,0.31,0.40,0.28))

func _folder(c: CanvasItem, shift: Vector2, opened: float, front: bool) -> void:
	var base := folder_leaf_rect()
	base.position -= shift
	var unit := art_scale()
	var edge_light := Color("bfb096") if folder_cover else Color("ead09b")
	var edge_dark := Color("625b4b") if folder_cover else Color("775330")
	var hinge_x := base.position.x
	var angle := opened*PI
	var edge_x := hinge_x + base.size.x*cos(angle)
	var lift := sin(angle)*34*unit
	if not front:
		c.draw_rect(Rect2(base.position+Vector2(2,4)*unit,base.size+Vector2(2,1)*unit),Color(0.15,0.10,0.06,0.16))
		c.draw_rect(Rect2(base.position+Vector2(2,5)*unit,base.size),Color("6f5134"))
		if folder_base:
			c.draw_texture_rect(folder_base,base,false,FOLDER_LIGHT)
		else:
			c.draw_rect(base,Color("c8a06a"))
			c.draw_rect(base.grow(-5*unit),Color("ddc08a"))
		for i: int in range(3): c.draw_line(base.position+Vector2(3,base.size.y-3+i*2),base.end+Vector2(-2,-3+i*2),Color("ac9b7e") if folder_base else Color("eed3a0"),unit)
		# Genuine two-leaf folder: the cover turns around its long spine, not a
		# shape-swap or a vertically stretched rectangle.
		var cover := PackedVector2Array([Vector2(hinge_x,base.position.y),Vector2(edge_x,base.position.y-lift),Vector2(edge_x,base.end.y-lift),Vector2(hinge_x,base.end.y)])
		if opened > 0.04 and absf(cos(angle)) > 0.015:
			var cover_shadow := PackedVector2Array()
			var offset := Vector2(3+sin(angle)*10,4+sin(angle)*9)*unit
			for point: Vector2 in cover: cover_shadow.append(point+offset)
			c.draw_colored_polygon(cover_shadow,Color(0.14,0.11,0.08,0.11))
		if absf(cos(angle)) > 0.015:
			var face: Texture2D = folder_inside if opened > 0.5 else folder_cover
			if face:
				var uv := PackedVector2Array([Vector2(0,0),Vector2(1,0),Vector2(1,1),Vector2(0,1)])
				# Both supplied faces have their fold at u=0, anchored to the spine.
				var texture := face
				# Polygon UVs use the underlying texture; explicitly map atlas padding.
				if face is AtlasTexture:
					texture = face.atlas
					for index: int in range(uv.size()):
						uv[index] = (face.region.position+uv[index]*face.region.size)/texture.get_size()
				var shade := FOLDER_LIGHT.darkened(sin(angle)*0.18)
				c.draw_polygon(cover,PackedColorArray([shade]),uv,texture)
			else:
				c.draw_colored_polygon(cover,Color("b58a51").lerp(Color("d6b67d"),opened))
		c.draw_line(cover[1],cover[2],edge_light,unit,true)
		c.draw_line(cover[0],cover[1],edge_light,unit,true)
		c.draw_line(cover[3],cover[2],edge_dark,2*unit,true)
		c.draw_line(Vector2(hinge_x,base.position.y),Vector2(hinge_x,base.end.y),edge_dark,3*unit,true)
		if opened>0.45 and not folder_base:
			# Metal clip and folded hinge make the accepting page unambiguous.
			var clip := Rect2(base.position+Vector2(8,12)*unit,Vector2(18,base.size.y/unit-24)*unit)
			c.draw_rect(clip,Color("6f7770"))
			c.draw_line(clip.position+Vector2(3,2)*unit,Vector2(clip.position.x+3*unit,clip.end.y-2*unit),Color("d5d9ba"),3*unit,true)
			for f: float in [0.2,0.8]: c.draw_circle(Vector2(clip.get_center().x,lerpf(clip.position.y,clip.end.y,f)),3*unit,Color("344746"))
	else:
		if opened < 0.5: return
		# A thin retaining pocket occludes only the lower part of the resting page.
		var y := base.position.y+base.size.y*folder_pocket_start
		if folder_base:
			var texture_size := folder_base.get_size()
			c.draw_texture_rect_region(folder_base,Rect2(Vector2(base.position.x,y),Vector2(base.size.x,base.size.y*(1.0-folder_pocket_start))),Rect2(Vector2(0,texture_size.y*folder_pocket_start),Vector2(texture_size.x,texture_size.y*(1.0-folder_pocket_start))),FOLDER_LIGHT)
			return
		c.draw_colored_polygon(PackedVector2Array([Vector2(base.position.x,y+6*unit),Vector2(base.end.x,y),base.end,Vector2(base.position.x,base.end.y)]),Color("c29a60"))
		c.draw_line(Vector2(base.position.x,y+6*unit),Vector2(base.end.x,y),Color("ead09e"),1.5*unit,true)

func _paper(c: CanvasItem, shift: Vector2, point: Vector2, paper_time: float, grounded: bool, tint: Color = Color.WHITE, collect: float = -1.0, recorded: bool = false) -> void:
	var center := world_to_local(point) - shift
	var scale := art_scale()
	var extent := paper_extent()
	var lift := 0.0
	var departure := 0.0
	if collect >= 0:
		# First lift away from the pocket; then carry the sheet off the desk.
		lift = smoothstep(0.0,0.30,collect)
		departure = smoothstep(0.24,1.0,collect)
		if reduced_motion:
			lift = 0.0
			departure = collect
		center += Vector2(0,-24*scale)*lift + Vector2(-size.x*0.12,size.y*0.57)*departure
		tint.a *= 1.0-smoothstep(0.82,1.0,collect)
	var settle := 1.0
	if grounded and model.catch_time >= 0 and collect < 0:
		settle = clampf((paper_time-model.catch_time)/Model.SETTLE_DURATION,0.0,1.0)
	var shadow_offset := lerpf(18.0,1.5,settle) if grounded else 28.0
	shadow_offset += lift*16.0
	var shadow_center := center + Vector2(3,shadow_offset)*scale
	c.draw_set_transform(shadow_center,0,Vector2(1,0.16))
	c.draw_circle(Vector2.ZERO,23.0*scale,Color(0.12,0.09,0.07,(0.12 if grounded else 0.07)*tint.a))
	c.draw_set_transform(Vector2.ZERO)
	var held: bool = paper_grip.held and collect < 0 and not recorded
	var frame := 0 if grounded or reduced_motion or held else posmod(int(paper_time*7.0),5)
	var angle := 0.0 if reduced_motion else sin(paper_time*2.8)*0.12
	if grounded: angle = lerpf(-0.10,0.0,smoothstep(0.0,0.8,settle))
	if held: angle *= 1.0-grip_amount
	if collect >= 0: angle = -0.12*lift if not reduced_motion else 0.0
	if not grounded and collect < 0 and not recorded: extent *= 1.0-grip_amount*0.035
	c.draw_set_transform(center,angle)
	c.draw_texture_rect(FLIGHT[frame],Rect2(-extent*0.5,extent),false,tint if recorded else tint*PAPER_LIGHT)
	c.draw_set_transform(Vector2.ZERO)

func _paint_record(canvas: CanvasItem) -> void:
	if size.x <= 1 or size.y <= 1: return
	var shift := history_window.position
	_environment(canvas,shift,true)
	_folder(canvas,shift,0.0,false)
	_paper(canvas,shift,Model.free_position(history_time),history_time,false,Color(HISTORY,0.92),-1.0,true)
	_folder(canvas,shift,0.0,true)

func _draw() -> void:
	if not model or size.x <= 1 or size.y <= 1: return
	_environment(self,Vector2.ZERO,false)
	_folder(self,Vector2.ZERO,folder_open_amount,false)
	if paper_grip.held or model.mode == "failed":
		# A local trace explains the reversible path without drawing a second page.
		var path := PackedVector2Array()
		var start := maxf(0.0,model.time-2.4) if paper_grip.held else 0.0
		var finish := minf(7.8,model.time+0.45) if paper_grip.held else 7.8
		for i: int in range(32): path.append(world_to_local(Model.free_position(lerpf(start,finish,i/31.0))))
		draw_polyline(path,Color(INTERACTION,0.40),1.5,true)
	if not model.paper_collected:
		_paper(self,Vector2.ZERO,model.paper_position(),model.time,model.catch_time>=0)
	if model.catch_time < 0.0 and model.time > 7.8 and model.mode != "cancelled":
		_paper(self,Vector2.ZERO,Model.free_position(7.8),7.8,false,Color(INTERACTION,0.48))
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
	# One small direction cue clears the thumb. No duplicate paper/connector box.
	var p := thumb_preview_rect().get_center()
	grip_preview.draw_line(p+Vector2(8,-4),p-Vector2(2,0),Color(INTERACTION,0.8),2,true)
	grip_preview.draw_line(p-Vector2(2,0),p+Vector2(5,6),Color(INTERACTION,0.8),2,true)
