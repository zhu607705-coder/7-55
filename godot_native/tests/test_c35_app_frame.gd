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
func reading_geometry_matches(frame: Control) -> bool:
	var scale: float=absf(frame.get_global_transform_with_canvas().get_scale().x)
	var app := rect(frame)
	var content := rect(frame.content)
	return absf((content.position.x-app.position.x)/scale-18)<.5 and absf((app.end.x-content.end.x)/scale-18)<.5 and absf(frame.content.size.x-388)<.5
func semantic_controls(node: Node) -> Array:
	var result: Array=[]
	if (node is Label and not node.text.is_empty()) or node is Button:result.append(node)
	for child in node.get_children():result.append_array(semantic_controls(child))
	return result
func visible_rect(control: Control) -> Rect2:
	var bounds := rect(control)
	var owner := control.get_parent()
	while owner!=null:
		if owner is Control and owner.clip_contents:bounds=bounds.intersection(rect(owner))
		owner=owner.get_parent()
	return bounds
func check_reading_geometry(frame: Control, label: String) -> void:
	var app := rect(frame)
	check(reading_geometry_matches(frame),"reading margins are equal: "+label)
	check(frame.footer_margin.get_theme_constant("margin_left")==18 and frame.footer_margin.get_theme_constant("margin_right")==18,"footer keeps its own equal margins: "+label)
	for fraction: float in [0.0,.5,1.0]:
		var bar: VScrollBar=frame.scroll.get_v_scroll_bar()
		frame.scroll.scroll_vertical=roundi((bar.max_value-bar.page)*fraction);await frames()
		for control: Control in semantic_controls(frame.content):
			if not control.is_visible_in_tree() or not visible_rect(control).has_area():continue
			check(rect(control).position.x>=app.position.x-.5 and rect(control).end.x<=app.end.x+.5,"reading text/action stays inside app: "+label+" / "+control.name)
	var bag: Control=main.phone_chrome.inventory
	var was_visible: bool=bag.visible
	bag.hide();main._layout();await frames()
	check(reading_geometry_matches(frame),"hiding the shelf leaves both margins alone: "+label)
	bag.visible=was_visible;main._layout();await frames()
	check(reading_geometry_matches(frame),"showing the shelf leaves both margins alone: "+label)
	frame.scroll.scroll_vertical=0
	await frames()
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
		var intro_back: Button=find_control("C35IntroBack")
		check(is_instance_valid(intro_back) and intro_back.get_meta("phone_button_material","")=="flat" and intro_back.size==Vector2(44,44),"introduction back keeps its flat phone material and hit area")
		check(not main.phone_chrome.task_button.visible and not main.phone_chrome.inventory.visible,"chapter introduction has one focal action")
		check(rect(main.phone_scroll).grow(1).encloses(rect(find_control("C35BeginRecovery"))),"start action fits without scrolling")
		check(intro_back.text=="×" and intro_back.get_meta("phone_nav_kind")=="exit","intro uses the same app exit symbol as Chapter 1")
		var reading := rect(find_control("C35IntroArt"))
		var previous_bottom := reading.end.y
		for name: String in ["C35IntroLocation","C35IntroTitle","C35IntroStatus","C35IntroNarrator","C35IntroPlayer","C35IntroSystem"]:
			var section := find_control(name)
			check(is_instance_valid(section),"intro has the expected reading section: "+name)
			if section==null:continue
			var bounds := rect(section)
			check(bounds.position.y>=previous_bottom-.5,"intro reads from the lake to the next step without overlap: "+name)
			check(bounds.position.x>=reading.position.x-.5 and bounds.end.x<=reading.end.x+.5,"intro section fits the reading column: "+name)
			check(visible_rect(section).grow(.5).encloses(bounds),"intro section is fully visible above the start action: "+name)
			previous_bottom=bounds.end.y
		await capture("intro-"+str(dimensions.x))
		await touch(find_control("C35BeginRecovery"))
		check(state.d.chapterThreeInterlude.recoveryOpened,"start touch requests validated recovery")
		var recovery_frame: Control=main.page_body.get_child(0)
		var app_back: Button=find_control("PhoneAppBack")
		check(is_instance_valid(app_back) and app_back.get_meta("phone_button_material","")=="flat" and app_back.size==Vector2(44,44),"app back keeps its flat phone material and hit area")
		check(app_back.text=="×","top-level recovery uses app exit")
		var content_before := rect(recovery_frame.content)
		var chrome: Control=main.phone_chrome
		var trigger_before := rect(chrome.inventory_handle)
		check(rect(main.phone).encloses(trigger_before) and trigger_before.get_center().x<rect(recovery_frame.toolbar).get_center().x and trigger_before.position.y>=rect(recovery_frame.toolbar).end.y,"collapsed inventory stays inside the left edge under navigation")
		await touch(chrome.inventory_handle)
		check(chrome.inventory_open and chrome.inventory_body.visible and rect(main.phone).encloses(rect(chrome.inventory_body)),"shelf opens the real drawer inside the phone")
		check(rect(recovery_frame.content)==content_before,"opening the drawer keeps the reading column steady")
		var side_tab := rect(chrome.inventory_handle)
		check(is_equal_approx(side_tab.position.x,rect(chrome.inventory_body).end.x) and side_tab.size.x>=27.99,"side tab fits the drawer edge and offers a usable touch target")
		await touch(chrome.inventory_handle)
		check(not chrome.inventory_open and not chrome.inventory_body.visible and rect(chrome.inventory_handle)==trigger_before,"side tab collapses the drawer to its original backpack entry")
		var point := rect(chrome.inventory_handle).get_center()
		var down := InputEventScreenTouch.new();down.index=0;down.position=point;down.pressed=true;Input.parse_input_event(down);Input.flush_buffered_events();await frames(1)
		var drag := InputEventScreenDrag.new();drag.index=0;drag.position=point+Vector2(0,44);drag.relative=Vector2(0,44);Input.parse_input_event(drag);Input.flush_buffered_events();await frames(1)
		var up := InputEventScreenTouch.new();up.index=0;up.position=drag.position;up.pressed=false;Input.parse_input_event(up);Input.flush_buffered_events();await frames()
		var moved_trigger := rect(chrome.inventory_handle)
		check(is_equal_approx(moved_trigger.position.x,trigger_before.position.x) and moved_trigger.position.y>trigger_before.position.y+20 and not chrome.inventory_open,"touch drag repositions the closed drawer along the left rail")
		recovery_frame=main.page_body.get_child(0)
		check(rect(recovery_frame.content)==content_before,"repositioning the drawer does not shift reading content")
		await touch(chrome.inventory_handle)
		check(chrome.inventory_open,"a deliberate tap still opens the moved drawer")
		await touch(chrome.inventory_handle)
		check(not chrome.inventory_open and rect(chrome.inventory_handle).is_equal_approx(moved_trigger),"collapse restores the moved entry")
		var open: Button=null
		for button: Button in main.page_body.find_children("*","Button",true,false):
			if button.text=="查看划船帖":open=button
		await touch(open)
		await touch(find_control("C35JournalComposer"))
		check(not state.d.chapterThreeInterlude.evidenceIds.has("journal_start"),"opening reply choices does not publish")
		var publication := find_control("C35Candidate_safe_return")
		check(rect(main.phone_scroll).encloses(rect(publication)),"reply candidate is reachable in the phone")
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
		check(find_control("PhoneAppBack").text=="‹","detail photo uses the standard previous-page symbol")
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
			await check_reading_geometry(frame,page+" / "+str(dimensions))
			if page=="c35_official":
				var cover := find_control("WechatArticleCover") as TextureRect
				check(cover!=null and cover.texture!=null and cover.texture.resource_path.ends_with("/notice.webp"),"evidence reader shows the campus notice cover")
				check(intent("c35_official")!=null,"the notice still has its save action")
			var header_before := rect(frame.toolbar)
			frame.scroll.scroll_vertical=10000;await frames()
			check(rect(frame.toolbar)==header_before,"scroll keeps navigation fixed: "+page)
			if frame.footer.visible and frame.footer.get_child_count()>0:
				check(rect(main.phone_scroll).grow(1).encloses(rect(frame.footer_margin)),"context action bar stays in viewport: "+page)
			check(state.d.chapterThreeInterlude==before,"navigation does not earn evidence: "+page)
			if page=="c35_voice":
				var clear := intent("c35_voice_clear")
				check(clear!=null and rect(clear).size.x>=44,"secondary recording action has a readable touch target")
			frame.scroll.scroll_vertical=0;await frames()
			await capture(page+"-"+str(dimensions.x))
	await show("phone_home")
	var voice: Button=find_control("HomeApp_voice_memos")
	check(voice!=null,"voice app is available from the phone home")
	if voice!=null:
		await touch(voice)
		check(state.d.native.page=="c35_voice" and find_control("PhoneAppBack").text=="×","direct voice app entry shows exit")
		await touch(find_control("PhoneAppBack"))
		check(state.d.native.page=="phone_home","direct voice exit returns to the home screen")
	await main.shutdown();main.queue_free();await frames()
	print("C35_APP_FRAME ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
