extends SceneTree
## Real Entry + WebContent lifecycle; native input is not browser performance proof.
var checks := 0
var failures := 0
var pressed := 0
var content: Node
class Transport extends RefCounted:
	func request(_raw: String) -> void: pass
	func retry(_raw: String) -> void: pass
func _initialize() -> void: run.call_deferred()
func check(ok: bool, note: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("ENTRY_CONTENT_COVER: " + note)
func frames() -> void:
	for unused in 3: await process_frame
func new_entry() -> Control:
	var entry: Control = load("res://scenes/entry.tscn").instantiate()
	root.add_child(entry)
	return entry
func begin_optional(result: Array) -> void:
	result.append(await content.ensure_families(["flc_activity"], true))
func save_bytes(path: String) -> PackedByteArray:
	return FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else PackedByteArray()
func run() -> void:
	if not load("res://tests/native_test_isolation.gd").is_isolated_save():
		push_error("ENTRY_CONTENT_COVER_ISOLATION_REQUIRED"); quit(2); return
	root.set_meta("entry_arguments_consumed", true)
	root.size = Vector2i(390,844)
	content = root.get_node("WebContent")
	var state: Node = root.get_node("State")
	var before: Dictionary = state.d.duplicate(true)
	var save_before := save_bytes(state.SAVE_PATH)
	var backup_before := save_bytes(state.BACKUP_PATH)
	var connections: int = content.blocking_changed.get_connections().size()
	var entry := new_entry()
	await frames()
	check(entry.visible and entry.story_button.is_visible_in_tree(), "native monolithic entry stays visible")
	entry.flc_button.grab_focus()
	var child_visibility: bool = entry.detail.visible
	content._fatal_error = "fixture retry"
	content._show_fatal()
	await frames()
	check(not entry.visible and not entry.card.is_visible_in_tree() and not entry.get_node("EntryDormBackdrop").is_visible_in_tree(), "cover hides actual entry and backdrop")
	check(content._overlay.visible and content._retry.is_visible_in_tree(), "independent loading overlay and retry remain visible")
	check(entry.is_processing() and entry.can_process(), "hidden entry keeps snapshot processing alive")
	var snapshot: Dictionary = entry.entry_snapshot()
	check(snapshot.entry and snapshot.content.blocking and snapshot.visibleControls.is_empty(), "snapshot remains readable without hidden controls")
	await frames()
	check(entry.entry_snapshot().sampleFrame > snapshot.sampleFrame, "hidden snapshot reports advancing frames")
	# Hidden controls cannot receive normal pointer or keyboard activation.
	var probe := Button.new(); probe.position = Vector2(10,10); probe.size = Vector2(90,44)
	entry.add_child(probe); probe.pressed.connect(func(): pressed += 1)
	for down in [true,false]:
		var mouse := InputEventMouseButton.new(); mouse.button_index = MOUSE_BUTTON_LEFT
		mouse.position = Vector2(20,20); mouse.pressed = down; root.push_input(mouse)
	# Deliberately attempts deferred/programmatic focus on a hidden child;
	# Godot emits an expected refusal warning when recursive focus is disabled.
	probe.grab_focus()
	check(not probe.has_focus(), "hidden descendant cannot take keyboard focus")
	for down in [true,false]:
		var key := InputEventKey.new(); key.keycode = KEY_ENTER; key.pressed = down; root.push_input(key)
	check(pressed == 0, "hidden descendant receives no pointer or keyboard activation")
	probe.queue_free()
	content._retry_required()
	check(not entry.visible and content.is_blocking(), "retry keeps entry hidden while error cover remains")
	content._fatal_error = ""; content._update_overlay()
	await frames()
	check(entry.visible and entry.flc_button.has_focus(), "unblocking restores entry and its original focus")
	check(entry.detail.visible == child_visibility, "child visibility is preserved")
	check(entry.focus_behavior_recursive == Control.FOCUS_BEHAVIOR_INHERITED, "recursive focus policy is restored")
	for unused in 3:
		content._show_fatal(); content._set_blocking(true)
		content._fatal_error = ""; content._update_overlay()
	check(entry.visible and entry.flc_button.has_focus(), "repeated and duplicate transitions preserve visibility and focus")
	entry.hide(); content._show_fatal(); content._update_overlay()
	check(not entry.visible, "preexisting hidden entry is not revealed on unblock")
	entry.show(); entry.flc_button.grab_focus(); content._show_fatal()
	var manager := Button.new(); manager.text = "unrelated manager"; root.add_child(manager); manager.grab_focus()
	content._update_overlay()
	check(manager.visible and manager.has_focus(), "unrelated manager remains visible and keeps its focus")
	manager.queue_free(); await frames()
	entry.queue_free(); await frames()
	check(content.blocking_changed.get_connections().size() == connections, "freed entry disconnects its listener")
	# Already blocking before Entry ready, including an initially hidden instance.
	content._show_fatal(); entry = new_entry(); await frames()
	check(not entry.visible, "already blocking at ready hides entry")
	content._update_overlay(); await frames()
	check(entry.visible and entry.story_button.has_focus(), "ready-time focus restored after cover closes")
	content._show_fatal(); root.remove_child(entry)
	check(entry.visible and not entry._content_cover_active, "scene exit restores local visibility without retaining a cover session")
	check(content.blocking_changed.get_connections().size() == connections, "scene exit disconnects before a newer scene appears")
	entry.free(); content._update_overlay()
	entry = load("res://scenes/entry.tscn").instantiate(); entry.hide()
	content._show_fatal(); root.add_child(entry); content._update_overlay()
	check(not entry.visible, "initially hidden instance remains hidden after ready-time cover")
	entry.queue_free(); await frames()
	# Actual optional waiter, error, retry, cancel, and retry-after-cancel paths.
	var record := {"id":"flc_fixture", "family":"flc_activity", "file":"packs/flc_fixture.pck", "bytes":1, "sha256":"0".repeat(64)}
	check(content._configure_manifest({"schema":"755-web-content-v1", "core":{"file":"core.pck", "bytes":1, "sha256":"0".repeat(64)}, "packs":[record], "backgroundOrder":[]}, Transport.new()), "optional fixture configures real coordinator")
	entry = new_entry(); await frames(); entry.flc_button.grab_focus()
	for unused in 2:
		var result: Array = []; begin_optional(result); await frames()
		check(not entry.visible and content._cancel_optional_button.is_visible_in_tree(), "optional wait hides entry but keeps cancel available")
		content._packs.flc_fixture.status = "error"; content._update_overlay()
		check(content._retry.is_visible_in_tree() and not entry.visible, "optional error keeps retry over hidden entry")
		content._retry_required()
		check(content._packs.flc_fixture.status == "requested" and not entry.visible, "optional retry preserves the block")
		content._cancel_optional_button.pressed.emit(); await frames()
		check(result == [false] and entry.visible and entry.flc_button.has_focus(), "actual optional cancel restores entry and focus")
	check(state.d == before and save_bytes(state.SAVE_PATH) == save_before and save_bytes(state.BACKUP_PATH) == backup_before, "cover lifecycle changes neither progress nor save bytes")
	current_scene = entry
	var successor := Control.new()
	var packed := PackedScene.new(); check(packed.pack(successor) == OK, "successor scene packs")
	successor.free()
	content._show_fatal()
	check(change_scene_to_packed(packed) == OK, "actual scene change leaves blocked entry")
	await frames()
	content._update_overlay()
	check(current_scene.visible, "old entry listener cannot hide the replacement scene")
	check(content.blocking_changed.get_connections().size() == connections, "final entry listener is released")
	print("ENTRY_CONTENT_COVER: %d checks; %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
