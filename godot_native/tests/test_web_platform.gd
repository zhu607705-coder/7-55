extends SceneTree
## Uses the browser transport's actual State importer in a disposable profile.
const Platform = preload("res://scripts/platform/web_platform.gd")
var checks := 0
var failures := 0
var state: Node
var shell: Control
var bridge: Node

func _initialize() -> void: call_deferred("run")

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error("WEB PLATFORM: " + message)

func disk(path: String) -> PackedByteArray:
	return FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else PackedByteArray()

func run() -> void:
	if not load("res://tests/native_test_isolation.gd").is_isolated_save():
		push_error("WEB_PLATFORM_TEST_ISOLATION_REQUIRED")
		quit(2)
		return
	state = root.get_node("State")
	state.developer_mode = false
	state.d = state.initial()
	check(state.save_game(), "initial save commits in the isolated profile")
	shell = load("res://scenes/main.tscn").instantiate()
	root.add_child(shell)
	await process_frame
	bridge = Platform.new()
	shell.add_child(bridge)
	bridge.setup(shell, state)
	check(shell.web_platform == null, "desktop keeps its original filesystem dialog path")
	check(not bridge.legacy_save_available(), "desktop never attempts browser storage")
	var before: Dictionary = state.d.duplicate(true)
	var primary := disk(state.SAVE_PATH)
	var backup := disk(state.BACKUP_PATH)
	var snapshot: Dictionary = bridge.read_snapshot()
	check(snapshot.engine == "Godot" and not snapshot.web and not snapshot.version.is_empty(), "snapshot identifies the actual engine")
	check(snapshot.state == before and not snapshot.visibleControls.is_empty(), "snapshot observes real state and rendered controls")
	check(snapshot.saveDigest == primary.get_string_from_utf8().sha256_text(), "save digest describes actual autosave bytes")
	check(snapshot.world.camera == bridge._json_value(shell.world.camera) and snapshot.world.size == bridge._json_value(shell.world.size) and snapshot.world.zoom == shell.world.zoom, "read-only world geometry matches the actual camera, viewport and uniform zoom")
	var original_camera: Vector2 = shell.world.camera
	snapshot.world.camera.x += 100
	check(shell.world.camera == original_camera, "detached render geometry cannot move the real camera")
	var previous_mobile: bool = shell.world.mobile_exploration
	shell.world.mobile_exploration = true
	var touch_snapshot: Dictionary = bridge.read_snapshot()
	var actual_controls: Dictionary = shell.world.mobile_control_metrics()
	check(touch_snapshot.world.touchControls.interact == bridge._rect(actual_controls.interact), "touch hit geometry comes from the actual rendered world control")
	touch_snapshot.world.touchControls.interact.x += 100
	check(shell.world.mobile_control_metrics().interact == actual_controls.interact and state.d == before and disk(state.SAVE_PATH) == primary, "geometry observation has no world-input, progression or save write authority")
	shell.world.mobile_exploration = previous_mobile
	snapshot.state.native.page = "detached-only"
	check(state.d == before and disk(state.SAVE_PATH) == primary and disk(state.BACKUP_PATH) == backup, "reading and mutating a returned copy cannot alter state or either save")
	var result: Dictionary = bridge.import_text('{"state":')
	check(not result.ok, "malformed browser upload is rejected by the strict importer")
	check(state.d == before and disk(state.SAVE_PATH) == primary and disk(state.BACKUP_PATH) == backup, "failed upload retains state and both autosave files byte-for-byte")
	check(not FileAccess.file_exists(Platform.IMPORT_PATH), "failed upload leaves no temporary source file")
	var message: Array = []
	bridge.import_finished.connect(func(text: String): message.append(text))
	bridge._on_browser_file(["", "too_large"])
	bridge._on_browser_file(["", "read_error"])
	check(message.size() == 2 and message[0].contains("过大") and message[1].contains("无法读取"), "browser read and size failures give visible feedback")
	check(state.d == before and disk(state.SAVE_PATH) == primary, "browser transport errors never modify progression")
	var native: Dictionary = before.duplicate(true)
	native.native.settings.text_scale = 1.25
	result = bridge.import_text(JSON.stringify({"format": "7-55-godot-native", "version": 1, "sourceVersion": 35, "state": native}))
	check(result.ok and state.d.native.settings.text_scale == 1.25, "native upload reaches the original State validation and save transaction")
	check(not FileAccess.file_exists(Platform.IMPORT_PATH), "successful upload retires the temporary source file")
	state.d = state.initial()
	check(state.load_game() and state.d.native.settings.text_scale == 1.25, "uploaded state survives the actual native file reload")
	result = bridge.import_text(JSON.stringify({"version": 35, "state": state.initial()}))
	check(result.ok and state.d.native.page == "alarm", "retained browser envelope uses the ordinary migration path")
	var exported_state: Dictionary = state.d.duplicate(true)
	var committed := disk(state.SAVE_PATH)
	check(bridge.export_save() == OK, "portable export reuses the controller-owned archive")
	check(state.d == exported_state and disk(state.SAVE_PATH) == committed and not FileAccess.file_exists(Platform.EXPORT_PATH), "export cannot alter progression and leaves no temporary export file")
	bridge.queue_free()
	await process_frame
	if is_instance_valid(shell.audio_director): await shell.audio_director.shutdown()
	if is_instance_valid(shell.media_host): await shell.media_host.shutdown()
	shell.queue_free()
	await process_frame
	print("WEB_PLATFORM: ", checks, " checks; ", failures, " failures")
	quit(1 if failures else 0)
