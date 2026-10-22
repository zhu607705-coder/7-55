extends SceneTree
## Domain, ordinary UI wiring and file migration checks. Not WASM acceptance.
const Chapter=preload("res://scripts/chapters/chapter1_2.gd")
const Access=preload("res://scripts/chapters/tiyi_access.gd")
const Pages=preload("res://scripts/ui/phone_pages.gd")
const PROOF={"failed":false,"points":10,"distanceMeters":3000,"elapsedSeconds":600}
var checks=0
var failures=0
var state: Node
var controller: RefCounted
var s: Dictionary
var pages: RefCounted
var page: Control

func _initialize() -> void: run.call_deferred()
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error("TIYI UPDATE: "+label)
func fresh() -> void:
	s=state.initial(); controller=Chapter.new()
	s.native.page="phone_home"; s.native.chapter=2
	s.actOne.phase="movement_required"; s.actOne.characterNamed=true
	s.networkMode="cellular"
func act(id: String,value: Variant=null) -> Dictionary: return controller.dispatch(s,id,value)
func frames(count: int=3) -> void:
	for i in range(count): await process_frame
func render() -> void:
	if is_instance_valid(page): page.free()
	pages.entry_session=controller.phone_entry_session(s)
	page=pages.build("wechat",controller.view("wechat",s),s)
	root.add_child(page)
	await frames()
func click(id: String) -> void:
	var target: Control=page.find_child(id,true,false)
	check(target!=null,"ordinary UI target "+id)
	if target==null: return
	var point=target.get_global_transform_with_canvas()* (target.size/2)
	var motion=InputEventMouseMotion.new(); motion.position=point; root.push_input(motion,true)
	await frames(1)
	for down in [true,false]:
		var event=InputEventMouseButton.new(); event.position=point; event.button_index=MOUSE_BUTTON_LEFT; event.pressed=down
		root.push_input(event,true); await frames(1)
	await render()
func import_snapshot(snapshot: Dictionary,version: Variant) -> Dictionary:
	var file=FileAccess.open("user://tiyi-update-import.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"format":"7-55-godot-native","version":1,"sourceVersion":version,"state":snapshot})); file.close()
	return state.import_save("user://tiyi-update-import.json")

func run() -> void:
	if not load("res://tests/native_test_isolation.gd").is_isolated_save():
		push_error("Tiyi update persistence checks require isolated user data"); quit(2); return
	state=root.get_node("State")
	fresh(); s.actOne.phase="prologue"; s.native.chapter=1
	for network in ["campus_wifi","offline","cellular"]:
		s.networkMode=network
		check(Access.allowed(s)==(network=="cellular"),"C1 original network puzzle "+network)
	s.native.page="tiyi"; act("c1_tiyi_digit")
	check(s.digits.d2=="7" and s.flags.tiyiCountTaken,"C1 cellular still earns 7 without reinstall")
	act("c2_tiyi_discover"); check(s.actOne.tiyiUpdateStage=="not_started","C1 cannot preinstall C2 update")
	s.flags.codeScattered=true; act("c1_rain_drop")
	check(s.flags.waterDropTaken and s.items.waterDrop,"C1 plant water remains independent")
	fresh()
	for network in ["campus_wifi","cellular","offline","cellular"]:
		s.networkMode=network
		check(not Access.allowed(s) and not act("c2_exercise").has("game"),"C2 switching network cannot unlock "+network)
		act("c2_exercise_result",PROOF); check(not s.actOne.exerciseStarted,"result cannot bypass update "+network)
	act("c2_tiyi_install"); act("c2_tiyi_acquire")
	check(s.actOne.tiyiUpdateStage=="not_started","skipped source/acquire/install order rejected")
	s.native.page="tiyi"; var entry=controller.phone_entry_session(s)
	entry.advance(3000); act("c1_tiyi_crash"); entry.advance(620); act("c1_tiyi_exit")
	check(s.native.page=="phone_home" and s.flags.tiyiCrashCount==0,"outdated app returns only in-game, no C1 network taunt count")
	act("c2_tiyi_discover"); s.networkMode="offline"; act("c2_tiyi_acquire")
	check(s.actOne.tiyiUpdateStage=="official_entry_found","offline acquisition does not create a package")
	act("c2_tiyi_install"); check(not Access.installed(s),"discovery alone cannot install")
	s.networkMode="campus_wifi"; act("c2_tiyi_acquire")
	check(s.actOne.tiyiUpdateStage=="package_ready" and not Access.allowed(s),"network transfers package but does not install")
	act("c2_exercise_result",PROOF); act("c2_weather_drop")
	check(not s.actOne.exerciseStarted and not s.actOne.weatherWaterTaken,"package grants neither exercise nor C2 water")
	act("c2_tiyi_install"); var installed=s.duplicate(true)
	for id in ["c2_tiyi_discover","c2_tiyi_acquire","c2_tiyi_install"]: act(id)
	check(s==installed,"repeating update intents is idempotent")
	check(not Access.allowed(s),"installed client still preserves cellular access contract")
	s.networkMode="cellular"; s.native.page="phone_home"
	check(act("c2_exercise").has("game"),"installed identity can open existing run")
	act("c2_exercise_result",PROOF); act("c2_weather_drop")
	check(s.actOne.exerciseStarted and s.actOne.weatherWaterTaken,"existing ten-point proof then grants C2 weather water")
	fresh(); s.actOne.phase="prologue"; s.ui.libraryFinalsPhase="evidence_gathering"; s.ui.libraryFinalsPuzzle.investigationOpened=true
	var draft=s.ui.libraryFinalsPuzzle.auditArrivalMinutes
	act("lib_audit_value",{"field":"arrival","value":7}); act("lib_audit",["7","47","3"])
	check(Access.needs_update(s) and s.ui.libraryFinalsPuzzle.auditArrivalMinutes==draft and not s.ui.libraryFinalsPuzzle.presenceProofCollected,"later library domain cannot masquerade as C1")
	# Real native pointer events over the actual account/card controls.
	fresh(); s.native.page="wechat"; pages=Pages.new(); root.size=Vector2i(430,860)
	pages.action_requested.connect(func(id,value): act(id,value))
	pages.page_requested.connect(func(id): s.native.page=id)
	await render(); await click("TiyiOfficialAccount")
	check(s.actOne.tiyiUpdateStage=="not_started","opening account does not grant discovery")
	await click("TiyiContact"); check(s.actOne.tiyiUpdateStage=="official_entry_found","contact button discovers actual card")
	await click("TiyiAcquireUpdate"); check(s.actOne.tiyiUpdateStage=="package_ready","card pointer acquires package")
	await click("TiyiInstallUpdate"); check(s.actOne.tiyiUpdateStage=="installed" and not s.actOne.exerciseStarted,"install pointer does not fabricate exercise")
	page.free()
	# Normal import path, with native v35 absence migrated narrowly.
	for earned in [false,true]:
		var legacy=state.initial(); legacy.actOne.erase("tiyiUpdateStage")
		legacy.ui.erase("homeDeskReturnScene")
		legacy.actOne.exerciseStarted=earned; legacy.flags.tiyiCountTaken=true; legacy.digits.d2="7"
		check(import_snapshot(legacy,35).get("ok",false),"v35 missing field accepted")
		check(state.d.actOne.tiyiUpdateStage==("legacy_ready" if earned else "not_started"),"only earned C2 evidence gives legacy access")
		check(state.d.ui.homeDeskReturnScene==null,"old desktop navigation defaults to no return context")
		var before=state.d.duplicate(true)
		for version in [36,0,-1,34]:
			check(not import_snapshot(legacy,version).get("ok",false) and state.d==before,"missing stage rejects unsupported/current version "+str(version))
	for invalid in ["wrong",true,0,null]:
		var bad=state.initial(); bad.actOne.tiyiUpdateStage=invalid
		check(not import_snapshot(bad,36).get("ok",false),"explicit bad stage rejected "+str(invalid))
	var missing_desk=state.initial(); missing_desk.ui.erase("homeDeskReturnScene")
	check(not state.validate_snapshot(missing_desk),"live v36 saves never accept absent desktop fields")
	check(not import_snapshot(missing_desk,36).get("ok",false),"v36 missing desktop field rejected independently")
	var missing_update=state.initial(); missing_update.actOne.erase("tiyiUpdateStage")
	check(not state.validate_snapshot(missing_update),"live v36 saves never accept absent update fields")
	for invalid in ["wrong",true,0]:
		var bad=state.initial(); bad.ui.homeDeskReturnScene=invalid
		check(not import_snapshot(bad,36).get("ok",false),"explicit bad desktop return rejected "+str(invalid))
	var explicit=state.initial(); explicit.actOne.tiyiUpdateStage="package_ready"; explicit.actOne.exerciseStarted=true
	check(import_snapshot(explicit,35).get("ok",false) and state.d.actOne.tiyiUpdateStage=="package_ready","explicit valid stage not overwritten by earned evidence")
	check(state.save_game() and state.load_game() and state.d.actOne.tiyiUpdateStage=="package_ready","current state round trips through normal save/load")
	var desk=state.initial(); desk.currentScene="desktop"; desk.native.page="desktop"; desk.ui.homeDeskReturnScene="bonsai"
	check(import_snapshot(desk,36).get("ok",false) and state.d.ui.homeDeskReturnScene=="bonsai","valid C1 desktop return survives import")
	desk.currentScene="phone_home"; desk.native.page="phone_home"
	check(import_snapshot(desk,36).get("ok",false) and state.d.ui.homeDeskReturnScene==null,"stale desktop return is sanitized like source without charging progress")
	print("TIYI_UPDATE: %d checks; %d failures" % [checks,failures])
	quit(1 if failures else 0)
