extends SceneTree
var checks:=0
var failures:=0
var state:Node
var shell:Control
func _initialize():run.call_deferred()
func frames(n:int=3):
	for i in n:await process_frame
func check(ok:bool,label:String):
	checks+=1
	if not ok:failures+=1;push_error(label)
func run():
	state=root.get_node("State")
	for view in [Vector2i(390,844),Vector2i(430,860),Vector2i(1180,812)]:
		root.size=view;state.d=state.initial();state.developer_mode=true
		state.d.qizhenLake.phase="complete";state.d.chapterThreeInterlude.recoveryOpened=true;state.d.chapterThreeInterlude.phase="destination_verified";state.d.chapterThreeInterlude.destinationId="duan_yongping_a1";state.d.chapterThreeInterlude.evidenceIds=["journal_start","photo_direction","broadcast_end","network_destination"]
		state.d.chapterThreeInterlude.rejectedDecoyIds=["canteen_0755","theater_0832","status_clock_075523"];state.d.chapterThreeInterlude.statusClockMarkedUntrusted=true
		state.d.native.page="c35_recovery";state.d.native.settings.reduced_motion=true
		shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames()
		state.act("c35_replay");await frames()
		check(is_instance_valid(shell.active_game),"accepted Replay opens one film without second Play")
		if not is_instance_valid(shell.active_game):await shell.shutdown();shell.queue_free();await frames();continue
		var owner=shell.active_game;owner.set_process(false)
		shell._resume_recovered_replay();shell._refresh();shell._layout();await frames()
		check(shell.active_game==owner,"repeated admission and refresh keep one film")
		check(not shell.toast.visible,"source admission notice does not cover film controls")
		owner.cancelled.emit();await frames();shell._refresh();shell._layout();await frames()
		check(not is_instance_valid(shell.active_game),"deliberate Return remains closed")
		check(not state.d.chapter4.prologueSeen,"Return never commits chapter completion")
		shell._resume_recovered_replay();await frames();owner=shell.active_game;owner.set_process(false)
		owner._skip_prologue();await frames()
		check(not state.d.chapter4.prologueSeen and owner.stage=="card","source Skip waits for explicit acknowledgment")
		owner._finish({"acknowledged":true});await frames(1)
		check(state.d.chapter4.prologueSeen and state.d.chapter4.phase=="opening_handoff","issued proof commits original opening handoff")
		check(shell.mobile_world and shell.world_frame.visible and not shell.phone.visible,"accepted world effect reveals world before its animation")
		check(is_instance_valid(shell.world_effect) and shell.world_effect.kind=="paper_flight","one original paper-flight owner")
		check(not shell.world_viewport.gui_disable_input,"visible scene has correct viewport input")
		await shell.shutdown();shell.queue_free();await frames(5)
	print("REPLAY_WORLD_HANDOFF ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
