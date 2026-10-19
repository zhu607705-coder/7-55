extends SceneTree
var failures:=0
var checks:=0
func check(value: bool,message: String) -> void:
	checks+=1
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
	# The real discovery film retains its own reading surface. Ordinary feedback
	# must wait rather than overwrite it; release below is presentation-only.
	shell.set_process(false);shell.audio_director.set_process(false)
	shell._clear_notice_presentations()
	var owner_text: String=shell.world.subtitle
	check(shell.c3_scene_host.owns_world_contract() and shell.c3_scene_host.paper.session==shell.c3_scene_host.current,"real scene presentation owns the reading surface")
	shell._feedback("单一场景字幕")
	check(shell.notice_queue.current.get("text","")=="单一场景字幕" and shell.notice_surface.is_empty(),"world feedback queues behind the live scene owner")
	check(shell.world.subtitle==owner_text and shell.toast.text.is_empty() and not shell.toast.visible,"waiting feedback cannot create a second subtitle owner")
	shell.audio_director.subtitle_timed.emit("单一语音字幕","toast",4200,"system")
	check(shell.notice_queue.pending.size()==1 and shell.notice_queue.pending[0].text=="单一语音字幕" and is_equal_approx(shell.notice_queue.pending[0].duration,4.2),"audio-derived exact duration queues after the first feedback")
	var unread: float=shell.notice_queue.current.remaining
	shell._process(8)
	check(is_equal_approx(shell.notice_queue.current.remaining,unread) and shell.world.subtitle==owner_text and shell.toast.text.is_empty() and not shell.toast.visible,"scene-time waiting spends no unread notice lifetime and never overwrites its owner")
	print("WORLD_OWNER_DIAGNOSTIC ",JSON.stringify({"sceneOwns":shell.c3_scene_host.owns_world_contract(),"noticeSurface":shell.notice_surface,"toastVisible":shell.toast.visible,"worldSubtitle":shell.world.subtitle,"queueCurrent":shell.notice_queue.current,"queuePending":shell.notice_queue.pending}))
	# Explicitly release only the presentation fixture, without granting story facts.
	shell.c3_scene_host.reset();shell.world.subtitle="";shell.world.subtitle_left=0
	shell._layout_toast()
	check(shell.world.subtitle=="单一场景字幕" and shell.notice_surface=="world" and shell.toast.text.is_empty() and not shell.toast.visible,"released scene hands the first queued notice to exactly one world surface")
	for i in 200:
		if shell.world.subtitle!="单一场景字幕":break
		shell.world._process(.05);shell._process(.05)
	print("WORLD_FIFO_DIAGNOSTIC ",JSON.stringify({"worldText":shell.world.subtitle,"left":shell.world.subtitle_left,"surface":shell.notice_surface,"current":shell.notice_queue.current,"pending":shell.notice_queue.pending}))
	check(shell.world.subtitle=="单一语音字幕" and is_equal_approx(shell.world.subtitle_left,4.2) and shell.toast.text.is_empty() and not shell.toast.visible,"FIFO audio-derived notice begins with its complete authored4.2-second lifetime on the same single world surface")
	for i in 10: shell.world._process(.05);shell._process(.05)
	check(is_equal_approx(shell.world.subtitle_left,3.7),"visible world notice uses its actual surface reading clock")
	for i in 200:
		if shell.notice_queue.current.is_empty():break
		shell.world._process(.05);shell._process(.05)
	check(shell.notice_queue.current.is_empty() and shell.notice_queue.pending.is_empty() and shell.world.subtitle.is_empty() and shell.toast.text.is_empty() and not shell.toast.visible,"both queued notices expire once without a duplicate root surface")
	shell.c3_scene_host.reset(); state.d.native.scene=""; state.d.runtimeMode="phone"
	await shell.shutdown(); shell.queue_free(); await process_frame
	print("World presentation/input lifecycle checks: ",checks,"; failures: ",failures)
	quit(1 if failures else 0)
