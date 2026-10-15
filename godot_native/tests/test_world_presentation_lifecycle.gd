extends SceneTree
var failures:=0
func check(value: bool,message: String) -> void:
	if not value: failures+=1; push_error("TEST FAILED: "+message)
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	var state=root.get_node("State"); state.developer_mode=true
	var shell=load("res://scenes/main.tscn").instantiate(); root.add_child(shell); await process_frame
	state.begin_checkpoint("c3-canteen-entry"); shell._refresh(); shell.mobile_world=true; shell._layout(); shell.world.set_process(false); shell.c3_scene_host.set_process(false)
	shell.world.player=Vector2(1053,660); shell.world._sync_player(); shell.c3_scene_host.tick(0,true)
	check(shell.c3_scene_host.blocks_world_input(),"real canteen discovery locks physical input")
	shell.world.transition_alpha=1.0
	var before: Vector2=shell.world.player
	for i in 12: shell.world._process(.05)
	check(shell.world.transition_alpha==0,"transition fade completes while authored scene owns input")
	check(shell.world.player==before,"presentation fade does not release player control")
	shell._feedback("单一场景字幕")
	check(shell.world.subtitle=="单一场景字幕" and shell.toast.text.is_empty(),"world feedback has one subtitle owner")
	shell.audio_director.subtitle_timed.emit("单一语音字幕","toast",4200,"system")
	check(shell.world.subtitle=="单一语音字幕" and is_equal_approx(shell.world.subtitle_left,4.2) and shell.toast.text.is_empty(),"audio-derived duration uses same source world surface")
	shell.c3_scene_host.reset(); state.d.native.scene=""; state.d.runtimeMode="phone"
	await shell.shutdown(); shell.queue_free(); await process_frame
	print("World presentation/input lifecycle failures: ",failures)
	quit(1 if failures else 0)
