extends SceneTree
const Chapter=preload("res://scripts/chapters/chapter4.gd")
var checks:=0
var failures:=0
func check(value:bool,label:String):
	checks+=1
	if not value:failures+=1;push_error(label)
func _initialize():run.call_deferred()
func run():
	var chapter=Chapter.new()
	var state:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/initial_state.json"))
	state.native={"chapter":4,"page":"c4_notes","scene":"duan_yongping_temporal_maze","mode":"light","player":{},"settings":{},"log":[],"completed":[]}
	state.chapter4.prologueSeen=true;state.chapter4.phase="bakery_hour_hand";state.chapter4.floor="A1";state.chapter4.timeState="1225_bakery";state.chapter4.mode="light";state.chapter4.factIds=["hall_clock_inspected"]
	check(chapter.objective(state)=="查查面包坊的传送带","Initial source objective")
	var request:Dictionary=chapter.dispatch(state,"c4_lamp_switch")
	check(request.has("world_effect"),"Original lamp starts its controlled stop presentation")
	check(chapter.objective(state)=="查查面包坊的传送带","No premature exposed objective")
	var effect:Dictionary=request.get("world_effect",{})
	chapter.dispatch(state,str(effect.get("on_success","")),{"session":effect.get("session",""),"kind":effect.get("kind",""),"elapsedMs":700,"acknowledged":true})
	check(chapter.objective(state)=="取走传送带上的旧时针","Validated stop selects source collect objective")
	chapter.dispatch(state,"c4_hour_hand")
	check(state.items.oldClockHourHand,"Unchanged controller grants item")
	check(chapter.objective(state)=="回大厅装回旧时针","Held hand selects source install objective")
	var serialized:String=JSON.stringify(state)
	var reload:Dictionary=JSON.parse_string(serialized)
	check(Chapter.new().objective(reload)=="回大厅装回旧时针","Normal saved state retains install objective")
	check(JSON.stringify(state)==serialized,"Objective read does not mutate progress")
	reload.items.oldClockHourHand=false
	check(chapter.objective(reload)=="回大厅装回旧时针","Source fact branch also restores collected guidance")
	chapter.dispatch(state,"c4_install_hour")
	check(not state.items.oldClockHourHand and state.chapter4.phase=="room204_restore","Existing install consumes once and advances original phase")
	check(chapter.objective(state)==str(chapter.content.tasks.tune_clock_to_1850.label),"Later original time objective remains intact")
	print("C4_BAKERY_OBJECTIVE ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
