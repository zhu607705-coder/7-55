extends Node2D

const PROTOCOL_VERSION := "1.0.0"
const SCENE_ID := "theater_interior"
const LOGICAL_VIEWPORT := Vector2(960.0, 540.0)
const PLAYER_SPEED := 210.0
const PLAYER_SCALE := 0.65
const PLAYER_FRAME_MS := 90
const PLAYER_COLLISION_SIZE := Vector2(19.5, 14.625)
const PLAYER_COLLISION_OFFSET := Vector2(0.0, 31.7)
const PLAYER_VISUAL_SIZE := Vector2(96.0, 128.0) * PLAYER_SCALE
const DEBUG_INTERVAL_MS := 180
const SPOTLIGHT_PANEL_CENTER := Vector2(480.0, 270.0)
const SPOTLIGHT_AIM_Y := 360.0
const SPOTLIGHT_AIM_MIN_X := -320.0
const SPOTLIGHT_AIM_MAX_X := 320.0
const SPOTLIGHT_EARLY_EXPOSURE_LIMIT_MS := 450.0

var _runtime_data: Dictionary = {}
var _snapshot: Dictionary = {}
var _snapshot_revision := -1
var _input_blocked := true
var _host_direction := Vector2.ZERO
var _player: CharacterBody2D
var _player_sprite: Sprite2D
var _camera: Camera2D
var _mode_modulate: CanvasModulate
var _gate_body: StaticBody2D
var _gate_shape: CollisionShape2D
var _occlusion_visuals: Array = []
var _facing := "up"
var _walk_frame := 0
var _walk_elapsed_ms := 0
var _has_initial_snapshot := false
var _debug_elapsed_ms := 0
var _js_window
var _message_callback
var _story_announced := false
var _lifecycle_paused := false
var _spotlight_font: Font
var _spotlight_layer: CanvasLayer
var _spotlight_root: Control
var _spotlight_title: Label
var _spotlight_status: Label
var _spotlight_hint: Label
var _spotlight_assist_label: Label
var _spotlight_lock_bar: ColorRect
var _spotlight_time_bar: ColorRect
var _spotlight_fire_button: ColorRect
var _spotlight_fire_label: Label
var _spotlight_path_lines: Array[Line2D] = []
var _spotlight_paper: Polygon2D
var _spotlight_decoy: Polygon2D
var _spotlight_aim_ring: Line2D
var _spotlight_aim_marker: Polygon2D
var _spotlight_beam: Polygon2D
var _spotlight_stage := "idle"
var _spotlight_round_index := -1
var _spotlight_config: Dictionary = {}
var _spotlight_assist: Dictionary = {}
var _spotlight_stage_elapsed_ms := 0.0
var _spotlight_action_elapsed_ms := 0.0
var _spotlight_current_lock_ms := 0.0
var _spotlight_max_lock_ms := 0.0
var _spotlight_first_beam_ms = null
var _spotlight_early_exposure_ms := 0.0
var _spotlight_aim_x := 0.0
var _spotlight_beam_active := false
var _spotlight_beam_activated := false
var _spotlight_pointer_firing := false
var _spotlight_pointer_aiming := false
var _spotlight_last_failure := ""
var _spotlight_target_position := Vector2.ZERO
var _spotlight_decoy_position := Vector2.ZERO
var _spotlight_decoy_visible := false
var _spotlight_reversal_elapsed_ms := 0.0
var _spotlight_reversal_burst_created := false
var _spotlight_reversal_shadow_created := false
var _spotlight_reversal_submitted := false
var _spotlight_shards: Array = []
var _spotlight_shadow: Polygon2D


func _ready() -> void:
	_runtime_data = JSON.parse_string(FileAccess.get_file_as_string("res://data/theater-runtime.json"))
	if _runtime_data.is_empty():
		push_error("Missing theater runtime data.")
		return
	_spotlight_font = load(
		"res://assets/rpg/fonts/fusion_pixel_12px_proportional_zh_hans.ttf"
	) as Font
	_create_world()
	_create_player()
	_install_web_bridge()
	if not OS.has_feature("web"):
		_apply_standalone_snapshot()
	call_deferred("_announce_ready")


func _exit_tree() -> void:
	if _js_window != null and _message_callback != null:
		_js_window.removeEventListener("message", _message_callback)
	_destroy_spotlight_overlay()


func _process(delta: float) -> void:
	if _lifecycle_paused:
		return
	_update_spotlight(delta * 1000.0)


func _physics_process(delta: float) -> void:
	if _player == null:
		return
	var direction := Vector2.ZERO
	if not _input_blocked and _spotlight_stage == "idle":
		direction = _read_keyboard_direction() + _host_direction
		if direction.length_squared() > 1.0:
			direction = direction.normalized()
	_player.velocity = direction * PLAYER_SPEED
	_player.move_and_slide()
	var world: Dictionary = _runtime_data.get("world", {})
	_player.position.x = clampf(_player.position.x, 78.0, float(world.get("width", 1672)) - 78.0)
	_player.position.y = clampf(_player.position.y, 30.0, float(world.get("height", 941)) - 30.0)
	_update_player_pose(direction, delta)
	_update_occlusion()
	_debug_elapsed_ms += int(delta * 1000.0)
	if _debug_elapsed_ms >= DEBUG_INTERVAL_MS:
		_debug_elapsed_ms = 0
		_post_debug_snapshot()


func _unhandled_input(event: InputEvent) -> void:
	if _input_blocked:
		return
	if _spotlight_stage != "idle":
		_handle_spotlight_input(event)
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			_interact_with_nearest_target()
			get_viewport().set_input_as_handled()


func _draw() -> void:
	var selected_item := str(_snapshot.get("selectedItem", ""))
	if selected_item.is_empty():
		return
	var target: Dictionary = {}
	for candidate in _active_targets():
		if str(candidate.get("acceptedItem", "")) == selected_item:
			target = candidate
			break
	if target.is_empty():
		return
	var required_mode := str(target.get("requiredMode", ""))
	var current_mode := str(_snapshot.get("theater", {}).get("mode", "light"))
	if not required_mode.is_empty() and required_mode != current_mode:
		return
	var stand := _target_stand(target)
	var in_position := _player.position.distance_to(stand) <= float(target.get("proximity", 0))
	var color := Color("#7ddca7") if in_position else Color("#5ab2ff")
	var width := float(target.get("dropWidth", target.get("width", float(target.get("proximity", 40)) * 2.0)))
	var height := float(target.get("dropHeight", target.get("height", float(target.get("proximity", 40)) * 2.0)))
	var center := Vector2(float(target.get("x", 0)), float(target.get("y", 0)))
	draw_rect(Rect2(center - Vector2(width, height) / 2.0, Vector2(width, height)), color, false, 4.0)
	draw_arc(stand, 24.0, 0.0, TAU, 32, color, 4.0)
	draw_line(stand, center, color, 3.0)


func _create_world() -> void:
	var world: Dictionary = _runtime_data.get("world", {})
	var background := Sprite2D.new()
	background.name = "ApprovedTheaterPlate"
	background.texture = load("res://assets/rpg/interiors/theater_interior.png")
	background.position = Vector2(float(world.get("width", 1672)) / 2.0, float(world.get("height", 941)) / 2.0)
	background.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	background.z_index = -1000
	add_child(background)

	for occlusion in _runtime_data.get("occlusions", []):
		_create_occlusion_crop(occlusion, background.texture)
	for collision in _runtime_data.get("collisions", []):
		_create_static_rect(collision, false)
	_gate_body = _create_static_rect(_runtime_data.get("gateBlocker", {}), true)
	_gate_shape = _gate_body.get_child(0) as CollisionShape2D

	_mode_modulate = CanvasModulate.new()
	_mode_modulate.name = "TheaterMode"
	add_child(_mode_modulate)


func _create_occlusion_crop(rect: Dictionary, texture: Texture2D) -> void:
	var left := float(rect.get("left", 0))
	var top := float(rect.get("top", 0))
	var right := float(rect.get("right", left))
	var bottom := float(rect.get("bottom", top))
	var bounds := Rect2(left, top, maxf(1.0, right - left), maxf(1.0, bottom - top))
	var sprite := Sprite2D.new()
	sprite.name = "Occlusion_%s" % str(rect.get("id", "crop"))
	sprite.texture = texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.region_enabled = true
	sprite.region_rect = bounds
	sprite.position = bounds.get_center()
	sprite.visible = false
	sprite.z_index = -900
	add_child(sprite)
	_occlusion_visuals.append({
		"sprite": sprite,
		"bounds": bounds,
		"sortY": float(rect.get("sortY", bottom))
	})


func _create_static_rect(rect: Dictionary, disabled: bool) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.name = str(rect.get("id", "GateBlocker" if disabled else "Collision"))
	var shape_node := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	var left := float(rect.get("left", 0))
	var top := float(rect.get("top", 0))
	var right := float(rect.get("right", left))
	var bottom := float(rect.get("bottom", top))
	shape.size = Vector2(maxf(1.0, right - left), maxf(1.0, bottom - top))
	shape_node.shape = shape
	shape_node.position = Vector2((left + right) / 2.0, (top + bottom) / 2.0)
	shape_node.disabled = disabled
	body.add_child(shape_node)
	add_child(body)
	return body


func _create_player() -> void:
	_player = CharacterBody2D.new()
	_player.name = "Player"
	_player.position = _spawn_for_zone("lobby")
	_player.collision_layer = 1
	_player.collision_mask = 1

	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = PLAYER_COLLISION_SIZE
	collision.shape = shape
	collision.position = PLAYER_COLLISION_OFFSET
	_player.add_child(collision)

	_player_sprite = Sprite2D.new()
	_player_sprite.name = "PlayerVisual"
	_player_sprite.scale = Vector2.ONE * PLAYER_SCALE
	_player_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_player.add_child(_player_sprite)
	add_child(_player)
	_apply_player_frame()

	_camera = Camera2D.new()
	_camera.name = "PlayerCamera"
	_camera.position = Vector2(0.0, 24.0)
	_camera.position_smoothing_enabled = true
	_camera.position_smoothing_speed = 8.0
	_camera.limit_left = 0
	_camera.limit_top = 0
	_camera.limit_right = int(_runtime_data.get("world", {}).get("width", 1672))
	_camera.limit_bottom = int(_runtime_data.get("world", {}).get("height", 941))
	_player.add_child(_camera)
	_camera.make_current()


func _install_web_bridge() -> void:
	if not OS.has_feature("web"):
		return
	_js_window = JavaScriptBridge.get_interface("window")
	_message_callback = JavaScriptBridge.create_callback(_on_window_message)
	_js_window.addEventListener("message", _message_callback)


func _announce_ready() -> void:
	_post_message({
		"type": "runtime_ready",
		"sceneId": SCENE_ID,
		"viewport": { "width": int(LOGICAL_VIEWPORT.x), "height": int(LOGICAL_VIEWPORT.y) }
	})
	if not _story_announced:
		_story_announced = true
		_post_intent("rpg_booted", { "scene": SCENE_ID, "checkpoint": "theater_lobby" })
		_post_intent("theater_interior_opened")


func _on_window_message(arguments: Array) -> void:
	if arguments.is_empty():
		return
	var event = arguments[0]
	if event == null:
		return
	var raw := str(event.data)
	var message = JSON.parse_string(raw)
	if not message is Dictionary:
		return
	if str(message.get("source", "")) != "7-55-react":
		return
	if str(message.get("version", "")) != PROTOCOL_VERSION:
		_post_error("protocol_mismatch", "Expected protocol %s." % PROTOCOL_VERSION)
		return
	var message_type := str(message.get("type", ""))
	if message_type == "host_hello":
		_announce_ready()
	elif message_type == "state_snapshot":
		_apply_snapshot(message)
	elif message_type == "host_command":
		_apply_host_command(message.get("command", {}))
	elif message_type == "lifecycle":
		_lifecycle_paused = bool(message.get("paused", false))
		_input_blocked = bool(message.get("paused", false)) or bool(message.get("inputBlocked", false))
		if _input_blocked:
			_host_direction = Vector2.ZERO
			_spotlight_pointer_firing = false


func _apply_snapshot(message: Dictionary) -> void:
	var revision := int(message.get("revision", -1))
	if revision <= _snapshot_revision:
		return
	_snapshot_revision = revision
	_snapshot = message.get("snapshot", {})
	_input_blocked = bool(_snapshot.get("inputBlocked", false))
	if not _has_initial_snapshot:
		_has_initial_snapshot = true
		var theater: Dictionary = _snapshot.get("theater", {})
		var spawn_zone := str(_snapshot.get("spawnZone", ""))
		if spawn_zone != "lobby" and spawn_zone != "auditorium" and spawn_zone != "stage":
			spawn_zone = _legacy_spawn_zone(
				str(theater.get("phase", "entry_ticket")),
				bool(theater.get("admitted", false))
			)
		_player.position = _spawn_for_zone(spawn_zone)
	_sync_from_snapshot()


func _apply_standalone_snapshot() -> void:
	_apply_snapshot({
		"revision": 0,
		"snapshot": {
			"checkpoint": "theater_lobby",
			"spawnZone": "lobby",
			"inputBlocked": false,
			"selectedItem": "",
			"theater": {
				"phase": "entry_ticket",
				"admitted": true,
				"mode": "light",
				"collectedProgramIds": []
			}
		}
	})


func _sync_from_snapshot() -> void:
	var theater: Dictionary = _snapshot.get("theater", {})
	var dark_mode := str(theater.get("mode", "light")) == "dark"
	_mode_modulate.color = Color(0.42, 0.46, 0.58, 1.0) if dark_mode else Color.WHITE
	if _gate_shape != null:
		_gate_shape.set_deferred("disabled", bool(theater.get("admitted", false)))
	_sync_spotlight_from_snapshot(theater)
	queue_redraw()
	_post_debug_snapshot()


func _apply_host_command(command: Dictionary) -> void:
	var name := str(command.get("name", ""))
	var payload: Dictionary = command.get("payload", {})
	if name == "rpg_direction_changed":
		if _spotlight_stage == "idle":
			_host_direction = Vector2(float(payload.get("x", 0)), float(payload.get("y", 0)))
	elif name == "rpg_interact":
		if _spotlight_stage == "idle":
			_interact_with_nearest_target()
	elif name == "rpg_inventory_drop_requested":
		_handle_inventory_drop(payload)
	elif name == "rpg_inventory_drag_started" or name == "rpg_inventory_drag_ended":
		queue_redraw()


func _read_keyboard_direction() -> Vector2:
	var direction := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		direction.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		direction.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		direction.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		direction.y += 1.0
	return direction.normalized() if direction.length_squared() > 1.0 else direction


func _update_player_pose(direction: Vector2, delta: float) -> void:
	if direction.length_squared() <= 0.001:
		_walk_frame = 0
		_walk_elapsed_ms = 0
		_apply_player_frame()
		return
	if absf(direction.x) > absf(direction.y):
		_facing = "side"
		_player_sprite.flip_h = direction.x < 0.0
	else:
		_facing = "up" if direction.y < 0.0 else "down"
		_player_sprite.flip_h = false
	_walk_elapsed_ms += int(delta * 1000.0)
	_walk_frame = int(_walk_elapsed_ms / PLAYER_FRAME_MS) % 4
	_apply_player_frame()


func _apply_player_frame() -> void:
	var path := "res://assets/rpg/player/player_%s_%d.png" % [_facing, _walk_frame]
	_player_sprite.texture = load(path)
	_player.z_index = int(_player.position.y + 120.0)


func _update_occlusion() -> void:
	if _player == null:
		return
	var player_bounds := Rect2(_player.position - PLAYER_VISUAL_SIZE / 2.0, PLAYER_VISUAL_SIZE)
	var foot_y := _player.position.y + PLAYER_COLLISION_OFFSET.y + PLAYER_COLLISION_SIZE.y / 2.0
	for entry in _occlusion_visuals:
		var sprite: Sprite2D = entry.get("sprite")
		var bounds: Rect2 = entry.get("bounds")
		var horizontal_overlap := player_bounds.end.x > bounds.position.x and player_bounds.position.x < bounds.end.x
		var behind := horizontal_overlap and foot_y < float(entry.get("sortY", bounds.end.y)) - 1.0
		sprite.visible = behind
		sprite.z_index = _player.z_index + 2 if behind else -900
		sprite.modulate.a = 0.52 if behind and player_bounds.intersects(bounds) else 1.0


func _sync_spotlight_from_snapshot(theater: Dictionary) -> void:
	var phase := str(theater.get("phase", "entry_ticket"))
	var round_index := int(theater.get("spotlightRound", 0))
	var mistakes := int(theater.get("spotlightMistakes", 0))
	if phase == "spotlight_hunt":
		if _spotlight_stage == "idle":
			_begin_spotlight_round(round_index)
		elif _spotlight_stage == "awaiting":
			if round_index > _spotlight_round_index:
				_show_spotlight_hit(false)
			elif mistakes > int(_spotlight_assist.get("knownMistakes", mistakes)):
				_show_spotlight_miss()
		_spotlight_assist["knownMistakes"] = mistakes
		return
	if phase == "reversal":
		if _spotlight_stage == "awaiting":
			_show_spotlight_hit(true)
		elif _spotlight_stage != "hit" and _spotlight_stage != "reversal":
			_begin_reversal()
		return
	if phase != "spotlight_hunt" and phase != "reversal":
		_destroy_spotlight_overlay()


func _begin_spotlight_round(round_index: int) -> void:
	var spotlight: Dictionary = _runtime_data.get("spotlight", {})
	var rounds: Array = spotlight.get("rounds", [])
	if round_index < 0 or round_index >= rounds.size():
		_post_error("spotlight_round_missing", "No authored spotlight round %d." % round_index)
		return
	_destroy_spotlight_overlay()
	_spotlight_round_index = round_index
	_spotlight_config = rounds[round_index]
	var mistakes := int(_snapshot.get("theater", {}).get("spotlightMistakes", 0))
	var assist_threshold := int(spotlight.get("assistMistakes", 3))
	_spotlight_assist = (
		spotlight.get("failureAssist", {}).duplicate(true)
		if mistakes >= assist_threshold
		else spotlight.get("baseAssist", {}).duplicate(true)
	)
	_spotlight_assist["knownMistakes"] = mistakes
	_spotlight_stage = "preview"
	_spotlight_stage_elapsed_ms = 0.0
	_spotlight_action_elapsed_ms = 0.0
	_spotlight_current_lock_ms = 0.0
	_spotlight_max_lock_ms = 0.0
	_spotlight_first_beam_ms = null
	_spotlight_early_exposure_ms = 0.0
	_spotlight_aim_x = 0.0
	_spotlight_beam_active = false
	_spotlight_beam_activated = false
	_spotlight_pointer_firing = false
	_spotlight_pointer_aiming = false
	_spotlight_last_failure = ""
	_create_spotlight_overlay()
	_set_spotlight_preview_visuals()
	_post_debug_snapshot()


func _create_spotlight_overlay() -> void:
	_spotlight_layer = CanvasLayer.new()
	_spotlight_layer.name = "SpotlightHuntLayer"
	_spotlight_layer.layer = 100
	add_child(_spotlight_layer)
	_spotlight_root = Control.new()
	_spotlight_root.name = "SpotlightHunt"
	_spotlight_root.position = Vector2.ZERO
	_spotlight_root.size = LOGICAL_VIEWPORT
	_spotlight_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_spotlight_layer.add_child(_spotlight_root)

	_add_spotlight_rect(Vector2(0, 0), LOGICAL_VIEWPORT, Color(0.015, 0.02, 0.07, 0.78))
	_add_spotlight_rect(Vector2(60, 55), Vector2(840, 430), Color("#080b18"), Color("#6dcce5"), 4)
	_add_spotlight_rect(Vector2(120, 161), Vector2(720, 238), Color("#10192a"), Color("#415d73"), 2)
	_spotlight_title = _add_spotlight_label(
		Vector2(120, 72),
		Vector2(720, 32),
		"第 %d / 3 轮 · 观察" % (_spotlight_round_index + 1),
		21,
		Color("#fff4dc")
	)
	_spotlight_status = _add_spotlight_label(
		Vector2(120, 113),
		Vector2(720, 48),
		"深色模式：观察纸条的移动路径。",
		16,
		Color("#8fe8ff")
	)
	_spotlight_hint = _add_spotlight_label(
		Vector2(140, 398),
		Vector2(680, 28),
		"记住完整尾迹与最后灯区。",
		14,
		Color("#8fe8ff")
	)
	_spotlight_assist_label = _add_spotlight_label(
		Vector2(160, 142),
		Vector2(640, 24),
		"辅助已开启：残影延长，命中范围扩大。",
		12,
		Color("#ffe699")
	)
	_spotlight_assist_label.visible = bool(_spotlight_assist.get("active", false))

	var lock_label := _add_spotlight_label(
		Vector2(130, 435),
		Vector2(120, 22),
		"连续锁定",
		13,
		Color("#bcefff")
	)
	lock_label.name = "SpotlightLockLabel"
	lock_label.visible = false
	var lock_track := _add_spotlight_rect(Vector2(288, 443), Vector2(270, 10), Color("#26313e"))
	lock_track.name = "SpotlightLockTrack"
	lock_track.visible = false
	var time_track := _add_spotlight_rect(Vector2(288, 465), Vector2(270, 8), Color("#26313e"))
	time_track.name = "SpotlightTimeTrack"
	time_track.visible = false
	_spotlight_lock_bar = _add_spotlight_rect(Vector2(288, 443), Vector2(0, 10), Color("#66e4ff"))
	_spotlight_lock_bar.visible = false
	_spotlight_time_bar = _add_spotlight_rect(Vector2(288, 465), Vector2(270, 8), Color("#ffdf73"))
	_spotlight_time_bar.visible = false
	_spotlight_fire_button = _add_spotlight_rect(
		Vector2(681, 434),
		Vector2(150, 48),
		Color("#25384a"),
		Color("#b9d7e8"),
		3
	)
	_spotlight_fire_button.visible = false
	_spotlight_fire_label = _add_spotlight_label(
		Vector2(681, 445),
		Vector2(150, 28),
		"按住照射",
		16,
		Color("#f4fbff")
	)
	_spotlight_fire_label.visible = false

	var lane_positions := {
		"left": 250.0,
		"center": 480.0,
		"right": 710.0
	}
	for lane in lane_positions:
		var lane_circle := _create_circle_line(
			Vector2(float(lane_positions[lane]), SPOTLIGHT_AIM_Y),
			49.0,
			Color(0.55, 0.51, 0.31, 0.34),
			2.0
		)
		_spotlight_root.add_child(lane_circle)
		var lane_text := "左" if lane == "left" else "中" if lane == "center" else "右"
		_add_spotlight_label(
			Vector2(float(lane_positions[lane]) - 35.0, 384),
			Vector2(70, 20),
			lane_text,
			13,
			Color("#8f927f")
		)

	_create_spotlight_paths()
	_spotlight_paper = _create_spotlight_paper(Color("#90efff"))
	_spotlight_root.add_child(_spotlight_paper)
	var path_points: Array = _spotlight_config.get("pathPoints", [])
	_spotlight_target_position = _spotlight_screen_point(_sample_spotlight_path(path_points, 0.0))
	_spotlight_paper.position = _spotlight_target_position
	var decoy_points: Array = _spotlight_config.get("decoyPathPoints", [])
	if not decoy_points.is_empty():
		_spotlight_decoy = _create_spotlight_paper(Color(0.42, 0.51, 0.56, 0.55))
		_spotlight_root.add_child(_spotlight_decoy)
		_spotlight_decoy_position = _spotlight_screen_point(_sample_spotlight_path(decoy_points, 0.0))
		_spotlight_decoy.position = _spotlight_decoy_position
		_spotlight_decoy_visible = true

	_spotlight_beam = Polygon2D.new()
	_spotlight_beam.color = Color(1.0, 0.91, 0.6, 0.3)
	var beam_radius := _spotlight_radius()
	_spotlight_beam.polygon = PackedVector2Array([
		Vector2(-15.0, 165.0),
		Vector2(15.0, 165.0),
		Vector2(beam_radius, SPOTLIGHT_AIM_Y),
		Vector2(-beam_radius, SPOTLIGHT_AIM_Y)
	])
	_spotlight_beam.position = Vector2(480.0, 0.0)
	_spotlight_beam.visible = false
	_spotlight_root.add_child(_spotlight_beam)
	_spotlight_aim_ring = _create_circle_line(
		Vector2.ZERO,
		_spotlight_radius(),
		Color(1.0, 0.91, 0.6, 1.0),
		3.0
	)
	_spotlight_aim_ring.position = Vector2(480.0, SPOTLIGHT_AIM_Y)
	_spotlight_aim_ring.visible = false
	_spotlight_root.add_child(_spotlight_aim_ring)
	_spotlight_aim_marker = Polygon2D.new()
	_spotlight_aim_marker.polygon = PackedVector2Array([
		Vector2(-5, -5), Vector2(5, -5), Vector2(5, 5), Vector2(-5, 5)
	])
	_spotlight_aim_marker.color = Color("#fff2aa")
	_spotlight_aim_marker.position = Vector2(480.0, SPOTLIGHT_AIM_Y)
	_spotlight_aim_marker.visible = false
	_spotlight_root.add_child(_spotlight_aim_marker)


func _create_spotlight_paths() -> void:
	var path_points: Array = _spotlight_config.get("pathPoints", [])
	var main_line := Line2D.new()
	main_line.width = 6.0
	main_line.default_color = Color(0.38, 0.87, 1.0, 0.82)
	for sample_index in range(31):
		main_line.add_point(_spotlight_screen_point(
			_sample_spotlight_path(path_points, float(sample_index) / 30.0)
		))
	_spotlight_root.add_child(main_line)
	_spotlight_path_lines.append(main_line)
	var decoy_points: Array = _spotlight_config.get("decoyPathPoints", [])
	if decoy_points.is_empty():
		return
	for sample_index in range(30):
		if sample_index % 5 >= 2:
			continue
		var segment := Line2D.new()
		segment.width = 3.0
		segment.default_color = Color(0.48, 0.58, 0.64, 0.48)
		segment.add_point(_spotlight_screen_point(
			_sample_spotlight_path(decoy_points, float(sample_index) / 30.0)
		))
		segment.add_point(_spotlight_screen_point(
			_sample_spotlight_path(decoy_points, float(sample_index + 1) / 30.0)
		))
		_spotlight_root.add_child(segment)
		_spotlight_path_lines.append(segment)


func _set_spotlight_preview_visuals() -> void:
	for line in _spotlight_path_lines:
		line.visible = true
	_spotlight_paper.visible = true
	_spotlight_paper.modulate.a = 1.0
	if _spotlight_decoy != null:
		_spotlight_decoy.visible = true
		_spotlight_decoy.modulate.a = 1.0
	_spotlight_aim_ring.visible = false
	_spotlight_aim_marker.visible = false
	_spotlight_beam.visible = false
	_set_spotlight_action_controls_visible(false)


func _prepare_spotlight_action() -> void:
	if _spotlight_stage != "preview":
		return
	_spotlight_stage = "ready"
	_spotlight_stage_elapsed_ms = 0.0
	_post_intent("rpg_theater_mode_requested", { "mode": "light" })
	_spotlight_title.text = "第 %d / 3 轮 · 预置" % (_spotlight_round_index + 1)
	_spotlight_status.text = "预置追光灯"
	_spotlight_status.add_theme_color_override("font_color", Color("#ffe49a"))
	_spotlight_hint.text = "拖动下方滑轨，或按 ← / → 移动。"
	_spotlight_hint.add_theme_color_override("font_color", Color("#fff3bd"))
	for line in _spotlight_path_lines:
		line.visible = false
	_spotlight_paper.visible = true
	_spotlight_paper.modulate.a = 0.0
	if _spotlight_decoy != null:
		_spotlight_decoy.visible = true
		_spotlight_decoy.modulate.a = 0.0
	_spotlight_aim_ring.visible = true
	_spotlight_aim_marker.visible = true
	_set_spotlight_action_controls_visible(true)
	_set_spotlight_aim(_spotlight_aim_x)


func _start_spotlight_tracking() -> void:
	if _spotlight_stage != "ready":
		return
	_spotlight_stage = "tracking"
	_spotlight_stage_elapsed_ms = 0.0
	_spotlight_action_elapsed_ms = 0.0
	_spotlight_current_lock_ms = 0.0
	_spotlight_max_lock_ms = 0.0
	_spotlight_first_beam_ms = null
	_spotlight_early_exposure_ms = 0.0
	_spotlight_beam_activated = false
	_spotlight_title.text = "第 %d / 3 轮 · 锁定" % (_spotlight_round_index + 1)
	_spotlight_status.text = "浅色模式：等纸条进入光圈后持续照射。"
	_spotlight_status.add_theme_color_override("font_color", Color("#ffe49a"))
	_spotlight_hint.text = "左右移动追光灯；按住照射键或空格完成锁定。"
	_spotlight_paper.visible = true
	_spotlight_paper.modulate.a = 1.0
	if _spotlight_decoy != null:
		_spotlight_decoy.visible = true
		_spotlight_decoy.modulate.a = 1.0
	_spotlight_decoy_visible = _spotlight_decoy != null


func _update_spotlight(delta_ms: float) -> void:
	if _spotlight_stage == "idle" or _spotlight_root == null:
		return
	if _input_blocked:
		_spotlight_pointer_firing = false
	if _spotlight_stage == "reversal":
		_update_reversal(delta_ms)
		return
	_spotlight_stage_elapsed_ms += delta_ms
	if _spotlight_stage == "preview":
		var preview_ms := (
			float(_spotlight_config.get("previewMs", 1000))
			+ float(_spotlight_assist.get("previewBonusMs", 0))
		)
		var progress := clampf(_spotlight_stage_elapsed_ms / maxf(1.0, preview_ms), 0.0, 1.0)
		_update_spotlight_papers(progress, progress)
		if progress >= 1.0:
			_prepare_spotlight_action()
		return
	if _spotlight_stage == "ready":
		_update_spotlight_aim_from_keyboard(delta_ms)
		_update_spotlight_beam(false)
		var ready_ms := float(_runtime_data.get("spotlight", {}).get("readyMs", 900))
		if _spotlight_stage_elapsed_ms >= ready_ms:
			_start_spotlight_tracking()
		return
	if _spotlight_stage == "tracking":
		_update_spotlight_tracking(delta_ms)
		return
	if _spotlight_stage == "miss":
		var retry_ms := float(_runtime_data.get("spotlight", {}).get("retryMs", 1100))
		if _spotlight_stage_elapsed_ms >= retry_ms:
			_begin_spotlight_round(int(_snapshot.get("theater", {}).get("spotlightRound", 0)))
		return
	if _spotlight_stage == "hit":
		var wait_ms := (
			80.0
			if str(_snapshot.get("theater", {}).get("phase", "")) == "reversal"
			else float(_runtime_data.get("spotlight", {}).get("hitMs", 350))
		)
		if _spotlight_stage_elapsed_ms >= wait_ms:
			if str(_snapshot.get("theater", {}).get("phase", "")) == "reversal":
				_begin_reversal()
			else:
				_begin_spotlight_round(int(_snapshot.get("theater", {}).get("spotlightRound", 0)))


func _update_spotlight_tracking(delta_ms: float) -> void:
	_update_spotlight_aim_from_keyboard(delta_ms)
	var action_ms := float(_spotlight_config.get("actionMs", 1))
	_spotlight_action_elapsed_ms = minf(action_ms, _spotlight_action_elapsed_ms + delta_ms)
	var progress := clampf(_spotlight_action_elapsed_ms / maxf(1.0, action_ms), 0.0, 1.0)
	var motion_progress := clampf(progress / 0.72, 0.0, 1.0)
	_update_spotlight_papers(motion_progress, clampf(progress / 0.78, 0.0, 1.0))
	_spotlight_beam_active = not _input_blocked and (
		_spotlight_pointer_firing or Input.is_key_pressed(KEY_SPACE)
	)
	_update_spotlight_beam(_spotlight_beam_active)
	if _spotlight_beam_active:
		_spotlight_beam_activated = true
		if _spotlight_first_beam_ms == null:
			_spotlight_first_beam_ms = _spotlight_action_elapsed_ms
	var aim_position := Vector2(480.0 + _spotlight_aim_x, SPOTLIGHT_AIM_Y)
	var target_overlap := _spotlight_beam_active \
		and aim_position.distance_to(_spotlight_target_position) <= _spotlight_radius() + 12.0
	var decoy_overlap := _spotlight_beam_active \
		and _spotlight_decoy_visible \
		and aim_position.distance_to(_spotlight_decoy_position) <= _spotlight_radius() + 10.0
	if _spotlight_beam_active and not target_overlap and not decoy_overlap and progress < 0.68:
		_spotlight_early_exposure_ms += delta_ms
	else:
		_spotlight_early_exposure_ms = maxf(0.0, _spotlight_early_exposure_ms - delta_ms * 1.5)
	if _spotlight_early_exposure_ms >= SPOTLIGHT_EARLY_EXPOSURE_LIMIT_MS:
		_spotlight_last_failure = "early"
		_submit_spotlight_attempt()
		return
	if decoy_overlap and not target_overlap:
		_spotlight_current_lock_ms = 0.0
		_spotlight_status.text = "断裂尾迹是假残影。"
		_spotlight_status.add_theme_color_override("font_color", Color("#ffb3b3"))
	elif target_overlap:
		_spotlight_current_lock_ms += delta_ms
		_spotlight_status.text = "锁定中，保持照射。"
		_spotlight_status.add_theme_color_override("font_color", Color("#9af3ff"))
	elif _spotlight_current_lock_ms > 0.0:
		_spotlight_current_lock_ms = maxf(0.0, _spotlight_current_lock_ms - delta_ms * 2.4)
		_spotlight_status.text = "光圈脱离纸条，重新锁定。"
		_spotlight_status.add_theme_color_override("font_color", Color("#ffd49a"))
	_spotlight_max_lock_ms = maxf(_spotlight_max_lock_ms, _spotlight_current_lock_ms)
	var required_lock_ms := _spotlight_required_lock_ms()
	_spotlight_lock_bar.size.x = 270.0 * clampf(
		_spotlight_current_lock_ms / maxf(1.0, required_lock_ms),
		0.0,
		1.0
	)
	_spotlight_time_bar.size.x = 270.0 * (1.0 - progress)
	if _spotlight_current_lock_ms >= required_lock_ms:
		_submit_spotlight_attempt()
	elif _spotlight_action_elapsed_ms >= action_ms:
		_spotlight_last_failure = "timeout"
		_submit_spotlight_attempt()


func _update_spotlight_papers(main_progress: float, decoy_progress: float) -> void:
	var path_points: Array = _spotlight_config.get("pathPoints", [])
	_spotlight_target_position = _spotlight_screen_point(_sample_spotlight_path(path_points, main_progress))
	if _spotlight_paper != null:
		_spotlight_paper.position = _spotlight_target_position
		_spotlight_paper.rotation = deg_to_rad(main_progress * 220.0)
	var decoy_points: Array = _spotlight_config.get("decoyPathPoints", [])
	_spotlight_decoy_visible = not decoy_points.is_empty() and _spotlight_decoy != null
	if _spotlight_decoy_visible:
		_spotlight_decoy_position = _spotlight_screen_point(
			_sample_spotlight_path(decoy_points, decoy_progress)
		)
		_spotlight_decoy.position = _spotlight_decoy_position
		_spotlight_decoy.rotation = deg_to_rad(-decoy_progress * 170.0)


func _update_spotlight_aim_from_keyboard(delta_ms: float) -> void:
	if _input_blocked:
		return
	var direction := float(
		int(Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D))
		- int(Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A))
	)
	if direction != 0.0:
		_set_spotlight_aim(_spotlight_aim_x + direction * delta_ms * 0.38)


func _handle_spotlight_input(event: InputEvent) -> void:
	if _spotlight_stage != "ready" and _spotlight_stage != "tracking":
		_spotlight_pointer_firing = false
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if _spotlight_fire_rect().has_point(event.position):
				_spotlight_pointer_firing = true
			elif _spotlight_aim_rect().has_point(event.position):
				_spotlight_pointer_aiming = true
				_set_spotlight_aim(event.position.x - 480.0)
		else:
			_spotlight_pointer_firing = false
			_spotlight_pointer_aiming = false
	elif event is InputEventMouseMotion and _spotlight_pointer_aiming:
		_set_spotlight_aim(event.position.x - 480.0)
	elif event is InputEventScreenTouch:
		if event.pressed:
			if _spotlight_fire_rect().has_point(event.position):
				_spotlight_pointer_firing = true
			elif _spotlight_aim_rect().has_point(event.position):
				_spotlight_pointer_aiming = true
				_set_spotlight_aim(event.position.x - 480.0)
		else:
			_spotlight_pointer_firing = false
			_spotlight_pointer_aiming = false
	elif event is InputEventScreenDrag and _spotlight_pointer_aiming:
		_set_spotlight_aim(event.position.x - 480.0)


func _submit_spotlight_attempt() -> void:
	if _spotlight_stage != "tracking":
		return
	_spotlight_stage = "awaiting"
	_spotlight_pointer_firing = false
	_spotlight_pointer_aiming = false
	_spotlight_beam_active = false
	_update_spotlight_beam(false)
	_post_intent("rpg_theater_spotlight_attempt", {
		"round": _spotlight_round_index,
		"lane": _spotlight_aim_lane(),
		"maxContinuousLockMs": snappedf(_spotlight_max_lock_ms, 0.01),
		"beamActivated": _spotlight_beam_activated,
		"firstBeamAtMs": (
			null
			if _spotlight_first_beam_ms == null
			else snappedf(float(_spotlight_first_beam_ms), 0.01)
		),
		"actionMs": int(_spotlight_config.get("actionMs", 0)),
		"submittedAtMs": snappedf(_spotlight_action_elapsed_ms, 0.01)
	})


func _show_spotlight_hit(final_hit: bool) -> void:
	_spotlight_stage = "hit"
	_spotlight_stage_elapsed_ms = 0.0
	_spotlight_beam_active = false
	_update_spotlight_beam(false)
	var hit_count := int(_snapshot.get("theater", {}).get("spotlightRound", 0))
	_spotlight_title.text = "第 %d / 3 轮 · 命中" % hit_count
	_spotlight_status.text = "追光命中。已命中 %d / 3" % hit_count
	_spotlight_status.add_theme_color_override("font_color", Color("#fff4b2"))
	_spotlight_hint.text = "连续锁定完成。" if not final_hit else "第三次锁定完成。"
	_spotlight_lock_bar.size.x = 270.0
	_spotlight_lock_bar.color = Color("#ffe487")


func _show_spotlight_miss() -> void:
	_spotlight_stage = "miss"
	_spotlight_stage_elapsed_ms = 0.0
	_spotlight_beam_active = false
	_update_spotlight_beam(false)
	var hint: String = str({
		"wrong_lane": "灯位不符。重新观察纸条最后进入的灯区。",
		"beam_not_activated": "没有开启追光灯。纸条进入灯区时按住照射。",
		"early": "照射开启过早，纸条在进入灯区前改变了路线。",
		"late": "照射开启过晚，纸条已经离开灯区。",
		"interrupted": "照射中断。需要保持光圈与纸条连续重合。",
		"timeout": "纸条已经离开舞台，本轮重新开始。"
	}.get(_spotlight_last_failure, "检查灯位、开启时机和连续照射时间。"))
	_spotlight_title.text = "第 %d / 3 轮 · 重试" % (_spotlight_round_index + 1)
	_spotlight_status.text = "它避开了追光灯。\n%s" % str(hint)
	_spotlight_status.add_theme_color_override("font_color", Color("#ff9f9f"))
	_spotlight_hint.text = "保持已完成轮次，重新观察本轮。"


func _begin_reversal() -> void:
	_destroy_spotlight_overlay()
	_spotlight_stage = "reversal"
	_spotlight_reversal_elapsed_ms = 0.0
	_spotlight_reversal_burst_created = false
	_spotlight_reversal_shadow_created = false
	_spotlight_reversal_submitted = false
	_spotlight_layer = CanvasLayer.new()
	_spotlight_layer.name = "TheaterReversalLayer"
	_spotlight_layer.layer = 100
	add_child(_spotlight_layer)
	_spotlight_root = Control.new()
	_spotlight_root.size = LOGICAL_VIEWPORT
	_spotlight_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_spotlight_layer.add_child(_spotlight_root)
	_add_spotlight_rect(Vector2.ZERO, LOGICAL_VIEWPORT, Color(0.035, 0.012, 0.02, 0.9))
	_add_spotlight_rect(Vector2(60, 55), Vector2(840, 430), Color("#09060a"), Color("#c05260"), 4)
	_spotlight_status = _add_spotlight_label(
		Vector2(120, 100),
		Vector2(720, 46),
		"它把被抓也写进了流程。",
		19,
		Color("#ffadb5")
	)
	_spotlight_paper = _create_spotlight_paper(Color("#ffe8d0"))
	_spotlight_paper.scale = Vector2.ONE * 1.65
	_spotlight_paper.position = Vector2(480, 290)
	_spotlight_root.add_child(_spotlight_paper)
	for crack_points in [
		[Vector2(480, 272), Vector2(472, 289), Vector2(486, 300), Vector2(477, 316)],
		[Vector2(480, 287), Vector2(498, 280)],
		[Vector2(482, 301), Vector2(500, 311)]
	]:
		var crack := Line2D.new()
		crack.width = 2.0
		crack.default_color = Color("#8c7d77")
		for point in crack_points:
			crack.add_point(point)
		crack.name = "ReversalCrack"
		_spotlight_root.add_child(crack)


func _update_reversal(delta_ms: float) -> void:
	_spotlight_reversal_elapsed_ms += delta_ms
	if _spotlight_reversal_elapsed_ms >= 370.0 and not _spotlight_reversal_burst_created:
		_spotlight_reversal_burst_created = true
		if _spotlight_paper != null:
			_spotlight_paper.visible = false
		for child in _spotlight_root.get_children():
			if child.name == "ReversalCrack":
				child.visible = false
		for index in range(8):
			var shard := _create_spotlight_paper(Color("#e7dbc8"))
			shard.scale = Vector2.ONE * (0.34 + float(index % 3) * 0.08)
			shard.position = Vector2(480, 290)
			shard.rotation = deg_to_rad(float(index * 27))
			_spotlight_root.add_child(shard)
			var angle := deg_to_rad(-155.0 + float(index) * 44.0)
			_spotlight_shards.append({
				"node": shard,
				"velocity": Vector2(cos(angle), sin(angle)) * (100.0 + float(index % 3) * 35.0),
				"age": 0.0
			})
	if _spotlight_reversal_burst_created:
		for shard_entry in _spotlight_shards:
			var shard: Polygon2D = shard_entry.get("node")
			var age := float(shard_entry.get("age", 0.0)) + delta_ms
			shard_entry["age"] = age
			var velocity: Vector2 = shard_entry.get("velocity", Vector2.ZERO)
			shard.position += velocity * delta_ms / 1000.0
			shard.position.y += 150.0 * pow(delta_ms / 1000.0, 2)
			shard.rotation += delta_ms * 0.006
			shard.modulate.a = maxf(0.0, 1.0 - age / 450.0)
	if _spotlight_reversal_elapsed_ms >= 770.0 and not _spotlight_reversal_shadow_created:
		_spotlight_reversal_shadow_created = true
		_spotlight_shadow = _create_spotlight_paper(Color(0.14, 0.2, 0.27, 0.74))
		_spotlight_shadow.position = Vector2(390, 310)
		_spotlight_root.add_child(_spotlight_shadow)
	if _spotlight_shadow != null:
		var shadow_progress := clampf((_spotlight_reversal_elapsed_ms - 770.0) / 560.0, 0.0, 1.0)
		_spotlight_shadow.position = Vector2(390, 310).lerp(Vector2(860, 225), shadow_progress)
		_spotlight_shadow.rotation = deg_to_rad(240.0 * shadow_progress)
		_spotlight_shadow.modulate.a = 1.0 - shadow_progress
	var reversal_ms := float(_runtime_data.get("spotlight", {}).get("reversalMs", 1320))
	if _spotlight_reversal_elapsed_ms >= reversal_ms and not _spotlight_reversal_submitted:
		_spotlight_reversal_submitted = true
		_post_intent("rpg_theater_reversal_complete_requested")


func _destroy_spotlight_overlay() -> void:
	if _spotlight_layer != null and is_instance_valid(_spotlight_layer):
		_spotlight_layer.queue_free()
	_spotlight_layer = null
	_spotlight_root = null
	_spotlight_title = null
	_spotlight_status = null
	_spotlight_hint = null
	_spotlight_assist_label = null
	_spotlight_lock_bar = null
	_spotlight_time_bar = null
	_spotlight_fire_button = null
	_spotlight_fire_label = null
	_spotlight_path_lines.clear()
	_spotlight_paper = null
	_spotlight_decoy = null
	_spotlight_aim_ring = null
	_spotlight_aim_marker = null
	_spotlight_beam = null
	_spotlight_shadow = null
	_spotlight_shards.clear()
	_spotlight_stage = "idle"
	_spotlight_round_index = -1
	_spotlight_pointer_firing = false
	_spotlight_pointer_aiming = false
	_spotlight_beam_active = false
	_spotlight_decoy_visible = false


func _set_spotlight_action_controls_visible(visible: bool) -> void:
	for node_name in ["SpotlightLockLabel", "SpotlightLockTrack", "SpotlightTimeTrack"]:
		var node := _spotlight_root.get_node_or_null(node_name)
		if node != null:
			node.visible = visible
	_spotlight_lock_bar.visible = visible
	_spotlight_time_bar.visible = visible
	_spotlight_fire_button.visible = visible
	_spotlight_fire_label.visible = visible


func _set_spotlight_aim(value: float) -> void:
	_spotlight_aim_x = clampf(value, SPOTLIGHT_AIM_MIN_X, SPOTLIGHT_AIM_MAX_X)
	var center := Vector2(480.0 + _spotlight_aim_x, SPOTLIGHT_AIM_Y)
	_spotlight_aim_ring.position = center
	_spotlight_aim_marker.position = center
	_spotlight_beam.position.x = center.x
	_update_spotlight_beam(_spotlight_beam_active)


func _update_spotlight_beam(active: bool) -> void:
	if _spotlight_beam == null:
		return
	var beam_visible := _spotlight_stage == "tracking" or _spotlight_stage == "ready"
	var beam_alpha := 1.0 if active else 0.2
	if not is_equal_approx(_spotlight_beam.modulate.a, beam_alpha):
		_spotlight_beam.modulate.a = beam_alpha
	if _spotlight_beam.visible != beam_visible:
		_spotlight_beam.visible = beam_visible
	if _spotlight_aim_ring != null:
		var ring_alpha := 0.98 if active else 0.58
		if not is_equal_approx(_spotlight_aim_ring.modulate.a, ring_alpha):
			_spotlight_aim_ring.modulate.a = ring_alpha


func _spotlight_radius() -> float:
	return float(_spotlight_config.get("beamRadius", 50)) \
		* float(_spotlight_assist.get("radiusScale", 1.0))


func _spotlight_required_lock_ms() -> float:
	return float(_spotlight_config.get("requiredLockMs", 300)) \
		* float(_spotlight_assist.get("lockScale", 1.0))


func _spotlight_aim_lane() -> String:
	if _spotlight_aim_x <= -112.0:
		return "left"
	if _spotlight_aim_x >= 112.0:
		return "right"
	return "center"


func _spotlight_screen_point(local_point: Vector2) -> Vector2:
	return SPOTLIGHT_PANEL_CENTER + local_point


func _sample_spotlight_path(raw_points: Array, progress: float) -> Vector2:
	if raw_points.is_empty():
		return Vector2.ZERO
	var points: Array[Vector2] = []
	for raw_point in raw_points:
		points.append(Vector2(float(raw_point.get("x", 0)), float(raw_point.get("y", 0))))
	if points.size() == 1:
		return points[0]
	var scaled := clampf(progress, 0.0, 1.0) * float(points.size() - 1)
	var segment := mini(int(floor(scaled)), points.size() - 2)
	var t := scaled - float(segment)
	var p0 := points[maxi(segment - 1, 0)]
	var p1 := points[segment]
	var p2 := points[segment + 1]
	var p3 := points[mini(segment + 2, points.size() - 1)]
	return 0.5 * (
		2.0 * p1
		+ (-p0 + p2) * t
		+ (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t * t
		+ (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t * t * t
	)


func _add_spotlight_rect(
	position: Vector2,
	size: Vector2,
	color: Color,
	border_color: Color = Color.TRANSPARENT,
	border_width: int = 0
) -> ColorRect:
	if border_width > 0:
		var border := ColorRect.new()
		border.position = position - Vector2.ONE * float(border_width)
		border.size = size + Vector2.ONE * float(border_width * 2)
		border.color = border_color
		border.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_spotlight_root.add_child(border)
	var rect := ColorRect.new()
	rect.position = position
	rect.size = size
	rect.color = color
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_spotlight_root.add_child(rect)
	return rect


func _add_spotlight_label(
	position: Vector2,
	size: Vector2,
	text: String,
	font_size: int,
	color: Color
) -> Label:
	var label := Label.new()
	label.position = position
	label.size = size
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	if _spotlight_font != null:
		label.add_theme_font_override("font", _spotlight_font)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_spotlight_root.add_child(label)
	return label


func _create_spotlight_paper(color: Color) -> Polygon2D:
	var paper := Polygon2D.new()
	paper.polygon = PackedVector2Array([
		Vector2(-20, -13), Vector2(13, -13), Vector2(20, -7), Vector2(18, 10),
		Vector2(8, 13), Vector2(-18, 11), Vector2(-21, 2)
	])
	paper.color = color
	var crease := Line2D.new()
	crease.width = 2.0
	crease.default_color = Color(0.2, 0.3, 0.38, 0.45)
	crease.add_point(Vector2(-12, -5))
	crease.add_point(Vector2(10, 4))
	paper.add_child(crease)
	var fold := Line2D.new()
	fold.width = 2.0
	fold.default_color = Color(0.2, 0.3, 0.38, 0.36)
	fold.add_point(Vector2(-4, -10))
	fold.add_point(Vector2(-9, 8))
	paper.add_child(fold)
	return paper


func _create_circle_line(center: Vector2, radius: float, color: Color, width: float) -> Line2D:
	var line := Line2D.new()
	line.width = width
	line.default_color = color
	_set_circle_line_center(line, center, radius)
	return line


func _set_circle_line_center(line: Line2D, center: Vector2, radius: float) -> void:
	if line == null:
		return
	line.clear_points()
	for index in range(33):
		var angle := TAU * float(index) / 32.0
		line.add_point(center + Vector2(cos(angle), sin(angle)) * radius)


func _spotlight_fire_rect() -> Rect2:
	return Rect2(665, 420, 182, 78)


func _spotlight_aim_rect() -> Rect2:
	return Rect2(130, 290, 700, 130)


func _nearest_target() -> Dictionary:
	var nearest: Dictionary = {}
	var nearest_distance := INF
	for target in _active_targets():
		var stand := _target_stand(target)
		var distance := _player.position.distance_to(stand)
		if distance <= float(target.get("proximity", 0)) and distance < nearest_distance:
			nearest = target
			nearest_distance = distance
	return nearest


func _active_targets() -> Array:
	var phase := _theater_phase()
	var theater: Dictionary = _snapshot.get("theater", {})
	var collected_program_ids: Array = theater.get("collectedProgramIds", [])
	var active: Array = []
	for target in _runtime_data.get("targets", []):
		var kind := str(target.get("kind", ""))
		var enabled := false
		if phase == "entry_ticket":
			enabled = kind == "poster" or kind == "kiosk" or kind == "gate"
		elif phase == "program_search":
			enabled = kind == "console"
			if kind == "program":
				var program_id := str(target.get("programId", ""))
				enabled = not program_id.is_empty() and not collected_program_ids.has(program_id)
		elif phase == "prop_setup":
			enabled = kind == "prop" or kind == "scanner" or kind == "vent"
		elif phase == "spotlight_ready":
			enabled = kind == "console"
		elif phase == "complete":
			enabled = kind == "exit"
		if enabled:
			active.append(target)
	return active


func _interact_with_nearest_target() -> void:
	if _input_blocked:
		return
	var target := _nearest_target()
	if target.is_empty():
		return
	var target_id := str(target.get("id", ""))
	if target_id == "theater_ticket_kiosk":
		_post_intent("rpg_theater_ticket_kiosk_requested")
	elif target_id == "theater_prop_box":
		_post_intent("rpg_theater_prop_inspect_requested")
	elif target_id == "theater_exit":
		_post_intent("rpg_theater_exit_requested")
	elif target_id == "theater_light_console" and _theater_phase() == "program_search":
		var theater: Dictionary = _snapshot.get("theater", {})
		if str(theater.get("mode", "light")) == "dark":
			_post_intent("rpg_theater_program_order_read_requested")
		elif theater.get("collectedProgramIds", []).size() >= 3:
			_post_intent("rpg_theater_program_panel_requested")
		else:
			_post_intent("rpg_subtitle", {
				"text": "先在浅色模式收齐三张节目单，再回到灯光控制台。",
				"tone": "task",
				"durationMs": 3600
			})
	elif str(target.get("kind", "")) == "program":
		var theater: Dictionary = _snapshot.get("theater", {})
		if str(theater.get("mode", "light")) == "light":
			_post_intent("rpg_theater_program_collect_requested", { "programId": str(target.get("programId", "")) })
		elif theater.get("collectedProgramIds", []).size() >= 3:
			_post_intent("rpg_theater_program_order_read_requested")
		else:
			_post_intent("rpg_subtitle", {
				"text": "深色观察只显示节目单残影；切回浅色操作后取得残页。",
				"tone": "task",
				"durationMs": 3600
			})


func _handle_inventory_drop(payload: Dictionary) -> void:
	var item_id := str(payload.get("itemId", ""))
	var canvas_point := Vector2(float(payload.get("canvasX", -1)), float(payload.get("canvasY", -1)))
	var world_point := get_canvas_transform().affine_inverse() * canvas_point
	var target := _drop_target_at(world_point, item_id)
	if target.is_empty():
		_post_item_feedback(item_id, "missed_target", "剧院场景", "道具没有放入当前高亮目标。")
		return
	var label := _target_label(target)
	if str(target.get("acceptedItem", "")) != item_id:
		_post_item_feedback(item_id, "wrong_item", label, "目标范围命中，但该道具不匹配。")
		return
	var required_mode := str(target.get("requiredMode", ""))
	var current_mode := str(_snapshot.get("theater", {}).get("mode", "light"))
	if not required_mode.is_empty() and required_mode != current_mode:
		_post_item_feedback(item_id, "locked", label, "需要浅色操作：深色模式只读取线索和异常。")
		return
	if _player.position.distance_to(_target_stand(target)) > float(target.get("proximity", 0)):
		_post_item_feedback(item_id, "too_far", label, "松手位置正确；先让人物站进蓝色站位圈。")
		return
	var target_id := str(target.get("id", ""))
	if target_id == "theater_ticket_gate":
		_post_intent("rpg_theater_admission_requested")
	elif target_id == "theater_prop_scanner":
		_post_intent("rpg_theater_prop_ticket_requested")
	elif target_id == "theater_poster":
		_post_intent("rpg_theater_poster_tissue_requested")
	elif target_id == "theater_backstage_vent":
		_post_intent("rpg_theater_vent_brush_requested")
	elif target_id == "theater_light_console":
		_post_intent("rpg_theater_spotlight_start_requested")
	else:
		_post_item_feedback(item_id, "locked", label, "该目标当前不接收道具。")


func _drop_target_at(point: Vector2, item_id: String) -> Dictionary:
	var matches: Array[Dictionary] = []
	for target in _active_targets():
		var width := float(target.get("dropWidth", target.get("width", float(target.get("proximity", 40)) * 2.0)))
		var height := float(target.get("dropHeight", target.get("height", float(target.get("proximity", 40)) * 2.0)))
		var center := Vector2(float(target.get("x", 0)), float(target.get("y", 0)))
		if absf(point.x - center.x) <= width / 2.0 and absf(point.y - center.y) <= height / 2.0:
			matches.append(target)
	matches.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_accepts := str(a.get("acceptedItem", "")) == item_id
		var b_accepts := str(b.get("acceptedItem", "")) == item_id
		if a_accepts != b_accepts:
			return a_accepts
		var a_area := float(a.get("dropWidth", a.get("width", a.get("proximity", 40) * 2))) * float(a.get("dropHeight", a.get("height", a.get("proximity", 40) * 2)))
		var b_area := float(b.get("dropWidth", b.get("width", b.get("proximity", 40) * 2))) * float(b.get("dropHeight", b.get("height", b.get("proximity", 40) * 2)))
		return a_area < b_area
	)
	return matches[0] if not matches.is_empty() else {}


func _find_target(target_id: String) -> Dictionary:
	for target in _runtime_data.get("targets", []):
		if str(target.get("id", "")) == target_id:
			return target
	return {}


func _target_stand(target: Dictionary) -> Vector2:
	var stand: Dictionary = target.get("stand", {})
	return Vector2(
		float(stand.get("x", target.get("x", 0))),
		float(stand.get("y", target.get("y", 0)))
	)


func _target_label(target: Dictionary) -> String:
	var authored_label := str(target.get("label", ""))
	if not authored_label.is_empty():
		return authored_label
	var labels := {
		"theater_poster": "入口海报",
		"theater_ticket_kiosk": "取票机",
		"theater_ticket_gate": "检票闸机右侧读票器",
		"theater_program_opening": "开场节目单",
		"theater_program_spotlight": "追光节目单",
		"theater_program_finale": "终场节目单",
		"theater_light_console": "灯光控制台",
		"theater_prop_box": "道具箱",
		"theater_prop_scanner": "道具箱旁票据扫描器",
		"theater_backstage_vent": "后台通风口",
		"theater_exit": "剧院出口"
	}
	return str(labels.get(str(target.get("id", "")), "场景目标"))


func _spawn_for_zone(spawn_zone: String) -> Vector2:
	var spawns: Dictionary = _runtime_data.get("spawns", {})
	var key := spawn_zone
	if key != "lobby" and key != "auditorium" and key != "stage":
		key = "lobby"
	var spawn: Dictionary = spawns.get(key, { "x": 836, "y": 842 })
	return Vector2(float(spawn.get("x", 836)), float(spawn.get("y", 842)))


func _legacy_spawn_zone(phase: String, admitted: bool) -> String:
	if not admitted or phase == "complete":
		return "lobby"
	if phase == "prop_setup" or phase == "spotlight_ready" or phase == "spotlight_hunt" or phase == "reversal":
		return "stage"
	return "auditorium"


func _theater_phase() -> String:
	return str(_snapshot.get("theater", {}).get("phase", "entry_ticket"))


func _post_item_feedback(item_id: String, reason: String, target_label: String, detail: String) -> void:
	_post_intent("rpg_item_use_feedback", {
		"itemId": item_id,
		"reason": reason,
		"targetLabel": target_label,
		"detail": detail
	})


func _post_intent(name: String, payload: Dictionary = {}) -> void:
	_post_message({
		"type": "intent",
		"sceneId": SCENE_ID,
		"requestId": "%s-%d" % [name, Time.get_ticks_msec()],
		"name": name,
		"payload": payload
	})


func _post_error(code: String, detail: String) -> void:
	_post_message({
		"type": "runtime_error",
		"sceneId": SCENE_ID,
		"code": code,
		"detail": detail
	})


func _post_debug_snapshot() -> void:
	if _player == null:
		return
	var camera_position := _camera.get_screen_center_position() if _camera != null else Vector2.ZERO
	var nearest := _nearest_target()
	_post_message({
		"type": "debug_snapshot",
		"sceneId": SCENE_ID,
		"revision": _snapshot_revision,
		"debug": {
			"engine": "godot",
			"coordinateSystem": "Godot world coordinates, origin at top-left, x right, y down",
			"world": _runtime_data.get("world", {}),
			"player": {
				"x": snappedf(_player.position.x, 0.01),
				"y": snappedf(_player.position.y, 0.01),
				"facing": _facing,
				"texture": "player_%s_%d" % [_facing, _walk_frame],
				"displayScale": PLAYER_SCALE,
				"collisionWidth": PLAYER_COLLISION_SIZE.x,
				"collisionHeight": PLAYER_COLLISION_SIZE.y
			},
			"camera": {
				"scrollX": snappedf(camera_position.x - LOGICAL_VIEWPORT.x / 2.0, 0.01),
				"scrollY": snappedf(camera_position.y - LOGICAL_VIEWPORT.y / 2.0, 0.01),
				"zoom": 1.0,
				"mode": "follow"
			},
			"scene": SCENE_ID,
			"checkpoint": str(_snapshot.get("checkpoint", "")),
			"activeTargets": _active_targets(),
				"theater": {
					"runtimeContractVersion": PROTOCOL_VERSION,
					"phase": _theater_phase(),
					"spawnZone": str(_snapshot.get("spawnZone", "")),
					"mode": str(_snapshot.get("theater", {}).get("mode", "light")),
					"activeTarget": str(nearest.get("id", "")) if not nearest.is_empty() else null,
					"panel": null,
					"spotlightChoiceOpen": _spotlight_stage == "tracking",
					"spotlight": {
						"stage": _spotlight_stage,
						"round": int(_snapshot.get("theater", {}).get("spotlightRound", 0)),
						"aimX": snappedf(_spotlight_aim_x, 0.01),
						"aimLane": _spotlight_aim_lane(),
						"beamActive": _spotlight_beam_active,
						"actionElapsedMs": snappedf(_spotlight_action_elapsed_ms, 0.01),
						"actionRemainingMs": maxf(
							0.0,
							float(_spotlight_config.get("actionMs", 0)) - _spotlight_action_elapsed_ms
						),
						"currentLockMs": snappedf(_spotlight_current_lock_ms, 0.01),
						"maxContinuousLockMs": snappedf(_spotlight_max_lock_ms, 0.01),
						"requiredLockMs": snappedf(_spotlight_required_lock_ms(), 0.01),
						"earlyExposureMs": snappedf(_spotlight_early_exposure_ms, 0.01),
						"assistActive": bool(_spotlight_assist.get("active", false)),
						"lastFailureReason": _spotlight_last_failure if not _spotlight_last_failure.is_empty() else null,
						"target": {
							"x": snappedf(_spotlight_target_position.x, 0.01),
							"y": snappedf(_spotlight_target_position.y, 0.01),
							"visible": _spotlight_paper != null and _spotlight_paper.visible
						} if _spotlight_stage != "idle" else null,
						"decoyVisible": _spotlight_decoy_visible
					}
				}
			}
		})


func _post_message(message: Dictionary) -> void:
	if not OS.has_feature("web") or _js_window == null:
		return
	message["source"] = "7-55-godot"
	message["version"] = PROTOCOL_VERSION
	var parent = _js_window.parent
	parent.postMessage(JSON.stringify(message), _js_window.location.origin)
