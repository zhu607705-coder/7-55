extends SceneTree
const Model=preload("res://scripts/games/chapter4_clock_chain.gd")
const Chapter=preload("res://scripts/chapters/chapter4.gd")
const Driver=preload("res://tests/helpers/clock_chain_driver.gd")
var checks:=0
var failures:=0
var store:Node
func check(ok:bool,message:String)->void:
	checks+=1
	if not ok:failures+=1;push_error(message)
func _initialize()->void:run.call_deferred()
func entry(id:String)->Dictionary:
	var s:Dictionary=store.initial()
	s.native.chapter=4;s.native.scene=Chapter.SCENE;s.native.page="c4_device";s.native.c4_context="clock";s.native.mode="light";s.runtimeMode="rpg";s.rpgScene=Chapter.SCENE
	var index:int=Model.IDS.find(id)
	s.chapter4.prologueSeen=true;s.chapter4.floor="A1";s.chapter4.mode="light"
	s.chapter4.phase=["hall_clock_inspection","room204_restore","maintenance_repair"][index]
	s.chapter4.timeState=["2245_opening","1225_bakery","1850_evening"][index]
	s.chapter4.factIds=[Model.data().runs[id].fact]
	return s
func run()->void:
	store=root.get_node("State");store.developer_mode=false
	for id in Model.IDS:
		var c=Chapter.new();var s:=entry(id);var before:Dictionary=s.chapter4.duplicate(true)
		check(store.validate_snapshot(s),"old entry without chain remains valid "+id)
		c.dispatch(s,"c4_clock_set",{"time":id});check(s.chapter4==before,"correct time alone cannot bypass deductions")
		var begin:Dictionary=c.dispatch(s,"c4_clock_begin");check(begin.has("clock"),"eligible clock begins")
		if not begin.has("clock"):continue
		var token:Dictionary=begin.clock.session
		for invalid in [{"kind":"source","id":"phone"},{"kind":"verify","id":"live"},{"kind":"repair","id":"backlash"},null,[],false,{"kind":3},{"kind":"source","id":"hall","forged":true}]:
			var result:Dictionary=c.dispatch(s,"c4_clock_event",{"session":token,"event":invalid})
			check(not result.get("accepted",false) and not s.native.has("c4_clock_chain"),"wrong and out-of-order events preserve progress")
		var previous_step:=0
		for event in Driver.events(id):
			var result:Dictionary=c.dispatch(s,"c4_clock_event",{"session":token,"event":event})
			check(result.get("accepted",false),"legal input "+str(event))
			check(store.validate_snapshot(s),"every partial checkpoint is saveable")
			var cp:Dictionary=Model.current(s,id)
			if cp.step!=previous_step:
				check(cp.step==previous_step+1,"no thinking stage skipped")
				previous_step=int(cp.step)
				store.d=s;check(store.save_game(),"save at stage boundary")
				check(store.load_game(),"ordinary Continue at stage boundary")
				check(Model.current(store.d,id)==cp,"Continue keeps completed deductions")
				check(not c.dispatch(store.d,"c4_clock_event",{"session":token,"event":event}).get("accepted",false),"old session rejected after reload")
				s=store.d;c=Chapter.new();c.dispatch(s,"c4_clock");token=c.dispatch(s,"c4_clock_begin").clock.session
		check(Model.completed(s,id) and s.chapter4.timeState==before.timeState,"seven steps do not silently change world time")
		var inventory:Dictionary=s.items.duplicate(true)
		c.dispatch(s,"c4_clock_set",{"time":id,"session":token})
		check(s.chapter4.timeState==id and s.items==inventory,"final crown commits original time without changing inventory")
		var after:Dictionary=s.duplicate(true)
		c.dispatch(s,"c4_clock_set",{"time":id,"session":token});check(s==after,"duplicate commit is inert")
		check(store.validate_snapshot(s),"finished checkpoint validates")
		var invalid:Dictionary=s.duplicate(true);invalid.native.c4_clock_chain.runs[id].step=2
		check(not store.validate_snapshot(invalid),"forged receipt with inconsistent dependencies rejected")
		invalid=s.duplicate(true);invalid.native.c4_clock_chain.runs[id].hour="12"
		check(not store.validate_snapshot(invalid),"malformed wheel state rejected")
		for mutation in ["mode","floor","scene","runtime","owner","cancel"]:
			var other:=entry(id);var guard=Chapter.new();var issued:Dictionary=guard.dispatch(other,"c4_clock_begin").clock.session
			match mutation:
				"mode":other.chapter4.mode="dark"
				"floor":other.chapter4.floor="A2"
				"scene":other.native.scene="library_interior"
				"runtime":other.runtimeMode="phone"
				"owner":other=other.duplicate(true)
				"cancel":guard.dispatch(other,"c4_clock_cancel",{"session":issued})
			check(not guard.dispatch(other,"c4_clock_event",{"session":issued,"event":{"kind":"source","id":"hall"}}).get("accepted",false),"stale capability rejects "+mutation)
	print("CLOCK_CHAIN ",checks," checks; ",failures," failures");quit(1 if failures else 0)
