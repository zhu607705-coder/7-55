extends ColorRect
## World-space document surface. Existing chapter intents own acknowledgement.
var host:Control
var bound_state:Dictionary
var page:=""
var end_seen:=false
var confirmed:=false
var disposed:=false
var spread:Control

func configure(main:Control,b,page_id:String,view:Dictionary)->void:
	host=main;bound_state=b.s;page=page_id
	name="LibraryWorldDocument";color=Color(.025,.045,.05,.88)
	z_index=300;mouse_filter=Control.MOUSE_FILTER_STOP
	spread=Control.new();spread.size=Vector2(960,540);add_child(spread)
	var rule:bool=page=="library_rule"
	end_seen=not rule or bool(bound_state.ui.libraryFinalsPuzzle.archivedRuleRead)
	b._panel(spread,Rect2(48,32,304,476),Color("183c3d"),Color("b89b62"),0,2)
	b._panel(spread,Rect2(48,32,22,476),Color("102d32"))
	b._panel(spread,Rect2(88,74,226,330),Color("214748"),Color("b89b62"),0,1)
	b._label(spread,"三分钟离座法\n及其例外" if rule else "基础图书馆\n门禁查验记录",Rect2(111,110,184,140),27,Color("e5d5ac"))
	b._label(spread,"期末周修订版\n馆内秩序编写组" if rule else "022 座位\n到馆时间记录",Rect2(111,310,184,74),17,Color("d4c191"))
	for edge:int in 4:b._panel(spread,Rect2(55+edge,509+edge*2,294,1),Color("c5b793"))
	var scroll:=ScrollContainer.new();scroll.name="LibraryWorldDocumentScroll"
	scroll.position=Vector2(376,32);scroll.size=Vector2(536,476)
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;spread.add_child(scroll)
	var paper:=Control.new();paper.custom_minimum_size=Vector2(516,790 if rule else 472);scroll.add_child(paper)
	b._panel(paper,Rect2(0,0,516,790 if rule else 472),Color("efe3c5"),Color("b5a17a"),0,1)
	b._panel(paper,Rect2(0,0,17,790 if rule else 472),Color("d4c29a"))
	b._label(paper,str(view.get("title","")),Rect2(42,26,432,42),25,Color("293d39"))
	b._panel(paper,Rect2(42,83,432,1),Color("9a865f"))
	var text:Label=b._label(paper,str(view.get("body","")),Rect2(42,108,432,530 if rule else 225),21,Color("343b30"))
	text.vertical_alignment=VERTICAL_ALIGNMENT_TOP
	b._label(paper,"—  755  —" if rule else "基础馆 · 门禁记录",Rect2(42,665 if rule else 350,432,28),15,Color("766849"),HORIZONTAL_ALIGNMENT_CENTER)
	var close:Button=b._button(paper,"合上书" if rule else "返回馆内" if bound_state.ui.libraryFinalsPuzzle.entranceRecordRead else "记下入馆记录",Rect2(112,720 if rule else 405,292,46),func():
		if not can_close():return
		confirmed=true;host._close_modal(),Color("214748"),Color("efe3c5"))
	close.name="LibraryWorldDocumentClose";close.disabled=not end_seen
	var bar:VScrollBar=scroll.get_v_scroll_bar()
	bar.value_changed.connect(func(_v):
		if bar.max_value>bar.page and bar.value+bar.page>=bar.max_value-2:end_seen=true;close.disabled=false)

func layout_panel(available:Vector2)->void:
	position=Vector2.ZERO;size=available
	var factor:float=minf(available.x/960,available.y/540)
	spread.scale=Vector2.ONE*factor;spread.position=(available-Vector2(960,540)*factor)/2

func sync_authority(current:Dictionary)->bool:
	return is_same(current,bound_state) and current.native.page==page

func can_close()->bool:
	return not is_same(host.get_node("/root/State").d,bound_state) or end_seen

func dispose_session()->void:
	if disposed:return
	disposed=true
	var state:Node=host.get_node("/root/State")
	if not is_same(state.d,bound_state):return
	if page=="library_rule" and end_seen and not bound_state.ui.libraryFinalsPuzzle.archivedRuleRead:
		# Reading starts a story session that locks navigation. Leave the book
		# page first, then submit the original controller-owned reading action.
		state.open_page("library_app")
		state.act("lib_read_rule")
		return
	if page=="library_record" and confirmed and not bound_state.ui.libraryFinalsPuzzle.entranceRecordRead:state.act("lib_record")
	state.open_page("library_app")
