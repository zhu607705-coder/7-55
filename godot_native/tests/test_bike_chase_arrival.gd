extends SceneTree
const Chapter=preload("res://scripts/chapters/chapter3.gd")
var checks:=0
var failures:=0
var state: Node
var teleports: Array=[]
var saved_before_teleport:=false
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures+=1;push_error(label)
func _initialize() -> void: call_deferred("run")
func fixture() -> Dictionary:
	var s: Dictionary=state.initial()
	s.native.chapter=3;s.native.scene="campus_bootstrap";s.native.page="c3_canteen"
	s.runtimeMode="rpg";s.rpgScene="campus_bootstrap";s.rpgCheckpoint="campus_canteen_bike"
	s.canteenHunt.active=true;s.canteenHunt.phase="chasing";s.canteenHunt.bikePaid=true
	s.native.player={"x":3220.0,"y":650.0,"world_x":3220.0,"world_y":650.0,"scene":"campus_bootstrap"}
	s.native.positions={"campus_bootstrap:":{"x":3220.0,"y":650.0},"theater_interior:":{"x":900.0,"y":750.0}}
	return s
func run() -> void:
	state=root.get_node("State");state.developer_mode=false
	var controller:=Chapter.new()
	var source: Dictionary=controller.world("campus_bootstrap").manifest.theater.approach
	var expected: Array=[float(source.x),float(source.y)]
	check(expected==[3300.0,1360.0],"the source theater approach is the arrival authority")
	var proof: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/chase.json"))
	for bad: Dictionary in [{"mode":"story","distance":755,"lives":3,"collisions":0},{"mode":"story","distance":400,"lives":2,"collisions":0},{"mode":"story","distance":400,"lives":0,"collisions":3}]:
		var s:=fixture();var before: Dictionary=s.native.duplicate(true)
		var result: Dictionary=controller.dispatch(s,"c3_chase_result",bad)
		check(not result.has("teleport") and not result.get("chase_arrival",false),"forged/incomplete/lost rides never request arrival")
		check(s.native.player==before.player and s.native.positions==before.positions,"rejected or failed ride preserves every position")
		check(not s.canteenHunt.chaseCompleted,"rejected or failed ride cannot complete the chase")
	state.d=fixture();var before: Dictionary=state.d.duplicate(true)
	var result: Dictionary=controller.dispatch(state.d,"c3_chase_result",proof)
	check(state.d.canteenHunt.chaseCompleted and state.d.canteenHunt.phase=="theater_reached","existing replay proof still owns terminal success")
	check(result.get("teleport",[])==expected and result.get("chase_arrival",false),"validated success alone returns explicit arrival marker")
	check(state.d.native.positions["campus_bootstrap:"]==source,"saved campus position changes before publication")
	check(state.d.native.player.x==source.x and state.d.native.player.y==source.y,"source interaction position matches arrival")
	check(state.d.native.player.get("world_x")==source.x and state.d.native.player.get("world_y")==source.y,"native world position matches arrival")
	check(state.d.native.positions["theater_interior:"]==before.native.positions["theater_interior:"],"unrelated stored room position is preserved")
	check(state.d.items==before.items and state.d.wallet==before.wallet,"arrival does not mint or consume items or cash")
	check(state.d.rpgCheckpoint=="campus_theater_junction" and state.d.native.scene=="campus_bootstrap","arrival retains the authored scene/checkpoint")
	check(state.d.canteenHunt.chaseAttemptCount==1,"accepted proof counts exactly one attempt")
	state.world_teleport.connect(func(point: Array):
		teleports.append(point.duplicate())
		var envelope=JSON.parse_string(FileAccess.get_file_as_string(state.SAVE_PATH))
		saved_before_teleport=envelope is Dictionary and envelope.get("state",{}).get("native",{}).get("positions",{}).get("campus_bootstrap:",{})==source and envelope.get("state",{}).get("canteenHunt",{}).get("chaseCompleted",false)
	)
	state._accept_result("c3_chase_result",before,result)
	check(teleports==[expected],"existing live-world teleport signal is emitted once")
	check(saved_before_teleport,"earned result and arrival are saved before optional presentation or teleport consumers")
	check(state.load_game(),"ordinary save reader accepts the complete arrival")
	check(state.d.native.positions["campus_bootstrap:"]==source and state.d.native.player.x==source.x and state.d.native.player.y==source.y,"ordinary reload cannot restore the previous bike position")
	var accepted: Dictionary=state.d.duplicate(true)
	var duplicate: Dictionary=controller.dispatch(state.d,"c3_chase_result",proof)
	check(not duplicate.has("teleport") and not duplicate.get("chase_arrival",false) and state.d==accepted,"duplicate terminal callback cannot relocate or grant again")
	print("BIKE_CHASE_ARRIVAL: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
