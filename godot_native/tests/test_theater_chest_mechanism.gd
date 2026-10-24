extends SceneTree
const Chapter=preload("res://scripts/chapters/chapter3.gd")
const Model=preload("res://scripts/games/theater_chest_mechanism.gd")
var checks:=0
var failures:=0
var state: Node
func _initialize() -> void:run.call_deferred()
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error("THEATER_CHEST_STORY: "+label)
func initial(opened:=true) -> Dictionary:
	var s: Dictionary=state.initial()
	s.native.merge({"chapter":3,"scene":"theater_interior","page":"c3_theater","mode":"light","player":{"scene":"theater_interior","x":294,"y":228}},true)
	s.runtimeMode="rpg";s.rpgScene="theater_interior";s.rpgCheckpoint="theater_stage"
	s.actOne.phase="complete";s.actOne.movementEnabled=true
	s.theaterHunt.merge({"active":true,"admitted":true,"phase":"prop_setup","mode":"light","propBoxOpened":opened},true)
	s.items.spotlightRemote=true;s.items.temporaryTheaterTicket=not opened
	if opened:s.native.theater_chest=Model.fresh()
	return s
func begin(chapter: RefCounted,s: Dictionary) -> Dictionary:
	var result: Dictionary=chapter.dispatch(s,"c3_chest_begin")
	check(result.get("accepted",false),"box issues scoped inspection")
	return result.get("mechanism",{})
func act(chapter: RefCounted,s: Dictionary,token: Dictionary,action: String,extra: Dictionary={}) -> Dictionary:
	var payload:=extra.duplicate(true);payload.session=token.duplicate(true)
	return chapter.dispatch(s,"c3_chest_"+action,payload)
func move_to(chapter: RefCounted,s: Dictionary,id: String) -> void:
	var target: Dictionary=chapter.get_definition("theater_interior",id,s)
	s.native.player=target.get("stand",{"x":target.x,"y":target.y}).duplicate()
func assemble(chapter: RefCounted,s: Dictionary,token: Dictionary) -> void:
	for piece: String in Model.CLEAR_ORDER:
		check(act(chapter,s,token,"clear",{"piece":piece}).accepted,"move stacked "+piece)
	check(act(chapter,s,token,"inspect").mechanism.clue_open,"uncovered paper opens")
	act(chapter,s,token,"inspect")
	var before:=s.duplicate(true)
	check(not act(chapter,s,token,"place",{"piece":"fan","slot":0}).accepted and s==before,"mismatched keyway does not accept or move token")
	for index: int in range(3):check(act(chapter,s,token,"place",{"piece":Model.ASSEMBLY[index],"slot":index}).accepted,"fit matching socket %d"%index)
	check(act(chapter,s,token,"place",{"piece":"crank","slot":"axle"}).accepted,"mount handle")
	check(not act(chapter,s,token,"open").accepted,"installed handle alone cannot open hatch")
	check(not act(chapter,s,token,"turn",{"direction":-1}).accepted,"cam stop rejects reverse turn")
	var result:=act(chapter,s,token,"turn",{"direction":1})
	check(result.accepted and result.mechanism.latch_released and result.mechanism.slots==Model.SOLUTION,"real turn retracts latch")
	check(act(chapter,s,token,"open").accepted,"player pulls released hatch")

func run() -> void:
	if not load("res://tests/native_test_isolation.gd").is_isolated_save():quit(2);return
	state=root.get_node("State");state.developer_mode=false
	create_timer(45).timeout.connect(func():push_error("Chest story watchdog");quit(2))
	var chapter:=Chapter.new();var s:=initial(false)
	move_to(chapter,s,"theater_prop_scanner")
	check(not chapter.can_operate(s,"theater_interior","theater_prop_box"),"scanner's authored stand is outside box radius")
	chapter.dispatch(s,"c3_target:theater_prop_scanner")
	check(s.theaterHunt.propBoxOpened and not s.items.fluorescentBrush and not s.items.temporaryTheaterTicket,"scan consumes ticket and unlocks outer box only")
	check(state.validate_snapshot(s),"new scanner checkpoint validates")
	var token: Dictionary=begin(chapter,s).session
	check(not act(chapter,s,token,"open").accepted and not act(chapter,s,token,"take").accepted,"locked compartment cannot yield brush")
	check(not act(chapter,s,token,"inspect").accepted,"buried paper cannot be inspected")
	check(not act(chapter,s,token,"clear",{"piece":"lamp"}).accepted,"covered bottom token cannot jump through stack")
	move_to(chapter,s,"theater_backstage_vent")
	chapter.dispatch(s,"c3_target:theater_backstage_vent")
	check(not s.theaterHunt.paperDusted and s.theaterHunt.phase=="prop_setup","vent cannot bypass physical pickup")
	move_to(chapter,s,"theater_prop_box");token=begin(chapter,s).session
	for invalid: Dictionary in [{"piece":"fan","slot":true},{"piece":"fan","slot":1.5},{"piece":"crank","slot":0},{"piece":"other","slot":0},{"piece":"fan","slot":-1}]:
		check(not act(chapter,s,token,"place",invalid).accepted,"malformed placement rejected")
	assemble(chapter,s,token)
	check(not s.items.fluorescentBrush,"opening compartment still requires picking up brush")
	check(act(chapter,s,token,"clue").accepted and s.native.theater_chest.vent_clue_seen,"vent sketch records inspection")
	check(act(chapter,s,token,"take").accepted and s.items.fluorescentBrush,"physical pickup grants original brush")
	var before:=s.duplicate(true)
	check(not act(chapter,s,token,"take").accepted and s==before,"duplicate pickup cannot award again")
	check(act(chapter,s,token,"cancel").cancelled,"close retires exact nonce")
	var reopened:=begin(chapter,s)
	check(reopened.drawer_open and reopened.brush_taken and reopened.slots==Model.SOLUTION and reopened.session!=token,"reopen preserves all earned work under a new session")
	check(not act(chapter,s,token,"take").accepted,"retired session cannot act")
	var forged: Dictionary=reopened.session.duplicate();forged.nonce="forged"
	check(not act(chapter,s,forged,"clue").accepted,"forged capability rejected")
	move_to(chapter,s,"theater_backstage_vent");chapter.dispatch(s,"c3_target:theater_backstage_vent")
	check(s.theaterHunt.paperDusted and s.theaterHunt.phase=="spotlight_ready" and not s.items.fluorescentBrush,"original vent consumes brush and unlocks spotlight")
	move_to(chapter,s,"theater_prop_box");reopened=begin(chapter,s)
	check(reopened.brush_taken and reopened.drawer_open and not act(chapter,s,reopened.session,"take").accepted,"spent brush stays absent on later inspection")
	check(state.validate_snapshot(s),"post-vent checkpoint validates")
	move_to(chapter,s,"theater_light_console");chapter.dispatch(s,"c3_target:theater_light_console")
	check(s.theaterHunt.phase=="spotlight_hunt" and not s.items.spotlightRemote,"original console starts authored spotlight game")
	for fault: String in ["distance","dark","unadmitted","inactive","closed","phase","runtime","scene","checkpoint","owner"]:
		s=initial();token=begin(chapter,s).session
		match fault:
			"distance":s.native.player.x=1500
			"dark":s.native.mode="dark"
			"unadmitted":s.theaterHunt.admitted=false
			"inactive":s.theaterHunt.active=false
			"closed":s.theaterHunt.propBoxOpened=false
			"phase":s.theaterHunt.phase="spotlight_ready"
			"runtime":s.runtimeMode="phone"
			"scene":s.native.scene="qizhen_lake"
			"checkpoint":s.rpgCheckpoint="elsewhere"
			"owner":s=s.duplicate(true)
		before=s.duplicate(true)
		check(not act(chapter,s,token,"clear",{"piece":"butterfly"}).accepted and s==before,"stale context rejects "+fault)
	await persistence()
	print("THEATER_CHEST_STORY: %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)

func persistence() -> void:
	state.d=initial();state.modules[1]=Chapter.new()
	var token: Dictionary=state.act("c3_chest_begin").mechanism.session
	var before: Dictionary=state.d.duplicate(true)
	state.act("c3_chest_inspect",{"session":token})
	check(state.d==before,"rejected observation does not write save or log")
	state.act("c3_chest_clear",{"session":token,"piece":"butterfly"})
	check(FileAccess.file_exists(state.SAVE_PATH),"actual persistent action autosaves")
	var saved: Dictionary=state.d.native.theater_chest.duplicate(true)
	check(not JSON.stringify(saved).contains("nonce"),"runtime capability never enters save")
	var disk: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(state.SAVE_PATH)).state
	check(Model.valid(disk),"serialized mechanism validates")
	check(state.validate_snapshot(disk),"serialized full snapshot validates")
	if not state.validate_snapshot(disk):print("CHEST_SAVE_DIAGNOSTIC model=",Model.valid(disk)," shape=",state._matches_shape(state.initial(),disk)," domain=",state._domain_guard.validate(disk))
	state.d=state.initial();check(state.load_game(),"ordinary Continue loads disk save")
	if not state.d.native.has("theater_chest"):return
	check(state.d.native.theater_chest==JSON.parse_string(JSON.stringify(saved)) and not state.d.items.fluorescentBrush,"partial pile survives disk reload without reward")
	var resumed:=begin(state.modules[1],state.d)
	check(resumed.cleared==["butterfly"] and resumed.session!=token,"reload resumes already moved piece")
	assemble(state.modules[1],state.d,resumed.session)
	check(state.export_save("user://chest-story.json")==OK,"uncollected open compartment exports")
	state.d=state.initial()
	check(state.import_save("user://chest-story.json").ok,"native import accepts persistent compartment")
	check(state.d.native.theater_chest.drawer_open and not state.d.native.theater_chest.brush_taken and not state.d.items.fluorescentBrush,"native import retains uncollected physical reward")
	token=begin(state.modules[1],state.d).session
	state.act("c3_chest_take",{"session":token})
	check(state.load_game() and state.d.items.fluorescentBrush and state.d.native.theater_chest.brush_taken,"pickup survives ordinary Continue")
	var good: Dictionary=state.d.duplicate(true)
	for field: String in ["slots","cleared","turns","brush_taken","drawer_open","version","extra"]:
		var bad: Dictionary=good.duplicate(true)
		match field:
			"slots":bad.native.theater_chest.slots=["fan","fan","lamp"]
			"cleared":bad.native.theater_chest.cleared=["fan"]
			"turns":bad.native.theater_chest.turns=0
			"brush_taken":bad.native.theater_chest.brush_taken=false
			"drawer_open":bad.native.theater_chest.drawer_open=false
			"version":bad.native.theater_chest.version=true
			"extra":bad.native.theater_chest.nonce="unbounded"
		check(not state.validate_snapshot(bad),"save rejects inconsistent "+field)
	for spent: bool in [false,true]:
		var legacy:=initial();legacy.native.erase("theater_chest");legacy.items.fluorescentBrush=not spent
		legacy.theaterHunt.paperDusted=spent;legacy.theaterHunt.phase="spotlight_ready" if spent else "prop_setup"
		state.d=legacy
		check(state.save_game() and state.load_game(),"legacy native save loads")
		check(state.d.native.theater_chest.legacy and state.d.native.theater_chest.brush_taken and state.d.items.fluorescentBrush==not spent,"legacy owned/spent reward retained without redoing mechanism")
		var file:=FileAccess.open("user://chest-browser.json",FileAccess.WRITE)
		legacy.erase("native");file.store_string(JSON.stringify({"version":36,"state":legacy}));file.close()
		check(state.import_save("user://chest-browser.json").ok,"legacy browser save imports")
		check(state.d.native.theater_chest.legacy and state.d.items.fluorescentBrush==not spent,"browser migration preserves owned/spent brush")
	await process_frame
