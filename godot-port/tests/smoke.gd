extends SceneTree

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var packed: PackedScene = load("res://scenes/theater.tscn")
	if packed == null:
		quit(1)
		return
	var scene = packed.instantiate()
	root.add_child(scene)
	await process_frame
	if not scene.ready_for_test or scene.collision_count != scene.manifest.collisions.size():
		push_error("Spatial scene did not initialize with every source collider")
		quit(1)
		return
	if scene.occlusion_count != scene.manifest.occlusion.size():
		push_error("Missing source occlusion regions")
		quit(1)
		return
	await physics_frame
	for zone in ["lobby", "auditorium", "stage"]:
		scene.player.reset_to_legacy_spawn(scene.manifest.spawns[zone])
		await physics_frame
		var query := PhysicsShapeQueryParameters2D.new()
		var body_shape: CollisionShape2D = scene.player.get_child(0)
		query.shape = body_shape.shape
		query.transform = body_shape.global_transform
		query.exclude = [scene.player.get_rid()]
		if not scene.player.get_world_2d().direct_space_state.intersect_shape(query).is_empty():
			push_error("Spawn overlaps native collider: " + zone)
			quit(1)
			return
	scene.player.reset_to_legacy_spawn(scene.manifest.spawns.lobby)
	var start_x: float = scene.player.position.x
	Input.action_press("port_right")
	for index in range(120):
		await physics_frame
	Input.action_release("port_right")
	if scene.player.position.x <= start_x or scene.player.position.x > float(scene.manifest.world.width):
		push_error("Movement failed or escaped the world")
		quit(1)
		return
	scene.player.reset_to_legacy_spawn(scene.manifest.spawns.lobby)
	Input.action_press("port_up")
	for index in range(120):
		await physics_frame
	Input.action_release("port_up")
	for rect in scene.manifest.collisions:
		if rect.id == "admission_gate" and scene.player.position.y < float(rect.bottom):
			push_error("Player crossed the closed admission gate")
			quit(1)
			return
	Input.action_press("port_right")
	scene.player.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	if Input.is_action_pressed("port_right") or scene.player.velocity != Vector2.ZERO:
		push_error("Focus loss left movement pressed")
		quit(1)
		return
	print("GODOT_SPATIAL_SMOKE_OK")
	quit(0)
