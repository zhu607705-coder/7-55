extends SceneTree
## Chooser lifecycle regression: real menu clicks must not grant story facts,
## quit the host, retain owned input, or leave preview nodes processing.
var checks := 0
var failures := 0
var state: Node
var state_before: Dictionary
var save_before: Dictionary = {}
var actions_before: Dictionary

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("ENTRY_PREVIEWS: " + message)

func frames(count := 3) -> void:
	for index in count:await process_frame

func click(control: Control) -> void:
	var position := control.get_global_transform_with_canvas() * (control.size / 2)
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = position;event.button_index = MOUSE_BUTTON_LEFT;event.pressed = pressed
		root.push_input(event)
	await frames()

func input_snapshot() -> Dictionary:
	var result: Dictionary = {}
	for action in InputMap.get_actions():
		var events: Array[String] = []
		for event in InputMap.action_get_events(action):events.append(event.as_text())
		result[str(action)] = {"deadzone":InputMap.action_get_deadzone(action),"events":events}
	return result

func preserved() -> void:
	if state != null:check(state.d == state_before,"preview leaves controller state unchanged")
	for path in save_before:check(FileAccess.get_file_as_bytes(path) == save_before[path],"preview leaves save bytes unchanged")
	check(input_snapshot() == actions_before,"preview restores the exact input action definitions")

func run() -> void:
	state = root.get_node_or_null("State")
	if state != null:state_before = state.d.duplicate(true)
	for path in ["user://save.json","user://save.previous.json"]:save_before[path] = FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else PackedByteArray()
	actions_before = input_snapshot()
	root.set_meta("entry_arguments_consumed",true)
	check(change_scene_to_file("res://scenes/entry.tscn") == OK,"entry loads")
	await frames(5)
	for size in [Vector2i(1440,900),Vector2i(390,844),Vector2i(667,375),Vector2i(844,390)]:
		root.size = size;await frames(4)
		var entry = current_scene
		var bounds := Rect2(Vector2.ZERO,Vector2(size))
		check(bounds.encloses(entry.card.get_global_rect()),"main chooser fits " + str(size))
		for button in [entry.story_button,entry.campus_button,entry.haidian_button,entry.changping_button,entry.preview_button]:
			check(bounds.encloses(button.get_global_rect()) and button.size.y >= 44,"entry target fits " + str(button.name))
		await click(entry.preview_button)
		check(entry.previews_open and entry.preview_menu.visible,"real menu click opens preview choices")
		check(bounds.encloses(entry.card.get_global_rect()),"scrollable preview menu fits " + str(size))
		await click(entry.preview_back)
		check(not entry.previews_open and entry.content.visible,"real back click restores modern chooser")
	root.size = Vector2i(1280,720);await frames(4)
	for index in range(3):
		for use_local_exit in [false,true]:
			var entry = current_scene
			await click(entry.preview_button)
			var button: Button = entry.preview_rows.get_child(index * 2)
			entry.preview_scroll.ensure_control_visible(button);await frames(3)
			await click(button)
			var preview: Node = entry.preview_instance
			check(is_instance_valid(preview),"preview opens through its real choice " + str(index))
			if not is_instance_valid(preview):continue
			check(current_scene == entry and not entry.card.visible,"preview embeds without replacing or quitting chooser")
			var reference: WeakRef = weakref(preview)
			var bar_reference: WeakRef = weakref(entry.preview_bar)
			if index < 2:
				preview.start_button.pressed.emit();await frames(3)
				check(preview.active,"stair preview starts its real timer")
				if use_local_exit:preview._request_exit()
				else:await click(entry.preview_bar.get_child(0))
			else:
				preview.start_guide();await frames(3)
				check(preview.guide_active,"tree preview starts its real guide")
				if use_local_exit:preview.return_to_entry()
				else:await click(entry.preview_bar.get_child(0))
			await frames(6)
			check(reference.get_ref() == null and bar_reference.get_ref() == null,"preview and overlay are freed; no background timer remains")
			check(current_scene.has_method("open_previews") and current_scene.card.visible,"both exit paths keep host running")
			preserved()
			if current_scene.previews_open:await click(current_scene.preview_back)
	print("ENTRY_PREVIEWS: %d checks; %d failures" % [checks,failures])
	current_scene.queue_free();await frames(3)
	quit(0 if failures == 0 else 1)
