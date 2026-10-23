extends "res://tests/test_phone_app_scroll_shell.gd"
## The reconstructed learning entrance is exercised through real Main controls.
## Its visual changes must preserve P15 -> P11 -> P15 routing and story ownership.
func gesture(target: Control,touch: bool) -> void:
	if not touch:
		await click(target)
		return
	check(target!=null and target.is_visible_in_tree(),"raw touch target exists")
	if target==null:return
	var point:=rect(target).get_center()
	check(Rect2(Vector2.ZERO,Vector2(root.size)).has_point(point),"raw touch target is inside the visible viewport")
	for down: bool in [true,false]:
		var event:=InputEventScreenTouch.new();event.index=0;event.position=point;event.pressed=down
		Input.parse_input_event(event);Input.flush_buffered_events();await frames(2)
	await frames()

func story() -> String:
	return JSON.stringify({"items":state.d.items,"flags":state.d.flags,"digits":state.d.digits,"actOne":state.d.actOne})

func prepare(viewport: Vector2i,later: bool=false) -> void:
	state.d=state.initial();state.developer_mode=true
	state.d.native.page="phone_home";state.d.runtimeMode="phone";state.d.networkMode="campus_wifi"
	if later:
		state.d.native.chapter=2;state.d.actOne.phase="movement_required"
		state.d.actOne.inventoryRecovered=true;state.d.items.campusCard=true
	root.size=viewport;shell.size=Vector2(viewport);shell.mobile_world=false
	shell.phone_builder.zjuding_page="hub";shell.phone_builder.zjuding_panel="";shell.phone_builder.zjuding_overlay=""
	shell._refresh();await frames()

func open_learn(touch: bool) -> void:
	await gesture(node("HomeApp_zjuding"),touch)
	check(state.d.native.page=="zjuding","real launcher opens the original Zjuding route")
	check(state.get_phone_entry_session().phase=="loading","source network/loading gate still runs before the learning entrance")
	state.advance_phone_entry(1500);await frames()
	await gesture(node("ZjudingApp_learn"),touch)
	check(shell.phone_builder.zjuding_page=="learn" and state.d.native.page=="zjuding","real app tile opens the learning subpage without a new progression route")

func assert_illustrations() -> void:
	var expected: Dictionary={
		"LearnCampusIllustration":Rect2(196,63,165,72),
		"LearnCourseIllustration_0":Rect2(3,3,163,83),
		"LearnCourseIllustration_1":Rect2(3,3,163,83)
	}
	for id: String in expected:
		var image: TextureRect=node(id)
		check(image!=null,"independent illustration exists: "+id)
		if image==null:continue
		var authored: Rect2=expected[id]
		check(image.size.is_equal_approx(authored.size) and image.position.is_equal_approx(authored.position),"actual TextureRect geometry matches its card-sized authored rectangle: "+id)
		check(image.expand_mode==TextureRect.EXPAND_IGNORE_SIZE and image.clip_contents,"source texture cannot expand or draw outside the illustration slot: "+id)
		check(image.mouse_filter==Control.MOUSE_FILTER_IGNORE and image.focus_mode==Control.FOCUS_NONE,"illustration cannot steal mouse, touch or keyboard input: "+id)
		var parent_transform: Transform2D=image.get_parent().get_global_transform_with_canvas()
		var expected_screen:=Rect2(parent_transform*authored.position,authored.size*parent_transform.get_scale())
		check(rect(image).is_equal_approx(expected_screen),"rendered illustration bounds preserve the authored crop at current phone scale: "+id)
		for protected_id: String in ["ZjudingLearnTitle","LearnCoursesTitle","LearnNoticeTitle","LearnNotice"]:
			check(not rect(image).intersects(rect(node(protected_id))),"illustration does not cover a heading or the notice card: "+id+" / "+protected_id)
		if id.begins_with("LearnCourseIllustration_"):
			check(rect(image.get_parent()).encloses(rect(image)),"course illustration fits inside its own card")
			for label: Label in image.get_parent().find_children("*","Label",true,false):
				check(not rect(image).intersects(rect(label)),"course illustration does not cover its course title or teacher text")

func verify_legacy_image_negative_control() -> void:
	var current: TextureRect=node("LearnCampusIllustration")
	check(current!=null,"negative control has the actual campus atlas")
	if current==null:return
	# Reproduce the former order on a detached fixture, not the live page.
	# Assigning size while the texture owns minimum size must fail our bounds
	# condition; a root-frame-only assertion would have missed this regression.
	var legacy:=TextureRect.new();legacy.texture=current.texture
	legacy.position=Vector2(196,63);legacy.size=Vector2(165,72)
	legacy.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	legacy.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	check(not legacy.size.is_equal_approx(Vector2(165,72)),"former texture-before-expand ordering is rejected by the actual-size check")
	legacy.free()

func assert_surface(phone_rect: Rect2,available: bool) -> void:
	check(shell.phone.size==Vector2(430,860),"learn retains the canonical 430 by 860 phone")
	check(rect(shell.phone).is_equal_approx(phone_rect),"learn keeps the phone frame position and uniform scale")
	check(shell.page_body.get_child_count()==1 and shell.page_body.get_child(0).get_meta("source_page",false),"learn remains one source-owned app inside Main")
	check(shell.phone_scroll.scroll_vertical==0 and shell.phone_scroll.get_v_scroll_bar().max_value-shell.phone_scroll.get_v_scroll_bar().page<=1,"learn never grows the outer phone scroll")
	var native_text: Array[String]=[]
	for label: Label in shell.page_body.find_children("*","Label",true,false):
		if label.is_visible_in_tree():native_text.append(label.text)
	for button: Button in shell.page_body.find_children("*","Button",true,false):
		if button.is_visible_in_tree():native_text.append(button.text)
	check("\n".join(native_text).contains("学在浙大"),"learning title is live native text rather than baked into a page screenshot")
	check(not available or "\n".join(native_text).contains("签到"),"available check-in has a visible native text label")
	for image: TextureRect in shell.page_body.find_children("*","TextureRect",true,false):
		check(image.texture==null or not image.texture.resource_path.ends_with("/ui/zjuding_home.png"),"retired whole-page learning screenshot is not mounted")
		if image.texture is AtlasTexture:
			check(image.texture.region.get_area()>0 and image.texture.region.get_area()<image.texture.atlas.get_size().x*image.texture.atlas.get_size().y*.5,"source art is limited to independent illustration crops")
	var checkin: Control=node("ZjudingCheckin")
	check((checkin!=null and checkin.is_visible_in_tree() and not checkin.disabled)==available,"check-in availability matches the original chapter gate")
	var surface_rect:=rect(shell.page_body.get_child(0))
	for button: Button in shell.page_body.find_children("*","Button",true,false):
		if not button.is_visible_in_tree() or button.disabled:continue
		check(button.name in ["PhoneNav_back","ZjudingCheckin","ZjudingLearnTab","LearnSchedule","LearnCourse_0","LearnCourse_1","LearnNotice"],"native reconstruction exposes only the original route and local information readers: "+str(button.name))
		check(button.size.x>=28 and button.size.y>=28,"learning action has a usable logical target: "+str(button.name))
		check(surface_rect.grow(1).encloses(rect(button)),"learning action stays inside the app viewport: "+str(button.name))
		if button.name=="ZjudingCheckin":
			var style:=button.get_theme_stylebox("normal")
			check(not button.text.is_empty() or button.find_children("*","Label",true,false).size()>0,"check-in is a rendered text control, not an invisible screenshot hotspot")
			check(not (style is StyleBoxFlat) or style.bg_color.a>0,"check-in has its own native card surface")
	var profile: Control=node("LearnProfileDisplay")
	check(profile!=null and not (profile is BaseButton) and profile.focus_mode==Control.FOCUS_NONE,"source locked secondary tab remains static and cannot take focus")
	assert_illustrations()

func readers(touch: bool,before: String) -> void:
	for id: String in ["LearnSchedule","LearnCourse_0","LearnCourse_1","LearnNotice"]:
		var target: Control=node(id)
		if id.begins_with("LearnCourse_"):target=node("LearnCourseIllustration_"+id.right(1))
		await gesture(target,touch)
		var reader: Control=node("LearnReader")
		check(reader!=null and node("LearnReaderBody") is Label and not node("LearnReaderBody").text.is_empty(),"real information control opens native readable content: "+id)
		if reader==null:continue
		check(rect(shell.page_body.get_child(0)).grow(1).encloses(rect(reader)),"reader remains within the fixed app viewport")
		check(state.d.native.page=="zjuding" and story()==before,"local reader does not route or mutate story: "+id)
		if id=="LearnSchedule":
			await gesture(node("ZjudingCheckin"),touch)
			check(state.d.native.page=="zjuding" and node("LearnReader")!=null,"open reader blocks the underlying check-in action")
			var event:=InputEventKey.new();event.keycode=KEY_ESCAPE;event.physical_keycode=KEY_ESCAPE;event.pressed=true
			Input.parse_input_event(event);Input.flush_buffered_events();await frames()
			event=event.duplicate();event.pressed=false;Input.parse_input_event(event);Input.flush_buffered_events();await frames()
		else:
			await gesture(node("LearnReaderDone" if id=="LearnCourse_1" else "LearnReaderBack"),touch)
		check(node("LearnReader")==null and shell.phone_builder.zjuding_page=="learn","reader back/close restores the same learning page")
		check(story()==before,"closing local information preserves story state")

func run() -> void:
	if not load("res://tests/native_test_isolation.gd").is_isolated_save():
		push_error("Learn page acceptance requires an isolated save fixture");quit(2);return
	create_timer(90).timeout.connect(func():push_error("Learn page acceptance watchdog");quit(2))
	var old_mouse: bool=Input.emulate_mouse_from_touch;Input.emulate_mouse_from_touch=true
	state=root.get_node("State");state.d=state.initial();state.developer_mode=true
	state.d.native.page="phone_home";state.d.runtimeMode="phone";state.d.networkMode="campus_wifi"
	shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames()
	shell.set_process(false);shell.world.set_process(false)
	for viewport: Vector2i in [Vector2i(390,844),Vector2i(430,860),Vector2i(1180,812)]:
		for touch: bool in [false,true]:
			await prepare(viewport)
			var phone_rect:=rect(shell.phone);var before:=story()
			await open_learn(touch);assert_surface(phone_rect,true)
			check(story()==before,"opening learning does not grant digits, items or check-in progress")
			verify_legacy_image_negative_control()
			await gesture(node("LearnCampusIllustration"),touch)
			check(state.d.native.page=="zjuding" and shell.phone_builder.zjuding_page=="learn" and node("LearnReader")==null and story()==before,"campus illustration stays decorative under actual pointer/touch input")
			await readers(touch,before)
			await gesture(node("ZjudingCheckin"),touch)
			check(state.d.native.page=="checkin" and node("CheckinSubmit")!=null,"learning action enters the existing native check-in form")
			check(rect(shell.phone).is_equal_approx(phone_rect),"opening the keypad never resizes the phone frame")
			await gesture(node("CheckinKey_1"),touch)
			check(shell.phone_builder.checkin_page.code=="1" and story()==before,"original keypad receives input without prematurely submitting attendance")
			await gesture(node("PhoneNav_back"),touch)
			state.advance_phone_entry(1500);await frames()
			check(state.d.native.page=="zjuding" and shell.phone_builder.zjuding_page=="learn","check-in back restores the learning subpage")
			assert_surface(phone_rect,true)
			await gesture(node("PhoneNav_back"),touch)
			check(state.d.native.page=="zjuding" and shell.phone_builder.zjuding_page=="hub","learning back restores the Zjuding hub")
			check(story()==before,"complete pointer/touch round trip leaves original story facts unchanged")
		await prepare(viewport,true)
		var phone_rect:=rect(shell.phone);var before:=story()
		await open_learn(false);assert_surface(phone_rect,false)
		check(story()==before,"later chapter learning remains a passive page without re-opening attendance")
		await gesture(node("PhoneNav_back"),false)
		check(shell.phone_builder.zjuding_page=="hub","locked later-chapter page still has its normal way back")
	Input.emulate_mouse_from_touch=old_mouse
	await shell.shutdown();shell.queue_free();await frames()
	print("NATIVE_LEARN_PAGE: %d checks, %d failures" % [checks,failures])
	quit(0 if failures==0 else 1)
