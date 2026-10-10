extends "res://tests/test_lake_shell_input.gd"
## Synthetic pursuit fixture. Verifies original feedback timing, not earned play.
func run() -> void:
	if not OS.get_user_data_dir().begins_with("/tmp/"): quit(1); return
	state=root.get_node("State");state.developer_mode=false;state.d=state.initial()
	root.size=Vector2i(430,860)
	var s: Dictionary=state.d
	s.native.chapter=3;s.native.scene="qizhen_lake";s.native.page="c3_lake";s.native.mode="light";s.runtimeMode="rpg";s.rpgScene="qizhen_lake"
	s.qizhenLake.merge({"active":true,"phase":"swan_chase","zone":"channel","vehicle":"kayak","boardingTutorialCompleted":true,"rainSafetyCleared":true,"kayakEquipped":true,"leftPaddleEquipped":true,"rightPaddleEquipped":true,"paperCaptured":true,"swanReleased":true,"chaseAttempts":1,"chaseDistance":0,"safeSpawnId":"channel_chase"},true)
	s.items.magneticFishingRod=true
	shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await flush()
	shell._show_world_mobile();await flush()
	check(shell.world_frame.is_visible_in_tree(),"pursuit timing fixture owns the visible world")
	for i in range(600):
		shell.world._process(1.0/60.0)
		if s.qizhenLake.chaseAttempts==2: break
	var source: Dictionary=state.content("chapter3-qizhen-lake.content.json")
	var failure_text: String=str(source.chase.caught)+str(source.chase.failed)
	check(s.qizhenLake.chaseAttempts==2 and shell.world.lake_session.status=="recovering","one original idle catch starts one recovery")
	check(shell.world.subtitle==failure_text,"caught feedback keeps both original sentences")
	check(absf(shell.world.subtitle_left-3.0)<.0001,"swan-catch footer uses original3000ms instead of generic text-length duration")
	var left: float=shell.world.subtitle_left
	shell._show_phone_surface();await flush()
	var attempts: int=s.qizhenLake.chaseAttempts
	for i in range(100):shell.world._process(.05)
	check(is_equal_approx(shell.world.subtitle_left,left) and s.qizhenLake.chaseAttempts==attempts,"hidden phone mode freezes both footer and pursuit")
	shell._show_world_mobile();await flush()
	for i in range(62):shell.world._process(1.0/60.0)
	check(shell.world.lake_session.status=="recovering" and shell.world.subtitle==failure_text,"source1040ms recovery still displays the original failure")
	for i in range(117):shell.world._process(1.0/60.0)
	check(shell.world.lake_session.status=="running" and s.qizhenLake.chaseAttempts==attempts,"original automatic retry and counter stay unchanged")
	check(shell.world.subtitle==failure_text,"caught text remains visible until the original3000ms boundary")
	for i in range(2):shell.world._process(1.0/60.0)
	check(shell.world.subtitle!=failure_text,"previous failure is gone after the source3000ms deadline")
	state.feedback.emit("其他交互提示")
	check(is_equal_approx(shell.world.subtitle_left,2.4),"unrelated short feedback retains generic duration")
	var facts: Dictionary=s.duplicate(true)
	var result: Dictionary=state.last_result.duplicate(true)
	state.last_result={"message":failure_text,"presentation":[]}
	state.feedback.emit(failure_text)
	check(is_equal_approx(shell.world.subtitle_left,4.6),"matching wording without the issued catch cue keeps ordinary duration")
	state.last_result.presentation=[{"cueId":"qizhen_chase_failed","payload":{"reason":"same_side_strokes"}}]
	state.feedback.emit(failure_text)
	check(is_equal_approx(shell.world.subtitle_left,4.6),"other failure reasons do not inherit the swan-catch deadline")
	state.last_result.presentation=[{"cueId":"qizhen_chase_failed","payload":{"reason":"swan_caught"}}]
	state.feedback.emit(failure_text)
	check(is_equal_approx(shell.world.subtitle_left,3.0),"Main and World use one source duration instead of overwriting each other")
	state.feedback.emit("其他交互提示")
	check(is_equal_approx(shell.world.subtitle_left,2.4),"stale catch metadata cannot shorten another message")
	check(s==facts,"feedback display cannot change gameplay or earned state")
	state.last_result=result
	await shell.shutdown();shell.queue_free();await process_frame
	print("LAKE_PURSUIT_FEEDBACK: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
