extends "res://tests/test_mobile_floor_route.gd"
## Deterministic frame-boundary regression; fixture, not manual-play evidence.
func run() -> void:
	await setup_main();await route_fixture(Vector2i(390,844));await tap_ground(GOAL)
	var w=shell.world
	var before:=story();var action_count:=actions.size();var geometry: Array=w.collisions.duplicate(true)
	var planned: Array[Vector2]=w._floor_route.duplicate()
	check(planned.size()>1,"real root tap retains its authored dogleg route")
	for waypoint: Vector2 in planned:
		var ticks:=0
		while w.player.distance_to(waypoint)>8.25 and ticks<800:
			w._process(.05);ticks+=1
		check(ticks<800 and not w._floor_route.is_empty(),"bounded frames approach each waypoint")
		var remaining: float=w.player.distance_to(waypoint)
		var route_before: Array[Vector2]=w._floor_route.duplicate()
		var previous: Vector2=w.player
		# Legal frame delta deliberately leaves a sub-pixel distance which the
		# old coordinate-relative is_equal_approx mistook for arrival.
		w._process((remaining-.004)/165.0)
		check(w.player!=waypoint and w.player.distance_to(waypoint)>.002,"partial frame remains short of the exact waypoint")
		check(w._floor_status=="moving" and w._floor_route==route_before,"partial frame cannot retire an approximate waypoint")
		check(w.can_stand(w.player) and previous.distance_to(w.player)<=remaining-.004+.001,"partial frame respects collision and native speed")
		previous=w.player
		w._process(.008/165.0)
		check(w.player==waypoint,"next legal frame reaches the exact endpoint")
		check(w._floor_route.size()==route_before.size()-1,"exact endpoint retires exactly one waypoint")
		check(w.can_stand(w.player) and previous.distance_to(w.player)<=.008+.001,"final sub-pixel step remains legal and bounded")
	check(w._floor_status=="arrived" and Metrics.foot_rect(w.player).get_center().distance_to(GOAL)<.001,"deterministic route preserves the strict full-foot destination")
	check(w.collisions==geometry and story()==before and actions.size()==action_count,"exact arrival changes no geometry or progression")
	# The planner can legitimately return the current anchor for a zero-length
	# request. Exercise its real result without pretending this is pointer input.
	var start: Vector2=w.player
	w._floor_route=w._floor_planner.plan(start,start,w._floor_obstacles(),w._floor_bounds,w._floor_stand,func(a: Vector2,b: Vector2):return w._floor_segment_clear(a,b))
	w._floor_status="moving"
	check(w._floor_route==[start],"zero-length planner request retains the exact current anchor")
	w._process(.016)
	check(w.player==start and w._floor_route.is_empty() and w._floor_status=="arrived","zero-length waypoint completes without movement or hanging")
	# A long frame must keep the existing 50 ms cap and ordered waypoint steps.
	# Synthetic close waypoints isolate traversal, without changing geometry.
	w._floor_route.assign([start,start+Vector2(1,0),start+Vector2(2,0)])
	w._floor_goal=start+Vector2(2,0)+Metrics.FOOT_CENTER_OFFSET;w._floor_status="moving"
	for expected: Vector2 in [start,start+Vector2(1,0),start+Vector2(2,0)]:
		var count: int=w._floor_route.size()
		var previous: Vector2=w.player
		w._process(2.0)
		check(w.player==expected and w._floor_route.size()==count-1,"large delta retires waypoints in order, including a zero-length prefix")
		check(w.can_stand(w.player) and previous.distance_to(w.player)<=165*.05+.001,"large delta remains collision-safe and speed-capped")
	check(w._floor_status=="arrived" and w._floor_route.is_empty(),"large-delta route completes only at its exact final endpoint")
	start=w.player
	w._floor_route.assign([start+Vector2(20,0)])
	w._floor_goal=start+Vector2(20,0)+Metrics.FOOT_CENTER_OFFSET;w._floor_status="moving"
	w._process(2.0)
	check(w.player==start+Vector2(8.25,0) and w._floor_status=="moving" and w._floor_route.size()==1,"two-second frame advances only the capped 50 ms distance")
	w._process(2.0);w._process(2.0)
	check(w.player==start+Vector2(20,0) and w._floor_status=="arrived" and w._floor_route.is_empty(),"later capped frames reach the long segment exactly")
	check(w.collisions==geometry and story()==before and actions.size()==action_count,"degenerate and large-delta routes emit no action or story change")
	await finish("MOBILE_FLOOR_EXACT_ARRIVAL")
