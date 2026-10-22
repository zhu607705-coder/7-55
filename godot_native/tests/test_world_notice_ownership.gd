extends SceneTree
## Real State feedback, Main/world ownership and natural surface clocks.
## Uses the disposable native save profile; never completes a story gate.
var failures:=0
var checks:=0
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error("WORLD_NOTICE_OWNERSHIP: "+label)
func _initialize()->void:run.call_deferred()
func tick(shell:Control,count:int)->void:
	for i in count:shell.world._process(.05);shell._process(.05)
func until_next(shell:Control,text:String)->void:
	for i in 200:
		if shell.notice_queue.current.get("text","")!=text:return
		tick(shell,1)
func run()->void:
	check(load("res://tests/native_test_isolation.gd").is_isolated_save(),"isolated save profile")
	if failures:quit(1);return
	var state=root.get_node("State");state.developer_mode=true
	var shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await process_frame
	state.begin_checkpoint("c3-canteen-entry");shell._refresh();shell.mobile_world=true;shell._layout()
	shell.set_process(false);shell.audio_director.set_process(false);shell.world.set_process(false);shell.c3_scene_host.set_process(false)
	shell.world.player=Vector2(1053,660);shell.world._sync_player();shell.c3_scene_host.tick(0,true);shell._clear_notice_presentations()
	check(shell.c3_scene_host.owns_world_contract(),"real scene owns the reading surface")
	check(not state.feedback.is_connected(shell.world._receive_feedback),"Main owns State feedback instead of a second direct world route")
	var owner:String=shell.world.subtitle
	for text in ["甲通知","乙通知","丙通知"]:state.feedback.emit(text)
	check(shell.world.subtitle==owner and shell.toast.text.is_empty() and not shell.toast.visible,"State feedback burst never leaks over an active scene")
	check(shell.notice_queue.current.get("text","")=="甲通知" and shell.notice_queue.pending.size()==2,"State burst retains the first reading item and both following unique items")
	shell._process(9)
	check(is_equal_approx(shell.notice_queue.current.remaining,2.4),"scene waiting consumes no notice lifetime")
	shell.c3_scene_host.reset();shell.world.subtitle="";shell.world.subtitle_left=0;shell._layout_toast()
	check(shell.world.subtitle=="甲通知" and is_equal_approx(shell.world.subtitle_left,2.4),"scene release starts the first State message at its full lifetime")
	until_next(shell,"甲通知")
	check(shell.world.subtitle=="乙通知" and is_equal_approx(shell.world.subtitle_left,2.4),"first actual world expiry starts only the second State message at full duration")
	tick(shell,1)
	check(is_equal_approx(shell.world.subtitle_left,2.35),"world reading time is deducted once, not twice per tick")
	until_next(shell,"乙通知")
	check(shell.world.subtitle=="丙通知" and is_equal_approx(shell.world.subtitle_left,2.4),"second expiry starts only the third State message at full duration")
	until_next(shell,"丙通知")
	check(shell.notice_queue.current.is_empty() and shell.notice_queue.pending.is_empty() and shell.world.subtitle.is_empty(),"all State messages expire once with no replay or stale FIFO head")
	state.feedback.emit("跨面通知");tick(shell,10)
	var remaining:float=shell.notice_queue.current.remaining
	shell._show_phone_surface();shell._layout_toast()
	check(shell.notice_surface=="toast" and shell.toast.text=="跨面通知" and shell.world.subtitle.is_empty() and is_equal_approx(shell.toast_time,remaining),"ordinary world-to-phone route preserves unread time and one surface")
	shell._process(.3);remaining-=.3;shell._return_from_phone();shell._layout_toast()
	check(shell.notice_surface=="world" and shell.world.subtitle=="跨面通知" and shell.toast.text.is_empty() and is_equal_approx(shell.world.subtitle_left,remaining),"ordinary phone-to-world route retains its unread time")
	shell.world._receive_feedback("跨面通知");shell.world.subtitle_left=.1
	shell._layout_toast()
	check(shell.notice_surface.is_empty() and shell.world.subtitle=="跨面通知" and is_equal_approx(shell.notice_queue.current.remaining,remaining),"an external same-text owner does not clear or charge the queued notice")
	tick(shell,2)
	check(shell.notice_queue.current.get("text","")=="跨面通知" and is_equal_approx(shell.notice_queue.current.remaining,remaining),"external same-text expiry cannot finish Main's different owner token")
	check(shell.notice_surface=="world" and is_equal_approx(shell.world.subtitle_left,remaining),"external owner releases to the same unread Main item")
	# Direct clearing or replacement is not a natural-expiry acknowledgement.
	shell.world.subtitle="";shell.world.subtitle_left=0;shell._layout_toast()
	check(shell.notice_queue.current.get("text","")=="跨面通知" and is_equal_approx(shell.world.subtitle_left,remaining),"an external clear resumes rather than consumes unread content")
	until_next(shell,"跨面通知")
	check(shell.notice_queue.current.is_empty() and shell.world.subtitle.is_empty(),"resumed surface eventually completes once")
	await shell.shutdown();shell.queue_free();await process_frame
	var standalone=load("res://scripts/world.gd").new();root.add_child(standalone);standalone.set_process(false)
	state.feedback.emit("独立世界反馈")
	check(state.feedback.is_connected(standalone._receive_feedback) and standalone.subtitle=="独立世界反馈","standalone World retains its State feedback fallback")
	standalone.queue_free();await process_frame
	print("WORLD_NOTICE_OWNERSHIP: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
