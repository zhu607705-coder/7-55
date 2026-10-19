extends SceneTree
const Model=preload("res://scripts/games/chapter4_chase_stair_model.gd")
const Space=preload("res://scripts/games/chapter4_chase_space.gd")
const Chapter=preload("res://scripts/chapters/chapter4.gd")
const Metrics=preload("res://scripts/player_metrics.gd")
const Capture=preload("res://scripts/presentation/chapter4_guard_capture.gd")
var checks:=0
var failures:=0
func _initialize():run.call_deferred()
func check(ok:bool,label:String):
	checks+=1
	if not ok:failures+=1;push_error(label)
func frames(n:=3):
	for i in n:await process_frame
func path_from(start:int,targets:Array)->Array:
	var path:Array=[];var at:Vector2=Model.point(Model.data().landings[start].spawn);var clock:=0.0
	for target:Vector2 in targets:
		while at.distance_to(target)>.01:
			at=at.move_toward(target,20.8);clock+=100;path.append({"x":at.x,"y":at.y,"t":clock})
	return path
func new_path_from(space:RefCounted,start:int,targets:Array)->Array:
	var path:Array=[];var at:Vector2=space.vec(space.layout.landings[start].spawn);var clock:=0.0
	for target:Vector2 in targets:
		while at.distance_to(target)>.01:
			at=at.move_toward(target,20.8);clock+=100;path.append({"x":at.x,"y":at.y,"t":clock})
	return path
func proof(config:Dictionary,path:Array,landing:int=-1)->Dictionary:
	return {"kind":"chase_stairwell","session":config.session,"geometryVersion":config.get("geometryVersion",""),"expectedAttempt":config.expectedAttempt,"path":path.duplicate(true),"elapsedMs":path.back().t,"landing":landing,"escaped":landing==2}
func drive(game:Control,targets:Array):
	for target:Vector2 in targets:
		var safety:=0
		game.pointer_moving=true;game.pointer_target=target
		while game.player.distance_to(target)>=8 and not game.done and game.stage=="chase" and safety<250:
			game.elapsed+=50;game._chase(.05);safety+=1
		game.pointer_moving=false
		if game.done or game.stage!="chase":break
func run():
	for landing:int in 3:
		for lead:float in [100,650,1200,5000]:
			var entry:Dictionary=Model.guard_entry(landing,lead);var original:Dictionary=Model.data().landings[landing]
			check(entry.player==Model.point(original.spawn) and entry.guard==Model.point(original.guard),"Original landing spawn/guard")
			check(is_equal_approx(entry.delayMs,(clampf(lead,650,2000)-entry.player.distance_to(entry.guard))/174*1000),"Source lead-derived delay")
	check(not Model.player_open(Vector2(763.5,900)),"Original full foot rejects baseline wall overlap")
	check(Model.player_open(Vector2(765,900)),"Legal source corridor remains open")
	check(not Model.player_open(Vector2(INF,800)),"Nonfinite pose rejected")
	check(not Model.player_open(Vector2(833,940)),"Full body remains within source map")
	var first:Array=path_from(0,[Vector2(989,826),Vector2(989,426)])
	var second:Array=path_from(0,[Vector2(989,826),Vector2(989,426),Vector2(784,426),Vector2(784,207)])
	var complete:Array=path_from(0,[Vector2(989,826),Vector2(989,426),Vector2(784,426),Vector2(784,207),Vector2(715,207),Vector2(715,57)])
	check(Model.valid_trace(first,0,1,false,first.back().t),"Legitimate first-platform path")
	check(Model.valid_trace(second,0,2,false,second.back().t,first),"Unchanged first prefix continues to next gate")
	check(Model.valid_trace(complete,0,2,true,complete.back().t,second),"Full exit path remains validated")
	var short:Array=path_from(2,[Vector2(715,80)])
	check(short.size()<10 and Model.valid_trace(short,2,2,true,short.back().t),"Legitimate short resumed segment retains physical proof")
	check(not Model.valid_trace([],0,1,false,0),"Empty proof rejected")
	check(not Model.valid_trace([{"x":989,"y":426,"t":10}],0,1,false,10),"Teleport proof rejected")
	var bad:Array=first.duplicate(true);bad[0].t=1000
	check(not Model.valid_trace(bad,0,1,false,first.back().t),"Unobserved oversized time gap rejected")
	bad=first.duplicate(true);bad[0].x=NAN
	check(not Model.valid_trace(bad,0,1,false,first.back().t),"Nonfinite trace rejected")
	bad=first.duplicate(true);bad[0].x=[]
	check(not Model.valid_trace(bad,0,1,false,first.back().t),"Malformed coordinate rejected without casting")
	bad=second.duplicate(true);bad[0].x+=.1
	check(not Model.valid_trace(bad,0,2,false,second.back().t,first),"Accepted prefix cannot be rewritten")
	var space:=Space.new()
	# Legacy source model tests above remain independent. Controller/actual-input
	# checks below now traverse the authorized new space with unchanged rules.
	first=new_path_from(space,0,space.route.slice(1,9))
	second=new_path_from(space,0,space.route.slice(1,17))
	complete=new_path_from(space,0,space.route.slice(1))
	var state:Node=root.get_node("State");state.developer_mode=true;state.begin_checkpoint("c4-755-chase")
	var chapter:RefCounted=Chapter.new();var s:Dictionary=state.d.duplicate(true)
	var entered:Dictionary=chapter.dispatch(s,"c4_chase",{"expectedAttempt":s.chapter4.chaseAttempt,"leadDistance":1200})
	check(entered.has("game") and entered.game.guardLeadDistance==1200,"Actual world lead reaches issued configuration")
	var cfg:Dictionary=entered.game
	check(not chapter.dispatch(s,"c4_chase").has("game"),"Inside traversal cannot create a duplicate admission")
	var p:Dictionary=proof(cfg,first,1);var stale:Dictionary=p.duplicate(true);stale.session="wrong"
	check(not chapter.dispatch(s,"c4_chase_landing",stale).get("accepted",false),"Wrong session cannot commit platform")
	stale=p.duplicate(true);stale.expectedAttempt+=1
	check(not chapter.dispatch(s,"c4_chase_landing",stale).get("accepted",false),"Wrong attempt cannot commit platform")
	stale=p.duplicate(true);stale.expectedAttempt=NAN
	check(not chapter.dispatch(s,"c4_chase_landing",stale).get("accepted",false),"Nonfinite attempt rejected")
	stale=p.duplicate(true);stale.elapsedMs=[]
	check(not chapter.dispatch(s,"c4_chase_landing",stale).get("accepted",false),"Malformed elapsed time rejected without cast")
	check(not chapter.dispatch(s,"c4_chase_landing",proof(cfg,second,2)).get("accepted",false),"Platform order remains authoritative")
	check(chapter.dispatch(s,"c4_chase_landing",p).get("accepted",false) and s.chapter4.chaseStairwellLanding==1,"Controller commits first platform")
	check(not chapter.dispatch(s,"c4_chase_landing",p).get("accepted",false),"Duplicate platform callback rejected")
	var restored:Dictionary=JSON.parse_string(JSON.stringify(s));var old_cfg:Dictionary=cfg
	var resume:Dictionary=chapter.dispatch(restored,"c4_chase_resume");cfg=resume.game
	check(restored.chapter4.chaseStairwellLanding==1 and cfg.startLanding==1 and cfg.session!=old_cfg.session,"Serialized platform resumes with a new session")
	check(not chapter.dispatch(restored,"c4_chase_done",proof(old_cfg,complete,2)).get("accepted",false),"Old exit proof cannot cross the replacement session")
	var resumed_second:Array=new_path_from(space,1,space.route.slice(9,17))
	check(chapter.dispatch(restored,"c4_chase_landing",proof(cfg,resumed_second,2)).get("accepted",false),"Resumed first platform reaches second authoritatively")
	var resumed_exit:Array=new_path_from(space,1,space.route.slice(9))
	check(chapter.dispatch(restored,"c4_chase_done",proof(cfg,resumed_exit,2)).get("accepted",false) and restored.chapter4.floor=="A2","Resumed trace completes original exit")
	var arrival_key:="duan_yongping_temporal_maze:A2:0754_blackout:final_chase"
	check(restored.native.positions[arrival_key]=={"x":966.0,"y":214.0},"Arrival pose committed before save")
	# Actual native Main/Activity/controller wiring, driven only in this fixture.
	state.begin_checkpoint("c4-755-chase");root.size=Vector2i(390,844)
	var shell:Control=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames(5)
	state.act("c4_chase");await frames(2)
	var game:Control=shell.active_game;game.set_process(false)
	drive(game,space.route.slice(1,9))
	check(game.landing==1 and state.d.chapter4.chaseStairwellLanding==1,"Native movement signal commits saved platform")
	var old:Control=game;var old_proof:Dictionary=game._chase_proof_payload();old._leave_chase()
	check(not is_instance_valid(shell.active_game),"Deliberate Exit releases owner")
	shell._show_world_mobile();game=shell.active_game;game.set_process(false)
	check(game.config.startLanding==1 and game.player==Vector2(2820,800),"Explicit Return resumes original platform spawn")
	var attempt:int=state.d.chapter4.chaseAttempt
	old_proof.landing=2;old.progress_requested.emit(old_proof);old.attempt_failed.emit(old_proof)
	check(shell.active_game==game and state.d.chapter4.chaseAttempt==attempt,"Retired owner callbacks cannot affect replacement")
	await frames()
	game._leave_chase();await frames();shell._refresh();shell._layout();await frames()
	check(not is_instance_valid(shell.active_game),"Refresh/resize do not reopen deliberately exited activity")
	shell._show_world_mobile();game=shell.active_game;game.set_process(false)
	drive(game,space.route.slice(9))
	check(state.d.chapter4.floor=="A2" and not is_instance_valid(shell.active_game),"Native owned exit reaches A2 once")
	check(not shell.world.stair_handoff.is_empty() and float(shell.world.stair_handoff.leadDistance)>=600,"Accepted view hands original lead to A2")
	check(not shell.world.accept_stair_handoff({"attempt":attempt+1,"destination":"A2","leadDistance":1200}),"Stale handoff rejected")
	await frames()
	state.begin_checkpoint("c4-755-chase");await frames(3);state.act("c4_chase");await frames(2)
	game=shell.active_game;game.set_process(false)
	for i in 150:
		if game.chase_capture.active:break
		game.elapsed+=50;game._chase(.05)
	check(game.chase_capture.active and game.body.text.contains(Capture.LINE),"Real model contact opens original capture")
	check(game.failures==0 and state.d.chapter4.chaseAttempt==0,"Contact does not locally count failure")
	var early:Dictionary=game._chase_proof_payload();early.captured=true;early.guard={"x":game.guard.x,"y":game.guard.y};early.captureMs=5199
	check(not state.act("c4_chase_failed",early).get("accepted",false) and state.d.chapter4.chaseAttempt==0,"Controller rejects premature capture completion")
	early.captureMs=NAN
	check(not state.act("c4_chase_failed",early).get("accepted",false) and state.d.chapter4.chaseAttempt==0,"Controller rejects nonfinite capture time")
	var body:Vector2=game.player;var guard:Vector2=game.guard
	game._tick_chase_capture(5199)
	check(state.d.chapter4.chaseAttempt==0 and game.player==body and game.guard==guard,"5199ms capture holds physics and attempt")
	game._tick_chase_capture(1)
	check(state.d.chapter4.chaseAttempt==1 and state.d.chapter4.chaseStairwellLanding==0 and state.d.chapter4.chaseStairwellStage=="pending","5200ms original controller resets A1 attempt")
	var restart_key:="duan_yongping_temporal_maze:A1:0754_blackout:final_chase"
	check(state.d.native.positions[restart_key]=={"x":590.0,"y":612.0},"Failure save cannot retain stale stair pose")
	game._tick_chase_capture(9999);check(state.d.chapter4.chaseAttempt==1,"Failure callback occurs once")
	await frames()
	state.act("c4_chase");await frames(2);game=shell.active_game;game.set_process(false)
	for i in 150:
		if game.chase_capture.active:break
		game.elapsed+=50;game._chase(.05)
	var owner:RefCounted=game.chase_capture;game._leave_chase();await frames()
	check(not owner.active and state.d.chapter4.chaseAttempt==1,"Capture disposal cancels failure without retry")
	shell._show_world_mobile();game=shell.active_game;game.set_process(false)
	state.act("c4_fail_chase",{"expectedAttempt":1,"failureFloor":"A1"});game._process(.05);await frames()
	check(not is_instance_valid(shell.active_game) and state.d.chapter4.chaseAttempt==2,"Changed attempt retires stale activity without another failure")
	await shell.shutdown();shell.queue_free();await frames()
	print("CHAPTER4_CHASE_STAIR_RULES ",checks," checks; ",failures," failures");quit(1 if failures else 0)
