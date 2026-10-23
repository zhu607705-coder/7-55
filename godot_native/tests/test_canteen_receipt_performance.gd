extends "res://tests/test_c3_canteen_devices_controls.gd"
## Declared local prerequisites, actual menu input and the original order action.
## The receipt is presentation only; this is not an earned campaign walkthrough.
const Receipt = preload("res://scripts/objects/canteen_receipt_performance.gd")
var capture_dir := OS.get_environment("CANTEEN_RECEIPT_CAPTURE")

func capture(label: String) -> void:
	if capture_dir.is_empty() or DisplayServer.get_name() == "headless": return
	await process_frame
	await RenderingServer.frame_post_draw
	var suffix := "%dx%d_%s" % [root.size.x, root.size.y, label]
	root.get_texture().get_image().save_png(capture_dir.path_join(suffix + ".png"))
	var image: Image = shell.world.get_viewport().get_texture().get_image()
	var scene: Node2D = shell.world.native_canteen
	var point: Vector2 = scene.source_space.get_global_transform_with_canvas() * Receipt.TERMINAL_POINT
	var crop := Rect2i(Vector2i(point) - Vector2i(64, 70), Vector2i(128, 140)).intersection(Rect2i(Vector2i.ZERO, image.get_size()))
	if crop.has_area(): image.get_region(crop).save_png(capture_dir.path_join(suffix + "_source_crop.png"))
	# Diagnostic magnification of the same world, separate from the actual-size
	# screenshots above. No source geometry, art scale or collision is changed.
	var world: Control = shell.world
	var processing: bool = world.is_processing()
	world.set_process(false)
	var old_camera: Vector2 = world.camera; var old_zoom: float = world.zoom
	world.camera = Vector2(790, 246); world.zoom = 6.0; world.queue_redraw()
	await process_frame; await RenderingServer.frame_post_draw
	world.get_viewport().get_texture().get_image().save_png(capture_dir.path_join(suffix + "_diagnostic_zoom6.png"))
	world.camera = old_camera; world.zoom = old_zoom; world.queue_redraw()
	world.set_process(processing)

func _test_acceptance() -> void:
	for option: String in ["A", "B", "C", "D", "E"]:
		var before: Dictionary = state.initial()
		before.native.scene = "canteen_interior"; before.native.mode = "light"
		before.canteenHunt.active = true; before.canteenHunt.phase = "menu_order"
		var next: Dictionary = before.duplicate(true)
		next.canteenHunt.phase = "pickup_search"; next.canteenHunt.orderAttemptCount += 1
		next.canteenHunt.orderedMenuOption = option; next.items.pickupTicket0755 = true
		var saved_before: Dictionary = before.duplicate(true)
		var saved_next: Dictionary = next.duplicate(true)
		check(Receipt.accepted_order("c3_order", option, before, next, {"handled":true}), "each actual menu option can print its already granted ticket")
		check(not Receipt.accepted_order("c3_order", option, next, next, {"handled":true}), "repeat owned ticket cannot print twice")
		check(not Receipt.accepted_order("c3_order", option, before, before, {"handled":true}), "locked handled result does not print")
		check(not Receipt.accepted_order("c3_target:ordering_kiosk", option, before, next, {"handled":true}), "opening terminal never prints")
		check(not Receipt.accepted_order("c3_order", option, before, next, {"handled":false}), "unhandled action never prints")
		var invalid: Dictionary = next.duplicate(true); invalid.items.pickupTicket0755 = false
		check(not Receipt.accepted_order("c3_order", option, before, invalid, {"handled":true}), "count alone never supplies missing ticket")
		invalid = next.duplicate(true); invalid.native.mode = "dark"
		check(not Receipt.accepted_order("c3_order", option, before, invalid, {"handled":true}), "observation mode cannot print")
		invalid = next.duplicate(true); invalid.native.scene = "theater_interior"
		check(not Receipt.accepted_order("c3_order", option, before, invalid, {"handled":true}), "another scene cannot print")
		check(before == saved_before and next == saved_next, "observer never changes either transaction snapshot")

func run() -> void:
	check(load("res://tests/native_test_isolation.gd").is_isolated_save(), "isolated test profile")
	if errors: quit(1); return
	state = root.get_node("State")
	var palette: Array = JSON.parse_string(FileAccess.get_file_as_string("res://docs/art/art_direction_v1.json")).palette.colors
	for color: Color in [Receipt.INK, Receipt.PAPER, Receipt.PAPER_SHADE, Receipt.METAL_SHADE, Receipt.METAL_MID, Receipt.METAL_LIGHT]:
		check(palette.has(color.to_html(false).to_upper()), "new paper/metal pixel colors belong to the locked project palette")
	_test_acceptance()
	for dim in [Vector2i(1280, 720), Vector2i(390, 844), Vector2i(844, 390)]:
		await setup_device("ordering_kiosk", dim, "menu_order")
		# Unlike a dark observation fixture, ordinary light-mode access needs
		# the already-completed queue shift that causally owns menu_order.
		state.d.canteenHunt.promoDrinkPlaced = true
		state.d.canteenHunt.queueGapOpened = true
		shell.world.refresh_world(); await frames()
		var scene: Node2D = shell.world.native_canteen
		var printer: Node2D = scene.receipt_performance
		printer.set_process(false)
		check(printer.get_child_count() == 2 and printer.paper.get_parent() == scene.source_space and printer.paper != printer.roller and printer.roller != printer.lip, "paper, feed roller and lip have independent parts and sorting planes")
		check(not printer.playing and not printer.paper.visible, "initial menu state preserves exact original terminal")
		var source_geometry: Dictionary = scene.objects.ordering_terminal.geometry()
		var source_collision: Array = scene.navigation_rects().duplicate()
		await capture("00_idle")
		await open_world("ordering_kiosk")
		if not is_instance_valid(shell.c3_device_panel): await teardown(); continue
		check(not printer.playing and not state.d.items.pickupTicket0755, "opening menu grants and animates nothing")
		var before_order: Dictionary = state.d.duplicate(true)
		if dim.x >= 1100 or not capture_dir.is_empty(): await click(shell.c3_device_panel.controls.A)
		else: await touch(shell.c3_device_panel.controls.A)
		check(state.d.items.pickupTicket0755 and state.d.canteenHunt.orderedMenuOption == "A", "ordinary input grants controller ticket immediately")
		check(printer.playing and printer.observed_orders == 1, "one accepted order starts one printer sequence")
		check(not is_instance_valid(shell.c3_device_panel), "receipt does not retain or block the dismissed menu")
		await capture("01_start")
		var accepted_state: Dictionary = state.d.duplicate(true)
		printer.advance(.58)
		await capture("02_peak")
		check(printer.paper.visible and printer.paper.length == Receipt.PAPER_LENGTH and printer.paper.position.distance_to(Receipt.TERMINAL_POINT + Receipt.SLOT_POINT) < 1, "complete paper feeds from the registered original terminal slot")
		check(scene.objects.ordering_terminal.geometry() == source_geometry and scene.navigation_rects() == source_collision, "printing never deforms the terminal or changes source collision")
		check(state.d == accepted_state, "paper feed cannot commit progression or consume ticket")
		var accepted_result: Dictionary = state.last_result.duplicate(true)
		state.action_completed.emit("c3_order", before_order, state.d.duplicate(true), accepted_result)
		check(printer.observed_orders == 1 and is_equal_approx(printer.elapsed_ms, 580.0), "replayed accepted signal cannot restart a spent live edge")
		printer.advance(-1)
		check(is_equal_approx(printer.elapsed_ms, 580.0), "negative elapsed time never rewinds paper")
		printer.advance(.40)
		check(printer.paper_depth > Receipt.Metrics.foot_rect(shell.world.player).end.y and printer.z_index == scene.objects.ordering_terminal.parts[0].sprite.z_index, "loose paper reaches the hand plane while the terminal mechanism stays fixed")
		await capture("03_take")
		if dim.x == 390:
			state.d = state.d.duplicate(true); scene.sync(state.d, "canteen_interior")
			check(not printer.playing and not printer.paper.visible and state.d.items.pickupTicket0755, "mid-animation save replacement settles only presentation and retains the ticket")
		elif dim.x == 844:
			shell.world.hide(); printer._process(0); shell.world.show()
			check(not printer.playing and not printer.paper.visible and state.d.items.pickupTicket0755, "hiding the world retires detached paper without revoking the order")
		printer.advance(10)
		await capture("04_settled")
		check(not printer.playing and not printer.paper.visible and not printer.roller.visible and not printer.lip.visible, "take retires every temporary part to the original idle terminal")
		check(state.d == accepted_state, "animation completion gives no extra item or story fact")
		state.d = state.d.duplicate(true); scene.sync(state.d, "canteen_interior")
		check(not printer.playing and state.d.items.pickupTicket0755, "loading already ordered state stays settled without replay")
		state.action_completed.emit("c3_order", before_order, state.d.duplicate(true), accepted_result)
		check(printer.observed_orders == 1 and not printer.playing, "loaded ticket cannot reconstruct a transient order animation")
		await teardown()
	# Reduced motion is one brief stable paper, never a feed, sway or hand flight.
	for age: float in [0.0, 60.0, 179.0]:
		var pose: Dictionary = Receipt.sample(age, true)
		check(pose.length == Receipt.PAPER_LENGTH and pose.take == 0 and pose.sway == 0 and pose.lip == 0, "reduced mode stays in one settled receipt pose")
	check(Receipt.sample(180, true).length == 0, "reduced paper retires without a movement requirement")
	print("CANTEEN_RECEIPT_PERFORMANCE: ", checks, " checks; ", errors, " failures")
	quit(1 if errors else 0)
