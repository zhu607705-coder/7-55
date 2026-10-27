extends Control
## Standalone art review only. It never reads or writes game state.

const WORLD_SIZE := Vector2(1672, 941)
const PORTRAIT_INTERACTION := preload("res://portrait_interaction.gd")
class Board extends Control:
	var review: Control
	func _draw() -> void:
		if is_instance_valid(review): review.draw_board(self)
	func _gui_input(event: InputEvent) -> void:
		if is_instance_valid(review): review.board_input(self, event)
var manifest: Dictionary
var textures: Dictionary = {}
var hit_test_images: Dictionary = {}
var placements: Dictionary = {"a3": []}
var hidden_objects: Dictionary = {}
var selected_floor := "a3"
var mode := "empty"
var full_floor_capture := false
var board_rect := Rect2()
var board_scale := 1.0
var board: Board
var zoom_factor := 1.0
var pan_offset := Vector2.ZERO
var pointer_down := false
var pointer_dragged := false
var pointer_start := Vector2.ZERO
var status_label: Label
var font: Font
var controls_column: VBoxContainer
var portrait_inspector: Control
var portrait_frames: Dictionary = {}
var portrait_ids: Array[String] = []
var focused_portrait_id := "zhu_kezhen"
var hovered_portrait_id := ""

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	manifest = JSON.parse_string(FileAccess.get_file_as_string("res://asset_manifest.json"))
	font = load("res://assets/MorningNote-Regular.ttf")
	for floor_id: String in manifest.backgrounds:
		for state: String in ["empty", "original"]:
			textures[floor_id + "_" + state] = load(manifest.backgrounds[floor_id][state])
	for id: String in manifest.objects:
		textures[id] = load(manifest.objects[id].texture)
	_build_placements()
	board = Board.new()
	board.review = self
	board.clip_contents = true
	board.mouse_filter = Control.MOUSE_FILTER_STOP
	board.focus_mode = Control.FOCUS_ALL
	board.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(board)
	_build_controls()
	var portrait_data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://portrait_interaction_data.json"))
	for figure: Dictionary in portrait_data.figures:
		portrait_ids.append(figure.id)
	portrait_inspector = PORTRAIT_INTERACTION.new()
	add_child(portrait_inspector)
	portrait_inspector.configure(portrait_data.figures, textures, manifest.objects, font, _portrait_screen_rect)
	portrait_inspector.figure_changed.connect(_portrait_changed)
	portrait_inspector.accent_changed.connect(board.queue_redraw)
	portrait_inspector.dismissed.connect(board.grab_focus)
	for arg: String in OS.get_cmdline_user_args():
		if arg == "--objects": mode = "objects"
		if arg == "--capture-floor": full_floor_capture = true
	if full_floor_capture:
		controls_column.hide()
	_refresh_status()
	resized.connect(_layout_board)
	_layout_board()
	queue_redraw()
	if "--capture" in OS.get_cmdline_user_args() or full_floor_capture:
		_capture_review()

func _button(parent: Container, title: String, action: Callable) -> void:
	var control := Button.new()
	control.text = title
	control.custom_minimum_size = Vector2(78, 36)
	control.add_theme_font_override("font", font)
	control.add_theme_font_size_override("font_size", 16)
	control.pressed.connect(action)
	parent.add_child(control)

func _build_controls() -> void:
	controls_column = VBoxContainer.new()
	controls_column.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	controls_column.offset_left = 12
	controls_column.offset_right = -12
	controls_column.offset_top = 8
	add_child(controls_column)
	controls_column.resized.connect(_layout_board)
	var controls := HFlowContainer.new()
	controls.add_theme_constant_override("separation", 7)
	controls_column.add_child(controls)
	_button(controls, "空白底图", _select_mode.bind("empty"))
	_button(controls, "独立物件", _select_mode.bind("objects"))
	_button(controls, "原始整图", _select_mode.bind("original"))
	_button(controls, "人物", _inspect_focused_portrait)
	_button(controls, "恢复物件", _reset_objects)
	_button(controls, "＋", _change_zoom.bind(1.5))
	_button(controls, "－", _change_zoom.bind(1.0 / 1.5))
	_button(controls, "全图", _reset_view)
	var reduce_motion := CheckButton.new()
	reduce_motion.text = "减少动画"
	reduce_motion.custom_minimum_size = Vector2(122, 36)
	reduce_motion.add_theme_font_override("font", font)
	reduce_motion.add_theme_font_size_override("font_size", 16)
	reduce_motion.toggled.connect(func(value: bool): portrait_inspector.set_reduced_motion(value))
	controls.add_child(reduce_motion)
	status_label = Label.new()
	status_label.add_theme_font_override("font", font)
	status_label.add_theme_font_size_override("font_size", 15)
	status_label.add_theme_color_override("font_color", Color(0.83, 0.88, 0.91))
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	controls_column.add_child(status_label)

func _select_mode(value: String) -> void:
	mode = value
	if is_instance_valid(portrait_inspector) and value != "objects": portrait_inspector.reset()
	if value == "objects": board.grab_focus()
	_refresh_status()
	board.queue_redraw()

func _reset_objects() -> void:
	hidden_objects.clear()
	_refresh_status()
	board.queue_redraw()

func _change_zoom(factor: float) -> void:
	zoom_factor = clampf(zoom_factor * factor, 1.0, 4.0)
	pan_offset = Vector2.ZERO
	board.queue_redraw()

func _reset_view() -> void:
	zoom_factor = 1.0
	pan_offset = Vector2.ZERO
	board.queue_redraw()

func _layout_board() -> void:
	if not is_instance_valid(board) or not is_instance_valid(controls_column): return
	if full_floor_capture:
		board.position = Vector2.ZERO
		board.size = size
		board.queue_redraw()
		return
	var top := maxf(91.0, controls_column.position.y + controls_column.size.y + 15.0)
	board.position = Vector2(12, top)
	board.size = Vector2(maxf(size.x - 24.0, 1.0), maxf(size.y - top - 12.0, 1.0))
	board.queue_redraw()

func _refresh_status() -> void:
	var description: String = {"empty": "空白建筑底图", "objects": "透明物件试排（尚未完整）", "original": "原始整图"}[mode]
	status_label.text = "%s · %s  |  点按画像阅读；← → 选择，Space 展开；放大后拖动查看。" % [selected_floor.to_upper(), description]

func _add(floor_id: String, object_id: String, texture_id: String, bounds: Rect2, anchor: Vector2 = Vector2(0.5, 1.0)) -> void:
	placements[floor_id].append({"id": object_id, "texture": texture_id, "bounds": bounds, "anchor": anchor})

func _build_placements() -> void:
	var a3: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://a3_review_layout.json"))
	for row: Dictionary in a3.placements:
		var bounds: Array = row.bounds
		var anchor: Array = row.get("anchor", [0.5, 1.0])
		_add("a3", row.id, row.texture, Rect2(float(bounds[0]), float(bounds[1]), float(bounds[2]), float(bounds[3])), Vector2(float(anchor[0]), float(anchor[1])))
		if String(row.id).begins_with("frame_"):
			portrait_frames[String(row.id).trim_prefix("frame_")] = placements.a3.back()

func _fitted_rect(row: Dictionary) -> Rect2:
	var source: Array = manifest.objects[row.texture].sourceRect
	var source_size := Vector2(float(source[2]), float(source[3]))
	var bounds: Rect2 = row.bounds
	var uniform_scale := minf(bounds.size.x / source_size.x, bounds.size.y / source_size.y)
	var result_size := source_size * uniform_scale
	var anchor: Vector2 = row.get("anchor", Vector2(0.5, 1.0))
	return Rect2(bounds.position + (bounds.size - result_size) * anchor, result_size)

func draw_board(canvas: Control) -> void:
	var available := canvas.size
	board_scale = minf(available.x / WORLD_SIZE.x, available.y / WORLD_SIZE.y) * zoom_factor
	var board_size := WORLD_SIZE * board_scale
	for axis: int in range(2):
		var limit := maxf(0.0, (board_size[axis] - available[axis]) / 2.0)
		pan_offset[axis] = clampf(pan_offset[axis], -limit, limit)
	board_rect = Rect2((available - board_size) / 2.0 + pan_offset, board_size)
	var state := "original" if mode == "original" else "empty"
	if textures.has(selected_floor + "_" + state):
		canvas.draw_texture_rect(textures[selected_floor + "_" + state], board_rect, false)
	if mode != "objects":
		return
	for row: Dictionary in placements[selected_floor]:
		if hidden_objects.has(row.id):
			continue
		var source: Array = manifest.objects[row.texture].sourceRect
		var src := Rect2(float(source[0]), float(source[1]), float(source[2]), float(source[3]))
		var fitted := _fitted_rect(row)
		var destination := Rect2(board_rect.position + fitted.position * board_scale, fitted.size * board_scale)
		var tint := Color.WHITE
		if String(row.id).begins_with("frame_"):
			var id: String = String(row.id).trim_prefix("frame_")
			var accent := 0.3 if id == focused_portrait_id or id == hovered_portrait_id else 0.0
			if is_instance_valid(portrait_inspector) and id == portrait_inspector.active_id:
				accent = maxf(accent, portrait_inspector.emphasis)
			tint = Color(1.0 + accent * 0.1, 1.0 + accent * 0.06, 1.0, 1.0)
		canvas.draw_texture_rect_region(textures[row.texture], destination, src, tint)

func board_input(canvas: Control, event: InputEvent) -> void:
	if is_instance_valid(portrait_inspector) and portrait_inspector.visible: return
	if event is InputEventMouseMotion and not pointer_down:
		var hovered := _portrait_at(event.position)
		if hovered != hovered_portrait_id:
			hovered_portrait_id = hovered
			canvas.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if not hovered.is_empty() else Control.CURSOR_ARROW
			canvas.queue_redraw()
	if event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		_change_zoom(1.5 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / 1.5)
		canvas.accept_event()
		return
	if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT) or event is InputEventScreenTouch:
		if event.pressed:
			pointer_down = true
			pointer_dragged = false
			pointer_start = event.position
		elif pointer_down:
			pointer_down = false
			if not pointer_dragged: _toggle_object_at(event.position)
		canvas.accept_event()
	elif pointer_down and (event is InputEventMouseMotion or event is InputEventScreenDrag):
		if event.position.distance_to(pointer_start) > 5.0: pointer_dragged = true
		if pointer_dragged:
			pan_offset += event.relative
			board.queue_redraw()
		canvas.accept_event()

func _toggle_object_at(position: Vector2) -> void:
	if mode != "objects" or not board_rect.has_point(position): return
	var figure_id := _portrait_at(position)
	if not figure_id.is_empty():
		_open_portrait(figure_id)
		return
	var point: Vector2 = (position - board_rect.position) / board_scale
	var rows: Array = placements[selected_floor]
	for index: int in range(rows.size() - 1, -1, -1):
		var row: Dictionary = rows[index]
		if not hidden_objects.has(row.id) and _object_contains_point(row, point):
			hidden_objects[row.id] = true
			board.queue_redraw()
			return

func _portrait_at(position: Vector2) -> String:
	if mode != "objects" or board_scale <= 0.0: return ""
	var closest := ""
	var distance := INF
	for id: String in portrait_ids:
		if hidden_objects.has("frame_" + id) or hidden_objects.has("portrait_" + id): continue
		var fitted := _fitted_rect(portrait_frames[id])
		var rendered := Rect2(board_rect.position + fitted.position * board_scale, fitted.size * board_scale)
		var hit_size := rendered.size.max(Vector2(32, 44))
		var hit := Rect2(rendered.get_center() - hit_size / 2.0, hit_size)
		var candidate_distance := position.distance_squared_to(rendered.get_center())
		if hit.has_point(position) and candidate_distance < distance:
			closest = id
			distance = candidate_distance
	return closest

func _portrait_screen_rect(id: String) -> Rect2:
	var fitted := _fitted_rect(portrait_frames[id])
	return Rect2(board.global_position + board_rect.position + fitted.position * board_scale, fitted.size * board_scale)

func _open_portrait(id: String) -> void:
	focused_portrait_id = id
	pointer_down = false
	portrait_inspector.open_portrait(id)
	board.queue_redraw()

func _inspect_focused_portrait() -> void:
	if mode != "objects": _select_mode("objects")
	_open_portrait(focused_portrait_id)

func _portrait_changed(id: String) -> void:
	focused_portrait_id = id
	board.queue_redraw()

func _input(event: InputEvent) -> void:
	if mode != "objects" or portrait_inspector.visible or not board.has_focus() or not event is InputEventKey or not event.pressed or event.echo: return
	match event.keycode:
		KEY_LEFT, KEY_RIGHT:
			var direction := -1 if event.keycode == KEY_LEFT else 1
			focused_portrait_id = portrait_ids[posmod(portrait_ids.find(focused_portrait_id) + direction, portrait_ids.size())]
			board.queue_redraw()
		KEY_SPACE, KEY_ENTER: _open_portrait(focused_portrait_id)
		_: return
	get_viewport().set_input_as_handled()

func _object_contains_point(row: Dictionary, point: Vector2) -> bool:
	var fitted := _fitted_rect(row)
	if not fitted.has_point(point): return false
	var texture_id: String = row.texture
	if not hit_test_images.has(texture_id):
		var texture: Texture2D = textures.get(texture_id)
		if texture == null: return false
		hit_test_images[texture_id] = texture.get_image()
	var source: Array = manifest.objects[texture_id].sourceRect
	var relative := (point - fitted.position) / fitted.size
	var image: Image = hit_test_images[texture_id]
	var x := clampi(int(float(source[0]) + relative.x * float(source[2])), 0, image.get_width() - 1)
	var y := clampi(int(float(source[1]) + relative.y * float(source[3])), 0, image.get_height() - 1)
	return image.get_pixel(x, y).a >= 0.05

func _capture_review() -> void:
	var capture_viewport: Viewport = get_viewport()
	if full_floor_capture:
		# Native macOS windows can round their height to an even number.
		# Render the same board at the exact source size in a separate viewport.
		var floor_viewport := SubViewport.new()
		floor_viewport.size = Vector2i(WORLD_SIZE)
		floor_viewport.disable_3d = true
		floor_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		add_child(floor_viewport)
		var capture_board := Board.new()
		capture_board.review = self
		capture_board.size = WORLD_SIZE
		capture_board.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		floor_viewport.add_child(capture_board)
		capture_viewport = floor_viewport
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := capture_viewport.get_texture().get_image()
	var output := OS.get_environment("NORTH_CLEAN_CAPTURE")
	if not output.is_empty():
		image.save_png(output)
	get_tree().quit()
