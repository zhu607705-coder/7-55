extends SceneTree
## CPU/headless preparation only. No high-detail ground or GPU acceptance claim.
const ROAD = preload("res://campuses/buct_changping/scripts/north_road_extension.gd")
const BODY = preload("res://campuses/buct_changping/scripts/registered_hd_building.gd")
var campus: Node2D
var checks := 0
var failures: Array[String] = []
var trace: Array = []
var arrivals: Array = []
var motion_ticks := 0
var illegal_ticks := 0
var maximum_speed := 0.0
var active_keys: Array[int] = []
var default_mode := false
func _initialize() -> void: run.call_deferred()
func tick() -> void: await physics_frame;await process_frame
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label);push_error(label)
func record() -> void:
	motion_ticks += 1
	var point: Vector2 = campus.visitor.position
	if not campus.is_walkable(point): illegal_ticks += 1
	maximum_speed = maxf(maximum_speed,campus.visitor.last_motion.length()*Engine.physics_ticks_per_second)
	if motion_ticks%4 == 0: trace.append([point.x,point.y])
func set_keys(next: Array[int]) -> void:
	for code in active_keys:
		if code not in next: key(code,false)
	for code in next:
		if code not in active_keys: key(code,true)
	active_keys = next
func key(code: int, pressed: bool) -> void:
	var event := InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=pressed
	Input.parse_input_event(event)
func walk_path(target: Vector2) -> void:
	check(campus.path_to(target),"Production path exists to "+str(target))
	var deadline := Time.get_ticks_msec()+28000
	while campus.visitor.position.distance_to(target)>3.1 and Time.get_ticks_msec()<deadline:
		await tick();record()
	check(campus.visitor.position.distance_to(target)<=3.1,"Continuous physical path arrives "+str(target))
	campus.current_path.clear()
func manual_to(target: Vector2) -> void:
	var start: Vector2i = campus.nearest_cell(campus.visitor.position)
	var end: Vector2i = campus.nearest_cell(target)
	var route: PackedVector2Array = campus.grid.get_point_path(start,end)
	check(not route.is_empty(),"Manual input reference path exists "+str(target))
	if route.is_empty():return
	var index := 0
	var deadline := Time.get_ticks_msec()+12000
	while campus.visitor.position.distance_to(target)>3.1 and Time.get_ticks_msec()<deadline:
		while index < route.size()-1 and campus.visitor.position.distance_to(route[index])<2.0:index+=1
		var d: Vector2 = route[index]-campus.visitor.position
		var next: Array[int] = []
		if absf(d.x)>maxf(.4,.40*absf(d.y)):next.append(KEY_D if d.x>0 else KEY_A)
		if absf(d.y)>maxf(.4,.40*absf(d.x)):next.append(KEY_S if d.y>0 else KEY_W)
		set_keys(next)
		await tick();record()
	set_keys([]);await tick()
	check(campus.visitor.position.distance_to(target)<=3.1,"True key-input arrives "+str(target))
	arrivals.append({"target":[target.x,target.y],"actual":[campus.visitor.position.x,campus.visitor.position.y],"kind":"physical_key_events"})
	var release: Vector2 = campus.visitor.position
	for i in range(4):await tick()
	check(campus.visitor.position.distance_to(release)<.001,"Key release has zero drift "+str(target))
func run() -> void:
	default_mode = OS.get_environment("BUCT_NORTH_DEFAULT")=="1"
	campus=load("res://campuses/buct_changping/scenes/playable.tscn").instantiate();campus.enable_north_hd_region=default_mode;root.add_child(campus)
	await tick();await tick()
	check(campus.initialized,"Exact production campus initializes")
	var original_poly_count: int = 82
	var old_edges: Array[PackedVector2Array] = []
	for edge in campus.east_road_extension.profile.exposed_union_boundary_segments:old_edges.append(campus.pts(edge))
	var old_collider: Node = campus.objects.get_node("north_sports_hall/GroundFootprint0")
	var old_shape: PackedVector2Array = old_collider.get_child(0).polygon.duplicate()
	var profile: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://campuses/buct_changping/data/north_sports_hall_registration.json"))
	var body:Node2D
	if default_mode:
		check(is_instance_valid(campus.north_hd_region),"Default full HD region remains installed during true movement")
		body=campus.north_hd_region.bodies.north_sports_hall
	else:
		body=Node2D.new();body.set_script(BODY);campus.objects.add_child(body)
		check(body.configure(profile,load(profile.body_asset)),"Original RGBA registration validates and configures")
	check(body.body_passes.size()==2 and body.surface_count==1,"One solid surface uses exactly two common-quad passes")
	check(body.alpha_bytes.size()==1275*1233,"Only original per-texel alpha is retained")
	check(body.hit_test_alpha(Vector2(681,485)),"Stepped central equipment is solid alpha, not a courtyard")
	check(not body.hit_test_alpha(Vector2(627,435)),"Transparent outside body is not picked")
	check(old_collider.get_child(0).polygon==old_shape,"Original building collision stays unchanged")
	if not default_mode:body.hide()
	var road = ROAD.install(campus)
	check(is_instance_valid(road),"Additive road installs")
	campus.walk_cells.clear();campus._build_grid()
	check(campus.walk_polys.size()==original_poly_count+1,"One bounded pavement polygon added")
	var joined_edges: Array[PackedVector2Array] = []
	for edge in road.profile.exposed_joined_union_boundary_segments:joined_edges.append(campus.pts(edge))
	check(campus.east_road_extension.exposed_edges.size()==59 and campus.east_road_extension.exposed_edges==joined_edges,"Joined union retains exact accepted 59-edge profile boundary")
	check(campus.is_walkable(Vector2(731,670)),"Old y670 north cap now opens with full radius3 clearance")
	check(campus.is_walkable(Vector2(666,548)),"Conservative gray-road southwest stop is legal")
	check(not campus.is_walkable(Vector2(699,536)),"Uncertain planted frontage remains closed")
	check(not campus.is_walkable(Vector2(716,601)),"East lawn remains closed")
	check(not campus.is_walkable(Vector2(676,605)),"West lawn remains closed")
	check(not campus.is_walkable(Vector2(684,510)),"Original building footprint remains closed")
	check(campus.visitor.speed==88 and campus.visitor.display_height==18,"Shared student speed88 and height18 preserved")
	await walk_path(Vector2(731,676))
	await manual_to(Vector2(707,620))
	await manual_to(Vector2(666,548))
	await manual_to(Vector2(707,620))
	await manual_to(Vector2(731,676))
	await walk_path(Vector2(760,877))
	check(illegal_ticks==0,"Every actual forward/reverse physical tick stays legal")
	check(maximum_speed<=88.05,"No input movement exceeds speed88")
	check(campus.visited.is_empty(),"New exterior traversal creates no tour progress")
	road.uninstall();await tick()
	check(campus.walk_polys.size()==original_poly_count and campus.east_road_extension.exposed_edges==old_edges,"Road removal restores exact previous union and permissions")
	check(old_collider.get_child(0).polygon==old_shape,"Physical footprint remains exact after entire traversal")
	var output := OS.get_environment("BUCT_NORTH_QA_DIR")
	if not output.is_empty():
		var file := FileAccess.open(output.path_join("default-north-walk-result.json" if default_mode else "preparation-result.json"),FileAccess.WRITE)
		file.store_string(JSON.stringify({"checks":checks,"failures":failures,"physical_ticks":motion_ticks,"illegal_ticks":illegal_ticks,"maximum_speed":maximum_speed,"position_writes_after_initial_spawn":0,"arrivals":arrivals,"trace_every4ticks":trace,"scope":"Default full-region true movement" if default_mode else "Headless original-art road and registered body preparation only; no ground or GPU acceptance"},"  "));file.close()
	campus.queue_free();await process_frame
	print("BUCT_NORTH_PREPARATION checks=%d failures=%d"%[checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
