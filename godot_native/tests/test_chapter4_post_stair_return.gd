extends SceneTree
const Chapter=preload("res://scripts/chapters/chapter4.gd")
var checks:=0
var failures:=0
var original: Dictionary
func _initialize() -> void:run.call_deferred()
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func state_for(floor: String="A1") -> Dictionary:
	var s: Dictionary=original.duplicate(true);s.chapter4.floor=floor;s.native.scene="duan_yongping_temporal_maze";s.native.c4_elevator_transport=true
	return s
func selection(c: RefCounted,s: Dictionary) -> Dictionary:
	var before:=JSON.stringify(s);var r: Dictionary=c.dispatch(s,"c4_elevator")
	check(r.has("open_c4_floor_selection"),"Solved stair opens original floor selection from "+s.chapter4.floor)
	check(JSON.stringify(s)==before,"Opening selection cannot mutate saved progress")
	return r.get("open_c4_floor_selection",{})
func run() -> void:
	var path:=OS.get_environment("C4_RETURN_INPUT")
	original=JSON.parse_string(FileAccess.get_file_as_string(path)).state if not path.is_empty() else fixture_state()
	for from: String in ["A1","A2","A3"]:
		for to: String in ["A1","A2","A3"]:
			if from==to:continue
			var s:=state_for(from);var c: RefCounted=Chapter.new();var open:=selection(c,s)
			if open.is_empty():continue
			check(open.fromFloor==from and open.destinations.has(to) and not open.destinations.has(from),"Only other permitted source floors offered")
			var before:=JSON.stringify(s);var r: Dictionary=c.dispatch(s,"c4_floor_select",{"session":"forged","destination":to})
			check(not r.has("world_effect") and JSON.stringify(s)==before,"Forged selection cannot travel")
			r=c.dispatch(s,"c4_floor_select",{"session":open.session,"destination":to})
			check(r.has("world_effect") and s.chapter4.floor==from,"Choice issues existing ride without early floor progress")
			if not r.has("world_effect"):continue
			var fx: Dictionary=r.world_effect
			check(fx.kind=="elevator_ride" and fx.destination==to and fx.durationMs==2720+620*abs(int(from.substr(1))-int(to.substr(1))),"Original elevator timing and presentation retained")
			var proof: Dictionary={"session":fx.session,"fromFloor":from,"destination":to,"elapsedMs":fx.durationMs-1,"boarded":true,"arrived":true}
			c.dispatch(s,"c4_floor_arrived",proof);check(s.chapter4.floor==from,"Early arrival still rejected")
			proof.elapsedMs=fx.durationMs;proof.destination=from;c.dispatch(s,"c4_floor_arrived",proof);check(s.chapter4.floor==from,"Mismatched destination still rejected")
			proof.destination=to;r=c.dispatch(s,"c4_floor_arrived",proof)
			check(s.chapter4.floor==to and r.has("teleport"),"Validated original arrival changes floor once")
			var landing: Dictionary=c.layout.floors[int(to.substr(1))-1].elevator.arrivalPosition
			var key: String="duan_yongping_temporal_maze:"+to+":"+s.chapter4.timeState+":"+s.chapter4.phase
			check(s.native.positions.get(key,{})=={"x":landing.x,"y":landing.y},"Source landing persists before save")
			before=JSON.stringify(s);r=c.dispatch(s,"c4_floor_arrived",proof);check(JSON.stringify(s)==before and not r.has("teleport"),"Duplicate arrival cannot repeat progression")
	var c: RefCounted=Chapter.new();var s:=state_for();var first:=selection(c,s);var second:=selection(c,s)
	if not second.is_empty():
		c.dispatch(s,"c4_cancel_floor_selection",{"session":first.session});check(c.pending.get("token")==second.session,"Old cancellation cannot retire newer selection")
		c.dispatch(s,"c4_cancel_floor_selection",{"session":second.session});check(c.pending.is_empty(),"Close cancels current selection")
		check(not c.dispatch(s,"c4_floor_select",{"session":second.session,"destination":"A2"}).has("world_effect"),"Cancelled choice cannot travel")
		var fresh: RefCounted=Chapter.new();check(not fresh.dispatch(s,"c4_floor_select",{"session":second.session,"destination":"A2"}).has("world_effect"),"Reload does not restore a live selection token")
	# The actual stair proof remains; replay is not required after its original fact.
	s=state_for("A3");var saved_proof: Variant=s.native.get("c4_stair_proof");var r: Dictionary=c.dispatch(s,"c4_stairs")
	check(s.chapter4.floor=="A2" and not r.has("game"),"Solved original stair returns normally to A2")
	check(s.native.get("c4_stair_proof")==saved_proof,"Ordinary return preserves prior four-level proof")
	s=state_for("A3");s.chapter4.factIds.erase("misaligned_stair_solved");s.chapter4.stairAlignmentSolved=true;r=c.dispatch(s,"c4_stairs")
	check(r.has("game") and r.game.kind=="chapter4_stair_campaign" and s.chapter4.floor=="A3","First traversal still requires original campaign despite a loose boolean")
	s=state_for();s.chapter4.factIds.erase("misaligned_stair_solved");r=c.dispatch(s,"c4_elevator")
	check(not r.has("open_c4_floor_selection"),"Unsolved state cannot open post-solved floor selection")
	print("C4_POST_STAIR_RETURN ",checks," checks; ",failures," failures");quit(1 if failures else 0)

static func fixture_state() -> Dictionary:
	var s: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/initial_state.json"))
	s.native={"chapter":4,"page":"c4_notes","scene":"duan_yongping_temporal_maze","mode":"light","player":{},"positions":{},"settings":{},"log":[],"completed":[],"c4_elevator_transport":true,"c4_stair_proof":{"fixture":"preserved, not an earned campaign proof"}}
	s.chapter4.merge({"phase":"room204_restore","floor":"A1","timeState":"1850_evening","mode":"light","prologueSeen":true},true)
	s.chapter4.factIds=["hour_hand_installed","classroom_104_chalk_residual_observed","classroom_105_terminal_replay_checked","elevator_history_calibrated","elevator_history_observed","a1_time_route_compared","a3_reference_observed","a3_identity_context_observed","misaligned_stair_solved"]
	return s
