extends Control

const Registry := preload("registry.gd")
const PlateView := preload("plate_view.gd")
const PreviewFont := preload("assets/MorningNote-Regular.ttf")

var registry := Registry.new()
var building_id := "north1"
var floor_number := 1
var building_picker: OptionButton
var floor_picker: OptionButton
var plate: Control
var empty_notice: Label
var status: Label
var source_button: Button
var detail_panel: ScrollContainer
var detail_text: RichTextLabel
var drawing_panel: Control
var zoom_in: Button
var zoom_out: Button
var fit_button: Button
var background_button: Button
var load_error := ""
var cached_path := ""

func _ready() -> void:
	_build_ui()
	_refresh_floor_picker()
	_refresh()
	building_picker.grab_focus()

func _style(fill: String, edge: String) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(fill)
	style.border_color = Color(edge)
	style.set_border_width_all(1)
	style.set_content_margin_all(10)
	return style

func _button(title: String, callback: Callable) -> Button:
	var result := Button.new()
	result.text = title
	result.custom_minimum_size.y = 44
	result.pressed.connect(callback)
	return result

func _label(text: String, points: int = 17) -> Label:
	var result := Label.new()
	result.text = text
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.add_theme_font_size_override("font_size", points)
	return result

func _build_ui() -> void:
	theme = Theme.new()
	theme.default_font = PreviewFont
	theme.default_font_size = 18
	for type_name in ["Button", "OptionButton"]:
		for state_name in ["normal", "hover", "pressed", "disabled"]:
			theme.set_stylebox(state_name, type_name, _style("243344" if state_name != "pressed" else "3b5061", "556979"))
		theme.set_stylebox("focus", type_name, _style("243344", "ecc776"))
		theme.set_color("font_color", type_name, Color("f3eee0"))
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 12)
	add_child(margin)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 8)
	margin.add_child(body)
	body.add_child(_label("北教 · 真实资料预览", 26))
	body.add_child(_label("独立研究样例｜4 座一层美术候选｜不是可行走楼层", 16))
	var selection := HBoxContainer.new()
	selection.add_theme_constant_override("separation", 8)
	body.add_child(selection)
	building_picker = OptionButton.new()
	building_picker.name = "BuildingPicker"
	building_picker.custom_minimum_size = Vector2(120, 44)
	building_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for building_data: Dictionary in registry.buildings():
		building_picker.add_item(str(building_data.name))
		building_picker.set_item_metadata(building_picker.item_count - 1, str(building_data.id))
	building_picker.item_selected.connect(_on_building_selected)
	selection.add_child(building_picker)
	floor_picker = OptionButton.new()
	floor_picker.name = "FloorPicker"
	floor_picker.custom_minimum_size = Vector2(140, 44)
	floor_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	floor_picker.item_selected.connect(_on_floor_selected)
	selection.add_child(floor_picker)
	var controls := HBoxContainer.new()
	controls.add_theme_constant_override("separation", 6)
	body.add_child(controls)
	fit_button = _button("全图", func(): plate.reset_view())
	zoom_out = _button("−", func(): plate.set_zoom(plate.zoom / 1.25))
	zoom_in = _button("＋", func(): plate.set_zoom(plate.zoom * 1.25))
	zoom_in.tooltip_text = "放大美术候选，不改变源图方向"
	zoom_out.tooltip_text = "缩小美术候选"
	background_button = _button("棋盘", _toggle_background)
	background_button.tooltip_text = "切换透明背景检查"
	source_button = _button("资料", toggle_sources)
	source_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for button in [fit_button, zoom_out, zoom_in, background_button, source_button]:
		controls.add_child(button)
	drawing_panel = Control.new()
	drawing_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	drawing_panel.custom_minimum_size.y = 120
	body.add_child(drawing_panel)
	plate = PlateView.new()
	plate.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	drawing_panel.add_child(plate)
	empty_notice = _label("", 19)
	empty_notice.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	empty_notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	empty_notice.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	empty_notice.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drawing_panel.add_child(empty_notice)
	detail_panel = ScrollContainer.new()
	detail_panel.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	detail_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_panel.custom_minimum_size.y = 120
	detail_panel.visible = false
	body.add_child(detail_panel)
	detail_text = RichTextLabel.new()
	detail_text.bbcode_enabled = false
	detail_text.selection_enabled = true
	detail_text.fit_content = true
	detail_text.scroll_active = false
	detail_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_text.add_theme_font_size_override("normal_font_size", 17)
	detail_panel.add_child(detail_text)
	status = _label("", 16)
	status.add_theme_color_override("font_color", Color("e5c98a"))
	body.add_child(status)
	body.add_child(_label("拖动 / 滚轮查看 · Tab / Enter 选择 · Esc 返回图像\n保持候选原图方向；尚未与测量坐标配准。", 14))

func _on_building_selected(index: int) -> void:
	select_building(str(building_picker.get_item_metadata(index)))

func select_building(value: String) -> bool:
	if registry.building(value).is_empty():
		return false
	building_id = value
	floor_number = 1
	for index in building_picker.item_count:
		if building_picker.get_item_metadata(index) == value:
			building_picker.select(index)
	_refresh_floor_picker()
	_refresh()
	return true

func _refresh_floor_picker() -> void:
	floor_picker.clear()
	for floor_data: Dictionary in registry.building(building_id).get("floors", []):
		var number := int(floor_data.number)
		floor_picker.add_item("%dF · %s" % [number, "候选图" if number == 1 else "仅资料"], number)
		if number == floor_number:
			floor_picker.select(floor_picker.item_count - 1)

func _on_floor_selected(index: int) -> void:
	select_floor(floor_picker.get_item_id(index))

func select_floor(value: int) -> bool:
	if registry.floor_record(building_id, value).is_empty():
		return false
	floor_number = value
	floor_picker.select(floor_picker.get_item_index(value))
	_refresh()
	return true

func _refresh() -> void:
	var floor_data := registry.floor_record(building_id, floor_number)
	var building_data := registry.building(building_id)
	var path := registry.plate_path(building_id, floor_number)
	load_error = ""
	if path != cached_path or plate.texture == null:
		var texture: Texture2D = null
		if not path.is_empty():
			if ResourceLoader.exists(path):
				texture = load(path) as Texture2D
			if texture == null:
				load_error = "候选图无法载入；未以其他楼层替代。"
		plate.set_plate(texture)
		cached_path = path
	empty_notice.visible = plate.texture == null
	empty_notice.text = load_error if not load_error.is_empty() else "%s · %dF\n只有历史图纸资料\n尚无本层美术或可行走几何\n不会复制一层充当此层" % [building_data.get("name", "资料不可用"), floor_number]
	if not registry.errors.is_empty():
		empty_notice.text = "\n".join(registry.errors)
	for button in [fit_button, zoom_in, zoom_out, background_button]:
		button.disabled = plate.texture == null or detail_panel.visible
	status.text = "%s · %dF｜%s｜碰撞 / 楼梯连接未核验" % [building_data.get("name", "未知"), floor_number, "近似美术，不能导航" if plate.texture != null else "资料占位，不可行走"]
	_refresh_sources(building_data, floor_data)

func _refresh_sources(building_data: Dictionary, floor_data: Dictionary) -> void:
	var source := registry.source(str(building_data.get("sourceId", "")))
	var text := "%s · %dF\n\n【资料范围】\n已找到 %d 张分层图；不是现状总层数证明。\n现状总层数：未知。几何配准：未完成。\n\n【官方出处】\n%s\n%s\n\n附件：\n%s\n\n【图纸】\n%s\n图签日期：%s\n%s\n\n【方向与边界】\n%s\n\n【本层实现】\n美术：%s\n可走区域：未提取\n房间多边形：未核验\n楼梯、门与跨层连接：未核验\n\n【下一步需要的证据】\n逐层核对外轮廓、退台、屋面和实际门洞。测量配准后，分别登记可走多边形、实体墙、房间编号与成对楼梯端点。文字标签框不是房间或碰撞边界。\n\n【与正式游戏的关系】\n本样例没有玩家、存档、剧情控制器或生产入口。A1/A2/A3 是已有游戏空间，不自动等同于现实北教楼层。\n" % [building_data.get("name", "未知"), floor_number, building_data.get("floors", []).size(), source.get("title", "未登记"), source.get("noticeUrl", ""), source.get("archiveUrl", ""), (floor_data.get("sourceMember") if floor_data.get("sourceMember") != null else "原始内部文件名待复核（只确认对应楼层资料）"), building_data.get("drawingDate", "未确认"), building_data.get("sourceCaveat", ""), building_data.get("orientationNote", ""), "一层近似候选，门洞与尺寸未配准" if floor_number == 1 else "尚未绘制；不复用其他楼层"]
	if floor_number == 1:
		text += "\n【候选已知差异】\n" + str(building_data.get("artCaveat", ""))
	detail_text.text = text

func _toggle_background() -> void:
	plate.checkerboard = not plate.checkerboard
	background_button.text = "棋盘" if plate.checkerboard else "纯色"
	plate.queue_redraw()

func toggle_sources() -> void:
	detail_panel.visible = not detail_panel.visible
	drawing_panel.visible = not detail_panel.visible
	source_button.text = "返回图像" if detail_panel.visible else "资料"
	if detail_panel.visible:
		detail_panel.scroll_vertical = 0
	_refresh()
	source_button.grab_focus()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE and detail_panel.visible:
		toggle_sources()
		get_viewport().set_input_as_handled()
