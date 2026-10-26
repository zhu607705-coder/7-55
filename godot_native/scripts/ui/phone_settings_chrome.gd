extends RefCounted
const Ui=preload("res://scripts/ui/native_ui_theme.gd")
const Type=preload("res://scripts/ui/native_typography.gd")
const Icon=preload("res://scripts/ui/phone_system_icon.gd")
const COLORS=["007aff","ff375f","3478f6","7558d2","2678da","537dc7","30a64a","85858b"]

static func icon(parent: Control,kind: String,rect: Rect2,ink: Color=Color.WHITE) -> Control:
	var node=Icon.new();node.kind=kind;node.position=rect.position;node.size=rect.size;node.ink=ink;parent.add_child(node)
	return node

static func header(b,root: Control,title: String) -> void:
	b._panel(root,Rect2(0,0,378,54),Color("f7f7f9"))
	var back: Button=b._button(root,"",Rect2(5,3,87,48),func():
		if b.settings_page=="root": b.page_requested.emit("phone_home")
		else: b.settings_page="root";b.settings_direction=-1;b.action_requested.emit("phone_refresh",{}),Color.TRANSPARENT,Color("007aff"),0,Color.TRANSPARENT)
	back.name="SettingsBack";back.accessibility_name="返回桌面" if b.settings_page=="root" else "返回设置"
	icon(back,"back",Rect2(5,11,24,24),Color("007aff"))
	b._label(back,"桌面" if b.settings_page=="root" else "设置",Rect2(30,10,53,26),15,Color("007aff"))
	var heading: Label=b._label(root,title,Rect2(95,12,252,29),17,Color("1c1c1e"))
	heading.autowrap_mode=TextServer.AUTOWRAP_OFF;heading.clip_text=true;heading.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	b._panel(root,Rect2(0,53,378,.6),Color("d8d8dc"))
	if b.settings_direction!=0:
		var direction: int=b.settings_direction;b.settings_direction=0
		if not b.s.native.get("settings",{}).get("reduced_motion",false):
			root.ready.connect(func():
				root.position.x=direction*20
				root.modulate.a=.6
				var tween=root.create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
				tween.tween_property(root,"position:x",0.0,.18);tween.tween_property(root,"modulate:a",1.0,.18))

static func index(b,root: Control,rows: Array,no_results: String) -> void:
	var search: LineEdit=b._line_edit(root,"搜索设置项",Rect2(15,68,348,39),b.settings_query)
	Ui.apply_input(search,Color("e6e6eb"),Color("1c1c1e"),Color.TRANSPARENT,9,16,Vector2(12,7));search.name="SettingsSearch"
	var scroll=ScrollContainer.new();scroll.name="SettingsScroll";scroll.position=Vector2(15,123);scroll.size=Vector2(348,b.APP_HEIGHT-137);scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;root.add_child(scroll)
	var list=VBoxContainer.new();list.size_flags_horizontal=Control.SIZE_EXPAND_FILL;list.add_theme_constant_override("separation",0);scroll.add_child(list)
	var controls=[]
	var font_scale=clampf(float(b.s.native.get("settings",{}).get("text_scale",1)),.85,1.35)
	for index in range(rows.size()):
		var entry: Array=rows[index]
		var row=Button.new();row.name="Settings_"+entry[0];row.accessibility_name=entry[2];row.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		row.mouse_filter=Control.MOUSE_FILTER_PASS
		Ui.apply_button(row,Color.WHITE,Color("1c1c1e"),Color.TRANSPARENT,9,0,16,Vector2.ZERO)
		list.add_child(row)
		row.pressed.connect(func(): b.settings_page=entry[0];b.settings_direction=1;b.action_requested.emit("phone_refresh",{}))
		var margin=MarginContainer.new();margin.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(margin);margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		for side in ["left","right"]:margin.add_theme_constant_override("margin_"+side,12)
		for side in ["top","bottom"]:margin.add_theme_constant_override("margin_"+side,11)
		var line=HBoxContainer.new();line.mouse_filter=Control.MOUSE_FILTER_IGNORE;line.add_theme_constant_override("separation",12);margin.add_child(line)
		var tile=Panel.new();tile.mouse_filter=Control.MOUSE_FILTER_IGNORE;tile.custom_minimum_size=Vector2(31,31);tile.size_flags_vertical=Control.SIZE_SHRINK_CENTER;tile.add_theme_stylebox_override("panel",Ui.box(Color(COLORS[index]),Color.TRANSPARENT,0,7));line.add_child(tile)
		icon(tile,entry[0],Rect2(3,3,25,25)).name="SettingsIcon_"+entry[0]
		var words=VBoxContainer.new();words.mouse_filter=Control.MOUSE_FILTER_IGNORE;words.size_flags_horizontal=Control.SIZE_EXPAND_FILL;line.add_child(words)
		for part in [2,3]:
			var text=Label.new();Type.apply_body(text);text.text=entry[part];text.mouse_filter=Control.MOUSE_FILTER_IGNORE;text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
			text.add_theme_font_size_override("font_size",roundi((16 if part==2 else 11)*font_scale));text.add_theme_color_override("font_color",Color("1c1c1e") if part==2 else Color("85858b"));words.add_child(text)
		var arrow=Icon.new();arrow.kind="chevron";arrow.ink=Color("b8b8bf");arrow.custom_minimum_size=Vector2(14,22);arrow.size_flags_vertical=Control.SIZE_SHRINK_CENTER;line.add_child(arrow)
		margin.minimum_size_changed.connect(func():row.custom_minimum_size.y=maxf(61,margin.get_combined_minimum_size().y))
		row.custom_minimum_size.y=61
		var gap=Control.new();gap.mouse_filter=Control.MOUSE_FILTER_IGNORE;gap.custom_minimum_size.y=14 if index in [0,4,6] else 1;list.add_child(gap)
		controls.append([row,gap])
	var empty=Label.new();Type.apply_body(empty);empty.text=no_results;empty.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;empty.custom_minimum_size.y=60;list.add_child(empty)
	var filter=func(query: String):
		b.settings_query=query
		var count=0
		for i in range(rows.size()):
			var show=query.strip_edges().is_empty() or (str(rows[i][2])+str(rows[i][3])).contains(query.strip_edges())
			controls[i][0].visible=show;controls[i][1].visible=show
			if show:count+=1
		empty.visible=count==0
	search.text_changed.connect(filter);filter.call(b.settings_query)
	scroll.get_v_scroll_bar().value_changed.connect(func(value):b.settings_scroll=int(value))
	root.ready.connect(func():scroll.scroll_vertical=b.settings_scroll)
