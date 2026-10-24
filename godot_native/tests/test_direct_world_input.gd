extends SceneTree
const Metrics=preload("res://scripts/player_metrics.gd")
var checks:=0
var failures:=0
var state:Node
var world:Control
var actions:Array=[]
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error("DIRECT WORLD INPUT: "+label)
func _initialize()->void:run.call_deferred()
func fixture()->void:
	state.d=state.initial();state.d.native.chapter=2;state.d.native.scene="library_interior";state.d.native.page="phone_home";state.d.native.mode="light"
	state.d.runtimeMode="rpg";state.d.rpgScene="library_interior";state.d.actOne.phase="complete"
	state.d.ui.libraryFinalsPhase="library_entered";state.d.ui.libraryFinalsPuzzle.entranceRecordRead=true
	state.d.native.player={"scene":"library_interior","x":715.0,"y":792.5};state.d.native.positions={"library_interior:":{"x":715.0,"y":792.5}}
	if is_instance_valid(world):world.world_key="";world.refresh_world();world._process(0)
	actions.clear()
func local(point:Vector2)->Vector2:return (point-world.camera)*world.zoom+world.size/2
func touch(id:int,point:Vector2,pressed:bool,canceled:bool=false)->void:
	var e:=InputEventScreenTouch.new();e.index=id;e.position=point;e.pressed=pressed;e.canceled=canceled;world._gui_input(e)
func drag(id:int,point:Vector2,relative:Vector2)->void:
	var e:=InputEventScreenDrag.new();e.index=id;e.position=point;e.relative=relative;world._gui_input(e)
func run()->void:
	check(load("res://tests/native_test_isolation.gd").is_isolated_save(),"isolated storage")
	state=root.get_node("State");state.developer_mode=true;fixture()
	state.action_completed.connect(func(action,_before,_after,_result):actions.append(action))
	world=load("res://scripts/world.gd").new();world.size=Vector2(960,540);root.add_child(world)
	await process_frame;world.set_process(false);world.mobile_exploration=true;world.touch_controls=true
	var metrics:Dictionary=world.mobile_control_metrics()
	check(metrics.scheme=="direct_world" and not metrics.has("stick") and not metrics.has("interact"),"direct scene exposes no permanent or invisible virtual controls")
	check(metrics.gestureArea==world.exploration_safe_rect(true),"visible safe scene and actual gesture area share geometry")
	var before:Vector2=world.player;var items:Dictionary=state.d.items.duplicate(true);var source_collisions:Array=world.collisions.duplicate(true)
	var target:Vector2=local(Vector2(715,673.1875))
	touch(1,target,true)
	check(world._floor_route.is_empty() and actions.is_empty(),"finger down does not move or interact")
	touch(1,target,false)
	check(not world._floor_route.is_empty(),"ordinary real scene tap plans through an earned open entrance")
	var steps:=0
	while not world._floor_route.is_empty() and steps<400:
		var previous:Vector2=world.player;world._process(.016);steps+=1
		check(world.can_stand(world.player) and previous.distance_to(world.player)<=165*.016+.001,"path step keeps original body and speed")
	check(steps<400 and world.player.y<700 and world._floor_status=="arrived","tap reaches exact source floor through the open door")
	check(state.d.items==items and world.collisions==source_collisions and actions.is_empty(),"direct walking retains all source colliders, items and controller facts")
	fixture();state.d.ui.libraryFinalsPuzzle.entranceRecordRead=false;world.player=Vector2(715,842);world._sync_player();world._update_camera();world.library_door.sync(state.d,true);world.queue_redraw();await process_frame
	var approach:=local(Vector2(750,727));touch(30,approach,true);touch(30,approach,false)
	check(not world._floor_route.is_empty() and not world._floor_pending_interaction.is_empty() and actions.is_empty(),"far record tap starts an owned physical approach without early controller action")
	for i:int in range(200):
		world._process(.016)
		if world._floor_route.is_empty():break
	check(world.can_stand(world.player) and state.d.native.page=="library_record" and actions.count("lib_open_record")==1 and not state.d.ui.libraryFinalsPuzzle.entranceRecordRead,"authored entrance spawn reaches original record controller exactly once without granting access")
	fixture();state.d.ui.libraryFinalsPuzzle.entranceRecordRead=false;world.player=Vector2(715,842);world._sync_player();world._update_camera();world.library_door.sync(state.d,true);world.mobile_exploration=false;world.touch_controls=false;world.queue_redraw();await process_frame
	var fine_click:=InputEventMouseButton.new();fine_click.button_index=MOUSE_BUTTON_LEFT;fine_click.position=local(Vector2(750,727));fine_click.pressed=true;world._gui_input(fine_click)
	check(not world._floor_route.is_empty() and not world._floor_pending_interaction.is_empty() and actions.is_empty(),"fine mouse uses the same physical far-entity approach without early action")
	for i:int in range(200):
		var previous:Vector2=world.player;world._process(.016)
		check(world.can_stand(world.player) and previous.distance_to(world.player)<=165*.016+.001,"fine approach retains actual collision body and original movement speed")
		if world._floor_route.is_empty():break
	check(state.d.native.page=="library_record" and actions.count("lib_open_record")==1 and not state.d.ui.libraryFinalsPuzzle.entranceRecordRead,"fine mouse arrival submits the original record controller exactly once")
	world.mobile_exploration=true;world.touch_controls=true
	for reason:String in ["identity","mode","phase","target","focus","resize","new_touch","drag"]:
		fixture();state.d.ui.libraryFinalsPuzzle.entranceRecordRead=false;world.player=Vector2(715,842);world._sync_player();world._update_camera();world.library_door.sync(state.d,true);world.queue_redraw();await process_frame
		approach=local(Vector2(750,727));touch(31,approach,true);touch(31,approach,false)
		check(not world._floor_pending_interaction.is_empty(),"cancellation sample has a real pending entity approach "+reason)
		before=world.player
		match reason:
			"identity":state.d=state.d.duplicate(true)
			"mode":state.d.native.mode="dark"
			"phase":state.d.ui.libraryFinalsPhase="evidence_gathering"
			"target":
				for row:Dictionary in world.targets:
					if row.id=="entrance_record":row.action="changed_intent"
			"focus":world._notification(Control.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
			"resize":world.size+=Vector2(1,0)
			"new_touch":touch(32,Vector2(300,200),true);touch(32,Vector2(300,200),false,true)
			"drag":touch(33,Vector2(300,200),true);drag(33,Vector2(320,200),Vector2(20,0));touch(33,Vector2(320,200),false)
		for i:int in range(100):world._process(.016)
		check(world._floor_pending_interaction.is_empty() and world._floor_route.is_empty() and actions.is_empty() and world.player==before,"cancelled pending approach never resumes or submits a stale controller "+reason)
	fixture();var a:=Vector2(430,220);before=world.player;var old_camera:Vector2=world.camera
	touch(2,a,true);drag(2,a+Vector2(30,0),Vector2(30,0));drag(2,a,Vector2(-30,0));touch(2,a,false)
	check(world._floor_route.is_empty() and world.player==before and actions.is_empty(),"drag that returns to origin never leaks a click or floor walk")
	fixture();before=world.player;var old_zoom:float=world.zoom
	touch(3,Vector2(400,220),true);touch(4,Vector2(560,220),true)
	drag(3,Vector2(380,210),Vector2(-20,-10));drag(4,Vector2(600,240),Vector2(40,20))
	check(world.zoom>old_zoom and world.player==before and actions.is_empty(),"real two-finger gesture changes only camera zoom and pan")
	touch(3,Vector2(380,210),false);touch(5,Vector2(500,200),true);touch(5,Vector2(500,200),false);touch(4,Vector2(600,240),false)
	check(not world.direct_gestures.has_active() and world._floor_route.is_empty() and actions.is_empty(),"camera sequence remains click-free until every finger lifts")
	for reason:String in ["focus","resize","scene","state","cancel"]:
		fixture();target=local(Vector2(750,727));before=world.player;touch(10,target,true)
		match reason:
			"focus":world._notification(Control.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
			"resize":world.size+=Vector2(1,0)
			"scene":state.d.native.scene="campus_bootstrap"
			"state":state.d=state.d.duplicate(true)
		touch(10,target,false,reason=="cancel")
		check(actions.is_empty() and world._floor_route.is_empty() and world.player==before and not world.direct_gestures.has_active(),"stale release is neutral after "+reason)
	fixture();world.player=Vector2(715,770);world._sync_player();world._update_camera();world.queue_redraw();await process_frame;target=local(Vector2(750,727))
	touch(20,target,true);check(actions.is_empty(),"entity touch still waits for release")
	touch(20,target,false)
	check(actions.count("lib_open_record")==1 and state.d.native.page=="library_record","entity tap submits the original range-validated controller exactly once")
	touch(20,target,false);check(actions.count("lib_open_record")==1,"duplicate entity release cannot repeat controller action")
	world.queue_free();await process_frame
	print("DIRECT_WORLD_INPUT: %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
