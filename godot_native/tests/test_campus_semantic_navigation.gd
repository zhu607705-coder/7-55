extends SceneTree
const Metrics = preload("res://scripts/player_metrics.gd")
var failures := 0
var checks := 0
func _initialize() -> void: run.call_deferred()
func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error("Semantic campus: " + label)
func anchor(point: Vector2) -> Vector2: return point - Metrics.foot_center_offset("campus_bootstrap")
func run() -> void:
	check(load("res://tests/native_test_isolation.gd").is_isolated_save(), "isolated save")
	if failures: quit(1); return
	var state = root.get_node("State")
	state.developer_mode = true
	state.d = state.initial()
	# Main-shell fixture must actually enter RPG layout before testing taps.
	state.d.native.chapter = 2
	state.d.native.scene = "campus_bootstrap"
	state.d.native.page = "phone_home"
	state.d.runtimeMode = "rpg"
	state.d.rpgScene = "campus_bootstrap"
	state.d.actOne.phase = "complete"
	root.size = Vector2i(1440,900)
	var shell = load("res://scenes/main.tscn").instantiate()
	root.add_child(shell)
	await process_frame
	state.d.native.scene = "campus_bootstrap"
	state.d.rpgCheckpoint = ""
	state.d.native.positions = {}
	var world = shell.world
	world.refresh_world()
	shell._layout()
	await process_frame
	await process_frame
	world.set_process(false)
	check(shell.world_frame.is_visible_in_tree() and world.is_visible_in_tree(), "main RPG layout exposes the real world surface")
	check(world.size.x > 0 and world.size.y > 0, "world viewport has resolved dimensions")
	check(world.campus_layers.ready, "semantic resources load")
	if not world.campus_layers.ready: quit(1); return
	var art = world.campus_layers
	check(int(art.manifest.get("semanticLayerVersion", 0)) == 2, "explicit semantic version")
	var raised := 0
	for row: Dictionary in art.manifest.layers:
		if row.get("renderPass") != "raised": continue
		raised += 1
		if row.get("depthMode", "baseline") != "baseline": continue
		for delta: float in [-1.0, 1.0]:
			var back := 0
			var front := 0
			for item: Dictionary in art.render_plan(float(row.baseline) + delta, false):
				if item.kind == "layer" and item.row.id == row.id: back += 1
			for item: Dictionary in art.render_plan(float(row.baseline) + delta, true):
				if item.kind == "layer" and item.row.id == row.id: front += 1
			check(back + front == 1 and front == int(delta < 0), "actual object foot ordering " + str(row.id))
	check(raised > 0, "raised objects are not empty")
	for point: Vector2 in [Vector2(875,145),Vector2(830,351),Vector2(760,420),Vector2(500,400)]:
		check(art.navigation_decision(Metrics.foot_rect(anchor(point),"campus_bootstrap"), Callable(), true) != 0, "whole foot avoids new water " + str(point))
	# The narrower campus profile clears the old x=790 probe. At x=794 the
	# center remains dry, while the actual 16px-wide foot crosses the shore.
	check(art.navigation_decision(Rect2(Vector2(794,420),Vector2(.01,.01)), Callable(), true) != 0, "shore test center is dry")
	check(art.navigation_decision(Metrics.foot_rect(anchor(Vector2(794,420)),"campus_bootstrap"), Callable(), true) == 0, "shore center alone is insufficient: whole foot crosses water")
	check(art.navigation_decision(Metrics.foot_rect(anchor(Vector2(830,420)),"campus_bootstrap"), Callable(), true) == 0, "actual river water blocks whole foot")
	for route: Array in [[Vector2(840,145),Vector2(915,145)],[Vector2(785,351),Vector2(885,351)],[Vector2(500,600),Vector2(500,400),Vector2(500,310),Vector2(500,155)]]:
		for segment in range(route.size()-1):
			var start: Vector2 = route[segment]
			var goal: Vector2 = route[segment+1]
			var steps := int(ceil(start.distance_to(goal) / 2.0))
			var previous := anchor(start)
			var blocked_points: Array = []
			for step in range(steps+1):
				var point: Vector2 = start.lerp(goal, float(step)/steps)
				var next := anchor(point)
				var horizontal: Vector2 = world._axis_destination(previous, Vector2(next.x-previous.x,0))
				var swept: Vector2 = world._axis_destination(horizontal, Vector2(0,next.y-horizontal.y))
				if not world.can_stand(next) or not swept.is_equal_approx(next):
					if blocked_points.size() < 8: blocked_points.append(point)
				previous = next
			check(blocked_points.is_empty(), "real bridge/path route " + str(start) + " -> " + str(goal) + " blocked=" + str(blocked_points))
	for pair: Array in [[Vector2(780,145),Vector2(910,145)],[Vector2(910,145),Vector2(780,145)]]:
		var a: Vector2 = anchor(pair[0])
		var b: Vector2 = anchor(pair[1])
		world.player = a
		world.safe_player = a
		world._sync_player()
		world._update_camera()
		# Planner bounds are initialized by the tap entry; a direct segment
		# assertion must establish the same visible footprint domain first.
		world._floor_bounds = world._floor_anchor_bounds(world._floor_visible_rect())
		check(world._floor_stand(a) and world._floor_stand(b), "both click endpoints are in the actual visible foot domain")
		check(world._floor_segment_clear(a,b), "bridge click full segment " + str(pair))
		var local: Vector2 = (pair[1]-world.camera)*world.zoom+world.size*.5
		check(world.exploration_safe_rect(true).has_point(local), "tap is inside the real safe viewport")
		world._mobile_floor_tap(local)
		check(world._floor_status == "moving", "actual bridge floor tap creates route " + str(pair))
		world.cancel_exploration_gestures()
	shell.queue_free()
	await process_frame
	print("Semantic campus runtime: ", checks, " checks, ", failures, " failures")
	quit(0 if failures == 0 else 1)
