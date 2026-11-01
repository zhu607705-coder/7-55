extends "res://campuses/future_learning_center/tests/test_object_input.gd"

func run() -> void:
	if not preload("res://tests/native_test_isolation.gd").is_isolated_save(): quit(2); return
	root.title = "7:55 · 储物柜数字解密交互验收"
	RenderingServer.set_default_clear_color(Color("101820"))
	host = SubViewportContainer.new(); host.size = Vector2(960, 540); host.stretch = false; root.add_child(host)
	viewport = SubViewport.new(); viewport.size = Vector2i(960, 540); viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS; host.add_child(viewport)
	world = load("res://campuses/future_learning_center/scripts/floor_view.gd").new(); viewport.add_child(world)
	root.size_changed.connect(fit); fit(); root.grab_focus(); await process_frame; await process_frame
	touch = OS.get_environment("FLC_TOUCH") == "1"
	world.load_floor(2); check(not world.open_locker(), "another floor cannot open the studio locker")
	world.load_floor(3)
	var approach: Vector2 = world.locker_approach()
	check(approach.is_finite() and world.space.can_stand(approach - world.Body.FOOT_CENTER_OFFSET), "cabinet has a grounded approach")
	var cabinet: Dictionary = world.locker_cabinet()
	check(not cabinet.is_empty() and world.set_foot(world.coupling_approach()) and not world.can_open_locker(), "existing table area is outside locker reach")
	await process_frame; await capture("locker_room")
	await click(world.world_to_screen(world.Space.rect(cabinet.bounds).get_center()))
	var lab: Control = world.locker_cipher
	check(world.locker_pending and not lab.visible, "cabinet click starts a real approach from the table")
	var deadline := Time.get_ticks_msec() + 12000
	while not lab.visible and Time.get_ticks_msec() < deadline: await process_frame
	check(lab.visible and no_action_strip(lab) and world.invalid_frames == 0, "real cabinet click opens the close view")
	if not lab.visible: write_result(); return
	var return_foot: Vector2 = world.player
	await create_timer(.3).timeout; await capture("locker_closed")
	await stroke(Vector2(796, 340), Vector2(796, 380))
	check(not lab.model.unlocked and lab.model.failed_attempts == 1, "wrong code refuses without losing state")
	await click(Vector2(245, 250)); await create_timer(.4).timeout
	check(lab.model.clue_open, "directly opening a cabinet door exposes clues")
	await capture("locker_clue")
	await stroke(lab.HINT_NOTE.get_center(), lab.HINT_NOTE.get_center() + Vector2(-80, 20))
	check(lab.model.hint_index == 0 and not lab.model.unlocked, "dragging away from the physical note cancels without revealing a hint")
	await click(lab.HINT_NOTE.get_center())
	check(lab.model.hint_index == 1 and not lab.model.unlocked, "optional clue has no progression side effect")
	var start: Vector2 = lab.CARD_HOME + Vector2(20, 80)
	await point(start, "down", 7, true); await point(start + Vector2(-80, 0), "move", 7, true)
	await point(start + Vector2(-80, 0), "up", 8, true)
	check(lab.pointer_owner == 7, "a second finger cannot take the card gesture")
	await point(start + Vector2(-80, 0), "up", 7, true, true)
	check(not lab.model.stencil_placed and lab.card_preview == lab.CARD_HOME, "cancelled touch returns the paper card")
	await point(start, "down"); await point(start + Vector2(-80, 0), "move")
	lab._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(lab.gesture.is_empty() and not lab.model.stencil_placed, "focus loss cancels an uncommitted card")
	await point(start + Vector2(-80, 0), "up")
	root.grab_focus(); await process_frame
	await stroke(start, lab.BOARD + Vector2(20, 80))
	check(lab.model.stencil_placed and not lab.model.unlocked, "matching folded corners reveals digits without opening lock")
	await capture("locker_aligned")
	await point(lab.WHEEL_CENTERS[0], "down"); await point(lab.WHEEL_CENTERS[0] - Vector2(0, 48), "move")
	check(lab.wheel_preview(0) == 2 and lab.model.digits[0] == 0, "wheel visibly follows the held gesture without an early commit")
	await capture("locker_rolling")
	lab._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(lab.wheel_preview(0) == 0 and lab.model.digits[0] == 0, "interrupted wheel drag restores the original digit")
	await point(lab.WHEEL_CENTERS[0] - Vector2(0, 48), "up")
	root.grab_focus(); await process_frame
	var expected: Array[int] = lab.model.answer()
	for i: int in 3:
		var steps: int = expected[i] if expected[i] <= 5 else expected[i] - 10
		await stroke(lab.WHEEL_CENTERS[i], lab.WHEEL_CENTERS[i] - Vector2(0, 24 * steps))
	check(lab.model.digits == expected and not lab.model.unlocked, "direct wheel gestures enter the ordered shape-pair sums")
	await capture("locker_entered")
	await stroke(Vector2(796, 340), Vector2(796, 380)); await create_timer(.5).timeout
	check(lab.model.unlocked and lab.lock_progress > .99, "physical handle opens only with the matching code")
	await capture("locker_open")
	await click(Vector2(876, 27))
	check(not lab.visible and world.player == return_foot and world.ui.visible, "exit restores the same grounded player position")
	await capture("locker_return")
	if not lab.visible: await click(world.world_to_screen(world.Space.rect(cabinet.bounds).get_center()))
	check(lab.visible and lab.model.unlocked and world.player == return_foot, "cabinet result is retained after a real exit and reentry")
	world.load_floor(2)
	check(not lab.visible and not world.locker_pending, "floor changes close the cabinet safely")
	write_result()

func write_result() -> void:
	var failed: Array = results.filter(func(row: Dictionary) -> bool: return not row.passed)
	var folder := OS.get_environment("FLC_CAPTURE_DIR"); DirAccess.make_dir_recursive_absolute(folder)
	var file := FileAccess.open(folder.path_join("locker_input.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks": assertions, "failures": failed.size(), "results": results, "touch": touch, "keyboardEvents": 0, "viewport": [root.size.x, root.size.y]}, "  ")); file.close()
	print("FLC_LOCKER_INPUT: %d checks, %d failures, keyboard events 0" % [assertions, failed.size()])
	quit(1 if failed.size() else 0)
