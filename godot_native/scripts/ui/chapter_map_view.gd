extends VBoxContainer

signal replay_requested(id: String)
signal return_requested
signal rewrite_requested
signal restore_requested

const Map = preload("res://scripts/chapters/chapter_map.gd")
const Journal = preload("res://scripts/ui/native_journal_view.gd")
const Ui = preload("res://scripts/ui/native_ui_theme.gd")
const INK := Color("202b35")
const LINE := Color("526b7a")
const PAPER := Color("f4ead5")
const RED := Color("91483f")
const MUTED := Color("645d50")
const BRANCHES := {
	"rules":["核对旧规","book"],"visit":["到馆补录","ledger"],
	"bag":["书包取证","bag"],"receipt":["取出小票","receipt"],
}
const PIXELS := {
	"map":[" 111 111","12221221","12121221","12121121","111 111 "],
	"signpost":["   1    "," 111111 ","12222211"," 111111 ","  1111  "," 13331  ","  111   ","   1    "],
	"ledger":[" 111111 ","1322221 ","1311121 ","1322221 ","1322221 ","1111111 "],
	"clipboard":["  141   "," 111111 "," 122221 "," 121121 "," 122221 "," 121121 "," 111111 "],
	"rewind":["   1    ","  1     ","111111  ","  1   1 ","   1  1 ","  1111  "],
	"lock":["  111   "," 1   1  ","1111111 ","1221221 ","1221221 ","1111111 "],
	"book":["111 111 ","1221221 ","1211121 ","1221221 ","1111111 "],
	"bag":["  111   "," 11111  "," 13331  "," 13331  "," 12121  "," 11111  "],
	"receipt":[" 111111 "," 122221 "," 121121 "," 122221 "," 121121 "," 111111 "," 1 1 1  "],
	"id-card":[" 111111 "," 122221 "," 131121 "," 132221 "," 111111 "],
	"alarm-clock":["1 111 1 "," 11211  "," 12121  "," 12221  ","  111   "," 1   1  "],
	"phone":[" 11111  "," 13331  "," 13331  "," 12221  "," 11111  "],
	"chair":[" 11     "," 11     "," 11111  "," 12221  "," 1   1  "," 1   1  "],
}
var _model: Dictionary
var _buttons: Dictionary = {}
var _icons: Dictionary = {}
var _selected := ""
var _action_line: VBoxContainer
var _node_title: Label
var _node_detail: Label
var _play: Button

func setup(model: Dictionary) -> void:
	_model = model.duplicate(true)
	_selected = str(_model.current)

func _ready() -> void:
	name = "ChapterMap"
	add_theme_constant_override("separation",8)
	_chapter("第一章 · 早八签到", "alarm-clock", ["morning","code","voice"], _selected in ["morning","code","voice"])
	_chapter("第二章 · 基础馆", "map", ["campus","gate","junction","notice","seat"], _selected not in ["morning","code","voice"])
	for title: String in ["第三章","第四章"]:
		var locked := _row(title + " · 暂未开放", "lock")
		locked.disabled = true
		add_child(locked)
	add_child(HSeparator.new())
	_action_line = VBoxContainer.new()
	add_child(_action_line)
	_node_title = _label("",18)
	_node_detail = _label("",14)
	_action_line.add_child(_node_title)
	_action_line.add_child(_node_detail)
	_play = _row("从这里重玩","rewind",true)
	_play.name = "ChapterMapReplay"
	_play.pressed.connect(func(): replay_requested.emit(_selected))
	_action_line.add_child(_play)
	if _model.replaying:
		var back := _row("返回原进度","rewind")
		back.pressed.connect(func(): return_requested.emit())
		_action_line.add_child(back)
		if _model.can_apply:
			var apply := _row("设为主线","clipboard",true)
			apply.pressed.connect(func(): rewrite_requested.emit())
			_action_line.add_child(apply)
	elif _model.restore:
		var restore := _row("恢复改写前的主线","rewind")
		restore.pressed.connect(func(): restore_requested.emit())
		_action_line.add_child(restore)
	_refresh_selection()

func _label(copy: String, size_px: int) -> Label:
	var label := Label.new()
	label.text = copy
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	Journal.style_label(label,size_px,INK,size_px>=18)
	return label

func _row(copy: String, glyph: String, primary := false) -> Button:
	var button := Button.new()
	button.text = copy
	button.custom_minimum_size.y = 44
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.expand_icon = true
	button.add_theme_constant_override("icon_max_width",20)
	button.add_theme_constant_override("h_separation",8)
	button.icon = _icon(glyph, primary)
	Journal.style_button(button)
	if primary: _ink_button(button,true,true)
	return button

func _icon(glyph: String, inverse := false) -> ImageTexture:
	var key := glyph + str(inverse)
	if _icons.has(key): return _icons[key]
	var image := Image.create_empty(8,8,false,Image.FORMAT_RGBA8)
	var pixels: Array = PIXELS[glyph]
	var palette := [Color.TRANSPARENT, PAPER if inverse else INK, PAPER, Color("7993a1"), RED]
	for y: int in pixels.size():
		var row: String = pixels[y]
		for x: int in row.length():
			if row[x] != " ": image.set_pixel(x,y,palette[int(row[x])])
	var texture := ImageTexture.create_from_image(image)
	_icons[key] = texture
	return texture

func _ink_button(button: Button, selected: bool, filled := false) -> void:
	var face := Ui.box(RED if filled else Color("f1d9cb") if selected else PAPER, RED if selected else LINE, 2 if selected else 1, 0, Vector2(8,6))
	for mode: String in ["normal","hover","pressed","hover_pressed"]:
		button.add_theme_stylebox_override(mode,face)
	button.add_theme_color_override("font_color",PAPER if filled else INK)
	button.add_theme_color_override("font_hover_color",PAPER if filled else INK)
	button.texture_filter = Control.TEXTURE_FILTER_NEAREST

func _chapter(title: String, glyph: String, ids: Array, open: bool) -> void:
	var toggle := _row(title,glyph)
	toggle.theme_type_variation = &"FlatButton"
	add_child(toggle)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation",0)
	var panel := _foldable(body)
	for id: String in ids:
		if body.get_child_count() > 0: body.add_child(_stem())
		if id == "junction":
			_add_junction(body)
		else:
			body.add_child(_node(id))
	_bind_fold(toggle,panel,body,title,open)

func _add_junction(body: VBoxContainer) -> void:
	var row := HBoxContainer.new()
	body.add_child(row)
	row.add_child(_node("junction"))
	var toggle := _row("＋","map")
	toggle.accessibility_name = "展开或收起 022 调查路线"
	toggle.custom_minimum_size.x = 48
	toggle.size_flags_horizontal = Control.SIZE_SHRINK_END
	toggle.disabled = not _model.nodes.has("rules")
	row.add_child(toggle)
	var branch := VBoxContainer.new()
	branch.add_theme_constant_override("separation",0)
	var panel := _foldable(branch)
	body.add_child(panel)
	branch.add_child(_stem())
	var fork := HSeparator.new()
	fork.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	branch.add_child(fork)
	var lanes := HBoxContainer.new()
	lanes.add_theme_constant_override("separation",5)
	branch.add_child(lanes)
	for list: Array in [["rules","visit"],["bag"],["receipt"]]:
		var lane := VBoxContainer.new()
		lane.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lane.size_flags_stretch_ratio = 1.0
		lane.add_theme_constant_override("separation",0)
		lanes.add_child(lane)
		for id: String in list:
			lane.add_child(_stem())
			lane.add_child(_node(id,true))
		lane.add_child(_stem())
	branch.add_child(HSeparator.new())
	_bind_fold(toggle,panel,branch,"",false)
	var junction: Button = _buttons["junction"]
	junction.pressed.connect(func():
		if not toggle.disabled and not panel.get_meta("expanded"): toggle.pressed.emit())

func _stem() -> Control:
	var line := ColorRect.new()
	line.color = LINE
	line.custom_minimum_size = Vector2(1,9)
	line.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return line

func _foldable(body: VBoxContainer) -> Control:
	var panel := Control.new()
	panel.clip_contents = true
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_child(body)
	body.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	return panel

func _bind_fold(toggle: Button, panel: Control, body: VBoxContainer, title: String, open: bool) -> void:
	if panel.get_parent() == null: add_child(panel)
	var update_title := func(expanded: bool):
		var cue := "−" if expanded else "＋"
		toggle.text = title + "  " + cue if not title.is_empty() else cue
		toggle.tooltip_text = "收起路线" if expanded else "展开路线"
	panel.set_meta("expanded",open)
	update_title.call(open)
	body.visible = open
	panel.custom_minimum_size.y = body.get_combined_minimum_size().y if open else 0
	body.minimum_size_changed.connect(func():
		if panel.get_meta("expanded") and not panel.has_meta("fold_tween"):
			panel.custom_minimum_size.y = body.get_combined_minimum_size().y)
	toggle.pressed.connect(func():
		var expanding: bool = not panel.get_meta("expanded")
		panel.set_meta("expanded",expanding)
		update_title.call(expanding)
		if panel.has_meta("fold_tween"):
			var prior: Tween = panel.get_meta("fold_tween")
			prior.kill()
			panel.remove_meta("fold_tween")
		if expanding: body.show()
		var goal := body.get_combined_minimum_size().y if expanding else 0.0
		if _model.reduced_motion:
			panel.custom_minimum_size.y = goal
			body.visible = expanding
			return
		var tween := panel.create_tween().set_trans(Tween.TRANS_CUBIC)
		tween.set_ease(Tween.EASE_OUT if expanding else Tween.EASE_IN)
		panel.set_meta("fold_tween",tween)
		tween.tween_property(panel,"custom_minimum_size:y",goal,0.26 if expanding else 0.19)
		tween.tween_callback(func():
			panel.remove_meta("fold_tween")
			body.visible = expanding
			panel.custom_minimum_size.y = body.get_combined_minimum_size().y if expanding else 0)
	)

func _node(id: String, compact := false) -> Button:
	var core: Array = Map.CHECKPOINTS.get(id,[])
	var branch: Array = BRANCHES.get(id,[])
	var label: String = core[0] if not core.is_empty() else branch[0]
	var glyph: String = core[4] if not core.is_empty() else branch[1]
	var status: String = _model.nodes.get(id,"future")
	var tag: String = {"ready":"✓","seen":"✓","future":"◇","blocked":"·","done":"✓","open":"·"}.get(status,"")
	if id == _model.current: tag = "◆"
	if id == _model.replay: tag = "↶"
	var row := _row(label + ("\n" if compact else "  ") + tag,glyph)
	row.name = "ChapterMapStop_" + id
	row.accessibility_name = label + " · " + _status_text(id)
	if compact:
		row.add_theme_constant_override("icon_max_width",14)
		row.add_theme_font_size_override("font_size",13)
	row.disabled = status == "future" and id != _model.current
	row.pressed.connect(func():
		_selected = id
		_refresh_selection())
	_buttons[id] = row
	return row

func _status_text(id: String) -> String:
	if _model.replaying and not id.is_empty() and id == _model.replay: return "回溯中"
	if not id.is_empty() and id == _model.current: return "当前进度"
	var label: String = {"ready":"可重玩","seen":"已到达","future":"未到达","done":"已完成","blocked":"还需核对旧规","open":"调查中"}.get(_model.nodes.get(id,"future"),"未到达")
	return label

func _refresh_selection() -> void:
	for id: String in _buttons:
		_ink_button(_buttons[id],id == _selected)
	var core: Array = Map.CHECKPOINTS.get(_selected,[])
	var branch: Array = BRANCHES.get(_selected,[])
	_node_title.text = core[0] if not core.is_empty() else branch[0] if not branch.is_empty() else "章节地图"
	var ready: bool = _model.nodes.get(_selected) == "ready" and not _model.replaying
	_node_detail.text = str(core[2]) if ready else _status_text(_selected)
	_play.visible = ready
