extends SceneTree

var checks := 0
var failures := 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func touch(view: Control, point: Vector2) -> void:
	var down := InputEventScreenTouch.new()
	down.position = point
	down.pressed = true
	view.board_input(view.board, down)
	var up := InputEventScreenTouch.new()
	up.position = point
	up.pressed = false
	view.board_input(view.board, up)

func _initialize() -> void:
	await process_frame
	var view: Control = load("res://preview.tscn").instantiate()
	root.add_child(view)
	await process_frame
	await process_frame
	view._select_mode("objects")
	view.board_rect = Rect2(0, 0, 1672, 941)
	view.board_scale = 1.0
	var inspector: Control = view.portrait_inspector
	inspector.set_reduced_motion(true)
	var at: Vector2 = view._fitted_rect(view.portrait_frames.zhu_kezhen).get_center()
	touch(view, at)
	check(inspector.visible and inspector.active_id == "zhu_kezhen", "Touch opens Zhu's portrait")
	check(inspector.phase == "open" and inspector.hero.visible, "Reduced motion opens a settled portrait")
	check(view.hidden_objects.is_empty(), "Portrait interaction never hides artwork")
	check(inspector.title_label.text == "竺可桢" and "1936—1949" in inspector.biography.text, "Read the existing authored biography")
	inspector.next_button.pressed.emit()
	check(inspector.active_id == "lu_yongxiang" and view.focused_portrait_id == "lu_yongxiang", "Next figure updates portrait and wall selection together")
	inspector.previous_button.pressed.emit()
	check(inspector.active_id == "zhu_kezhen", "Previous figure restores Zhu")
	for viewport_size: Vector2i in [Vector2i(1280, 720), Vector2i(390, 844), Vector2i(360, 360)]:
		root.size = viewport_size
		await process_frame
		await process_frame
		await process_frame
		var visible_area := Rect2(Vector2.ZERO, Vector2(viewport_size))
		check(visible_area.encloses(inspector.panel.get_global_rect()), "Biography fits the window: %s; panel %s; host %s" % [viewport_size, inspector.panel.get_global_rect(), inspector.size])
		check(inspector.panel.get_global_rect().encloses(inspector.close_button.get_global_rect()), "Close remains reachable: " + str(viewport_size))
		check(inspector.panel.get_global_rect().encloses(inspector.next_button.get_global_rect()), "Figure navigation remains reachable: " + str(viewport_size))
		check(inspector.biography.size.y > 0 and inspector.biography.scroll_active, "Biography remains scrollable: " + str(viewport_size))
	inspector.close_button.pressed.emit()
	check(not inspector.visible and inspector.phase == "closed", "Close returns to the intact wall")
	root.size = Vector2i(1280, 760)
	await process_frame
	inspector.set_reduced_motion(false)
	view._open_portrait("zhu_kezhen")
	inspector.close_portrait()
	await create_timer(0.5).timeout
	check(inspector.phase == "closed" and not inspector.visible, "Closing during opening cancels stale callbacks")
	view._open_portrait("zhu_kezhen")
	await process_frame
	view._open_portrait("chen_jiangong")
	await create_timer(0.55).timeout
	check(inspector.phase == "open" and inspector.active_id == "chen_jiangong", "Rapid reselection finishes on the latest person")
	check(inspector.hero.visible and not inspector.traveling.visible, "The traveling portrait settles exactly once")
	view._select_mode("empty")
	check(not inspector.visible and inspector.active_id.is_empty(), "Changing the art mode closes the inspector")
	view._select_mode("objects")
	view._open_portrait("su_buqing")
	inspector.set_reduced_motion(true)
	await process_frame
	check(inspector.phase == "open" and inspector.active_id == "su_buqing", "Reduced motion safely interrupts an opening animation")
	inspector.reset()
	inspector.open_portrait("unknown")
	check(not inspector.visible and inspector.phase == "closed", "An unknown portrait cannot open a blank panel")
	check(view.hidden_objects.is_empty(), "Repeated reading and closing preserve every scene object")
	view.queue_free()
	await process_frame
	print("A3 portrait interaction: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
