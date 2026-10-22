extends SceneTree
## Full native renderer integration, with declared original Chapter 3 prerequisites.
const Fixture = preload("res://tests/canteen_native_fixture.gd")
const Frames = preload("res://scripts/presentation/c3_door_frames.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("CANTEEN DOOR INTEGRATION: " + label)

func repaint(world: Control) -> void:
	world.native_canteen.configure_view(Vector2.ZERO, 1.0, world.player)

func run() -> void:
	var state: Node = root.get_node("State")
	Fixture.install(state)
	var story_before := JSON.stringify(state.d.canteenHunt)
	var items_before := JSON.stringify(state.d.items)
	var world: Control = load("res://scripts/world.gd").new()
	world.size = Vector2(960, 540)
	root.add_child(world)
	await process_frame
	world.set_process(false)
	var scene: Node2D = world.native_canteen
	var motion: RefCounted = scene.layers.doors
	motion.configure("canteen_interior", false)
	repaint(world)
	var source: Node2D = scene.objects.southeast_door
	check(source.position == Vector2(1349, 900) and is_equal_approx(source.scale_value, 88.0 / 766.0),
		"source anchor and uniform geometry remain unchanged")
	check(source.source_region == Frames.SOURCE_REGION, "exact original source crop")
	var closed: Sprite2D = scene.entities.southeast_door_closed
	check(closed.visible and closed.texture == source.texture and closed.region_rect == source.source_region,
		"closed endpoint uses the exact original full-resolution texture")
	check(closed.modulate.a == 1.0 and closed.scale.is_equal_approx(Vector2.ONE * source.scale_value),
		"closed original is opaque and uniformly scaled")
	check(scene.objects.west_door.parts[0].sprite.visible, "west static source door stays unchanged")
	for progress: float in [0.0, .10, .379, .38, .60, 1.0, .60, .38, .379, .10, 0.0]:
		motion.progress = progress
		motion.visual_progress = (1 - cos(PI * progress)) / 2
		repaint(world)
		var index: int = Frames.frame_index(motion.visual_progress, motion.passable())
		check((float(Frames.CENTERED_CLEAR_WIDTHS[index]) >= 19.5) == motion.passable(),
			"forward/reverse visible opening follows the unchanged 38% gate")
		if index == 0:
			check(closed.visible, "closing restores the original source endpoint")
			continue
		var leaves: Sprite2D = scene.entities.southeast_door_leaves
		var frame: Sprite2D = scene.entities.southeast_door_frame
		check(not closed.visible and leaves.visible and frame.visible, "open presentation owns only frame and leaves")
		check(leaves.region_rect == Frames.atlas_region(index), "original clock selects the registered leaf region")
		check(leaves.scale.is_equal_approx(Vector2.ONE * source.scale_value * 2.0) and leaves.modulate.a == 1.0,
			"no widthfold or fade survives in the active leaf renderer")
		check(frame.texture.resource_path == Frames.FRAME_ASSET and frame.scale.is_equal_approx(Vector2.ONE * source.scale_value),
			"stationary original frame retains its fixed source scale")
		check(frame.position.is_equal_approx(source.position + source.top_left + source.dimensions / 2),
			"stationary original frame never shifts")
		check(frame.get_index() > leaves.get_index(), "original hinge plates render above the independent leaves")
	check(JSON.stringify(state.d.canteenHunt) == story_before and JSON.stringify(state.d.items) == items_before,
		"render sampling does not change story, reward or inventory facts")
	# The same gate clamp is used on interrupted source sine tweens.
	for pair: Vector2 in [Vector2(.39, .10), Vector2(.37, .90)]:
		motion.progress = pair.x
		motion.visual_progress = pair.y
		repaint(world)
		var selected: int = Frames.frame_index(pair.y, motion.passable())
		check((float(Frames.CENTERED_CLEAR_WIDTHS[selected]) >= 19.5) == motion.passable(),
			"interrupted visual/linear pair remains visibly gate-safe")
	motion.configure("canteen_interior", true)
	check(motion.duration_ms == 120, "original reduced-motion clock stays 120 ms")
	motion.set_open(true)
	motion.advance(120)
	repaint(world)
	check(scene.entities.southeast_door_leaves.region_rect == Frames.atlas_region(7), "reduced-motion endpoint uses stable open pose")
	scene.sync(state.d, "campus_bootstrap")
	check(not scene.visible, "scene retirement hides all door presentation nodes")
	motion.configure("canteen_interior", false)
	scene.sync(state.d, "canteen_interior")
	repaint(world)
	check(closed.visible and not scene.entities.southeast_door_leaves.visible and not scene.entities.southeast_door_frame.visible,
		"reentry restores original closed identity without a stale open overlay")
	world.queue_free()
	await process_frame
	print("CANTEEN_DOOR_INTEGRATION %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)
