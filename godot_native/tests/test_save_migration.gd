extends SceneTree
const Migration = preload("res://scripts/save_migration.gd")
var failures := 0
var checked := 0
func _initialize() -> void: call_deferred("_run")
func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		if failures <= 30: push_error("SAVE MIGRATION: " + message)
func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty(): push_error("Pass fixture JSON path"); quit(2); return
	var fixtures = JSON.parse_string(FileAccess.get_file_as_string(args[-1]))
	if not fixtures is Dictionary: push_error("Cannot parse fixture corpus"); quit(2); return
	var migration := Migration.new()
	var defaults: Dictionary = fixtures.initial.duplicate(true)
	defaults["native"] = {"chapter":1,"page":"alarm","scene":"","mode":"light","player":{},"settings":{"music":true,"effects":true,"volume":0.6,"text_scale":1.0,"reduced_motion":false},"log":[],"completed":[],"selected_item":""}
	for fixture in fixtures.fixtures:
		var result := migration.decode(fixture.payload,defaults)
		checked += 1
		if fixture.expected == null:
			check(not result.get("ok",false),fixture.id + " rejected by source")
			continue
		check(result.get("ok",false),fixture.id + " should normalize: " + str(result.get("detail","")))
		if not result.get("ok",false): continue
		var actual: Dictionary = result.state.duplicate(true)
		actual.erase("native"); actual.erase("cc98")
		if actual != fixture.expected:
			check(false,fixture.id + " differs at " + first_difference(actual,fixture.expected))
			var file := FileAccess.open(args[-1] + ".mismatch.json",FileAccess.WRITE)
			if file: file.store_string(JSON.stringify({"id":fixture.id,"actual":actual,"expected":fixture.expected},"\t")); file.close()
		var assertions: Dictionary = fixture.get("assertions",{})
		if assertions.get("no_elevator"): check(not result.state.native.get("c4_elevator_transport",false),fixture.id + " fabricated elevator proof")
		if assertions.get("no_stair"): check(not result.state.native.has("c4_stair_proof"),fixture.id + " fabricated stair proof")
		if assertions.has("floor"): check(result.state.chapter4.floor == assertions.floor,fixture.id + " unsafe floor")
		if assertions.get("elevator"): check(migration.validate_import_proof(result.state,"elevator"),fixture.id + " elevator provenance failed")
		if assertions.get("stair"): check(migration.validate_import_proof(result.state,"stair"),fixture.id + " stair provenance failed")
		if assertions.get("completed"): check(result.state.chapter4.completed and migration.validate_import_proof(result.state,"closure"),fixture.id + " real completion lost")
		if assertions.get("not_completed"): check(not result.state.chapter4.completed,fixture.id + " fabricated completion")
		if assertions.get("legacy_completed"): check(result.state.native.save_import.legacy_completed and result.state.chapter4.phase == "exterior_closure" and not result.state.chapter4.completed,fixture.id + " legacy completion migration")
		if assertions.get("transient_clean"): check(not actual.ui.controlCenterOpen and not actual.ui.inventoryOpen and actual.ui.selectedItem == null,fixture.id + " stale UI")
		if checked % 100 == 0: print("Save differential progress: ",checked)
	_check_adapters(migration,defaults)
	print("Native save migration differential: ",checked," cases, ",failures," failures")
	quit(0 if failures == 0 else 1)

func first_difference(a: Variant,b: Variant,path: String = "state") -> String:
	if a is Dictionary and b is Dictionary:
		for key in a:
			if not b.has(key): return path + "." + key + " (unexpected key)"
		for key in b:
			if not a.has(key): return path + "." + key + " (missing key)"
			if a[key] != b[key]: return first_difference(a[key],b[key],path + "." + key)
	if a is Array and b is Array:
		if a.size() != b.size(): return path + " (array length)"
		for i in range(a.size()):
			if a[i] != b[i]: return first_difference(a[i],b[i],path + "[" + str(i) + "]")
	return path + " (" + str(a) + " != " + str(b) + ")"

func _check_adapters(migration: RefCounted,defaults: Dictionary) -> void:
	var valid := {"version":35,"state":defaults.duplicate(true)}
	var backup: Dictionary = migration.decode_with_backup("{truncated",valid,defaults)
	check(backup.ok and backup.source_selection == "backup","backup recovers corrupted primary")
	var primary: Dictionary = migration.decode_with_backup(valid,{"version":36,"state":{}},defaults)
	check(primary.ok and primary.source_selection == "primary","valid primary wins over backup")
	check(not migration.decode_with_backup("bad","bad",defaults).ok,"two corrupt saves rejected")
	var edited_posts := [{"id":"local-edit","title":"用户修改的标题","content":"保留正文 🧪","threadReplies":[{"author":"测试用户","content":"未改变回复"}]}]
	var overrides := {"library-finals":{"title":"编辑过的剧情帖子"}}
	var bundle := {"format":"7-55-browser-storage","storage":{migration.PRIMARY_KEY:JSON.stringify(valid),migration.POSTS_KEY:JSON.stringify(edited_posts),migration.QUEST_POSTS_KEY:JSON.stringify(overrides)}}
	var imported: Dictionary = migration.decode(bundle,defaults)
	check(imported.ok and imported.stores.posts == edited_posts and imported.stores.questPostOverrides == overrides,"separate edited CC98 data preserved")
	check(not migration.decode(valid,defaults).has("stores"),"plain GameState does not erase separate edits")
	var invalid := {"version":35,"state":defaults.duplicate(true)}
	invalid.state.chapter4 = {"phase":"room204_restore","floor":"A2"}
	invalid.state.native = {"c4_stair_proof":{"fake":true},"c4_elevator_transport":true}
	var sanitized: Dictionary = migration.decode(invalid,defaults)
	check(sanitized.ok and not sanitized.state.native.has("c4_stair_proof") and not sanitized.state.native.has("c4_elevator_transport"),"browser payload native proof is never trusted")
	var tampered: Dictionary = imported.state.duplicate(true)
	tampered.native["c4_stair_proof"] = {"source":"browser_save"}
	check(not migration.validate_import_proof(tampered,"stair"),"fake import provenance rejected")
	var too_deep: Dictionary = {}
	var current: Dictionary = too_deep
	for i in range(26): current["nested"]={}; current=current.nested
	check(not migration.decode(too_deep,defaults).ok,"excessive nesting rejected")
	check(not migration.decode({"version":35,"state":{"phoneBattery":{"percent":NAN}}},defaults).ok,"non-finite numbers rejected")
	check(not migration.decode({"version":35,"state":{"items":{"execute":["call","OS.execute"]}}},defaults).state.items.has("execute"),"payload cannot inject normalization instructions")
