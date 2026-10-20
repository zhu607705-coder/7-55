extends "res://tests/test_c3_canteen_devices_controls.gd"
## Real device controls + State feedback, preserving the separate unread FIFO.
## Seeded isolated state is setup, not earned campaign/OS desktop acceptance.
func tick_reading(count:int) -> void:
	for i in count:shell.world._process(.05);shell._process(.05)
func wait_notice_release(text:String) -> void:
	for i in 200:
		if shell.notice_queue.current.get("text","")!=text:return
		tick_reading(1)
func run() -> void:
	check(load("res://tests/native_test_isolation.gd").is_isolated_save(),"local feedback uses an isolated profile")
	if errors:quit(1);return
	state=root.get_node("State")
	await setup_device("ordering_kiosk",Vector2i(390,844),"menu_order",true)
	shell.set_process(false);shell.world.set_process(false);shell.audio_director.set_process(false);shell.audio_director.reset()
	shell.c3_scene_host.set_process(false);shell.c3_narrative_host.set_process(false)
	shell._clear_notice_presentations();shell.world.subtitle="";shell.world.subtitle_left=0
	state.feedback.emit("操作前甲通知");state.feedback.emit("操作前乙通知");tick_reading(10)
	var unread:float=shell.notice_queue.current.remaining
	check(unread>0 and unread<2.4 and shell.world.subtitle=="操作前甲通知","ordinary notice is genuinely partly read before opening the device")
	# An external clear is not acknowledgement of reading this queue item.
	shell.world.subtitle="";shell.world.subtitle_left=0;shell._layout_toast()
	check(shell.world.subtitle=="操作前甲通知" and is_equal_approx(shell.notice_queue.current.remaining,unread),"external clear resumes the same unread notice rather than consuming it")
	await open_world("ordering_kiosk")
	var panel:Control=shell.c3_device_panel
	if not is_instance_valid(panel):await teardown();quit(1);return
	await click(panel.controls.D);shell._process(0)
	check(shell.world.subtitle.contains("只能查看") and panel.labels.title.visible,"actual dark Order rejection immediately replaces the device observation")
	check(shell.notice_surface.is_empty() and not shell.toast.visible and shell.toast.text.is_empty(),"device correction has no second generic notice surface")
	check(is_equal_approx(shell.notice_queue.current.remaining,unread) and shell.notice_queue.pending.size()==1,"local action preserves partly read current and earlier pending ordinary message")
	state.feedback.emit("操作期间丙通知");tick_reading(12)
	check(shell.world.subtitle.contains("只能查看") and is_equal_approx(shell.notice_queue.current.remaining,unread) and shell.notice_queue.pending.size()==2,"ambient arrival waits without replacing the correction or spending unread time")
	var facts:Dictionary=state.d.duplicate(true)
	await click(panel.controls.D);shell._process(0)
	check(state.d.canteenHunt.orderAttemptCount==facts.canteenHunt.orderAttemptCount and state.d.canteenHunt.orderedMenuOption==facts.canteenHunt.orderedMenuOption and state.d.items==facts.items and state.d.wallet==facts.wallet and shell.world.subtitle.contains("只能查看"),"repeated real rejected action stays readable without granting an order")
	await key(KEY_ESCAPE);shell._process(0)
	check(not is_instance_valid(shell.c3_device_panel) and shell.world.subtitle.contains("只能查看") and shell.notice_surface.is_empty(),"closing device preserves its remaining local result instead of replaying observation")
	for i in 200:
		if shell.notice_surface=="world":break
		tick_reading(1)
	check(shell.world.subtitle=="操作前甲通知" and is_equal_approx(shell.world.subtitle_left,unread),"ordinary FIFO resumes exactly its earlier unread lifetime after local expiry")
	wait_notice_release("操作前甲通知")
	check(shell.world.subtitle=="操作前乙通知" and is_equal_approx(shell.world.subtitle_left,2.4),"earlier pending message follows once at full duration")
	wait_notice_release("操作前乙通知")
	check(shell.world.subtitle=="操作期间丙通知" and is_equal_approx(shell.world.subtitle_left,clampf(1.6+"操作期间丙通知".length()*.12,2.4,6.5)),"device-time ambient arrival follows once in FIFO order")
	wait_notice_release("操作期间丙通知")
	check(shell.notice_queue.current.is_empty() and shell.notice_queue.pending.is_empty() and shell.world.subtitle.is_empty(),"local correction and observations never replay as ordinary queued notifications")
	# A real accepted order dismisses its panel and issues the original narrative.
	await open_world("ordering_kiosk");panel=shell.c3_device_panel
	await click(panel.controls.mode);await click(panel.controls.D)
	shell.c3_narrative_host.tick(0,true);shell._process(0)
	check(state.d.items.pickupTicket0755 and state.d.canteenHunt.orderAttemptCount==1 and not is_instance_valid(shell.c3_device_panel),"real accepted order preserves controller result and dismisses its local owner")
	check(shell.c3_narrative_host.current!=null,"accepted order issues its original narrative handoff")
	check(shell.c3_narrative_host.view.is_visible_in_tree() and shell.world.subtitle.is_empty(),"actual order dialogue retires its own old observation result before rendering")
	check(is_zero_approx(float(shell.world.hud_metrics(shell.world._hud_line()).body_height)),"visible order dialogue has no leftover local feedback HUD row")
	var owner:RefCounted=shell.c3_narrative_host.current
	state.feedback.emit("对白期间丁通知");shell._process(8)
	check(shell.c3_narrative_host.current==owner and not shell.toast.visible and shell.notice_surface.is_empty(),"handoff keeps the real narrative owner and holds ambient notification")
	check(shell.notice_queue.current.get("text","")=="对白期间丁通知" and is_equal_approx(shell.notice_queue.current.remaining,clampf(1.6+"对白期间丁通知".length()*.12,2.4,6.5)),"scene takeover does not charge or duplicate its waiting ordinary message")
	await teardown()
	# Independent ownership fixture: another source replaces the same wording.
	# A subsequent real order may retire only its own revision, never this one.
	await setup_device("ordering_kiosk",Vector2i(1280,720),"menu_order",true)
	shell.set_process(false);shell.world.set_process(false);shell.audio_director.set_process(false);shell.audio_director.reset()
	shell.c3_scene_host.set_process(false);shell.c3_narrative_host.set_process(false)
	await open_world("ordering_kiosk");panel=shell.c3_device_panel
	var foreign_text:String=shell.world.subtitle
	shell.world._receive_feedback(foreign_text)
	var foreign_revision:int=shell.world.subtitle_revision
	await click(panel.controls.mode);await click(panel.controls.D)
	shell.c3_narrative_host.tick(0,true);shell._process(0)
	check(state.d.items.pickupTicket0755 and shell.c3_narrative_host.current!=null,"foreign-owner fixture still follows the real accepted order handoff")
	check(not foreign_text.is_empty() and shell.world.subtitle==foreign_text and shell.world.subtitle_revision==foreign_revision,"takeover cannot clear an external same-text replacement with a different revision")
	await teardown()
	print("NATIVE_LOCAL_FEEDBACK_OWNERSHIP: ",checks," checks; ",errors," failures")
	quit(1 if errors else 0)
