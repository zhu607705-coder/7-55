extends "res://tests/test_chapter4_device_main.gd"
## A controller-backed fixture, not an earned gameplay route.
func wait_until(predicate:Callable,ms:int=10000)->bool:
	var deadline:=Time.get_ticks_msec()+ms
	while not predicate.call() and Time.get_ticks_msec()<deadline:await process_frame
	return predicate.call()
func run()->void:
	state_node=root.get_node("State");state_node.developer_mode=true
	create_timer(55).timeout.connect(func():push_error("Elevator visibility watchdog");quit(2))
	for dimensions in [Vector2i(390,844),Vector2i(1180,812)]:
		await prepare(dimensions,"c4-755-elevator-history")
		state_node.act("c4_elevator_align");await frames(3)
		var activity=shell.active_game
		for i in range(int(activity.config.timeline.correctReplayStartSeconds)-int(activity.config.timeline.selectableStartMinSeconds)):await press_key(KEY_RIGHT)
		await press_key(KEY_ENTER);await press_key(KEY_SPACE)
		check(await wait_until(func():return shell.active_game==null),"Actual timed fixture earns calibration")
		state_node.act("c4_elevator");await frames(3)
		check(not shell.world_frame.is_visible_in_tree(),"Fixture starts the travel request from phone")
		var facts_before=state_node.d.chapter4.factIds.duplicate()
		state_node.act("c4_elevator_ride");await frames(3)
		var owner=shell.world_effect
		check(is_instance_valid(owner) and owner.get_parent()==shell.world,"Existing sole effect remains attached to original World")
		check(shell.world_frame.is_visible_in_tree(),"Phone-initiated elevator is visible before transport advances")
		check(shell.world.size==Vector2(960,540),"Elevator retains the authored960x540 camera contract")
		check(state_node.d.chapter4.floor=="A1" and state_node.d.chapter4.factIds==facts_before,"Revealing world cannot grant destination or facts")
		var position=shell.world.player
		await press_key(KEY_D);check(shell.world.player==position,"Transport retains world movement ownership")
		shell._cancel_world_effect();await frames(3)
		check(not is_instance_valid(owner) and state_node.d.chapter4.floor=="A1","Cancel disposes old owner without granting arrival")
		state_node.act("c4_elevator");await frames(3);state_node.act("c4_elevator_ride");await frames(3)
		check(is_instance_valid(shell.world_effect) and shell.world_effect!=owner,"Retry creates one distinct source effect")
		check(await wait_until(func():return state_node.d.chapter4.floor=="A3"),"Original duration and controller proof complete actual fixture transport")
		await frames(4)
		check(shell.world_frame.is_visible_in_tree() and shell.mobile_world,"Arrival remains on the visible world")
		check(state_node.d.native.c4_elevator_transport and state_node.d.native.c4_native_elevator_completed,"Arrival provenance remains controller-owned")
		check(not is_instance_valid(shell.world_effect) and shell.active_game==null,"Arrival disposes presentation without a second owner")
		await frames(3);check(shell.world.has_focus(),"Arrival returns world focus")
		check(shell.world.mobile_exploration==(dimensions.x<600),"Arrival restores the normal responsive exploration contract")
	await shell.shutdown();shell.queue_free();await frames(3)
	print("C4_ELEVATOR_VISIBILITY ",checks," checks; ",failures," failures");quit(1 if failures else 0)
