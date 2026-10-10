extends SceneTree
const Feedback=preload("res://scripts/presentation/c3_admission_feedback.gd")
const Metrics=preload("res://scripts/player_metrics.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func _initialize()->void:run.call_deferred()
func run()->void:
	check(ProjectSettings.globalize_path("user://").begins_with("/tmp/"),"isolated test save")
	if failures:quit(1);return
	var state:Node=root.get_node("State");state.developer_mode=true;state.begin_checkpoint("c3-theater-code")
	state.d.items.temporaryTheaterTicket=true;state.d.native.selected_item="temporaryTheaterTicket"
	state.d.native.player={"x":842.0,"y":740.0,"scene":"theater_interior"};state.d.native.positions={"theater_interior:":{"x":842.0,"y":740.0}}
	var main:Control=load("res://scenes/main.tscn").instantiate();root.add_child(main)
	for i in 4:await process_frame
	var world:Control=main.world;var host:Control=main.c3_narrative_host
	main._show_world_mobile();world.set_process(false);host.set_process(false);world.player=Vector2(842,740);world._sync_player();world._process(0)
	check(world.can_stand(world.player),"recording start is outside every fixture")
	check(world.player.distance_to(Vector2(907,732))<88,"start within even strict reader-center radius")
	check(not world.chapter3_layers.doors.sensor_open,"start does not open exterior entrance")
	world.chapter3_layers.doors.sensor_open=true;world.chapter3_layers.doors.set_open(true);world.chapter3_layers.doors.advance(520)
	for i in 20:world._process(.05)
	check(not world.chapter3_layers.doors.sensor_open and world.chapter3_layers.doors.progress==0,"start also closes an already open exterior sensor")
	var collisions:Array=world.collisions.duplicate(true)
	var arm:Dictionary=world.chapter3_layers.entries(state.d).filter(func(e:Dictionary):return e.id=="ticket_gate_arm")[0]
	check(arm.open_ratio==0 and Feedback.gate_tip(0)==Vector2(786,700),"closed visual spans actual fixture gap inside existing blocker")
	check(arm.depth==794,"arm uses blocker-south edge and player foot-bottom sorting")
	check(arm.depth<689+120 and arm.depth>660+120,"closed-side actor stays in front; crossed-side actor is behind gate")
	world.touch_axis=Vector2.UP
	for i in 25:world._process(.05)
	world.touch_axis=Vector2.ZERO
	check(world.player.y>=688.625,"existing pre-admission blocker still blocks passage")
	world.player=Vector2(842,740);world._sync_player()
	state.act("c3_target:theater_ticket_gate");host.tick(0,true);world._process(0)
	var session:RefCounted=host.current
	check(session!=null and session.sequence_id=="theater_admission","actual safe-start interaction accepts original valid ticket")
	check(not host.blocks_movement(),"original admission dialogue permits normal walking")
	var after:Array=world.collisions
	check(after.size()==collisions.size()-1,"only existing gate blocker is removed")
	for box:Dictionary in after:check(collisions.has(box),"new visual does not modify other collisions")
	check(world.chapter3_layers.admission_pose(state.d).accepted,"reader and barrier share actual accepted edge")
	for i in 6:host.tick(100,true);world._process(0)
	arm=world.chapter3_layers.entries(state.d).filter(func(e:Dictionary):return e.id=="ticket_gate_arm")[0]
	check(arm.open_ratio==1 and Feedback.gate_tip(1).is_equal_approx(Vector2(883,603)),"bar raises vertically against reader hinge, never toward exterior door")
	check(Feedback.gate_tip(1).x-Metrics.visual_rect(Vector2(842,660)).end.x>8,"fully open arm clears complete player frame at passage")
	var paused:Dictionary=world.chapter3_layers.admission_pose(state.d);host.tick(100,false)
	for i in 10:world._process(.05)
	check(world.chapter3_layers.admission_pose(state.d)==paused,"pause freezes arm and reader with narrative clock")
	world.touch_axis=Vector2.UP
	for i in 14:
		host.tick(50,true);world._process(.05)
		check(world.can_stand(world.player),"normal movement stays collision safe while crossing gate")
	world.touch_axis=Vector2.ZERO
	check(world.player.y<630 and world.player.y>610,"player visibly crosses bar line before authored handoff")
	check(not world.chapter3_layers.doors.sensor_open,"northward path never opens exterior entrance")
	var teleports:Array=[]
	var listener:Callable=func(p:Array):teleports.append(p)
	state.world_teleport.connect(listener)
	while host.current!=null:host.tick(100,true);world._process(0)
	check(session.status=="consumed" and teleports.size()==1 and world.player==Vector2(1080,590),"unchanged dialogue ends with one original auditorium handoff")
	check(state.d.items.temporaryTheaterTicket,"ticket still available for later scanner")
	state.world_teleport.disconnect(listener)
	for reduced in [false,true]:
		var prior:float=0
		for ms in range(0,650,10):
			var p:Dictionary=Feedback.sample(float(ms),true,reduced)
			check(p.gate_open>=prior and p.gate_open<=1,"arm opening is bounded and monotone")
			prior=p.gate_open
	check(Feedback.sample(INF,true).gate_open==1 and Feedback.sample(INF,false).gate_open==0,"restored gate matches saved admission without replay")
	await main.shutdown();main.queue_free();await process_frame
	print("THEATER_GATE_PASSAGE: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
