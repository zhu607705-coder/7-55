extends Control
## Read-only portrait inspection. Animation never writes game or progression state.

signal figure_changed(figure_id: String)
signal dismissed
signal accent_changed

class Artwork extends Control:
	var inspector: Control
	func _draw() -> void:
		if is_instance_valid(inspector): inspector.draw_artwork(self)

var figures: Array = []
var textures: Dictionary
var assets: Dictionary
var source_rect_provider: Callable
var active_id := ""
var phase := "closed"
var reduced_motion := false
var emphasis := 0.0
var serial := 0
var animation: Tween
var backdrop: ColorRect
var panel: PanelContainer
var hero: Artwork
var traveling: Artwork
var title_label: Label
var years_label: Label
var role_label: Label
var biography: RichTextLabel
var source_label: Label
var counter: Label
var previous_button: Button
var next_button: Button
var close_button: Button
var source_button: Button

func configure(data: Array, texture_map: Dictionary, asset_map: Dictionary, ui_font: Font, rect_provider: Callable) -> void:
	figures = data
	textures = texture_map
	assets = asset_map
	source_rect_provider = rect_provider
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 20
	var ui_theme := Theme.new()
	ui_theme.default_font = ui_font
	ui_theme.default_font_size = 18
	ui_theme.set_color("font_color", "Label", Color("382d24"))
	ui_theme.set_color("default_color", "RichTextLabel", Color("382d24"))
	theme = ui_theme
	_build_ui()
	resized.connect(_on_resized)
	hide()
	_layout_panel()

func _label(parent: Node, font_size: int) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(label)
	return label

func _button(parent: Node, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(82, 44)
	button.add_theme_font_size_override("font_size", 17)
	button.pressed.connect(action)
	parent.add_child(button)
	return button

func _build_ui() -> void:
	backdrop = ColorRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.025, 0.03, 0.035, 0.68)
	backdrop.gui_input.connect(_backdrop_input)
	add_child(backdrop)
	panel = PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var style := StyleBoxFlat.new()
	style.bg_color = Color("eee3ca")
	style.border_color = Color("9e8050")
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	panel.minimum_size_changed.connect(func(): _layout_panel.call_deferred())
	var margin := MarginContainer.new()
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 18)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)
	var heading := HBoxContainer.new()
	column.add_child(heading)
	_label(heading, 18).text = "校史人物"
	close_button = _button(heading, "收起", close_portrait)
	var identity := HBoxContainer.new()
	identity.add_theme_constant_override("separation", 18)
	column.add_child(identity)
	hero = Artwork.new()
	hero.inspector = self
	hero.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	hero.mouse_filter = Control.MOUSE_FILTER_IGNORE
	identity.add_child(hero)
	var names := VBoxContainer.new()
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	names.add_theme_constant_override("separation", 8)
	identity.add_child(names)
	title_label = _label(names, 30)
	years_label = _label(names, 17)
	role_label = _label(names, 18)
	for label: Label in [title_label, years_label, role_label]:
		label.custom_minimum_size.x = 120
	biography = RichTextLabel.new()
	biography.size_flags_vertical = Control.SIZE_EXPAND_FILL
	biography.bbcode_enabled = false
	biography.scroll_active = true
	biography.add_theme_constant_override("line_separation", 5)
	column.add_child(biography)
	var source_row := HBoxContainer.new()
	source_row.add_theme_constant_override("separation", 8)
	column.add_child(source_row)
	source_label = _label(source_row, 14)
	source_label.custom_minimum_size.x = 100
	source_button = _button(source_row, "资料来源 ↗", _open_source)
	var navigation := HBoxContainer.new()
	navigation.alignment = BoxContainer.ALIGNMENT_CENTER
	navigation.add_theme_constant_override("separation", 12)
	column.add_child(navigation)
	previous_button = _button(navigation, "上一位", select_offset.bind(-1))
	counter = _label(navigation, 16)
	counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	counter.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	counter.custom_minimum_size.x = 44
	next_button = _button(navigation, "下一位", select_offset.bind(1))
	traveling = Artwork.new()
	traveling.inspector = self
	traveling.mouse_filter = Control.MOUSE_FILTER_IGNORE
	traveling.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	traveling.z_index = 2
	add_child(traveling)
	traveling.hide()

func _layout_panel() -> void:
	if not is_instance_valid(panel): return
	hero.custom_minimum_size = Vector2(76, 90) if size.y < 560 else Vector2(108, 140)
	panel.size = Vector2(minf(620.0, size.x - 24.0), minf(640.0, size.y - 24.0))
	panel.position = (size - panel.size) / 2.0

func _on_resized() -> void:
	_layout_panel()
	if visible and phase in ["opening", "closing"]:
		_stop_animation()
		if phase == "closing": _finish_close(serial)
		else: _finish_open(serial)

func figure_index() -> int:
	for index: int in range(figures.size()):
		if figures[index].id == active_id: return index
	return -1

func _fill_content() -> void:
	var index := figure_index()
	var figure: Dictionary = figures[index]
	title_label.text = figure.name
	years_label.text = figure.years
	role_label.text = figure.role
	biography.text = "\n\n".join(figure.biography)
	biography.scroll_to_line(0)
	source_label.text = figure.sourceLabel
	counter.text = "%d / %d" % [index + 1, figures.size()]
	hero.queue_redraw()
	traveling.queue_redraw()

func open_portrait(figure_id: String) -> void:
	if not figures.any(func(row): return row.id == figure_id): return
	_stop_animation()
	serial += 1
	var ticket := serial
	active_id = figure_id
	phase = "opening"
	show()
	_fill_content()
	_layout_panel()
	phase = "opening"
	backdrop.modulate.a = 0.0
	panel.modulate.a = 0.0
	hero.hide()
	biography.visible_ratio = 0.0
	figure_changed.emit(active_id)
	if reduced_motion:
		_finish_open(ticket)
		return
	await get_tree().process_frame
	await get_tree().process_frame
	if ticket != serial or phase != "opening": return
	var start: Rect2 = source_rect_provider.call(active_id)
	var target := hero.get_global_rect()
	traveling.position = start.position
	traveling.size = start.size
	traveling.show()
	animation = create_tween().set_parallel(true)
	animation.tween_property(backdrop, "modulate:a", 1.0, 0.24)
	animation.tween_property(panel, "modulate:a", 1.0, 0.28).set_delay(0.1)
	animation.tween_property(traveling, "position", target.position, 0.38).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	animation.tween_property(traveling, "size", target.size, 0.38).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	animation.tween_method(_set_emphasis, 0.0, 1.0, 0.3)
	animation.chain().tween_callback(_finish_open.bind(ticket))

func _finish_open(ticket: int) -> void:
	if ticket != serial: return
	phase = "open"
	backdrop.modulate.a = 1.0
	panel.modulate.a = 1.0
	traveling.hide()
	hero.show()
	hero.modulate.a = 1.0
	_set_emphasis(1.0)
	biography.visible_ratio = 1.0
	close_button.grab_focus()

func select_offset(offset: int) -> void:
	if phase not in ["opening", "open"]: return
	_stop_animation()
	serial += 1
	active_id = figures[posmod(figure_index() + offset, figures.size())].id
	_fill_content()
	phase = "open"
	traveling.hide()
	hero.show()
	backdrop.modulate.a = 1.0
	panel.modulate.a = 1.0
	biography.visible_ratio = 1.0
	figure_changed.emit(active_id)
	if not reduced_motion:
		hero.modulate.a = 0.2
		animation = create_tween()
		animation.tween_property(hero, "modulate:a", 1.0, 0.22)
	else: hero.modulate.a = 1.0

func close_portrait() -> void:
	if phase in ["closed", "closing"]: return
	_stop_animation()
	serial += 1
	var ticket := serial
	phase = "closing"
	if reduced_motion:
		_finish_close(ticket)
		return
	var start := Rect2(traveling.position, traveling.size) if traveling.visible else hero.get_global_rect()
	var target: Rect2 = source_rect_provider.call(active_id)
	traveling.position = start.position
	traveling.size = start.size
	traveling.show()
	hero.hide()
	animation = create_tween().set_parallel(true)
	animation.tween_property(panel, "modulate:a", 0.0, 0.15)
	animation.tween_property(backdrop, "modulate:a", 0.0, 0.28)
	animation.tween_property(traveling, "position", target.position, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	animation.tween_property(traveling, "size", target.size, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	animation.tween_method(_set_emphasis, emphasis, 0.0, 0.3)
	animation.chain().tween_callback(_finish_close.bind(ticket))

func _finish_close(ticket: int) -> void:
	if ticket != serial: return
	phase = "closed"
	_set_emphasis(0.0)
	traveling.hide()
	hero.modulate.a = 1.0
	active_id = ""
	hide()
	dismissed.emit()

func _stop_animation() -> void:
	if animation != null and animation.is_valid(): animation.kill()

func reset() -> void:
	_stop_animation()
	serial += 1
	if phase != "closed": _finish_close(serial)

func set_reduced_motion(value: bool) -> void:
	reduced_motion = value
	if value and visible:
		_stop_animation()
		serial += 1
		if phase == "closing": _finish_close(serial)
		else: _finish_open(serial)

func _set_emphasis(value: float) -> void:
	emphasis = value
	accent_changed.emit()

func _backdrop_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed) or (event is InputEventScreenTouch and event.pressed):
		close_portrait()
		accept_event()

func _input(event: InputEvent) -> void:
	if not visible or not event is InputEventKey or not event.pressed or event.echo: return
	match event.keycode:
		KEY_ESCAPE: close_portrait()
		KEY_LEFT: select_offset(-1)
		KEY_RIGHT: select_offset(1)
		_: return
	get_viewport().set_input_as_handled()

func _open_source() -> void:
	var url: String = figures[figure_index()].sourceUrl
	if url.begins_with("https://"): OS.shell_open(url)

func draw_artwork(canvas: Control) -> void:
	if active_id.is_empty(): return
	var frame: Dictionary = assets.a3_frame
	var source: Array = frame.sourceRect
	var ratio := minf(canvas.size.x / float(source[2]), canvas.size.y / float(source[3]))
	var frame_size := Vector2(float(source[2]), float(source[3])) * ratio
	var destination := Rect2((canvas.size - frame_size) / 2.0, frame_size)
	var aperture: Array = frame.contentRect
	var interior := Rect2(destination.position + Vector2(float(aperture[0]) - float(source[0]), float(aperture[1]) - float(source[1])) * ratio, Vector2(float(aperture[2]), float(aperture[3])) * ratio)
	var portrait_id := "portrait_" + active_id
	var photo: Array = assets[portrait_id].sourceRect
	var photo_size := Vector2(float(photo[2]), float(photo[3]))
	var photo_scale := minf(interior.size.x / photo_size.x, interior.size.y / photo_size.y)
	var fitted := photo_size * photo_scale
	canvas.draw_texture_rect_region(textures[portrait_id], Rect2(interior.position + (interior.size - fitted) / 2.0, fitted), Rect2(float(photo[0]), float(photo[1]), float(photo[2]), float(photo[3])))
	canvas.draw_texture_rect_region(textures.a3_frame, destination, Rect2(float(source[0]), float(source[1]), float(source[2]), float(source[3])))
