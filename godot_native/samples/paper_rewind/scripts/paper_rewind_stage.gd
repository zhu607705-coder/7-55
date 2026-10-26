extends Control

const Model = preload("res://scripts/paper_rewind_model.gd")
const HistoryWindow = preload("res://scripts/paper_history_window.gd")
const PaperGrip = preload("res://scripts/paper_grip.gd")
const PAPER = preload("res://assets/paper.png")
const INK := Color("26363d")
const PAPER_TONE := Color("eee4c8")
const TEAL := Color("88b6b4")
const FOLDER := Color("c69c65")

var model: RefCounted
var reduced_motion := false
var folder_button: Button
var paper_grip: Control
var history_window: Control
var grip_preview: Control
var history_rect := Rect2(580, 40, 330, 190)
var history_time := 0.0
var environment_time := 0.0
var broadcast_quiet := false
var _world_scale := 1.0
var _world_offset := Vector2.ZERO

func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	folder_button = Button.new()
	folder_button.name = "Folder"
	folder_button.accessibility_name = "文件夹；撑开夹层"
	folder_button.tooltip_text = "文件夹（F）"
	folder_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state: String in ["normal", "hover", "pressed", "disabled"]:
		folder_button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color.TRANSPARENT
	focus.border_color = Color("d9ece5")
	focus.set_border_width_all(3)
	folder_button.add_theme_stylebox_override("focus", focus)
	add_child(folder_button)
	paper_grip = PaperGrip.new()
	paper_grip.name = "PaperGrip"
	add_child(paper_grip)
	history_window = HistoryWindow.new()
	history_window.name = "HistoryWindow"
	history_window.moved.connect(move_history)
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
	_world_scale = minf(size.x / 960.0, size.y / 540.0)
	_world_offset = (size - Vector2(960, 540) * _world_scale) * 0.5
	if folder_button:
		folder_button.position = _world_offset + Model.FOLDER_RECT.position * _world_scale
		folder_button.size = Vector2(Model.FOLDER_RECT.size.x * _world_scale, maxf(44.0, Model.FOLDER_RECT.size.y * _world_scale))
		_layout_grip()
		_layout_history()
		grip_preview.queue_redraw()
	queue_redraw()

func _layout_history() -> void:
	history_window.position = _world_offset + history_rect.position * _world_scale
	history_window.size = history_rect.size * _world_scale
	history_window.world_rect = history_rect
	history_window.world_scale = _world_scale
	history_window.queue_redraw()

func _layout_grip() -> void:
	if not paper_grip or not model:
		return
	var point: Vector2 = model.paper_position()
	if model.catch_time < 0.0 and model.time > 7.8:
		point = Model.free_position(7.8)
	var extent := Vector2.ONE * maxf(48.0, 72.0 * _world_scale)
	paper_grip.size = extent
	paper_grip.position = _world_offset + point * _world_scale - extent * 0.5
	paper_grip.visible = not model.paper_collected and model.mode != "cancelled"
	paper_grip.queue_redraw()

func project_paper_time(screen_point: Vector2) -> float:
	var world_point := (screen_point - global_position - _world_offset) / _world_scale
	var best_time := 0.0
	var best_distance := INF
	# Project onto the physical curved path, not an unrelated horizontal slider.
	for index: int in range(391):
		var at_time := index * 0.02
		var distance: float = Model.free_position(at_time).distance_squared_to(world_point)
		if distance < best_distance:
			best_distance = distance
			best_time = at_time
	return best_time

func move_history(screen_delta: Vector2) -> void:
	if _world_scale <= 0:
		return
	history_rect.position += screen_delta / _world_scale
	history_rect.position.x = clampf(history_rect.position.x, 0, 960 - history_rect.size.x)
	history_rect.position.y = clampf(history_rect.position.y, 0, 540 - history_rect.size.y)
	_layout_history()

func reset_history() -> void:
	history_rect = Rect2(580, 40, 330, 190)
	history_time = 0.0
	_layout_history()

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

func _draw() -> void:
	if not model:
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color("17252d"))
	draw_set_transform(_world_offset, 0.0, Vector2.ONE * _world_scale)
	# Intentionally simple graphic prototype, not replacement production room art.
	draw_rect(Rect2(0, 0, 960, 540), Color("253942"))
	draw_rect(Rect2(42, 42, 275, 235), Color("172d39"))
	draw_rect(Rect2(52, 52, 255, 215), Color("9fbec2"))
	draw_rect(Rect2(72, 72, 103, 175), Color("aacbd0"))
	draw_rect(Rect2(189, 72, 98, 175), Color("bdd5ce"))
	draw_rect(Rect2(173, 52, 15, 215), Color("4e6c72"))
	draw_rect(Rect2(52, 143, 255, 12), Color("4e6c72"))
	# Broadcast display is paired with optional sound; it never changes simulation.
	draw_rect(Rect2(360, 62, 138, 62), Color("172831"))
	draw_rect(Rect2(371, 76, 27, 30), Color("8dabae"))
	for index: int in range(4):
		var height := 5.0 if broadcast_quiet else 12.0 + index * 7.0
		draw_rect(Rect2(411 + index * 18, 109 - height, 9, height), Color("84b5b5") if broadcast_quiet else Color("d3b780"))
	draw_colored_polygon(PackedVector2Array([Vector2(52, 267), Vector2(306, 267), Vector2(890, 460), Vector2(420, 460)]), Color(0.84, 0.83, 0.63, 0.09))
	draw_rect(Rect2(70, 366, 806, 96), Color("604e40"))
	draw_colored_polygon(PackedVector2Array([Vector2(70, 366), Vector2(145, 286), Vector2(852, 286), Vector2(876, 366)]), Color("8b7055"))
	draw_line(Vector2(70, 366), Vector2(876, 366), Color("bca282"), 4)
	draw_rect(Rect2(115, 462, 27, 78), Color("4b423a"))
	draw_rect(Rect2(810, 462, 27, 78), Color("4b423a"))
	# A physical page-rest mark offers comparison without a written solution.
	draw_line(Vector2(360, 332), Vector2(417, 332), Color("b7a080"), 2)
	draw_line(Vector2(360, 332), Vector2(360, 307), Color("b7a080"), 2)
	if not reduced_motion:
		for index: int in range(4):
			var x := 78.0 + fmod(environment_time * 65.0 + index * 78.0, 280.0)
			var y := 182.0 + index * 19.0
			draw_line(Vector2(x, y), Vector2(x + 42, y - 3), Color(0.8, 0.9, 0.88, 0.26), 2)
	# Folder rear and the raised cover are physically different silhouettes.
	draw_rect(Rect2(485, 279, 230, 89), Color("a87b4c"))
	draw_rect(Rect2(485, 269, 86, 17), FOLDER)
	if model.folder_open:
		draw_colored_polygon(PackedVector2Array([Vector2(485, 294), Vector2(502, 218), Vector2(687, 218), Vector2(715, 294)]), Color("d2b180"))
		draw_line(Vector2(502, 218), Vector2(687, 218), Color("e1c79c"), 4)
		draw_rect(Rect2(506, 295, 185, 36), Color("604c3b"))
	else:
		draw_rect(Rect2(485, 279, 230, 69), FOLDER)
		draw_line(Vector2(485, 348), Vector2(715, 348), Color("e2bd85"), 3)
	if model.mode == "rewind" and not reduced_motion:
		for index: int in range(1, 5):
			var p: Vector2 = Model.free_position(minf(Model.DURATION, model.time + index * 0.18))
			draw_circle(p, 8.0 - index, Color(0.55, 0.78, 0.79, 0.22))
	if paper_grip.held or model.mode == "failed":
		for index: int in range(25):
			var trace: Vector2 = Model.free_position(index * 7.8 / 24.0)
			draw_circle(trace, 2.5, Color(0.70, 0.85, 0.84, 0.5))
	var point: Vector2 = model.paper_position()
	var angle := 0.0 if reduced_motion or model.catch_time >= 0.0 else sin(model.time * 3.0) * 0.16
	# On portrait phones the paper itself remains legible, not just its hit box.
	var paper_scale := maxf(_world_scale, 0.67)
	draw_set_transform(_world_offset + point * _world_scale, angle, Vector2.ONE * paper_scale)
	if not model.paper_collected:
		draw_texture_rect(PAPER, Rect2(-24, -29, 48, 58), false)
	draw_set_transform(_world_offset, 0.0, Vector2.ONE * _world_scale)
	if model.catch_time < 0.0 and model.time > 7.8 and model.mode != "cancelled":
		var trace: Vector2 = Model.free_position(7.8)
		var trace_size := Vector2(48, 58) * paper_scale / _world_scale
		draw_texture_rect(PAPER, Rect2(trace - trace_size * 0.5, trace_size), false, Color(0.62, 0.85, 0.91, 0.7))
	# The front lip occludes the paper only while it actually enters the folder.
	if model.folder_open:
		draw_rect(Rect2(485, 322, 230, 46), FOLDER)
		draw_line(Vector2(485, 322), Vector2(715, 322), Color("e6c898"), 4)
	if model.mode in ["intro", "cancelled"]:
		draw_rect(Rect2(0, 0, 960, 540), Color(0.05, 0.09, 0.12, 0.27))
	draw_set_transform(Vector2.ZERO)

func world_to_local(point: Vector2) -> Vector2:
	return _world_offset + point * _world_scale

func thumb_preview_rect() -> Rect2:
	var point := world_to_local(model.paper_position())
	var preview := point - Vector2(0, 64)
	if preview.y < 24:
		preview = point + Vector2(64, 0)
		if preview.x > size.x - 24:
			preview = point - Vector2(64, 0)
	preview.x = clampf(preview.x, 24, maxf(24, size.x - 24))
	preview.y = clampf(preview.y, 24, maxf(24, size.y - 24))
	return Rect2(preview - Vector2(16, 19.5), Vector2(32, 39))

func _draw_grip_preview() -> void:
	if not paper_grip.held or model.paper_collected:
		return
	# Non-interactive top layer: never clipped by the past window or the thumb.
	var preview := thumb_preview_rect()
	grip_preview.draw_line(world_to_local(model.paper_position()), preview.get_center(), Color(0.86, 0.88, 0.75, 0.6), 1.5)
	grip_preview.draw_rect(preview.grow(4), Color("243942"))
	grip_preview.draw_texture_rect(PAPER, preview, false, Color(0.90, 0.98, 0.92, 0.9))
