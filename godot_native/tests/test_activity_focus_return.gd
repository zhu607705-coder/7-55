extends "res://tests/test_chapter4_device_main.gd"
## Real activity buttons and root key routing. Source checkpoints/preview-only
## configs are explicit fixtures; they never stand in for earned story proof.
func visible_button(parent:Node,text:String)->Button:
	for button in parent.find_children("*","Button",true,false):
		if button.is_visible_in_tree() and not button.is_queued_for_deletion() and button.text==text:return button
	return null
func prepare_world(view:Vector2i)->void:
	await prepare(view,"c4-755-elevator-history")
	shell._show_world_mobile();await frames()
	var source:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/source/chapter4-three-floor-maze.layout.json"))
	var stand:Dictionary=source.floors[0].elevator.standPosition
	shell.world.player=Vector2(stand.x,stand.y);shell.world._sync_player();shell.world._process(0);shell.world.grab_focus();await frames()
func prologue_preview()->Control:
	# No completion callback: this exercises Main's activity lifetime without
	# fabricating a formal prologue receipt on the retained-world fixture.
	shell._open_game({"script":"res://scripts/games/chapter4_activity.gd","kind":"prologue","settings":{"reduced_motion":true}})
	await frames();shell.active_game.set_process(false)
	return shell.active_game
func check_returned(label:String)->void:
	check(shell.active_game==null and shell.world_frame.is_visible_in_tree(),label+" reveals the retained world")
	check(root.gui_get_focus_owner()==null and shell.world_viewport.gui_get_focus_owner()==shell.world,label+" restores the real world keyboard focus")
	# No map click, focus repair, or controller call between terminal and key.
	await press_key(KEY_SPACE);await frames()
	check(state_node.d.native.page=="c4_device" and is_instance_valid(visible_button(shell,"调节回放起点")),label+" first root Space opens the actual nearby elevator record")
func prologue_return(view:Vector2i,complete:bool)->void:
	await prepare_world(view)
	var before:Dictionary=state_node.d.chapter4.duplicate(true)
	var activity:Control=await prologue_preview()
	check(not shell.world_frame.is_visible_in_tree(),"Prologue owns the sole fitted presentation")
	if complete:
		await mouse_click(visible_button(activity,"跳过恢复回放"));await frames()
		await mouse_click(visible_button(activity,"收下任务，进入第四章"))
	else:await mouse_click(visible_button(activity,"返回"))
	await frames(4)
	check(state_node.d.chapter4==before,"Preview-only terminal cannot grant a formal prologue fact")
	await check_returned(("Prologue completion " if complete else "Prologue cancellation ")+str(view))
func stairs_return(view:Vector2i)->void:
	await prepare_world(view)
	var before:Dictionary=state_node.d.chapter4.duplicate(true)
	shell._open_game({"script":"res://scripts/games/chapter4_stairs.gd","kind":"chapter4_stair_campaign"});await frames()
	var activity:Control=shell.active_game
	await mouse_click(visible_button(activity,"返回"));await frames(4)
	check(state_node.d.chapter4==before,"Stair preview Return cannot grant a campaign proof")
	await check_returned("Stair controls Return "+str(view))
func defense_return(view:Vector2i)->void:
	await prepare(view,"c3-canteen-block")
	if not is_instance_valid(shell.active_game):
		# Compact entry starts from the retained phone; use its actual Return.
		await mouse_click(shell.phone_world_return);await frames(5)
	var activity:Control=shell.active_game
	check(is_instance_valid(activity) and activity.get_script().resource_path.ends_with("canteen_defense.gd"),"Original controller admits the full-scene canteen defense")
	if not is_instance_valid(activity):return
	activity.set_process(false)
	var before:Dictionary=state_node.d.canteenHunt.duplicate(true)
	await mouse_click(activity.exit_button);await frames(4)
	check(shell.active_game==null and shell.world_frame.is_visible_in_tree(),"Defense Exit returns to its retained world")
	check(root.gui_get_focus_owner()==null and shell.world_viewport.gui_get_focus_owner()==shell.world,"Defense Exit restores world key focus without clicking the map "+str(view))
	check(state_node.d.canteenHunt==before,"Defense Exit cannot grant a win or alter the source phase")
	var keys:Array=[]
	shell.world.gui_input.connect(func(event:InputEvent):
		if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_SPACE:keys.append(event.keycode)
	)
	await press_key(KEY_SPACE)
	check(keys==[KEY_SPACE],"First root Space after Defense Exit reaches the actual world input surface")
func guarded_destination(view:Vector2i,destination:String,complete:bool)->void:
	await prepare_world(view)
	var activity:Control=await prologue_preview()
	# Competing navigation is an explicit UI-owner fixture, invoked after Main
	# queues its deferred handoff but before it runs. Existing guards must win.
	var navigate:Callable=func(_result:Dictionary={}):
		if destination=="phone":shell._show_phone_surface()
		else:shell._show_settings()
	if complete:activity.completed.connect(navigate)
	else:activity.cancelled.connect(navigate)
	if complete:
		await mouse_click(visible_button(activity,"跳过恢复回放"));await frames()
		await mouse_click(visible_button(activity,"收下任务，进入第四章"))
	else:await mouse_click(visible_button(activity,"返回"))
	await frames(4)
	if destination=="phone":
		check(shell.phone.visible and not shell.world_frame.is_visible_in_tree(),"Deferred activity handoff respects a phone destination")
		check(root.gui_get_focus_owner()==shell.phone_world_return and shell.world_viewport.gui_get_focus_owner()!=shell.world,"Phone Return retains focus instead of a hidden world")
	else:
		var focused:Control=root.gui_get_focus_owner()
		check(is_instance_valid(shell.modal) and (focused==shell.modal or shell.modal.is_ancestor_of(focused)),"Deferred activity handoff preserves the new modal's keyboard owner")
		check(shell.world_viewport.gui_get_focus_owner()!=shell.world,"A new modal prevents deferred world focus theft")
func run()->void:
	state_node=root.get_node("State");state_node.developer_mode=true
	if not load("res://tests/native_test_isolation.gd").is_isolated_save():push_error("Activity test requires isolated save profile");quit(2);return
	for view:Vector2i in [Vector2i(1440,900),Vector2i(390,844)]:
		await prologue_return(view,false)
		await prologue_return(view,true)
		await stairs_return(view)
		await defense_return(view)
		for complete:bool in [false,true]:
			await guarded_destination(view,"phone",complete)
			await guarded_destination(view,"modal",complete)
	await shell.shutdown();shell.queue_free();await frames(4)
	print("ACTIVITY_FOCUS_RETURN: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
