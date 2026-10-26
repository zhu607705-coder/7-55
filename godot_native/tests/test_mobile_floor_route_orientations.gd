extends "res://tests/test_mobile_floor_route.gd"
## Reconstructed orientation/bag input contract, source fixture only.
func run() -> void:
	await setup_main()
	var start:=Vector2(1040,598.3125);var goal:=Vector2(1130,630)
	for dimensions: Vector2i in [Vector2i(430,860),Vector2i(844,390),Vector2i(960,540)]:
		for bag in [false,true]:
			await route_fixture(dimensions,start,bag)
			await tap_ground(goal);await walk_route(goal)
		await route_fixture(dimensions,start,false)
		await tap_ground(goal)
		var position:Vector2=shell.world.player
		var geometry:Rect2=shell.world_view.get_global_rect()
		await click(await reveal("rightArrow"))
		check(shell.inventory_dock.visible and not shell.inventory_handle.visible and shell.world_view.get_global_rect()==geometry and shell.world.player==position,"inline item use leaves the world transform and actor unchanged")
		await cancel_floor_touch(source_screen(goal))
		await tap_ground(goal);await walk_route(goal)
		await tap_ground(goal);position=shell.world.player
		var rotated:=Vector2i(844,390) if dimensions.x<dimensions.y else Vector2i(430,860)
		root.size=rotated;shell.size=Vector2(rotated);shell._layout();await frames()
		check(shell.world._floor_route.is_empty() and shell.world._floor_goal==Vector2.INF and shell.world.player==position,"orientation change cancels route and marker before movement")
		# route_fixture freezes processing for deterministic movement. Restore the
		# ordinary camera follow after resized root-space controls have settled.
		shell.world._update_camera()
		var return_goal:Vector2=Metrics.foot_rect(start).get_center()
		var local:Vector2=(return_goal-shell.world.camera)*shell.world.zoom+shell.world.size/2
		check(shell.world_view.get_global_rect().has_point(source_screen(return_goal)) and shell.world.exploration_safe_rect(true).has_point(local) and shell.world._direct_touch_role(local)=="map","return tap stays on actual visible map floor after the frozen camera follows resized controls")
		await tap_ground(return_goal);await walk_route(return_goal)
	await finish("MOBILE_FLOOR_ROUTE_ORIENTATIONS")
