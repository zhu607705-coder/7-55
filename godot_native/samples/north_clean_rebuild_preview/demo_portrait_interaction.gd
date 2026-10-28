extends SceneTree
## Real GUI-input capture for Godot's movie writer. No story or save fixtures.

var view: Control
var failures := 0

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func click(point: Vector2, touchscreen := false) -> void:
	if touchscreen:
		var down := InputEventScreenTouch.new()
		down.index = 0
		down.position = point
		down.pressed = true
		Input.parse_input_event(down)
		await process_frame
		var up := InputEventScreenTouch.new()
		up.index = 0
		up.position = point
		up.pressed = false
		Input.parse_input_event(up)
	else:
		# Keep native macOS pointer events on the same position as the injected click.
		Input.warp_mouse(point)
		await process_frame
		var motion := InputEventMouseMotion.new()
		motion.position = point
		motion.global_position = point
		Input.parse_input_event(motion)
		await process_frame
		var down := InputEventMouseButton.new()
		down.button_index = MOUSE_BUTTON_LEFT
		down.position = point
		down.global_position = point
		down.button_mask = MOUSE_BUTTON_MASK_LEFT
		down.pressed = true
		Input.parse_input_event(down)
		await process_frame
		var up := InputEventMouseButton.new()
		up.button_index = MOUSE_BUTTON_LEFT
		up.position = point
		up.global_position = point
		up.pressed = false
		Input.parse_input_event(up)
	await process_frame

func _initialize() -> void:
	await process_frame
	view = load("res://preview.tscn").instantiate()
	root.add_child(view)
	root.grab_focus()
	view._select_mode("objects")
	await process_frame
	await RenderingServer.frame_post_draw
	await create_timer(0.6).timeout
	await click(view._portrait_screen_rect("zhu_kezhen").get_center())
	await create_timer(0.85).timeout
	var inspector: Control = view.portrait_inspector
	check(inspector.active_id == "zhu_kezhen" and inspector.phase == "open", "Real mouse click opens Zhu")
	var output := OS.get_environment("NORTH_PORTRAIT_STILL")
	if not output.is_empty():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(output)
	await create_timer(1.2).timeout
	await click(inspector.next_button.get_global_rect().get_center())
	await create_timer(1.45).timeout
	check(inspector.active_id == "lu_yongxiang", "Real button click selects the next figure")
	var close_point: Vector2 = inspector.close_button.get_global_rect().get_center()
	print("Close-button capture: point=%s; phase=%s; panel=%s" % [close_point, inspector.phase, inspector.panel.get_global_rect()])
	await click(close_point)
	await create_timer(0.7).timeout
	check(not inspector.visible, "Real close button returns to the wall (phase=%s, mouse=%s)" % [inspector.phase, root.get_mouse_position()])
	await click(view._portrait_screen_rect("chen_jiangong").get_center(), true)
	await create_timer(1.9).timeout
	check(inspector.active_id == "chen_jiangong" and inspector.phase == "open", "Real touchscreen event opens Chen")
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	Input.parse_input_event(escape)
	await create_timer(0.65).timeout
	check(not inspector.visible and view.hidden_objects.is_empty(), "Escape returns without hiding any portrait")
	view.board.grab_focus()
	var open_key := InputEventKey.new()
	open_key.keycode = KEY_SPACE
	open_key.pressed = true
	Input.parse_input_event(open_key)
	await create_timer(0.6).timeout
	check(inspector.phase == "open", "Space opens the keyboard-selected portrait")
	var previous_id: String = inspector.active_id
	var next_key := InputEventKey.new()
	next_key.keycode = KEY_RIGHT
	next_key.pressed = true
	Input.parse_input_event(next_key)
	await create_timer(0.4).timeout
	check(inspector.active_id != previous_id, "Right arrow changes figures while a button is focused")
	Input.parse_input_event(escape)
	await create_timer(0.5).timeout
	check(not inspector.visible, "Keyboard close settles after keyboard navigation")
	print("A3 portrait real-input capture: 8 checks, %d failures" % failures)
	quit(1 if failures else 0)
