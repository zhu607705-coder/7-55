extends SceneTree
## Fixture starts after the original projection, never after the new press.
const Chapter = preload("res://scripts/chapters/chapter4.gd")
const Model = preload("res://scripts/objects/room201_press_model.gd")
const ENTRY = "res://tests/fixtures/room201_projection_entry.json"
const FACT = "a2_positioning_plate_calibrated"
const MOVES = [{"kind":"insert"},{"kind":"step","axis":"horizontal","delta":-1},{"kind":"step","axis":"horizontal","delta":-1},{"kind":"step","axis":"vertical","delta":1},{"kind":"step","axis":"pressure","delta":1},{"kind":"step","axis":"pressure","delta":1},{"kind":"step","axis":"pressure","delta":1}]
var checks := 0
var failures := 0
var owner: Node
var controller: RefCounted
func _initialize() -> void: run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error(label)
func entry(collect: bool=true) -> Dictionary:
	var state: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(ENTRY)).state
	if collect: controller.dispatch(state,"c4_plate")
	controller.dispatch(state,"c4_device_positioning_calibration")
	return state
func move(state: Dictionary, event: Variant) -> Dictionary:
	return controller.dispatch(state,"c4_plate_press_event",event)
func prepare(state: Dictionary) -> void:
	for event: Dictionary in MOVES: move(state,event)
	check(Model.ready_to_press(state.native.get("c4_plate_press",{})),"Legal object moves reach the original registration")
	check(not FACT in state.chapter4.factIds,"Physical preparation alone never earns calibration")
func solve(state: Dictionary, value: Variant=null) -> Dictionary:
	return controller.dispatch(state,"c4_solve_positioning_calibration",Model.source().registration.calibration.duplicate() if value==null else value)
func stale(state: Dictionary, gate: String) -> void:
	match gate:
		"scene": state.native.scene="library_interior"
		"chapter": state.native.chapter=3
		"fractional": state.native.chapter=4.5
		"native_mode": state.native.mode="dark"
		"context": state.native.c4_context="power_topology"
		"phase": state.chapter4.phase="maintenance_repair"
		"floor": state.chapter4.floor="A1"
		"mode": state.chapter4.mode="dark"
		"time": state.chapter4.timeState="2245_opening"
		"plate": state.items.clockPositioningPlate=false
		"collection": state.chapter4.factIds.erase("positioning_plate_collected")
		"stairs": state.chapter4.factIds.erase("misaligned_stair_solved")
		"prologue": state.chapter4.prologueSeen=false
		_: state.native.erase(gate)
func run() -> void:
	owner=root.get_node("State");owner.developer_mode=false;controller=Chapter.new()
	check(owner.validate_snapshot(entry(false)),"Honest pre-plate fixture is a valid ordinary snapshot")
	test_gates(); test_payloads(); test_order_and_install(); test_saves()
	print("ROOM201_PRESS_AUTHORITY ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
func test_gates() -> void:
	var ready:=entry();prepare(ready)
	for gate: String in ["scene","chapter","fractional","native_mode","context","phase","floor","mode","time","plate","collection","stairs","prologue","mode","c4_context"]:
		for event: Dictionary in [{"kind":"step","axis":"horizontal","delta":1},{"kind":"reset"},{"kind":"insert"}]:
			var state: Dictionary=ready.duplicate(true);stale(state,gate)
			var before:=JSON.stringify(state);var result:=move(state,event)
			check(JSON.stringify(state)==before and not result.has("press_motion"),"Stale "+gate+" cannot mutate "+event.kind)
		var state: Dictionary=ready.duplicate(true);stale(state,gate)
		var before:=JSON.stringify(state);solve(state)
		check(JSON.stringify(state)==before,"Stale "+gate+" cannot calibrate")
	var unowned:=entry(false);var before:=JSON.stringify(unowned)
	move(unowned,{"kind":"insert"});solve(unowned)
	check(JSON.stringify(unowned)==before,"201 cannot fabricate or calibrate a plate before 204 collection")
	var unprepared:=entry();before=JSON.stringify(unprepared);solve(unprepared)
	check(JSON.stringify(unprepared)==before,"Exact numeric answer cannot skip physical insertion and adjustments")
	move(unprepared,{"kind":"insert"});before=JSON.stringify(unprepared)
	var bounced:=solve(unprepared)
	check(JSON.stringify(unprepared)==before and bounced.get("press_motion")=="rebound","Wrong press visibly rebounds without losing adjustments")
	for event: Dictionary in MOVES.slice(1):move(unprepared,event)
	solve(unprepared)
	check(FACT in unprepared.chapter4.factIds and unprepared.items.clockPositioningPlate and unprepared.native.c4_plate_press.imprinted,"Accepted press calibrates the existing owned plate")
	before=JSON.stringify(unprepared);solve(unprepared);move(unprepared,{"kind":"reset"})
	check(JSON.stringify(unprepared)==before,"Repeated successful press cannot duplicate fact or reset finished checkpoint")
func test_payloads() -> void:
	var state:=entry()
	for value: Variant in [null,[],false,0,"insert",{}, {"kind":"unknown"}, {"kind":"step","axis":"horizontal","delta":1},{"kind":"reset"}]:
		var before:=JSON.stringify(state);move(state,value)
		check(JSON.stringify(state)==before,"Malformed or premature press event cannot create checkpoint")
	move(state,{"kind":"insert"})
	for axis: String in Model.AXES:
		for value: Variant in [null,true,"1",0,2,0.5,INF,NAN]:
			var before:=JSON.stringify(state);move(state,{"kind":"step","axis":axis,"delta":value})
			check(JSON.stringify(state)==before,"Malformed step rejected for "+axis)
	for axis: String in Model.AXES:
		for iteration in range(12):move(state,{"kind":"step","axis":axis,"delta":-1})
		check(state.native.c4_plate_press.calibration[axis]==Model.source().ranges.positioning_calibration[axis][0],"Lower rail/spring bound "+axis)
		for iteration in range(12):move(state,{"kind":"step","axis":axis,"delta":1})
		check(state.native.c4_plate_press.calibration[axis]==Model.source().ranges.positioning_calibration[axis][1],"Upper rail/spring bound "+axis)
	move(state,{"kind":"reset"})
	check(state.native.c4_plate_press.inserted and state.native.c4_plate_press.calibration==Model.initial().calibration,"Reset preserves inserted plate and resets only controls")
	state=entry();prepare(state)
	for value: Variant in [{},[],false,{"horizontal":"-2","vertical":1,"pressure":3},{"horizontal":-2,"vertical":1,"pressure":true},{"horizontal":-2,"vertical":1,"pressure":3,"forced":true}]:
		var before:=JSON.stringify(state);solve(state,value)
		check(JSON.stringify(state)==before,"Final controller value must match the strict original numeric registration")
func test_order_and_install() -> void:
	var state:=entry(false)
	check(controller._room204_task(state.chapter4)=="collect_positioning_plate","Task order asks for the real plate before calibration")
	controller.dispatch(state,"c4_plate")
	check(controller._room204_task(state.chapter4)=="resolve_a2_inserted_puzzles","Collected plate opens the outstanding calibration objective")
	var before:=JSON.stringify(state);controller.dispatch(state,"c4_plate")
	check(JSON.stringify(state)==before,"Repeated drawer collection does not duplicate the plate")
	state.items.clockPositioningPlate=false;before=JSON.stringify(state);controller.dispatch(state,"c4_plate")
	check(JSON.stringify(state)==before,"Collection fact prevents a second award even after item removal")
	state=entry();prepare(state);solve(state)
	var open: Dictionary=controller.dispatch(state,"c4_elevator").open_c4_floor_selection
	var travel: Dictionary=controller.dispatch(state,"c4_floor_select",{"session":open.session,"destination":"A1"}).world_effect
	controller.dispatch(state,"c4_floor_arrived",{"session":travel.session,"elapsedMs":travel.durationMs,"boarded":true,"arrived":true,"fromFloor":"A2","destination":"A1"})
	check(state.chapter4.floor=="A1","Existing validated elevator returns the calibrated plate to A1")
	controller.dispatch(state,"c4_install_plate")
	check(state.chapter4.phase=="maintenance_repair" and not state.items.clockPositioningPlate and "positioning_plate_installed" in state.chapter4.factIds,"A1 installation consumes exactly the original plate")
	check(state.chapter4.timeState=="1850_evening","Installation does not silently advance the clock")
	check(controller.dispatch(state,"c4_clock").get("page")=="c4_device","Installed plate exposes the existing manual clock detent")
	controller.dispatch(state,"c4_clock_set",{"time":"2245_maintenance"})
	check(state.chapter4.timeState=="2245_maintenance" and owner.validate_snapshot(state),"Original validated 22:45 clock action remains reachable and persistable")
	before=JSON.stringify(state);controller.dispatch(state,"c4_install_plate")
	check(JSON.stringify(state)==before,"Repeated install cannot recreate or consume any extra item")
func test_saves() -> void:
	var legacy:=entry();check(owner.validate_snapshot(legacy) and not legacy.native.has("c4_plate_press"),"Old unfinished saves require no fabricated press checkpoint")
	owner.d=legacy.duplicate(true)
	owner.act("c4_plate_press_event",{"kind":"insert"})
	owner.act("c4_plate_press_event",{"kind":"step","axis":"horizontal","delta":-1})
	var expected: Dictionary=owner.d.native.c4_plate_press.duplicate(true)
	check(owner.save_game(),"Partial press saves through actual State writer")
	owner.d=owner.initial();check(owner.load_game(),"Partial press reloads through actual State reader")
	check(Model.canonical(owner.d.native.get("c4_plate_press",{}))==Model.canonical(expected) and not FACT in owner.d.chapter4.factIds,"Reload retains partial rail position without granting completion")
	legacy.chapter4.factIds.append(FACT)
	check(owner.validate_snapshot(legacy),"Old completed calibration remains valid without new object checkpoint")
	var before:=JSON.stringify(legacy);solve(legacy);move(legacy,{"kind":"reset"})
	check(JSON.stringify(legacy)==before,"Old completed calibration remains read-only without invented press history")
	var illegal: Array=[null,false,1,"press",[],{},Model.initial()]
	illegal[-1].extra=true
	for key: String in ["version","inserted","calibration","imprinted"]:
		var bad:=Model.initial();bad.erase(key);illegal.append(bad)
	for axis: String in Model.AXES:
		for value: Variant in [-99,99,0.5,"1",true,null,INF,NAN]:
			var bad:=Model.initial();bad.inserted=true;bad.calibration[axis]=value;illegal.append(bad)
	for key: String in ["inserted","imprinted"]:
		for value: Variant in [0,1,"true",null]:
			var bad:=Model.initial();bad[key]=value;illegal.append(bad)
	var impossible:=Model.initial();impossible.imprinted=true;illegal.append(impossible)
	for checkpoint: Variant in illegal:
		var state:=entry();state.native.c4_plate_press=checkpoint
		check(not owner.validate_snapshot(state),"Malformed present press checkpoint rejects whole snapshot")
		before=JSON.stringify(state);move(state,{"kind":"insert"});solve(state)
		check(JSON.stringify(state)==before,"Malformed checkpoint cannot be repaired into earned progress")
	var saved_bytes:=FileAccess.get_file_as_string(owner.SAVE_PATH)
	owner.d.native.c4_plate_press=null
	check(not owner.save_game() and FileAccess.get_file_as_string(owner.SAVE_PATH)==saved_bytes,"Invalid checkpoint cannot overwrite last valid ordinary save")
