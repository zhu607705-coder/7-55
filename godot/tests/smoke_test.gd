extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var migration_state := root.get_node_or_null("MigrationState")
	_expect(migration_state != null, "MigrationState autoload exists")
	if migration_state == null:
		_finish()
		return

	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		_fail("main scene could not be loaded")
		_finish()
		return

	var scene := packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	var runtime := scene.get_node_or_null("CampusRuntime")
	_expect(runtime != null, "CampusRuntime exists")
	if runtime == null:
		_finish()
		return

	var plate := runtime.get_node_or_null("CampusPlate") as Sprite2D
	_expect(plate != null and plate.texture != null, "campus plate texture imported")
	var player := runtime.get_node_or_null("Player") as CharacterBody2D
	_expect(player != null, "player exists")
	var camera := runtime.get_node_or_null("Player/Camera2D") as Camera2D
	_expect(camera != null and camera.enabled, "camera is enabled")

	if player != null:
		_expect(player.global_position.distance_to(Vector2(2550.0, 650.0)) < 1.0, "default checkpoint uses canonical spawn")
		player.set_input_enabled(false)
		player.global_position = Vector2(-300.0, 9000.0)
		player._physics_process(0.016)
		_expect(is_equal_approx(player.global_position.x, 0.0), "negative x is clamped")
		_expect(is_equal_approx(player.global_position.y, 3420.0), "oversized y is clamped")

	migration_state.call("hydrate", {
		"runtimeMode": "rpg",
		"rpgScene": "campus_bootstrap",
		"rpgCheckpoint": "campus_library_gate",
		"themeMode": "dark",
		"quest": {"objective": "测试图书馆检查点"},
		"canteenHunt": {"active": false, "phase": "tracking", "mode": "light"}
	})
	await process_frame
	if player != null:
		_expect(player.global_position.distance_to(Vector2(3805.0, 1680.0)) < 1.0, "library checkpoint uses runtime manifest approach")

	runtime._adjust_zoom(99.0)
	_expect(camera != null and is_equal_approx(camera.zoom.x, 1.8), "camera zoom upper bound")
	runtime._adjust_zoom(-99.0)
	_expect(camera != null and is_equal_approx(camera.zoom.x, 0.65), "camera zoom lower bound")

	var snapshot: Dictionary = runtime.snapshot()
	_expect(snapshot.get("scene", "") == "campus_bootstrap", "snapshot scene")
	_expect(snapshot.get("world", {}).get("width", 0) == 4516, "snapshot world width")
	_expect(snapshot.get("player", {}).has("x"), "snapshot player position")
	_finish()


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("[PASS] %s" % message)
	else:
		_fail(message)


func _fail(message: String) -> void:
	_failures.append(message)
	push_error("[FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("Godot migration smoke passed")
		quit(0)
	else:
		print("Godot migration smoke failed count=%d" % _failures.size())
		quit(1)
