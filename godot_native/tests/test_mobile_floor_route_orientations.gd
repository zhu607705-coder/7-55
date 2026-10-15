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
		var position: Vector2=shell.world.player
		await click(shell.inventory_handle)
		check(shell.compact_inventory_open and shell.world._floor_route.is_empty() and shell.world.player==position,"opening bag changes transform and cancels without movement")
		await tap_ground(goal);await walk_route(goal)
		await tap_ground(Vector2(1040,630));position=shell.world.player
		await click(shell.inventory_handle)
		check(not shell.compact_inventory_open and shell.world._floor_route.is_empty() and shell.world.player==position,"closing bag cancels before movement")
		await tap_ground(Vector2(1040,630));await walk_route(Vector2(1040,630))
		await tap_ground(goal);position=shell.world.player
		var rotated:=Vector2i(844,390) if dimensions.x<dimensions.y else Vector2i(430,860)
		root.size=rotated;shell.size=Vector2(rotated);shell._layout();await frames()
		check(shell.world._floor_route.is_empty() and shell.world._floor_goal==Vector2.INF and shell.world.player==position,"orientation change cancels route and marker before movement")
		await tap_ground(goal);await walk_route(goal)
	await finish("MOBILE_FLOOR_ROUTE_ORIENTATIONS")
