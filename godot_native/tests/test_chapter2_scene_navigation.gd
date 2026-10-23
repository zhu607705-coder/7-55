extends SceneTree
## Source-phase fixtures test actual app controls and shell navigation, not a
## manual campaign. The separate earned CUA run found both regressions.
var state: Node
var shell: Control
var checks := 0
var failures := 0
func _initialize() -> void: run.call_deferred()
func frames(count: int = 4) -> void:
	for i in range(count): await process_frame
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error("C2 NAVIGATION: " + message)
func named(node: Node, value: String) -> Node:
	if node.name == value: return node
	for child in node.get_children():
		var found := named(child, value)
		if found != null: return found
	return null
func click(control: Control) -> void:
	check(control != null and control.is_visible_in_tree(), "actual visible control exists")
	if control == null: return
	var point := control.get_global_transform_with_canvas() * (control.size / 2)
	var motion := InputEventMouseMotion.new(); motion.position = point; motion.global_position = point
	Input.parse_input_event(motion); await frames(1)
	for down: bool in [true, false]:
		var event := InputEventMouseButton.new(); event.position = point; event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT; event.pressed = down
		Input.parse_input_event(event); await frames(1)
	await frames()
func fixture(viewport: Vector2i, phase: String) -> void:
	state.d = state.initial(); state.developer_mode = true
	state.d.native.chapter = 2; state.d.native.page = "zjuding"
	state.d.actOne.phase = phase; state.d.actOne.dormHubUnlocked = true
	state.d.networkMode = "campus_wifi"
	root.size = viewport; shell.size = Vector2(viewport); shell.mobile_world = false
	shell._refresh(); await frames(); shell._process(1.5); await frames()
func reload_surface(viewport: Vector2i, phone_expected: bool) -> void:
	var prior_progress: Dictionary={"actOne":state.d.actOne.duplicate(true),"items":state.d.items.duplicate(true),"wallet":state.d.wallet.duplicate(true),"checkpoint":state.d.rpgCheckpoint,"scene":state.d.native.scene}
	var prior_position: Vector2=shell.world.player
	# Source-phase fixtures remain explicit test setup. Only persistence uses the
	# ordinary writer in the isolated profile, with a separately mounted Main.
	state.developer_mode=false
	check(state.save_game(),"ordinary surface save succeeds at "+str(viewport))
	await shell.shutdown(); shell.queue_free(); await frames()
	check(state.load_game(),"ordinary surface save reloads at "+str(viewport))
	shell=load("res://scenes/main.tscn").instantiate(); root.add_child(shell); await frames(10)
	shell.set_process(false)
	check(shell.phone.visible==phone_expected and shell.world_frame.visible!=phone_expected,"new Main restores the saved surface at "+str(viewport))
	check(state.d.runtimeMode==("phone" if phone_expected else "rpg"),"new Main retains the explicit runtime mode at "+str(viewport))
	check(state.d.actOne==prior_progress.actOne and state.d.items==prior_progress.items and state.d.wallet==prior_progress.wallet and state.d.rpgCheckpoint==prior_progress.checkpoint and state.d.native.scene==prior_progress.scene,"surface persistence preserves progression, inventory and checkpoint at "+str(viewport))
	check(shell.world.player.distance_to(prior_position)<0.001,"surface persistence preserves the world position at "+str(viewport))
func run() -> void:
	if not load("res://tests/native_test_isolation.gd").is_isolated_save():
		push_error("Chapter2 navigation persistence requires an isolated native test profile"); quit(2); return
	state = root.get_node("State"); state.developer_mode = true; state.d = state.initial()
	shell = load("res://scenes/main.tscn").instantiate(); root.add_child(shell); await frames()
	shell.set_process(false)
	for viewport: Vector2i in [Vector2i(390,844), Vector2i(430,860), Vector2i(1440,900)]:
		await fixture(viewport, "inventory_required")
		await click(named(shell.page_body, "ZjudingApp_campus_map"))
		check(state.d.native.scene == "dorm_hub", "map enters source dorm scene")
		check(shell.world_frame.visible and shell.mobile_world, "map immediately reveals world without hidden footer")
		check(not shell.phone.visible, "scene entry displays only the world")
		var position_before: Vector2 = shell.world.player
		await click(shell.mobile_back)
		check(shell.phone.visible and state.d.native.page == "phone_home", "return reaches visible home")
		check(state.d.runtimeMode=="phone","explicit phone return persists phone mode")
		check(shell.world.player == position_before, "phone return retains world position")
		await reload_surface(viewport,true)
		await click(shell.phone_world_return)
		check(state.d.runtimeMode=="rpg" and shell.world_frame.visible,"explicit world return restores world mode")
		await reload_surface(viewport,false)
		await click(shell.mobile_back)
		check(shell.phone.visible and state.d.runtimeMode=="phone","phone return remains available after reloading the world")
		# Home now fits without the removed return footer. Explicitly provide
		# tall inner content to exercise the shell's overflow ownership contract.
		# Keep it on the body container so same-page rebuilds retain the fixture.
		var natural_minimum: Vector2 = shell.page_body.custom_minimum_size
		shell.page_body.custom_minimum_size.y = shell.phone_scroll.size.y + 120
		await frames()
		shell.phone_scroll.scroll_vertical = 50; await frames()
		var scrolled: int = shell.phone_scroll.scroll_vertical
		check(scrolled > 0, "fixture really has outer phone overflow")
		state.changed.emit(); await frames()
		check(shell.phone_scroll.scroll_vertical == scrolled, "same-page refresh preserves outer scroll")
		shell.page_body.custom_minimum_size = natural_minimum
		state.open_page("wechat"); await frames(10)
		check(shell.phone_scroll.scroll_vertical == 0, "new app resets previous outer scroll")
		state.open_page("phone_home"); await frames(10)
		check(shell.phone_scroll.scroll_vertical == 0, "home returns with its complete header visible")
		await fixture(viewport, "complete")
		await click(named(shell.page_body, "ZjudingApp_campus_map"))
		check(state.d.native.scene == "campus_bootstrap" and shell.world_frame.visible, "completed C2 map reveals campus")
	await shell.shutdown(); shell.queue_free(); await frames()
	print("Chapter2 scene navigation: ", checks, " checks, ", failures, " failures")
	quit(1 if failures else 0)
