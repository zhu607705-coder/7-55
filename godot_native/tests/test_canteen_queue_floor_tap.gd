extends "res://tests/test_portrait_exploration.gd"
## Portable Main/root-input regression. Optional ordinary-save replay is loaded
## normally from an isolated profile; source fixture values are not CUA evidence.
## The native service-wall foot is y=236, so the exact center limit is246.3125.
## Test obstacles are injected into the active native geometry owner.
const Metrics=preload("res://scripts/player_metrics.gd")
const Tap=preload("res://scripts/canteen_floor_tap.gd")
const START=Vector2(1440,574.368041992188)
const BOARD=Vector2(1200.888888888889,234.368055555556)
const QUEUE_START=Vector2(867.555555555556,258.8125)
var baseline: Dictionary={}
var records: Array=[]
var ordinary_save:=false
class CountPlanner extends "res://scripts/mobile_floor_route.gd":
	var calls:=0
	func plan(start: Vector2,goal: Vector2,boxes: Array,allowed: Rect2,stand: Callable,clear: Callable) -> Array[Vector2]:
		calls+=1
		return super.plan(start,goal,boxes,allowed,stand,clear)
func story() -> Dictionary:
	var value: Dictionary=state.d.duplicate(true)
	value.native.erase("player");value.native.erase("positions")
	return value
func root_tap(at: Vector2,using_touch: bool=false) -> void:
	if using_touch: touch(at,true);touch(at,false)
	else: motion(at);mouse(at,true);mouse(at,false)
func source_at(at: Vector2) -> Vector2:
	var local: Vector2=shell.world_view.source_position(shell.world_view.get_global_transform_with_canvas().affine_inverse()*at)
	return (local-shell.world.size/2)/shell.world.zoom+shell.world.camera
func source_screen(point: Vector2) -> Vector2:
	return world_screen((point-shell.world.camera)*shell.world.zoom+shell.world.size/2)
func wheel() -> void:
	var e:=InputEventMouseButton.new();e.position=Vector2(195,408);e.global_position=e.position;e.button_index=MOUSE_BUTTON_WHEEL_DOWN;e.pressed=true;event(e)
	e=e.duplicate();e.pressed=false;event(e);await frames(4)
func reset_route() -> void:
	state.story_reset.emit();state.d=baseline.duplicate(true)
	# Unsaved NPC dialogue assignments are fixture-seeded, never trace evidence.
	seed(755)
	shell.world.world_key="";shell.world.scene_id="";shell._refresh();shell._show_world_mobile();await frames(6)
	shell.world.set_process(true)
	check(shell.world.player.distance_to(START)<.002,"normal Main load retains ordinary starting position")
	for i in 4: await wheel()
	check(is_equal_approx(shell.world.zoom,.45),"four recorded root wheel events derive minimum zoom .45")
	check(shell.world_view.get_global_rect()==Rect2(10,66,370,712),"actual Main viewport matches recorded 390x844 transform")
	shell.world._floor_planner=CountPlanner.new()
func arrive(at: Vector2,expected: Vector2,using_touch: bool=false) -> void:
	var w=shell.world
	var raw:=source_at(at);var before:=story();var action_count:=actions.size()
	var raw_valid: bool=w.can_stand(raw-Metrics.FOOT_CENTER_OFFSET)
	await snapshot(str(records.size())+"-before")
	var geometry: Array=w.collisions.duplicate(true);var start: Vector2=w.player
	var old_calls:int=w._floor_planner.calls;var tick:=Time.get_ticks_usec()
	root_tap(at,using_touch)
	var planning_us:=Time.get_ticks_usec()-tick
	var waypoints: String=str(w._floor_route)
	check(w._floor_status=="moving" and not w._floor_route.is_empty(),"root input starts an actual floor route")
	check(w._floor_planner.calls==old_calls+1,"exactly one unchanged planner call per request")
	check(w._floor_goal.distance_to(expected)<.002,"accepted marker is the resolved full-foot center")
	if raw_valid:check(w._floor_goal==raw,"valid raw floor intent remains exact")
	await snapshot(str(records.size())+"-accepted")
	check(w._floor_goal.distance_to(raw)*w.zoom<=Tap.PIXEL_RADIUS+.001,"correction is bounded in physical pixels")
	check(planning_us<200000 and w._canteen_floor_tap.candidate_count<=Tap.MAX_CANDIDATES,"correction and planning remain bounded")
	var legal:=true;var transform_ok:=true;var continuous:=true;var count:=0
	var deadline:=Time.get_ticks_msec()+10000
	while not w._floor_route.is_empty() and Time.get_ticks_msec()<deadline:
		var previous: Vector2=w.player
		await process_frame
		legal=legal and w.can_stand(w.player);transform_ok=transform_ok and w._floor_transform_current()
		continuous=continuous and previous.distance_to(w.player)<=165*.05+.001;count+=1
	check(w._floor_status=="arrived" and Metrics.foot_rect(w.player).get_center().distance_to(expected)<.002,"live Main frames arrive at selected full-foot center")
	check(legal and continuous and transform_ok,"every frame preserves exact feet, native speed and camera ownership")
	check(w.collisions==geometry and story()==before and actions.size()==action_count,"route changes no geometry, story, inventory, wallet or interaction")
	await snapshot(str(records.size())+"-arrived")
	records.append({"root":str(at),"input":"touch" if using_touch else "mouse","start":str(start),"raw":str(raw),"resolved":str(expected),"snapPixels":raw.distance_to(expected)*w.zoom,"waypoints":waypoints,"final":str(w.player),"frames":count,"planningUs":planning_us,"edges":w._floor_planner.edge_checks,"candidates":w._canteen_floor_tap.candidate_count})
func replay_approach() -> void:
	await reset_route()
	await arrive(Vector2(168,330),BOARD+Metrics.FOOT_CENTER_OFFSET)
	root_tap(Vector2(329,695));await frames(2)
	check(shell.world.subtitle=="请先从物品栏选择对应物品。","recorded board interaction retains source item requirement")
	# Fix only the unsaved animation phase for a repeatable empty-floor approach.
	shell.world.set_process(false);shell.world.chapter3_layers.clock_ms=0;shell.world.queue_redraw();await frames(2)
	check(shell.world._pick_target(source_at(Vector2(45,341))).is_empty(),"fixture approach floor has no transient NPC pick")
	shell.world.set_process(true)
	await arrive(Vector2(45,341),QUEUE_START+Metrics.FOOT_CENTER_OFFSET)
	check(shell.world.player.distance_to(QUEUE_START)<.002,"first queue-area tap reproduces reported actor without teleport")
func rejection(at: Vector2,label: String) -> void:
	var w=shell.world;var position: Vector2=w.player;var before:=story();var count:=actions.size()
	var raw:=source_at(at);root_tap(at)
	check(w._floor_status=="blocked" and w._floor_route.is_empty() and w._floor_goal==raw,label+" retains blocked marker at raw request")
	await frames(2)
	check(w.player==position and story()==before and actions.size()==count,label+" has no movement or progression")
func snapshot(name: String) -> void:
	var directory:=OS.get_environment("QUEUE_CAPTURE_DIR")
	if directory.is_empty():return
	# Optional graphical fixture output. Dummy headless rendering has no pixels.
	if DisplayServer.get_name()=="headless":return
	var running: bool=shell.world.is_processing()
	shell.world.set_process(false);shell.world.queue_redraw();await frames(2)
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(directory)
	check(root.get_texture().get_image().save_png(directory.path_join(name+".png"))==OK,"render fixture saved: "+name)
	shell.world.set_process(running)
func run() -> void:
	state=root.get_node("State");ordinary_save=OS.get_environment("EARNED_QUEUE_REPLAY")=="1"
	if not ordinary_save:
		state.d=state.initial()
		state.d.native.chapter=3;state.d.native.page="phone_home";state.d.native.scene="canteen_interior"
		state.d.actOne.phase="complete";state.d.actOne.inventoryRecovered=true
		state.d.actOne.controlsInstalled=true;state.d.actOne.manualControlTested=true
		state.d.canteenHunt.active=true;state.d.canteenHunt.phase="tray_search";state.d.canteenHunt.entryPaperEscaped=true
		state.d.canteenHunt.trayTaskStarted=true;state.d.canteenHunt.drinkShelfRead=true
		state.d.canteenHunt.returnedTrayIds=["tray_plain_03","tray_blue_02","tray_blue_01","tray_blue_03"]
		state.d.items.campusCard=true;state.d.items.cafeteriaWages=true;state.d.items.greaseTissue=true;state.d.wallet.cashCents=200
		state.d.runtimeMode="rpg";state.d.native.positions={"canteen_interior:":{"x":START.x,"y":START.y}}
	state.developer_mode=true;baseline=state.d.duplicate(true)
	check(state.d.canteenHunt.returnedTrayIds.size()==4 and not state.d.canteenHunt.queueChallengeSeen,"post-trays baseline keeps unseen queue; fixture origin is explicit")
	root.size=Vector2i(390,844);shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames(8)
	state.action_completed.connect(func(id,_a,_b,_c):actions.append(id))
	state.feedback.connect(func(line):feedback.append(line))
	for using_touch in [false,true]:
		await replay_approach()
		var raw:=source_at(Vector2(79,321));var goal:=raw-Metrics.FOOT_CENTER_OFFSET
		check(not shell.world.can_stand(goal),"recorded second tap's original full-foot position overlaps source wall")
		var hits: Array=[]
		for box: Dictionary in shell.world.collisions:
			if Metrics.foot_rect(goal).intersects(shell.world._rect(box)):hits.append(box.id)
		check(hits==["north_service_wall"],"exact endpoint rejection is the static service-wall foot overlap")
		check(shell.world._pick_target(raw).is_empty() and shell.world._floor_empty_destination(raw),"recorded near miss is empty floor with no object/actor/HUD veto")
		await arrive(Vector2(79,321),Vector2(raw.x,246.3125),using_touch)
	# Reuse current legal start for negative requests through the same root path.
	var w=shell.world
	await rejection(source_screen(Vector2(620,239)),"solid wall center")
	await rejection(source_screen(Vector2(w.camera.x,-1)),"outside visible source world")
	# Actual opaque actor pixels and reserved HUD input retain their ownership.
	w.set_process(false);await frames(2)
	var actor:=Vector2.INF
	var texture: Texture2D=w.player_side_idle if w.facing=="side" else w.player_frames[w.facing][0]
	for y in range(-24,25,2):
		for x in range(-16,17,2):
			var point: Vector2=w.player+Vector2(x,y)
			if w._pick_target(point).is_empty() and w.object_picker.contains({"rect":Metrics.visual_rect(w.player,w.display_scale_at(w.player)),"texture":texture,"flip_h":w.player_flip and w.facing=="side"},point):actor=point;break
		if actor.is_finite():break
	check(actor.is_finite(),"fixture contains an opaque actor pixel away from nearby object picks")
	var calls: int=w._floor_planner.calls
	root_tap(source_screen(actor))
	check(w._floor_planner.calls==calls and w._floor_route.is_empty() and w._floor_goal==Vector2.INF,"actor input cannot become a corrected floor goal")
	root_tap(world_screen(Vector2(18,18)),true)
	check(w._floor_planner.calls==calls and w._floor_route.is_empty(),"HUD touch cannot enter floor planner")
	w.zoom=1.2;w._update_camera();w.queue_redraw();await frames(2)
	await rejection(source_screen(Vector2(680,241.1)),"empty-floor correction beyond six screen pixels")
	w.zoom=.45;w._update_camera();w.queue_redraw();await frames(2)
	# The nearest corrected destination belongs to a painted object: no fallback.
	var raw:=Vector2(620,246)
	w.set_process(false);await frames(2)
	w.object_picker.add([],{"rect":Rect2(619,246.3125,2,1)},true)
	await rejection(source_screen(raw),"painted nearest destination")
	w.queue_redraw();await frames(2)
	# A legal endpoint behind a new full-height barrier stays exact and blocked.
	w.chapter3_layers=null
	var barrier:=StaticBody2D.new();w.native_canteen.source_space.add_child(barrier)
	w.native_canteen.structures.append({"id":"fixture_full_height_barrier","body":barrier,"polygon":PackedVector2Array([Vector2(650,0),Vector2(652,0),Vector2(652,941),Vector2(650,941)])})
	w.native_canteen.navigation_signature=""
	await rejection(source_screen(Vector2(690,299)),"legal unreachable goal")
	# Other scenes and masks keep exact endpoints, even if invalid.
	var anchor:=Vector2(620,246)-Metrics.FOOT_CENTER_OFFSET
	w._floor_bounds=w._floor_anchor_bounds(w._floor_visible_rect())
	w.scene_id="library_interior"
	check(w._canteen_floor_goal(anchor,w._floor_obstacles())==anchor,"input correction does not expand to another scene")
	w.scene_id="canteen_interior";w.mask.resize(1);w.mask[0]=0
	check(w._canteen_floor_goal(anchor,w._floor_obstacles())==anchor,"input correction does not approximate mask boundaries")
	# Pure helper covers the radius and nearest-ownership policy independently.
	var helper:=Tap.new();var box:=Rect2(-10,-10,12,20)
	var stand:=func(point: Vector2)->bool:return not box.has_point(point)
	check(helper.nearest(Vector2.ZERO,1.9,[box],stand,func(_p):return true)==Vector2.ZERO,"over-radius nearest point is rejected")
	check(helper.nearest(Vector2.ZERO,6,[box],stand,func(_p):return true)==Vector2(2,0),"nearest legal rectangle boundary wins")
	check(helper.nearest(Vector2.ZERO,6,[box],stand,func(_p):return false)==Vector2.ZERO,"nearest ownership veto never chooses a farther alternative")
	var path:=OS.get_environment("QUEUE_REPORT")
	if not path.is_empty():
		var f:=FileAccess.open(path,FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":failures,"ordinarySave":ordinary_save,"graphicalAcceptance":false,"routes":records},"\t"));f.close()
	await shell.shutdown();shell.queue_free();await frames()
	print("CANTEEN_QUEUE_FLOOR_TAP: ",checks," checks; ",failures," failures; ordinarySave=",ordinary_save);quit(1 if failures else 0)
