extends SceneTree
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
