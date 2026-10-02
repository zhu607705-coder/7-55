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
func run() -> void:
	state = root.get_node("State"); state.developer_mode = true; state.d = state.initial()
	shell = load("res://scenes/main.tscn").instantiate(); root.add_child(shell); await frames()
	shell.set_process(false)
	for viewport: Vector2i in [Vector2i(390,844), Vector2i(430,860), Vector2i(1440,900)]:
		await fixture(viewport, "inventory_required")
		await click(named(shell.page_body, "ZjudingApp_campus_map"))
		check(state.d.native.scene == "dorm_hub", "map enters source dorm scene")
		check(shell.world_frame.visible and shell.mobile_world, "map immediately reveals world without hidden footer")
		check(shell.phone.visible == (viewport.x >= 1100), "desktop split remains visible; compact enters world")
		var position_before: Vector2 = shell.world.player
		if viewport.x < 1100: await click(shell.mobile_back)
		else: state.open_page("phone_home"); await frames()
		check(shell.phone.visible and state.d.native.page == "phone_home", "return reaches visible home")
		check(shell.world.player == position_before, "phone return retains world position")
		# Reproduce an outer scroll offset while a scene's return affordance is
		# present. Refresh preserves it; an actual new destination resets it.
		shell.phone_scroll.scroll_vertical = 50; await frames()
		var scrolled: int = shell.phone_scroll.scroll_vertical
		check(scrolled > 0, "fixture really has outer phone overflow")
		state.changed.emit(); await frames()
		check(shell.phone_scroll.scroll_vertical == scrolled, "same-page refresh preserves outer scroll")
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
