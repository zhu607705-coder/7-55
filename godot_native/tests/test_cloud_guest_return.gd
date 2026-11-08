extends SceneTree
## A first-time guest must be able to leave the ordinary save manager.
var checks := 0
var failures := 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("CLOUD GUEST RETURN: " + label)

func find_action(column: VBoxContainer, label: String) -> Button:
	for child in column.get_children():
		if child is Button and child.text == label:
			return child
	return null

func click(button: Button) -> void:
	for frame in 3: await process_frame
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.position = button.get_global_rect().get_center()
	down.global_position = down.position
	down.pressed = true
	root.push_input(down, true)
	var up: InputEventMouseButton = down.duplicate()
	up.pressed = false
	root.push_input(up, true)
	await process_frame

func run() -> void:
	if not preload("res://tests/native_test_isolation.gd").is_isolated_save():
		quit(2)
		return
	root.size = Vector2i(1280, 720)
	var state: Node = root.get_node("State")
	check(state.activate_profile("guest", false).get("ok", false), "fresh guest profile is usable")
	var cloud: Node = load("res://scripts/platform/cloud_saves.gd").new()
	root.add_child(cloud)
	cloud.set_process(false)
	cloud.process_mode = Node.PROCESS_MODE_ALWAYS
	cloud._build_surface()
	state.snapshot_saved.connect(cloud._mark_dirty)
	cloud._resume()
	check(not cloud.has_save, "fresh guest starts without a durable save")
	var fresh_state: Dictionary = state.d.duplicate(true)
	cloud.show_manager()
	var back := find_action(cloud._column, "返回")
	check(is_instance_valid(back), "empty guest manager provides a return action")
	if is_instance_valid(back):
		await click(back)
		check(not paused and cloud.ready_for_play and not cloud._cover.visible, "return dismisses the empty manager and releases its pause")
		check(state.d == fresh_state and not FileAccess.file_exists(state.SAVE_PATH), "return preserves a fresh guest without creating a save")
	cloud.ready_for_play = false
	cloud.show_manager()
	check(find_action(cloud._column, "返回") == null, "a required account gate cannot be dismissed as a voluntary manager")
	cloud._resume()
	state.developer_mode = true
	check(not state.save_game() and not cloud.has_save, "developer save cannot enable guest continuation")
	state.developer_mode = false
	state.d.phoneBattery.percent = -1
	check(not state.save_game() and not cloud.has_save, "rejected invalid save cannot enable guest continuation")
	state.d = state.initial()
	state.open_page("phone_home")
	check(FileAccess.file_exists(state.SAVE_PATH), "ordinary navigation creates the first guest save")
	check(cloud.has_save, "successful first save enables manager continuation")
	var before: Dictionary = state.d.duplicate(true)
	var bytes_before: PackedByteArray = FileAccess.get_file_as_bytes(state.SAVE_PATH)
	cloud.show_manager()
	check(paused and not cloud.ready_for_play, "manager acquires its normal pause lease")
	var continuation := find_action(cloud._column, "继续游戏")
	check(is_instance_valid(continuation), "first-time guest manager provides Continue")
	if is_instance_valid(continuation):
		await click(continuation)
		check(not paused and cloud.ready_for_play and not cloud._cover.visible, "Continue dismisses manager and releases pause")
		check(state.d == before and FileAccess.get_file_as_bytes(state.SAVE_PATH) == bytes_before, "return preserves story and saved bytes")
	cloud._resume()
	cloud.free()
	print("CLOUD_GUEST_RETURN: ", checks, " checks; ", failures, " failures")
	quit(1 if failures else 0)
