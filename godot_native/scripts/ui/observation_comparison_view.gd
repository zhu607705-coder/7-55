extends VBoxContainer
## Player-directed comparison only. All content is supplied by the earned-card model.
signal close_requested
const UI = preload("res://scripts/ui/native_ui_theme.gd")
const Typography = preload("res://scripts/ui/native_typography.gd")
const Hardware = preload("res://scripts/ui/interaction_chrome.gd")
const ItemArt = preload("res://scripts/ui/phone_chrome.gd")
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
	Typography.apply_body(label)
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size",maxi(15,size_value))
	label.add_theme_color_override("font_color",color)
	return label

func _button(text: String, id: String, action: Callable, selected: bool=false) -> Button:
	var button := Button.new()
	button.name = id
	button.text = text
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.custom_minimum_size = Vector2(0,48)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Typography.apply_body(button)
	button.add_theme_font_size_override("font_size",16)
	for state_name in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
		button.add_theme_color_override(state_name,Hardware.INK)
	button.add_theme_color_override("font_disabled_color",Color("6d736f"))
	var normal := Hardware.style(Color("f5efdf"),Hardware.CORAL if selected else Hardware.EDGE,1)
	normal.content_margin_left=12; normal.content_margin_right=12
	normal.content_margin_top=10; normal.content_margin_bottom=10
	var hover: StyleBoxFlat=normal.duplicate(); hover.bg_color=Color("eee3cd")
	Hardware.apply_states(button,normal,hover)
	Hardware.set_selected(button,selected)
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
			_add_option_art(option,entry)
		add_child(_button("清空选择","ObservationClear",func(): session.clear(); _render("ObservationSlot0")))
	if not focus_id.is_empty(): call_deferred("_restore_focus",focus_id)

func _item_art(entry: Dictionary, extent: float) -> Control:
	var id := str(entry.get("id",""))
	if not id.begins_with("item:"): return null
	id = id.trim_prefix("item:")
	if not ItemArt.PIXEL_ICONS.has(id) and not ItemArt.RASTER_ICONS.has(id): return null
	# Reuse source item art, never an invented symbol or a Main/State instance.
	var icon := ItemArt.PixelIcon.new()
	icon.name = "ObservationItemArt_"+id
	icon.pixels = ItemArt.PIXEL_ICONS.get(id,{})
	if ItemArt.RASTER_ICONS.has(id): icon.raster = load(ItemArt.RASTER_ICONS[id])
	icon.custom_minimum_size = Vector2.ONE*extent
	icon.size = Vector2.ONE*extent
	return icon

func _add_option_art(option: Button, entry: Dictionary) -> void:
	var icon := _item_art(entry,32)
	if icon == null: return
	option.set_meta("tactile_keep_layout",true)
	for state_name in ["normal","hover","pressed","hover_pressed","disabled"]:
		var style: StyleBoxFlat = option.get_theme_stylebox(state_name).duplicate()
		style.content_margin_left = 56
		option.add_theme_stylebox_override(state_name,style)
	option.add_child(icon)
	icon.anchor_top=.5; icon.anchor_bottom=.5
	icon.offset_left=12; icon.offset_right=44
	icon.offset_top=-16; icon.offset_bottom=16

func _comparison_card(entry: Dictionary, index: int) -> void:
	var panel := PanelContainer.new(); panel.name="ObservationCard"+str(index)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# The containing notebook owns the paper; cards are unboxed content leaves.
	var leaf := Hardware.style(Color.TRANSPARENT,Hardware.EDGE,0)
	leaf.border_width_bottom=1
	leaf.content_margin_left=4; leaf.content_margin_right=4
	leaf.content_margin_top=8; leaf.content_margin_bottom=16
	panel.add_theme_stylebox_override("panel",leaf)
	var box := VBoxContainer.new(); box.add_theme_constant_override("separation",8); panel.add_child(box)
	var heading := HBoxContainer.new(); heading.add_theme_constant_override("separation",12); box.add_child(heading)
	var icon := _item_art(entry,40)
	if icon != null: heading.add_child(icon)
	var titles := VBoxContainer.new(); titles.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	heading.add_child(titles)
	titles.add_child(_label(str(entry.kind),15,Color("637080")))
	titles.add_child(_label(str(entry.title),18))
	var body := _label(str(entry.body),16); body.name="ObservationBody"+str(index); box.add_child(body)
	add_child(panel)

func _restore_focus(id: String) -> void:
	if not is_inside_tree(): return
	var target := find_child(id,true,false)
	if target is Control and target.visible and not (target is Button and target.disabled): target.grab_focus()
