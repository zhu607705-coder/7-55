extends "res://tests/test_cc98_gamepad_exchange.gd"
## Lead-only graphical fixture. Use a separate user profile; not earned-play proof.
var output: String
var captured := 0
func capture(label: String) -> void:
	await frames(); await RenderingServer.frame_post_draw
	var path := output + "/" + label + ".png"
	check(root.get_texture().get_image().save_png(path) == OK, "capture saved: " + path)
	captured += 1; print("CC98_GAMEPAD_CAPTURE ", path)
func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Use test_cc98_gamepad_exchange.gd headlessly; the lead owns graphical captures")
		quit(1); return
	output = OS.get_environment("CC98_GAMEPAD_CAPTURE_DIR")
	if output.is_empty(): output = ProjectSettings.globalize_path("res://.screenshots/cc98-gamepad")
	DirAccess.make_dir_recursive_absolute(output)
	state = root.get_node("State"); state.developer_mode = true; state.d = state.initial()
	shell = load("res://scenes/main.tscn").instantiate(); root.add_child(shell); await frames(); shell.set_process(false)
	for viewport: Vector2i in [Vector2i(390,844), Vector2i(430,860), Vector2i(1440,900)]:
		DisplayServer.window_set_size(viewport); root.size = viewport; shell.size = Vector2(viewport); await frames()
		var prefix := "%dx%d" % [viewport.x, viewport.y]
		await fixture(viewport, 6, false); check_geometry(); await capture(prefix + "-insufficient")
		await click(named(shell.page_body, "Cc98GamepadPurchase")); await capture(prefix + "-rejected")
		await fixture(viewport); check_geometry(); await capture(prefix + "-ready")
		var scroll: ScrollContainer = named(shell.page_body, "Cc98GamepadScroll")
		scroll.scroll_vertical = 10000; await capture(prefix + "-product-details")
		await click(named(shell.page_body, "Cc98GamepadPurchase")); check_geometry(true); await capture(prefix + "-purchased")
		await click(named(shell.page_body, "Cc98GamepadReturn")); await capture(prefix + "-dorm-return")
	await shell.shutdown(); shell.queue_free(); await frames()
	print("CC98 gamepad graphical fixtures: ", captured, " captures; ", checks, " checks; ", failures, " failures. Not manual campaign proof.")
	quit(1 if failures else 0)
