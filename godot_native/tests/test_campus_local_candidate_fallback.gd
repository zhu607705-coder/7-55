extends SceneTree
## Visible U-shaped floor proves local pruning never removes the full fallback.
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
		push_error("Local candidate fallback: " + label)

func anchor(center: Vector2) -> Vector2:
	return center - Metrics.foot_center_offset("campus_bootstrap")

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
	# Both ends are at y=80. The only connection goes down to y=180, well
	# outside the first-attempt corridor. The entire U is inside allowed bounds.
	var regions: Array[Rect2i] = [Rect2i(68,60,24,132),Rect2i(68,168,124,24),Rect2i(168,60,24,132)]
	for area: Rect2i in regions:
		for y in range(area.position.y,area.end.y):
			for x in range(area.position.x,area.end.x):
				var i := y * 256 + x
				bits[i / 8] |= 1 << (i % 8)
	var candidate_centers := PackedVector2Array([Vector2(80,100),Vector2(180,100),Vector2(80,180),Vector2(180,180)])
	art.walk_supports = [{"id":"visible_reviewed_u","origin":Vector2.ZERO,"width":256,"height":256,"bits":bits,"bounds":Rect2(68,60,124,132),"routeCandidateFootCenters":candidate_centers}]
	var world = load("res://scripts/world.gd").new()
	world.scene_id = "campus_bootstrap"
	world.world_size = Vector2(256,256)
	world._floor_bounds = Rect2(0,0,256,256)
	world.mask.resize(512)
	world.mask.fill(0)
	world.mask_meta = {"cellSize":4,"gridWidth":64,"gridHeight":64}
	world.campus_layers = art
	var start := anchor(Vector2(80,80))
	var goal := anchor(Vector2(180,80))
	world.player = start
	var local: Array[Vector2] = world._floor_campus_detour_nodes(goal,true)
	var all: Array[Vector2] = world._floor_campus_detour_nodes(goal)
	check(local.size()==2 and all.size()==4,"local attempt excludes distant U bends but complete attempt retains them")
	check(not local.has(anchor(Vector2(80,180))) and all.has(anchor(Vector2(80,180))),"outside-corridor visible bend remains available for fallback")
	var obstacles: Array = world._floor_obstacles()
	var clear: Callable = func(a:Vector2,b:Vector2)->bool: return world._floor_segment_clear(a,b,obstacles,true)
	check(world._floor_planner.plan_with_candidates(start,goal,obstacles,world._floor_bounds,world._floor_stand,clear,local).is_empty(),"local-only graph genuinely cannot cross U-shaped unsupported center")
	var tick := Time.get_ticks_usec()
	var route: Array[Vector2] = world._floor_plan(goal,obstacles)
	var micros := Time.get_ticks_usec()-tick
	check(route.size()>1 and route[-1].is_equal_approx(goal),"production plan retries full visible candidates and finds U detour")
	var previous := start
	for point: Vector2 in route:
		check(world._floor_bounds.has_point(point),"fallback stays inside current visible allowed bounds")
		check(world.can_stand(point) and world._floor_segment_clear(previous,point),"fallback edge passes unchanged current whole-foot checks")
		previous = point
	check(world.player==start and state.d==before,"neither candidate pass moves player or story state")
	world.player = goal
	check(not world._floor_plan(start,obstacles).is_empty(),"U fallback works in reverse")
	world.player = start
	world.collisions = [{"x":130,"y":168,"width":1,"height":24}]
	check(world._floor_plan(goal,world._floor_obstacles()).is_empty(),"new story barrier invalidates old edge proofs on next plan")
	world.collisions = []
	check(not world._floor_plan(goal,world._floor_obstacles()).is_empty(),"removing barrier restores route with freshly validated proofs")
	var water := Rect2(130,168,1,24)
	art.water_regions = [{"bounds":water,"rects":[water]}]
	check(world._floor_plan(goal,world._floor_obstacles()).is_empty(),"fallback cannot use a water-crossing hint chain")
	art.water_regions = []
	# A nearby destination is handled by the small local graph and direct edge.
	var near := anchor(Vector2(80,110))
	var near_route: Array[Vector2] = world._floor_plan(near,world._floor_obstacles())
	check(near_route.size()==1 and near_route[0].is_equal_approx(near),"nearby clear route does not need global U bends")
	check(world._floor_planner.edge_checks==1 and world._floor_planner.corner_count==0,"successful direct local attempt does not construct fallback graph")
	check(art.textures.is_empty() and not world.is_inside_tree(),"fixture uses no textures or scene lifecycle")
	world.free()
	print("Local candidate fallback: ",checks," checks, ",failures," failures; U plan usec=",micros)
	quit(0 if failures == 0 else 1)
