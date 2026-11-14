extends SceneTree
## The native wall opening, collider and ordinary target share one registration.
const Fixture=preload("res://tests/canteen_native_fixture.gd")
const CanteenLayout=preload("res://scripts/space/canteen_layout.gd")
var checks:=0
var failures:=0
var departures: Array[Vector2] = []

func _initialize()->void: run.call_deferred()

func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:
		failures+=1
		push_error("CANTEEN DOOR INTEGRATION: "+label)

func tap_exit(world:Control, point:Vector2, touch:bool)->void:
	var local:Vector2=(point-world.camera)*world.zoom+world.size/2
	check(world.exploration_safe_rect(true).has_point(local),"south exit is inside the playable viewport")
	for pressed:bool in [true,false]:
		if touch:
			var finger:=InputEventScreenTouch.new()
			finger.index=3
			finger.position=local
			finger.pressed=pressed
			world._gui_input(finger)
		else:
			var mouse:=InputEventMouseButton.new()
			mouse.button_index=MOUSE_BUTTON_LEFT
			mouse.position=local
			mouse.pressed=pressed
			world._gui_input(mouse)

func keyboard(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func run()->void:
	create_timer(40).timeout.connect(func() -> void: quit(2))
	var state:Node=root.get_node("State")
	state.action_completed.connect(func(action: String, before: Dictionary, after: Dictionary, _result: Dictionary) -> void:
		if action == "c3_target:" + CanteenLayout.EXIT_TARGET_ID and after.native.scene == "campus_bootstrap":
			departures.append(Vector2(before.native.player.x, before.native.player.y))
	)
	Fixture.install(state)
	var story_before:=JSON.stringify(state.d.canteenHunt)
	var items_before:=JSON.stringify(state.d.items)
	var world:Control=load("res://scripts/world.gd").new()
	root.add_child(world)
	world.size=Vector2(960,540)
	await process_frame
	world.set_process(false)
	var scene:Node2D=world.native_canteen
	var motion:RefCounted=scene.layers.doors
	var registration:Dictionary=CanteenLayout.data().side_exit
	var target:Dictionary=registration.target
	var stand:=Vector2(target.stand.x,target.stand.y)
	var threshold:=Vector2(registration.exitPoint.x,registration.exitPoint.y)
	motion.configure("canteen_interior",false)
	scene.configure_view(Vector2.ZERO,1.0,world.player)
	check(not scene.objects.has("southeast_door") and not scene.objects.has("southeast_mat"),"old floor-standing door and mat are retired")
	check(scene.objects.west_door.parts[0].sprite.visible,"west entry remains visible")
	check(world.can_stand(Vector2(1564,835)) and world._pick_target(Vector2(1564,835)).get("id","")!="southeast_exit","former off-center exit is ordinary floor")
	check(not world.can_stand(Vector2(1635,806.5)) and world._pick_target(Vector2(1635,843)).get("id","")!="southeast_exit","east wall is continuous at the former side opening")
	var counter_edge: float = scene.objects.south_counter.geometry().rect.end.x
	var east_wall: Dictionary = scene.structures.filter(func(row: Dictionary) -> bool: return row.id=="east_wall_lower")[0]
	var east_edge: float = east_wall.polygon[0].x
	check(motion.opening.end.y==world.world_size.y and absf(motion.opening.get_center().x-(counter_edge+east_edge)/2.0)<1.0,
		"the south opening is horizontally centered in the open floor between the hot counter and the east wall")
	check(scene.target_geometry("southeast_exit").rect == motion.canteen_pick_rect(), "standing frame and opening share the fixed pick surface")
	var glass := Vector2(motion.canteen_face.get_center().x, motion.canteen_face.position.y + 24)
	var picked:Dictionary=world._pick_target(glass)
	check(glass.y < motion.opening.position.y and picked.get("id","")==target.id and picked.get("stand",{})==target.stand,
		"upper glass above the floor opening resolves the exit target")
	check(world.can_stand(stand) and not world.can_stand(threshold),"approach is clear and the closed leaves block the threshold")
	motion.set_open(true)
	motion.advance(174)
	check(not world.can_stand(threshold),"feet cannot cross before the existing motion gate")
	motion.advance(1)
	check(world.can_stand(threshold),"feet can cross through the opened leaves")
	var jamb_offset:=Vector2(motion.opening.size.x/2+16,0)
	check(not world.can_stand(threshold-jamb_offset) and not world.can_stand(threshold+jamb_offset),"wall remains solid on both sides of the aperture")
	world._floor_bounds=Rect2(Vector2.ZERO,world.world_size)
	check(world._floor_segment_clear(stand,threshold),"open south doorway admits the whole foot box along its center line")
	motion.advance(285)
	check(world.can_stand(threshold),"fully open doorway retains continuous floor support")
	check(JSON.stringify(state.d.canteenHunt)==story_before and JSON.stringify(state.d.items)==items_before,"door motion grants no progress or items")
	motion.configure("canteen_interior",true)
	check(motion.duration_ms==120,"reduced-motion duration stays intact")
	motion.set_open(true)
	motion.advance(120)
	check(world.can_stand(threshold),"reduced motion reaches the same passage")
	scene.sync(state.d,"campus_bootstrap")
	check(not scene.visible,"scene retirement hides the south exit")
	motion.configure("canteen_interior",false)
	scene.sync(state.d,"canteen_interior")
	check(not world.can_stand(threshold),"reentry starts with a closed south exit")
	for input_name: String in ["mouse", "touch", "keyboard"]:
		var touch := input_name == "touch"
		var walking := input_name == "keyboard"
		Fixture.install(state)
		world.mobile_exploration=touch
		world.touch_controls=touch
		world.size=Vector2(390,844) if touch else Vector2(960,540)
		world.world_key=""
		world.refresh_world()
		if touch:
			world.player=stand-Vector2(100,56)
			world._sync_player()
		elif walking:
			world.player=stand
			world._sync_player()
		world._update_camera()
		scene.configure_view(world.size/2-world.camera*world.zoom,world.zoom,world.player)
		check(world.can_stand(world.player),"input starts on walkable floor")
		var exits_before := departures.size()
		if walking:
			world.transition_alpha = 0.0
			world._process(0.0)
			world._sync_selected_overlay()
			check(world.nearby.get("id") == target.id and not world.selected_overlay.plaque.visible,
				"walk-through exit remains a nearby target without a Space prompt")
			state.act("c3_target:" + target.id)
			check(state.d.native.scene == "canteen_interior", "controller requires the player to cross beyond the nearby approach")
			world._process(0.05)
			check(departures.size() == exits_before, "standing at the approach never departs")
			keyboard(KEY_S, true)
		else:
			tap_exit(world, glass, touch)
			var destination:Dictionary=world._floor_pending_interaction.get("target",{})
			check(world._floor_status=="moving" and not world._floor_route.is_empty() and world._floor_route.back() == threshold
				and destination.get("id","")==target.id, "actual exit input routes all the way through the opening (%s)" % input_name)
		for frame:int in range(180):
			if state.d.native.scene!="canteen_interior": break
			world._process(.05)
		if walking: keyboard(KEY_S, false)
		check(state.d.native.scene=="campus_bootstrap" and state.d.rpgScene=="campus_bootstrap",
			"ordinary exit intent returns to campus (%s)" % input_name)
		check(departures.size() == exits_before + 1 and CanteenLayout.exit_contains_player(departures.back()),
			"the controller receives exactly one departure after the whole foot enters the threshold (%s)" % input_name)
		check(JSON.stringify(state.d.canteenHunt)==story_before and JSON.stringify(state.d.items)==items_before,"leaving through the south exit preserves hunt and inventory")
	Fixture.install(state)
	world.world_key = ""
	world.refresh_world()
	motion.set_open(true)
	motion.advance(motion.duration_ms)
	var edge: Vector2 = world._axis_destination(threshold, Vector2(0, 20))
	check(CanteenLayout.exit_contains_player(edge) and world._axis_destination(edge, Vector2(0, 8)) == edge,
		"legacy fixture is wholly through the opening with no remaining outward movement")
	state.d.native.positions["canteen_interior:"] = {"x": edge.x, "y": edge.y}
	state.d.native.player = {"scene": "canteen_interior", "x": edge.x, "y": edge.y}
	world.scene_id = ""
	world.world_key = ""
	world.refresh_world()
	var exits_before_restore := departures.size()
	world._process(.05)
	check(world.player == edge and state.d.native.scene == "canteen_interior", "restoring at the edge waits for outward input")
	keyboard(KEY_S, true)
	world._process(.05)
	keyboard(KEY_S, false)
	check(state.d.native.scene == "campus_bootstrap" and departures.size() == exits_before_restore + 1,
		"holding outward after restoring at the edge leaves through the same controller once")
	Fixture.install(state, "exit_blocking")
	world.world_key = ""
	world.refresh_world()
	world.player = stand
	world._sync_player()
	keyboard(KEY_S, true)
	for frame in range(24): world._process(.05)
	keyboard(KEY_S, false)
	check(state.d.native.scene == "canteen_interior" and not CanteenLayout.exit_contains_player(world.player) and not motion.passable(),
		"the cart interception phase keeps the ordinary exit closed")
	world.queue_free()
	await process_frame
	print("CANTEEN DOOR INTEGRATION %d checks; %d failures" % [checks,failures])
	quit(1 if failures else 0)
