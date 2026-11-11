extends ColorRect
## World-space document surface. Existing chapter intents own acknowledgement.
var host:Control
var bound_state:Dictionary
var page:=""
var end_seen:=false
var disposed:=false
var spread:Control
var cover:Control
var scroll:ScrollContainer
var paper:Control
var body:Label
var close:Button
var desktop_geometry:Array=[]
var desktop_paper_size:=Vector2.ZERO
var last_available:=Vector2.ZERO
var layout_pending:=false
var layout_generation:=0
var scroll_fraction:=0.0

func configure(main:Control,b,page_id:String,view:Dictionary)->void:
	host=main;bound_state=b.s;page=page_id
	name="LibraryWorldDocument";color=Color(.025,.045,.05,.88)
	z_index=300;mouse_filter=Control.MOUSE_FILTER_STOP
	spread=Control.new();spread.size=Vector2(960,540);add_child(spread)
	cover=Control.new();spread.add_child(cover)
	cover.mouse_filter=Control.MOUSE_FILTER_IGNORE
	end_seen=bool(bound_state.ui.libraryFinalsPuzzle.archivedRuleRead)
	b._panel(cover,Rect2(48,32,304,476),Color("183c3d"),Color("b89b62"),0,2)
	b._panel(cover,Rect2(48,32,22,476),Color("102d32"))
	b._panel(cover,Rect2(88,74,226,330),Color("214748"),Color("b89b62"),0,1)
	b._label(cover,"三分钟离座法\n及其例外",Rect2(111,110,184,140),27,Color("e5d5ac"))
	b._label(cover,"期末周修订版\n馆内秩序编写组",Rect2(111,310,184,74),17,Color("d4c191"))
	for edge:int in 4:b._panel(cover,Rect2(55+edge,509+edge*2,294,1),Color("c5b793"))
	scroll=ScrollContainer.new();scroll.name="LibraryWorldDocumentScroll"
	scroll.position=Vector2(376,32);scroll.size=Vector2(536,476)
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;spread.add_child(scroll)
	paper=Control.new();paper.custom_minimum_size=Vector2(516,790)
	# Let drag/wheel events on the paper reach its ScrollContainer while child
	# controls keep their own ordinary pointer handling.
	paper.mouse_filter=Control.MOUSE_FILTER_PASS;scroll.add_child(paper)
	var page_background: Control=b._panel(paper,Rect2(0,0,516,790),Color("efe3c5"),Color("b5a17a"),0,1)
	var page_edge: Control=b._panel(paper,Rect2(0,0,17,790),Color("d4c29a"))
	b._label(paper,str(view.get("title","")),Rect2(42,26,432,42),25,Color("293d39"))
	b._panel(paper,Rect2(42,83,432,1),Color("9a865f"))
	body=b._label(paper,str(view.get("body","")),Rect2(42,108,432,530),21,Color("343b30"))
	body.vertical_alignment=VERTICAL_ALIGNMENT_TOP
	body.propagate_notification(Control.NOTIFICATION_THEME_CHANGED)
	body.size.y=maxf(body.size.y,body.get_minimum_size().y)
	var footer_y:=body.position.y+body.size.y+27
	var close_y:=footer_y+55
	paper.custom_minimum_size.y=close_y+70
	desktop_paper_size=paper.custom_minimum_size
	page_background.size.y=desktop_paper_size.y
	page_edge.size.y=page_background.size.y
	b._label(paper,"—  755  —",Rect2(42,footer_y,432,28),15,Color("766849"),HORIZONTAL_ALIGNMENT_CENTER)
	close=b._button(paper,"合上书",Rect2(112,close_y,292,46),func():
		if disposed or not can_close():return
		host._close_modal(),Color("214748"),Color("efe3c5"))
	close.name="LibraryWorldDocumentClose";close.disabled=not end_seen
	var bar:VScrollBar=scroll.get_v_scroll_bar()
	bar.value_changed.connect(func(_v):
		if not layout_pending and bar.max_value>bar.page and bar.value+bar.page>=bar.max_value-2:end_seen=true;close.disabled=false)
	for node in cover.get_children()+paper.get_children():
		desktop_geometry.append({"node":node,"position":node.position,"size":node.size,"font":node.get_theme_font_size("font_size") if node is Label else 0})

func layout_panel(available:Vector2)->void:
	position=Vector2.ZERO;size=available
	if available==last_available:return
	# Browser toolbar/rotation changes preserve reading progress. Only ordinary
	# input may mark the end; geometry-generated scrollbar signals cannot.
	if not layout_pending:
		var bar:=scroll.get_v_scroll_bar()
		scroll_fraction=bar.value/maxf(1,bar.max_value-bar.page)
	last_available=available;layout_pending=true;layout_generation+=1
	var factor:float=minf(available.x/960,available.y/540)
	if factor>=.96:
		cover.scale=Vector2.ONE;cover.position=Vector2.ZERO
		for entry in desktop_geometry:
			entry.node.position=entry.position;entry.node.size=entry.size
			if entry.node is Label:entry.node.add_theme_font_size_override("font_size",entry.font)
		paper.custom_minimum_size=desktop_paper_size
		scroll.position=Vector2(376,32);scroll.size=Vector2(536,476)
		spread.scale=Vector2.ONE*factor;spread.position=(available-Vector2(960,540)*factor)/2
	else:
		# Focus the same bound volume instead of shrinking a desktop spread.
		spread.scale=Vector2.ONE;spread.position=Vector2.ZERO
		var wide:bool=available.x>=650
		var width:float=minf(560,available.x-24-(208 if wide else 0))
		var left:float=(available.x-width-(208 if wide else 0))/2
		cover.scale=Vector2.ONE;cover.position=Vector2(left,12)
		var cover_width:float=192 if wide else width
		var cover_height:float=available.y-24 if wide else 164
		var parts:=cover.get_children()
		_rect(parts[0],Rect2(0,0,cover_width,cover_height))
		_rect(parts[1],Rect2(0,0,12,cover_height))
		_rect(parts[2],Rect2(22,12,cover_width-34,cover_height-24))
		_rect(parts[3],Rect2(34,22,cover_width-58,64))
		parts[3].add_theme_font_size_override("font_size",20)
		_rect(parts[4],Rect2(34,100,cover_width-58,48))
		parts[4].add_theme_font_size_override("font_size",16)
		for edge:int in 4:_rect(parts[5+edge],Rect2(5+edge,cover_height+edge,cover_width-8,1))
		scroll.position=Vector2(left+208,12) if wide else Vector2(left,188)
		scroll.size=Vector2(width,available.y-scroll.position.y-12)
		var paper_width:float=width-16
		var text_width:float=paper_width-48
		var parts_p:=paper.get_children()
		parts_p[2].add_theme_font_size_override("font_size",22)
		_rect(parts_p[2],Rect2(24,24,text_width,60))
		_rect(parts_p[3],Rect2(24,96,text_width,1))
		body.add_theme_font_size_override("font_size",18)
		_rect(body,Rect2(24,116,text_width,1))
		# Label computes wrapped height at the new width; no clipped fixed body box.
		body.propagate_notification(Control.NOTIFICATION_THEME_CHANGED)
		var body_height:float=body.get_minimum_size().y
		body.size.y=body_height
		var footer_y:float=116+body_height+24
		var close_y:float=footer_y+44
		var height:float=maxf(close_y+72,scroll.size.y+48)
		paper.custom_minimum_size=Vector2(paper_width,height)
		scroll.size=Vector2(width,available.y-scroll.position.y-12)
		_rect(parts_p[0],Rect2(0,0,paper_width,height))
		_rect(parts_p[1],Rect2(0,0,10,height))
		_rect(parts_p[5],Rect2(24,footer_y,text_width,28))
		parts_p[5].add_theme_font_size_override("font_size",15)
		_rect(close,Rect2(24,height-72,text_width,48))
	_settle_layout.call_deferred(layout_generation)

func _rect(control:Control,rect:Rect2)->void:
	control.position=rect.position;control.size=rect.size

func _settle_layout(generation:int)->void:
	await get_tree().process_frame
	await get_tree().process_frame
	if generation==layout_generation:
		var bar:=scroll.get_v_scroll_bar()
		scroll.scroll_vertical=roundi(scroll_fraction*maxf(0,bar.max_value-bar.page))
		layout_pending=false

func sync_authority(current:Dictionary)->bool:
	return is_same(current,bound_state) and current.native.page==page

func can_close()->bool:
	return not is_same(host.get_node("/root/State").d,bound_state) or end_seen

func dispose_session()->void:
	if disposed:return
	disposed=true
	var state:Node=host.get_node("/root/State")
	if not is_same(state.d,bound_state):return
	if end_seen and not bound_state.ui.libraryFinalsPuzzle.archivedRuleRead:
		# Reading starts a story session that locks navigation. Leave the book
		# page first, then submit the original controller-owned reading action.
		state.open_page("library_app")
		state.act("lib_read_rule")
		return
	state.open_page("library_app")
