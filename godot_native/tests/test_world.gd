extends SceneTree
const Metrics = preload("res://scripts/player_metrics.gd")
var failures := 0
func _initialize() -> void: call_deferred("_run")
func check(value: bool,message: String) -> void:
	if not value: failures += 1; push_error("TEST FAILED: "+message)
func _run() -> void:
	var state = root.get_node("State")
	state.developer_mode = true
	var shell = load("res://scenes/main.tscn").instantiate()
	root.add_child(shell)
	await process_frame
	var world = shell.world
	for scene in ["dorm_hub","campus_bootstrap","library_interior","canteen_interior","theater_interior","qizhen_lake","duan_yongping_temporal_maze"]:
		state.d.native.scene = scene
		state.d.rpgCheckpoint = ""
		state.d.native.positions = {}
		world.refresh_world()
		check(world.background != null,scene+" background resource loads")
		check(world.can_stand(world.player),scene+" safe spawn is not blocked")
		check(not world.can_stand(Vector2(-1,0)),scene+" rejects outside world")
		if scene == "canteen_interior":
			_check_native_canteen(world)
			continue
		for box in world.collisions:
			var rect: Rect2 = world._rect(box)
			if rect.size.x > 0 and rect.size.y > 0: check(not world.can_stand(rect.get_center()-Vector2(0,31.6875)),scene+" solid collision "+str(box.get("id","")))
	state.d.native.scene = "duan_yongping_temporal_maze"
	for floor in ["A1","A2","A3"]:
		state.d.chapter4.floor = floor
		world.refresh_world()
		check(world.world_size == Vector2(1672,941),floor+" exact floor size")
		check(not world.can_stand(Vector2(1680,500)),floor+" cannot enter inter-floor storage")
	state.d.native.scene = "dorm_hub"
	state.d.actOne.phase = "inventory_required"
	state.d.native.positions = {}
	world.refresh_world()
	check(world.player == Vector2(570,460),"inventory spawn is source650,920 transformed")
	check(float(state.d.native.player.x)==650 and float(state.d.native.player.y)==920,"controller receives actual source-pixel coordinates")
	shell.queue_free()
	await process_frame
	print("World collision/scene tests: ","PASS" if failures == 0 else "FAIL", " (",failures," failures)")
	quit(0 if failures==0 else 1)

func _check_native_canteen(world: Control) -> void:
	# The native scene replaces the baked source rectangles. Read its authored
	# geometry independently, so missing runtime solids cannot erase test cases.
	var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/native/canteen-object-layout.json"))
	var native: Node2D = world.native_canteen
	check(is_instance_valid(native) and native.is_active(),"canteen native collision owner is active")
	if not is_instance_valid(native): return
	check(layout.structures.size() == 15 and native.structures.size() == 15,"canteen retains all 15 measured structures")
	check(layout.objects.size() == 132 and native.objects.size() == 132,"canteen retains all 132 independent objects")
	for row: Dictionary in layout.structures:
		var polygon := _polygon(row.polygon)
		var registered := false
		for actual: Dictionary in native.structures:
			if actual.id == row.id:
				registered = actual.polygon == polygon and actual.body.collision_layer == 1
		check(registered,"canteen active structure matches authored polygon "+str(row.id))
		_check_solid_polygon(world,polygon,"canteen structure "+str(row.id))
	var solid_props := 0
	for row: Dictionary in layout.objects:
		if row.get("footprint",[]).is_empty(): continue
		solid_props += 1
		var polygon := _polygon(row.footprint,Vector2(row.position[0],row.position[1]))
		var prop: Node2D = native.objects.get(row.id)
		check(is_instance_valid(prop),"canteen solid prop is registered "+str(row.id))
		if is_instance_valid(prop):
			check(prop.collision_polygon() == polygon and prop.body.collision_layer == 1,"canteen active prop matches authored footprint "+str(row.id))
		_check_solid_polygon(world,polygon,"canteen prop "+str(row.id))
	check(solid_props == 96,"canteen checks all 96 solid prop footprints")
	for box: Dictionary in native.dynamic_collisions:
		check(not world.can_stand(world._rect(box).get_center()-Metrics.FOOT_CENTER_OFFSET),"canteen dynamic foot collision "+str(box.get("id","")))
	# Keep positive space coverage: a blanket blocker must not satisfy the solids.
	for point: Vector2 in [Vector2(1194,834),Vector2(1473,208),Vector2(1320,400),Vector2(1470,576),Vector2(260,870),Vector2(755,250),Vector2(1349,835)]:
		check(world.can_stand(point),"canteen authored entrance/task aisle stays open "+str(point))

func _polygon(points: Array, offset := Vector2.ZERO) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point: Array in points: result.append(offset+Vector2(point[0],point[1]))
	return result

func _check_solid_polygon(world: Control, polygon: PackedVector2Array, label: String) -> void:
	# A concave frame's bounding-box center can lie in its walkable opening.
	# Triangle interiors instead probe every authored solid component.
	var triangles := Geometry2D.triangulate_polygon(polygon)
	check(not triangles.is_empty(),label+" has triangulatable geometry")
	for i in range(0,triangles.size(),3):
		var center := (polygon[triangles[i]]+polygon[triangles[i+1]]+polygon[triangles[i+2]])/3.0
		check(not world.can_stand(center-Metrics.FOOT_CENTER_OFFSET),label+" blocks triangle "+str(i/3))
