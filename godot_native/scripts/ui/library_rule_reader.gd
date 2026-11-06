extends RefCounted
## Physical archived volume. Scroll position is local presentation, never evidence.
func build(b,view:Dictionary)->Control:
	var root:Control=b._base(Color("273b3c"),b.APP_HEIGHT)
	root.name="LibraryRuleReader"
	root.set_meta("handles_all_actions",true)
	root.set_meta("end_seen",bool(b.s.ui.libraryFinalsPuzzle.archivedRuleRead))
	var scroll:=ScrollContainer.new()
	scroll.name="LibraryRuleScroll"
	scroll.position=Vector2(54,12);scroll.size=Vector2(310,b.APP_HEIGHT-24)
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	var volume:Control=b._base(Color.TRANSPARENT,1100)
	# The printed page must pass finger drags to its ScrollContainer.
	volume.mouse_filter=Control.MOUSE_FILTER_PASS
	volume.custom_minimum_size=Vector2(296,1100);scroll.add_child(volume)
	# Cloth cover, inset title plate, spine and exposed page edges share the book.
	b._panel(volume,Rect2(7,8,282,317),Color("183c3d"),Color("101f25"),0,2)
	b._panel(volume,Rect2(7,8,18,317),Color("102d32"))
	for y:int in [42,275]:b._panel(volume,Rect2(10,y,12,4),Color("b89b62"))
	b._panel(volume,Rect2(39,40,226,235),Color("214748"),Color("b89b62"),0,1)
	b._label(volume,"三分钟离座法\n及其例外",Rect2(56,68,194,94),26,Color("e5d5ac"))
	b._label(volume,"期末周修订版",Rect2(56,180,194,32),15,Color("d4c191"))
	b._label(volume,"馆内秩序编写组",Rect2(56,230,194,26),13,Color("d4c191"))
	for edge:int in 4:b._panel(volume,Rect2(13+edge,326+edge*3,275,2),Color("c5b793"))
	# The printed source is kept intact, with room for wrapping on the fixed phone.
	b._panel(volume,Rect2(7,358,282,652),Color("efe3c5"),Color("b5a17a"),0,1)
	b._panel(volume,Rect2(8,359,17,650),Color("d4c29a"))
	b._panel(volume,Rect2(25,359,2,650),Color("b9a17a"))
	b._label(volume,"旧版离座规则",Rect2(44,390,224,39),22,Color("293d39"))
	b._panel(volume,Rect2(44,438,221,1),Color("9a865f"))
	var text:Label=b._label(volume,str(view.get("body","")),Rect2(44,465,221,460),18,Color("343b30"))
	text.vertical_alignment=VERTICAL_ALIGNMENT_TOP
	b._label(volume,"—  755  —",Rect2(44,962,221,25),13,Color("766849"),HORIZONTAL_ALIGNMENT_CENTER)
	var close:Button=b._button(volume,"合上书",Rect2(44,1035,221,46),func():
		if not root.get_meta("end_seen",false):return
		var acknowledge:bool=b.s.ui.libraryFinalsPuzzle.archivedRuleCollected and not b.s.ui.libraryFinalsPuzzle.archivedRuleRead
		# Reading starts narration and locks navigation. Leave the reader first.
		b.page_requested.emit("library_app")
		if acknowledge:b.action_requested.emit("lib_read_rule",null),Color("214748"),Color("efe3c5"))
	close.name="LibraryRuleAction" if b.s.ui.libraryFinalsPuzzle.archivedRuleCollected and not b.s.ui.libraryFinalsPuzzle.archivedRuleRead else "LibraryRuleClose"
	close.disabled=not root.get_meta("end_seen",false)
	var bar:VScrollBar=scroll.get_v_scroll_bar()
	bar.value_changed.connect(func(_value):
		if bar.max_value>bar.page and bar.value+bar.page>=bar.max_value-2:
			root.set_meta("end_seen",true);close.disabled=false)
	return root
