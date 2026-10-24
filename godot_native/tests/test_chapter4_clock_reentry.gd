extends SceneTree
const Chapter=preload("res://scripts/chapters/chapter4.gd")
const Model=preload("res://scripts/games/chapter4_clock_chain.gd")
const Driver=preload("res://tests/helpers/clock_chain_driver.gd")
var checks:=0
var failures:=0
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func run()->void:
	var store=root.get_node("State")
	for index in 3:
		var id:String=Model.IDS[index]
		var s:Dictionary=store.initial();s.native.chapter=4;s.native.scene=Chapter.SCENE;s.native.page="c4_notes";s.native.mode="light";s.runtimeMode="rpg";s.rpgScene=Chapter.SCENE
		s.chapter4.prologueSeen=true;s.chapter4.phase=["hall_clock_inspection","room204_restore","maintenance_repair"][index];s.chapter4.timeState=["2245_opening","1225_bakery","1850_evening"][index];s.chapter4.factIds=[Model.data().runs[id].fact];s.chapter4.floor="A1";s.chapter4.mode="light"
		var c=Chapter.new();var before:Dictionary=s.chapter4.duplicate(true)
		check(c.targets(Chapter.SCENE,s)[0].action=="c4_clock","required-time target remains clock")
		check(c.dispatch(s,"c4_clock").get("page")=="c4_device","misaligned original phase can reach clock")
		check(s.chapter4==before,"opening changes no story")
		var request:Dictionary=c.dispatch(s,"c4_clock_begin");var token:Dictionary=request.clock.session
		c.dispatch(s,"c4_clock_event",{"session":token,"event":{"kind":"source","id":"hall"}})
		c.dispatch(s,"c4_clock_cancel",{"session":token})
		check(Model.current(s,id).step==1,"closing keeps completed inference")
		c.dispatch(s,"c4_clock");request=c.dispatch(s,"c4_clock_begin");check(request.clock.checkpoint.step==1 and request.clock.session!=token,"reentry preserves chain and replaces session")
		check(not c.dispatch(s,"c4_elevator_ride").has("world_effect") and s.chapter4==before,"new chain does not bypass original alignment gate")
		for event in Driver.events(id).slice(1):c.dispatch(s,"c4_clock_event",{"session":request.clock.session,"event":event})
		c.dispatch(s,"c4_clock_set",{"session":request.clock.session,"time":id})
		check(s.chapter4.timeState==id,"each original time remains reachable through connected chain")
	print("CLOCK_REENTRY ",checks," checks; ",failures," failures");quit(1 if failures else 0)
