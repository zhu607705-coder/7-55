extends SceneTree
const Departure=preload("res://scripts/presentation/theater_departure.gd")
var state:Node
var world:Control
var checks:=0
var failures:=0
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error("THEATER DEPARTURE: "+label)
func facts()->String:
	return JSON.stringify({"theater":state.d.theaterHunt,"canteen":state.d.canteenHunt,"lake":state.d.qizhenLake,"chapter4":state.d.chapter4,"items":state.d.items,"wallet":state.d.wallet,"flags":state.d.flags})
func fixture()->void:
	state.begin_checkpoint("c3-theater-code")
	# Declared completed-theater acceptance fixture. The presentation must not
	# create this fact, ticket admission, lake entry or any reward itself.
	state.d.theaterHunt.admitted=true;state.d.theaterHunt.phase="complete"
	state.d.native.player={"scene":"theater_interior","x":800.0,"y":820.0}
	state.d.native.positions={"theater_interior:":{"x":800.0,"y":820.0}}
	if is_instance_valid(world):world.scene_id="";world.world_key="";world.refresh_world()
func effect()->Control:
	var view:Control=Departure.new();world.add_child(view);view.set_process(false)
	check(view.setup(world,func()->Dictionary:return state.d),"valid physical exit starts presentation")
	return view
func frames(view:Control,count:int,focused:bool=true)->void:
	for i:int in range(count):
		if not is_instance_valid(view) or view.is_finished():return
		world._process(.05);view.tick(.05,focused)
		check(world.can_stand(world.player),"every motion frame respects the complete shared foot body")
func run()->void:
	check(load("res://tests/native_test_isolation.gd").is_isolated_save(),"isolated user storage")
	if failures:quit(1);return
	state=root.get_node("State");state.developer_mode=true;fixture()
	world=load("res://scripts/world.gd").new();world.size=Vector2(960,540);root.add_child(world)
	await process_frame;world.set_process(false)
	world.chapter3_layers.doors.configure("theater_interior")
	var initial:String=facts();var done:Array=[];var cancelled:Array=[]
	var view:Control=effect()
	view.completed.connect(func():done.append(world.player))
	view.cancelled.connect(func(reason:String):cancelled.append(reason))
	var start:Vector2=world.player
	frames(view,30,false)
	check(world.player==start and view.elapsed_ms==0 and world.chapter3_layers.doors.progress==0,"focus loss pauses actor, owned door clock and active timeout")
	state.d.ui.controlCenterOpen=true;frames(view,30)
	check(world.player==start and view.elapsed_ms==0 and world.chapter3_layers.doors.progress==0,"open control center pauses the same complete sequence")
	state.d.ui.controlCenterOpen=false
	frames(view,80)
	check(view.finished and not view.was_cancelled and done==[Vector2(836,895)] and cancelled.is_empty(),"one completion follows real alignment and physical threshold crossing")
	check(facts()==initial and state.d.native.scene=="theater_interior","presentation completion never writes exit, lake, ticket, inventory or chapter facts")
	check(not world.chapter3_layers.doors.departure_held and not world.chapter3_layers.doors.departure_clock_owned,"completion releases both door ownership fields")
	view.cancel("late_cancel");check(done.size()==1 and cancelled.is_empty(),"late cancel cannot duplicate completion or cancellation")
	await process_frame
	for fault:String in ["state_identity","scene","phase","checkpoint","external_motion","explicit_cancel","tree_exit","blocked_passage"]:
		fixture();view=effect();var notices:Array=[]
		view.completed.connect(func():notices.append("completed"))
		view.cancelled.connect(func(reason:String):notices.append(reason))
		initial=facts()
		match fault:
			"state_identity":state.d=state.d.duplicate(true)
			"scene":state.d.native.scene="library_interior"
			"phase":state.d.theaterHunt.phase="entry_ticket"
			"checkpoint":state.d.rpgCheckpoint="theater_stage"
			"external_motion":world.player+=Vector2(4,0);world._sync_player()
			"explicit_cancel":view.cancel("explicit_cancel");view.cancel("duplicate")
			"tree_exit":world.remove_child(view)
			"blocked_passage":world.collisions.append({"id":"test_visible_stage_blocker","left":825.0,"top":800.0,"right":925.0,"bottom":920.0})
		if fault=="tree_exit":
			check(not world.chapter3_layers.doors.departure_held and not world.chapter3_layers.doors.departure_clock_owned,"tree exit always releases held door and clock")
			view.free()
		else:
			frames(view,100)
			check(view.was_cancelled and not view.finished and notices.size()==1 and notices[0]!="completed","invalid/cancelled "+fault+" never completes or emits twice")
			check(not world.chapter3_layers.doors.departure_held and not world.chapter3_layers.doors.departure_clock_owned,"cancelled "+fault+" restores ordinary sensor ownership")
			if fault=="blocked_passage":
				check(notices==["blocked_passage"] and world.player.x<=815.251 and world.can_stand(world.player),"blocked timeout stops against actual solid without teleporting through it")
		if fault not in ["scene","phase","checkpoint"]:check(facts()==initial,"cancelled "+fault+" does not change original domain facts")
		await process_frame
	fixture();view=Departure.new();world.add_child(view);view.set_process(false)
	world.player=Vector2(1080,590);world._sync_player()
	check(not view.setup(world,func()->Dictionary:return state.d) and not world.chapter3_layers.doors.departure_held,"distant call cannot animate a cross-map exit")
	await process_frame
	world.queue_free();await process_frame
	print("THEATER_DEPARTURE: %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
