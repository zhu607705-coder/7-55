extends SceneTree
## Actual Main, State/controller, audio scheduler and real control visibility.
## No game progress is granted by a timer or notice; saved logs stay independent.
var checks:=0
var failures:=0
var shell: Control
var state: Node
func _initialize() -> void: run.call_deferred()
func frames(count:int=3) -> void:
	for index in count: await process_frame
func check(ok:bool,label:String) -> void:
	checks+=1
	if not ok: failures+=1;push_error("TRANSIENT_NOTICE_LATEST: "+label)
func shown(text:String) -> bool:
	return shell.toast.is_visible_in_tree() and shell.toast.text==text and shell.notice_queue.current.get("text","")==text and shell.notice_queue.pending.is_empty()

func check_balance_cue() -> void:
	var director: Node=shell.audio_director
	for intervening_event: String in ["none","newer","expiry"]:
		director.reset()
		shell._clear_notice_presentations()
		state.d=state.initial()
		state.d.native.chapter=2;state.d.native.page="campus_card"
		state.d.actOne.phase="movement_required";state.d.actOne.rightArrowAssembled=true
		state.d.actOne.inventoryRecovered=true;state.d.items.campusCard=true;state.d.items.rightArrow=true
		state.d.flags.checkinDone=true;state.d.native.selected_item="rightArrow"
		state.changed.emit();await frames()
		var balance: Button=shell.find_child("CampusCardBalance",true,false)
		check(is_instance_valid(balance) and balance.is_visible_in_tree() and not balance.disabled,"campus card opens with the original balance control")
		if not is_instance_valid(balance):continue
		balance.pressed.emit()
		var message: String=state.last_result.get("message","")
		check(state.d.wallet.campusCardCents==600 and shown(message),"right arrow applies and the receipt starts in the phone's top lane")
		var balance_cues: Array=director.scheduled.filter(func(entry: Dictionary)->bool:return entry.id=="act2_balance_shifted")
		check(balance_cues.any(func(entry: Dictionary)->bool:return entry.get("cue",{}).get("channel")=="text"),"the actual balance event has a scheduled subtitle")
		if intervening_event=="newer":
			message="后续操作提示"
			state.feedback.emit(message)
		shell._advance_notices(7.0 if intervening_event=="expiry" else .1)
		var anchor: Rect2=shell.toast.get_global_rect()
		var time: float=shell.toast_time
		for entry: Dictionary in balance_cues:entry.at=director.presentation_clock()
		director._process(0)
		if intervening_event=="expiry":
			check(not shell.toast.visible and shell.notice_queue.current.is_empty(),"late audio cannot resurrect an expired receipt")
		else:
			check(shown(message) and shell.toast.get_global_rect().is_equal_approx(anchor) and is_equal_approx(shell.toast_time,time),"delayed duplicate neither moves nor renews the visible receipt")
		check(not shell.phone_story_caption.visible and not shell.story_caption.visible,"delayed duplicate never opens a second caption")
		await frames()

func check_spoken_feedback() -> void:
	var director: Node=shell.audio_director
	director.reset();shell._clear_notice_presentations()
	var text: String=director.source.storyLines.prologue_narrator_caught.subtitleZh
	director.source.events.notice_test_receipt_voice={"cues":[{"channel":"voice","asset":"vo_prologue_narrator_caught","subtitleKey":"prologue_narrator_caught","durationMs":180}]}
	state.feedback.emit(text)
	director.update_state("notice_test",state.d,state.d,{"message":text,"presentation":["notice_test_receipt_voice"]})
	for entry: Dictionary in director.scheduled:entry.at=director.presentation_clock()
	director._process(0)
	check(director.last_subtitle.text==text and director.last_subtitle.get("repeatsFeedback",false) and director.voice_asset=="vo_prologue_narrator_caught" and shown(text) and not shell.phone_story_caption.visible,"voice still plays while its duplicate keeps the first visual owner")
	await frames()
	director.reset()
	shell._clear_notice_presentations()
	director.cue("notice_test_receipt_voice")
	for entry: Dictionary in director.scheduled:entry.at=director.presentation_clock()
	director._process(0)
	check(not director.last_subtitle.get("repeatsFeedback",false) and shell.phone_story_caption.is_visible_in_tree() and shell.phone_story_caption.text==text,"an independently requested voice caption still renders")

func run() -> void:
	check(load("res://tests/native_test_isolation.gd").is_isolated_save(),"disposable test save profile")
	if failures:quit(1);return
	state=root.get_node("State");state.developer_mode=true
	state.d=state.initial();state.d.native.page="phone_home"
	shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames(5)
	shell.set_process(false);shell.world.set_process(false);shell.audio_director.set_process(false);shell.audio_director.reset()
	for extent:Vector2i in [Vector2i(430,860),Vector2i(390,844),Vector2i(1440,900)]:
		root.size=extent;shell.size=Vector2(extent);shell._layout();shell._clear_notice_presentations()
		var initial:Dictionary=state.d.duplicate(true)
		for index in 40:
			var text:="操作反馈 %02d"%index
			state.feedback.emit(text)
			check(shown(text),"each burst entry replaces visible toast synchronously at "+str(extent))
		check(state.d==initial,"notice replacement does not delete log, inventory or progress")
		check(shell.phone.get_global_rect().encloses(shell.toast.get_global_rect()),"latest toast fits the actual scaled phone")
		shell._advance_notices(1.5)
		state.feedback.emit("操作反馈 39")
		check(shown("操作反馈 39") and is_equal_approx(shell.toast_time,shell.notice_queue.current.duration) and is_zero_approx(shell.notice_queue.current.elapsed),"repeated action refreshes full visible lifetime")
		shell._advance_notices(1)
		shell._feedback("操作反馈 39","error",4.2)
		check(shown("操作反馈 39") and is_equal_approx(shell.toast_time,4.2) and shell.toast.get_node("NoticeSpeaker").text=="提示","authored duration and speaker replace same-text presentation immediately")
		shell._advance_notices(4.19);check(shown("操作反馈 39"),"latest notice survives until its new deadline")
		shell._advance_notices(.02)
		check(shell.notice_queue.current.is_empty() and not shell.toast.visible,"new deadline clears once without replaying predecessors")
		# Both ordinary phone surfaces follow one latest interaction order.
		shell._feedback("较长的普通系统提示","system",6.5)
		shell.phone_builder._toast(shell.page_body.get_child(0).get_child(0),"短提示")
		var local:Control=shell.page_body.find_child("SourceToast",true,false)
		local.set_process(false)
		check(local.is_visible_in_tree() and not shell.toast.visible and shell.notice_queue.current.is_empty(),"short local receipt synchronously retires longer Main notice")
		local._process(2.3);shell._advance_notices(2.3)
		check(not local.visible and not shell.toast.visible and shell.notice_queue.current.is_empty(),"short local expiry cannot replay the replaced long Main notice")
		await frames()
		shell.phone_builder._toast(shell.page_body.get_child(0).get_child(0),"重复的本地提示")
		local=shell.page_body.find_child("SourceToast",true,false);local.set_process(false);local._process(1)
		shell.phone_builder._toast(shell.page_body.get_child(0).get_child(0),"重复的本地提示")
		var renewed:Control=shell.page_body.find_child("SourceToast",true,false);renewed.set_process(false)
		check(renewed!=local and not local.is_inside_tree() and is_equal_approx(renewed.remaining,2.2),"same local text gets a new timer and retires the old node")
		local._process(20)
		check(renewed.is_visible_in_tree(),"old local deadline cannot dismiss its same-text replacement")
		shell._feedback("来自控制器的最新通知","system",3.5)
		check(shown("来自控制器的最新通知") and not renewed.visible,"new Main notice synchronously dismisses the older local receipt")
		renewed._process(20)
		check(shown("来自控制器的最新通知") and is_equal_approx(shell.toast_time,3.5),"retired local clock cannot dismiss or shorten newer Main notice")
		shell._advance_notices(4)
		check(shell.notice_queue.current.is_empty() and not shell.toast.visible,"cross-lane replacement leaves no backlog")
		await frames()
		# The controller keeps persistent history even when its visible receipt is replaced.
		var log_count:int=state.d.native.log.size()
		state.act("c1_network","移动数据");state.act("c1_brightness",65);state.act("c1_auto_rotate")
		check(state.d.networkMode=="cellular" and state.d.ui.brightness==65,"real controller actions still apply their state")
		check(state.d.native.log.size()==log_count+3 and state.d.native.log[-3].text=="网络已切换。" and state.d.native.log[-2].text=="屏幕亮度已调整。","all replaced controller receipts remain in persisted history")
		check(shown(str(state.last_result.message)),"last controller result replaces earlier results immediately")
		var committed:Dictionary=state.d.duplicate(true)
		# The actual scheduler retains both delayed critical dialogue cues through a burst.
		var director:Node=shell.audio_director
		director.reset()
		director.schedule_cue("native_story_subtitle",{"text":"系统：保留的第一句对白","tone":"system","durationMs":1200},100000)
		director.schedule_cue("native_story_subtitle",{"text":"玩家：保留的第二句对白","tone":"player","durationMs":1200},200000)
		var scheduled:Array=director.scheduled.duplicate(true)
		for index in 20:state.feedback.emit("替换普通提示 %02d"%index)
		check(director.scheduled==scheduled,"ordinary burst cannot remove, reorder or retime critical scheduled cues")
		director.scheduled[0].at=director.presentation_clock();director._process(0)
		check(shell.phone_story_caption.text=="系统：保留的第一句对白" and shell.phone_story_caption.is_visible_in_tree() and not shell.story_caption.visible and not shell.toast.visible,"first scheduled dialogue uses one phone caption")
		check(shell.phone_story_caption.has_node("NoticeAvatar") and shell.phone_story_caption.get_theme_stylebox("normal").bg_color==shell.toast.get_theme_stylebox("normal").bg_color,"timed phone dialogue shares the phone notice composition")
		state.feedback.emit("对白遮挡下的过期提示");shell._advance_notices(10)
		check(shell.notice_queue.current.is_empty() and not shell.toast.visible and director.scheduled.size()==1,"hidden ordinary feedback expires without consuming the second scheduled dialogue")
		director.scheduled[0].at=director.presentation_clock();director._process(0)
		check(shell.phone_story_caption.text=="玩家：保留的第二句对白" and shell.phone_story_caption.is_visible_in_tree(),"second scheduled dialogue still appears in authored order")
		shell._advance_notices(2)
		check(not shell.toast.visible and not shell.phone_story_caption.visible and shell.notice_queue.pending.is_empty() and director.scheduled.is_empty(),"story finish retires the caption and does not resurrect stale feedback")
		check(state.d==committed,"all clocks and presentation handoffs preserve committed inventory, history and story state")
		director.reset();await frames()
	await check_balance_cue()
	await check_spoken_feedback()
	await shell.shutdown();shell.queue_free();await frames()
	print("TRANSIENT_NOTICE_LATEST: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
