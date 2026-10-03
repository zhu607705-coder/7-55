extends "res://tests/test_portrait_exploration.gd"
## Reconstructed portable fixture after executor loss; no manual-play evidence.
const Metrics=preload("res://scripts/player_metrics.gd")
const DOGLEG=Vector2(897.882568,550.701111)
const GOAL=Vector2(1040,630)
var route_cases: Array=[]

func route_fixture(dimensions: Vector2i,anchor: Vector2=DOGLEG,bag: bool=false) -> void:
	state.story_reset.emit(); state.d=state.initial()
	state.d.native.chapter=2;state.d.native.page="library_app";state.d.native.scene="library_interior"
	state.d.actOne.phase="complete";state.d.actOne.inventoryRecovered=true
	state.d.actOne.controlsInstalled=true;state.d.actOne.manualControlTested=true
	state.d.ui.libraryFinalsPhase="evidence_gathering";state.d.items.rightArrow=true
	state.d.native.positions={"library_interior:":{"x":anchor.x,"y":anchor.y}}
	root.size=dimensions;shell.size=Vector2(dimensions)
	shell.compact_inventory_open=bag;shell.mobile_world=true;shell.world.world_key=""
	shell._refresh();await frames(6);shell.world.set_process(false)
	shell.world.player=anchor;shell.world._sync_player();shell.world._update_camera()
	shell.world.transition_alpha=0;shell.world.queue_redraw();await frames(2)
	check(shell.world.mobile_exploration,"actual Main compact surface")
	check(shell.world.can_stand(anchor),"source fixture starts on legal exact feet")

func source_screen(point: Vector2) -> Vector2:
	return world_screen((point-shell.world.camera)*shell.world.zoom+shell.world.size/2)
func tap_ground(point: Vector2) -> void:
	var at:=source_screen(point)
	touch(at,true);await frames(1);touch(at,false);await frames(2)
func story() -> Dictionary:
	var copy: Dictionary=state.d.duplicate(true)
	copy.native.erase("positions");copy.native.erase("player")
	return copy
func walk_route(goal: Vector2) -> void:
	var w=shell.world
	var source_collisions: Array=w.collisions.duplicate(true)
	var before:=story();var action_count:=actions.size();var start: Vector2=w.player
	check(not w._floor_route.is_empty(),"real root tap starts floor route")
	var steps:=0;var legal:=true;var bounded:=true
	while not w._floor_route.is_empty() and steps<800:
		var previous: Vector2=w.player
		w._process(.016);steps+=1
		legal=legal and w.can_stand(w.player)
		bounded=bounded and previous.distance_to(w.player)<=165*.016+.001
	check(steps<800 and w._floor_status=="arrived","route reaches explicit goal without completion shortcut")
	check(Metrics.foot_rect(w.player).get_center().distance_to(goal)<.001,"exact foot-center destination equals tap and marker")
	check(legal and bounded,"every frame keeps exact source feet and native speed")
	check(w.collisions==source_collisions,"source collisions remain unchanged")
	check(story()==before and actions.size()==action_count,"walking emits no target action or story writes")
	route_cases.append({"view":str(root.size),"bag":shell.compact_inventory_open,"start":str(start),"goal":str(goal),"foot_error":Metrics.foot_rect(w.player).get_center().distance_to(goal),"steps":steps,"edge_checks":w._floor_planner.edge_checks,"corners":w._floor_planner.corner_count})
func setup_main() -> void:
	state=root.get_node("State");state.developer_mode=true;state.d=state.initial()
	shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames()
	shell.set_process(false)
	state.action_completed.connect(func(id,_before,_after,_result): actions.append(id))
	state.feedback.connect(func(line): feedback.append(line))
func finish(label: String) -> void:
	await shell.shutdown();shell.queue_free();await frames()
	var path:=OS.get_environment("FLOOR_ROUTE_REPORT")
	if not path.is_empty():
		var file:=FileAccess.open(path,FileAccess.WRITE);file.store_string(JSON.stringify({"reconstructed":true,"checks":checks,"failures":failures,"graphical_acceptance":false,"routes":route_cases},"\t"));file.close()
	print(label,": ",checks," checks; ",failures," failures; routes=",JSON.stringify(route_cases))
	quit(1 if failures else 0)
func run() -> void:
	await setup_main();await route_fixture(Vector2i(390,844))
	var w=shell.world
	var before:=story();var action_count:=actions.size()
	var started:=Time.get_ticks_usec();await tap_ground(GOAL)
	check(w._floor_route.size()>1,"dogleg routes around visible authored furniture")
	check(w._floor_planner.edge_checks<=4096 and w._floor_planner.corner_count<=192,"planner has bounded graph cost")
	print("DOGLEG plan plus routed frames usec=",Time.get_ticks_usec()-started," path=",w._floor_route)
	await walk_route(GOAL)
	check(story()==before and actions.size()==action_count,"dogleg does not auto-interact")
	await route_fixture(Vector2i(390,844))
	await tap_ground(Vector2(920,590))
	check(w._floor_route.is_empty() and w._floor_status=="blocked","unreachable shelf floor shows stop feedback")
	check(w.player==DOGLEG,"unreachable tap never teleports")
	await tap_ground(GOAL);var position: Vector2=w.player
	var key:=InputEventKey.new();key.keycode=KEY_A;key.physical_keycode=KEY_A;key.pressed=true;event(key);w._process(.016)
	key=key.duplicate();key.pressed=false;event(key)
	check(w._floor_route.is_empty() and w._floor_goal==Vector2.INF,"manual keyboard cancels route and marker")
	await route_fixture(Vector2i(390,844));await tap_ground(GOAL)
	var newer:=Vector2(1025,628);await tap_ground(newer)
	check(w._floor_goal==newer,"new explicit tap replaces older goal")
	await walk_route(newer)
	await route_fixture(Vector2i(390,844));await tap_ground(GOAL)
	position=w.player;w.camera+=Vector2(1,0);w._process(.016)
	check(w._floor_route.is_empty() and w.player==position,"unexpected camera change cancels before movement")
	await route_fixture(Vector2i(390,844));await tap_ground(GOAL)
	w.zoom+=.1;w._process(.016);check(w._floor_route.is_empty(),"zoom change cancels")
	await route_fixture(Vector2i(390,844));await tap_ground(GOAL)
	w.capture_mode=true;w._process(.016);check(w._floor_route.is_empty(),"capture owns movement and clears route");w.capture_mode=false
	await route_fixture(Vector2i(390,844));await tap_ground(GOAL)
	w._notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT);check(w._floor_route.is_empty(),"focus loss cancels")
	await route_fixture(Vector2i(390,844));await tap_ground(GOAL)
	var at:=source_screen(Vector2(1060,630));touch(at,true);touch(at,false,true);await frames()
	check(w._floor_route.is_empty(),"canceled new gesture cannot resume route")
	await route_fixture(Vector2i(390,844));await tap_ground(GOAL)
	await click(shell.inventory_handle);check(w._floor_route.is_empty(),"bag resize cancels route")
	before=story();position=w.player;action_count=actions.size()
	var hud_at:=world_screen(Vector2(18,18));touch(hud_at,true);touch(hud_at,false);await frames()
	check(w._floor_route.is_empty() and w.player==position and story()==before and actions.size()==action_count,"HUD title hit cannot walk or choose hidden target")
	# Actual bag drag owns input while a floor route is active.
	await route_fixture(Vector2i(430,860),Vector2(1040,598.3125),true)
	await tap_ground(Vector2(1130,630));position=w.player
	var inventory_before: Dictionary=state.d.items.duplicate(true)
	var item: Control=await reveal("rightArrow")
	await begin_drag(item,false);w._process(.016)
	check(w._floor_route.is_empty() and w.player==position,"native inventory drag cancels active floor movement")
	var drop_at:=source_screen(Vector2(1130,630));motion(drop_at,Vector2.ZERO,MOUSE_BUTTON_MASK_LEFT);mouse(drop_at,false);await frames()
	check(state.d.items==inventory_before and w._floor_route.is_empty() and w.player==position,"floor item drop preserves inventory and never starts route")
	await route_fixture(Vector2i(390,844));await tap_ground(GOAL)
	position=w.player
	var foot:=Metrics.foot_rect(w._floor_route[0])
	w.collisions.append({"x":foot.position.x,"y":foot.position.y,"width":foot.size.x,"height":foot.size.y})
	for step in range(20): w._process(.016)
	check(w._floor_route.is_empty() and w._floor_status=="blocked","new collision stops without automatic replan")
	check(w.can_stand(w.player),"dynamic stop keeps exact current foot legality")
	await route_fixture(Vector2i(390,844));await tap_ground(GOAL)
	position=w.player
	var drag_at:=source_screen(Vector2(1040,630));touch(drag_at,true);finger(drag_at+Vector2(20,0),Vector2(20,0));touch(drag_at+Vector2(20,0),false);await frames()
	check(w._floor_route.is_empty() and w.player==position,"camera pan cannot walk or resume older goal")
	await route_fixture(Vector2i(390,844));await tap_ground(GOAL)
	position=w.player;shell._show_settings();await frames();w._process(.016)
	check(w._floor_route.is_empty() and w.player==position,"modal ownership cancels before movement")
	shell._close_modal();await frames()
	await route_fixture(Vector2i(390,844));await tap_ground(GOAL)
	state.d.native.scene="campus_bootstrap";shell._refresh();await frames()
	check(w._floor_route.is_empty() and w._floor_goal==Vector2.INF,"scene change clears route and marker")
	# Pure swept checks prove sub-pixel barriers and exact tangency semantics.
	var planner=load("res://scripts/mobile_floor_route.gd")
	check(planner.segment_hits(Vector2(0,0),Vector2(10,0),Rect2(4,-1,.01,2)),"swept segment cannot tunnel thin obstacle")
	check(not planner.segment_hits(Vector2(0,1),Vector2(10,1),Rect2(4,-1,1,2)),"exact tangency retains unchanged rectangle semantics")
	check(planner.segment_hits(Vector2(5,0),Vector2(5,3),Rect2(4,-1,2,2)),"starting inside obstacle is blocked")
	# Synthetic mask-only corridor isolates the exact five-foot-sample sweep.
	# These are temporary fixture values, never authored source edits.
	w.collisions=[];w.mask_meta={"cellSize":10,"gridWidth":50,"gridHeight":50}
	w.mask.resize(313);w.mask.fill(255);w.world_size=Vector2(500,500);w._floor_bounds=Rect2(40,40,400,400)
	for row in range(50):
		var bit:=row*50+20;w.mask[bit/8]&=~(1<<(bit%8))
	check(w.can_stand(Vector2(100,200)) and w.can_stand(Vector2(300,200)),"mask sweep endpoints are both legal")
	check(not w._floor_segment_clear(Vector2(100,200),Vector2(300,200)),"mask-cell crossing catches blocked interval between legal endpoints")
	check(w._floor_segment_clear(Vector2(100,200),Vector2(150,200)),"mask sweep permits wholly legal segment")
	await route_fixture(Vector2i(390,844));await tap_ground(GOAL)
	var tick:=Time.get_ticks_usec()
	var obstacles: Array=w._floor_obstacles()
	var proof: Array=w._floor_planner.plan(w.player,GOAL-Metrics.FOOT_CENTER_OFFSET,obstacles,w._floor_bounds,w._floor_stand,func(a: Vector2,b: Vector2): return w._floor_segment_clear(a,b,obstacles,true))
	var micros:=Time.get_ticks_usec()-tick
	check(proof==w._floor_route,"planner is deterministic for same source world")
	check(micros<200000,"bounded visible planner stays below200ms on test host")
	print("DOGLEG algorithm usec=",micros," edges=",w._floor_planner.edge_checks," corners=",w._floor_planner.corner_count)
	await finish("MOBILE_FLOOR_ROUTE")
