extends SceneTree
## Source-guidance regression on copied dictionaries. Optional recorded input
## comes from C4_HANDOFF_INPUT; default is a synthetic source-data fixture.
const Chapter=preload("res://scripts/chapters/chapter4.gd")
var checks:=0
var failures:=0
var records:Array=[]
var source: Dictionary
var earned: Dictionary
func _initialize() -> void: run.call_deferred()
func check(ok: bool,label: String,actual: Variant=null,expected: Variant=null) -> void:
	checks+=1
	records.append({"check":label,"passed":ok,"actual":actual,"expected":expected})
	if not ok:failures+=1;push_error(label+" actual="+str(actual)+" expected="+str(expected))
func add_facts(s: Dictionary,ids: Array) -> void:
	for id in ids:
		if id not in s.chapter4.factIds:s.chapter4.factIds.append(id)
func objective(s: Dictionary,key: String,label: String) -> void:
	var controller: RefCounted=Chapter.new();var before:=JSON.stringify(s);var value: String=controller.objective(s);var expected: String=source.tasks[key].label
	check(value==expected,label,value,expected)
	check(JSON.stringify(s)==before,"Objective is read-only: "+label)
func run() -> void:
	var input_path:=OS.get_environment("C4_HANDOFF_INPUT")
	earned=JSON.parse_string(FileAccess.get_file_as_string(input_path)).state if not input_path.is_empty() else fixture()
	source=JSON.parse_string(FileAccess.get_file_as_string("res://data/source/chapter4-755.content.json"))
	check(earned.chapter4.room204Placements.size()==12 and "room204_restored" in earned.chapter4.factIds,"Input has the complete original Room204 placement set")
	var s: Dictionary=earned.duplicate(true)
	objective(s,"resolve_a2_inserted_puzzles","Original QuestModel first names unfinished A2 records")
	add_facts(s,["a2_positioning_plate_calibrated","a2_power_topology_recovered","a2_evacuation_route_confirmed"])
	objective(s,"resolve_elevator_stop_chain","Original next task names the missing floor-stop reconstruction")
	add_facts(s,["elevator_stop_chain_reconstructed"])
	objective(s,"resolve_a1_investigation","Original next task returns to unfinished A1 duty-board work")
	add_facts(s,["a1_duty_board_reconstructed"])
	objective(s,"watch_room204_projection","Projection goal only follows the original remaining records")
	var c: RefCounted=Chapter.new();var blocked: Dictionary=earned.duplicate(true);var before:=JSON.stringify(blocked)
	var reply: Dictionary=c.dispatch(blocked,"c4_projection")
	check(reply.message==source.intentFeedback.details.duty_board_required.reason,"Projection rejection names the missing original duty board",reply.message,source.intentFeedback.details.duty_board_required.reason)
	check(not reply.has("world_effect") and JSON.stringify(blocked)==before,"Missing record still prevents projection and writes no progress")
	blocked.chapter4.factIds.erase("a1_time_route_compared");reply=c.dispatch(blocked,"c4_projection")
	check(reply.message==source.intentFeedback.details.a1_comparison_required.reason,"Original comparison rejection precedes duty board",reply.message,source.intentFeedback.details.a1_comparison_required.reason)
	# The existing guarded return is available; absence of a record is not
	# sufficient evidence of a story dead end.
	var return_state: Dictionary=earned.duplicate(true);reply=c.dispatch(return_state,"c4_elevator")
	check(reply.has("open_c4_floor_selection") and "A1" in reply.open_c4_floor_selection.destinations,"Ordinary source return floor is offered")
	if reply.has("open_c4_floor_selection"):
		reply=c.dispatch(return_state,"c4_floor_select",{"session":reply.open_c4_floor_selection.session,"destination":"A1"})
	check(reply.has("world_effect") and reply.world_effect.get("destination")=="A1","Selected ordinary source return elevator remains available")
	var ready: Dictionary=earned.duplicate(true);add_facts(ready,["a1_duty_board_reconstructed"]);reply=c.dispatch(ready,"c4_projection")
	check(reply.has("world_effect"),"Existing readiness gate accepts the complete original record set")
	if reply.has("world_effect"):
		var effect: Dictionary=reply.world_effect
		check(effect.durationMs==900,"Original native projection timing remains900ms")
		var proof: Dictionary={"session":effect.session,"elapsedMs":899}
		c.dispatch(ready,"c4_projection_done",proof)
		check("room204_projection_completed" not in ready.chapter4.factIds,"Early terminal still rejects")
		proof.elapsedMs=900;c.dispatch(ready,"c4_projection_done",proof)
		check("room204_projection_completed" in ready.chapter4.factIds,"Original valid terminal remains the sole completion owner")
	all_task_branches()
	var output:=OS.get_environment("C4_HANDOFF_OUTPUT")
	if not output.is_empty():FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"scope":"Headless copied-state regression, not actual CUA progression","records":records},"  ")+"\n")
	print("C4_PROJECTION_HANDOFF_SOURCE ",checks," checks; ",failures," failures");quit(1 if failures else 0)

func all_task_branches() -> void:
	# Ordered source task coverage uses isolated dictionary copies, never the
	# saved campaign or a progression shortcut.
	var full: Dictionary=earned.duplicate(true)
	add_facts(full,["a2_positioning_plate_calibrated","a2_power_topology_recovered","a2_evacuation_route_confirmed","elevator_stop_chain_reconstructed","a1_duty_board_reconstructed","room204_projection_completed","positioning_plate_collected"])
	objective(full,"install_positioning_plate","Fully observed route names the original installation")
	var cases: Array=[
		["positioning_plate_collected","collect_positioning_plate"],
		["room204_projection_completed","watch_room204_projection"],
		["room204_restored","restore_room204"],
		["room204_residual_observed","restore_room204"],
		["a1_duty_board_reconstructed","resolve_a1_investigation"],
		["elevator_stop_chain_reconstructed","resolve_elevator_stop_chain"],
		["a2_positioning_plate_calibrated","resolve_a2_inserted_puzzles"],
		["a2_power_topology_recovered","resolve_a2_inserted_puzzles"],
		["a2_evacuation_route_confirmed","resolve_a2_inserted_puzzles"],
		["misaligned_stair_solved","solve_misaligned_stair"],
		["a3_reference_observed","resolve_a3_archive_chain"],
		["classroom_104_chalk_residual_observed","resolve_a1_investigation"],
		["classroom_105_terminal_replay_checked","resolve_a1_investigation"],
		["elevator_history_observed","resolve_a1_investigation"],
		["elevator_history_calibrated","resolve_a1_investigation"]]
	for entry in cases:
		var s: Dictionary=full.duplicate(true);s.chapter4.factIds.erase(entry[0])
		objective(s,entry[1],"Source objective after missing "+entry[0])
	var mismatch: Dictionary=earned.duplicate(true);mismatch.chapter4.timeState="1225_bakery"
	objective(mismatch,"tune_clock_to_1850","Wrong time takes precedence over other missing records")
	var c: RefCounted=Chapter.new()
	for fact in ["a3_reference_observed","room204_residual_observed","room204_restored"]:
		var state: Dictionary=earned.duplicate(true);add_facts(state,["a1_duty_board_reconstructed"]);state.chapter4.factIds.erase(fact)
		var before:=JSON.stringify(state);var result: Dictionary=c.dispatch(state,"c4_projection")
		var code: String="room204_layout_incomplete" if fact=="room204_restored" else "room204_observations_required"
		check(result.message==source.intentFeedback.details[code].reason,"Original rejection for missing "+fact,result.message,source.intentFeedback.details[code].reason)
		check(not result.has("world_effect") and JSON.stringify(state)==before,"Rejection cannot mutate or open projection: "+fact)

func fixture() -> Dictionary:
	var s: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/initial_state.json"))
	s.native={"chapter":4,"page":"c4_notes","scene":"duan_yongping_temporal_maze","mode":"light","player":{},"settings":{},"log":[],"completed":[]}
	s.chapter4.merge({"phase":"room204_restore","floor":"A2","timeState":"1850_evening","mode":"light","prologueSeen":true},true)
	s.chapter4.factIds=["hour_hand_installed","classroom_104_chalk_residual_observed","classroom_105_terminal_replay_checked","elevator_history_calibrated","elevator_history_observed","a1_time_route_compared","a3_reference_observed","a3_identity_context_observed","misaligned_stair_solved","room204_residual_observed","room204_restored"]
	s.chapter4.room204Placements=[]
	var content: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/source/chapter4-755.content.json"))
	for group in content.room204.groups:
		for mapping in group.mappings:
			s.chapter4.room204Placements.append({"pieceId":mapping.pieceId,"slotId":mapping.slotId,"orientation":"up"})
	return s
