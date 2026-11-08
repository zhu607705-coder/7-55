extends SceneTree
## Synthetic S-bend: candidate points are hints, never collision permission.
## Uses the approved campus footprint with isolated user data.
const Layered = preload("res://scripts/presentation/campus_layered_map.gd")
const Metrics = preload("res://scripts/player_metrics.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	run.call_deferred()

func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error("Reviewed route candidates: " + label)

func anchor(foot: Vector2) -> Vector2:
	return foot - Metrics.foot_center_offset("campus_bootstrap")

func polygon(rect: Rect2) -> PackedVector2Array:
	return PackedVector2Array([rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)])

func run() -> void:
	check(load("res://tests/native_test_isolation.gd").is_isolated_save(),"isolated save")
	if failures:
		quit(1)
		return
	var state = root.get_node("State")
	state.developer_mode = true
	state.d = state.initial()
	var before: Dictionary = state.d.duplicate(true)
	var art := Layered.new()
	art.ready = true
	var bits := PackedByteArray()
	bits.resize(8192)
	bits.fill(0)
	var corridors: Array[Rect2i] = [Rect2i(40,68,94,24),Rect2i(108,68,24,96),Rect2i(108,138,104,24)]
	for area: Rect2i in corridors:
		for y in range(area.position.y,area.end.y):
			for x in range(area.position.x,area.end.x):
				var index := y * 256 + x
				bits[index / 8] |= 1 << (index % 8)
	art.walk_supports = [{"id":"reviewed_s_bend","origin":Vector2.ZERO,"width":256,"height":256,"bits":bits,"bounds":Rect2(40,68,172,96),"routeCandidateFootCenters":PackedVector2Array()}]
	var world = load("res://scripts/world.gd").new()
	world.scene_id = "campus_bootstrap"
	world.world_size = Vector2(256,256)
	world._floor_bounds = Rect2(0,0,256,256)
	world.mask.resize(512)
	world.mask.fill(0)
	world.mask_meta = {"cellSize":4,"gridWidth":64,"gridHeight":64}
	world.campus_layers = art
	var start := anchor(Vector2(60,80))
	var goal := anchor(Vector2(190,150))
	world.player = start
	check(world.can_stand(start) and world.can_stand(goal),"S-bend endpoints have unchanged full-foot support")
	check(not world._floor_segment_clear(start,goal),"direct chord across unsupported ground is blocked")
	check(world._floor_plan(goal,world._floor_obstacles()).is_empty(),"physical corners alone cannot discover mask-only bends")
	art.walk_supports[0].routeCandidateFootCenters = PackedVector2Array([Vector2(120,80),Vector2(120,150),Vector2(84,111),Vector2(500,500)])
	var candidates: Array[Vector2] = world._floor_campus_detour_nodes(goal)
	check(candidates.has(anchor(Vector2(120,80))) and candidates.has(anchor(Vector2(120,150))),"foot-center candidates convert once to shared anchor coordinates")
	check(not candidates.has(anchor(Vector2(500,500))),"offscreen/world candidate excluded by current allowed bounds")
	check(not world.can_stand(anchor(Vector2(84,111))),"unsafe candidate remains unsupported")
	var tick := Time.get_ticks_usec()
	var route: Array[Vector2] = world._floor_plan(goal,world._floor_obstacles())
	var micros := Time.get_ticks_usec()-tick
	check(route.size()>1 and route[-1].is_equal_approx(goal),"candidate visibility graph reaches actual goal through bends")
	check(world.player == start,"planning never teleports or moves the player")
	check(state.d == before,"planning never writes story or save state")
	check(not route.has(anchor(Vector2(84,111))),"stand callable discards unsafe navigation hint")
	var previous := start
	for point: Vector2 in route:
		check(world.can_stand(point) and world._floor_segment_clear(previous,point),"every returned edge revalidates full foot, source/support and hazards")
		previous = point
	check(world._floor_planner.corner_count<=4 and world._floor_planner.edge_checks<=16,"small synthetic graph keeps bounded candidates and edge calls")
	world.player = goal
	check(not world._floor_plan(start,world._floor_obstacles()).is_empty(),"same candidates work in reverse")
	world.player = start
	var blocker := Rect2(108,110,24,1)
	world.collisions = [{"x":108,"y":110,"width":24,"height":1}]
	check(world._floor_plan(goal,world._floor_obstacles()).is_empty(),"existing story collision cannot be crossed via route hints")
	world.collisions = []
	art.water_regions = [{"bounds":blocker,"rects":[blocker]}]
	check(world._floor_plan(goal,world._floor_obstacles()).is_empty(),"true water cannot be crossed via route hints")
	art.water_regions = []
	art.solid_polygons = [polygon(blocker)]
	check(world._floor_plan(goal,world._floor_obstacles()).is_empty(),"measured solid cannot be crossed via route hints")
	art.solid_polygons = []
	check(not world._floor_plan(goal,world._floor_obstacles()).is_empty(),"restored valid world recovers without changing candidate data")
	world.player = anchor(Vector2(20,220))
	check(world._floor_campus_detour_nodes(anchor(Vector2(30,230))).is_empty(),"remote support contributes no unrelated candidate points")
	check(art.textures.is_empty() and not world.is_inside_tree(),"test uses no map texture or scene lifecycle")
	world.free()
	print("Reviewed route candidates: ",checks," checks, ",failures," failures; synthetic plan usec=",micros)
	quit(0 if failures == 0 else 1)
