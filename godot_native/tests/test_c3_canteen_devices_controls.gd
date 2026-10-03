extends "res://tests/test_c3_devices_controls.gd"
## Seeded Chapter 3 device acceptance through viewport controls, not earned
## continuous story traversal. Source stand points supply test setup only.
func key(code: Key) -> void:
	# Deliver OS-style input across rendered frames, including the opening
	# key release and subsequent explicit confirmation.
	var event:=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=true
	Input.parse_input_event(event);await frames(2)
	var released:=InputEventKey.new();released.keycode=code;released.physical_keycode=code;released.pressed=false
	Input.parse_input_event(released);await frames(3)
func setup_device(target: String,dim: Vector2i,phase: String="tray_search",dark: bool=false) -> void:
	root.size=dim;state.d=state.initial();state.developer_mode=true
	state.modules[1]=Chapter.new()
	var scene: String="campus_bootstrap" if target=="bike" else "canteen_interior"
	state.d.native.chapter=3;state.d.native.scene=scene;state.d.native.page="c3_canteen";state.d.native.mode="dark" if dark else "light"
	state.d.rpgScene=scene;state.d.runtimeMode="rpg";state.d.canteenHunt.active=true;state.d.canteenHunt.phase=phase;state.d.canteenHunt.mode=state.d.native.mode;state.d.canteenHunt.entryPaperEscaped=true
	var entry: Dictionary=controller.get_definition(scene,target,state.d)
	var point: Dictionary=entry.get("stand",{"x":entry.x,"y":entry.y})
	state.d.native.player={"x":point.x,"y":point.y,"scene":scene}
	shell=load("res://scripts/main.gd").new();shell.size=Vector2(dim);root.add_child(shell);await frames(6)
	if dim.x<1100: shell._show_world_mobile()
	shell.world.player=Vector2(point.x,point.y);shell.world._sync_player();shell.world._update_camera();shell.world._process(0);shell.world.grab_focus();await frames()
func touch(node: Control) -> void:
	var point: Vector2=node.get_global_transform_with_canvas()*(node.size/2)
	# OS-style touch is delivered through Input, including Godot's configured
	# touch-to-mouse bridge, rather than calling a button signal directly.
	for down in [true,false]:
		var event:=InputEventScreenTouch.new();event.position=point;event.index=0;event.pressed=down
		Input.parse_input_event(event);await frames(2)
	await frames()
func enabled_buttons(panel: Control) -> Array:
	var result: Array=[]
	for button in panel.controls.values():
		if button.visible and not button.disabled: result.append(button)
	return result
func check_focus(panel: Control) -> void:
	for i in range(enabled_buttons(panel).size()+1):
		await key(KEY_TAB)
		var owner: Control=root.gui_get_focus_owner()
		check(owner!=null and panel.is_ancestor_of(owner),"Tab remains inside device controls")
func check_readability(panel: Control) -> void:
	super.check_readability(panel)
	if not panel.compact_layout: return
	for label in panel.labels.values():
		if not label.visible or label.text.is_empty(): continue
		check(label.get_line_count()<=label.get_visible_line_count(),"compact label fits all authored lines: "+label.name+" "+label.text)
	for button in enabled_buttons(panel):
		var fg: float=button.get_theme_color("font_hover_color").get_luminance()
		var bg: float=button.get_theme_stylebox("hover").bg_color.get_luminance()
		check(absf(fg-bg)>.4,"hover text retains readable contrast")
func close_check(original: Vector2) -> void:
	check(not is_instance_valid(shell.c3_device_panel),"device dismissed")
	check(shell.world.player.distance_to(original)<.1,"dismissal never moves or acts through to world")
	check(shell.world.get_viewport().gui_get_focus_owner()==shell.world,"dismissal returns world keyboard focus")
func run() -> void:
	check(ProjectSettings.globalize_path("user://").begins_with("/tmp/"),"isolated test profile")
	if errors: quit(1);return
	state=root.get_node("State")
	var machines: Array=controller.world("canteen_interior").constants.CANTEEN_DRINK_MACHINES
	for dim in [Vector2i(1280,720),Vector2i(960,540),Vector2i(390,844),Vector2i(430,860),Vector2i(844,390)]:
		print("C3 controls viewport ",dim)
		for machine in machines:
			var target: String=machine.id;var item: String=machine.value
			await setup_device(target,dim)
			var point: Vector2=shell.world.player
			await open_world(target)
			if not is_instance_valid(shell.c3_device_panel):await teardown();continue
			check(not state.d.items[item],"opening machine does not grant "+item)
			await key(KEY_D);await key(KEY_ENTER);close_check(point)
			check(not state.d.items[item],"keyboard Cancel grants nothing")
			await open_world(target);await touch(shell.c3_device_panel.controls.cancel);close_check(point)
			check(not state.d.items[item],"touch Cancel grants nothing")
			await open_world(target);await key(KEY_ESCAPE);close_check(point)
			check(not state.d.items[item],"Escape grants nothing")
			await open_world(target);await key(KEY_A);await key(KEY_SPACE);close_check(point)
			check(state.d.items[item],"keyboard Take grants exactly named drink")
			var inventory: Dictionary=state.d.items.duplicate(true)
			await open_world(target);await click(shell.c3_device_panel.controls.take)
			check(state.d.items==inventory,"owned drink repeat does not duplicate inventory")
			check(shell.world.subtitle.contains("已经"),"owned drink explains existing bottle")
			await teardown()
		await setup_device("ordering_kiosk",dim,"menu_order",true)
		await open_world("ordering_kiosk")
		if not is_instance_valid(shell.c3_device_panel):await teardown();continue
		check(state.d.canteenHunt.menuDarkClueRead,"opening dark menu records source clue")
		for option in shell.c3_device_panel.content.menu.options:
			check(shell.c3_device_panel.controls[str(option.id)].text==str(option.id)+"  "+str(option.dark),"dark menu preserves source label "+str(option.id))
		await touch(shell.c3_device_panel.controls.D)
		check(not state.d.items.pickupTicket0755 and state.d.canteenHunt.orderAttemptCount==0,"dark touch cannot order")
		check(shell.world.subtitle.contains("只能查看"),"dark refusal visible through one subtitle owner")
		check_readability(shell.c3_device_panel)
		await click(shell.c3_device_panel.controls.mode)
		for option in shell.c3_device_panel.content.menu.options: check(shell.c3_device_panel.controls[str(option.id)].text==str(option.id)+"  "+str(option.light),"mode changes labels without replacing authority")
		await check_focus(shell.c3_device_panel)
		await touch(shell.c3_device_panel.controls.A)
		check(state.d.canteenHunt.orderedMenuOption=="A" and state.d.items.pickupTicket0755,"source decoy order remains playable")
		check(not is_instance_valid(shell.c3_device_panel),"order dismisses device for authored dialogue")
		await teardown()
		await setup_device("ordering_kiosk",dim,"pickup_search",true)
		state.d.items.pickupTicket0755=true;state.d.canteenHunt.orderedMenuOption="A"
		await open_world("ordering_kiosk");await click(shell.c3_device_panel.controls.mode);await click(shell.c3_device_panel.controls.D)
		check(state.d.canteenHunt.orderedMenuOption=="A" and state.d.canteenHunt.orderAttemptCount==0,"pending meal blocks repeat order")
		check(shell.world.subtitle.contains("先取完"),"pending meal refusal retains source wording")
		check_readability(shell.c3_device_panel);await key(KEY_ESCAPE);await teardown()
		await setup_device("bike",dim,"chase_ready")
		state.d.items.greaseTissue=true;state.d.items.cafeteriaWages=true;state.d.wallet.cashCents=200
		await open_world("bike")
		if not is_instance_valid(shell.c3_device_panel):await teardown();continue
		check(shell.world.subtitle.contains("反光过强"),"first lock inspection shows source glare failure")
		await click(shell.c3_device_panel.controls.pay)
		check(not state.d.canteenHunt.bikePaid and state.d.wallet.cashCents==200,"unclean lock cannot pay")
		await click(shell.c3_device_panel.controls.mode);await touch(shell.c3_device_panel.controls.inspect)
		check(state.d.canteenHunt.bikeCodeRead,"dark inspection records optional code evidence")
		await touch(shell.c3_device_panel.controls.inspect)
		check(shell.world.subtitle.contains("不具备支付资格"),"repeat dark inspect uses source refusal")
		await touch(shell.c3_device_panel.controls.clean);await touch(shell.c3_device_panel.controls.pay)
		check(not state.d.canteenHunt.bikeLockCleaned and not state.d.canteenHunt.bikePaid,"dark mode cannot clean or pay")
		check_readability(shell.c3_device_panel)
		await touch(shell.c3_device_panel.controls.mode);await touch(shell.c3_device_panel.controls.clean)
		check(state.d.canteenHunt.bikeLockCleaned and state.d.items.greaseTissue,"light clean removes glare and retains owned tissue")
		await key(KEY_ESCAPE)
		await open_world("bike");check(state.d.canteenHunt.bikeLockCleaned,"close/reopen retains cleaned authority")
		await touch(shell.c3_device_panel.controls.pay)
		check(state.d.canteenHunt.bikePaid and state.d.wallet.cashCents==0 and not state.d.items.cafeteriaWages,"payment consumes wages exactly once")
		check(shell.c3_device_panel.controls.ride.visible and not shell.c3_device_panel.controls.pay.visible,"paid device offers actual chase")
		await key(KEY_ESCAPE);await open_world("bike")
		check(state.d.wallet.cashCents==0,"paid reopen cannot charge again")
		await check_focus(shell.c3_device_panel);check_readability(shell.c3_device_panel)
		await touch(shell.c3_device_panel.controls.ride);await frames(6)
		check(state.d.canteenHunt.phase=="chase_ready" and shell.active_game.stage=="start","Ride opens original departure before committing chase")
		await touch(shell.active_game.skip_button);await frames(6)
		check(state.d.canteenHunt.phase=="chasing" and is_instance_valid(shell.active_game),"Ride enters existing chase")
		await teardown()
	# Direct dispatch still validates distance and phase; UI does not confer authority.
	var s: Dictionary=state.initial();s.native.chapter=3;s.native.scene="canteen_interior";s.native.player={"x":0,"y":0};s.canteenHunt.active=true;s.canteenHunt.phase="tray_search";s.canteenHunt.entryPaperEscaped=true
	controller.dispatch(s,"c3_drink_take:"+str(machines[0].id))
	check(not s.items[str(machines[0].value)],"distant crafted Take rejected")
	print("C3 canteen routed controls: ",checks," checks, ",errors," failures")
	quit(1 if errors else 0)
