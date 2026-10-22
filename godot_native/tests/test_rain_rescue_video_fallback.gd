extends SceneTree
const Model=preload("res://scripts/media/c3_rain_rescue_model.gd")
const Session=preload("res://scripts/media/c3_rain_rescue_session.gd")
const FOCUS_SHELL_PATH="res://tests/fixtures/rain_rescue_focus_shell.gd"
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error("TEST FAILED: "+label)
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var state=root.get_node("State")
	state.new_game(); state.developer_mode=true
	state.d.native.chapter=3; state.d.native.scene="qizhen_lake"; state.d.native.page="c3_lake"; state.d.native.settings.reduced_motion=false
	state.d.runtimeMode="rpg"; state.d.rpgScene="qizhen_lake"; state.d.rpgCheckpoint="qizhen_dock"
	var q: Dictionary=state.d.qizhenLake
	q.active=true; q.phase="boarding_tutorial"; q.zone="dock"; q.vehicle="on_foot"
	q.kayakEquipped=true; q.leftPaddleEquipped=true; q.rightPaddleEquipped=true; q.rainWarningSeen=true
	q.rainSafetyCleared=false; q.rainRescueCompleted=false
	var shell: Control=load("res://scenes/main.tscn").instantiate(); shell.set_script(load(FOCUS_SHELL_PATH)); root.add_child(shell)
	await process_frame
	shell._refresh(); shell.mobile_world=true; shell._layout(); shell.world.player=Vector2(690,620); shell.world._sync_player()
	# Exercise the supported explicit legacy-mode configuration with the exact
	# controller-issued capability and normal Main registration/consumer path.
	state.world_effect_requested.disconnect(shell._open_world_effect)
	state.world_effect_requested.connect(func(config: Dictionary):
		var legacy: Dictionary=config.duplicate(); legacy.cinematic_mode="video"
		shell._open_world_effect(legacy)
	)
	var result: Dictionary=state.act("c3_lake_target:qizhen_dock_board")
	var session: RefCounted=result.world_effect.session
	var presenter: Control=shell.world_effect
	var deadline: int=Time.get_ticks_msec()+6500
	while Time.get_ticks_msec()<deadline and session.phase()!="cinematic": await create_timer(.02).timeout
	check(session.phase()=="cinematic" and is_instance_valid(presenter.video),"legacy mode still opens actual VideoStreamPlayer")
	check(session.snapshot().cinematicMode=="video" and session.snapshot().cinematicDurationMs==5875,"legacy mode retains original declared video duration")
	check(Model.WATCHDOG_MS==9000 and Model.VIDEO_DURATION_MS==5875,"legacy watchdog and minimum are unchanged")
	check(not session.finish_cinematic(presenter,"video") and not session.finish_cinematic(presenter,"native"),"early video and foreign native callbacks cannot complete legacy mode")
	if is_instance_valid(presenter.video):
		await create_timer(.25).timeout
		check(presenter.video.stream!=null and presenter.video.stream_position>0,"real native Theora decoder advances")
		shell.test_focused=false; await create_timer(.04).timeout
		var frozen: float=presenter.video.stream_position
		var cinematic_ms: int=int(session.snapshot().cinematicMs)
		presenter.video.finished.emit(); presenter.skip.pressed.emit()
		await create_timer(.15).timeout
		check(presenter.video.paused and absf(presenter.video.stream_position-frozen)<.01 and session.snapshot().cinematicMs==cinematic_ms,"legacy decoder and session pause together")
		check(session.phase()=="cinematic" and not state.d.qizhenLake.rainRescueCompleted,"focus loss rejects decoder and skip callbacks")
		shell.test_focused=true
		presenter.skip.pressed.emit(); presenter.skip.pressed.emit()
		# Paused capability resumes on the next session sample before input can settle.
		await create_timer(.04).timeout
		presenter.skip.pressed.emit(); presenter.video.finished.emit()
		check(session.phase()=="rescued" and session.snapshot().outcome=="skipped","legacy skip settles once despite duplicate/late decoder callbacks")
	deadline=Time.get_ticks_msec()+2500
	while Time.get_ticks_msec()<deadline and not state.d.qizhenLake.rainRescueCompleted: await create_timer(.02).timeout
	check(state.d.qizhenLake.rainRescueCompleted and state.d.native.scene=="dorm_hub","legacy fallback still requires controller dock hold and dorm handoff")
	await shell.shutdown(); shell.queue_free(); await process_frame
	# A stalled legacy decoder still uses the original 9s watchdog. This is an
	# actual monotonic wait, followed by identity and live-owner consume guards.
	var bound: Dictionary={"runtimeMode":"rpg","rpgScene":"qizhen_lake","native":{"scene":"qizhen_lake"},"qizhenLake":{"active":true,"phase":"boarding_tutorial","zone":"dock","vehicle":"on_foot","rainWarningSeen":true,"rainSafetyCleared":false,"rainRescueCompleted":false}}
	var owner:=Node.new(); root.add_child(owner)
	var guarded: RefCounted=Session.new(); guarded.configure(true,Model.APPROACH_POINT,bound)
	check(guarded.begin(owner,"video"),"legacy watchdog registers live owner")
	deadline=Time.get_ticks_msec()+12500
	while Time.get_ticks_msec()<deadline and guarded.phase()!="complete":
		guarded.sample(owner)
		await create_timer(.02).timeout
	check(guarded.phase()=="complete" and guarded.snapshot().outcome=="fallback" and guarded.snapshot().reason=="watchdog" and guarded.snapshot().cinematicMs>=9000,"legacy watchdog runs at unchanged 9s then requires dock hold")
	check(not guarded.consume(bound.duplicate(true)),"matching contents in foreign state identity cannot consume")
	guarded.sample(owner,false)
	check(not guarded.consume(bound),"even completed receipt cannot consume while focus-paused")
	guarded.sample(owner,true); root.remove_child(owner)
	check(not guarded.consume(bound),"detached presenter is not a live registered consumer")
	root.add_child(owner)
	check(guarded.consume(bound) and not guarded.consume(bound),"same bound state and live owner consume once")
	owner.queue_free(); await process_frame
	print("Rain rescue video fallback: ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)
