extends SceneTree
const SQUIRREL = preload("res://campuses/buct/scripts/ambient_squirrel.gd")
const PATCH = preload("res://campuses/buct/scripts/ambient_squirrel_patch.gd")
const PROFILE := "res://campuses/buct/data/ambient-squirrel-profile.json"
var checks := 0
var failures: Array[String] = []
var report: Array[Dictionary] = []
var blocked_route := false

func _initialize() -> void: run.call_deferred()

func check(value: bool, label: String) -> void:
	checks += 1
	report.append({"pass": value, "label": label})
	if not value:
		failures.append(label)
		push_error(label)

func legal(point: Vector2) -> bool:
	return not blocked_route and point.x >= 722 and point.x <= 746 and is_equal_approx(point.y, 690)

func contains_collision(node: Node) -> bool:
	if node is CollisionObject2D or node is CollisionShape2D or node is CollisionPolygon2D: return true
	for child in node.get_children():
		if contains_collision(child): return true
	return false

func run() -> void:
	var profile: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PROFILE))
	var atlas: Texture2D = load(str(profile.atlas))
	var common_final: Dictionary = {}
	for hz in [30, 60, 120]:
		var actor = SQUIRREL.new()
		check(actor.configure(profile, atlas, Callable(self, "legal")), "Valid small route configures at %d Hz" % hz)
		root.add_child(actor)
		actor.set_on_screen(true)
		actor.set_process(false)
		check(actor.get_child_count() == 2 and actor.registered.size() == 8, "One sprite, one notifier, eight cached textures")
		check(not contains_collision(actor), "Visual actor contains no collision nodes")
		check(actor.sprite.scale.x == actor.sprite.scale.y, "Uniform scale only")
		if hz == 30:
			var transmission := 1.0
			var bounded_shadow: bool = actor.SHADOW_LAYERS.size() == 3
			for layer in actor.SHADOW_LAYERS:
				bounded_shadow = bounded_shadow and layer.x <= 1.0 and layer.y <= 0.25 and layer.z <= 0.055
				transmission *= 1.0 - layer.z
			check(bounded_shadow and actor.SHADOW_MAX_VISIBLE_SOURCE_SIZE == Vector2(4, 1) and 1.0 - transmission < 0.13, "Three cached shadow layers have half-size radii for bounded AA and 13 percent center opacity")
			check(actor.SHADOW_OFFSET == Vector2(0, 0.10) and actor.contact_shadow_enabled, "Small warm contact shadow starts at the original foot anchor")
			var original_position: Vector2 = actor.position
			var original_scale: Vector2 = actor.sprite.scale
			actor.set_contact_shadow_enabled(false)
			actor.set_contact_shadow_enabled(true)
			check(actor.position == original_position and actor.sprite.scale == original_scale and actor.get_child_count() == 2, "Shadow toggle cannot change actor geometry or add nodes")
		var initial_texture_ids: Array = []
		for frame in actor.registered: initial_texture_ids.append(frame.texture.get_instance_id())
		var states: Dictionary = {}
		var run_frames: Dictionary = {}
		var both_directions: Dictionary = {}
		var feet_correct := true
		var stayed_legal := true
		var stopped_idle := true
		var stopped_position_stable := true
		for i in range(hz * 90):
			var before: Dictionary = actor.snapshot()
			actor.advance(1.0 / hz)
			var after: Dictionary = actor.snapshot()
			states[after.phase] = true
			stayed_legal = stayed_legal and legal(actor.position)
			feet_correct = feet_correct and actor.current_foot_global().distance_to(actor.global_position) < 0.00001
			if before.phase != "run" and after.phase != "run": stopped_position_stable = stopped_position_stable and before.position == after.position
			if after.phase == "run" and before.position.distance_to(after.position) > 0.0:
				run_frames[after.frame] = true
				both_directions[after.facing_left] = true
			if after.phase == "idle": stopped_idle = stopped_idle and after.frame == int(profile.poses.idle[0])
		check(states.size() == 4 and run_frames.size() == 4 and both_directions.size() == 2, "Idle, peek, flick and four real run frames both ways")
		check(stayed_legal and feet_correct, "Every simulated sample stays legal with exact mirrored foot anchor")
		check(stopped_idle and stopped_position_stable, "Stops use true idle; non-run actions do not slide")
		check(actor.run_count >= 3, "Repeated bounded out-and-back trips complete")
		var after_ids: Array = []
		for frame in actor.registered: after_ids.append(frame.texture.get_instance_id())
		check(after_ids == initial_texture_ids, "No per-tick texture allocation")
		if common_final.is_empty(): common_final = actor.snapshot()
		else:
			check(actor.position.distance_to(common_final.position) < 0.0001 and absf(actor.distance_travelled - common_final.distance_travelled) < 0.0001 and actor.current_frame == common_final.frame, "Time-step invariant position, stride and pose")
		actor.set_on_screen(false)
		var paused: Dictionary = actor.snapshot()
		for i in range(100): actor.advance(1.0)
		check(actor.snapshot() == paused and not actor.is_processing(), "Off-screen fully paused with no time catch-up")
		actor.set_on_screen(true)
		actor.set_app_focused(false)
		paused = actor.snapshot()
		for i in range(100): actor.advance(1.0)
		check(actor.snapshot() == paused and not actor.is_processing(), "Focus loss fully paused")
		actor.set_app_focused(true)
		actor.set_process(false)
		var before_distance: float = actor.distance_travelled
		actor.advance(60.0)
		check(actor.distance_travelled - before_distance <= float(profile.speed_source_px_per_second) * 0.1 + 0.00001, "Long frame is bounded, never fast-forwards")
		blocked_route = true
		for i in range(600): actor.advance(0.1)
		check(actor.blocked and actor.current_frame == int(profile.poses.idle[0]) and not actor.is_processing(), "Invalidated route stops safely without changing navigation")
		blocked_route = false
		var weak: WeakRef = weakref(actor)
		actor.queue_free()
		await process_frame
		await process_frame
		check(weak.get_ref() == null, "Actor and child resources released at %d Hz" % hz)
	var rejected = SQUIRREL.new()
	blocked_route = true
	check(not rejected.configure(profile, atlas, Callable(self, "legal")), "Initially blocked route rejects actor before scene attachment")
	blocked_route = false
	rejected.free()
	var changed: Dictionary = profile.duplicate(true)
	changed.poses.run = [4, 4, 4, 4]
	rejected = SQUIRREL.new()
	check(not rejected.configure(changed, atlas, Callable(self, "legal")), "Duplicate-index fake run cycle rejected")
	rejected.free()
	for entry in range(2):
		var app = load("res://campuses/buct/scenes/playable.tscn").instantiate()
		root.add_child(app)
		await process_frame
		check(is_instance_valid(app.ambient_squirrel), "Exactly one actor installed on campus entry %d" % entry)
		var actor = app.ambient_squirrel
		actor.set_on_screen(true)
		actor.set_process(false)
		check(actor.get_parent() == app.objects and app.objects.y_sort_enabled and actor.z_index == 0, "Feet-sorted alongside existing student and tree nodes")
		check(PATCH.install(app, app.objects) == actor, "Repeated installer is idempotent")
		var walk_cells_before: Array = app.walk_cells.duplicate()
		var blockers_before: Array = app.blockers.duplicate(true)
		var visitor_position: Vector2 = app.visitor.position
		var visited_before: Array = app.visited.duplicate()
		var collision_found := contains_collision(actor)
		var valid := true
		for i in range(49):
			var point := Vector2(722 + i * 0.5, 690)
			valid = valid and app.is_walkable(point)
		for x in range(722, 747, 4):
			var cell := Vector2i(floori(x / app.CELL), floori(690.0 / app.CELL))
			valid = valid and app.grid.is_in_boundsv(cell) and not app.grid.is_point_solid(cell)
		for i in range(600): actor.advance(1.0 / 60.0)
		check(valid and not collision_found, "All 49 half-pixel route samples and seven existing graph nodes are legal")
		check(app.walk_cells == walk_cells_before and app.blockers == blockers_before and app.visitor.position == visitor_position and app.visited == visited_before, "Ambient actor cannot alter navigation, visitor or visit state")
		var probe := CharacterBody2D.new()
		probe.collision_layer = 0
		probe.collision_mask = 1
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 3.0
		shape.shape = circle
		probe.add_child(shape)
		app.objects.add_child(probe)
		probe.position = Vector2(722, 690)
		await physics_frame
		check(probe.move_and_collide(Vector2(24, 0)) == null, "Real radius-three physics body traverses entire squirrel route")
		var weak: WeakRef = weakref(actor)
		app.queue_free()
		await process_frame
		await process_frame
		check(weak.get_ref() == null, "Full campus exit releases squirrel on entry %d" % entry)
	var out := OS.get_environment("BUCT_SQUIRREL_EVIDENCE_DIR")
	if not out.is_empty():
		if not out.is_absolute_path() or DirAccess.make_dir_recursive_absolute(out) != OK:
			printerr("SQUIRREL_EVIDENCE_WRITE_FAILED")
			quit(2)
			return
		var file := FileAccess.open(out.path_join("headless-results.json"), FileAccess.WRITE)
		if file == null:
			quit(2)
			return
		file.store_string(JSON.stringify({"checks": checks, "failures": failures, "results": report}, "  "))
		file.flush()
		if file.get_error() != OK:
			quit(2)
			return
	print("BUCT_AMBIENT_SQUIRREL: ", checks, " checks; ", failures.size(), " failures")
	quit(0 if failures.is_empty() else 1)
