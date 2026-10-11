extends SceneTree
const Feedback=preload("res://scripts/presentation/c3_admission_feedback.gd")
const Layers=preload("res://scripts/ui/chapter3_world_layers.gd")
var checks:=0
var failures:=0
var state: Node
var shell: Control
func check(ok: bool,label: String)->void:
	checks+=1
	if not ok: failures+=1; push_error(label)
func _initialize()->void: run.call_deferred()
func seed_gate(ticket: bool=true,dark: bool=false)->void:
	state.begin_checkpoint("c3-theater-code")
	state.d.items.temporaryTheaterTicket=ticket
	state.d.native.mode="dark" if dark else "light"
	state.d.native.selected_item="temporaryTheaterTicket" if ticket else ""
	state.d.native.player={"x":907.0,"y":812.0,"scene":"theater_interior"}
	state.d.native.positions={"theater_interior:":{"x":907.0,"y":812.0}}
func run()->void:
	check(ProjectSettings.globalize_path("user://").begins_with("/tmp/"),"isolated user profile")
	if failures: quit(1);return
	state=root.get_node("State"); state.developer_mode=true
	for t in [-1.0,0.0,350.0,899.0,900.0,1020.0,1160.0,1420.0,5440.0,9000.0,INF]:
		for reduced in [false,true]:
			var rejected:Dictionary=Feedback.sample(t,false,reduced)
			check(not rejected.accepted and rejected.check_progress==0 and rejected.offset==Vector2.ZERO,"no success pose without admitted fact")
			var pose:Dictionary=Feedback.sample(t,true,reduced)
			check(ResourceLoader.exists(pose.asset),"all poses reuse existing source actor art")
			check(pose.offset.length()<=4.01 and absf(pose.angle)<=3.01,"bounded original-scale gesture")
			if reduced:check(pose.offset==Vector2.ZERO and pose.angle==0 and pose.pulse==0,"reduced motion has no nod or pulse")
	check(Feedback.sample(0,true).accepted and Feedback.sample(260,true).check_progress==1,"reader acknowledges the same accepted event as gate release")
	check(Feedback.sample(1020,true).offset.y>0 and Feedback.sample(1420,true).asset.ends_with("idle_right.png"),"nod resolves to direction-facing pose")
	check(Feedback.sample(INF,true).check_progress==1 and Feedback.sample(INF,true).offset==Vector2.ZERO,"loaded admitted state has settled check without replay")
	for denied in ["missing","dark","far"]:
		seed_gate(denied!="missing",denied=="dark")
		if denied=="far":state.d.native.player.x=1200
		state.act("c3_target:theater_ticket_gate")
		check(not state.d.theaterHunt.admitted and state.d.theaterHunt.phase=="entry_ticket","invalid admission refused: "+denied)
	for variant in [{"dim":Vector2i(1280,720),"reduced":false},{"dim":Vector2i(390,844),"reduced":false},{"dim":Vector2i(390,844),"reduced":true}]:
		var dim:Vector2i=variant.dim
		seed_gate();root.size=dim;state.d.native.settings.reduced_motion=variant.reduced
		shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell)
		for i in 4:await process_frame
		var world:Control=shell.world;var host:Control=shell.c3_narrative_host
		world.set_process(false);host.set_process(false)
		world.player=Vector2(907,812);world._sync_player();world.refresh_world()
		var teleports:Array=[]
		var listener:Callable=func(p:Array):teleports.append(p)
		state.world_teleport.connect(listener)
		state.act("c3_target:theater_ticket_gate");host.tick(0,true);world._process(0)
		var session:RefCounted=host.current
		check(session!=null and session.sequence_id=="theater_admission","actual Main attaches accepted ticket dialogue")
		check(session.duration_ms==(8800 if variant.reduced else 8980) and session.lines.size()==3,"all original dialogue lines and duration preserved")
		check(state.d.theaterHunt.admitted and state.d.theaterHunt.phase=="program_search" and state.d.rpgCheckpoint=="theater_auditorium","only controller grants admission/checkpoint")
		check(world.player==Vector2(907,812) and teleports.is_empty(),"success feedback cannot teleport early")
		state.act("c3_story_complete",null);state.act("c3_story_complete",session)
		check(teleports.is_empty() and session.status=="playing","forged/early acknowledgement cannot enter auditorium")
		for i in 10:host.tick(100,true);world._process(0)
		var before:Dictionary=world.chapter3_layers.admission_pose(state.d)
		var actor_before:Dictionary=world.chapter3_layers.entries(state.d).filter(func(e:Dictionary):return e.id=="ticket_inspector")[0]
		host.tick(100,false)
		for i in 220:world.chapter3_layers.tick(.05,state.d)
		check(world.chapter3_layers.admission_pose(state.d)==before and session.elapsed_ms==1000,"focus loss freezes gesture even if world presentation ticks")
		check(world.chapter3_layers.entries(state.d).filter(func(e:Dictionary):return e.id=="ticket_inspector")[0]==actor_before,"actual actor point and angle stay frozen past nine seconds of blur")
		var facts:String=JSON.stringify(state.d)
		for i in 20:world.chapter3_layers.entries(state.d)
		check(JSON.stringify(state.d)==facts,"drawing cannot change saved facts or inventory")
		while host.current!=null:host.tick(100,true);world._process(0)
		check(session.status=="consumed" and teleports.size()==1,"original terminal dispatch enters exactly once")
		check(world.player==Vector2(1080,590),"actual World receives authored auditorium spawn")
		check(state.d.items.temporaryTheaterTicket,"ticket retained for original later prop scanner")
		state.act("c3_story_complete",session);state.act("c3_target:theater_ticket_gate")
		check(teleports.size()==1,"stale completion and repeated ticket use cannot replay admission")
		state.world_teleport.disconnect(listener)
		await shell.shutdown();shell.queue_free();await process_frame
	seed_gate();var layers=Layers.new();layers.sync(state.d,true);state.act("c3_target:theater_ticket_gate");layers.sync(state.d)
	var cancelled:RefCounted=state.get_c3_narrative_session();layers.narrative_session=cancelled
	cancelled.elapsed_ms=1050;cancelled.cancel()
	check(layers.admission_pose(state.d).offset==Vector2.ZERO,"cancelled session removes unfinished gesture")
	var replacement:Dictionary=state.d.duplicate(true)
	check(layers.admission_pose(replacement).offset==Vector2.ZERO,"replaced state cannot reuse old session pose")
	layers.sync(replacement,true)
	check(layers.admission_ms==INF and layers.admission_pose(replacement).check_progress==1,"reentry shows static accepted reader without scanning again")
	state.story_reset.emit()
	print("THEATER_ADMISSION: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
