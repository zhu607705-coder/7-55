extends "res://tests/test_chapter4_device_main.gd"
const Proof=preload("res://tests/test_chapter4_post_stair_return.gd")
func prepare_floor(view: Vector2i) -> void:
	if is_instance_valid(shell):await shell.shutdown();shell.queue_free();await frames(3)
	state_node.story_reset.emit();state_node.d=state_node.initial()
	var fixture: Dictionary=Proof.fixture_state();state_node.d.chapter4=fixture.chapter4
	state_node.d.native.merge(fixture.native,true);state_node.d.runtimeMode="rpg";state_node.d.rpgScene="duan_yongping_temporal_maze"
	state_node.d.native.player={"x":772.5,"y":204,"scene":"duan_yongping_temporal_maze"}
	root.size=view;shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);root.size=view;shell._refresh();shell._show_world_mobile();await frames(5)
func owner() -> RefCounted:
	for m in state_node.modules:
		if m.has_method("_post_stair_floor_allowed"):return m
	return null
func run() -> void:
	state_node=root.get_node("State");state_node.developer_mode=true
	create_timer(45).timeout.connect(func():push_error("Floor-panel watchdog");quit(2))
	for view: Vector2i in [Vector2i(390,844),Vector2i(430,860),Vector2i(1180,812)]:
		await prepare_floor(view)
		check(not shell._open_chapter4_floor_selection({"session":"forged","fromFloor":"A1","phase":"room204_restore","destinations":["A2"]}),"Unissued panel rejected")
		var before: Dictionary=state_node.d.chapter4.duplicate(true)
		state_node.act("c4_elevator");await frames(4)
		var panel=shell.modal;check(is_instance_valid(panel) and panel.has_method("valid_context"),"Real controller request mounts one native floor panel")
		if not is_instance_valid(panel):continue
		check(shell.world_frame.visible and shell.active_game==null and not is_instance_valid(shell.world_effect),"Selection retains world with no travel owner")
		check(Rect2(Vector2.ZERO,Vector2(view)).encloses(panel.frame.get_global_rect()),"Floor panel fits "+str(view))
		check(panel.buttons.A1.disabled and not panel.buttons.A2.disabled and not panel.buttons.A3.disabled,"Current floor disabled, two original destinations available")
		for id in panel.buttons:
			check(panel.frame.get_global_rect().encloses(screen_rect(panel.buttons[id])) and panel.buttons[id].size.y>=44,"Readable precise floor target "+id+" "+str(view))
		var token: String=panel.config.session
		await press_key(KEY_SPACE);check(panel.records.visible,"Space reviews already-earned source records")
		await press_key(KEY_DOWN);check(panel.selected=="A3" and state_node.d.chapter4==before,"Arrow selection cannot mutate story")
		await press_key(KEY_ESCAPE);check(shell.modal==null and owner().pending.is_empty() and state_node.d.chapter4==before,"Escape retires selection without travel")
		state_node.act("c4_floor_select",{"session":token,"destination":"A2"});await frames(2);check(not is_instance_valid(shell.world_effect) and state_node.d.chapter4==before,"Stale closed selection cannot start a ride")
		state_node.act("c4_elevator");await frames(3);panel=shell.modal
		await mouse_click(panel.buttons.A2);await mouse_click(panel.primary);await frames(3)
		check(shell.modal==null and is_instance_valid(shell.world_effect) and state_node.d.chapter4.floor=="A1","Actual pointer starts one timed ride, not early arrival")
		if is_instance_valid(shell.world_effect):
			check(shell.world_effect.config.destination=="A2" and shell.world_effect.get_parent()==shell.world,"Original World owns selected travel presentation")
			shell._cancel_world_effect();await frames(2);check(state_node.d.chapter4==before,"Cancel retains floor and original facts")
	# The original ordinary stair destination must be legal under the same
	# native full-foot geometry; this is a synthetic lifecycle fixture.
	await prepare_floor(Vector2i(1180,812));state_node.d.chapter4.floor="A3";shell.world.world_key="";shell.world.refresh_world();await frames(3)
	state_node.act("c4_stairs");await frames(5)
	check(state_node.d.chapter4.floor=="A2" and shell.active_game==null,"Solved stair return does not instantiate another campaign")
	check(shell.world.player.is_equal_approx(Vector2(1036,214)),"Ordinary stair uses exact original A2 landing")
	check(shell.world.can_stand(shell.world.player),"Original stair arrival supports the full native player foot")
	# Context changes retire the selection; old owner cannot reopen it.
	await prepare_floor(Vector2i(430,860));state_node.act("c4_elevator");await frames(3)
	state_node.d.chapter4.phase="maintenance_repair";await frames(3)
	check(shell.modal==null and owner().pending.is_empty(),"Phase change disposes selection and its pending token")
	await shell.shutdown();shell.queue_free();await frames(3)
	print("C4_FLOOR_PANEL ",checks," checks; ",failures," failures");quit(1 if failures else 0)
