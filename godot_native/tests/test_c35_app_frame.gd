extends SceneTree
## Real Main, phone-local geometry and ordinary touch input. Fixture, not campaign proof.
var state: Node
var main: Control
var checks := 0
var failures := 0
func _initialize() -> void: run.call_deferred()
func frames(count: int=6) -> void:
	for i: int in count: await process_frame
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok: failures+=1;push_error("C35 APP: "+message)
func rect(control: Control) -> Rect2:
	var transform := control.get_global_transform_with_canvas()
	return Rect2(transform.origin,control.size*transform.get_scale())
func touch(control: Control) -> void:
	check(control!=null,"touch target exists")
	if control==null:return
	var owner: Node=control.get_parent()
	while owner!=null:
		if owner is ScrollContainer:owner.ensure_control_visible(control)
		owner=owner.get_parent()
	await frames()
	var point := rect(control).get_center()
	check(rect(main.phone).has_point(point) or (control==main.phone_chrome.inventory_handle and Rect2(Vector2.ZERO,Vector2(root.size)).has_point(point)),"touch is inside phone or its attached side handle")
	for down: bool in [true,false]:
		var event := InputEventScreenTouch.new();event.index=0;event.position=point;event.pressed=down
		Input.parse_input_event(event);Input.flush_buffered_events();await frames(1)
	await frames()
func find_control(name: String) -> Control:return main.page_body.find_child(name,true,false)
func intent(id: String, value: Variant=null) -> Button:
	for button: Button in main.page_body.find_children("*","Button",true,false):
		if button.get_meta("intent","")==id and (value==null or button.get_meta("intent_value")==value):return button
	return null
func capture(label: String) -> void:
	var folder := OS.get_environment("C35_UI_CAPTURE_DIR")
	if folder.is_empty() or DisplayServer.get_name()=="headless":return
	DirAccess.make_dir_recursive_absolute(folder)
	var deadline := Time.get_ticks_msec()+8000
	while not main.notice_queue.current.is_empty() and Time.get_ticks_msec()<deadline:await process_frame
	await create_timer(.5).timeout;await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(folder.path_join(label+".png"))==OK,"capture "+label)
func show(page: String) -> void:
	state.open_page(page);main._refresh();await frames()
	var deadline := Time.get_ticks_msec()+3500
	while Time.get_ticks_msec()<deadline and find_control("PhoneAppScroll")==null and find_control("C35RecoveryIntro")==null:await frames()
func run() -> void:
	state=root.get_node("State");state.developer_mode=true
	main=load("res://scenes/main.tscn").instantiate();root.add_child(main);await frames()
	for dimensions: Vector2i in [Vector2i(430,860),Vector2i(390,844),Vector2i(360,640),Vector2i(1440,900)]:
		root.size=dimensions;main.size=Vector2(dimensions)
		check(state.begin_checkpoint("c3-interlude-reboot"),"source checkpoint")
		state.d.native.settings.reduced_motion=true
		await show("c35_recovery")
		check(main.phone.size==Vector2(430,860),"canonical phone never changes")
		check(is_equal_approx(main.phone.scale.x,main.phone.scale.y),"phone scales uniformly")
		check(find_control("C35RecoveryIntro")!=null,"unopened chapter uses the approved introduction")
		check(not main.phone_chrome.task_button.visible and not main.phone_chrome.inventory.visible,"chapter introduction has one focal action")
		check(rect(main.phone_scroll).grow(1).encloses(rect(find_control("C35BeginRecovery"))),"start action fits without scrolling")
		await capture("intro-"+str(dimensions.x))
		await touch(find_control("C35BeginRecovery"))
		check(state.d.chapterThreeInterlude.recoveryOpened,"start touch requests validated recovery")
		var recovery_frame: Control=main.page_body.get_child(0)
		var content_before := rect(recovery_frame.content)
		var chrome: Control=main.phone_chrome
		check(chrome.inventory.position.y>=108 and (is_zero_approx(chrome.inventory.position.x) or absf(chrome.inventory.position.x+chrome.inventory_handle.size.x)<1),"collapsed inventory attaches to side, not toolbar")
		await touch(chrome.inventory_handle)
		check(chrome.inventory_open and chrome.inventory_body.visible,"side handle opens real item drawer")
		check(rect(recovery_frame.content)==content_before,"drawer overlays content without reserving or shifting a column")
		await touch(chrome.inventory_handle)
		check(not chrome.inventory_open and not chrome.inventory_body.visible,"side handle collapses drawer")
		var side_x: float=chrome.inventory.position.x
		var old_top: float=chrome.inventory_top
		var point := rect(chrome.inventory_handle).get_center()
		var down := InputEventScreenTouch.new();down.index=0;down.position=point;down.pressed=true;Input.parse_input_event(down);Input.flush_buffered_events();await frames(1)
		var drag := InputEventScreenDrag.new();drag.index=0;drag.position=point+Vector2(0,44);drag.relative=Vector2(0,44);Input.parse_input_event(drag);Input.flush_buffered_events();await frames(1)
		var up := InputEventScreenTouch.new();up.index=0;up.position=drag.position;up.pressed=false;Input.parse_input_event(up);Input.flush_buffered_events();await frames()
		check(chrome.inventory_top>old_top and is_equal_approx(chrome.inventory.position.x,side_x) and not chrome.inventory_open,"vertical drag moves side attachment without toggling or detaching")
		var open: Button=null
		for button: Button in main.page_body.find_children("*","Button",true,false):
			if button.text=="查看划船帖":open=button
		await touch(open)
		await touch(intent("c35_summary_select","safe_return"))
		check(not state.d.chapterThreeInterlude.evidenceIds.has("journal_start"),"draft does not publish")
		var publication := intent("c35_journal")
		check(rect(main.phone_scroll).encloses(rect(publication)),"publish action is fixed and reachable")
		await touch(publication)
		check(state.d.chapterThreeInterlude.evidenceIds.has("journal_start"),"explicit publish earns timestamp")
		await touch(find_control("PhoneAppBack"))
		check(state.d.native.page=="c35_recovery","thread back returns to recovery")
		await capture("recovery-"+str(dimensions.x))
		await touch(find_control("C35Source_photo"))
		var frame: Control=main.page_body.get_child(0)
		check(main.page_body.find_children("*","ScrollContainer",true,false).size()==1,"one phone-local scroll owner")
		check(main.phone_scroll.get_v_scroll_bar().max_value-main.phone_scroll.get_v_scroll_bar().page<1,"outer shell does not scroll the app toolbar")
		var before: Dictionary=state.d.chapterThreeInterlude.duplicate(true)
		frame.scroll.scroll_vertical=100;await frames()
		await touch(find_control("C35View_paper_left"))
		check(state.d.chapterThreeInterlude==before and state.d.native.get("c35_photo_selection",[]).is_empty(),"viewing a photograph does not select or solve it")
		check(main.page_body.get_child(0).scroll.scroll_vertical==0,"photo viewer starts at the top")
		await capture("photo-viewer-"+str(dimensions.x))
		await touch(intent("c35_select_photo","paper_left"))
		check(state.d.native.c35_photo_selection==["paper_left"] and not state.d.chapterThreeInterlude.photoSequenceSolved,"separate photo selection does not submit")
		await touch(find_control("PhoneAppBack"))
		check(find_control("C35PhotoOrder")!=null,"viewer back returns to gallery")
		await touch(find_control("PhoneAppBack"))
		check(state.d.native.page=="c35_recovery","gallery back returns to its actual parent")
		for page: String in ["c35_voice","c35_official","c35_messages","c35_network"]:
			await show(page)
			frame=main.page_body.get_child(0)
			check(frame.size==Vector2(424,814),"app fills the shared phone interior: "+page)
			if frame.get_script()!=load("res://scripts/ui/phone_app_frame.gd"):
				check(false,"specialized app is ready: "+page);continue
			var app_bounds := rect(frame)
			var content_bounds := rect(frame.content)
			check(absf((content_bounds.position.x-app_bounds.position.x)-(app_bounds.end.x-content_bounds.end.x))<1,"reading area has equal side margins: "+page)
			check(frame.content.size.x>=388,"reading area uses the recovered side column: "+page)
			var header_before := rect(frame.toolbar)
			frame.scroll.scroll_vertical=10000;await frames()
			check(rect(frame.toolbar)==header_before,"scroll keeps navigation fixed: "+page)
			if frame.footer.visible and frame.footer.get_child_count()>0:
				check(rect(main.phone_scroll).grow(1).encloses(rect(frame.footer_margin)),"context action bar stays in viewport: "+page)
			check(state.d.chapterThreeInterlude==before,"navigation does not earn evidence: "+page)
			if page=="c35_voice":
				var clear := intent("c35_voice_clear")
				check(clear!=null and rect(clear).size.x>=44,"secondary recording action has a readable touch target")
			await capture(page+"-"+str(dimensions.x))
	await main.shutdown();main.queue_free();await frames()
	print("C35_APP_FRAME ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
