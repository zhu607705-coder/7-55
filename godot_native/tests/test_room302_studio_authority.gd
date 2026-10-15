extends SceneTree
## Isolated authority/save regressions. The fixture records an earned 301 film;
## every new studio checkpoint in this test is produced by controller intents.
const Chapter = preload("res://scripts/chapters/chapter4.gd")
const Model = preload("res://scripts/objects/room302_studio_model.gd")
const ENTRY = "res://tests/fixtures/room302_earned_film_entry.json"
const FACT = "a3_media_alignment_completed"
var checks := 0
var failures := 0
var owner: Node
var controller: RefCounted

func _initialize() -> void: run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
func entry() -> Dictionary:
	var state: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ENTRY)).state
	controller.dispatch(state,"c4_device_media_alignment")
	return state
func dispatch(state: Dictionary, event: Dictionary) -> Dictionary:
	return controller.dispatch(state,"c4_media_studio_event",event)
func prepare(state: Dictionary) -> void:
	for event: Dictionary in [
		{"kind":"swap","a":0,"b":2}, {"kind":"swap","a":1,"b":2},
		{"kind":"step","axis":"xOffset","delta":1}, {"kind":"step","axis":"xOffset","delta":1},
		{"kind":"step","axis":"yOffset","delta":-1}, {"kind":"step","axis":"rotationQuarterTurns","delta":1}]:
		dispatch(state,event)
	check(Model.ready_to_record(state.native.get("c4_media_studio",{})),"Legal object moves prepare the exact source registration")
	check(not FACT in state.chapter4.factIds,"Object preparation cannot publish the original completion fact")

func run() -> void:
	owner = root.get_node("State")
	owner.developer_mode = false
	controller = Chapter.new()
	check(owner.validate_snapshot(entry()),"Earned-film source fixture is an ordinary valid save")
	test_gates()
	test_payloads()
	test_save_compatibility()
	print("ROOM302_STUDIO_AUTHORITY ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)

func stale(state: Dictionary, gate: String) -> void:
	match gate:
		"scene": state.native.scene = "library_interior"
		"native_chapter": state.native.chapter = 3
		"fractional_chapter": state.native.chapter = 4.5
		"native_mode": state.native.mode = "dark"
		"context": state.native.c4_context = "archive_index"
		"phase": state.chapter4.phase = "maintenance_repair"
		"floor": state.chapter4.floor = "A2"
		"mode": state.chapter4.mode = "dark"
		"time": state.chapter4.timeState = "2245_opening"
		"film": state.chapter4.factIds.erase("a3_archive_film_retrieved")
		"prologue": state.chapter4.prologueSeen = false
		"missing_scene": state.native.erase("scene")
		"missing_chapter": state.native.erase("chapter")
		"missing_mode": state.native.erase("mode")
		"missing_context": state.native.erase("c4_context")

func test_gates() -> void:
	var ready: Dictionary = entry()
	prepare(ready)
	var partial: Dictionary = entry()
	dispatch(partial,{"kind":"swap","a":0,"b":2})
	for gate: String in ["scene","native_chapter","fractional_chapter","native_mode","context","phase","floor","mode","time","film","prologue","missing_scene","missing_chapter","missing_mode","missing_context"]:
		for event: Dictionary in [{"kind":"swap","a":1,"b":2},{"kind":"step","axis":"xOffset","delta":-1},{"kind":"reset_alignment"},{"kind":"inspect"}]:
			var state: Dictionary = (partial if event.kind=="swap" else ready).duplicate(true)
			stale(state,gate)
			var before: String = JSON.stringify(state)
			var result: Dictionary = dispatch(state,event)
			check(JSON.stringify(state)==before,"Stale "+gate+" cannot mutate "+event.kind+" checkpoint or facts")
			check(not result.has("studio_motion"),"Stale "+gate+" cannot acknowledge studio input "+event.kind)
		var state: Dictionary = ready.duplicate(true)
		stale(state,gate)
		var before: String = JSON.stringify(state)
		controller.dispatch(state,"c4_solve_media_alignment",Model.source().registration.media.duplicate())
		check(JSON.stringify(state)==before,"Stale "+gate+" cannot record prepared studio")
	var unprepared: Dictionary = entry()
	var before: String = JSON.stringify(unprepared)
	controller.dispatch(unprepared,"c4_solve_media_alignment",Model.source().registration.media.duplicate())
	check(JSON.stringify(unprepared)==before,"Legacy numeric answer cannot skip either physical stage")
	dispatch(unprepared,{"kind":"swap","a":0,"b":2})
	dispatch(unprepared,{"kind":"swap","a":1,"b":2})
	before = JSON.stringify(unprepared)
	controller.dispatch(unprepared,"c4_solve_media_alignment",Model.source().registration.media.duplicate())
	check(JSON.stringify(unprepared)==before,"Correct hats cannot skip unfinished curtain alignment")
	for wrong: Variant in [null,{},[],{"xOffset":0,"yOffset":0,"rotationQuarterTurns":0}]:
		var state: Dictionary = ready.duplicate(true)
		before = JSON.stringify(state)
		controller.dispatch(state,"c4_solve_media_alignment",wrong)
		check(JSON.stringify(state)==before,"Prepared studio still requires original validated final answer")
	var facts: Array = ready.chapter4.factIds.duplicate()
	controller.dispatch(ready,"c4_solve_media_alignment",Model.source().registration.media.duplicate())
	facts.append(FACT)
	check(ready.chapter4.factIds==facts,"Final controller validation adds exactly the original completion fact")
	before = JSON.stringify(ready)
	controller.dispatch(ready,"c4_solve_media_alignment",Model.source().registration.media.duplicate())
	dispatch(ready,{"kind":"reset_alignment"})
	check(JSON.stringify(ready)==before,"Repeated recording and completed studio events are idempotent")

func test_payloads() -> void:
	var state: Dictionary = entry()
	for value: Variant in [null,[],false,0,"swap",{}, {"kind":"unknown"}, {"kind":"step","axis":"xOffset","delta":1}, {"kind":"swap","a":0,"b":0}, {"kind":"swap","a":-1,"b":2}, {"kind":"swap","a":0.5,"b":2}, {"kind":"swap","a":"0","b":2}, {"kind":"swap","a":false,"b":2}]:
		var before: String = JSON.stringify(state)
		controller.dispatch(state,"c4_media_studio_event",value)
		check(JSON.stringify(state)==before,"Malformed or premature studio event cannot create a checkpoint")
	prepare(state)
	for event: Dictionary in [{"kind":"step","axis":"missing","delta":1},{"kind":"step","axis":"xOffset","delta":2},{"kind":"step","axis":"xOffset","delta":0.5},{"kind":"step","axis":"xOffset","delta":"1"},{"kind":"step","axis":"xOffset","delta":true}]:
		var before: String = JSON.stringify(state)
		dispatch(state,event)
		check(JSON.stringify(state)==before,"Malformed curtain input preserves valid progress")

func roundtrip(expected: Dictionary, label: String) -> void:
	check(owner.validate_snapshot(owner.d),label+" is a valid ordinary save")
	var written: bool = owner.save_game()
	check(written,label+" saves through the actual State writer")
	if not written: return
	owner.d = owner.initial()
	var loaded: bool = owner.load_game()
	check(loaded,label+" reloads through the actual State reader")
	if not loaded: return
	check(Model.canonical(owner.d.native.get("c4_media_studio",{}))==Model.canonical(expected),label+" preserves every object position")
	check(not FACT in owner.d.chapter4.factIds,label+" reload does not earn final completion")

func test_save_compatibility() -> void:
	var legacy: Dictionary = entry()
	check(not legacy.native.has("c4_media_studio") and owner.validate_snapshot(legacy),"Old unfinished save remains valid without optional checkpoint")
	owner.d = legacy.duplicate(true)
	owner.act("c4_media_studio_event",{"kind":"swap","a":0,"b":2})
	roundtrip(owner.d.native.c4_media_studio.duplicate(true),"Partial stage one")
	owner.act("c4_media_studio_event",{"kind":"swap","a":1,"b":2})
	owner.act("c4_media_studio_event",{"kind":"step","axis":"xOffset","delta":1})
	roundtrip(owner.d.native.c4_media_studio.duplicate(true),"Partial stage two")
	legacy.chapter4.factIds.append(FACT)
	check(owner.validate_snapshot(legacy),"Old completed save keeps original fact without a fabricated checkpoint")
	var before: String = JSON.stringify(legacy)
	controller.dispatch(legacy,"c4_solve_media_alignment",Model.source().registration.media.duplicate())
	dispatch(legacy,{"kind":"swap","a":0,"b":2})
	check(JSON.stringify(legacy)==before,"Old completed save stays read-only without backfilling invented progress")
	var illegal: Array = [null,false,1,"studio",[],{}, {"version":1}, Model.initial()]
	illegal[-1].completed = true
	for key: String in ["version","hats","alignment"]:
		var missing: Dictionary = Model.initial(); missing.erase(key); illegal.append(missing)
	for value: Variant in [0,2,1.5,"1",true,null]:
		var bad: Dictionary = Model.initial(); bad.version=value; illegal.append(bad)
	for value: Variant in [null,{},[],["stairs","stairs","entrance"],["stairs","honor_wall","unknown"],["stairs","honor_wall",1],["stairs","honor_wall","entrance","extra"]]:
		var bad: Dictionary = Model.initial(); bad.hats=value; illegal.append(bad)
	for value: Variant in [null,{},[],{"xOffset":0,"yOffset":0,"rotationQuarterTurns":0,"complete":true}]:
		var bad: Dictionary = Model.initial(); bad.alignment=value; illegal.append(bad)
	for axis: String in Model.AXES:
		for value: Variant in [-99,99,0.5,"1",true,null]:
			var bad: Dictionary = Model.initial(); bad.alignment[axis]=value; illegal.append(bad)
	for checkpoint: Variant in illegal:
		var snapshot: Dictionary = entry(); snapshot.native.c4_media_studio=checkpoint
		check(not owner.validate_snapshot(snapshot),"Malformed present checkpoint is rejected instead of reset or migrated")
		before = JSON.stringify(snapshot)
		dispatch(snapshot,{"kind":"swap","a":0,"b":2})
		controller.dispatch(snapshot,"c4_solve_media_alignment",Model.source().registration.media.duplicate())
		check(JSON.stringify(snapshot)==before,"Malformed runtime checkpoint cannot be repaired into earned progress")
	# Exercise the same strict reader/importer used for a supplied save, rather
	# than relying only on the in-memory validator.
	var live: Dictionary = owner.d.duplicate(true)
	var saved_bytes: String = FileAccess.get_file_as_string(owner.SAVE_PATH)
	owner.d.native.c4_media_studio = null
	check(not owner.save_game(),"Actual writer refuses malformed checkpoint")
	check(FileAccess.get_file_as_string(owner.SAVE_PATH)==saved_bytes,"Malformed checkpoint cannot overwrite the last valid ordinary save")
	var malformed_path := "user://room302-malformed-save.json"
	var file := FileAccess.open(malformed_path,FileAccess.WRITE)
	check(file!=null,"Malformed-save reader fixture can be written")
	if file:
		file.store_string(JSON.stringify({"format":"7-55-godot-native","version":1,"sourceVersion":35,"state":owner.d}))
		file.close()
		owner.d = live.duplicate(true)
		check(owner._read_native_save(malformed_path).is_empty(),"Actual native reader rejects malformed checkpoint")
		var response: Dictionary = owner.import_save(malformed_path)
		check(not response.get("ok",false) and owner.d==live,"Malformed native import cannot replace current progress")
		DirAccess.remove_absolute(ProjectSettings.globalize_path(malformed_path))
	owner.d = live
	for value: float in [NAN,INF,-INF]:
		var snapshot: Dictionary = entry(); snapshot.native.c4_media_studio=Model.initial(); snapshot.native.c4_media_studio.alignment.xOffset=value
		check(not owner.validate_snapshot(snapshot),"Non-finite studio checkpoint cannot enter ordinary saves")
