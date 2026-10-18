extends SceneTree
const Model=preload("res://scripts/media/c3_rain_rescue_model.gd")
const Session=preload("res://scripts/media/c3_rain_rescue_session.gd")
const FOCUS_SHELL_PATH="res://tests/fixtures/rain_rescue_focus_shell.gd"
var failures:=0
var checks:=0
func check(value: bool,message: String) -> void:
	checks+=1
	if not value: failures+=1; push_error("TEST FAILED: "+message)
func _initialize() -> void: _run.call_deferred()
func fixture(state: Node, shell: Control, reduced: bool=true) -> void:
	state.new_game(); state.developer_mode=true
	state.d.native.chapter=3; state.d.native.scene="qizhen_lake"; state.d.native.page="c3_lake"
	state.d.native.settings.reduced_motion=reduced
	state.d.runtimeMode="rpg"; state.d.rpgScene="qizhen_lake"; state.d.rpgCheckpoint="qizhen_dock"
	var q: Dictionary=state.d.qizhenLake
	q.active=true; q.phase="boarding_tutorial"; q.zone="dock"; q.vehicle="on_foot"
	q.kayakEquipped=true; q.leftPaddleEquipped=true; q.rightPaddleEquipped=true; q.rainWarningSeen=true
	q.rainSafetyCleared=false; q.rainRescueCompleted=false
	shell._refresh(); shell.mobile_world=true; shell._layout()
	shell.world.player=Vector2(690,620); shell.world._sync_player()
func wait_phase(session: RefCounted, phase: String, timeout_ms: int) -> bool:
	var deadline: int=Time.get_ticks_msec()+timeout_ms
	while Time.get_ticks_msec()<deadline and session.phase()!=phase: await create_timer(.02).timeout
	return session.phase()==phase
func _run() -> void:
	if OS.get_cmdline_user_args().has("--graphical-touch-skip"):
		await _run_graphical_touch_skip()
		return
	if OS.get_cmdline_user_args().has("--graphical-real-focus"):
		await _run_graphical()
		return
	var state=root.get_node("State")
	state.developer_mode=true
	# Unchanged Main and its real host reader: headless focus loss must pause,
	# rather than silently substituting State.d and dropping host protections.
	var actual: Control=load("res://scenes/main.tscn").instantiate(); root.add_child(actual)
	await process_frame
	fixture(state,actual)
	var result: Dictionary=state.act("c3_lake_target:qizhen_dock_board")
	check(result.has("world_effect"),"real Main creates the registered rain effect")
	if not result.has("world_effect"): actual.queue_free(); quit(1); return
	var session: RefCounted=result.world_effect.session
	var host_snapshot: Dictionary=actual.world_effect.read_state.call()
	check(not is_same(host_snapshot,state.d) and host_snapshot.native.has("host"),"real host supplies a deep snapshot with host visibility and focus")
	await create_timer(.12).timeout
	if not actual.get_window().has_focus():
		var frozen: int=int(session.snapshot().elapsedMs)
		await create_timer(.12).timeout
		check(session.phase()=="route" and int(session.snapshot().elapsedMs)==frozen,"unchanged headless Main pauses for real OS focus loss")
	check(not state.d.qizhenLake.rainRescueCompleted,"unchanged Main cannot complete from issue or focus loss")
	actual._cancel_world_effect(); await process_frame
	check(session.phase()=="cancelled" and not actual.world.presentation_actor_hidden,"unchanged Main cancellation restores actor and leaves no proof")
	await actual.shutdown(); actual.queue_free(); await process_frame

	# Only emulate OS focus. Production setup, read_state, deep-copy snapshots,
	# controller issue/consume, media rendering and monotonic clocks stay real.
	var shell: Control=load("res://scenes/main.tscn").instantiate(); shell.set_script(load(FOCUS_SHELL_PATH)); root.add_child(shell)
	await process_frame
	fixture(state,shell)
	var before: int=state.d.qizhenLake.capsizeCount
	result=state.act("c3_lake_target:qizhen_dock_board")
	check(result.has("world_effect") and not result.has("game"),"rain path requests authored sequence instead of four-stroke minigame")
	session=result.world_effect.session
	check(not is_same(shell.world_effect.read_state.call(),state.d),"completion tests preserve Main deep-copy boundary")
	check(not state.d.qizhenLake.rainRescueCompleted,"starting rescue writes no completion")
	state.act("c3_rain_rescue_result",{"success":true})
	check(not state.d.qizhenLake.rainRescueCompleted,"forged dictionary cannot complete rescue")
	state.act("c3_rain_rescue_result",session)
	check(not state.d.qizhenLake.rainRescueCompleted,"issued receipt cannot complete early")
	check(shell.world.presentation_actor_hidden,"source actor is replaced by transient rescue actor")
	check(is_equal_approx(Model.pre_cinematic_ms(false),5650) and is_equal_approx(Model.duration_ms(false),7250),"normal route and dock hold timing retained")
	check(is_equal_approx(Model.pre_cinematic_ms(true),1460) and is_equal_approx(Model.duration_ms(true),2260),"reduced route and dock hold timing retained")
	check(await wait_phase(session,"consumed",4000),"real reduced route plus deterministic dock hold completes")
	check(session.snapshot().outcome=="fallback" and session.snapshot().reason=="reduced_motion","reduced motion never starts full native cinematic")
	check(state.d.qizhenLake.rainRescueCompleted and state.d.qizhenLake.phase=="rain_recovery","reduced controller settlement retains recovery phase")
	check(state.d.native.scene=="dorm_hub" and state.d.currentScene=="phone_home" and state.d.native.page=="phone_home","source rescue returns dorm with phone-home route")
	check(state.d.qizhenLake.capsizeCount==before+1 and state.d.qizhenLake.boardingStrokeCount==0 and state.d.qizhenLake.boardingLastSide==null,"atomic source capsize and tutorial reset")
	check(not shell.world.presentation_actor_hidden,"presenter restores actor on completion")
	state.act("c3_rain_rescue_result",session)
	check(state.d.qizhenLake.capsizeCount==before+1,"receipt cannot settle twice")

	# Full native run, including route/cinematic/hold focus interruption. No clock
	# fields are advanced, mocked or rewritten to make these timing tests pass.
	fixture(state,shell,false)
	var start: int=Time.get_ticks_msec()
	result=state.act("c3_lake_target:qizhen_dock_board"); session=result.world_effect.session
	var presenter: Control=shell.world_effect
	shell.test_focused=false; await create_timer(.05).timeout
	var frozen: Dictionary=session.snapshot()
	await create_timer(.12).timeout
	check(session.snapshot().elapsedMs==frozen.elapsedMs,"route elapsed time freezes on focus loss")
	shell.test_focused=true
	check(await wait_phase(session,"cinematic",6500),"normal route opens native cinematic")
	check(is_instance_valid(presenter.native_renderer) and not is_instance_valid(presenter.video),"normal route embeds native art and creates no video decoder")
	check(session.snapshot().cinematicMode=="native" and session.snapshot().cinematicDurationMs==12350,"session records explicit native 12.350-second continuation mode")
	check(presenter.native_renderer.elapsed>=2.65 and presenter.native_renderer.elapsed<2.8,"native continuation starts with the player already holding the overturned hull")
	check(not session.finish_cinematic(presenter,"native") and not session.finish_cinematic(presenter,"video"),"early native and foreign video callbacks are rejected")
	check(not session.finish_cinematic(presenter,"played") and not session.finish_cinematic(presenter,"skipped_preview"),"sample terminal labels have no production authority")
	var foreign:=Node.new(); root.add_child(foreign)
	check(not session.finish_cinematic(foreign,"skipped") and session.sample(foreign).is_empty(),"foreign presenter cannot sample or finish capability")
	foreign.queue_free()
	shell.test_focused=false; await create_timer(.05).timeout
	frozen=session.snapshot(); var render_time: float=presenter.native_renderer.elapsed
	presenter.skip.pressed.emit(); presenter._request_finish("video")
	await create_timer(.15).timeout
	check(session.phase()=="cinematic" and session.snapshot().cinematicMs==frozen.cinematicMs and presenter.native_renderer.elapsed==render_time,"focus freezes native pose, rain, and session; queued skip/video cannot bypass")
	shell.test_focused=true
	while session.phase()=="cinematic" and session.snapshot().cinematicMs<9200: await create_timer(.03).timeout
	check(session.phase()=="cinematic" and not state.d.qizhenLake.rainRescueCompleted,"legacy 9-second watchdog cannot cut native cinematic short")
	check(not session.finish_cinematic(presenter,"native"),"native callback still cannot finish at legacy watchdog time")
	check(await wait_phase(session,"rescued",7000),"native session clock naturally reaches deterministic dock hold")
	check(session.snapshot().outcome=="native" and session.snapshot().cinematicMs>=12350,"native result proves full monotonic native duration")
	check(not presenter.native_renderer.visible and presenter.caption.visible and not presenter.skip.visible,"native view closes before existing dock hold")
	check(not state.d.qizhenLake.rainRescueCompleted and not session.finish_cinematic(presenter,"native"),"dock hold is required and duplicate native callback is rejected")
	shell.test_focused=false; await create_timer(.04).timeout
	frozen=session.snapshot(); await create_timer(.12).timeout
	check(session.snapshot().pose.localMs==frozen.pose.localMs and not session.consume(state.d),"dock hold pauses and cannot consume while unfocused")
	shell.test_focused=true
	check(await wait_phase(session,"consumed",2500),"full native path completes through existing controller")
	check(Time.get_ticks_msec()-start>=19600,"normal path never shortens authored route, 12.350-second native continuation or dock hold")
	check(state.d.native.scene=="dorm_hub" and state.d.qizhenLake.rainRescueCompleted and state.d.qizhenLake.weatherAdjustmentRequested,"native completion keeps dorm/weather handoff")
	before=state.d.qizhenLake.capsizeCount; state.act("c3_rain_rescue_result",session)
	check(state.d.qizhenLake.capsizeCount==before,"native duplicate receipt cannot increment capsize")

	# Cancellation while native drawing is live removes the whole presentation,
	# restores the original camera/actor, and leaves the controller retryable.
	fixture(state,shell,false); result=state.act("c3_lake_target:qizhen_dock_board"); session=result.world_effect.session
	presenter=shell.world_effect
	check(await wait_phase(session,"cinematic",6500),"cancellation test reaches live native cinematic")
	var original_camera: Vector2=presenter.old_camera
	var original_zoom: float=presenter.old_zoom
	shell._cancel_world_effect()
	# Assert the presentation restoration synchronously. On the next frame the
	# resumed exploration camera is allowed to follow its ordinary safe rect.
	check(shell.world.camera.is_equal_approx(original_camera) and is_equal_approx(shell.world.zoom,original_zoom) and not state.d.qizhenLake.rainRescueCompleted,"native cancellation restores camera/zoom and keeps source state retryable")
	await process_frame; await process_frame
	check(session.phase()=="cancelled" and not is_instance_valid(presenter) and not shell.world.presentation_actor_hidden,"native cancellation removes renderer and restores actor without progression")

	# Real skip runs exactly the old dock hold, then settles once.
	fixture(state,shell,false); result=state.act("c3_lake_target:qizhen_dock_board"); session=result.world_effect.session
	presenter=shell.world_effect
	check(await wait_phase(session,"cinematic",6500),"native retry starts a fresh registered presenter")
	presenter.skip.pressed.emit(); presenter.skip.pressed.emit()
	check(session.phase()=="rescued" and session.snapshot().outcome=="skipped" and not state.d.qizhenLake.rainRescueCompleted,"duplicate skip only begins one hold")
	check(await wait_phase(session,"consumed",2500),"skip runs source dock hold before controller settlement")

	# Scene replacement and presenter destruction leave retryable source state.
	fixture(state,shell,false); result=state.act("c3_lake_target:qizhen_dock_board"); session=result.world_effect.session
	state.d.native.scene="dorm_hub"; await create_timer(.05).timeout
	check(session.phase()=="cancelled" and not state.d.qizhenLake.rainRescueCompleted and not shell.world.presentation_actor_hidden,"scene change cancels and restores without progression")
	fixture(state,shell,false); result=state.act("c3_lake_target:qizhen_dock_board"); session=result.world_effect.session
	shell.world_effect.queue_free(); await process_frame; await process_frame
	check(session.phase()=="cancelled" and not state.d.qizhenLake.rainRescueCompleted and Session.eligible(state.d),"destroyed presenter cannot complete and retry remains eligible")
	state.act("c3_rain_rescue_result",session)
	check(not state.d.qizhenLake.rainRescueCompleted,"destroyed presenter stale callback is rejected")
	await shell.shutdown(); shell.queue_free(); await process_frame
	print("Rain rescue: ",checks," checks, ",failures," failures")
	quit(0 if failures==0 else 1)

func _run_graphical() -> void:
	var state=root.get_node("State")
	state.developer_mode=true
	var shell: Control=load("res://scenes/main.tscn").instantiate(); root.add_child(shell)
	root.grab_focus(); await create_timer(.15).timeout
	fixture(state,shell,false)
	check(DisplayServer.get_name()!="headless" and shell.get_window().has_focus(),"graphical test has real OS window focus")
	var result: Dictionary=state.act("c3_lake_target:qizhen_dock_board")
	check(result.has("world_effect"),"untouched graphical Main starts actual rain presenter")
	if not result.has("world_effect"):
		await shell.shutdown(); shell.queue_free(); quit(1); return
	var session: RefCounted=result.world_effect.session
	var presenter: Control=shell.world_effect
	var snapshot: Dictionary=presenter.read_state.call()
	check(not is_same(snapshot,state.d) and snapshot.native.host.focused and snapshot.native.host.world_visible,"unchanged Main host reader keeps focused deep-snapshot boundary")
	var capture_dir: String=OS.get_environment("RAIN_RESCUE_CAPTURE_DIR")
	if not capture_dir.is_empty(): DirAccess.make_dir_recursive_absolute(capture_dir)
	var captures: Array[int]=[0,5750,10550]
	var prelude_captured:=false
	var deadline: int=Time.get_ticks_msec()+30000
	var start: int=Time.get_ticks_msec()
	while Time.get_ticks_msec()<deadline and not state.d.qizhenLake.rainRescueCompleted:
		if session.phase()=="route" and session.snapshot().pose.stage=="capsize" and session.snapshot().pose.localMs>=850 and not prelude_captured:
			prelude_captured=true
			if not capture_dir.is_empty():
				await RenderingServer.frame_post_draw
				check(root.get_texture().get_image().save_png(capture_dir+"/prelude_capsize.png")==OK,"graphical source prelude capsize frame saved")
		if session.phase()=="cinematic" and not captures.is_empty() and session.snapshot().cinematicMs>=captures[0]:
			var at: int=captures.pop_front()
			check(is_instance_valid(presenter.native_renderer),"graphical timeline embeds actual native renderer")
			if at==0: check(presenter.native_renderer.elapsed>=2.65 and presenter.native_renderer.elapsed<2.85,"graphical native first frame is post-capsize hold_hull, never wind/fall")
			if not capture_dir.is_empty():
				await RenderingServer.frame_post_draw
				check(root.get_texture().get_image().save_png(capture_dir+"/native_rescue_"+str(at)+".png")==OK,"graphical rescue frame saved")
		await create_timer(.02).timeout
	check(state.d.qizhenLake.rainRescueCompleted and session.phase()=="consumed" and session.snapshot().outcome=="native","unchanged graphical Main completes native route through retained controller receipt")
	check(Time.get_ticks_msec()-start>=19600,"graphical completion preserves full native duration and dock hold")
	check(state.d.native.scene=="dorm_hub" and state.d.currentScene=="phone_home" and state.d.qizhenLake.weatherAdjustmentRequested,"graphical completion keeps original dorm/weather handoff")
	check(prelude_captured and captures.is_empty(),"graphical run preserves one prelude capsize before rescue contact and wet steps")
	await shell.shutdown(); shell.queue_free(); await process_frame
	print("Rain rescue graphical real focus: ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)

func _run_graphical_touch_skip() -> void:
	var state=root.get_node("State")
	state.developer_mode=true
	root.size=Vector2i(390,844)
	var shell: Control=load("res://scenes/main.tscn").instantiate(); root.add_child(shell)
	root.grab_focus(); await create_timer(.15).timeout
	fixture(state,shell,false)
	check(DisplayServer.get_name()!="headless" and shell.get_window().has_focus(),"portrait touch test has real OS window focus")
	var result: Dictionary=state.act("c3_lake_target:qizhen_dock_board")
	check(result.has("world_effect"),"portrait Main starts controller-issued rain presenter")
	if not result.has("world_effect"):
		await shell.shutdown(); shell.queue_free(); quit(1); return
	var session: RefCounted=result.world_effect.session
	var presenter: Control=shell.world_effect
	_check_compact_caption(presenter,state.content("chapter3-qizhen-lake.content").dock.forcedLaunch,"route")
	var capsize_deadline: int=Time.get_ticks_msec()+6500
	while Time.get_ticks_msec()<capsize_deadline and presenter.pose.get("stage","")!="capsize": await create_timer(.02).timeout
	_check_compact_caption(presenter,state.content("chapter3-qizhen-lake.content").dock.forcedCapsize,"capsize")
	check(await wait_phase(session,"cinematic",7500),"portrait rescue reaches native continuation")
	while session.phase()=="cinematic" and session.snapshot().cinematicMs<1050: await create_timer(.02).timeout
	var host: Dictionary=presenter.read_state.call().native.host
	var display_scale: float=host.world_display_scale
	check(not is_same(presenter.read_state.call(),state.d) and host.focused and host.world_visible,"portrait touch uses untouched Main host reader")
	check(presenter.native_renderer.size==Vector2(960,540) and shell.world_viewport.size==Vector2i(960,540),"touch adaptation preserves fixed native cinematic viewport")
	check(presenter.skip.size.y*display_scale>=44 and presenter.skip.get_theme_font_size("font_size")*display_scale>=16,"portrait skip has actual 44px minimum height and readable 16px font")
	check(Rect2(Vector2.ZERO,Vector2(960,540)).encloses(presenter.skip.get_rect()),"enlarged skip remains inside logical cinematic viewport")
	check(presenter.native_renderer.external_caption,"portrait native caption uses only one outer Label")
	_check_compact_caption(presenter,presenter.native_renderer.caption_text(),"native rescue")
	var source: Vector2=presenter.skip.get_global_transform_with_canvas()*(presenter.skip.size/2)
	var container_point: Vector2=source*shell.world_view.size/Vector2(shell.world_viewport.size)
	var point: Vector2=shell.world_view.get_global_transform_with_canvas()*container_point
	check(Rect2(Vector2.ZERO,Vector2(root.size)).has_point(point),"portrait skip center maps inside actual root window")
	var capture_dir: String=OS.get_environment("RAIN_RESCUE_CAPTURE_DIR")
	if not capture_dir.is_empty():
		DirAccess.make_dir_recursive_absolute(capture_dir)
		await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_png(capture_dir+"/native_rescue_portrait_touch_390x844.png")==OK,"portrait touch target screenshot saved")
	var touch_events: Array[String]=[]
	var pressed_events: Array[bool]=[]
	presenter.skip.gui_input.connect(func(input: InputEvent):
		if input is InputEventScreenTouch: touch_events.append("down" if input.pressed else "up"))
	presenter.skip.pressed.connect(func(): pressed_events.append(true))
	# Inject real root touch events. The engine and SubViewportContainer route
	# them into the existing Button. Never call pressed.emit or its handler.
	for down in [true,false]:
		var touch:=InputEventScreenTouch.new(); touch.position=point; touch.index=0; touch.pressed=down
		Input.parse_input_event(touch); Input.flush_buffered_events()
		await process_frame; await process_frame
	print("RAIN_TOUCH_SKIP: root=",point," scale=",display_scale," physical_size=",presenter.skip.size*display_scale," touch=",touch_events," pressed=",pressed_events.size()," phase=",session.phase())
	check(touch_events==["down","up"] and pressed_events.size()==1 and session.phase()=="rescued" and session.snapshot().outcome=="skipped","actual root ScreenTouch reaches Button and activates native skip exactly once")
	check(not state.d.qizhenLake.rainRescueCompleted,"touch skip cannot bypass dock hold")
	await process_frame
	_check_compact_caption(presenter,state.content("chapter3-qizhen-lake.content").dock.forcedRescue,"dock hold")
	check(await wait_phase(session,"consumed",2500),"touch skip consumes original controller receipt after dock hold")
	check(state.d.native.scene=="dorm_hub" and state.d.currentScene=="phone_home" and state.d.qizhenLake.rainRescueCompleted and not state.d.qizhenLake.rainSafetyCleared,"portrait touch preserves dorm handoff and weather gate")
	await shell.shutdown(); shell.queue_free(); await process_frame
	print("Rain rescue graphical touch skip: ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)

func _check_compact_caption(presenter: Control, expected: String, stage: String) -> void:
	var display_scale: float=presenter.read_state.call().native.host.world_display_scale
	var label: Label=presenter.caption
	check(label.visible and label.text==expected,stage+" caption preserves every original word in one visible Label")
	check(label.get_theme_font_size("font_size")*display_scale>=14,stage+" caption is at least 14 physical pixels")
	check(Rect2(0,424,960,116).encloses(label.get_rect()),stage+" caption stays inside original footer")
	check(label.get_line_count()<=2 and label.get_visible_line_count()==label.get_line_count(),stage+" caption wraps to at most two unclipped lines")
