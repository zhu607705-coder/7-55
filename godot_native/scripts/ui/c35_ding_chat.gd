extends RefCounted
## Views for the interlude's simulated DingTalk conversations.
const NativeUi = preload("res://scripts/ui/native_ui_theme.gd")
const Typography = preload("res://scripts/ui/native_typography.gd")
const BACKDROP := Color("edf1f6")
const WHITE := Color("ffffff")
const INK := Color("142332")
const MUTED := Color("485b6d")
const LINK := Color("155cad")
const AVATAR := Color("d8e8ff")
const OUTGOING := Color("d4e8ff")
const LINE := Color("bacdde")
const GROUP_NAME := "微积分（甲）课程群"
const MEMBERS := {
	"ta":"助教 · 张学长","zhou_qi":"周琪","chen_jia":"陈嘉","player":"林星宇","sun_yu":"孙雨",
	"jiang_lin":"蒋琳","he_miao":"何淼","zhao_ke":"赵可","qian_yu":"钱瑜","lu_jia":"陆佳","chen_mo":"陈默","lin_xiao":"林晓","zhao_yu":"赵宇",
}

static func surface(pages, parent: Control, color: Color, padding: Vector2, radius: int) -> VBoxContainer:
	var box := pages.card(parent,color) as VBoxContainer
	var panel := box.get_parent() as PanelContainer
	panel.add_theme_stylebox_override("panel",NativeUi.box(color,Color.TRANSPARENT,0,radius,padding))
	return box

static func avatar(pages, parent: Control, who: String, action: Callable=Callable()) -> Control:
	var name_text: String=MEMBERS.get(who,who)
	var initials := "助教" if who=="ta" else name_text.right(2)
	var face := Button.new()
	face.name="C35Avatar_"+who
	face.text=initials
	face.custom_minimum_size=Vector2(46,46)
	face.size_flags_vertical=Control.SIZE_SHRINK_BEGIN
	face.accessibility_name=name_text
	Typography.apply_body(face)
	NativeUi.apply_button(face,AVATAR,LINK,Color.TRANSPARENT,10,0,14,Vector2(4,4))
	if action.is_valid(): face.pressed.connect(action)
	else:
		face.mouse_filter=Control.MOUSE_FILTER_IGNORE
		face.focus_mode=Control.FOCUS_NONE
	parent.add_child(face)
	return face

static func bubble(pages, root: Control, who: String, message: String, action: Callable=Callable(), outgoing: bool=false, status: String="") -> VBoxContainer:
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation",10)
	root.add_child(line)
	if not outgoing: avatar(pages,line,who,action)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation",5)
	body.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	line.add_child(body)
	if outgoing: avatar(pages,line,who)
	var title := pages.label(MEMBERS.get(who,who),14,MUTED) as Label
	if outgoing: title.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	body.add_child(title)
	var card := surface(pages,body,OUTGOING if outgoing else WHITE,Vector2(12,10),11)
	if not message.is_empty(): card.add_child(pages.label(message,17,INK))
	if not status.is_empty():
		var mark := pages.label(status,13,LINK if status.begins_with("已读") else MUTED) as Label
		mark.name="C35ReadStatus"
		mark.autowrap_mode=TextServer.AUTOWRAP_OFF
		mark.custom_minimum_size=Vector2(58,24)
		mark.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		mark.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
		mark.size_flags_horizontal=Control.SIZE_SHRINK_END
		mark.add_theme_stylebox_override("normal",NativeUi.box(WHITE,LINE,1,4,Vector2(7,3)))
		body.add_child(mark)
	return card

static func chip(pages, parent: Control, copy: String, callback: Callable) -> Button:
	var button := pages.button(parent,copy,callback) as Button
	NativeUi.apply_button(button,WHITE,LINK,LINE,12,1,16,Vector2(9,6),LINK)
	return button

static func composer(pages, frame: Control, copy: String, candidates: Dictionary, selected: Callable) -> Button:
	var trigger := chip(pages,frame.content,copy,func() -> void:
		choice_sheet(pages,frame,"选择要发送的消息",candidates,selected))
	trigger.name="C35ChatComposer"
	return trigger

static func choice_sheet(pages, frame: Control, title: String, choices: Dictionary, selected: Callable, description: String="") -> void:
	var previous := frame.get_node_or_null("C35ChoiceSheet")
	if previous!=null: return
	var overlay := VBoxContainer.new()
	overlay.name="C35ChoiceSheet"
	overlay.z_index=55
	frame.add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_theme_constant_override("separation",0)
	var backdrop := Button.new()
	backdrop.accessibility_name="收起回复候选"
	backdrop.focus_mode=Control.FOCUS_NONE
	backdrop.size_flags_vertical=Control.SIZE_EXPAND_FILL
	for role: String in ["normal","hover","pressed","focus"]:
		backdrop.add_theme_stylebox_override(role,NativeUi.box(Color(0.05,0.12,0.20,0.38)))
	backdrop.pressed.connect(overlay.queue_free)
	overlay.add_child(backdrop)
	var panel := surface(pages,overlay,WHITE,Vector2(16,13),14)
	var header := HBoxContainer.new()
	panel.add_child(header)
	header.add_child(pages.label(title,17,INK))
	var close := chip(pages,header,"收起",overlay.queue_free)
	close.custom_minimum_size.x=72
	close.size_flags_horizontal=Control.SIZE_SHRINK_END
	if not description.is_empty(): panel.add_child(pages.label(description,15,MUTED))
	for id: String in choices:
		var option := chip(pages,panel,str(choices[id]),func() -> void:
			overlay.queue_free()
			selected.call(id))
		option.name="C35Candidate_"+id
		option.alignment=HORIZONTAL_ALIGNMENT_LEFT

static func profile(pages,frame: Control,who: String) -> void:
	choice_sheet(pages,frame,MEMBERS.get(who,who),{},Callable(),"微积分（甲）课程群成员")

static func group_settings(pages, frame: Control, member_action: Callable, notice: String) -> void:
	frame.configure(GROUP_NAME,"归属于 浙江大学 · 内部群")
	var settings := Button.new()
	settings.name="C35GroupSettings"
	settings.text="•••"
	settings.accessibility_name="群设置"
	settings.tooltip_text="群设置"
	Typography.apply_body(settings)
	NativeUi.apply_button(settings,Color.TRANSPARENT,INK,Color.TRANSPARENT,4,0,18,Vector2.ZERO)
	settings.position=Vector2(316,6);settings.size=Vector2(44,44)
	frame.toolbar.add_child(settings)
	settings.pressed.connect(func() -> void:
		if frame.get_node_or_null("C35GroupSettingsView")!=null: return
		var page = frame.get_script().new()
		page.name="C35GroupSettingsView"
		page.z_index=8
		page.background.color=BACKDROP
		page.configure("群设置","")
		page.back_requested.connect(page.queue_free)
		frame.add_child(page)
		var identity := surface(pages,page.content,BACKDROP,Vector2(4,4),0)
		identity.add_child(pages.label(GROUP_NAME,22,INK))
		identity.add_child(pages.label("归属于 浙江大学 · 内部群",15,MUTED))
		var members := surface(pages,page.content,WHITE,Vector2(10,12),14)
		var grid := GridContainer.new()
		grid.columns=5
		grid.add_theme_constant_override("h_separation",4)
		grid.add_theme_constant_override("v_separation",10)
		members.add_child(grid)
		var profile := pages.label("",15,MUTED) as Label
		profile.hide()
		var tiles: Array[Control]=[]
		for id: String in MEMBERS:
			var tile := VBoxContainer.new()
			tile.size_flags_horizontal=Control.SIZE_EXPAND_FILL
			grid.add_child(tile)
			var callback := func() -> void:
				if not member_action.call(id):
					profile.text=MEMBERS[id]+"  ·  课程群成员"
					profile.show()
			var face := avatar(pages,tile,id,callback)
			face.size_flags_horizontal=Control.SIZE_SHRINK_CENTER
			var name_label := pages.label(MEMBERS[id],14,MUTED) as Label
			name_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
			tile.add_child(name_label)
			tiles.append(tile)
			tile.visible=tiles.size()<=5
		chip(pages,members,"查看全部群成员（%d）"%tiles.size(),func() -> void:
			for tile in tiles: tile.show())
		members.add_child(profile)
		var tools := surface(pages,page.content,WHITE,Vector2(10,12),14)
		var search := LineEdit.new()
		search.placeholder_text="搜索群成员"
		search.custom_minimum_size.y=44
		Typography.apply_body(search)
		tools.add_child(search)
		search.text_changed.connect(func(term: String) -> void:
			for index in tiles.size(): tiles[index].visible=str(MEMBERS.values()[index]).contains(term.strip_edges()))
		var shortcuts := HBoxContainer.new()
		tools.add_child(shortcuts)
		chip(pages,shortcuts,"聊天记录",page.queue_free)
		var pinned := pages.label(notice,16,INK) as Label
		chip(pages,shortcuts,"群公告",func() -> void: pinned.visible=not pinned.visible)
		pinned.hide()
		tools.add_child(pinned))
