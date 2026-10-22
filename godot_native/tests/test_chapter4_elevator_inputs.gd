extends "res://tests/test_chapter4_device_main.gd"
## Actual native source arrow/buttons and timed transport, from an explicit A1 fixture.
func live_button(parent: Node,text: String) -> Button:
	for child in parent.get_children():
		if child is Button and not child.is_queued_for_deletion() and child.text==text: return child
	return null
func visible_button(text: String) -> Button:
	for child in shell.find_children("*","Button",true,false):
		if child.is_visible_in_tree() and not child.is_queued_for_deletion() and child.text==text: return child
	return null
func wait_until(predicate: Callable, milliseconds: int=10000) -> bool:
	var deadline:=Time.get_ticks_msec()+milliseconds
	while not predicate.call() and Time.get_ticks_msec()<deadline: await process_frame
	return predicate.call()
func prepare_elevator(view: Vector2i) -> void:
	await prepare(view,"c4-755-elevator-history")
	# Authored stand position is fixture placement, not progression or a focus
	# repair after closing the activity. Every subsequent action uses root input.
	shell._show_world_mobile();await frames()
	var layout: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/source/chapter4-three-floor-maze.layout.json"))
	var stand: Dictionary=layout.floors[0].elevator.standPosition
	shell.world.player=Vector2(stand.x,stand.y);shell.world._sync_player();shell.world._process(0);shell.world.grab_focus();await frames()
func open_elevator_record(label: String) -> bool:
	await press_key(KEY_SPACE);await frames()
	var opened: bool=state_node.d.native.page=="c4_device" and not shell.world_frame.is_visible_in_tree() and is_instance_valid(visible_button(label))
	check(opened,"root Space opens elevator record with "+label+" without a map click")
	return opened
func start_alignment() -> Control:
	if not await open_elevator_record("调节回放起点"):return null
	await mouse_click(visible_button("调节回放起点"));await frames(3)
	var activity: Control=shell.active_game
	check(is_instance_valid(activity) and activity.kind=="elevator_alignment","real record button mounts controller-owned elevator activity")
	return activity
func check_world_focus(label: String) -> void:
	check(shell.world_frame.is_visible_in_tree() and not shell.world._shell_input_blocked(),label+" reveals the unblocked original world")
	check(root.gui_get_focus_owner()==null and shell.world_viewport.gui_get_focus_owner()==shell.world,label+" returns keyboard focus to the actual world viewport")
func cancelled_return(view: Vector2i) -> void:
	await prepare_elevator(view)
	var activity: Control=await start_alignment()
	if not is_instance_valid(activity):return
	var before: Dictionary=state_node.d.chapter4.duplicate(true)
	await mouse_click(live_button(activity.elevator_panel.controls,"返回"));await frames(4)
	check(shell.active_game==null and not is_instance_valid(activity),"actual Return disposes the cancelled alignment owner")
	check(state_node.d.chapter4==before,"cancelling alignment cannot calibrate or grant travel")
	check_world_focus("Cancellation "+str(view))
	# No world.grab_focus, mouse click, direct controller intent, or placement.
	if not await open_elevator_record("调节回放起点"):return
	await mouse_click(visible_button("调节回放起点"));await frames()
	check(is_instance_valid(shell.active_game),"first Space after cancellation permits a fresh real alignment entry")
	await press_key(KEY_ESCAPE);await frames()
func completed_return(view: Vector2i) -> void:
	await prepare_elevator(view)
	var activity: Control=await start_alignment()
	if not is_instance_valid(activity):return
	await mouse_click(live_button(activity.elevator_panel.controls,"重放并校验")); await frames(3)
	await mouse_click(live_button(activity.elevator_panel.controls,"走入电梯"))
	check(await wait_until(func(): return activity.stage=="select"),"wrong replay completes through real six-second clock")
	check(not state_node.d.chapter4.elevatorTrackAligned and state_node.d.chapter4.floor=="A1","wrong start/boarding cannot grant travel")
	check(activity.elevator_panel.readout.text.contains("校验结果"),"actual failed replay retains source feedback")
	await press_key(KEY_LEFT)
	for i in range(int(activity.config.timeline.correctReplayStartSeconds)-int(activity.config.timeline.selectableStartMinSeconds)): await press_key(KEY_RIGHT)
	check(activity.selection==int(activity.config.timeline.correctReplayStartSeconds),"actual source arrow keys select door start")
	await mouse_click(live_button(activity.elevator_panel.controls,"重放并校验")); await frames(3)
	# Correct time without boarding must also remain incomplete.
	check(await wait_until(func(): return activity.stage=="select"),"missed boarding stays retryable after real six-second clock")
	check(not state_node.d.chapter4.elevatorTrackAligned,"time alone cannot calibrate")
	await mouse_click(live_button(activity.elevator_panel.controls,"重放并校验")); await frames(3)
	await mouse_click(live_button(activity.elevator_panel.controls,"走入电梯"))
	check(await wait_until(func(): return shell.active_game==null),"correct time and real Board completes actual activity")
	await frames(4)
	check(state_node.d.chapter4.elevatorTrackAligned and state_node.d.chapter4.floor=="A1","calibration earns fact but does not teleport")
	check_world_focus("Calibration "+str(view))
	# This is the previously missing GUI handoff. Direct State.act(ride) would
	# conceal a lost SubViewport focus while movement polling still worked.
	if not await open_elevator_record("走入电梯"):return
	await mouse_click(visible_button("走入电梯")); await frames(2)
	check(is_instance_valid(shell.world_effect) and state_node.d.chapter4.floor=="A1","actual record Ride button starts transit and holds origin")
	check(await wait_until(func(): return state_node.d.chapter4.floor=="A3"),"actual3960ms world presentation arrives A3")
	check(state_node.d.native.c4_elevator_transport and state_node.d.native.c4_native_elevator_completed,"only completed native transit earns provenance")
	await frames(4);check_world_focus("Arrival "+str(view))
	var targets:Array=state_node.get_targets("duan_yongping_temporal_maze")
	check(targets.any(func(target):return target.action=="c4_device_media_alignment"),"earned A3 transit exposes the scanner target")
func run() -> void:
	state_node=root.get_node("State"); state_node.developer_mode=true
	create_timer(110).timeout.connect(func():push_error("Elevator input watchdog");quit(2))
	for view: Vector2i in [Vector2i(1440,900),Vector2i(390,844)]:
		await cancelled_return(view)
		await completed_return(view)
	await shell.shutdown(); shell.queue_free(); await frames(3)
	print("C4_ELEVATOR_INPUTS: ",checks," checks; ",failures," failures"); quit(1 if failures else 0)
