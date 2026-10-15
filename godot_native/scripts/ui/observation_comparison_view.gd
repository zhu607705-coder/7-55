extends VBoxContainer
## Player-directed comparison only. All content is supplied by the earned-card model.
signal close_requested
const UI = preload("res://scripts/ui/native_ui_theme.gd")
var session: RefCounted
var message: Label
var slots: Array[Button] = []
var content: VBoxContainer
var compare_button: Button
var swap_button: Button

func configure(value: RefCounted) -> void:
	session = value

func _ready() -> void:
	name = "ObservationComparison"
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation",12)
	_render()

func _label(text: String, size_value: int=16, color: Color=UI.INK) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size",size_value)
	label.add_theme_color_override("font_color",color)
	return label

func _button(text: String, id: String, action: Callable, selected: bool=false) -> Button:
	var button := Button.new()
	button.name = id
	button.text = text
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.custom_minimum_size = Vector2(0,48)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UI.apply_button(button,Color("e1ebf0") if selected else UI.PAPER,UI.INK,Color("267b9e") if selected else UI.INK,0,2,16,Vector2(10,10))
	button.pressed.connect(action)
	return button

func _clear_children() -> void:
	for child in get_children(): remove_child(child); child.queue_free()
	slots.clear()

func _render(focus_id: String="") -> void:
	_clear_children()
	if session == null: return
	add_child(_label("把已见过的线索和手中的道具放在一起看看。",16))
	if not session.available():
		add_child(_label("还需要两条可对照的材料。",16))
		add_child(_button("返回游戏","ObservationReturn",func(): close_requested.emit()))
		return
	for index: int in range(2):
		var chosen: Dictionary = session.card(session.selected[index])
		var title := "选择一条材料" if chosen.is_empty() else str(chosen.title)
		var slot := _button(("① " if index==0 else "② ")+title,"ObservationSlot"+str(index),func(): session.select_slot(index); _render("ObservationSlot"+str(index)),session.active_slot==index and session.stage=="selection")
		slots.append(slot); add_child(slot)
	if session.stage == "comparison":
		for index: int in range(2): _comparison_card(session.card(session.selected[index]),index)
		var actions := HBoxContainer.new(); actions.add_theme_constant_override("separation",8); add_child(actions)
		swap_button = _button("交换位置","ObservationSwap",func(): session.swap(); _render("ObservationSwap"))
		actions.add_child(swap_button)
		actions.add_child(_button("重新选取","ObservationReselect",func(): session.select_slot(0); _render("ObservationSlot0")))
		add_child(_button("返回游戏，试试想法","ObservationReturn",func(): close_requested.emit()))
	else:
		compare_button = _button("放在一起对照","ObservationCompare",func():
			if session.compare(): _render("ObservationSlot0"))
		compare_button.disabled = not session.can_compare()
		add_child(compare_button)
		add_child(_label("正在选第 %d 条" % (session.active_slot+1),14,Color("526059")))
		content = VBoxContainer.new(); content.name="ObservationChoices"; content.add_theme_constant_override("separation",6); add_child(content)
		for entry: Dictionary in session.cards:
			var id: String = entry.id
			var selected_elsewhere: bool = session.selected[1-session.active_slot] == id
			var option := _button(str(entry.title)+"\n"+str(entry.kind),"ObservationChoice_"+id.replace(":","_"),func():
				if session.choose(id): _render("ObservationCompare" if session.can_compare() else "ObservationSlot"+str(session.active_slot)))
			option.disabled = selected_elsewhere
			content.add_child(option)
		add_child(_button("清空选择","ObservationClear",func(): session.clear(); _render("ObservationSlot0")))
	if not focus_id.is_empty(): call_deferred("_restore_focus",focus_id)

func _comparison_card(entry: Dictionary, index: int) -> void:
	var panel := PanelContainer.new(); panel.name="ObservationCard"+str(index)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel",UI.box(Color("fffaf0"),Color("87949a"),2,0,Vector2(12,12)))
	var box := VBoxContainer.new(); box.add_theme_constant_override("separation",8); panel.add_child(box)
	box.add_child(_label(str(entry.kind),13,Color("637080")))
	box.add_child(_label(str(entry.title),18))
	var body := _label(str(entry.body),16); body.name="ObservationBody"+str(index); box.add_child(body)
	add_child(panel)

func _restore_focus(id: String) -> void:
	if not is_inside_tree(): return
	var target := find_child(id,true,false)
	if target is Control and target.visible and not (target is Button and target.disabled): target.grab_focus()
