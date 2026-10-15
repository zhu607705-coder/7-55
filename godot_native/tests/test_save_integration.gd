extends SceneTree
## Actual-file persistence regressions. Run standalone under an isolated /tmp HOME
## and XDG_DATA_HOME; never open or alter the player's formal user-data directory.
const Migration = preload("res://scripts/save_migration.gd")
const Store = preload("res://scripts/data/cc98_store.gd")
const StairModel = preload("res://scripts/games/chapter4_stair_model.gd")
const Chapter = preload("res://scripts/chapters/chapter4.gd")
const INPUT := "user://integration-import.json"
const EXPORT := "user://integration-export.json"
var failures := 0
var checks := 0
var imported := 0
var state: Node
var migration: RefCounted

func _initialize() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error("SAVE INTEGRATION: " + message)
func write_text(path: String, text: String) -> void:
	var file := FileAccess.open(path,FileAccess.WRITE)
	check(file != null,"open test file " + path)
	if file:
		file.store_string(text)
		file.close()
func write_json(path: String, value: Variant) -> void: write_text(path,JSON.stringify(value))
func bytes(path: String) -> PackedByteArray:
	return FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else PackedByteArray()
func canonical(value: Variant) -> Variant: return JSON.parse_string(JSON.stringify(value))
func envelope(value: Dictionary) -> Dictionary:
	return {"format":"7-55-godot-native","version":1,"sourceVersion":35,"state":value}
func reload_matches(expected: Dictionary, label: String) -> void:
	state.d = state.initial()
	check(state.load_game(),label + " reloads from disk")
	check(canonical(state.d) == canonical(expected),label + " reload retains all fields")
func import_browser(payload: Variant, label: String) -> Dictionary:
	var raw: String = payload if payload is String else JSON.stringify(payload)
	var expected: Dictionary = migration.decode(raw,state.initial())
	check(expected.get("ok",false),label + " source normalizer accepts fixture")
	write_text(INPUT,raw)
	var result: Dictionary = state.import_save(INPUT)
	check(result.get("ok",false),label + " imports through State: " + str(result.get("message","")))
	if result.get("ok",false):
		imported += 1
		check(canonical(state.d) == canonical(expected.state),label + " integration preserves exact normalized source snapshot")
		reload_matches(expected.state,label)
	return result
func reject_raw(raw: String, label: String) -> void:
	var previous: Dictionary = state.d.duplicate(true)
	var prior_primary := bytes(state.SAVE_PATH)
	var prior_backup := bytes(state.BACKUP_PATH)
	var prior_posts := bytes(Store.posts_path)
	var prior_overrides := bytes(Store.quest_path)
	var preview: bool = state.developer_mode
	var formal: Dictionary = state.formal_snapshot.duplicate(true)
	write_text(INPUT,raw)
	var result: Dictionary = state.import_save(INPUT)
	check(not result.get("ok",false),label + " rejected")
	check(state.d == previous and state.developer_mode == preview and state.formal_snapshot == formal,label + " does not mutate current or preview state")
	check(bytes(state.SAVE_PATH) == prior_primary and bytes(state.BACKUP_PATH) == prior_backup,label + " leaves both autosave files byte-identical")
	check(bytes(Store.posts_path) == prior_posts and bytes(Store.quest_path) == prior_overrides,label + " leaves separate CC98 files byte-identical")

func run() -> void:
	if not OS.get_user_data_dir().begins_with("/tmp/"):
		push_error("Refusing persistence tests outside isolated /tmp HOME/XDG_DATA_HOME; formal saves must remain untouched.")
		quit(2)
		return
	state = root.get_node("State")
	migration = Migration.new()
	state.developer_mode = false
	state.d = state.initial()
	check(state.save_game(),"fresh native save writes")
	var checkpoints: Array = state.developer_checkpoints()
	check(checkpoints.size() == 117,"complete 117-checkpoint compressed source corpus")
	for checkpoint in checkpoints:
		import_browser({"version":35,"state":checkpoint.state},"checkpoint " + str(checkpoint.id))
		if str(checkpoint.id).begins_with("c2-") and checkpoint.state.actOne.phase != "complete":
			check(int(state.d.native.chapter) == 2,"imported Chapter 2 prelude retains its active native chapter: " + str(checkpoint.id))
	print("Save integration: all 117 developer checkpoints exercised")
	_test_chapter_two_continuation(checkpoints)
	for version in range(2,36):
		import_browser({"version":version,"state":state.initial()},"version " + str(version) + " fresh")
		var completed: Dictionary = state.initial()
		completed.chapter4.completed = true
		completed.chapter4.phase = "complete"
		var result := import_browser({"version":version,"state":completed},"version " + str(version) + " unproven completion")
		if result.ok:
			check(not state.d.chapter4.completed,"version " + str(version) + " cannot fabricate final completion")
			if version < 25:
				check(state.d.chapter4.phase == "exterior_closure" and state.d.native.save_import.legacy_completed,"legacy completion restores explicit closure waiting")
		var malformed := {"actOne":7,"phoneBattery":[],"chapter4":{"lightGrid":"x","zhuQuestionAnswers":[]},"ui":{"libraryFinalsPuzzle":4},"qizhenLake":{"journal":{"mainPhoto":{"recipe":[]},"optionalPhotos":[7]}}}
		import_browser({"version":version,"state":malformed},"version " + str(version) + " repairable nesting")
	_test_source_journal_strings()
	_test_roundtrip_and_invalid()
	_test_provenance()
	_test_backup_recovery()
	_test_cc98_coexistence()
	print("Native save integration: ",checks," checks, ",imported," real-file browser imports, ",failures," failures")
	quit(1 if failures else 0)

func _test_chapter_two_continuation(checkpoints: Array) -> void:
	var ready: Dictionary = {}
	var unreserved: Dictionary = {}
	for checkpoint in checkpoints:
		if checkpoint.id == "c2-dorm-exit": ready = checkpoint.state.duplicate(true)
		if checkpoint.id == "c2-seat-reservation": unreserved = checkpoint.state.duplicate(true)
	check(not ready.is_empty() and not unreserved.is_empty(),"source movement-ready and unreserved continuation checkpoints available")
	if ready.is_empty() or unreserved.is_empty(): return
	if import_browser({"version":35,"state":unreserved},"unreserved Chapter 2 continuation").ok:
		state.act("c2_dorm_exit")
		check(state.d.actOne.phase == "reservation_required" and state.d.ui.libraryFinalsPhase == "idle","Chapter 2 import does not grant an unreserved dorm exit")
		check(state.get_targets("campus_bootstrap").is_empty(),"unreserved source progress does not expose the library gate")
	if not import_browser({"version":35,"state":ready},"movement-ready Chapter 2 continuation").ok: return
	state.act("c2_dorm_exit")
	check(state.d.actOne.phase == "complete" and state.d.native.scene == "campus_bootstrap" and state.d.ui.libraryFinalsPhase == "library_route_unlocked","imported movement-ready save can complete the real dorm exit")
	check(int(state.d.native.chapter) == 2,"dorm exit preserves the imported Chapter 2 authority")
	reload_matches(state.d.duplicate(true),"post-import Chapter 2 dorm exit")
	var gate: Dictionary = {}
	for target in state.get_targets("campus_bootstrap"):
		if target.get("id") == "library_gate": gate = target
	check(gate.get("action") == "lib_enter","post-import campus exposes the actual library entrance target")
	if gate.is_empty(): return
	state.act(str(gate.action),gate.get("value"))
	check(state.d.native.scene == "library_interior" and state.d.ui.libraryFinalsPhase == "library_entered","imported Chapter 2 progress continues through the visible library gate")
	reload_matches(state.d.duplicate(true),"post-import Chapter 2 library entry")

func _test_source_journal_strings() -> void:
	# SaveStore uses nullableStringOr for authored IDs, even when not in today's catalog.
	var source: Dictionary = state.initial()
	source.qizhenLake.journal.mainTitleId = "unknown-title-from-source"
	source.qizhenLake.journal.mainStatusId = "unknown-status-from-source"
	import_browser({"version":8,"state":source},"source journal nullable string IDs")
	var photo := {"id":"source-photo","spotId":"lake_center","capturedAtSeconds":10000000000000000.0,"tags":[],"recipe":{"zone":"open_water","cropCenterX":836,"cropCenterY":470,"zoomStep":0,"kayakX":836,"kayakY":470,"headingBucket":0}}
	source.qizhenLake.journal.mainPhoto = photo
	source.qizhenLake.journal.pendingDraft = {"id":"qizhen-draft-source-photo","kind":"main","photo":photo,"titleId":"unknown-title","statusId":"unknown-status","captionId":"source-keeps-this-string"}
	import_browser({"version":35,"state":source},"source journal draft string IDs and integer capture time")
	var invalid: Dictionary = state.d.duplicate(true)
	invalid.qizhenLake.journal.pendingDraft.titleId = 7
	reject_raw(JSON.stringify(envelope(invalid)),"journal nullable string rejects number")

func _test_roundtrip_and_invalid() -> void:
	state.d = state.initial()
	state.d.native.page = "weather"
	state.d.native.positions = {"dorm_hub":{"x":321.5,"y":456.25}}
	state.d.native.player = {"x":321.5,"y":456.25}
	state.d.native["future_safe_metadata"] = {"text":"可恢复 🧪","values":[null,1,true,{"nested":"kept"}]}
	state.d.native.friend_scatter_pending = false
	state.d.native.tower_key_pending = true
	state.d.native.c35_reviewed = ["broadcast"]
	state.d.ui.controlCenterOpen = true
	state.d.ui.inventoryOpen = true
	state.d.ui.selectedItem = "campusCard"
	state.d.native.selected_item = "campusCard"
	var expected: Dictionary = state.d.duplicate(true)
	expected.ui.controlCenterOpen = false
	expected.ui.inventoryOpen = false
	expected.ui.selectedItem = null
	expected.native.selected_item = ""
	check(state.save_game(),"valid native snapshot with safe unknown fields writes")
	check(state.d.ui.controlCenterOpen and state.d.native.selected_item == "campusCard","saving cleans only persisted copy")
	reload_matches(expected,"native snapshot")
	check(state.export_save(EXPORT) == OK,"native export writes")
	state.d = state.initial()
	check(state.import_save(EXPORT).ok,"native export imports")
	reload_matches(expected,"native export/import")
	for malformed: String in ["{", "[]", "null", "true", '{"version":35,"state":{},}', '{"version":035,"state":{}}', '{"version":35.,"state":{}}', '{"version":35,"state":{"a":[1,]}}', '{"version":35,"state":{"a":"raw\nnewline"}}', '{"version":35,"state":{"a":"\\q"}}', '{"version":35,"state":{"a":NaN}}', '{"version":36,"state":{}}', '{"version":1,"state":{}}']:
		reject_raw(malformed,"invalid JSON/version " + malformed.left(45))
	reject_raw(" ".repeat(8*1024*1024 + 1),"oversized actual input file")
	check(DirAccess.make_dir_absolute(state.SAVE_PATH + ".tmp") == OK,"simulate inaccessible atomic-write destination")
	reject_raw(JSON.stringify(envelope(expected)),"valid import with actual write failure")
	check(DirAccess.remove_absolute(state.SAVE_PATH + ".tmp") == OK,"remove test-only write obstruction")
	var native_text := JSON.stringify(envelope(expected))
	reject_raw(native_text.left(-1) + ",}","native trailing comma")
	for field: String in ["c4_native_elevator_completed","c4_elevator_transport","friend_scatter_pending","tower_key_pending","c35_reviewed","positions","save_import","c3_tray_slots"]:
		var invalid := expected.duplicate(true)
		invalid.native[field] = "invalid"
		reject_raw(JSON.stringify(envelope(invalid)),"mistyped optional native " + field)
	for value: Variant in [false,"1",null,2]:
		var invalid_envelope := envelope(expected)
		invalid_envelope.version = value
		reject_raw(JSON.stringify(invalid_envelope),"native envelope version " + str(value))
	state.begin_preview(3,"qizhen_lake")
	reject_raw("{truncated","invalid import during developer preview")
	state.restore_formal()
	var previous_primary := bytes(state.SAVE_PATH)
	var previous_backup := bytes(state.BACKUP_PATH)
	state.d = expected.duplicate(true)
	state.d.phoneBattery.percent = 101
	check(not state.save_game(),"invalid runtime state cannot autosave")
	check(bytes(state.SAVE_PATH) == previous_primary and bytes(state.BACKUP_PATH) == previous_backup,"invalid runtime save preserves last good primary and backup bytes")
	write_text(EXPORT,"last good export")
	check(state.export_save(EXPORT) == ERR_INVALID_DATA and FileAccess.get_file_as_string(EXPORT) == "last good export","invalid export cannot clobber destination")
	state.d = expected.duplicate(true)
	state.d.native["unsafe_object"] = RefCounted.new()
	check(not state.save_game(),"unknown native fields must still be safe JSON")
	state.d = expected.duplicate(true)
	state.d.native["too_deep_in_envelope"] = {}
	var nested: Dictionary = state.d.native.too_deep_in_envelope
	for index in range(21):
		nested["next"] = {}
		nested = nested.next
	nested["leaf"] = "bounded"
	check(not state.save_game(),"envelope nesting cannot create an unreloadable native save")
	check(bytes(state.SAVE_PATH) == previous_primary and bytes(state.BACKUP_PATH) == previous_backup,"all rejected runtime states preserve both original files")
	state.d = expected

func _test_provenance() -> void:
	var complete_source: Dictionary = {}
	var stair_source: Dictionary = {}
	for checkpoint in state.developer_checkpoints():
		if checkpoint.id == "c4-755-closure": complete_source = checkpoint.state.duplicate(true)
		if checkpoint.id == "c4-755-a2-field-records": stair_source = checkpoint.state.duplicate(true)
	if import_browser({"version":35,"state":stair_source},"genuine browser stair provenance").ok:
		check(state.d.chapter4.floor == "A2","source stair proof retains A2")
		var tampered: Dictionary = state.d.duplicate(true)
		tampered.native.save_import.source_chapter4.factIds.erase("misaligned_stair_solved")
		reject_raw(JSON.stringify(envelope(tampered)),"tampered source stair provenance")
		tampered = state.d.duplicate(true)
		tampered.native.c4_stair_proof.source_version = 34
		reject_raw(JSON.stringify(envelope(tampered)),"tampered browser proof version")
	complete_source.chapter4.completed = true
	complete_source.chapter4.phase = "complete"
	complete_source.chapter4.exteriorClosureAcknowledged = true
	complete_source.chapter4.zhuQuestionAnswers = {"purpose":"seek_truth","person":"responsible"}
	complete_source.chapter4.factIds.append("zhu_two_questions_answered")
	complete_source.chapter4.factIds.append("exterior_closure_acknowledged")
	if import_browser({"version":35,"state":complete_source},"genuine browser final completion").ok:
		check(state.d.chapter4.completed,"valid source completion survives actual native reload")
		var tampered: Dictionary = state.d.duplicate(true)
		tampered.native.save_import.source_chapter4.exteriorClosureAcknowledged = false
		reject_raw(JSON.stringify(envelope(tampered)),"tampered source completion provenance")
	for floor_id: String in ["A2","A3"]:
		var invalid: Dictionary = state.initial()
		invalid.native.chapter = 4
		invalid.chapter4.floor = floor_id
		reject_raw(JSON.stringify(envelope(invalid)),"unsafe native " + floor_id)
		invalid.native.chapter = 1
		reject_raw(JSON.stringify(envelope(invalid)),"chapter marker cannot bypass unsafe " + floor_id)
		var source: Dictionary = state.initial()
		source.chapter4.prologueSeen = true
		source.chapter4.phase = "room204_restore"
		source.chapter4.floor = floor_id
		source.chapter4.roomId = "a2_room204" if floor_id == "A2" else "a3_wayfinding"
		source.native.c4_stair_proof = {"fake":true}
		source.native.c4_native_elevator_completed = true
		if import_browser({"version":35,"state":source},"unproven browser " + floor_id).ok:
			check(state.d.chapter4.floor == "A1" and not state.d.native.has("c4_native_elevator_completed"),"browser normalization cannot inherit native transport markers")
	var before_ride: Dictionary = {}
	for checkpoint in state.developer_checkpoints():
		if checkpoint.id == "c4-755-elevator-history": before_ride = checkpoint.state.duplicate(true)
	check(not before_ride.is_empty(),"source elevator checkpoint available")
	if not import_browser({"version":35,"state":before_ride},"pre-elevator browser provenance").ok: return
	var chapter := Chapter.new()
	state.d.chapter4.mode = "dark"
	chapter.dispatch(state.d,"c4_class104")
	state.d.chapter4.factIds.erase("elevator_history_observed")
	state.d.chapter4.mode = "light"
	chapter.dispatch(state.d,"c4_class105")
	var calibration: Dictionary = chapter.dispatch(state.d,"c4_elevator_align")
	if calibration.has("game"):
		chapter.dispatch(state.d,"c4_elevator_aligned",{"session":calibration.game.session,"startSeconds":81811,"elapsedMs":6000,"boarded":true})
	var ride: Dictionary = chapter.dispatch(state.d,"c4_elevator_ride")
	check(ride.has("game") or ride.has("world_effect"),"imported browser progress can start real native elevator")
	if ride.has("game") or ride.has("world_effect"):
		var config: Dictionary = ride.get("game",ride.get("world_effect",{}))
		chapter.dispatch(state.d,config.on_success,{"session":config.session,"elapsedMs":6000,"arrived":true,"boarded":true,"fromFloor":"A1","destination":"A3"})
		check(state.d.chapter4.floor == "A3" and state.d.native.get("c4_native_elevator_completed",false),"actual native elevator after browser import receives native provenance")
		check(state.save_game(),"post-import native elevator saves without forged browser evidence")
		reload_matches(state.d.duplicate(true),"post-import native elevator")
		check("elevator_history_observed" not in state.d.chapter4.factIds,"native travel without prior dark observation persists without fabricating history")
	var good_native: Dictionary = state.d.duplicate(true)
	good_native.native.chapter = 4
	good_native.chapter4.floor = "A2"
	for fact: String in ["misaligned_stair_solved","a3_reference_observed"]:
		if fact not in good_native.chapter4.factIds: good_native.chapter4.factIds.append(fact)
	good_native.native.c4_stair_proof = _stair_campaign()
	check(state.validate_snapshot(good_native),"replayed genuine native stair campaign validates after browser import")
	state.d = good_native
	check(state.save_game(),"native stair campaign autosaves")
	reload_matches(good_native,"native stair campaign")
	var bad_stairs := good_native.duplicate(true)
	bad_stairs.native.c4_stair_proof.levels[3].actions.pop_back()
	reject_raw(JSON.stringify(envelope(bad_stairs)),"truncated native stair campaign")
	bad_stairs = good_native.duplicate(true)
	bad_stairs.native.c4_stair_proof.doorTraversed = "true"
	reject_raw(JSON.stringify(envelope(bad_stairs)),"native door proof requires boolean")
	bad_stairs = good_native.duplicate(true)
	bad_stairs.native.c4_stair_proof.levels[0].actions[0].delta = "1"
	reject_raw(JSON.stringify(envelope(bad_stairs)),"native stair delta requires actual number")
	var fake_closure: Dictionary = state.initial()
	fake_closure.native.chapter = 4
	fake_closure.chapter4.completed = true
	fake_closure.chapter4.exteriorClosureAcknowledged = true
	fake_closure.chapter4.factIds.append("exterior_closure_acknowledged")
	fake_closure.native.c4_closure_proof = {"source":"browser_save"}
	reject_raw(JSON.stringify(envelope(fake_closure)),"fabricated browser closure")

func _stair_campaign() -> Dictionary:
	var source: Dictionary = StairModel.data()
	var records: Array = []
	for level in source.levels:
		var model: Dictionary = StairModel.initial(level)
		var camera: Dictionary = source.cameras[level.id]
		var steps: Array = []
		if level.id == "stair_a":
			set_mechanism(level,model,camera,"a_slide",1,steps); set_mechanism(level,model,camera,"a_stair",0,steps); set_mechanism(level,model,camera,"a_lift",1,steps)
			_step(level,model,camera,{"type":"view","value":"south_west"},steps); _step(level,model,camera,{"type":"walk","node":"A_EXIT"},steps)
		elif level.id == "stair_b":
			set_mechanism(level,model,camera,"b_lower_stair",3,steps); set_mechanism(level,model,camera,"b_mid_lift",0,steps); set_mechanism(level,model,camera,"b_upper_stair",1,steps); set_mechanism(level,model,camera,"b_exit_slide",2,steps)
			_step(level,model,camera,{"type":"view","value":"south_west"},steps); _step(level,model,camera,{"type":"walk","node":"B_MID_LIFT_LOW"},steps); set_mechanism(level,model,camera,"b_mid_lift",2,steps)
			_step(level,model,camera,{"type":"view","value":"top_oblique"},steps); _step(level,model,camera,{"type":"walk","node":"B_EXIT"},steps)
		else:
			for index in range(level.ascentViewSequence.size()):
				var prefix: String = level.id + "_" + str(index + 1)
				set_mechanism(level,model,camera,prefix + "_rotate",0,steps); set_mechanism(level,model,camera,prefix + "_transfer",0,steps)
				_step(level,model,camera,{"type":"view","value":level.ascentViewSequence[index]},steps); _step(level,model,camera,{"type":"walk","node":prefix + "_car"},steps); set_mechanism(level,model,camera,prefix + "_transfer",2,steps)
				_step(level,model,camera,{"type":"walk","node":level.exitNodeId if index == level.ascentViewSequence.size() - 1 else prefix + "_transfer_exit"},steps)
		records.append({"id":level.id,"actions":steps})
	return {"kind":"chapter4_stair_campaign","levels":records,"doorTraversed":true}
func set_mechanism(level: Dictionary, model: Dictionary, camera: Dictionary, id: String, target: int, steps: Array) -> void:
	for attempt in range(4):
		if int(model.values[id]) == target: return
		_step(level,model,camera,{"type":"step","id":id,"delta":1},steps)
func _step(level: Dictionary, model: Dictionary, camera: Dictionary, action: Dictionary, steps: Array) -> void:
	check(StairModel.apply(level,model,camera,action),"genuine stair replay action " + str(action))
	steps.append(action)

func _test_backup_recovery() -> void:
	state.d = state.initial()
	state.d.native.page = "weather"
	check(state.save_game(),"backup baseline writes")
	var previous: Dictionary = state.d.duplicate(true)
	state.d.native.page = "settings"
	check(state.save_game(),"new primary rotates last good backup")
	write_text(state.SAVE_PATH,"{broken")
	state.d = state.initial()
	check(state.load_game() and state.d.native.page == "weather","corrupt primary recovers actual previous file")
	check(not state.d.native.log.is_empty(),"backup recovery records notice")
	var restored: Dictionary = state.d.duplicate(true)
	check(state.save_game(),"recovered snapshot can repair primary")
	reload_matches(restored,"recovered primary")
	write_text(state.SAVE_PATH,JSON.stringify(envelope(previous)).left(-1) + ",}")
	write_text(state.BACKUP_PATH,"{also broken")
	var before: Dictionary = state.d.duplicate(true)
	check(not state.load_game() and state.d == before,"malformed native JSON plus corrupt backup leaves state unchanged")
	check(state.save_game(),"valid state repairs two corrupt files")
	var browser := {"format":"7-55-browser-storage","storage":{Migration.PRIMARY_KEY:"{broken",Migration.BACKUP_KEY:JSON.stringify({"version":35,"state":state.initial()})}}
	var result := import_browser(browser,"browser storage backup recovery")
	check(result.ok and not result.warnings.is_empty(),"browser backup selection reported")

func _test_cc98_coexistence() -> void:
	check(Store.restore_defaults() == OK,"isolated CC98 stores initialized")
	var posts: Array = Store.load_posts()
	check(not posts.is_empty(),"CC98 default posts available")
	if posts.is_empty(): return
	var id: String = posts[0].id
	check(Store.save_edits({id:{"title":"保留本机帖子 🧪"},"chapter4-study-index":{"body":"本机剧情帖子"}}) == OK,"existing CC98 edits saved separately")
	var prior_posts := bytes(Store.posts_path)
	var prior_quests := bytes(Store.quest_path)
	import_browser({"version":35,"state":state.initial()},"plain browser save alongside local CC98")
	check(bytes(Store.posts_path) == prior_posts and bytes(Store.quest_path) == prior_quests,"plain browser import preserves both separate stores byte-for-byte")
	check(state.export_save(EXPORT) == OK and state.import_save(EXPORT).ok,"native import alongside CC98")
	check(bytes(Store.posts_path) == prior_posts and bytes(Store.quest_path) == prior_quests,"native import preserves separate stores byte-for-byte")
	posts = Store.load_posts()
	posts[0].title = "浏览器编辑帖子 🧪"
	var bundle := {"format":"7-55-browser-storage","storage":{Migration.PRIMARY_KEY:JSON.stringify({"version":35,"state":state.initial()}),Migration.POSTS_KEY:JSON.stringify(posts)}}
	import_browser(bundle,"browser posts-only bundle")
	check(Store.load_posts()[0].title == "浏览器编辑帖子 🧪","explicit browser post edits replace matching local edits")
	check(Store.load_quest_overrides().get("chapter4-study-index",{}).get("body") == "本机剧情帖子","posts-only import preserves local quest overrides")
	prior_posts = bytes(Store.posts_path)
	bundle.storage.erase(Migration.POSTS_KEY)
	bundle.storage[Migration.QUEST_POSTS_KEY] = JSON.stringify({"chapter4-study-index":{"body":"浏览器剧情帖子"}})
	import_browser(bundle,"browser quest-only bundle")
	check(bytes(Store.posts_path) == prior_posts,"quest-only import preserves post document content")
	check(Store.load_quest_overrides().get("chapter4-study-index",{}).get("body") == "浏览器剧情帖子","explicit browser quest edits imported")
	prior_posts = bytes(Store.posts_path)
	prior_quests = bytes(Store.quest_path)
	bundle.storage[Migration.POSTS_KEY] = JSON.stringify([{"id":"invalid-incomplete-post"}])
	import_browser(bundle,"invalid browser CC98 content")
	check(bytes(Store.posts_path) == prior_posts and bytes(Store.quest_path) == prior_quests,"invalid separate CC98 bundle preserves both local files")
