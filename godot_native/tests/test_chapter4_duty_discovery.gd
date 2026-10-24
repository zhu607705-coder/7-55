extends SceneTree
const Model=preload("res://scripts/games/chapter4_duty_board.gd")
const Chapter=preload("res://scripts/chapters/chapter4.gd")
const Driver=preload("res://tests/helpers/duty_board_driver.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func _initialize()->void:call_deferred("run")
func run()->void:
	var valid_count:=0
	for a:String in Model.IDS:
		for b:String in Model.IDS:
			for c:String in Model.IDS:
				if a==b or b==c or a==c:continue
				for mask:int in 8:
					var cp:Dictionary={"version":1,"order":[a,b,c],"backs":{}}
					for i:int in 3:cp.backs[Model.IDS[i]]=bool(mask&(1<<i))
					check(Model.valid(cp),"All 48 complete physical configurations are valid drafts")
					if Model.connected(cp):valid_count+=1
	check(valid_count==1,"All contacts constrain one whole composition; no individual lock")
	var state:Node=root.get_node("State");state.developer_mode=true
	state.begin_checkpoint("c4-755-classrooms-1850")
	state.act("c4_device_duty_board")
	var original:Dictionary=state.d.duplicate(true)
	for i:int in 10:state.act("c4_solve_duty_board",{"a":"classroom_104","b":"classroom_105","c":"main_elevator"})
	check(not "a1_duty_board_reconstructed" in state.d.chapter4.factIds,"Answer-only repeated presses cannot bypass paper object state")
	state.act("c4_duty_event",Driver.events()[0])
	var draft:Dictionary=state.d.native.c4_duty_board.duplicate(true)
	check(state.validate_snapshot(state.d),"Wrong paper placement is a valid saved draft")
	state.developer_mode=false
	check(state.save_game(),"Unfinished paper draft writes through ordinary save")
	state.d=state.initial();check(state.load_game(),"Ordinary Continue accepts the serialized draft")
	check(state.d.native.get("c4_duty_board",{})==JSON.parse_string(JSON.stringify(draft)),"Ordinary Continue restores an unfinished paper placement")
	for event:Dictionary in Driver.events().slice(1):state.act("c4_duty_event",event)
	check(Model.connected(state.d.native.c4_duty_board),"Legal swaps and flips complete all contacts")
	check(not "a1_duty_board_reconstructed" in state.d.chapter4.factIds,"A matching draft alone grants nothing")
	state.act("c4_solve_duty_board",{"a":"classroom_104","b":"classroom_105","c":"main_elevator"})
	check("a1_duty_board_reconstructed" in state.d.chapter4.factIds,"Physical stamp commits the original fact")
	var invalid:Dictionary=state.d.duplicate(true);invalid.native.c4_duty_board.order[0]="forged"
	check(not state.validate_snapshot(invalid),"Unknown paper identity rejected on import")
	original.chapter4.factIds.append("a1_duty_board_reconstructed")
	check(state.validate_snapshot(original),"Old completed saves without a paper draft remain supported")
	print("DUTY_DISCOVERY ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
