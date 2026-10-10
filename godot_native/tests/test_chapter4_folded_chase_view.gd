extends SceneTree
## Preview verification. Runs with either the minimal runtime or full project:
## godot --headless --path <runtime> --script res://tests/test_chapter4_folded_chase_view.gd
## Input tests dispatch real InputEvents; physics advances only at explicit ticks.
const View = preload("res://scripts/presentation/chapter4_folded_chase_view.gd")
const Model = preload("res://scripts/games/chapter4_folded_chase_model.gd")
const VIEW_SOURCE := "res://scripts/presentation/chapter4_folded_chase_view.gd"
var checks := 0
var failures := 0
var verified_jump_poses := 0
var previous_accumulation := true

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("FOLDED_VIEW: " + label)

func frames(count: int = 2) -> void:
	for _index in count:
		await process_frame

func dispatch(event: InputEvent) -> void:
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func key(code: Key, pressed: bool, echo: bool = false) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	event.echo = echo
	return event

func touch(index: int, point: Vector2, pressed: bool) -> InputEventScreenTouch:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = point
	event.pressed = pressed
	return event

func drag(index: int, point: Vector2) -> InputEventScreenDrag:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = point
	return event

func release_keys() -> void:
	for code: Key in [KEY_A, KEY_D, KEY_LEFT, KEY_RIGHT, KEY_SPACE, KEY_ESCAPE]:
		dispatch(key(code, false))

func fresh(game) -> void:
	release_keys()
	game._start()
	game.model.guard = Vector2(-5.5, 0.0)
	game._present(0.0)
	root.gui_release_focus()

func tick(game) -> void:
	game._physics_process(1.0 / 60.0)

func run() -> void:
	previous_accumulation = Input.use_accumulated_input
	Input.use_accumulated_input = false
	root.size = Vector2i(1180, 812)
	var campaign_before := _campaign_snapshot()
	var saves_before := _save_snapshot()
	var game = View.new()
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	await frames()
	if campaign_before.is_empty():
		check(not root.has_node("State"), "standalone runtime needs no State autoload")
	else:
		print("CAMPAIGN_ISOLATION: existing State autoload is snapshotted without modification")
	check(game.menu.visible and not game.active, "preview starts at its local start menu")
	_test_isolation()
	_test_geometry(game)
	_test_source_art(game)
	_test_keys(game)
	_test_touch_and_pause(game)
	_test_fold_input(game)
	await _test_fit(game)
	_test_facing(game)
	_test_lights(game)
	release_keys()
	game.queue_free()
	await frames()
	check(_campaign_snapshot() == campaign_before, "preview lifecycle leaves actual campaign State unchanged")
	check(_save_snapshot() == saves_before, "preview lifecycle creates or changes neither formal save nor backup")
	Input.use_accumulated_input = previous_accumulation
	print("CHAPTER4_FOLDED_CHASE_VIEW ", checks, " checks; ", failures,
		" failures; verified_jump_atlas_poses=", verified_jump_poses)
	quit(1 if failures else 0)

func _campaign_snapshot() -> Dictionary:
	var state := root.get_node_or_null("State")
	if state == null:
		return {}
	# Public state inspected in scripts/state.gd; do not call initial(), act() or save_game().
	var progression: Dictionary = state.get("d")
	var formal: Dictionary = state.get("formal_snapshot")
	var result: Dictionary = state.get("last_result")
	return {"instance": state.get_instance_id(), "d": progression.duplicate(true),
		"developer_mode": state.get("developer_mode"), "formal_snapshot": formal.duplicate(true),
		"last_result": result.duplicate(true)}

func _save_snapshot() -> Dictionary:
	var snapshot := {}
	# These are State.SAVE_PATH and State.BACKUP_PATH. Reading does not create them.
	for path: String in ["user://save.json", "user://save.previous.json"]:
		var exists := FileAccess.file_exists(path)
		snapshot[path] = {"exists": exists,
			"sha256": FileAccess.get_sha256(path) if exists else "",
			"modified": FileAccess.get_modified_time(path) if exists else 0}
	return snapshot

func _test_isolation() -> void:
	for path: String in [VIEW_SOURCE, "res://scripts/games/chapter4_folded_chase_model.gd",
		"res://scripts/games/chapter4_side_chase_model.gd"]:
		var source := FileAccess.get_file_as_string(path)
		var code := ""
		for line: String in source.split("\n"):
			if not line.strip_edges().begins_with("#"):
				code += line + "\n"
		check(not code.contains("State.") and not code.contains('get_node("/root/State")'),
			"preview source has no campaign-state dependency: " + path)
		check(not code.contains("FileAccess.WRITE") and not code.contains("store_var(")
			and not code.contains("store_string(") and not code.contains("ResourceSaver.save"),
			"preview source has no save-writing API: " + path)
	for path: String in ["res://scripts/main.gd", "res://scripts/state.gd", "res://scenes/main.tscn"]:
		if FileAccess.file_exists(path):
			check(not FileAccess.get_file_as_string(path).contains("chapter4_folded_chase"),
				"formal Main/State does not integrate this preview: " + path)
	var scene := FileAccess.get_file_as_string("res://scenes/chapter4_folded_chase_preview.tscn")
	check(scene.contains(VIEW_SOURCE) and not scene.contains("main.tscn") and not scene.contains("state.gd"),
		"standalone scene binds only the preview view")
	check(bool(Model.data().get("prototypeOnly", false)), "canonical geometry is explicitly preview-only")

func _collect(node: Node, klass: String, found: Array[Node]) -> void:
	if node.is_class(klass):
		found.append(node)
	for child: Node in node.get_children():
		_collect(child, klass, found)

func _rect(raw: Dictionary) -> Rect2:
	if raw.has("x"):
		return Rect2(float(raw.x), float(raw.y), float(raw.width), float(raw.height))
	var r: Array = raw.rect
	return Rect2(float(r[0]), float(r[1]), float(r[2]), float(r[3]))

func _matching_solid(solids: Array[Node], position_3d: Vector3, dimensions: Vector3) -> Node:
	for body: Node in solids:
		var mesh = body.get_parent()
		if mesh is MeshInstance3D and mesh.mesh is BoxMesh:
			if mesh.global_position.is_equal_approx(position_3d) and mesh.mesh.size.is_equal_approx(dimensions):
				return body
	return null

func _test_geometry(game) -> void:
	var solids: Array[Node] = []
	_collect(game.world, "StaticBody3D", solids)
	var canonical: Dictionary = Model.data()
	check(canonical.floors.size() == 83, "manifest contains 83 actual floor/step boxes")
	var flights := 0
	for route: Dictionary in canonical.routes:
		if route.kind == "flight":
			flights += 1
	check(flights == 4, "four physical stair flights")
	check(solids.size() == canonical.floors.size() + canonical.obstacles.size() + flights,
		"all 83 floors, two barriers and four walls have StaticBody3D collision")
	check(game.solid_count == solids.size(), "reported solid count matches actual scene bodies")
	for group: String in ["floors", "obstacles"]:
		var index := 0
		for raw: Dictionary in canonical[group]:
			var r := _rect(raw)
			var progress := r.get_center().x
			var dimensions := Vector3(r.size.x, r.size.y, 2.0 if group == "floors" else 1.65)
			var expected: Vector3 = game.model.route_position(progress, r.get_center().y)
			var body := _matching_solid(solids, expected, dimensions)
			check(body != null, "%s %d has a correctly placed physical box" % [group, index])
			if body != null:
				var mesh: MeshInstance3D = body.get_parent()
				var expected_heading: Vector3 = game.model.route_heading(progress)
				check(mesh.global_basis.x.normalized().dot(expected_heading) > .999,
					"physical box follows folded route: %s %d" % [group, index])
			index += 1
	for body: Node in solids:
		check(body.get_child_count() == 1 and body.get_child(0) is CollisionShape3D
			and body.get_child(0).shape is BoxShape3D
			and not body.get_child(0).disabled
			and body.get_child(0).shape.size.is_equal_approx(body.get_parent().mesh.size),
			"solid mesh and enabled collision shape have identical dimensions")
	var environments: Array[Node] = []
	_collect(game.world, "WorldEnvironment", environments)
	check(environments.size() == 1, "one independent world environment")
	if environments.size() == 1:
		var environment: Environment = environments[0].environment
		check(environment.background_mode == Environment.BG_COLOR and environment.background_color == Color.BLACK,
			"world background is black")
		check(environment.ambient_light_energy <= .11, "ambient remains dark rather than flooding the room")

func _same_source(texture: Texture2D, path: String) -> bool:
	if texture == null or not FileAccess.file_exists(path):
		return false
	var source := Image.load_from_file(path)
	var actual := texture.get_image()
	if source == null or actual == null or source.get_size() != actual.get_size():
		return false
	source.convert(Image.FORMAT_RGBA8)
	actual.convert(Image.FORMAT_RGBA8)
	return source.get_data() == actual.get_data()

func _test_source_art(game) -> void:
	for direction: String in ["up", "down", "side"]:
		check(game.player_frames[direction].size() == 8, direction + " has eight original full-body player frames")
		for index in 8:
			var path := "res://assets/rpg/player/player_%s_%d.png" % [direction, index]
			check(_same_source(game.player_frames[direction][index], path), "original source PNG pixels: " + path)
		var suffix := "" if direction == "side" else "_" + direction
		check(_same_source(game.guard_frames[direction],
			"res://assets/rpg/npcs/finale/guard_walk%s_8frame.png" % suffix),
			"guard uses original " + direction + " eight-frame sheet")
	check(_same_source(game.player_frames.idle, "res://assets/rpg/player/player_side_idle.png"),
		"original side idle image is preserved")
	if FileAccess.file_exists(View.JUMP_PATH):
		var atlas := Image.load_from_file(View.JUMP_PATH)
		check(atlas != null and atlas.get_size() == Vector2i(1086, 1448), "available jump atlas has its authored size")
		check(game.jump_frames.size() == 4, "available jump atlas yields four actual regions")
		for index in game.jump_frames.size():
			check(game.jump_frames[index].region == Rect2((index % 2) * 543, int(index / 2) * 724, 543, 724),
				"jump atlas region %d is full-size and correctly located" % index)
		verified_jump_poses = game.jump_frames.size()
	else:
		check(game.jump_frames.is_empty(), "missing original jump atlas has zero fabricated poses")
		print("JUMP_ATLAS_UNAVAILABLE: source PNG is absent; zero atlas poses verified; original direction frames are tested")

func _test_keys(game) -> void:
	fresh(game)
	var initial_tick: int = game.model.tick
	dispatch(key(KEY_SPACE, true))
	check(game.queued_jump, "real Space keydown queues an edge before any physics tick")
	dispatch(key(KEY_SPACE, false))
	check(game.queued_jump and not Input.is_physical_key_pressed(KEY_SPACE)
		and game.model.tick == initial_tick, "short Space down/up between ticks retains exactly one queued edge")
	tick(game)
	check(not game.queued_jump and game.model.player_velocity.y > 0 and not game.model.player_grounded,
		"short Space edge is consumed by the next physics tick")
	check(game.model.input_log.size() == 1 and int(game.model.input_log[0]) & Model.JUMP,
		"one real queued Space edge records one jump tick")
	tick(game)
	check(not (int(game.model.input_log.back()) & Model.JUMP), "released Space does not leak into the next input tick")
	fresh(game)
	dispatch(key(KEY_SPACE, true, true))
	dispatch(key(KEY_SPACE, false))
	check(not game.queued_jump, "keyboard echo cannot create a queued jump edge")
	tick(game)
	check(game.model.player_grounded and not (int(game.model.input_log.back()) & Model.JUMP),
		"echo-only short event does not jump")
	fresh(game)
	dispatch(key(KEY_SPACE, true))
	check(Input.is_physical_key_pressed(KEY_SPACE), "real input dispatcher updates physical Space state")
	var takeoffs := 0
	for _index in 70:
		var was_grounded: bool = game.model.player_grounded
		tick(game)
		if was_grounded and not game.model.player_grounded:
			takeoffs += 1
	check(game.model.status == "running" and game.model.tick == 70, "held-Space test remains a live 70-tick attempt")
	check(takeoffs == 1 and game.model.player_grounded,
		"held Space lands and stays grounded without consecutive automatic jumps")
	dispatch(key(KEY_SPACE, false))
	tick(game)
	dispatch(key(KEY_SPACE, true))
	tick(game)
	check(not game.model.player_grounded and game.model.player_velocity.y > 0,
		"Space release then fresh press permits a second jump")
	release_keys()
	fresh(game)
	dispatch(key(KEY_D, true))
	tick(game)
	check(game.model.player_velocity.x > 0, "real D event steers at the initial camera heading")
	dispatch(key(KEY_D, false))
	tick(game)
	check(is_zero_approx(game.model.player_velocity.x) and game.held_screen_axis == 0,
		"actual movement key release stops and resets held screen intent")

func _actor_screen(game) -> Vector2:
	return game.camera.unproject_position(game.actor.global_position) * game.size / Vector2(game.viewport.size) + game.global_position

func _test_touch_and_pause(game) -> void:
	fresh(game)
	var origin: Vector2 = _actor_screen(game) + Vector2(110, 35)
	dispatch(touch(3, origin, true))
	check(game.primary_touch == 3 and game.touch_axis == 1, "real primary touch to actor's right steers right")
	tick(game)
	check(game.model.player_velocity.x > 0, "touch steering reaches the fixed-tick input stream")
	dispatch(touch(4, origin + Vector2(25, 0), true))
	check(game.primary_touch == 3 and game.touch_axis == 1 and game.queued_jump,
		"second finger queues jump without stealing the steering finger")
	dispatch(touch(4, origin, false))
	check(game.primary_touch == 3 and game.touch_axis == 1, "second-finger release preserves primary steering")
	tick(game)
	check(not game.queued_jump and not game.model.player_grounded, "second-finger jump is consumed once")
	dispatch(drag(3, origin + Vector2(0, -50)))
	check(game.queued_jump and game.swipe_used, "upward primary-finger swipe queues a jump")
	game.queued_jump = false
	dispatch(drag(3, origin + Vector2(0, -85)))
	check(not game.queued_jump, "one upward swipe cannot repeatedly queue jumps")
	dispatch(drag(3, _actor_screen(game) + Vector2(-100, -20)))
	check(game.touch_axis == -1, "primary finger can cross the actor to reverse screen direction")
	var overlay := ColorRect.new()
	overlay.position = Vector2(0, 0)
	overlay.size = Vector2(220, 220)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	game.add_child(overlay)
	game.touch_started = Time.get_ticks_msec() - 1000
	dispatch(touch(3, Vector2(30, 30), false))
	check(game.primary_touch == -99 and game.touch_axis == 0 and game.held_screen_axis == 0
		and game.held_route_direction == 0, "release over blocking UI retires all touch steering")
	tick(game)
	check(is_zero_approx(game.model.player_velocity.x), "release over UI stops motion on the next tick")
	overlay.free()
	fresh(game)
	origin = _actor_screen(game) + Vector2(100, 30)
	dispatch(touch(7, origin, true))
	tick(game)
	dispatch(touch(8, origin, true))
	var model_id: int = game.model.get_instance_id()
	var before := {"tick": game.model.tick, "player": game.model.player, "guard": game.model.guard,
		"inputs": game.model.input_log.duplicate()}
	root.focus_exited.emit()
	check(game.focus_paused and not game.active and game.menu.visible,
		"actual window focus-exited signal pauses the local attempt")
	check(game.primary_touch == -99 and game.touch_axis == 0 and not game.queued_jump
		and game.held_screen_axis == 0 and game.held_route_direction == 0,
		"lost focus clears touches, pending jump and retained input intent")
	check(game.viewport.render_target_update_mode == SubViewport.UPDATE_ONCE, "paused preview stops continuous world redraw")
	for _index in 5:
		tick(game)
	check(before == {"tick": game.model.tick, "player": game.model.player, "guard": game.model.guard,
		"inputs": game.model.input_log}, "paused physics cannot advance the attempt or input proof")
	game.start_button.pressed.emit()
	check(game.active and not game.focus_paused and not game.menu.visible
		and game.model.get_instance_id() == model_id and game.model.tick == int(before.tick),
		"Continue button resumes the same model and tick without reset")
	tick(game)
	check(game.model.tick == int(before.tick) + 1 and int(game.model.input_log.back()) == 0,
		"resume continues exactly once with neutral input")

func _test_fold_input(game) -> void:
	fresh(game)
	game.model.player.x = 10.0
	game._present(0.0)
	check(game._adjust_input_mask(Model.RIGHT) == Model.RIGHT, "fresh screen-right maps to forward on first flight")
	for progress: float in [16.5, 20.0, 32.0, 40.0, 48.0, 55.0, 64.0]:
		game.model.player.x = progress
		game._present(0.0)
		check(game._adjust_input_mask(Model.RIGHT) == Model.RIGHT,
			"held screen-right keeps route-forward intent across fold %.1f and camera update" % progress)
	game.camera.rotate_y(PI)
	check(game._adjust_input_mask(Model.RIGHT | Model.JUMP) == (Model.RIGHT | Model.JUMP),
		"camera basis reversal cannot flip held intent or drop jump bit")
	check(game._adjust_input_mask(0) == 0 and game.held_screen_axis == 0 and game.held_route_direction == 0,
		"neutral input releases both held axis and retained route direction")
	game.model.player.x = 20.0
	game._present(0.0)
	check(game._adjust_input_mask(Model.RIGHT) == Model.LEFT,
		"fresh screen-right remaps against current second-flight heading and camera")
	check(game._adjust_input_mask(Model.LEFT) == Model.RIGHT,
		"opposing gesture immediately reverses route intent without a neutral frame")
	game._adjust_input_mask(0)
	game.camera.rotate_y(PI)
	check(game._adjust_input_mask(Model.RIGHT) == Model.RIGHT,
		"fresh axis after release uses the new camera basis")
	check(game._adjust_input_mask(Model.LEFT | Model.RIGHT | Model.JUMP) == Model.JUMP
		and game.held_route_direction == 0, "opposed simultaneous axes clear steering while preserving jump")

func _test_fit(game) -> void:
	for dimensions: Vector2i in [Vector2i(1180, 812), Vector2i(844, 390), Vector2i(390, 844)]:
		root.size = dimensions
		await frames()
		game._fit()
		fresh(game)
		check(game.size == Vector2(dimensions) and game.scale == Vector2.ONE,
			"view fills actual root at " + str(dimensions))
		check(game.surface.position == Vector2.ZERO and game.surface.size == game.size
			and game.view_rect == Rect2(Vector2.ZERO, game.size), "render surface fills viewport at " + str(dimensions))
		var target_aspect := float(dimensions.x) / float(dimensions.y)
		var actual_aspect := float(game.viewport.size.x) / float(game.viewport.size.y)
		check(absf(actual_aspect - target_aspect) <= 2.0 / float(game.viewport.size.y),
			"subviewport preserves output aspect within one-pixel rounding at " + str(dimensions))
		check(game.viewport.size.x > 0 and game.viewport.size.y > 0
			and game.viewport.size.x <= 960 and game.viewport.size.y <= 660,
			"adaptive render size remains positive and bounded at " + str(dimensions))
		check(not game.menu.visible, "no fixed start panel covers the running world")
		for child: Node in game.get_children():
			if child is Control:
				check(child == game.surface or child == game.menu, "no old fixed HUD or duplicate touch-control overlay")
		for progress: float in [1.0, 10.0, 17.2, 27.1, 40.0, 55.0, 65.4]:
			game.model.player = Vector2(progress, game.model.floor_height_at(progress))
			game.model.player_velocity = Vector2(Model.PLAYER_SPEED, 0)
			game.model.player_grounded = true
			game._present(0.0)
			check(not game.camera.is_position_behind(game.actor.global_position),
				"actor is in front of camera at %s route %.1f" % [dimensions, progress])
			var bounds := Rect2(Vector2.ZERO, Vector2(game.viewport.size))
			var full_frame_inside := true
			for horizontal: float in [-48.0, 48.0]:
				for vertical: float in [-2.0, 126.0]:
					var corner: Vector3 = game.actor.global_position + game.camera.global_basis.x * horizontal * game.actor.pixel_size \
						+ game.camera.global_basis.y * vertical * game.actor.pixel_size
					full_frame_inside = full_frame_inside and bounds.has_point(game.camera.unproject_position(corner))
			check(full_frame_inside, "full source frame, head and feet fit at %s route %.1f" % [dimensions, progress])
	root.size = Vector2i(1180, 812)
	await frames()
	game._fit()

func _test_facing(game) -> void:
	fresh(game)
	# Expected faces are independent of visible_facing(): camera looks from +Z, -X.
	var cases := [[10.0, 1.0, "side", false], [10.0, -1.0, "side", true],
		[17.0, 1.0, "up", false], [17.0, -1.0, "down", false],
		[32.0, 1.0, "down", false], [32.0, -1.0, "up", false],
		[22.0, 1.0, "side", true], [22.0, -1.0, "side", false]]
	for sample: Array in cases:
		var progress := float(sample[0])
		var direction := float(sample[1])
		var facing := str(sample[2])
		game.model.player = Vector2(progress, game.model.floor_height_at(progress))
		game.model.guard = Vector2(progress - direction * 1.0, game.model.floor_height_at(progress - direction * 1.0))
		game.model.player_velocity = Vector2(direction * Model.PLAYER_SPEED, 0)
		game.model.guard_velocity = Vector2(direction * Model.GUARD_SPEED, 0)
		game.model.player_grounded = true
		game.model.tick = 21
		game._present(0.0)
		check(game.actor.texture == game.player_frames[facing][3] and game.actor.flip_h == bool(sample[3]),
			"actual heading/camera selects source player %s at %.1f direction %.0f" % [facing, progress, direction])
		var heading: Vector3 = game.retained_heading
		game.model.player_velocity = Vector2.ZERO
		game._present(0.0)
		var idle: Texture2D = game.player_frames.idle if facing == "side" else game.player_frames[facing][0]
		check(game.retained_heading.is_equal_approx(heading) and game.actor.texture == idle
			and game.actor.flip_h == bool(sample[3]), "stopping preserves source heading and correct idle face: " + facing)
	check(game.actor.billboard == BaseMaterial3D.BILLBOARD_ENABLED and game.actor.shaded
		and is_equal_approx(game.actor.pixel_size, 1.7 / 128.0), "full-body source sprite stays shaded, billboarded and correctly scaled")
	if game.jump_frames.is_empty():
		game.model.player_grounded = false
		game.model.player_velocity = Vector2(Model.PLAYER_SPEED, 2)
		game.model.player.x = 10.0
		game._present(0.0)
		check(game.actor.texture == game.player_frames.side[3],
			"missing jump atlas keeps a real source frame in flight, without invented jump-art coverage")

func _test_lights(game) -> void:
	fresh(game)
	check(game.torch is SpotLight3D and is_equal_approx(game.torch.spot_range, 6.0)
		and is_equal_approx(game.torch.spot_angle, 11.0) and game.torch.shadow_enabled,
		"guard beam is a shadow-casting 6m, 11-degree spotlight")
	check(game.phone is Node3D and game.phone_screen is MeshInstance3D
		and game.phone_screen.get_parent() == game.phone and game.phone.get_child_count() >= 2,
		"player carries an actual handset mesh with a separate screen")
	var handset_small := true
	for node: Node in game.phone.get_children():
		if node is MeshInstance3D and node.mesh is BoxMesh:
			handset_small = handset_small and node.mesh.size.length() < .25
	check(handset_small, "phone is a small hand prop rather than a world-sized emissive proxy")
	check(game.phone_screen.material_override is StandardMaterial3D
		and game.phone_screen.material_override.emission_enabled, "actual phone screen emits a visible local glow")
	check(game.actor_fill is OmniLight3D and game.actor_fill.omni_range > 0
		and game.actor_fill.omni_range <= .6 and game.actor_fill.light_energy > 0
		and game.actor_fill.light_energy <= .6 and game.actor_fill.light_cull_mask == 2,
		"phone has a tiny always-on actor-only face light")
	check((game.actor.layers & game.actor_fill.light_cull_mask) != 0, "phone light can reveal the player's own sprite")
	var architecture: Array[Node] = []
	for group: Node in game.groups:
		_collect(group, "GeometryInstance3D", architecture)
	var no_world_flood := true
	for node: Node in architecture:
		no_world_flood = no_world_flood and (node.layers & game.actor_fill.light_cull_mask) == 0
	check(architecture.size() > 83 and no_world_flood, "phone light mask excludes every stair, wall, barrier, rail and world label")
	for sample: Array in [[10.0, 1.0], [17.0, 1.0], [22.0, 1.0], [32.0, 1.0], [22.0, -1.0]]:
		var progress := float(sample[0])
		var direction := float(sample[1])
		game.model.guard = Vector2(progress, game.model.floor_height_at(progress))
		game.model.player = Vector2(progress + direction * 1.0, game.model.floor_height_at(progress + direction * 1.0))
		game.model.player_velocity = Vector2(direction * Model.PLAYER_SPEED, 0)
		game.model.guard_velocity = Vector2(direction * Model.GUARD_SPEED, 0)
		game._present(0.0)
		var guard_heading: Vector3 = game.model.route_heading(progress, direction)
		var beam_heading: Vector3 = -game.torch.global_basis.z
		var beam_horizontal := Vector3(beam_heading.x, 0, beam_heading.z).normalized()
		check(beam_horizontal.dot(guard_heading) > .999,
			"guard hand beam follows heading at route %.1f direction %.0f" % [progress, direction])
		var hand_offset: Vector3 = game.torch.global_position - game.pursuer.global_position
		check(hand_offset.y > .8 and hand_offset.y < 1.5
			and Vector2(hand_offset.x, hand_offset.z).length() <= .75,
			"guard light source stays attached at hand height")
		check((game.torch_case.global_position - game.torch.global_position).dot(guard_heading) < -.05,
			"torch casing stays behind its light source rather than blocking its own beam")
		check(game.torch_lens.global_position.distance_to(game.torch.global_position) < .04,
			"visible torch lens and actual light source coincide")
		var phone_offset: Vector3 = game.phone.global_position - game.actor.global_position
		var expected_phone: Vector3 = game.retained_heading * .20 + Vector3(0, 1.18, .12)
		check(phone_offset.is_equal_approx(expected_phone), "handset follows this frame's player heading at chest/hand height")
		check(game.actor_fill.global_position.is_equal_approx(game.phone_screen.global_position)
			and game.actor_fill.visible and game.actor_fill.light_energy > 0,
			"always-on face light originates at the actual moving phone screen")
