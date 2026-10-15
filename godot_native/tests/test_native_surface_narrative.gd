extends "res://tests/test_portrait_exploration.gd"
## Real phone inventory drag must reveal its controller-issued world dialogue.
func run() -> void:
	state=root.get_node("State"); state.developer_mode=true; state.d=state.initial()
	shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames()
	for dimensions: Vector2i in [Vector2i(390,844),Vector2i(430,860),Vector2i(1440,900)]:
		state.d=state.initial();state.developer_mode=true
		state.d.native.chapter=3;state.d.native.scene="theater_interior";state.d.native.page="phone_home"
		state.d.runtimeMode="rpg";state.d.rpgScene="theater_interior";state.d.actOne.phase="complete"
		state.d.theaterHunt.active=true;state.d.theaterHunt.phase="entry_ticket";state.d.theaterHunt.posterCleaned=true;state.d.theaterHunt.ticketCodeRead=true
		state.d.items.theaterTicketHalfA=true;state.d.items.theaterTicketHalfB=true
		state.story_reset.emit();root.size=dimensions;shell.size=Vector2(dimensions);shell.mobile_world=false;shell._refresh();await frames()
		shell.world.set_process(false);shell.c3_narrative_host.set_process(false)
		var actor: Vector2=shell.world.player
		check(shell.phone.visible and shell.world_page_origin_scene.is_empty(),"voluntary phone mode has no device origin marker")
		var chrome: Control=shell.phone_chrome
		if not chrome.inventory_open:await click(chrome.inventory_handle)
		var first: Control=chrome.inventory_slots.get_node("Item_theaterTicketHalfA")
		var second: Control=chrome.inventory_slots.get_node("Item_theaterTicketHalfB")
		var start: Vector2=first.get_global_rect().get_center()
		var end: Vector2=second.get_global_rect().get_center()
		motion(start);mouse(start,true);motion(start+Vector2(24,0),Vector2(24,0),MOUSE_BUTTON_MASK_LEFT);await frames(2)
		check(root.gui_is_dragging(),"real phone inventory drag begins")
		motion(end,end-start,MOUSE_BUTTON_MASK_LEFT);await frames(1);mouse(end,false);await frames()
		check(state.d.items.temporaryTheaterTicket and not state.d.items.theaterTicketHalfA and not state.d.items.theaterTicketHalfB,"controller combines each half exactly once")
		var issued=state.get_c3_narrative_session()
		check(issued!=null and issued.sequence_id=="theater_combined","combination issues the authored world dialogue")
		check(shell.world_frame.visible and not shell.phone.visible,"issued world dialogue takes its single visible world surface")
		check(shell.world.player==actor and state.d.native.scene=="theater_interior","handoff retains the current theater and actor")
		shell.c3_narrative_host.tick(0,true)
		check(shell.c3_narrative_host.current==issued,"one existing narrative host attaches the same issued session")
		for i in range(300):
			if shell.c3_narrative_host.current==null:break
			shell.c3_narrative_host.tick(100,true)
		check(shell.c3_narrative_host.current==null and not state.story_input_locked(),"authored dialogue completes and releases input")
		shell._show_phone_surface();await frames()
		check(shell.phone.visible and not shell.world_frame.visible,"phone can reopen after the world dialogue")
		shell._on_controller_page_intent("phone_refresh",state.d,state.d,{"handled":true,"narrative_owned":true})
		check(shell.phone.visible and not shell.world_frame.visible,"a bare result flag cannot invent a narrative owner")
	# A fresh compact save can contain a pending world-only entrance dialogue
	# before an action_completed event. It must not disable the only Return.
	state.modules[1]=load("res://scripts/chapters/chapter3.gd").new()
	state.d=state.initial();state.developer_mode=true
	state.d.native.chapter=3;state.d.native.scene="theater_interior";state.d.native.page="phone_home"
	state.d.runtimeMode="rpg";state.d.rpgScene="theater_interior"
	state.d.theaterHunt.active=true;state.d.theaterHunt.phase="entry_ticket"
	root.size=Vector2i(390,844);shell.size=Vector2(390,844);shell.mobile_world=false
	state.story_reset.emit();shell._refresh();await frames()
	shell.world.set_process(false);shell.c3_narrative_host.set_process(false)
	check(state.story_input_locked() and state.get_c3_narrative_session()!=null,"source theater entry issues a pending world dialogue")
	check(shell.phone.visible and not shell.phone_world_return.disabled,"pending world dialogue cannot disable its only Return")
	await click(shell.phone_world_return)
	check(shell.world_frame.visible and not shell.phone.visible,"ordinary Return reveals the pending world dialogue")
	shell.c3_narrative_host.tick(0,true)
	check(shell.c3_narrative_host.current!=null and shell.c3_narrative_host.current.sequence_id=="theater_entry","the original theater entrance owner is retained")
	for i in range(600):
		if shell.c3_narrative_host.current==null:break
		shell.c3_narrative_host.tick(100,true)
	check(not state.story_input_locked(),"pending world dialogue finishes and releases input after Return")
	await shell.shutdown();shell.queue_free();await frames()
	print("NATIVE_SURFACE_NARRATIVE: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
