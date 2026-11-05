extends SceneTree
## Real Main/State, isolated save and deterministic presentation clock boundaries.
var state: Node
var shell: Control
var checks:=0
var failures:=0
var capture_dir:=""
func _initialize()->void:run.call_deferred()
func frames(count:int=3)->void:
	for unused in count:await process_frame
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error("BATTERY_PRANK_STORY: "+label)
func fixture()->void:
	state.d=state.initial();state.d.native.page="phone_home";state.d.phoneBattery.percent=2;state.d.ui.brightness=37
	state.story_reset.emit();shell._refresh();shell._layout();await frames()
	shell.set_process(false);shell.audio_director.set_process(false);shell.audio_director.reset();shell.world.set_process(false)
	shell.battery_prank.set_process(false);shell._clear_notice_presentations()
func capture(label:String)->void:
	if capture_dir.is_empty() or DisplayServer.get_name()=="headless":return
	await frames(2);await RenderingServer.frame_post_draw
	var image:=root.get_texture().get_image()
	check(not image.is_empty() and image.save_png(capture_dir.path_join(label+".png"))==OK,"capture real Main frame: "+label)
func run()->void:
	for argument:String in OS.get_cmdline_user_args():
		if argument.begins_with("--battery-prank-capture="):capture_dir=argument.trim_prefix("--battery-prank-capture=")
	if not capture_dir.is_empty():DirAccess.make_dir_recursive_absolute(capture_dir)
	if not load("res://tests/native_test_isolation.gd").is_isolated_save():quit(2);return
	create_timer(90).timeout.connect(func():push_error("Battery story deadline");quit(2))
	state=root.get_node("State");state.developer_mode=true;state.d=state.initial()
	shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames(5)
	for extent:Vector2i in [Vector2i(430,860),Vector2i(390,844),Vector2i(1440,900)]:
		root.size=extent;shell.size=Vector2(extent)
		if DisplayServer.get_name()!="headless":DisplayServer.window_set_size(extent)
		await fixture()
		var prefix:="%dx%d-"%[extent.x,extent.y]
		var prank:Control=shell.battery_prank
		check(not prank.visible and not prank.used,"initial battery and loading alone do not trigger story")
		state.act("c1_network","cellular");await frames()
		check(state.d.phoneBattery.percent==1 and not prank.used,"arrival at 1 percent does not trigger early")
		for page:String in ["wechat","phone_home","bonsai","settings","phone_home"]:state.open_page(page)
		await frames()
		check(not prank.used and state.d.phoneBattery.percent==1,"ordinary app/home/back navigation never triggers or consumes reserve")
		state.act("c1_network","campus_wifi");await frames();prank._process(0);shell._layout();shell._advance_notices(0)
		check(prank.used and prank.visible and state.d.phoneBattery.percent==0,"next network action already at 1 starts exact prank while real battery reaches zero")
		var deadline:int=prank.deadline
		await capture(prefix+"01-warning")
		check(prank.view(deadline-10000)=={"kind":"warning","text":"请在 10秒之内充电，不然手机就会自动关机。","seconds":10},"exact original warning copy and countdown")
		check(prank.view(deadline-1).kind=="warning" and prank.view(deadline).text=="吓吓你的","exact ten-second transition and punchline")
		check(prank.view(deadline+3499).kind=="joke" and prank.view(deadline+3500).is_empty(),"exact 3.5 second joke expiry")
		check(prank.mouse_filter==Control.MOUSE_FILTER_IGNORE and prank.panel.mouse_filter==Control.MOUSE_FILTER_IGNORE and prank.notice.mouse_filter==Control.MOUSE_FILTER_IGNORE,"prank cannot intercept gameplay input")
		check(shell.phone.get_global_rect().encloses(prank.panel.get_global_rect()),"warning remains within scaled phone at "+str(extent))
		check(not shell.page_body.find_child("HomeFriendNotice",true,false).visible,"home banner yields without stacking under warning")
		for repeat in 6:
			state.act("c1_network","cellular" if repeat%2==0 else "campus_wifi")
			prank.consume_reserve(1)
		check(state.d.phoneBattery.percent==0 and prank.deadline==deadline,"repeated zero actions and duplicate events cannot restart the clock")
		check(state.d.ui.brightness==37 and not state.story_input_locked(),"story never dims screen or locks navigation")
		state.open_page("wechat");await frames();shell._layout()
		check(state.d.native.page=="wechat" and prank.deadline==deadline,"changing app during countdown preserves one story owner")
		state.open_page("phone_home");await frames();shell._layout()
		shell._on_phone_page("control_center");await frames()
		check(is_instance_valid(shell.control_center) and prank.deadline==deadline,"control-center interruption cannot restart or lock countdown")
		shell._on_phone_action("native_control_center_close",null);await frames()
		check(not is_instance_valid(shell.control_center) and prank.deadline==deadline,"control-center close returns without canceling or repeating story")
		shell._show_settings();await frames()
		check(is_instance_valid(shell.modal) and prank.deadline==deadline,"save/settings modal remains usable during warning")
		shell._close_modal();await frames()
		check(not is_instance_valid(shell.modal) and prank.deadline==deadline,"modal cancellation preserves original story deadline")
		var committed:Dictionary=state.d.duplicate(true)
		shell._feedback("旧的普通提示");shell._feedback("最新的普通提示")
		check(shell.notice_queue.current.text=="最新的普通提示" and shell.notice_queue.pending.is_empty(),"restored story never revives ordinary FIFO")
		shell._advance_notices(20)
		check(shell.notice_queue.current.is_empty(),"hidden latest ordinary notice still expires")
		var director:Node=shell.audio_director
		director.reset()
		director.schedule_cue("native_story_subtitle",{"text":"系统：第一句保留对白","tone":"system","durationMs":1200},100000)
		director.schedule_cue("native_story_subtitle",{"text":"玩家：第二句保留对白","tone":"player","durationMs":1200},200000)
		var scheduled:Array=director.scheduled.duplicate(true)
		prank.tick(deadline)
		await capture(prefix+"02-joke")
		check(prank.notice.text=="吓吓你的" and director.scheduled==scheduled,"punchline does not consume or retime critical dialogue")
		director.scheduled[0].at=director.presentation_clock();director._process(0)
		check(shell.story_caption_line.text=="系统：第一句保留对白","first critical cue retains order during prank")
		director.scheduled[0].at=director.presentation_clock();director._process(0)
		check(shell.story_caption_line.text=="玩家：第二句保留对白","second critical cue retains order during prank")
		prank.tick(deadline+3500);shell._advance_notices(10)
		await capture(prefix+"03-return")
		check(not prank.visible and shell.notice_queue.current.is_empty(),"expiry hides story and never replays stale ordinary feedback")
		check(state.d==committed,"warning, joke and critical presentation clocks never mutate battery or story state")
		prank.consume_reserve(1);check(not prank.visible,"completed prank cannot restart without reset")
		state.story_reset.emit();await frames()
		check(not prank.used and not prank.visible and prank.deadline<0,"story reset cancels deadline, punchline and consumed flag")
		prank.consume_reserve(1);check(prank.visible,"new story can arm once after reset")
		state.story_reset.emit();await frames();check(not prank.visible,"interrupted reset cannot leave stale warning or input gate")
	await shell.shutdown();shell.queue_free();await frames()
	print("BATTERY_PRANK_STORY: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
