extends ColorRect
## Main owns this as its modal; the controller remains the only story owner.
signal submit_requested(action: String, value: Dictionary, serial: int)
signal close_requested
const Session = preload("res://scripts/ui/chapter4_device_session.gd")
const Preview = preload("res://scripts/ui/chapter4_device_preview.gd")
const Ui = preload("res://scripts/ui/native_ui_theme.gd")
# Source device palette, scoped here; no shared theme changes.
var bg := Color("e8e5d7")
var surface := Color("ded9c6")
var text_ink := Color("16212a")
var muted := Color("645e51")
var accent := Color("74561f")
var border := Color("23303b")
var session: RefCounted
var frame: PanelContainer
var body: VBoxContainer
var content_grid: GridContainer
var workspace: VBoxContainer
var scroll: ScrollContainer
var close_button: Button
var submit_button: Button
var preview: Control
var readout: Label
var feedback_label: Label
var footer_hint: Label
var footer: VBoxContainer
var _focus_key := ""
var _layout_pending := false

func configure(id: String, state: Dictionary, font: Font = null) -> bool:
	session = Session.new()
	if not session.open(id,state): return false
	if session.mode == "dark":
		bg = Color("071f2b")
		surface = Color("0c4053")
		text_ink = Color("d7f8ff")
		muted = Color("8fd9e9")
		accent = Color("72e9ff")
		border = Color("54d9ff")
	if font != null: theme = Ui.font_theme(font)
	name = "Chapter4DevicePanel"
	color = Color(0.03,0.06,0.08,0.88)
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	z_index = 100
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame = PanelContainer.new()
	frame.name = "Chapter4DeviceFrame"
	frame.minimum_size_changed.connect(_schedule_layout)
	frame.add_theme_stylebox_override("panel",Ui.box(bg,border,3,0,Vector2(16,16)))
	add_child(frame)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",12)
	frame.add_child(column)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation",10)
	column.add_child(header)
	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_box)
	title_box.add_child(label(session.definition.locationLabel+" · "+("深色观察" if session.mode == "dark" else "浅色操作"),13,muted))
	title_box.add_child(label(session.definition.title,20,text_ink))
	close_button = button("×","close",request_close)
	close_button.tooltip_text = "返回现场"
	close_button.custom_minimum_size = Vector2(44,44)
	header.add_child(close_button)
	scroll = ScrollContainer.new()
	scroll.name = "DeviceBodyScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)
	body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation",12)
	scroll.add_child(body)
	footer = VBoxContainer.new()
	footer.add_theme_constant_override("separation",8)
	column.add_child(footer)
	footer_hint = label("痕迹已记下，可以关掉再动手试。" if session.mode == "dark" else "可以反复调整，核对失败会保留当前摆放。",13,muted)
	footer.add_child(footer_hint)
	submit_button = button("提交结果","submit",_submit_or_close)
	footer.add_child(submit_button)
	refresh_view()
	return true

func _ready() -> void:
	resized.connect(func(): layout_panel(size))
	layout_panel(size)
	close_button.grab_focus.call_deferred()

func _schedule_layout() -> void:
	if _layout_pending or not is_inside_tree(): return
	_layout_pending = true
	_finish_layout.call_deferred()

func _finish_layout() -> void:
	_layout_pending = false
	if is_inside_tree(): layout_panel(size)

func layout_panel(available: Vector2) -> void:
	if frame == null: return
	frame.size = Vector2(maxf(1,minf(760,available.x-24)),maxf(1,minf(760,available.y-24)))
	frame.position = (available-frame.size)/2
	if content_grid != null: content_grid.columns = 2 if frame.size.x >= 680 else 1

func label(text: String, pixels: int = 15, ink: Color = Color.TRANSPARENT) -> Label:
	var node := Label.new()
	node.text = text
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node.add_theme_font_size_override("font_size",pixels)
	node.add_theme_color_override("font_color",text_ink if ink.a == 0 else ink)
	return node

func button(text: String, key: String, callback: Callable) -> Button:
	var node := Button.new()
	node.text = text
	node.name = key
	node.custom_minimum_size.y = 44
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	Ui.apply_button(node,surface,text_ink,border,0,2,14,Vector2(10,6),Color("ffcf55"))
	node.pressed.connect(callback)
	return node

func owns_feedback() -> bool:
	return session != null and session.pending

func can_close() -> bool:
	return session == null or not session.pending

func request_close() -> void:
	if can_close(): close_requested.emit()

func dispose_session() -> void:
	if session != null: session.close()

func _submit_or_close() -> void:
	if session.view_kind() != "controls":
		request_close()
		return
	var request: Dictionary = session.begin_submit()
	if request.is_empty(): return
	refresh_view()
	submit_requested.emit(request.action,request.value,request.serial)

func resolve_submission(serial: int, state: Dictionary, result: Dictionary) -> void:
	if session.resolve(serial,state,result): refresh_view()

func sync_authority(state: Dictionary) -> bool:
	if not session.compatible(state): return false
	var old_kind: String = session.view_kind()
	session.update_authority(state)
	if old_kind != session.view_kind(): refresh_view()
	return true

func refresh_view() -> void:
	var previous_scroll := scroll.scroll_vertical
	var focus: Control = get_viewport().gui_get_focus_owner() if is_inside_tree() else null
	if focus != null and is_ancestor_of(focus): _focus_key = str(focus.name)
	for node in body.get_children():
		body.remove_child(node)
		node.queue_free()
	content_grid = GridContainer.new()
	content_grid.columns = 2 if frame.size.x >= 680 else 1
	content_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_grid.add_theme_constant_override("h_separation",14)
	content_grid.add_theme_constant_override("v_separation",12)
	body.add_child(content_grid)
	var figure := VBoxContainer.new()
	figure.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	figure.add_theme_constant_override("separation",8)
	content_grid.add_child(figure)
	workspace = VBoxContainer.new()
	workspace.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	workspace.add_theme_constant_override("separation",10)
	content_grid.add_child(workspace)
	preview = null
	readout = null
	var kind: String = session.view_kind()
	if kind == "controls":
		var caption := HBoxContainer.new()
		caption.add_theme_constant_override("separation",10)
		var art_path: String = session.source.assets[session.puzzle_id].url
		if ResourceLoader.exists(art_path):
			var thumbnail := TextureRect.new()
			thumbnail.texture = load(art_path)
			thumbnail.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			thumbnail.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			thumbnail.custom_minimum_size = Vector2(42,36)
			caption.add_child(thumbnail)
		caption.add_child(label("装置近景 · 当前调节",13,muted))
		figure.add_child(caption)
		preview = Preview.new()
		preview.setup(session)
		figure.add_child(preview)
		readout = label(preview.display_model.caption,14,text_ink)
		readout.name = "DraftReadout"
		figure.add_child(readout)
	else:
		var asset: String = session.source.assets[session.puzzle_id].url
		if ResourceLoader.exists(asset):
			var image := TextureRect.new()
			image.texture = load(asset)
			image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			image.custom_minimum_size.y = 150
			figure.add_child(image)
		figure.add_child(label("记录完成" if session.completed else ("观察残留痕迹" if session.mode == "dark" else "扫描台尚未放入底片"),13,muted))
	workspace.add_child(label(session.definition.darkPrompt if session.mode == "dark" else session.definition.lightPrompt))
	match kind:
		"completed":
			workspace.add_child(label("记录完成",18,accent))
			workspace.add_child(label(session.definition.successText))
		"locked":
			workspace.add_child(label("缺少可校准底片",18,accent))
			workspace.add_child(label("扫描台里还没放底片。301 的索引抽屉存着旧导视胶片。"))
		"observation":
			for trace: String in session.source.traces[session.puzzle_id]: workspace.add_child(label("• "+trace))
		"controls": _controls()
	feedback_label = label(session.feedback,15,Color("9b3e2d") if session.mode == "light" else accent)
	feedback_label.name = "DeviceFeedback"
	feedback_label.visible = not session.feedback.is_empty()
	workspace.add_child(feedback_label)
	close_button.disabled = session.pending
	submit_button.text = "返回现场" if kind != "controls" else ("正在核对…" if session.pending else "提交结果")
	submit_button.disabled = session.pending or (kind == "controls" and not session.can_submit())
	if is_inside_tree(): _restore_view.call_deferred(previous_scroll,_focus_key)

func _restore_view(previous_scroll: int, focus_key: String) -> void:
	if not is_inside_tree(): return
	scroll.scroll_vertical = previous_scroll
	var node := find_child(focus_key,true,false)
	if node is Control and node.is_visible_in_tree() and (not node is BaseButton or not node.disabled): node.grab_focus()

func _edited(changed: bool) -> void:
	if changed: refresh_view()

func _controls() -> void:
	match session.puzzle_id:
		"duty_board", "evacuation_route": _orders()
		"archive_index": _archive_controls()
		"media_alignment", "positioning_calibration": _axis_controls()
		"power_topology": _edge_controls()

func _orders() -> void:
	if session.puzzle_id == "evacuation_route":
		workspace.add_child(label("固定起点：202 教室门口\n固定终点：主楼梯下行口",15,accent))
	var order: Array = session.draft[session.order_key()]
	for index in range(order.size()):
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation",6)
		workspace.add_child(row)
		var title := label("%d  %s" % [index+1,session.source.labels[order[index]]],15)
		title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(title)
		var up := button("上移","up_"+order[index],func(): _edited(session.move_card(index,-1)))
		up.custom_minimum_size.x = 52
		up.disabled = session.pending or index == 0
		row.add_child(up)
		var down := button("下移","down_"+order[index],func(): _edited(session.move_card(index,1)))
		down.custom_minimum_size.x = 52
		down.disabled = session.pending or index == order.size()-1
		row.add_child(down)

func _archive_controls() -> void:
	for key: String in ["yearBand","floor","purpose"]:
		workspace.add_child(label({"yearBand":"年代","floor":"楼层","purpose":"用途"}[key]))
		var choice := OptionButton.new()
		choice.name = "choice_"+key
		choice.custom_minimum_size.y = 44
		choice.fit_to_longest_item = false
		choice.clip_text = true
		Ui.apply_button(choice,surface,text_ink,border,0,2,15,Vector2(10,6),Color("ffcf55"))
		var options: Array = session.source.options[key]
		var draft_key: String = {"yearBand":"archiveYearBand","floor":"archiveFloor","purpose":"archivePurpose"}[key]
		for index in range(options.size()):
			choice.add_item(options[index].label)
			if options[index].value == session.draft[draft_key]: choice.select(index)
		choice.disabled = session.pending
		choice.item_selected.connect(func(index: int): _edited(session.choose(key,options[index].value)))
		workspace.add_child(choice)

func _axis_controls() -> void:
	for key: String in session.source.ranges[session.puzzle_id]:
		var value: int = int(session.draft[session.axis_key()][key])
		var bounds: Array = session.source.ranges[session.puzzle_id][key]
		var rotation := key == "rotationQuarterTurns"
		var pressure := key == "pressure"
		var vertical := key in ["yOffset","vertical"]
		var decrease := "逆时针" if rotation else ("抬起" if pressure else ("向上" if vertical else "向左"))
		var increase := "顺时针" if rotation else ("压下" if pressure else ("向下" if vertical else "向右"))
		var unit := "90°" if rotation else ("1档" if pressure else "1格")
		var display := "%d°" % (value*90) if rotation else ("%d档" % value if pressure else Preview.signed(value)+"格")
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation",6)
		workspace.add_child(row)
		var title := label(session.source.axes[session.puzzle_id][key]+"\n"+display,15)
		title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(title)
		var minus := button(decrease+"\n"+unit,"minus_"+key,func(): _edited(session.step_axis(key,-1)))
		minus.custom_minimum_size.x = 78
		minus.disabled = session.pending or value <= bounds[0]
		row.add_child(minus)
		var plus := button(increase+"\n"+unit,"plus_"+key,func(): _edited(session.step_axis(key,1)))
		plus.custom_minimum_size.x = 78
		plus.disabled = session.pending or value >= bounds[1]
		row.add_child(plus)

func _edge_controls() -> void:
	for edge: String in session.source.edges:
		var selected: bool = edge in session.draft.powerEdges
		var toggle := button(("● " if selected else "○ ")+session.source.edges[edge],"edge_"+edge,func(): _edited(session.toggle_edge(edge)))
		toggle.toggle_mode = true
		toggle.button_pressed = selected
		toggle.disabled = session.pending or (not selected and session.draft.powerEdges.size() >= 5)
		workspace.add_child(toggle)
	workspace.add_child(label("已保留 %d / 5 条" % session.draft.powerEdges.size(),14,accent))
