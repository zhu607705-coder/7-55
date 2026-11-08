extends SceneTree
## Exercise normal map input, exact whole-foot arrival, and the source-pixel
## collision and depth regressions from the campus playtest.
const Metrics = preload("res://scripts/player_metrics.gd")
var failures := 0
var checks := 0
var world: Control

func _initialize() -> void: run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if ok: return
	failures += 1
	push_error(label)

func anchor(foot: Vector2) -> Vector2:
	return Metrics.anchor_from_foot_center(foot, "campus_bootstrap")

func tap(foot: Vector2, touch: bool) -> void:
	var local: Vector2 = (foot - world.camera) * world.zoom + world.size / 2.0
	if touch:
		var event := InputEventScreenTouch.new()
		event.position = local
		event.pressed = true
		world._gui_input(event)
		var release := event.duplicate() as InputEventScreenTouch
		release.pressed = false
		world._gui_input(release)
	else:
		var event := InputEventMouseButton.new()
		event.position = local
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = true
		world._gui_input(event)
		event.pressed = false
		world._gui_input(event)

func finger(index: int, point: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = point
	event.pressed = pressed
	world._gui_input(event)

func move_to(foot: Vector2, touch: bool) -> void:
	var started := Time.get_ticks_usec()
	tap(foot, touch)
	var plan_ms := float(Time.get_ticks_usec() - started) / 1000.0
	check(world._floor_status == "moving", "ordinary input plans to %s" % foot)
	for i in 1200:
		if world._floor_status != "moving": break
		world._process(1.0 / 30.0)
	check(world._floor_status == "arrived" and world.player.distance_to(anchor(foot)) < 0.001, "exact destination reached at %s (actual %s, goal %s, status %s)" % [foot, Metrics.foot_center(world.player, "campus_bootstrap"), world._floor_goal, world._floor_status])
	print("Campus input to ", foot, " planned in ", plan_ms, " ms")

func covers(id: String, foot: Vector2) -> bool:
	for entry: Dictionary in world.campus_layers.render_plan(world._ground_y(anchor(foot)), true):
		if entry.row.id == id: return true
	return false

func run() -> void:
	if not load("res://tests/native_test_isolation.gd").is_isolated_save():
		push_error("Campus road test needs isolated user data")
		quit(1)
		return
	var state: Node = root.get_node("State")
	state.d = state.initial()
	state.d.native.chapter = 2
	state.d.native.page = "zjuding"
	state.d.currentScene = "zjuding"
	state.d.actOne.dormHubUnlocked = true
	state.d.actOne.phase = "movement_ready"
	state.d.actOne.movementEnabled = true
	state.d.actOne.canLeaveDorm = true
	state.d.actOne.manualControlTested = true
	root.size = Vector2i(1280, 720)
	var main: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	state.act("c2_enter_dorm")
	await process_frame
	state.act("c2_dorm_exit")
	for i in 6: await process_frame
	world = main.world
	check(world.scene_id == "campus_bootstrap" and world.campus_layers.ready, "ordinary dorm exit mounts the authored campus")
	if failures > 0: quit(1); return
	world.transition_alpha = 0
	world.set_process(false)

	# An arbitrary slope on the same road must stay one line, even beyond the
	# old 64px local limit. Observe movement through the normal update path.
	var diagonal_start := Vector2(2550.25, 650.5)
	var diagonal_goal := Vector2(2774.75, 669.25)
	world.player = anchor(diagonal_start)
	world.camera = Vector2(2650, 656)
	tap(diagonal_goal, false)
	check(world._floor_route.size() == 1, "open road has no snapped endpoints or staircase waypoints")
	var diagonal_steps := 0
	var diagonal_direction := (diagonal_goal - diagonal_start).normalized()
	for i in 120:
		if world._floor_status != "moving": break
		var previous: Vector2 = world.player
		world._process(1.0 / 30.0)
		var displacement: Vector2 = world.player - previous
		if displacement.x > 0 and displacement.y > 0 and absf(displacement.cross(diagonal_direction)) < .001:
			diagonal_steps += 1
	check(diagonal_steps > 30 and world.player.distance_to(anchor(diagonal_goal)) < .001, "the actor actually travels both axes on the same line to the exact click")

	var curb_start := Vector2(2550.25, 683.5)
	var curb_goal := Vector2(2774.75, 683.5)
	world.player = anchor(curb_start)
	world.camera = Vector2(2650, 656)
	tap(curb_goal, true)
	check(world._floor_route.size() == 1, "a clear path on the same road has no forced lane change")
	var curb_route: Array[Vector2] = world._floor_route.duplicate()
	var old_zoom: float = world.zoom
	var wheel := InputEventMouseButton.new()
	wheel.position = world.size * .5
	wheel.button_index = MOUSE_BUTTON_WHEEL_UP
	wheel.pressed = true
	world._gui_input(wheel)
	world._process(1.0 / 30.0)
	check(world.zoom > old_zoom and world._floor_route == curb_route and world._floor_goal == curb_goal, "wheel zoom keeps the committed world-space route")

	var left: Vector2 = world.size * Vector2(.40, .43)
	var right: Vector2 = world.size * Vector2(.55, .43)
	finger(2, left, true)
	var before_pinch: Vector2 = world.player
	world._process(1.0 / 30.0)
	finger(3, right, true)
	var drag := InputEventScreenDrag.new()
	drag.index = 3
	drag.position = right + Vector2(40, 0)
	old_zoom = world.zoom
	world._gui_input(drag)
	world._process(1.0 / 30.0)
	check(world.zoom > old_zoom and world.player == before_pinch and world._floor_route == curb_route, "pinching pauses movement and retains the route")
	finger(3, drag.position, false)
	finger(2, left, false)
	check(not world.direct_gestures.has_active() and world._floor_goal == curb_goal, "releasing a pinch does not start a replacement route")

	var old_backing: Vector2i = main.world_viewport.size
	root.size = Vector2i(1120, 640)
	for i in 3: await process_frame
	main._layout()
	check(main.world_viewport.size != old_backing and world._floor_route == curb_route and world._floor_goal == curb_goal, "shell resize reprojects the existing destination")
	finger(2, world.size * .45, true)
	var before_blur: Vector2 = world.player
	world.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	world.notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
	world._process(.05)
	check(not world.direct_gestures.has_active() and world.player == before_blur and world._floor_route == curb_route, "focus loss clears the held pointer and pauses the route")
	world.notification(NOTIFICATION_APPLICATION_FOCUS_IN)
	world.notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_IN)
	for i in 150:
		if world._floor_status != "moving": break
		world._process(1.0 / 30.0)
	check(world._floor_status == "arrived" and world.player == anchor(curb_goal), "focus return finishes the original click without another tap")
	root.size = Vector2i(1280, 720)
	for i in 3: await process_frame
	main._layout()
	world.zoom = 1.1

	# The screenshot's south road is painted underneath the unused part of
	# the footer. The map must accept clicks there from the lakeside curve.
	var path_start := Vector2(2970.5, 1119.0)
	var south_road := Vector2(2977.0, 1373.0)
	world.subtitle = ""
	world.player = anchor(path_start)
	world.camera = south_road - Vector2(0, world.size.y * .445 / world.zoom)
	var lower_click: Vector2 = (south_road - world.camera) * world.zoom + world.size / 2.0
	check(not world.exploration_safe_rect(true).has_point(lower_click), "south road click reproduces the old footer rejection")
	move_to(south_road, true)

	world.player = anchor(path_start)
	world._update_camera()
	var down := InputEventKey.new()
	down.keycode = KEY_DOWN
	down.physical_keycode = KEY_DOWN
	down.pressed = true
	Input.parse_input_event(down)
	Input.flush_buffered_events()
	for i in 230:
		if Metrics.foot_center(world.player, "campus_bootstrap").y >= 1350.0: break
		world._process(1.0 / 60.0)
	var release := down.duplicate() as InputEventKey
	release.pressed = false
	Input.parse_input_event(release)
	Input.flush_buffered_events()
	var path_finish := Metrics.foot_center(world.player, "campus_bootstrap")
	check(path_finish.y >= 1350.0 and path_finish.x < 2950.0 and world.can_stand(world.player), "one held arrow slides around the path bends and onto the road (actual %s)" % path_finish)

	# Actual playtest click on opposite sides of the lawn and canal. These
	# foot coordinates come from CampusPathGrid with the current source mask.
	var block_start := Vector2(1437.625, 2197)
	var block_goal := Vector2(1139.25, 2206.375)
	world.player = anchor(block_start)
	world.camera = Vector2(1288, 2110)
	tap(block_goal, false)
	var block_route: Array[Vector2] = []
	for point: Vector2 in world._floor_route:
		block_route.append(Metrics.foot_center(point, "campus_bootstrap"))
	var web_route: Array[Vector2] = [Vector2(1452, 2196), Vector2(1452, 1812), Vector2(1404, 1764), Vector2(1188, 1764), Vector2(1164, 1788), block_goal]
	check(block_route == web_route, "canal route selects the exact Web waypoints through both intersections")
	move_to(block_goal, false)

	# The start and goal are both in view. Their road route goes north of the
	# initial camera, which used to be the hard limit of the click planner.
	world.player = anchor(Vector2(698, 3310))
	world.camera = Vector2(950, 3210)
	var goal := Vector2(1212, 3020)
	var visible: Rect2 = world._floor_visible_rect()
	check(visible.has_point(goal), "road test target is visible")
	tap(goal, false)
	var detours_offscreen := false
	var uses_arterial := false
	var previous_foot := Vector2(698, 3310)
	for point: Vector2 in world._floor_route:
		var foot := Metrics.foot_center(point, "campus_bootstrap")
		detours_offscreen = detours_offscreen or not visible.has_point(foot)
		var middle := previous_foot.lerp(foot, .5)
		uses_arterial = uses_arterial or (middle.x > 740 and middle.x < 1212 and middle.y < 2950)
		previous_foot = foot
	check(detours_offscreen and uses_arterial, "the route follows the arterial beyond the current view")
	check(world._floor_route.size() > 0 and world._floor_route[-1].distance_to(anchor(goal)) < .001, "arterial route keeps the selected point as the last waypoint")
	move_to(goal, false)

	world.player = anchor(Vector2(1050, 3130))
	world.camera = Vector2(1040, 3170)
	move_to(Vector2(1038, 3230), true)
	check(world.can_stand(anchor(Vector2(1118, 3240))), "walkway behind the circular roof is open")
	check(not world.can_stand(anchor(Vector2(1118, 3262))), "the circular hall's floor-level base remains solid")
	check(not world.can_stand(anchor(Vector2(3747, 1673))) and not world.can_stand(anchor(Vector2(3812, 1673))), "both library planters reject the player foot box")
	check(world.can_stand(anchor(Vector2(3780, 1680))), "the library entry stays walkable between planters")
	check(not world.can_stand(anchor(Vector2(2790, 2811))) and world.can_stand(anchor(Vector2(2791, 2834))), "central planter base blocks feet while its front walkway stays open")
	check(covers("right_v4__tree_181", Vector2(2730, 2792)), "walking behind the small planter draws its canopy over the player")
	check(not covers("right_v4__tree_182", Vector2(2791, 2834)), "standing in front of the roadside planter draws the player over its canopy")
	check(covers("right_v4__tree_173", Vector2(2379, 2797)) and not covers("right_v4__tree_173", Vector2(2379, 2834)), "west walkway tree only covers actors behind its trunk")
	var west_planter_side := Vector2(2356.75, 2813.5)
	check(world.can_stand(anchor(west_planter_side)) and covers("right_v4__tree_173", west_planter_side), "the legal side of the planter is behind the actual trunk contact")
	var annex_front := Vector2(778, 3275)
	check(world.can_stand(anchor(annex_front)) and not covers("chengzhang_v10_west_annex", annex_front), "annex door jamb does not cover an actor standing on its front steps")
	check(covers("chengzhang_v10_west_annex", Vector2(778, 3120)), "the same building still covers an actor behind its foot line")
	check(not world.can_stand(anchor(Vector2(4050, 2197))) and not world.can_stand(anchor(Vector2(4210, 2040))), "East 5–7 redraw retains the original closed courtyard and pond")

	main.queue_free()
	await process_frame
	print("Campus road and depth: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
