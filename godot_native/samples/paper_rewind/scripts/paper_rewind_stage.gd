extends Control

const SceneProjection = preload("res://scripts/paper_scene_projection.gd")
const FolderHit = preload("res://scripts/paper_folder_hit.gd")
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
var history_rect := Rect2(430, 250, 430, 50)
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
var camera := SceneProjection.new()
var graybox := OS.get_cmdline_user_args().has("--graybox")
var _world_scale := 1.0
const PAPER_SIZE := Vector2(112,156)
# Limit pitch by the actual 2-unit clearance above the closed cover.
const MAX_FLUTTER := 0.02

func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	folder_button = FolderHit.new()
	folder_button.hit_test = folder_hit
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
	# No independent per-object screen scales: the whole room shares this camera.
	camera.configure(size)
	_world_scale = camera.scale
	if folder_button:
		folder_button.position = folder_leaf_rect().position
		folder_button.size = folder_leaf_rect().size
		_layout_grip()
		_layout_history()
		grip_preview.queue_redraw()
	queue_redraw()

func _layout_history() -> void:
	history_window.position = history_rect.position * size / Vector2(960,540)
	history_window.size = history_rect.size * size / Vector2(960,540)
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
	var local_point := screen_point - global_position
	var best_time := 0.0
	var best_distance := INF
	for index: int in range(391):
		var at_time := index * 0.02
		var distance: float = world_to_local(Model.free_position(at_time)).distance_squared_to(local_point)
		if distance < best_distance:
			best_distance = distance; best_time = at_time
	return best_time

func move_history(screen_delta: Vector2) -> void:
	history_rect.position += screen_delta * Vector2(960,540) / size
	history_rect.position.x = clampf(history_rect.position.x, 0, 960 - history_rect.size.x)
	history_rect.position.y = clampf(history_rect.position.y, 0, 540 - history_rect.size.y)
	_layout_history()

func reset_history() -> void:
	history_rect = Rect2(430, 250, 430, 50)
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

func model_to_space(point: Vector2) -> Vector3:
	# Existing simulation coordinates are a deterministic path chart, not pixels.
	return Vector3(point.x,150.0+(point.y-170.0)*5.0,10.0)

func world_to_local(point: Vector2) -> Vector2:
	return camera.project(model_to_space(point))

func local_to_world(point: Vector2) -> Vector2:
	var p: Vector3 = camera.unproject_plane(point,10.0)
	return Vector2(p.x,170.0+(p.y-150.0)/5.0)

func art_scale() -> float:
	return camera.scale / (390.0/860.0)

func paper_extent() -> Vector2:
	return _bounds(_project_quad(_plane_quad(Rect2(-PAPER_SIZE*0.5,PAPER_SIZE),10.0))).size

func folder_world_rect() -> Rect2:
	var first_time := (Model.CATCH_RECT.position.x-8.0-110.0)/98.0
	var first := model_to_space(Model.free_position(first_time))
	var rest := model_to_space(Model.REST_POINT)
	var top := first.y+PAPER_SIZE.y*0.5-14.0
	var bottom := rest.y+PAPER_SIZE.y*0.5+24.0
	var length := bottom-top
	return Rect2(Vector2(rest.x-length/sqrt(2.0)*0.5,top),Vector2(length/sqrt(2.0),length))

func folder_leaf_polygon() -> PackedVector2Array:
	return _project_quad(_plane_quad(folder_world_rect(),6.0))

func folder_leaf_rect() -> Rect2:
	return _bounds(folder_leaf_polygon())

func open_folder_surface_rect() -> Rect2:
	var r := folder_world_rect()
	r.position.x -= r.size.x; r.size.x *= 2.0
	return _bounds(_project_quad(_plane_quad(r,6.0)))

func folder_hit(point: Vector2, opened: bool = false, tolerance: float = 0.0) -> bool:
	var q: Vector3 = camera.unproject_plane(point,6.0)
	var r := folder_world_rect()
	if opened: r.position.x -= r.size.x; r.size.x *= 2.0
	return r.grow(tolerance/maxf(camera.scale,0.001)).has_point(Vector2(q.x,q.y))

func folder_drag_amount(start: Vector2, point: Vector2) -> float:
	var a: Vector3 = camera.unproject_plane(start,6.0)
	var b: Vector3 = camera.unproject_plane(point,6.0)
	var r := folder_world_rect()
	return clampf(0.12+maxf((a.x-b.x)/(r.size.x*1.45),(a.y-b.y)/(r.size.y*0.8)),0,0.95)

func _plane_quad(rect: Rect2, height: float) -> Array:
	return [Vector3(rect.position.x,rect.position.y,height),Vector3(rect.end.x,rect.position.y,height),Vector3(rect.end.x,rect.end.y,height),Vector3(rect.position.x,rect.end.y,height)]

func _wall_quad(rect: Rect2, depth: float) -> Array:
	return [Vector3(rect.position.x,depth,rect.end.y),Vector3(rect.end.x,depth,rect.end.y),Vector3(rect.end.x,depth,rect.position.y),Vector3(rect.position.x,depth,rect.position.y)]

func _project_quad(points: Array, shift: Vector2 = Vector2.ZERO) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point: Vector3 in points: result.append(camera.project(point)-shift)
	return result

func _bounds(points: PackedVector2Array) -> Rect2:
	var r := Rect2(points[0],Vector2.ZERO)
	for point: Vector2 in points: r = r.expand(point)
	return r

func _surface(c: CanvasItem, points: Array, color: Color, shift: Vector2, texture: Texture2D = null, crop: Rect2 = Rect2(0,0,1,1)) -> void:
	var mapped := _project_quad(points,shift)
	if graybox or not texture:
		var value := color.get_luminance()
		c.draw_colored_polygon(mapped,Color(value,value,value,color.a) if graybox else color)
		return
	var uv := PackedVector2Array([crop.position,Vector2(crop.end.x,crop.position.y),crop.end,Vector2(crop.position.x,crop.end.y)])
	var source := texture
	if texture is AtlasTexture:
		source = texture.atlas
		for i: int in range(uv.size()): uv[i]=(texture.region.position+uv[i]*texture.region.size)/source.get_size()
	c.draw_polygon(mapped,PackedColorArray([color]),uv,source)

func _edge(c: CanvasItem, a: Vector3, b: Vector3, color: Color, shift: Vector2, width: float = 1.0) -> void:
	c.draw_line(camera.project(a)-shift,camera.project(b)-shift,color,width,true)

func _environment(c: CanvasItem, shift: Vector2, past: bool) -> void:
	c.draw_rect(Rect2(-shift,size),Color("44494a"))
	# Floor, rear wall and tabletop share all three projected world axes.
	_surface(c,_plane_quad(Rect2(-500,-100,2000,1800),-300),Color("434a49"),shift)
	_surface(c,_wall_quad(Rect2(-500,-300,2000,1100),0),Color("697270"),shift)
	_surface(c,_wall_quad(Rect2(18,82,370,456),12),Color("3c4746"),shift)
	var glass := _wall_quad(Rect2(36,100,334,420),-8)
	if graybox:
		_surface(c,glass,Color("a2aaa6"),shift)
	else:
		var canopy := AtlasTexture.new(); canopy.atlas=WINDOW_CANOPY; canopy.region=Rect2(603,340,314,395)
		_surface(c,glass,Color(0.48,0.52,0.47),shift,canopy)
		_surface(c,glass,Color(0.27,0.31,0.29,0.50),shift)
	# Recess reveals and an actual horizontal sill, not a screen-space stripe.
	_surface(c,[Vector3(18,12,538),Vector3(388,12,538),Vector3(370,-8,520),Vector3(36,-8,520)],Color("7a817b"),shift)
	_surface(c,[Vector3(18,12,82),Vector3(36,-8,100),Vector3(36,-8,520),Vector3(18,12,538)],Color("505c57"),shift)
	_surface(c,_wall_quad(Rect2(194,100,14,420),14),Color("66746c"),shift)
	_surface(c,_wall_quad(Rect2(36,306,334,14),14),Color("66746c"),shift)
	_surface(c,_plane_quad(Rect2(8,-8,390,70),82),Color("b3b4a2"),shift)
	_surface(c,_wall_quad(Rect2(8,68,390,14),62),Color("7d887f"),shift)
	# Wall-mounted receiver uses the same wall and height axes.
	_surface(c,_wall_quad(Rect2(730,175,174,80),20),Color("4d5651"),shift)
	for i: int in range(12):
		_edge(c,Vector3(744+i*10,21,186),Vector3(744+i*10,21,242),Color("333d3a"),shift)
	var lamp := camera.project(Vector3(888,23,215))-shift
	c.draw_circle(lamp,2.0*art_scale(),Color("92978e") if broadcast_quiet else Color("eee8cf"))
	# Legs and apron lie below the table, all measured in the same space.
	for x: float in [100.0,870.0]:
		_surface(c,_wall_quad(Rect2(x,-300,35,270),1040),Color("53514b"),shift)
	_surface(c,_wall_quad(Rect2(-160,-36,1260,36),1110),Color("665e50"),shift)
	_surface(c,_plane_quad(Rect2(-160,30,1260,1080),0),Color("a3947c"),shift)
	_edge(c,Vector3(-160,1110,0),Vector3(1100,1110,0),Color("c0b39b"),shift,2.0)
	if not graybox:
		for i: int in range(8):
			_edge(c,Vector3(50+i*35,150+i*115,1),Vector3(380+i*40,160+i*115,1),Color(0.3,0.24,0.16,0.08),shift)
	if not reduced_motion:
		for i: int in range(3):
			var x := 20+fmod(environment_time*27+i*32,120)
			_edge(c,Vector3(x,120+i*35,12),Vector3(x+60,120+i*35,12),Color(0.9,0.9,0.85,0.22),shift)
	if past: c.draw_rect(Rect2(-shift,size),Color(0.19,0.31,0.40,0.28))

func _folder(c: CanvasItem, shift: Vector2, opened: float, front: bool) -> void:
	var r := folder_world_rect()
	if front:
		if opened < 0.5: return
		var pocket := Rect2(Vector2(r.position.x,r.position.y+r.size.y*folder_pocket_start),Vector2(r.size.x,r.size.y*(1.0-folder_pocket_start)))
		_surface(c,_plane_quad(pocket,12),Color("ababaa") if graybox else FOLDER_LIGHT,shift,folder_base,Rect2(0,folder_pocket_start,1,1-folder_pocket_start))
		_edge(c,Vector3(pocket.position.x,pocket.position.y,12),Vector3(pocket.end.x,pocket.position.y,12),Color("777977"),shift)
		return
	_surface(c,_plane_quad(Rect2(r.position+Vector2(6,8),r.size),1),Color(0.15,0.13,0.1,0.16),shift)
	_surface(c,_wall_quad(Rect2(r.position.x,0,r.size.x,6),r.end.y),Color("74726b"),shift)
	_surface(c,_plane_quad(r,6),Color("b9bbba") if graybox else FOLDER_LIGHT,shift,folder_base)
	var angle := opened*PI
	var hinge := r.position.x
	var outer := hinge+r.size.x*cos(angle)
	var height := 8+r.size.x*sin(angle)
	var cover := [Vector3(hinge,r.position.y,8),Vector3(outer,r.position.y,height),Vector3(outer,r.end.y,height),Vector3(hinge,r.end.y,8)]
	var face: Texture2D = folder_inside if opened>0.5 else folder_cover
	_surface(c,cover,Color("c0c1bf").darkened(sin(angle)*0.20) if graybox else FOLDER_LIGHT.darkened(sin(angle)*0.18),shift,face)
	for i: int in range(4): _edge(c,cover[i],cover[(i+1)%4],Color("717570"),shift)
	_edge(c,Vector3(hinge,r.position.y,8),Vector3(hinge,r.end.y,8),Color("6b706a"),shift,2.0)
	if graybox and opened>0.5:
		var clip := Rect2(r.position+Vector2(12,55),Vector2(16,r.size.y*0.55))
		_surface(c,_plane_quad(clip,11),Color("727a78"),shift)
		_edge(c,Vector3(clip.position.x+4,clip.position.y,12),Vector3(clip.position.x+4,clip.end.y,12),Color("dadbd7"),shift,2.0)

func _paper(c: CanvasItem, shift: Vector2, point: Vector2, paper_time: float, grounded: bool, tint: Color = Color.WHITE, collect: float = -1.0, recorded: bool = false) -> void:
	var center := model_to_space(point)
	var opacity := tint.a
	if collect >= 0:
		center.z += 80*smoothstep(0,0.3,collect)
		center.y += 900*smoothstep(0.24,1,collect)
		center.x -= 80*smoothstep(0.24,1,collect)
		opacity *= 1-smoothstep(0.82,1,collect)
	var held: bool = paper_grip.held and collect<0 and not recorded
	var angle := 0.0 if grounded or held or reduced_motion else sin(paper_time*2.8)*0.12
	var flutter := 0.0 if grounded or held or reduced_motion else sin(paper_time*7.0)*MAX_FLUTTER
	var quad: Array = []
	for uv: Vector2 in [Vector2(-0.5,-0.5),Vector2(0.5,-0.5),Vector2(0.5,0.5),Vector2(-0.5,0.5)]:
		var p := (uv*PAPER_SIZE).rotated(angle)
		quad.append(center+Vector3(p.x,p.y*cos(flutter),p.y*sin(flutter)))
	var shadow: Array = []
	for q: Vector3 in quad: shadow.append(Vector3(q.x+4,q.y+5,7))
	_surface(c,shadow,Color(0.1,0.1,0.1,0.09*opacity),shift)
	var frame := 0 if grounded or held or reduced_motion else posmod(int(paper_time*7.0),5)
	_surface(c,quad,Color(0.92,0.93,0.92,opacity) if graybox else Color(tint,opacity)*PAPER_LIGHT,shift,FLIGHT[frame])
	if graybox:
		for i: int in range(4): _edge(c,quad[i],quad[(i+1)%4],Color(0.45,0.47,0.46,opacity),shift)
		_edge(c,quad[0].lerp(quad[3],0.20),quad[1].lerp(quad[2],0.20),Color(0.55,0.57,0.56,opacity),shift)

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
