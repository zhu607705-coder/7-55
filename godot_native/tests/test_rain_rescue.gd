extends SceneTree
const Model=preload("res://scripts/media/c3_rain_rescue_model.gd")
const Session=preload("res://scripts/media/c3_rain_rescue_session.gd")
var failures:=0
var checks:=0
func check(value: bool,message: String) -> void:
	checks+=1
	if not value: failures+=1; push_error("TEST FAILED: "+message)
func _initialize() -> void: _run.call_deferred()
func fixture(state: Node) -> void:
	state.new_game(); state.developer_mode=true
	state.d.native.chapter=3; state.d.native.scene="qizhen_lake"; state.d.native.page="c3_lake"
	state.d.native.settings.reduced_motion=true
	state.d.runtimeMode="rpg"; state.d.rpgScene="qizhen_lake"; state.d.rpgCheckpoint="qizhen_dock"
	var q: Dictionary=state.d.qizhenLake
	q.active=true; q.phase="boarding_tutorial"; q.zone="dock"; q.vehicle="on_foot"
	q.kayakEquipped=true; q.leftPaddleEquipped=true; q.rightPaddleEquipped=true; q.rainWarningSeen=true
	q.rainSafetyCleared=false; q.rainRescueCompleted=false
func _run() -> void:
	var state=root.get_node("State")
	state.developer_mode=true
	var shell=load("res://scenes/main.tscn").instantiate(); root.add_child(shell)
	await process_frame
	fixture(state); shell._refresh(); shell.mobile_world=true; shell._layout()
	shell.world.player=Vector2(690,620); shell.world._sync_player()
	var before: int=state.d.qizhenLake.capsizeCount
	var result: Dictionary=state.act("c3_lake_target:qizhen_dock_board")
	check(result.has("world_effect") and not result.has("game"),"rain path requests authored world sequence instead of four-stroke minigame")
	if not result.has("world_effect"): shell.queue_free(); quit(1); return
	shell.world_effect.read_state=func() -> Dictionary: return state.d
	var session: RefCounted=result.world_effect.session
	check(not state.d.qizhenLake.rainRescueCompleted,"starting rescue writes no completion")
	state.act("c3_rain_rescue_result",{"success":true})
	check(not state.d.qizhenLake.rainRescueCompleted,"forged dictionary cannot complete rescue")
	state.act("c3_rain_rescue_result",session)
	check(not state.d.qizhenLake.rainRescueCompleted,"issued receipt cannot complete early")
	check(shell.world.presentation_actor_hidden,"source actor is replaced by transient rescue actor")
	check(is_equal_approx(Model.pre_cinematic_ms(false),5650) and is_equal_approx(Model.duration_ms(false),7250),"exact normal source route and hold timing")
	check(is_equal_approx(Model.pre_cinematic_ms(true),1460) and is_equal_approx(Model.duration_ms(true),2260),"exact reduced source route and hold timing")
	var start:=Time.get_ticks_msec()
	while Time.get_ticks_msec()-start<4000 and not state.d.qizhenLake.rainRescueCompleted: await create_timer(.025).timeout
	check(state.d.qizhenLake.rainRescueCompleted and state.d.qizhenLake.phase=="rain_recovery","real reduced route plus deterministic dock hold completes")
	check(state.d.native.scene=="dorm_hub" and state.d.currentScene=="phone_home" and state.d.native.page=="phone_home","source rescue returns dorm with phone-home route")
	check(state.d.qizhenLake.capsizeCount==before+1 and state.d.qizhenLake.boardingStrokeCount==0 and state.d.qizhenLake.boardingLastSide==null,"atomic source capsize and tutorial reset")
	check(not shell.world.presentation_actor_hidden,"presenter restores actor on completion")
	state.act("c3_rain_rescue_result",session)
	check(state.d.qizhenLake.capsizeCount==before+1,"receipt cannot settle twice")
	# A changed scene interrupts without creating rescue proof and can retry.
	fixture(state); shell._refresh(); shell.mobile_world=true; shell._layout(); shell.world.player=Vector2(690,620); shell.world._sync_player()
	result=state.act("c3_lake_target:qizhen_dock_board")
	shell._cancel_world_effect(); await process_frame
	check(not state.d.qizhenLake.rainRescueCompleted and not shell.world.presentation_actor_hidden,"cancel restores rendering without progression")
	check(Session.eligible(state.d),"canceled source state remains retryable")
	# Normal path reaches actual native decoder; skip is the exact source UI action.
	state.d.native.settings.reduced_motion=false; result=state.act("c3_lake_target:qizhen_dock_board")
	session=result.world_effect.session
	shell.world_effect.read_state=func() -> Dictionary: return state.d
	start=Time.get_ticks_msec()
	while Time.get_ticks_msec()-start<7000 and session.phase()!="cinematic": await create_timer(.025).timeout
	check(session.phase()=="cinematic" and is_instance_valid(shell.world_effect.video),"normal authored path opens actual VideoStreamPlayer")
	if is_instance_valid(shell.world_effect.video):
		await create_timer(.25).timeout
		check(shell.world_effect.video.stream!=null and shell.world_effect.video.stream_position>0,"native Theora playback advances")
		shell.world_effect.skip.pressed.emit()
	start=Time.get_ticks_msec()
	while Time.get_ticks_msec()-start<2500 and not state.d.qizhenLake.rainRescueCompleted: await create_timer(.025).timeout
	check(state.d.qizhenLake.rainRescueCompleted,"skip replay still runs source dock hold then controller settlement")
	await shell.shutdown()
	shell.queue_free(); await process_frame
	print("Rain rescue: ",checks," checks, ",failures," failures")
	quit(0 if failures==0 else 1)
