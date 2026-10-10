extends Control
## Read-only ItemInspectDialog phone variant, using source item metadata/documents.
## Consumed recovery evidence remains readable; there is deliberately no Use action.
signal closed
var close_button: Button
var document_scroll: ScrollContainer
var content_scroll: ScrollContainer
func setup(b, item_id: String, full_interior: bool=false) -> void:
	var available_height=854.0/b.PHONE_SCALE if full_interior else b.APP_HEIGHT
	name="LibrarySubmittedDocument"; size=Vector2(378,available_height); z_index=120; mouse_filter=Control.MOUSE_FILTER_STOP
	var metadata: Dictionary={}
	for entry in JSON.parse_string(FileAccess.get_file_as_string("res://data/source/items.config.json")):
		if entry.id==item_id: metadata=entry; break
	var catalog: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/native/item_catalog.json"))
	var document: Dictionary=catalog.get(item_id,{}).get("document",{})
	var info={"bagNonPersonProof":["认证证明","物品身份盖章机"],"seat022Receipt":["座位凭据","022 桌面夹缝"],"libraryPresenceProof":["到场证明","浙大体艺访问记录"]}.get(item_id,["调查证据",""])
	var shade=b._button(self,"",Rect2(Vector2.ZERO,size),func(): closed.emit(),Color(.04,.047,.063,.72),Color.WHITE,0,Color.TRANSPARENT)
	shade.focus_mode=Control.FOCUS_NONE
	var panel_top=maxf(12,(available_height-624)/2)
	var panel: Panel=b._panel(self,Rect2(34,panel_top,310,624),Color("ebe3cf"),Color("223245"),0,4); panel.mouse_filter=Control.MOUSE_FILTER_STOP
	content_scroll=ScrollContainer.new(); content_scroll.name="SubmittedDocumentOuterScroll"; content_scroll.position=Vector2(51,panel_top+16); content_scroll.size=Vector2(276,592); content_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED; add_child(content_scroll)
	var content=Control.new(); content.custom_minimum_size=Vector2(268,753); content_scroll.add_child(content)
	b._panel(content,Rect2(0,0,58,23),Color("236ab8"),Color("1f2830"),0,2)
	b._label(content,"PHONE",Rect2(0,0,58,23),10,Color("fff8df"),HORIZONTAL_ALIGNMENT_CENTER)
	b._label(content,str(metadata.get("name",document.get("heading",""))),Rect2(0,30,209,31),16,Color("1f2830"))
	b._panel(content,Rect2(0,75,268,105),Color("d4dbe4"),Color("1f2830"),0,3)
	for x in range(3,260,14): b._panel(content,Rect2(x,78,7,99),Color(1,1,1,.08))
	b._source_icon(content,item_id,Rect2(108,101,52,52))
	var y=193
	for pair in [["分类",info[0]],["来源",info[1]],["简介",str(metadata.get("desc",""))]]:
		var height=85 if pair[0]=="简介" else 55
		b._panel(content,Rect2(0,y,268,height),Color(1,1,1,.34),Color(.12,.16,.19,.22),0,2)
		b._label(content,pair[0],Rect2(10,y+7,245,16),10,Color("236ab8"))
		b._label(content,pair[1],Rect2(10,y+26,245,height-31),12,Color("1f2830"))
		y+=height+8
	b._panel(content,Rect2(0,y+5,268,276),Color("fffaf0"),Color("1f2830"),0,3)
	document_scroll=ScrollContainer.new(); document_scroll.name="SubmittedDocumentBodyScroll"; document_scroll.position=Vector2(12,y+18); document_scroll.size=Vector2(244,251); document_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED; document_scroll.focus_mode=Control.FOCUS_ALL; content.add_child(document_scroll)
	var paper=Control.new(); paper.custom_minimum_size=Vector2(237,390); document_scroll.add_child(paper)
	b._label(paper,"DOCUMENT",Rect2(0,0,230,15),10,Color("8b3f35"))
	b._label(paper,str(document.get("heading","")),Rect2(0,22,230,26),16,Color("29251e"))
	b._panel(paper,Rect2(0,56,232,2),Color("736a5a"))
	var line_y=68
	for field in document.get("fields",[]):
		b._label(paper,str(field.label),Rect2(0,line_y,79,31),10,Color("766b58"))
		b._label(paper,str(field.value),Rect2(84,line_y,148,31),12,Color("29251e"))
		b._panel(paper,Rect2(0,line_y+36,232,1),Color("a79c88")); line_y+=43
	for line in document.get("body",[]):
		var height=maxf(34,ceil(str(line).length()/19.0)*18)
		b._label(paper,str(line),Rect2(0,line_y+6,230,height),12,Color("29251e")); line_y+=height+13
	b._label(paper,str(document.get("footer","")),Rect2(0,line_y+4,230,45),10,Color("766b58"))
	paper.custom_minimum_size.y=line_y+60; content.custom_minimum_size.y=y+292
	close_button=b._button(self,"×",Rect2(292,panel_top+12,39,39),func(): closed.emit(),Color("f7f2e2"),Color("1f2830"),0,Color("1f2830")); close_button.name="SubmittedDocumentClose"; close_button.add_theme_font_size_override("font_size",24)
	ready.connect(func(): close_button.grab_focus())
func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed: return
	if event.keycode==KEY_ESCAPE: closed.emit(); get_viewport().set_input_as_handled()
	elif event.keycode==KEY_TAB:
		if close_button.has_focus(): document_scroll.grab_focus()
		else: close_button.grab_focus()
		get_viewport().set_input_as_handled()
	elif event.keycode in [KEY_UP,KEY_DOWN,KEY_PAGEUP,KEY_PAGEDOWN]:
		var scroll=document_scroll if document_scroll.has_focus() else content_scroll
		scroll.scroll_vertical+=(-35 if event.keycode==KEY_UP else 35 if event.keycode==KEY_DOWN else -180 if event.keycode==KEY_PAGEUP else 180)
		get_viewport().set_input_as_handled()
