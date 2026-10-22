extends "res://tests/test_full_campaign.gd"
## Earned snapshots from the uninterrupted controller campaign, never DEV seeds.
## Positions are still explicit campaign test setup, not manual-navigation proof.
var capture_dir := OS.get_environment("CONTINUITY_CAPTURE_DIR")
const CAPTURE_ACTIONS := ["c1_checkin","c2_dorm_exit","lib_opening_complete","c3_defense_result","c3_chase_result","c3_enter_theater","c3_target:theater_ticket_gate","c3_target:theater_exit","c3_rain_rescue_result","c35_replay","c4_prologue_end","c4_checkin_card","c4_checkin_paper","c4_lamp_start"]
func run() -> void:
	var owner:Node=root.get_node("State")
	owner.action_completed.connect(func(action:String,_before:Dictionary,_after:Dictionary,_result:Dictionary):
		if action in ["c4_prologue_end","c4_checkin_card","c4_lamp_start","c4_arrive_a3","c4_arrive_a2","c4_chase_done"]:capture("action_"+action)
	)
	await super.run()
func step(id: String, value: Variant = null) -> Dictionary:
	await drain_c3()
	if id in CAPTURE_ACTIONS: capture("before_"+id)
	var result: Dictionary = state.act(id,value)
	trace.append({"action":id,"chapter":state.d.native.chapter,"phase":state.d.actOne.phase})
	check(result.get("handled",false),"handled " + id)
	if id in CAPTURE_ACTIONS: capture("after_"+id)
	if id in ["c3_defense_result","c3_target:theater_ticket_gate"]:
		check(state.load_game(),"interrupted handoff loads actual autosave "+id)
		var resumed:RefCounted=state.get_c3_narrative_session()
		check(resumed!=null and resumed.sequence_id==("canteen_escape" if id=="c3_defense_result" else "theater_admission"),"pending handoff restored "+id)
	await drain_library()
	await drain_c3()
	if id in CAPTURE_ACTIONS: capture("after_drained_"+id)
	return result
func boundary(label: String) -> void:
	await super.boundary(label)
	capture("boundary_"+label)
func capture(label: String) -> void:
	if capture_dir.is_empty(): return
	DirAccess.make_dir_recursive_absolute(capture_dir)
	var filename := label.replace(":","_").replace(" ","_")+".json"
	check(state.export_save(capture_dir.path_join(filename))==OK,"earned snapshot "+filename)
