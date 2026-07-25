extends Node2D

const CAMPUS_MAP_PATH := "res://assets/generated/rpg/campus/zijingang_campus_plate.png"
const CAMPUS_MANIFEST_PATH := "res://assets/generated/data/maps/zijingang-campus-runtime.json"
const PLAYER_SCRIPT := preload("res://scripts/player_controller.gd")

var _runtime_manifest: Dictionary = {}
var _world_size := Vector2(4516.0, 3420.0)
var _spawn := Vector2(2550.0, 650.0)
var _library_spawn := Vector2(3805.0, 1680.0)
var _canteen_spawn := Vector2(3120.0, 650.0)
var _canteen_hunt_spawn := Vector2(4200.0, 2868.0)
var _player
var _camera: Camera2D
var _canvas_modulate: CanvasModulate
var _objective_label: Label
var _status_label: Label
var _last_checkpoint := ""
var _last_snapshot_at := 0


func _ready() -> void:
	_read_runtime_manifest()
	_build_world()
	_build_overlay()
	MigrationState.state_changed.connect(_apply_state)
	WebBridge.command_received.connect(_on_bridge_command)
	_apply_state(MigrationState.snapshot())
	WebBridge.post_event("godot_runtime_started", {
		"scene": "campus_bootstrap",
		"world": {"width": _world_size.x, "height": _world_size.y}
	})
	_post_snapshot()


func _process(_delta: float) -> void:
	var now := Time.get_ticks_msec()
	if now - _last_snapshot_at >= 250:
		_post_snapshot()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_adjust_zoom(0.1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_adjust_zoom(-0.1)
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			_camera.global_position = _player.global_position
		elif event.keycode in [KEY_EQUAL, KEY_KP_ADD]:
			_adjust_zoom(0.1)
		elif event.keycode in [KEY_MINUS, KEY_KP_SUBTRACT]:
			_adjust_zoom(-0.1)


func snapshot() -> Dictionary:
	return {
		"scene": "campus_bootstrap",
		"checkpoint": str(MigrationState.value("rpgCheckpoint", "campus_spawn")),
		"world": {
			"width": roundi(_world_size.x),
			"height": roundi(_world_size.y)
		},
		"player": {
			"x": roundi(_player.global_position.x),
			"y": roundi(_player.global_position.y),
			"velocityX": roundi(_player.velocity.x),
			"velocityY": roundi(_player.velocity.y)
		},
		"camera": {
			"zoom": snappedf(_camera.zoom.x, 0.01)
		},
		"engine": Engine.get_version_info()
	}


func _read_runtime_manifest() -> void:
	if not FileAccess.file_exists(CAMPUS_MANIFEST_PATH):
		push_error("Godot campus manifest is missing. Run npm run godot:sync.")
		return
	var file := FileAccess.open(CAMPUS_MANIFEST_PATH, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_error("Godot campus manifest is invalid JSON.")
		return
	_runtime_manifest = parsed
	var world: Dictionary = _runtime_manifest.get("world", {})
	_world_size = Vector2(float(world.get("width", 4516)), float(world.get("height", 3420)))
	_spawn = _point_from(_runtime_manifest.get("spawn", {}), _spawn)
	var walkability: Dictionary = _runtime_manifest.get("walkability", {})
	_library_spawn = _point_from(walkability.get("gateApproach", {}), _library_spawn)
	var canteen: Dictionary = _runtime_manifest.get("canteen", {})
	_canteen_spawn = _point_from(canteen.get("approach", {}), _canteen_spawn)
	_canteen_hunt_spawn = _point_from(canteen.get("huntSpawn", {}), _canteen_hunt_spawn)


func _build_world() -> void:
	_canvas_modulate = CanvasModulate.new()
	_canvas_modulate.name = "CanvasModulate"
	add_child(_canvas_modulate)

	var map_texture := load(CAMPUS_MAP_PATH) as Texture2D
	if map_texture == null:
		push_error("Godot campus texture is missing. Run npm run godot:sync.")
	else:
		var background := Sprite2D.new()
		background.name = "CampusPlate"
		background.centered = false
		background.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		background.texture = map_texture
		background.z_index = -100
		add_child(background)

	_add_landmark("基础图书馆", Vector2(3718.0, 1568.0))
	var canteen: Dictionary = _runtime_manifest.get("canteen", {})
	_add_landmark("东区大食堂", _point_from(canteen.get("gate", {}), Vector2(3120.0, 620.0)))

	_player = CharacterBody2D.new()
	_player.name = "Player"
	_player.set_script(PLAYER_SCRIPT)
	add_child(_player)
	_player.configure(_world_size, _spawn)
	_player.position_changed.connect(_on_player_position_changed)

	_camera = Camera2D.new()
	_camera.name = "Camera2D"
	_camera.position_smoothing_enabled = true
	_camera.position_smoothing_speed = 7.0
	_camera.zoom = Vector2.ONE * 1.1
	_camera.limit_left = 0
	_camera.limit_top = 0
	_camera.limit_right = roundi(_world_size.x)
	_camera.limit_bottom = roundi(_world_size.y)
	_player.add_child(_camera)
	_camera.enabled = true


func _build_overlay() -> void:
	var layer := CanvasLayer.new()
	layer.name = "MigrationHud"
	layer.layer = 20
	add_child(layer)

	var panel := ColorRect.new()
	panel.position = Vector2(14.0, 14.0)
	panel.size = Vector2(530.0, 74.0)
	panel.color = Color(0.04, 0.06, 0.08, 0.92)
	layer.add_child(panel)

	var title := Label.new()
	title.position = Vector2(16.0, 9.0)
	title.text = "GODOT MIGRATION · CAMPUS SLICE"
	title.add_theme_color_override("font_color", Color("f0d54e"))
	title.add_theme_font_size_override("font_size", 17)
	panel.add_child(title)

	_objective_label = Label.new()
	_objective_label.position = Vector2(16.0, 35.0)
	_objective_label.size = Vector2(495.0, 30.0)
	_objective_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_objective_label.text = "验证校园地图与人物控制"
	_objective_label.add_theme_color_override("font_color", Color("f7f0dc"))
	_objective_label.add_theme_font_size_override("font_size", 15)
	panel.add_child(_objective_label)

	_status_label = Label.new()
	_status_label.position = Vector2(14.0, 500.0)
	_status_label.size = Vector2(920.0, 28.0)
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.text = "WASD / 方向键移动 · Shift 加速 · 滚轮缩放 · R 回到人物"
	_status_label.add_theme_color_override("font_color", Color("e8edf1"))
	_status_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
	_status_label.add_theme_constant_override("shadow_offset_x", 2)
	_status_label.add_theme_constant_override("shadow_offset_y", 2)
	_status_label.add_theme_font_size_override("font_size", 14)
	layer.add_child(_status_label)


func _add_landmark(text: String, world_position: Vector2) -> void:
	var marker := Polygon2D.new()
	marker.name = text
	marker.polygon = PackedVector2Array([
		Vector2(0.0, -13.0),
		Vector2(11.0, 8.0),
		Vector2(-11.0, 8.0)
	])
	marker.color = Color("f0d54e")
	marker.position = world_position
	marker.z_index = 3
	add_child(marker)

	var label := Label.new()
	label.text = text
	label.position = Vector2(-54.0, -42.0)
	label.size = Vector2(108.0, 24.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color("fff7df"))
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	marker.add_child(label)


func _apply_state(state: Dictionary) -> void:
	var checkpoint := str(state.get("rpgCheckpoint", "campus_spawn"))
	if checkpoint != _last_checkpoint:
		_last_checkpoint = checkpoint
		_player.global_position = _spawn_for_checkpoint(checkpoint, state)
		_camera.global_position = _player.global_position
	var quest: Dictionary = state.get("quest", {})
	_objective_label.text = str(quest.get("objective", "验证校园地图与人物控制"))
	var theme_mode := str(state.get("themeMode", "normal"))
	var canteen_hunt: Dictionary = state.get("canteenHunt", {})
	var dark := theme_mode == "dark" or (
		bool(canteen_hunt.get("active", false)) and str(canteen_hunt.get("mode", "light")) == "dark"
	)
	_canvas_modulate.color = Color(0.46, 0.55, 0.76, 1.0) if dark else Color.WHITE
	_post_snapshot()


func _spawn_for_checkpoint(checkpoint: String, state: Dictionary) -> Vector2:
	match checkpoint:
		"campus_library_gate":
			return _library_spawn
		"campus_canteen_gate":
			return _canteen_spawn
		_:
			var canteen_hunt: Dictionary = state.get("canteenHunt", {})
			if bool(canteen_hunt.get("active", false)) and str(canteen_hunt.get("phase", "")) in ["tracking", "canteen_reached"]:
				return _canteen_hunt_spawn
			return _spawn


func _on_bridge_command(command: String, payload: Dictionary) -> void:
	match command:
		"input":
			var x := float(payload.get("x", 0.0))
			var y := float(payload.get("y", 0.0))
			_player.set_virtual_direction(Vector2(x, y))
		"set_input_enabled":
			_player.set_input_enabled(bool(payload.get("enabled", true)))
		"recenter":
			_camera.global_position = _player.global_position
		"zoom":
			_adjust_zoom(float(payload.get("delta", 0.0)))


func _on_player_position_changed(_world_position: Vector2) -> void:
	var now := Time.get_ticks_msec()
	if now - _last_snapshot_at >= 120:
		_post_snapshot()


func _adjust_zoom(delta: float) -> void:
	var next_zoom: float = clampf(_camera.zoom.x + delta, 0.65, 1.8)
	_camera.zoom = Vector2.ONE * next_zoom
	_post_snapshot()


func _post_snapshot() -> void:
	_last_snapshot_at = Time.get_ticks_msec()
	WebBridge.post_snapshot(snapshot())


func _point_from(value: Variant, fallback: Vector2) -> Vector2:
	if value is Dictionary:
		return Vector2(float(value.get("x", fallback.x)), float(value.get("y", fallback.y)))
	return fallback
