extends SceneTree
const Chapter=preload("res://scripts/chapters/chapter4.gd")
const Lake=preload("res://scripts/chapters/c3_lake.gd")
const Proof=preload("res://tests/helpers/progressive_transport_proof.gd")
const Model=preload("res://scripts/games/progressive_transport_model.gd")
const Metrics=preload("res://scripts/player_metrics.gd")
var checks:=0
var failures:=0

func _initialize() -> void: run.call_deferred()
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures+=1;push_error("PROGRESSIVE_CONTROLLER: "+label)
func initial() -> Dictionary:
	var s: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/initial_state.json"))
	s.native={"chapter":4,"scene":Chapter.SCENE,"page":"c4_notes","mode":"light","player":{},"settings":{},"log":[],"completed":[]}
	s.runtimeMode="rpg";s.rpgScene=Chapter.SCENE
	s.chapter4.merge({"prologueSeen":true,"phase":"room204_restore","floor":"A2","roomId":"a2_corridor","timeState":"1850_evening","mode":"light"},true)
	return s
func c4_state(id: String) -> Dictionary:
	var s:=initial();s.native.c4_context=id;return s
func lake_state(phase: String="dock_outfitting") -> Dictionary:
	var s:=initial();s.native.chapter=3;s.native.scene="qizhen_lake";s.rpgScene="qizhen_lake";s.native.page="c3_lake"
	s.chapter4=JSON.parse_string(FileAccess.get_file_as_string("res://data/initial_state.json")).chapter4
	s.native.player={"scene":"qizhen_lake","x":590,"y":870}
	s.qizhenLake.merge({"active":true,"phase":phase,"zone":"dock","vehicle":"on_foot","mode":"light","safeSpawnId":"dock_entry"},true)
	s.rpgCheckpoint="qizhen_dock"
	return s
func issue(c: RefCounted,s: Dictionary,id: String) -> Dictionary:
	var request: Dictionary=c.dispatch(s,"c4_device_"+id)
	check(request.has("game") and not request.has("page"),id+" opens one activity without old panel")
	return request.get("game",{})
func lake_issue(c: RefCounted,s: Dictionary) -> Dictionary:
	var request: Dictionary=c.dispatch(s,"c3_lake_target:qizhen_dock_logistics")
	check(request.has("game") and not request.has("scene") and not request.has("page"),"Dock physical object opens local activity without routing")
	return request.get("game",{})

func test_c4(id: String) -> void:
	var c:=Chapter.new();var s:=c4_state(id);var before:=JSON.stringify(s)
	var config:=issue(c,s,id)
	check(JSON.stringify(s)==before,id+" opening never writes progress, items or wallet")
	var valid:=Proof.proof(config)
	check(not valid.is_empty(),id+" three stages produce legal input proof")
	var replay: Dictionary=Model.replay(id,valid.get("actions",[]))
	check(replay.get("valid",false) and replay.get("completed",false) and c._puzzle_correct(id,replay.get("controllerValue",{})),id+" derived value preserves exact retained source oracle")
	var forged: Dictionary=replay.get("controllerValue",{}).duplicate(true)
	c.dispatch(s,"c4_solve_"+id,forged)
	check(JSON.stringify(s)==before,id+" a correct final answer alone cannot write the original fact")
	for fault: String in ["no_trace","partial","digest","id","nonce","oversize","unknown","final_value"]:
		config=issue(c,s,id);var value:=Proof.proof(config)
		match fault:
			"no_trace": value.actions=[]
			"partial": value.actions.pop_back()
			"digest": value.layoutDigest="forged"
			"id": value.puzzleId="lake_logistics"
			"nonce": value.session.nonce="forged"
			"oversize": value.actions=[];value.actions.resize(4097);value.actions.fill("right")
			"unknown": value.actions=["finish"]
			"final_value": value.controllerValue=forged
		c.dispatch(s,"c4_puzzle_trace",value)
		check(JSON.stringify(s)==before,id+" rejects "+fault+" without state writes")
	for gate: String in ["phase","floor","room","time","mode","native_mode","scene","runtime","world_scene","context","new_state"]:
		s=c4_state(id);config=issue(c,s,id);var value:=Proof.proof(config)
		match gate:
			"phase": s.chapter4.phase="maintenance_repair"
			"floor": s.chapter4.floor="A3"
			"room": s.chapter4.roomId="a2_room204"
			"time": s.chapter4.timeState="0755_morning"
			"mode": s.chapter4.mode="dark"
			"native_mode": s.native.mode="dark"
			"scene": s.native.scene="dorm_hub"
			"runtime": s.runtimeMode="phone"
			"world_scene": s.rpgScene="dorm_hub"
			"context": s.native.c4_context="positioning_calibration"
			"new_state": s=s.duplicate(true)
		before=JSON.stringify(s);c.dispatch(s,"c4_puzzle_trace",value)
		check(JSON.stringify(s)==before,id+" rejects stale "+gate)
	s=c4_state(id);var first:=issue(c,s,id);var second:=issue(c,s,id)
	c.dispatch(s,"c4_puzzle_cancel",{"session":first.session})
	check(c.progressive_session==second.session,id+" old cancel does not retire newer nonce")
	c.dispatch(s,"c4_puzzle_trace",Proof.proof(first))
	check(not s.chapter4.factIds.has(c.extra.puzzles[id].factId),id+" old nonce cannot finish new activity")
	c.dispatch(s,"c4_puzzle_cancel",{"session":second.session})
	c.dispatch(s,"c4_puzzle_trace",Proof.proof(second))
	check(not s.chapter4.factIds.has(c.extra.puzzles[id].factId),id+" cancelled nonce cannot finish")
	config=issue(c,s,id);c.invalidate_progressive_session();s.native.mode="dark";s.chapter4.mode="dark";s.native.mode="light";s.chapter4.mode="light"
	c.dispatch(s,"c4_puzzle_trace",Proof.proof(config))
	check(not s.chapter4.factIds.has(c.extra.puzzles[id].factId),id+" mode invalidation prevents dark-light nonce revival")
	config=issue(c,s,id);valid=Proof.proof(config)
	var fresh:=Chapter.new();fresh.dispatch(s,"c4_puzzle_trace",valid)
	check(not s.chapter4.factIds.has(c.extra.puzzles[id].factId),id+" fresh controller/reload rejects old capability")
	c.dispatch(s,"c4_puzzle_trace",valid)
	check(s.chapter4.factIds.has(c.extra.puzzles[id].factId),id+" legal replay awards exactly the original fact")
	before=JSON.stringify(s);c.dispatch(s,"c4_puzzle_trace",valid)
	check(JSON.stringify(s)==before,id+" duplicate callback is one-shot")
	var readonly: Dictionary=c.dispatch(s,"c4_device_"+id)
	check(not readonly.has("game") and readonly.get("page")=="c4_device" and s.chapter4.factIds.has(c.extra.puzzles[id].factId),id+" completed old save opens read-only without regression")
	s=c4_state(id);s.chapter4.mode="dark";s.native.mode="dark";readonly=c.dispatch(s,"c4_device_"+id)
	check(not readonly.has("game") and readonly.get("page")=="c4_device",id+" dark observation remains accessible without light prerequisite")

func test_lake() -> void:
	var c:=Lake.new();var s:=lake_state();var before:=JSON.stringify(s)
	var target: Dictionary={}
	for entry: Dictionary in c.targets("qizhen_lake",s):
		if entry.id=="qizhen_dock_logistics": target=entry
	check(not target.is_empty() and target.action=="c3_lake_target:qizhen_dock_logistics" and target.has("art"),"Real dock object uses shared world interaction route")
	check(ResourceLoader.exists(str(target.get("art",""))),"Dock object has a visible independent asset")
	var dock: Dictionary=c.world("qizhen_lake").zones.dock
	var spawn:=Vector2(dock.onFootSpawn.x,dock.onFootSpawn.y)
	var clear:=true
	for step in range(21):
		var foot:=Metrics.foot_rect(spawn.lerp(Vector2(590,870),step/20.0))
		for rectangle: Dictionary in dock.onFootCollisions:
			if foot.intersects(Rect2(rectangle.left,rectangle.top,rectangle.right-rectangle.left,rectangle.bottom-rectangle.top)): clear=false
	check(clear,"Ordinary on-foot spawn reaches entry entirely on authored land with unchanged collision")
	for phase: String in c.LOGISTICS_PHASES:
		s=lake_state(phase);before=JSON.stringify(s);var config:=lake_issue(c,s)
		check(JSON.stringify(s)==before,"Opening optional activity preserves entire "+phase+" save state")
		var result: Dictionary=c.dispatch(s,"c3_lake_logistics_result",Proof.proof(config))
		check(result.get("accepted",false) and JSON.stringify(s)==before,"Successful local trace changes no lake/item/quest/checkpoint/wallet fields in "+phase)
		result=c.dispatch(s,"c3_lake_logistics_result",Proof.proof(config))
		check(not result.get("accepted",false) and JSON.stringify(s)==before,"Duplicate local finish is rejected without rewards")
	s=lake_state();var config:=lake_issue(c,s);before=JSON.stringify(s)
	var value:=Proof.proof(config);value.actions.pop_back()
	check(not c.dispatch(s,"c3_lake_logistics_result",value).get("accepted",false) and JSON.stringify(s)==before,"Partial local recovery cannot finish")
	var first:=lake_issue(c,s);var second:=lake_issue(c,s)
	c.dispatch(s,"c3_lake_logistics_cancel",{"session":first.session})
	check(c.logistics_session==second.session,"Old dock cancellation cannot retire a newer game")
	c.dispatch(s,"c3_lake_logistics_cancel",{"session":second.session})
	check(not c.dispatch(s,"c3_lake_logistics_result",Proof.proof(second)).get("accepted",false) and JSON.stringify(s)==before,"Cancel is story-neutral and invalidates completion")
	config=lake_issue(c,s);c.invalidate_logistics_session();s.native.mode="dark";s.native.mode="light"
	check(not c.dispatch(s,"c3_lake_logistics_result",Proof.proof(config)).get("accepted",false),"Dock mode toggle invalidates old nonce permanently")
	config=lake_issue(c,s);var reloaded: Dictionary=s.duplicate(true)
	check(not c.dispatch(reloaded,"c3_lake_logistics_result",Proof.proof(config)).get("accepted",false),"Reloaded state cannot restore runtime-only dock session")
	for gate: String in ["distance","dark","kayak","zone","complete","chase","rain","phone","scene"]:
		s=lake_state()
		match gate:
			"distance": s.native.player={"scene":"qizhen_lake","x":100,"y":100}
			"dark": s.native.mode="dark";s.qizhenLake.mode="dark"
			"kayak": s.qizhenLake.vehicle="kayak"
			"zone": s.qizhenLake.zone="open_water"
			"complete": s.qizhenLake.phase="complete"
			"chase": s.qizhenLake.phase="swan_chase"
			"rain": s.qizhenLake.phase="rain_recovery"
			"phone": s.runtimeMode="phone"
			"scene": s.native.scene="dorm_hub"
		before=JSON.stringify(s);var result: Dictionary=c.dispatch(s,"c3_lake_target:qizhen_dock_logistics")
		check(not result.has("game") and JSON.stringify(s)==before,"Dock entry rejects "+gate+" without writes")
		if gate=="dark": check(c.targets("qizhen_lake",s).any(func(t: Dictionary) -> bool: return t.id=="qizhen_dock_logistics"),"Dark target remains visible with readable mode feedback")

func run() -> void:
	if not load("res://tests/native_test_isolation.gd").is_isolated_save():
		push_error("Progressive controller checks require an isolated test user directory")
		quit(2);return
	for id: String in ["power_topology","evacuation_route"]: test_c4(id)
	test_lake()
	test_state_mode_invalidation()
	test_cancel_under_narrative_lock()
	print("PROGRESSIVE_TRANSPORT_CONTROLLER %d checks; %d failures"%[checks,failures])
	quit(1 if failures else 0)

func test_state_mode_invalidation() -> void:
	var state: Node=root.get_node("State")
	var previous: Dictionary=state.d
	state.d=c4_state("power_topology")
	var opened: Dictionary=state.act("c4_device_power_topology")
	check(opened.has("game"),"Ordinary State issues the physical device session")
	if opened.has("game"):
		var value:=Proof.proof(opened.game)
		state.toggle_mode();state.toggle_mode()
		state.act("c4_puzzle_trace",value)
		check(not state.d.chapter4.factIds.has("a2_power_topology_recovered"),"Actual State dark-light toggles cannot revive device nonce")
	state.d=lake_state()
	opened=state.act("c3_lake_target:qizhen_dock_logistics")
	check(opened.has("game"),"Ordinary State issues the physical dock session")
	if opened.has("game"):
		var value:=Proof.proof(opened.game)
		var prior_lake: Dictionary=state.d.qizhenLake.duplicate(true)
		state.toggle_mode();state.toggle_mode()
		var result: Dictionary=state.act("c3_lake_logistics_result",value)
		check(not result.get("accepted",false) and state.d.qizhenLake==prior_lake,"Actual State dock toggle invalidates nonce without changing lake progression")
	for surface: String in ["page","scene"]:
		state.d=c4_state("evacuation_route")
		opened=state.act("c4_device_evacuation_route")
		check(opened.has("game"),"State device issued before "+surface+" round trip")
		if opened.has("game"):
			var value:=Proof.proof(opened.game)
			if surface=="page":state.open_page("phone_home");state.open_page("c4_device")
			else:state.open_scene("dorm_hub");state.open_scene(Chapter.SCENE)
			state.act("c4_puzzle_trace",value)
			check(not state.d.chapter4.factIds.has("a2_evacuation_route_confirmed"),"Actual State device "+surface+" leave-return cannot revive nonce")
		state.d=lake_state()
		opened=state.act("c3_lake_target:qizhen_dock_logistics")
		check(opened.has("game"),"State dock issued before "+surface+" round trip")
		if opened.has("game"):
			var value:=Proof.proof(opened.game);var prior_lake: Dictionary=state.d.qizhenLake.duplicate(true)
			if surface=="page":state.open_page("phone_home");state.open_page("c3_lake")
			else:state.open_scene("dorm_hub");state.open_scene("qizhen_lake")
			var result: Dictionary=state.act("c3_lake_logistics_result",value)
			check(not result.get("accepted",false) and state.d.qizhenLake==prior_lake,"Actual State dock "+surface+" leave-return cannot revive nonce")
	state.d=previous

func test_cancel_under_narrative_lock() -> void:
	var state: Node=root.get_node("State");var previous: Dictionary=state.d
	# Unit dictionaries above deliberately isolate domain guards. Durable bytes
	# need a complete legitimate source fixture, not that reduced unit setup.
	check(state.begin_checkpoint("c3-qizhen-dock"),"Ordinary source dock fixture exists for durable cancellation")
	state.developer_mode=false
	state.d.native.player={"scene":"qizhen_lake","x":590,"y":870}
	var opened: Dictionary=state.act("c3_lake_target:qizhen_dock_logistics")
	if not check_return(opened.has("game"),"Ordinary dock session exists for locked cancellation"):state.d=previous;return
	check(state.save_game(),"Locked cancellation starts with an ordinary valid file")
	var chapter3: RefCounted
	for module: RefCounted in state.modules:
		if module.has_method("tell_lines"):chapter3=module
	# A concurrent runtime-only queue fixture proves cancellation bypasses the
	# ordinary intent lock; it adds no authored story or save fields.
	chapter3.tell_lines(state.d,"cancel-lock-fixture",["只读叙事锁测试。"])
	check(state.story_input_locked(),"Concurrent runtime narrative really holds the ordinary intent lock")
	var before:=JSON.stringify(state.d);var bytes:=FileAccess.get_file_as_string(state.SAVE_PATH)
	var value: Dictionary={"session":opened.game.session,"puzzleId":"lake_logistics"}
	check(not state.cancel_progressive_activity("c3_lake_logistics_cancel",{"session":{"nonce":"forged"}}),"Wrong nonce cannot use ephemeral cancellation")
	check(state.cancel_progressive_activity("c3_lake_logistics_cancel",value),"Exact runtime cancellation succeeds while narrative is locked")
	check(not state.cancel_progressive_activity("c3_lake_logistics_cancel",value),"Repeated ephemeral cancellation is rejected")
	check(not state.cancel_progressive_activity("c3_fishing_result",value),"Ephemeral API cannot dispatch another domain intent")
	check(JSON.stringify(state.d)==before and FileAccess.get_file_as_string(state.SAVE_PATH)==bytes,"Locked cancellation changes no state or durable save bytes")
	chapter3.story.cancel();chapter3.story=null;chapter3.story_request={}
	check(not state.act("c3_lake_logistics_result",Proof.proof(opened.game)).get("accepted",false),"Narrative release cannot revive cancelled dock nonce")
	state.d=previous

func check_return(ok: bool,label: String) -> bool:
	check(ok,label);return ok
