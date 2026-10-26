extends Control

const World3DScene = preload("res://scripts/paper_world_3d.gd")
const SceneProjection = preload("res://scripts/paper_scene_projection.gd")
const FolderHit = preload("res://scripts/paper_folder_hit.gd")
const Model = preload("res://scripts/paper_rewind_model.gd")
const HistoryWindow = preload("res://scripts/paper_history_window.gd")
const PaperGrip = preload("res://scripts/paper_grip.gd")
const WINDOW_CANOPY = preload("res://assets/window_canopy.png")
const PAPER = preload("res://assets/paper.png")
const FLIGHT = [PAPER, preload("res://assets/paper_flight_1.png"), preload("res://assets/paper_flight_2.png"), preload("res://assets/paper_flight_3.png"), preload("res://assets/paper_flight_4.png")]
var current_viewport: SubViewport
var past_viewport: SubViewport
var current_world: Node3D
var past_world: Node3D
var rendered_world: TextureRect
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
	_build_3d_views()
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

func _build_3d_views() -> void:
	current_viewport = _make_viewport("CurrentRender")
	past_viewport = _make_viewport("PastRender")
	current_world = World3DScene.new(); current_viewport.add_child(current_world)
	past_world = World3DScene.new(); past_viewport.add_child(past_world)
	current_world.setup(self,false); past_world.setup(self,true)
	rendered_world = TextureRect.new()
	rendered_world.name = "Actual3DRender"
	rendered_world.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rendered_world.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rendered_world.texture = current_viewport.get_texture()
	rendered_world.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	add_child(rendered_world)

func _make_viewport(label: String) -> SubViewport:
	var viewport := SubViewport.new()
	viewport.name = label
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.msaa_3d = Viewport.MSAA_2X
	viewport.gui_disable_input = true
	add_child(viewport)
	return viewport

func _layout() -> void:
	# No independent per-object screen scales: the whole room shares this camera.
	camera.configure(size)
	_world_scale = camera.scale
	if current_viewport:
		current_viewport.size = Vector2i(maxi(2,int(size.x)),maxi(2,int(size.y)))
		past_viewport.size = current_viewport.size
		current_world.configure_camera(); past_world.configure_camera()
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
	if current_world:
		current_world.update_scene(); past_world.update_scene()
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

func _paint_record(canvas: CanvasItem) -> void:
	if past_viewport and size.x>1 and size.y>1:
		canvas.draw_texture_rect(past_viewport.get_texture(),Rect2(-history_window.position,size),false)

func _draw() -> void:
	pass # Physical surfaces are rendered by Camera3D; no painted fake shadows.

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
