extends RefCounted
## The address book orders its authored display names without changing chat routes.
const Palette = preload("res://scripts/ui/phone_palette.gd")
const Chrome = preload("res://scripts/ui/wechat_chrome.gd")
const Typography = preload("res://scripts/ui/native_typography.gd")
const Ui = preload("res://scripts/ui/native_ui_theme.gd")

const SERVICES = [
	{"id":"officials", "name":"公众号", "icon":"officials", "fill":Color("1976c5")},
	{"id":"helper", "name":"文件传输助手", "icon":"transfer", "fill":Color("218154")},
]
const PEOPLE = [
	{"id":"friend", "name":"朋友", "pinyin":"pengyou", "icon":"me", "fill":Color("376697")},
	{"id":"roommate", "name":"室友", "pinyin":"shiyou", "icon":"roommate", "fill":Color("537847")},
	{"id":"mentor", "name":"导师", "pinyin":"daoshi", "icon":"mentor", "fill":Color("76589b")},
]
const RAIL_WIDTH := 32
var descending := false
var search_open := false
var query := ""

func reset() -> void:
	descending = false
	search_open = false
	query = ""

func build(b, social) -> Control:
	var root: Control = b._base(Color.WHITE, b.APP_HEIGHT)
	root.name = "WechatContacts"
	social.header(b, root, "通讯录", func(): b.page_requested.emit("phone_home"), "PhoneNav_exit")
	var search: Button = b._button(root, "", Rect2(328,5,44,44), func():
		search_open = not search_open
		if not search_open:
			query = ""
		social.refresh(b), Palette.CHROME, Palette.INK, 0, Color.TRANSPARENT)
	search.name = "WechatContactsSearch"
	search.accessibility_name = "关闭通讯录搜索" if search_open else "搜索通讯录"
	search.tooltip_text = search.accessibility_name
	Chrome.icon(search,"search",Rect2(10,10,24,24))
	var top := 104 if search_open else 54
	var list: VBoxContainer = social.feed(b, root, top, social.FOOTER_HEIGHT, "", 0)
	list.add_theme_constant_override("separation",0)
	var margin := list.get_parent() as MarginContainer
	margin.add_theme_constant_override("margin_top",0)
	margin.add_theme_constant_override("margin_bottom",4)
	var scroll := margin.get_parent() as ScrollContainer
	scroll.size.x -= RAIL_WIDTH
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	scroll.follow_focus = true

	var rail := VBoxContainer.new()
	rail.position.x = 378-RAIL_WIDTH
	rail.size.x = RAIL_WIDTH
	rail.add_theme_constant_override("separation",2)
	root.add_child(rail)
	var update := func():
		_fill(b,social,list,rail,scroll)
	_fill(b,social,list,rail,scroll)
	if search_open:
		var field := LineEdit.new()
		field.name = "WechatContactQuery"
		field.position = Vector2(12,57)
		field.size = Vector2(354,42)
		field.placeholder_text = "搜索联系人"
		field.text = query
		field.clear_button_enabled = true
		field.accessibility_name = "搜索联系人"
		Typography.apply_body(field)
		Ui.apply_input(field, Palette.SURFACE, Palette.INK, Palette.LINE, 6, social.font_size(b,16))
		root.add_child(field)
		field.text_changed.connect(func(value: String):
			query = value
			update.call())
	social.footer(b,root)
	return root

func _fill(b, social, list: VBoxContainer, rail: VBoxContainer, scroll: ScrollContainer) -> void:
	for container: VBoxContainer in [list,rail]:
		for child in container.get_children():
			container.remove_child(child)
			child.queue_free()
	scroll.scroll_vertical = 0
	var needle := query.strip_edges().to_lower()
	if needle.is_empty():
		_heading(social,b,list,"服务与入口")
		for service: Dictionary in SERVICES:
			_row(b,social,list,service)

	var people: Array = PEOPLE.filter(func(person: Dictionary) -> bool:
		return needle.is_empty() or needle in str(person.name) or needle in str(person.pinyin))
	if people.is_empty():
		var empty := social.copy(list,"未找到联系人",social.font_size(b,16),Palette.MUTED) as Label
		empty.custom_minimum_size.y=58
		empty.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		empty.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
		return
	people.sort_custom(func(a: Dictionary,b: Dictionary) -> bool:
		return a.pinyin > b.pinyin if descending else a.pinyin < b.pinyin)
	var heading := _heading(social,b,list,"联系人")
	var sort: Button = b._button(heading,"按拼音 Z–A" if descending else "按拼音 A–Z",Rect2(210,0,130,42),func():
		descending = not descending
		_fill(b,social,list,rail,scroll)
		list.find_child("WechatContactSort",true,false).grab_focus(),Palette.CHROME,Palette.INK,0,Color.TRANSPARENT)
	sort.name = "WechatContactSort"
	sort.tooltip_text = "切换为拼音升序" if descending else "切换为拼音降序"
	sort.accessibility_name = sort.text
	sort.add_theme_font_size_override("font_size",social.font_size(b,13))
	var previous := ""
	for entry: Dictionary in people:
		var initial := str(entry.pinyin).left(1).to_upper()
		var new_group := initial != previous
		if new_group:
			_heading(social,b,list,initial,26)
		var row := _row(b,social,list,entry)
		if new_group:
			_index(b,social,rail,initial,row,scroll)
		previous = initial
	rail.position.y = scroll.position.y + maxf(0,(scroll.size.y-rail.get_combined_minimum_size().y)/2)

func _heading(social, b, list: VBoxContainer, text: String, height: int = 42) -> Panel:
	var heading := Panel.new()
	heading.mouse_filter = Control.MOUSE_FILTER_PASS
	heading.custom_minimum_size.y = height
	heading.add_theme_stylebox_override("panel", Ui.box(Palette.CHROME))
	list.add_child(heading)
	var label: Label = b._label(heading,text,Rect2(14,0,175,height),social.font_size(b,13),Palette.MUTED)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return heading

func _row(b, social, list: VBoxContainer, entry: Dictionary) -> Button:
	var id := str(entry.id)
	var title := str(entry.name)
	var scale: float = float(social.font_size(b,18))/18.0
	var row := Chrome.conversation(list,title,"","",scale)
	row.name = "WechatPublicAccounts" if id=="officials" else "WechatContact_"+id
	row.accessibility_name = title
	row.mouse_filter = Control.MOUSE_FILTER_PASS
	row.find_child("ConversationPreview",true,false).hide()
	row.find_child("ConversationTime",true,false).hide()
	row.pressed.connect(func():
		if id=="friend":
			b._open_wechat_friend()
		else:
			social.open_panel(b,id))
	var slot := row.find_child("AvatarSlot",true,false) as Control
	var tile := Panel.new()
	tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.position = Vector2(4,4)
	tile.size = Vector2(40,40)
	var skin := StyleBoxFlat.new()
	skin.bg_color = entry.fill
	skin.set_corner_radius_all(7)
	tile.add_theme_stylebox_override("panel",skin)
	slot.add_child(tile)
	Chrome.icon(tile,entry.icon,Rect2(7,7,26,26),Color.WHITE)
	return row

func _index(b, social, rail: VBoxContainer, initial: String, row: Button, scroll: ScrollContainer) -> void:
	var letter: Button = b._button(rail,initial,Rect2(0,0,RAIL_WIDTH,40),func():
		scroll.ensure_control_visible(row)
		row.grab_focus(),Color.WHITE,Palette.MUTED,0,Color.TRANSPARENT)
	letter.name = "WechatContactIndex_"+initial
	letter.accessibility_name = "定位到 "+initial
	letter.custom_minimum_size = Vector2(RAIL_WIDTH,40)
	letter.add_theme_font_size_override("font_size",social.font_size(b,12))
	letter.set_meta("phone_button_role","navigation")
