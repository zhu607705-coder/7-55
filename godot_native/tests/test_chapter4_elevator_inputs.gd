extends "res://tests/test_chapter4_device_main.gd"
## Actual native slider/buttons and timed transport, from an explicit A1 fixture.
func live_button(parent: Node,text: String) -> Button:
	for child in parent.get_children():
		if child is Button and not child.is_queued_for_deletion() and child.text==text: return child
	return null
func wait_until(predicate: Callable, milliseconds: int=10000) -> bool:
	var deadline:=Time.get_ticks_msec()+milliseconds
	while not predicate.call() and Time.get_ticks_msec()<deadline: await process_frame
	return predicate.call()
func run() -> void:
	state_node=root.get_node("State"); state_node.developer_mode=true
	await prepare(Vector2i(1440,900),"c4-755-elevator-history")
	state_node.act("c4_elevator_align"); await frames(3)
	var activity=shell.active_game
	check(is_instance_valid(activity) and activity.kind=="elevator_alignment","actual controller mounts elevator activity")
	await mouse_click(live_button(activity.controls,"开始轨迹回放")); await frames(3)
	await mouse_click(live_button(activity.controls,"走入电梯"))
	check(await wait_until(func(): return activity.stage=="select"),"wrong replay completes through real six-second clock")
	check(not state_node.d.chapter4.elevatorTrackAligned and state_node.d.chapter4.floor=="A1","wrong start/boarding cannot grant travel")
	var slider: HSlider
	for child in activity.controls.get_children():
		if child is HSlider and not child.is_queued_for_deletion(): slider=child
	await mouse_click(slider); await press_key(KEY_HOME)
	for i in range(int(activity.config.timeline.correctReplayStartSeconds)-int(slider.min_value)): await press_key(KEY_RIGHT)
	check(activity.selection==int(activity.config.timeline.correctReplayStartSeconds),"actual slider Home/Right selects source start")
	await mouse_click(live_button(activity.controls,"开始轨迹回放")); await frames(3)
	# Correct time without boarding must also remain incomplete.
	check(await wait_until(func(): return activity.stage=="select"),"missed boarding stays retryable after real six-second clock")
	check(not state_node.d.chapter4.elevatorTrackAligned,"time alone cannot calibrate")
	await mouse_click(live_button(activity.controls,"开始轨迹回放")); await frames(3)
	await mouse_click(live_button(activity.controls,"走入电梯"))
	check(await wait_until(func(): return shell.active_game==null),"correct time and real Board completes actual activity")
	check(state_node.d.chapter4.elevatorTrackAligned and state_node.d.chapter4.floor=="A1","calibration earns fact but does not teleport")
	state_node.act("c4_elevator_ride"); await frames(2)
	check(is_instance_valid(shell.world_effect) and state_node.d.chapter4.floor=="A1","independent elevator transit holds origin")
	check(await wait_until(func(): return state_node.d.chapter4.floor=="A3"),"actual3960ms world presentation arrives A3")
	check(state_node.d.native.c4_elevator_transport and state_node.d.native.c4_native_elevator_completed,"only completed native transit earns provenance")
	state_node.act("c4_mode"); state_node.act("c4_reference"); await frames(2)
	check("a3_reference_observed" in state_node.d.chapter4.factIds,"earned transit opens genuine A3 reference")
	var targets: Array=state_node.get_targets("duan_yongping_temporal_maze")
	check(targets.any(func(t): return t.action=="c4_device_media_alignment"),"earned transit exposes scanner target")
	await shell.shutdown(); shell.queue_free(); await frames(3)
	print("C4_ELEVATOR_INPUTS: ",checks," checks; ",failures," failures"); quit(1 if failures else 0)
