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


func _ready() -> void:
	_runtime_data = JSON.parse_string(FileAccess.get_file_as_string("res://data/theater-runtime.json"))
	if _runtime_data.is_empty():
		push_error("Missing theater runtime data.")
		return
	_create_world()
	_create_player()
	_install_web_bridge()
	if not OS.has_feature("web"):
		_apply_standalone_snapshot()
	call_deferred("_announce_ready")


func _exit_tree() -> void:
	if _js_window != null and _message_callback != null:
		_js_window.removeEventListener("message", _message_callback)


func _physics_process(delta: float) -> void:
	if _player == null:
		return
	var direction := Vector2.ZERO
	if not _input_blocked:
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
		_input_blocked = bool(message.get("paused", false)) or bool(message.get("inputBlocked", false))
		if _input_blocked:
			_host_direction = Vector2.ZERO


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
	queue_redraw()
	_post_debug_snapshot()


func _apply_host_command(command: Dictionary) -> void:
	var name := str(command.get("name", ""))
	var payload: Dictionary = command.get("payload", {})
	if name == "rpg_direction_changed":
		_host_direction = Vector2(float(payload.get("x", 0)), float(payload.get("y", 0)))
	elif name == "rpg_interact":
		_interact_with_nearest_target()
	elif name == "rpg_inventory_drop_requested":
		_handle_inventory_drop(payload)
	elif name == "rpg_inventory_drag_ended":
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
				"spotlightChoiceOpen": false
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
