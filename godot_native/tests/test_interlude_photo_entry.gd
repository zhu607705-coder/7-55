extends SceneTree
## Source checkpoint fixture; real Home icon and frame input, not earned campaign.
var state:Node
var main:Control
var checks:int=0
var failures:int=0
func _initialize():run.call_deferred()
func frames():
	for i in 4:await process_frame
func check(ok:bool,label:String):
	checks+=1
	if not ok:failures+=1;push_error(label)
func find_button(node:Node,text:String)->Button:
	if node is Button and text in node.text:return node
	for child in node.get_children():
		var b=find_button(child,text)
		if b!=null:return b
	return null
func click(button:Button):
	check(button!=null,"visible source control exists")
	if button==null:return
	main.phone_scroll.ensure_control_visible(button);await frames()
	var point=button.get_global_rect().get_center()
	check(main.phone_scroll.get_global_rect().has_point(point),"control inside actual phone viewport")
	for down in [true,false]:
		var e=InputEventMouseButton.new();e.pressed=down;e.button_index=MOUSE_BUTTON_LEFT;e.button_mask=MOUSE_BUTTON_MASK_LEFT if down else 0;e.position=point;e.global_position=point;root.push_input(e,true);await process_frame
	await frames()
func run():
	state=root.get_node("State");state.developer_mode=true
	main=load("res://scenes/main.tscn").instantiate();root.add_child(main)
	for width in [390,430]:
		root.size=Vector2i(width,844 if width==390 else 860)
		for kind in ["before_interlude","before_journal","active_interlude","completed_interlude"]:
			check(state.begin_checkpoint("c3-interlude-photos"),"exact source fixture loaded")
			if kind=="before_interlude":state.d.qizhenLake.phase="inactive"
			elif kind=="before_journal":state.d.chapterThreeInterlude.evidenceIds=[];state.d.chapterThreeInterlude.recoveryOpened=false
			elif kind=="completed_interlude":state.d.chapterThreeInterlude.completed=true
			state.open_page("phone_home");await frames()
			await click(main.page_body.find_child("HomeApp_photos",true,false))
			check(state.d.native.page=="photos","Home retains ordinary Photos route")
			var recovered=find_button(main.page_body,"FRM B2")
			var expected=kind in ["before_journal","active_interlude"]
			check((recovered!=null)==expected,"source Photos phase predicate: "+kind+" / "+str(width))
			if recovered!=null:
				await click(recovered)
				check(state.d.native.get("c35_photo_selection",[]).has("paper_left")== (kind=="active_interlude"),"ordinary Photos cannot bypass journal gate")
				check(not state.d.chapterThreeInterlude.photoSequenceSolved,"ordinary Photos selection never auto-solves")
	await main.shutdown();main.queue_free();await frames()
	print("INTERLUDE_PHOTO_ENTRY ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
