extends SceneTree
## Real source timeline and shared movement feet; deterministic spatial fixtures.
const Chapter=preload("res://scripts/chapters/chapter1_2.gd")
const Metrics=preload("res://scripts/player_metrics.gd")
const Rules=preload("res://scripts/space/spatial_rules.gd")
const Isolation=preload("res://tests/native_test_isolation.gd")
var state:Node
var world:Control
var checks:=0
var failures:=0
var records:Array=[]

func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error("LIBRARY_SHELF_CONTACT "+label)

func acknowledge(controller:RefCounted,s:Dictionary)->void:
	var session=controller.library.story_session(s)
	while session!=null:
		session.attach(s,self)
		for line in session.lines:session.advance(s,self)
		controller.dispatch(s,"lib_story_complete",session)
		session=controller.library.story_session(s)

func eligible()->Dictionary:
	# Earn the same call-number ownership as the formal reveal integration suite.
	var s:Dictionary=state.initial()
	s.native.chapter=2;s.native.page="library_app";s.native.scene="campus_bootstrap"
	s.actOne.phase="complete";s.actOne.cc98Login.authenticated=true;s.networkMode="campus_wifi";s.ui.libraryFinalsPhase="library_route_unlocked"
	var controller:RefCounted=Chapter.new()
	controller.dispatch(s,"lib_enter");acknowledge(controller,s)
	controller.dispatch(s,"lib_register_arrival");controller.dispatch(s,"lib_record"); acknowledge(controller,s);controller.dispatch(s,"lib_backpack");acknowledge(controller,s)
	controller.dispatch(s,"lib_note"); acknowledge(controller,s);controller.dispatch(s,"lib_investigate","occupancyNote");acknowledge(controller,s)
	controller.dispatch(s,"lib_catalog_terminal");controller.dispatch(s,"lib_catalog_search","三分钟离座法")
	controller.dispatch(s,"lib_catalog_select","three-minute-leave-method");acknowledge(controller,s)
	return s

func progress()->Dictionary:
	var copy:Dictionary=state.d.duplicate(true)
	copy.native.erase("player");copy.native.erase("positions")
	return copy

func setup_actor(point:Vector2,reduced:bool=false)->void:
	state.story_reset.emit();state.d=eligible();state.developer_mode=true
	state.d.native.settings.reduced_motion=reduced
	world=load("res://scripts/world.gd").new();world.size=Vector2(960,540);root.add_child(world);world.set_process(false)
	await process_frame
	world.player=point;world.move_target=Vector2.INF;world.touch_axis=Vector2.ZERO;world._sync_player();world._update_camera()
	check(world.library_layers.objects.ready and world.library_layers.shelf_offset==0,"fixture uses the ready unshifted transparent shelf")
	state.act("lib_shelf");world.library_layers.sync(state.d)
	check(state.d.items.archivedLeaveRule and not state.d.items.callNumber755 and world.library_layers.shelf_animating,"original controller alone earns and starts the reveal")

func shelf_base()->Rect2:
	for row:Dictionary in world.collisions:
		if row.get("nativeLibraryObject",false) and row.id=="north_display_shelf":return world._rect(world.library_layers.replace_collision(row))
	return Rect2()

func finish_case(label:String,start:Vector2,before:Dictionary)->void:
	var layer:RefCounted=world.library_layers
	check(not layer.shelf_animating and layer.shelf_offset==16 and is_equal_approx(layer.shelf_ms,layer.shelf_total_ms()),label+" retains the exact final source timeline and pose")
	check(world.can_stand(world.player),label+" final actor is collision-safe")
	var previous:Vector2=world.player
	var away:=Vector2.LEFT if start.x<548 else Vector2.RIGHT
	world.touch_axis=away;world._process(.016);world.touch_axis=Vector2.ZERO
	check(world.can_stand(world.player) and world.player.distance_to(previous+away*2.64)<.001,label+" ordinary small movement exits after the full reveal")
	var boxes:Array=world._floor_obstacles()
	var route:Array=world._floor_planner.plan(world.player,Vector2(625,355),boxes,Rect2(0,0,1500,900),world.can_stand,func(a:Vector2,b:Vector2):return world._floor_segment_clear(a,b,boxes,true))
	check(not route.is_empty(),label+" resulting foot position remains connected to the normal shelf aisle")
	check(progress()==before,label+" physical clearance cannot alter story, items, settings or checkpoint facts")
	records.append({"case":label,"start":str(start),"final":str(previous),"escaped":str(world.player),"shelfMs":layer.shelf_ms})
	if label=="east side":
		world.touch_axis=Vector2.UP
		for frame:int in 65:world._process(.016)
		check(absf(world.player.y-(start.y-171.6))<.01,"walk the full narrow aisle after the shelf moves")
		world.touch_axis=Vector2.LEFT
		for frame:int in 19:world._process(.016)
		check(absf(world.player.x-(previous.x+2.64-19*2.64))<.01,"turn behind the stack on clear ground")
		world.touch_axis=Vector2.DOWN
		for frame:int in 60:world._process(.016)
		world.touch_axis=Vector2.ZERO
		var rear:float=shelf_base().position.y
		check(world.can_stand(world.player) and absf(Metrics.foot_rect(world.player).end.y-rear)<2.65,"ordinary walking stops at the measured rear support")
	world.queue_free();await process_frame

func timeline_case(label:String,start:Vector2,reduced:bool=false)->void:
	await setup_actor(start,reduced)
	check(world.can_stand(start),label+" close approach is initially legal")
	var before:Dictionary=progress()
	var layer:RefCounted=world.library_layers
	var seen:Array[int]=[0]
	var legal:=true;var held_blocked:=true;var minimal:=true
	var frames:=0
	while layer.shelf_animating and frames<400:
		var at:Vector2=world.player
		var old_offset:float=world._library_shelf_applied_offset
		var ms:=minf(10,layer.shelf_total_ms()-layer.shelf_ms)
		world.touch_axis=Vector2.RIGHT if layer.shelf_ms+ms<layer.shelf_total_ms() else Vector2.ZERO
		world._process(ms/1000.0);frames+=1
		if not seen.has(layer.shelf_offset):seen.append(layer.shelf_offset)
		legal=legal and world.can_stand(world.player)
		var moved:Vector2=world.player-at
		held_blocked=held_blocked and absf(moved.y)<.0001 and absf(moved.x)<=absf(layer.shelf_offset-old_offset)+.002
		var base:=shelf_base()
		var old_feet:=Metrics.foot_rect(at)
		if old_feet.intersects(base):
			var expected_x:float=base.end.x+Metrics.FOOT_SIZE.x/2+Rules.CONTACT_EPSILON if start.x>548 else base.position.x-Metrics.FOOT_SIZE.x/2-Rules.CONTACT_EPSILON
			minimal=minimal and absf(world.player.x-expected_x)<.001
		else:minimal=minimal and moved==Vector2.ZERO
	check(frames<400 and legal,label+" every authored shake and slide step leaves legal feet")
	check(held_blocked,label+" repeated held input never adds walking to the cabinet's minimal push")
	check(minimal,label+" contact moves only to the nearest same-side physical clearance")
	var expected:Array=[0,16] if reduced else [0,-2,1,-1,2,4,6,8,10,12,14,16]
	check(seen==expected,label+" actually executes every source offset in order")
	await finish_case(label,start,before)

func canceled_case()->void:
	var start:=Vector2(596,277)
	await setup_actor(start)
	check(world.can_stand(start),"canceled close approach is initially legal")
	var before:Dictionary=progress()
	world._process(.05)
	world.hide()
	world.library_layers.cancel_shelf_reveal(state.d,world.library_layers.reveal_serial)
	world._process(.01)
	check(world.player==start and world.library_layers.shelf_offset==16,"external cancellation settles while the hidden world owns no movement")
	world.show();world._process(.01)
	check(world.can_stand(world.player) and world.player.x>start.x and world.player.x-start.x<16,"return reconciles a canceled settled pose from the previously legal applied offset")
	await finish_case("canceled return",start,before)

func refused_cases()->void:
	await setup_actor(Vector2(560,277))
	var prior:Vector2=world.player
	check(not world.can_stand(prior),"adversarial fixture is already inside the original cabinet")
	world.library_layers.cancel_shelf_reveal(state.d,world.library_layers.reveal_serial);world._process(.01)
	check(world.player==prior,"a previously illegal actor never receives a general collision rescue")
	world.queue_free();await process_frame
	await setup_actor(Vector2(596,277))
	prior=world.player
	world.collisions.append({"id":"test_static_barrier","left":616,"top":300,"right":617,"bottom":320})
	check(world.can_stand(prior),"adversarial static barrier starts outside the legal actor feet")
	world.library_layers.cancel_shelf_reveal(state.d,world.library_layers.reveal_serial);world._process(.01)
	check(world.player==prior,"a physical push cannot pass through another wall or cross the cabinet to its far side")
	world.queue_free();await process_frame

func run()->void:
	check(Isolation.is_isolated_save(),"isolated native save")
	if failures:quit(1);return
	state=root.get_node("State");root.size=Vector2i(960,540)
	await timeline_case("east side",Vector2(596,277))
	await timeline_case("west side",Vector2(526,277))
	await timeline_case("front aisle",Vector2(564,320))
	await timeline_case("east reduced",Vector2(596,277),true)
	await canceled_case()
	await refused_cases()
	print("LIBRARY_SHELF_CONTACT ",checks," checks, ",failures," failures; cases=",JSON.stringify(records))
	quit(0 if failures==0 else 1)
