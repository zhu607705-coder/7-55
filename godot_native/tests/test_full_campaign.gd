extends SceneTree
## Continuous campaign integration, ONE fresh state. Spatial positioning is
## explicitly logged test setup, never a claim of manual navigation. No source
## checkpoint fixtures or story flag writes are used to advance the campaign.
const Pages = preload("res://scripts/ui/phone_pages.gd")
var state: Node
var pages = Pages.new()
var page: Control
var witness: Node
var trace: Array = []
var failures := 0
var completed_chapters: Array = []
var chapter3: RefCounted
var chapter4: RefCounted
var game_results: Array = []
var game: Control
var phone_clock_owned:=true

func _process(delta: float) -> bool:
	# This standalone fixture is the phone host (there is no Main scene here).
	# Use the same controller-owned clock as Main instead of a page-local tween.
	if state!=null and phone_clock_owned: state.advance_phone_entry(delta*1000)
	return false

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, label: String) -> bool:
	trace.append({"check":label,"ok":value})
	if not value:
		failures += 1
		push_error("CAMPAIGN: " + label)
	return value

func run() -> void:
	state = root.get_node("State")
	state.d = state.initial()
	witness = Node.new()
	root.add_child(witness)
	for module in state.modules:
		var path: String = module.get_script().resource_path
		if path.ends_with("/chapter3.gd"): chapter3 = module
		if path.ends_with("/chapter4.gd"): chapter4 = module
	pages.action_requested.connect(func(id, value): state.act(id,value))
	pages.page_requested.connect(func(id): state.open_page(id))
	await beginning()
	if failures == 0: await library()
	if failures == 0: await load("res://tests/campaign_chapter3.gd").new().run(self)
	if failures == 0: await load("res://tests/campaign_chapter4.gd").new().run(self)
	finish()

func finish() -> void:
	if is_instance_valid(page): page.queue_free()
	if is_instance_valid(game): game.queue_free()
	witness.queue_free()
	await process_frame
	var report := {"kind":"continuous-native-controller-campaign","completedChapters":completed_chapters,"failures":failures,"checks":trace.filter(func(row): return row.has("check")).size(),"notManualPlaythrough":true,"spatialSetupExplicit":true,"trace":trace}
	var path: String = OS.get_environment("CAMPAIGN_REPORT")
	if not path.is_empty():
		var file := FileAccess.open(path,FileAccess.WRITE)
		if file: file.store_string(JSON.stringify(report,"\t")); file.close()
	print("CONTINUOUS CAMPAIGN chapters=%s failures=%d" % [str(completed_chapters),failures])
	quit(1 if failures else 0)

func step(id: String, value: Variant = null) -> Dictionary:
	await drain_c3()
	var result: Dictionary = state.act(id,value)
	trace.append({"action":id,"chapter":state.d.native.chapter,"phase":state.d.actOne.phase})
	check(result.get("handled",false),"handled " + id)
	await drain_library()
	await drain_c3()
	return result

func drain_c3() -> void:
	if chapter3==null or not chapter3.has_method("narrative_session"): return
	for iteration in range(16):
		var session: RefCounted=chapter3.narrative_session(state.d)
		if session==null: return
		if session.status=="issued": check(session.attach(state.d,witness),"attach C3 source narrative")
		if session.sequence_id=="canteen_promo": check(not state.d.canteenHunt.queueGapOpened,"promo queue remains closed before source visual timeline")
		if session.sequence_id=="theater_reversal" and float(session.spec.delayMs)>0: check(not state.d.theaterHunt.decoyRevealed,"theater decoy remains unrevealed before1320ms visual")
		var frames:=0
		while session.status in ["playing","inspecting"] and frames<2000:
			session.frame(state.d,100,witness)
			# Same issued-session callback and clock boundary used by the native
			# narrative host. No queue/menu fact or elapsed time is written here.
			if session.sequence_id=="canteen_promo" and not session.visual_acknowledged and session.elapsed_ms>=float(session.spec.delayMs):
				check(not state.d.canteenHunt.queueGapOpened,"promo queue has no premature completion fact")
				state.act("c3_promo_visual_complete",session)
				check(session.visual_acknowledged and state.d.canteenHunt.queueGapOpened,"source promo visual receipt opens queue")
				trace.append({"c3VisualReceipt":session.sequence_id,"elapsedMs":session.elapsed_ms,"authoredBoundaryMs":session.spec.delayMs})
			if session.sequence_id=="theater_reversal" and not session.visual_acknowledged and session.elapsed_ms>=float(session.spec.delayMs):
				check(not state.d.theaterHunt.decoyRevealed,"reversal fact waits for visual receipt")
				state.act("c3_reversal_visual_complete",session)
				check(session.visual_acknowledged and state.d.theaterHunt.decoyRevealed,"actual issued reversal visual receipt commits source facts")
				trace.append({"c3VisualReceipt":session.sequence_id,"elapsedMs":session.elapsed_ms,"authoredBoundaryMs":session.spec.delayMs})
			if session.sequence_id=="theater_reversal" and session.status=="inspecting":
				var held_ms: float=session.elapsed_ms
				session.frame(state.d,100,witness)
				check(session.elapsed_ms==held_ms and session.emitted_lines==2,"paper inspection holds timeline after first two lines")
				check(session.mark_inspector_opened(state.d,witness),"bound native narrative host opens decoy paper inspector")
				check(session.mark_inspector_closed(state.d,witness),"explicit inspector-close input from same bound host")
				state.act("c3_reversal_inspect_closed",session)
				check(session.inspector_acknowledged and session.status=="playing","source inspector receipt resumes final three lines")
				trace.append({"c3InspectorReceipt":"decoyPaper","elapsedMs":held_ms,"input":"bound session inspector-open and explicit-close callbacks","notManualPlaythrough":true})
			frames+=1
		trace.append({"c3Narrative":session.sequence_id,"lines":session.lines.size(),"elapsedMs":session.elapsed_ms,"status":session.status})
		if session.status=="complete": state.act("c3_story_complete",session)
		else:
			check(false,"C3 narrative queue completes without bypass")
			return
	check(false,"C3 narrative queue bounded")

func drain_library() -> void:
	for iteration in range(32):
		var session: RefCounted = state.get_library_story_session(100)
		if session == null: return
		if session.status == "issued": check(session.attach(state.d,witness),"attach authored library dialogue")
		var line_count := 0
		while session.status == "playing" and line_count < 100:
			trace.append({"dialogue":session.sequence_id,"line":session.line_index,"text":session.snapshot().get("text","")})
			session.advance(state.d,witness)
			line_count += 1
		if session.status == "complete": state.act("lib_story_complete",session)
		else:
			check(false,"library dialogue terminates honestly")
			return
	check(false,"library queue bounded")

func show_phone(id: String) -> void:
	if is_instance_valid(page): page.free()
	var reopen_friend: bool=pages.friend_open
	state.open_page(id)
	pages.entry_session=state.get_phone_entry_session()
	if id=="wechat" and reopen_friend: pages.friend_open=true
	# Honor the authored app mount delay before inspecting its ready controls.
	if pages.entry_session.family in ["tiyi","zjuding"] and pages.entry_session.entry_allowed:
		while pages.entry_session.phase=="loading": await process_frame
	page = pages.build(id,state.get_view(id),state.d)
	root.add_child(page)
	await process_frame

func system_dialogue() -> void:
	var before: String = state.d.actOne.phase
	await show_phone("system_chat")
	var overlay: Control = page.find_child("SystemDialogueAdvance",true,false)
	if not check(overlay != null,"actual system dialogue mounted"): return
	for index in range(10):
		if not is_instance_valid(overlay) or not overlay.is_inside_tree(): break
		# Invoke the same native Button activation used by pointer/Enter input.
		overlay.pressed.emit()
		await process_frame
		if state.d.actOne.phase != before: break
	check(state.d.actOne.phase != before,"system final click advances phase")

func boundary(label: String) -> void:
	await drain_library()
	var phase: String = state.d.actOne.phase
	var chapter: int = state.d.native.chapter
	var inventory: Dictionary = state.d.items.duplicate(true)
	check(state.save_game(),label + " save")
	check(state.load_game(),label + " real file reload")
	check(state.d.actOne.phase==phase and state.d.native.chapter==chapter and state.d.items==inventory,label + " continuity")

func make_game(request: Dictionary) -> Control:
	if not check(request.has("game"),"controller issued minigame"): return null
	var config: Dictionary=request.game
	var result: Control=load(config.get("script","res://scripts/ui/minigame_host.gd")).new()
	result.size=Vector2(430,820)
	root.add_child(result)
	result.set_process(false)
	game_results=[]
	var callback: String=config.get("on_success",config.get("callback",""))
	var completion:=func(proof: Dictionary):
		game_results.append(proof)
		state.act(callback,proof)
	if result.has_signal("finished"): result.connect("finished",completion)
	elif result.has_signal("completed"): result.connect("completed",completion)
	if result.has_method("setup"): result.setup(config)
	elif result.has_method("start"): result.start(config)
	return result

func beginning() -> void:
	for id in ["c1_start_alarm","c1_dismiss_alarm","c1_wake","c1_enter_home"]: await step(id)
	await show_phone("wechat")
	page.find_child("WechatRow_1",true,false).pressed.emit()
	await show_phone("wechat")
	await create_timer(4.2).timeout
	var skip: Button=page.find_child("FriendAttackSkip",true,false)
	if not check(skip!=null,"authored friend skip is visible"): return
	skip.pressed.emit()
	await create_timer(5.7).timeout
	if not check(state.d.flags.codeScattered,"native scatter timeline finished"): return
	await step("c1_absence")
	await step("c1_network","移动数据")
	await step("c1_tiyi_digit")
	await step("c1_auto_rotate")
	await show_phone("phone_home")
	await create_timer(1.75).timeout
	check(state.d.flags.gearFallen,"real gear tween")
	await step("c1_collect_gear")
	await step("c1_auto_rotate")
	pages.friend_open=false
	await show_phone("wechat")
	await create_timer(1.35).timeout
	check(state.d.flags.slashHalfDropped,"real avatar tween")
	for i in range(3): await step("c1_avatar")
	await step("c1_combine",["slashLine","reverseGear"])
	await step("c1_tower","towerKey")
	await show_phone("phone_home")
	await create_timer(1.9).timeout
	check(state.d.flags.towerOpened,"real tower insertion and rotation")
	for pair in [["c1_music",null],["c1_headphone",null],["c1_rain_drop",null],["c1_combine",["waterDrop","headphone"]],["c1_plant","wateredHeadphone"],["c1_plant","fertilizer"],["c1_brightness",85],["c1_plant_light",null],["c1_flower",null],["c1_collect_flower",null],["c1_network","校园网"]]: await step(pair[0],pair[1])
	if not check(state.d.digits=={"d1":"0","d2":"7","d3":"9","d4":"8"},"four authored digits collected"): return
	game=make_game(await step("c1_checkin","0798"))
	if game==null: return
	for frame in range(2000):
		if not game_results.is_empty(): break
		if game.phase=="intercept": game._pointer(game._position(Vector2([24,78,50][mini(game.blocks,2)],80)),true)
		if game.phase=="lock": game._pointer(game._position(Vector2(50,42)),true)
		game._process(.02)
	check(game_results.size()==1 and state.d.native.chapter==2,"real prologue input and completed exchange")
	game.free(); game=null
	completed_chapters.append(1)
	await boundary("chapter1")
	pages.friend_open=true
	await show_phone("wechat")
	await create_timer(2.35).timeout
	check(state.d.actOne.phase=="system_required","source friend followup finished")
	await system_dialogue()
	await step("c2_enter_dorm")
	await step("c2_recover_card")
	await system_dialogue()
	await step("c2_identify",{"name":"林星宇","student_id":"3250100755"})
	await step("c1_network","移动数据")
	game=make_game(await step("c2_exercise"))
	if game==null: return
	for i in range(10): game.target.pressed.emit()
	check(game_results.size()==1 and state.d.actOne.exerciseStarted,"actual ten run point inputs")
	game.free(); game=null
	for pair in [["c2_weather_drop",null],["c2_mentor","weatherWater"],["c2_triangle",null],["c2_triangle",null],["c2_triangle",null],["c1_combine",["pushTriangle","mentorLine"]],["c2_balance","rightArrow"],["c1_network","校园网"],["c2_card_identity",null],["c2_login",{"student_id":"3250100755","password":"ZJU1897!"}],["c2_purchase_gamepad",null],["c2_use_gamepad",null]]: await step(pair[0],pair[1])
	# A real world movement callback will be plugged here; no synthetic summary.
	var world: Control=load("res://scripts/world.gd").new(); world.size=Vector2(960,540); root.add_child(world)
	await process_frame
	world.set_process(false)
	world.refresh_world()
	world.grab_focus()
	var press:=InputEventKey.new(); press.keycode=KEY_D; press.physical_keycode=KEY_D; press.pressed=true
	Input.parse_input_event(press)
	await process_frame
	trace.append({"movementStart":state.d.native.player.duplicate(true),"controlsInstalled":state.d.actOne.controlsInstalled,"keyPressed":Input.is_key_pressed(KEY_D),"scene":world.scene_id})
	for i in range(20): world._process(1.0/60.0)
	var release:=InputEventKey.new(); release.keycode=KEY_D; release.physical_keycode=KEY_D
	Input.parse_input_event(release)
	await process_frame
	trace.append({"movementEnd":state.d.native.player.duplicate(true),"phase":state.d.actOne.phase})
	check(state.d.actOne.manualControlTested,"native world input publishes actual movement")
	world.free()
	await system_dialogue()
	await step("c2_reserve",{"library":"基础馆","room":"一层书库","seat":"022"})
	await step("c2_dorm_exit")
	check(state.d.ui.libraryFinalsPhase=="library_route_unlocked","fresh route opens library")
	await boundary("dorm exit")

func library() -> void:
	for id in ["lib_enter","lib_record","lib_backpack","lib_note"]: await step(id)
	await step("lib_investigate","occupancyNote")
	await step("lib_catalog_terminal")
	await step("lib_catalog_search","三分钟离座法")
	await step("lib_catalog_select","three-minute-leave-method")
	for id in ["lib_shelf","lib_read_rule","lib_front_desk","lib_photo"]: await step(id)
	await step("c1_brightness",20)
	await step("lib_dim_photo")
	await step("lib_view_photo","seat_022_clue")
	await step("lib_item_report")
	game=make_game(await step("lib_scan"))
	if game==null: return
	for i in range(38): game._process(.02)
	game.stamp.pressed.emit()
	check(game_results.size()==1,"actual identity scanner and stamp")
	game.free(); game=null
	for i in range(10): state.get_library_story_session(100)
	await drain_library()
	await step("lib_receipt")
	await step("c1_network","移动数据")
	await step("lib_audit",["7","47","3"])
	await step("c1_network","校园网")
	for id in ["archived_leave_rule","bag_non_person_proof","seat_022_receipt","library_presence_proof"]: await step("lib_upload",id)
	for id in ["bd-rule-count","bd-identity-zero","bd-seat-tail","bd-arrival-minutes"]: await step("lib_bd_select",id)
	await step("lib_bd_submit")
	await step("lib_recovery_open")
	for id in ["bag_non_person_proof","seat_022_receipt","library_presence_proof"]: await step("lib_recovery_upload",id)
	for id in ["lib_generate_pass","lib_apply_pass","lib_sit"]: await step(id)
	var session: RefCounted=state.get_scene_session()
	if not check(session!=null and session.attach(state.d,witness),"actual source opening issued"): return
	for i in range(100):
		if session.status!="playing": break
		session.advance_current(state.d,witness)
	await step("lib_opening_complete",session)
	if check(state.d.native.chapter==3 and state.d.canteenHunt.active,"continuous library opens chapter3"):
		completed_chapters.append(2)
	await boundary("chapter2")
