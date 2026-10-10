extends SceneTree
const Feedback=preload("res://scripts/presentation/c3_admission_feedback.gd")
const Gate=preload("res://scripts/presentation/c3_ticket_gate_view.gd")
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
	var arm:Dictionary=world.chapter3_layers.entries(state.d).filter(func(e:Dictionary):return e.id=="ticket_gate_wings")[0]
	check(arm.gate.open_ratio==0 and arm.gate.left_inner==833 and arm.gate.right_inner==836,"closed acrylic wings meet inside the original fixture gap")
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
	host.tick(100,true);world._process(0)
	var half:float=world.chapter3_layers.ticket_gate.openness
	check(half>0 and half<1,"pause exercise begins while wings are partly open")
	host.tick(100,false)
	for i in 10:world._process(.05)
	check(world.chapter3_layers.ticket_gate.openness==half,"partly open wings freeze on unchanged narrative clock")
	for i in 6:host.tick(100,true);world._process(0)
	arm=world.chapter3_layers.entries(state.d).filter(func(e:Dictionary):return e.id=="ticket_gate_wings")[0]
	check(arm.gate.open_ratio==1 and arm.gate.left_inner==789 and arm.gate.right_inner==880,"accepted wings retract horizontally into side fixtures")
	check(float(arm.gate.right_inner)-Metrics.visual_rect(Vector2(842,660)).end.x>6,"open wings clear complete player frame")
	var paused:Dictionary=world.chapter3_layers.admission_pose(state.d)
	var paused_gate:Dictionary=world.chapter3_layers.ticket_gate.pose()
	host.tick(100,false)
	for i in 10:world._process(.05)
	check(world.chapter3_layers.admission_pose(state.d)==paused and world.chapter3_layers.ticket_gate.pose()==paused_gate,"pause freezes arm and reader with narrative clock")
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
	for i in 24:world._process(.05)
	check(world.chapter3_layers.ticket_gate.openness==0,"wings close only after player is clear at original auditorium handoff")
	for reduced in [false,true]:
		var gate:RefCounted=Gate.new()
		var facts:Dictionary=state.d.duplicate(true);facts.native.settings.reduced_motion=reduced
		facts.theaterHunt.admitted=false;facts.native.player={"x":842.0,"y":740.0}
		gate.reset(facts);check(gate.openness==0,"not admitted keeps wings closed")
		facts.theaterHunt.admitted=true
		var prior:float=0
		for i in 60:
			gate.tick(10,facts)
			check(gate.openness>=prior and gate.openness<=1,"opening is bounded monotone")
			prior=gate.openness
		check(gate.openness==1,"accepted approach opens")
		facts.native.player.y=668.5
		for i in 100:gate.tick(50,facts)
		check(gate.openness==1,"occupied foot-body strip cannot close after any wait")
		facts.native.player={"x":1080.0,"y":590.0}
		for i in 9:gate.tick(50,facts)
		check(gate.openness==1,"full 450ms clearance hold does not spend time twice or close early")
		for i in 12:gate.tick(50,facts,session)
		check(gate.openness==0,"clear passage closes after hold")
		# Re-entry while closing must reopen before a panel touches the body.
		facts.native.player={"x":842.0,"y":740.0}
		for i in 20:gate.tick(50,facts)
		facts.native.player={"x":1080.0,"y":590.0}
		for i in 10:gate.tick(50,facts)
		facts.native.player={"x":842.0,"y":668.5};gate.tick(1,facts)
		check(gate.openness==1,"occupied re-entry overrides a closing panel")
		var saved:String=JSON.stringify(facts)
		for i in 50:gate.pose()
		check(JSON.stringify(facts)==saved,"visual wing state never changes story or saved facts")
		gate.reset(facts);check(gate.openness==1,"restore with actor in passage is open")
		facts.native.player={"x":1080.0,"y":590.0};gate.reset(facts)
		check(gate.openness==0,"restored distant admitted player has closed wings without replay")
	await main.shutdown();main.queue_free();await process_frame
	print("THEATER_GATE_PASSAGE: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
