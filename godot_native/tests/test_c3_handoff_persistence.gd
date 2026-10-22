extends SceneTree
## Focused fixtures, not a fresh/manual campaign. Terminal defense is replayed
## from real model inputs; every transition and persistence uses State APIs.
const DefenseSolver=preload("res://tests/campaign_defense_solver.gd")
var state:Node
var chapter:RefCounted
var witness:Node
var failures:=0
var checks:=0
func _initialize():run.call_deferred()
func check(ok:bool,label:String):
	checks+=1
	if not ok:failures+=1;push_error(label)
func fresh(scene:String):
	state.d=state.initial();state.d.native.chapter=3;state.d.native.scene=scene;state.d.native.page="c3_canteen" if scene=="canteen_interior" else "c3_theater";state.d.rpgScene=scene;state.d.runtimeMode="rpg"
func drain() -> void:
	var session:RefCounted=state.get_c3_narrative_session()
	check(session!=null,"pending narrative exists")
	if session==null:return
	check(session.attach(state.d,witness),"fresh host attaches issued narrative")
	for i in range(2000):
		if session.status!="playing":break
		session.frame(state.d,100,witness)
	check(session.status=="complete","authored narrative reaches terminal clock")
	state.act("c3_story_complete",session)
	check(session.status=="consumed","controller consumes transition once")
func run():
	check(load("res://tests/native_test_isolation.gd").is_isolated_save(),"persistence regression cannot overwrite a player's save")
	if failures:quit(1);return
	state=root.get_node("State");witness=Node.new();root.add_child(witness)
	for module in state.modules:
		if module.get_script().resource_path.ends_with("/chapter3.gd"):chapter=module
	fresh("canteen_interior");state.d.canteenHunt.active=true;state.d.canteenHunt.phase="exit_blocking"
	var request:Dictionary=state.act("c3_defense")
	var model:RefCounted=DefenseSolver.new().solve(str(request.game.seed),null,false)
	var proof:Dictionary=model.result();proof.session_id=request.game.session_id
	state.act("c3_defense_result",proof)
	check(model.status=="won" and state.d.canteenHunt.phase=="chase_ready","validated defense earns exit handoff")
	check(state.d.native.has("c3_pending_handoff"),"pending receipt precedes autosave")
	var pose:Dictionary=state.d.native.c3_pending_handoff.duplicate(true)
	check(state.load_game(),"quit during escape can load formal autosave")
	var session:RefCounted=state.get_c3_narrative_session()
	check(session!=null and session.sequence_id=="canteen_escape","escape reconstructs from receipt")
	if session!=null:check(Vector2(session.spec.paperStart[0],session.spec.paperStart[1]).distance_to(Vector2(pose.paperX,pose.paperY))<0.001,"winning paper pose survives interruption")
	drain()
	check(state.d.native.scene=="campus_bootstrap" and not state.d.native.has("c3_pending_handoff"),"completed escape returns to campus and clears receipt")
	check(state.load_game() and state.get_c3_narrative_session()==null,"completed escape does not replay on reload")
	fresh("theater_interior");state.d.theaterHunt.active=true;state.d.theaterHunt.phase="entry_ticket"
	drain()
	check(state.d.native.get("c3_theater_entry_seen",false),"intro acknowledgement is persistent")
	check(state.load_game() and state.get_c3_narrative_session()==null,"finished intro is not replayed while ticket puzzle remains open")
	state.d.items.temporaryTheaterTicket=true
	var gate:Dictionary=chapter.get_definition("theater_interior","theater_ticket_gate",state.d)
	var stand:Dictionary=gate.get("stand",gate)
	state.d.native.player={"x":stand.x,"y":stand.y,"scene":"theater_interior"}
	state.act("c3_target:theater_ticket_gate")
	check(state.d.theaterHunt.admitted and state.d.native.has("c3_pending_handoff"),"accepted gate saves pending auditorium admission")
	check(state.load_game(),"admission reload is valid")
	drain()
	var point:Dictionary=chapter.world("theater_interior").spawns.theater_auditorium
	check(state.d.native.positions.get("theater_interior:",{})=={"x":point.x,"y":point.y},"admission destination commits before visual teleport")
	check(state.load_game() and state.d.native.positions.get("theater_interior:",{})=={"x":point.x,"y":point.y},"immediate reload retains auditorium destination")
	check(state.get_c3_narrative_session()==null,"consumed admission never replays")
	var invalid:Dictionary=state.d.duplicate(true);invalid.native.c3_pending_handoff=pose.duplicate(true);invalid.native.c3_pending_handoff.id="arbitrary_callback"
	check(not state.validate_snapshot(invalid),"save cannot inject arbitrary narrative callbacks")
	witness.queue_free();await process_frame
	print("C3_HANDOFF_PERSISTENCE ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
