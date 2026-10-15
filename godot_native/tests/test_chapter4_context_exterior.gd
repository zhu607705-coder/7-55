extends SceneTree
const Chapter=preload("res://scripts/chapters/chapter4.gd")
const Door=preload("res://scripts/ui/chapter4_exterior_door.gd")
var checks:=0
var failures:=0
func _initialize() -> void: run.call_deferred()
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error(message)
func run() -> void:
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/native/chapter4-context-source.json"))
	var state: Dictionary=root.get_node("State").initial()
	state.native.chapter=4; state.native.scene="duan_yongping_temporal_maze"; state.chapter4.prologueSeen=true
	var controller=Chapter.new()
	for entry in data.contexts:
		state.chapter4.floor=entry.floor; state.chapter4.phase="room204_restore"; state.chapter4.timeState="1850_evening"
		state.chapter4.roomId=entry.roomAliases[0]
		for mode in ["light","dark"]:
			state.chapter4.mode=mode
			var before=JSON.stringify(state)
			var result=controller.dispatch(state,"c4_context_"+entry.targetId)
			check(result.message==entry.textByTimeState["1850_evening"][mode],entry.targetId+" exact source "+mode+" text")
			check(JSON.stringify(state)==before,"context observation owns no state")
			var matches=controller.targets(state.native.scene,state).filter(func(t): return t.id==entry.targetId)
			check(matches.size()==1 and matches[0].radius==52,"context target uses source 52px bounds proximity")
		state.chapter4.roomId="a1_lobby"
		check(controller.targets(state.native.scene,state).all(func(t): return t.id!=entry.targetId),"wrong room cannot expose context")
		check(controller.dispatch(state,"c4_context_"+entry.targetId).message!=entry.textByTimeState["1850_evening"].dark,"wrong room cannot read context")
		state.chapter4.roomId=entry.roomAliases[0]; state.chapter4.phase="final_chase"
		check(controller.targets(state.native.scene,state).all(func(t): return t.id!=entry.targetId),"wrong phase cannot expose context")
	state.chapter4.phase="exterior_closure"; state.chapter4.floor="A1"; state.chapter4.roomId="a1_exterior"
	var before=JSON.stringify(state)
	var door=Door.new(); root.add_child(door); door.setup(func(): return state,func(p): return p)
	door.set_process(false)
	var results: Array=[]; door.opened.connect(func(): results.append(true))
	for i in range(4): door._process(.05)
	check(is_zero_approx(door.progress()) and results.is_empty(),"source 240ms delay does not show questions")
	for i in range(10): door._process(.05)
	check(door.progress()>0 and door.progress()<1 and results.is_empty(),"source door visibly opens through sine tween")
	for i in range(15): door._process(.05)
	check(is_equal_approx(door.progress(),1) and results.is_empty(),"hold remains until1500ms")
	door._process(.05); door._process(.05)
	check(results.size()==1 and door.finished,"one handoff after exact source1500ms")
	check(JSON.stringify(state)==before,"door presentation cannot write story or answers")
	door.queue_free(); await process_frame
	var interrupted=Door.new(); root.add_child(interrupted); interrupted.setup(func(): return state,func(p): return p); interrupted.set_process(false)
	interrupted.opened.connect(func(): results.append(true)); state.chapter4.phase="morning_checkin"; interrupted._process(.05)
	check(interrupted.cancelled and results.size()==1,"changed context cancels with no handoff")
	await process_frame
	print("C4_CONTEXT_EXTERIOR: ",checks," checks; ",failures," failures"); quit(1 if failures else 0)
