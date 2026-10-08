extends Node
## Single owner of native progression, persistence, and presentation requests.
signal changed
signal feedback(message: String)
signal game_requested(config: Dictionary)
signal narrative_requested(config: Dictionary)
signal audio_requested(path: String)
signal world_teleport(position: Array)
signal media_requested(config: Dictionary)
signal world_effect_requested(config: Dictionary)
signal capture_requested(config: Dictionary)
signal battery_reserve_used(percent: int)
signal story_reset
signal battery_recharged
signal action_completed(action: String,previous: Dictionary,next: Dictionary,result: Dictionary)
const SAVE_PATH := "user://save.json"
const BACKUP_PATH := "user://save.previous.json"
const SOURCE_VERSION := 35
const SaveDomainGuard = preload("res://scripts/save_domain_guard.gd")
var _domain_guard: RefCounted = SaveDomainGuard.new()
const JOURNAL_ARCHIVE = preload("res://scripts/media/journal_archive.gd")
const MAX_PORTABLE_SAVE_BYTES := 48*1024*1024
var d: Dictionary = {}
var modules: Array = []
var _content_cache: Dictionary = {}
var developer_mode := false
var formal_snapshot: Dictionary = {}
var last_result: Dictionary = {}
var _saving := false
var _journal_validator: RefCounted
var _migration: RefCounted
var _import_proof_cache: Dictionary = {}

func _ready() -> void:
	for path in ["res://scripts/chapters/chapter4.gd", "res://scripts/chapters/chapter3.gd", "res://scripts/chapters/chapter1_2.gd"]:
		if ResourceLoader.exists(path):
			var script = load(path)
			if script and script.can_instantiate(): modules.append(script.new())
	d = initial()
	if not OS.get_cmdline_user_args().has("--fresh"):
		load_game()

func initial() -> Dictionary:
	var value = JSON.parse_string(FileAccess.get_file_as_string("res://data/initial_state.json"))
	var fresh: Dictionary = value if value is Dictionary else {}
	fresh["native"] = {"chapter": 1, "page": "alarm", "scene": "", "mode": "light", "player": {}, "settings": {"music": true, "effects": true, "volume": 0.6, "text_scale": 1.0, "reduced_motion": false}, "log": [], "completed": [], "selected_item": ""}
	return fresh

func asset(path: String) -> String:
	if path.begins_with("res://"): return path
	return "res://assets/" + path.trim_prefix("src/assets/").trim_prefix("assets/").trim_prefix("/")

func content(name: String) -> Variant:
	var normalized := name.trim_prefix("src/data/").trim_prefix("data/source/")
	if not normalized.ends_with(".json"): normalized += ".json"
	if not _content_cache.has(normalized):
		var path := "res://data/source/" + normalized
		_content_cache[normalized] = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else {}
	return _content_cache[normalized]

func get_pages() -> Array:
	var result: Array = []
	var seen: Dictionary = {}
	for module in modules:
		if not module.has_method("pages"): continue
		for page in module.pages(d):
			if page is Dictionary and not seen.has(page.get("id", "")):
				seen[page.id] = true
				result.append(page)
	return result

func get_view(page: String) -> Dictionary:
	for module in modules:
		if module.has_method("view"):
			var found: Dictionary = module.view(page, d)
			if not found.is_empty(): return found
	return {"title": "7:55", "body": "请选择一个应用。"}

func get_actions(page: String) -> Array:
	var result: Array = []
	var seen: Dictionary = {}
	for module in modules:
		if not module.has_method("actions"): continue
		for action in module.actions(page, d):
			if action is Dictionary and not seen.has(action.get("id", "")):
				seen[action.id] = true
				result.append(action)
	return result

func get_c3_narrative_session(delta_ms: float=0) -> RefCounted:
	for module in modules:
		if module.has_method("narrative_session"): return module.narrative_session(d,delta_ms)
	return null

func get_library_story_session(delta_ms: float=0) -> RefCounted:
	for module in modules:
		if module.get("library")!=null: return module.library.story_session(d,delta_ms)
	return null

func get_phone_entry_session() -> RefCounted:
	for module in modules:
		if module.has_method("phone_entry_session"): return module.phone_entry_session(d)
	return null

func advance_phone_entry(delta_ms: float) -> Array:
	var session:=get_phone_entry_session()
	if session==null: return []
	var cues: Array=[]
	for event: Dictionary in session.advance(delta_ms):
		if event.get("action")=="phone_refresh": changed.emit()
		elif event.has("action"): act(str(event.action),event.get("value"))
		elif event.has("feedback"): feedback.emit(str(event.feedback))
		elif event.has("cue"): cues.append(str(event.cue))
	return cues

func get_scene_session() -> RefCounted:
	for module in modules:
		var session: RefCounted=null
		if module.has_method("scene_session"): session=module.scene_session(d)
		elif module.get("library")!=null and module.library.has_method("scene_session"): session=module.library.scene_session(d)
		if session!=null: return session
	return null

func get_targets(scene: String) -> Array:
	var result: Array = []
	for module in modules:
		if module.has_method("targets"):
			result.append_array(module.targets(scene,d))
	return result

func objective() -> String:
	for module in modules:
		if module.has_method("objective"):
			var value: String = module.objective(d)
			if not value.is_empty(): return value
	return "调查被打散的签到记录。"

func act(action: String, value: Variant = null) -> Dictionary:
	if action!="lib_story_complete" and get_library_story_session()!=null: return {"handled":true,"message":""}
	if action not in ["c3_story_complete","c3_promo_visual_complete","c3_reversal_visual_complete","c3_reversal_inspect_closed"] and get_c3_narrative_session()!=null: return {"handled":true,"message":""}
	var previous_state: Dictionary=d.duplicate(true)
	for module in modules:
		if not module.has_method("dispatch"): continue
		var result: Dictionary=module.dispatch(d,action,value)
		if not result.is_empty(): return _accept_result(action,previous_state,result)
	feedback.emit("这个操作暂时不可用。")
	return {"handled":false,"message":"这个操作暂时不可用。"}

func _accept_result(action: String,previous_state: Dictionary,result: Dictionary) -> Dictionary:
	var previous_page: String=str(previous_state.native.page)
	var previous_network: String=str(previous_state.networkMode)
	var previous_battery: int=int(previous_state.phoneBattery.percent)
	last_result=result
	if previous_network!=str(d.networkMode) and previous_battery<=1: battery_reserve_used.emit(1)
	if int(d.phoneBattery.percent)>previous_battery: battery_recharged.emit()
	if result.has("page"): d.native.page=str(result.page)
	if result.has("scene"):
		d.native.scene=str(result.scene); d.rpgScene=str(result.scene)
		d.runtimeMode="rpg" if not str(result.scene).is_empty() else "phone"
	get_phone_entry_session()
	if not str(result.get("message","")).is_empty():
		_record(str(result.message)); feedback.emit(str(result.message))
	if result.has("page"): _consume_scene_open(previous_page,str(d.native.page))
	save_game(); changed.emit()
	if result.get("teleport") is Array: world_teleport.emit(result.teleport)
	if result.get("media") is Dictionary: media_requested.emit(result.media)
	if result.get("world_effect") is Dictionary: world_effect_requested.emit(result.world_effect)
	if result.get("capture") is Dictionary: capture_requested.emit(result.capture)
	if result.get("audio") is String: audio_requested.emit(result.audio)
	if result.get("game") is Dictionary: game_requested.emit(result.game)
	if result.get("narrative") is Dictionary: narrative_requested.emit(result.narrative)
	action_completed.emit(action,previous_state,d.duplicate(true),result)
	return result

func lake_module() -> RefCounted:
	for module in modules:
		if module.get("lake")!=null: return module.lake
	return null

func lake_world_stroke(world: Node,side: String,reverse: bool=false) -> Dictionary:
	var owner:=lake_module()
	if owner==null: return {}
	var previous: Dictionary=d.duplicate(true)
	var result: Dictionary=owner.world_stroke(d,world,side,reverse)
	return _accept_result("c3_world_stroke",previous,result) if not result.is_empty() else {}

func lake_world_tick(world: Node,delta: float) -> Dictionary:
	var owner:=lake_module()
	if owner==null: return {}
	var previous: Dictionary=d.duplicate(true)
	var result: Dictionary=owner.world_tick(d,world,delta)
	return _accept_result("c3_world_tick",previous,result) if not result.is_empty() else {}

func source_app(page: String) -> String:
	var apps := ["alarm","desktop","phone_home","ending","wechat","cc98","zjuding","tiyi","weather","settings","bonsai","checkin","campus_card","photos","timeline_recovery","voice_memos","clock"]
	if page in apps: return page
	if page.begins_with("library_") or page in ["directory","c35_network","c3_campus_map"]: return "zjuding"
	if page in ["c35_recovery"]: return "timeline_recovery"
	if page in ["c35_voice"]: return "voice_memos"
	if page in ["c35_photos"]: return "photos"
	if page=="system_chat": return "zjuding"
	if page in ["c35_official","c35_messages"]: return "wechat"
	if page in ["c35_journal","c3_ticket_post"]: return "cc98"
	return ""

func _consume_scene_open(previous: String, next: String) -> void:
	var old_app := source_app(previous)
	var next_app := source_app(next)
	if next_app.is_empty() or next_app == old_app or next_app in ["alarm","desktop","phone_home","ending"]: return
	var before := int(d.phoneBattery.percent)
	if before <= 1:
		battery_reserve_used.emit(1)
		return
	d.phoneBattery.percent = maxi(1,before-(1 if d.phoneBattery.lowPowerMode else 2))
	if before > 10 and d.phoneBattery.percent <= 10: feedback.emit("电量降至 %s%%。点状态栏，可开启低电量模式或寻找附近电源。"%int(d.phoneBattery.percent))
	elif d.phoneBattery.percent == 1: feedback.emit("电量仅剩 1%，请寻找现场充电服务站。")

func story_input_locked() -> bool:
	return get_library_story_session()!=null or get_c3_narrative_session()!=null

func open_page(page: String) -> void:
	if story_input_locked(): return
	# P10's revealed flower digit is local to its mounted page.
	if str(d.native.page)=="bonsai" and page!="bonsai": d.native.erase("flower_eight_visible")
	_consume_scene_open(str(d.native.page),page)
	d.native.page = page
	get_phone_entry_session()
	var app := source_app(page)
	if not app.is_empty(): d.currentScene = app
	save_game()
	changed.emit()

func open_scene(scene: String) -> void:
	if story_input_locked(): return
	d.native.scene = scene
	d.rpgScene = scene
	d.runtimeMode = "rpg"
	save_game()
	changed.emit()

func toggle_mode() -> void:
	if story_input_locked(): return
	d.native.mode = "dark" if d.native.mode == "light" else "light"
	d.themeMode = "dark" if d.native.mode == "dark" else "normal"
	d.chapter4.mode = d.native.mode
	d.canteenHunt.mode = d.native.mode
	d.theaterHunt.mode = d.native.mode
	d.qizhenLake.mode = d.native.mode
	save_game()
	changed.emit()

func _record(message: String) -> void:
	d.native.log.append({"text":message,"time":Time.get_datetime_string_from_system()})
	while d.native.log.size() > 200: d.native.log.pop_front()

func select_item(id: String) -> void:
	if story_input_locked(): return
	if id.is_empty():
		d.native.selected_item = ""
		d.ui.selectedItem = null
		changed.emit()
		return
	if not d.items.get(id,false): return
	d.native.selected_item = id
	d.ui.selectedItem = id
	changed.emit()

func merge_defaults(base: Dictionary, incoming: Dictionary) -> Dictionary:
	var result := base.duplicate(true)
	for key in incoming:
		if base.has(key) and base[key] is Dictionary and incoming[key] is Dictionary:
			result[key] = merge_defaults(base[key],incoming[key])
		elif incoming[key] is Array or incoming[key] is Dictionary:
			result[key] = incoming[key].duplicate(true)
		else: result[key] = incoming[key]
	return result

func _matches_shape(template: Variant, value: Variant, depth: int = 0, location: String = "") -> bool:
	if depth > 24: return false
	if location == ".qizhenLake.journal":
		if _journal_validator == null and ResourceLoader.exists("res://scripts/chapters/c3_journal.gd"):
			_journal_validator = load("res://scripts/chapters/c3_journal.gd").new()
		return _journal_validator != null and _journal_validator.validate_journal_snapshot(value)
	if template is Dictionary:
		if not value is Dictionary: return false
		for key in template:
			if not value.has(key) or not _matches_shape(template[key],value[key],depth+1,location+"."+str(key)): return false
		return true
	if template is Array:
		if not value is Array or value.size() > 10000: return false
		for entry in value:
			if location == ".native.log":
				if not entry is Dictionary or not entry.get("text") is String or not entry.get("time") is String: return false
			elif location == ".chapter4.room204Placements":
				if not entry is Dictionary or not entry.get("pieceId") is String or not entry.get("slotId") is String or not entry.get("orientation") is String: return false
			elif location in [".qizhenLake.signRotations",".ui.libraryFinalsPuzzle.optionalAc01Floors"]:
				if not entry is int and not entry is float: return false
			elif not entry is String: return false
		return _safe_json(value,depth+1)
	if template is bool: return value is bool
	if template is String: return value is String and value.length() <= 200000
	if template is int or template is float:
		return (value is int or value is float) and is_finite(float(value))
	if template == null:
		return value == null or value is String or value is bool or ((value is int or value is float) and is_finite(float(value)))
	return false

func _safe_json(value: Variant, depth: int = 0) -> bool:
	if depth > 24: return false
	if value is Dictionary:
		if value.size() > 10000: return false
		for key in value:
			if (not key is String and not key is StringName) or not _safe_json(value[key],depth+1): return false
	elif value is Array:
		if value.size() > 10000: return false
		for entry in value:
			if not _safe_json(entry,depth+1): return false
	elif value is String:
		if value.length() > 200000: return false
	elif value is int or value is float:
		if not is_finite(float(value)): return false
	elif value != null and not value is bool: return false
	return true

func validate_snapshot(value: Variant) -> bool:
	if not value is Dictionary or not _safe_json(value): return false
	if not _matches_shape(initial(),value): return false
	if not _domain_guard.validate(value): return false
	# The studio checkpoint is optional for old saves; present checkpoints stay bounded.
	if value.native.has("c4_media_studio") and not load("res://scripts/objects/room302_studio_model.gd").valid(value.native.c4_media_studio): return false
	if int(value.native.chapter) != float(value.native.chapter) or int(value.native.chapter) < 1 or int(value.native.chapter) > 4: return false
	if value.native.mode not in ["light","dark"]: return false
	var scenes := ["", "campus_bootstrap", "campus_qizhen_loop", "dorm_hub", "library_interior", "canteen_interior", "theater_interior", "qizhen_lake", "duan_yongping_temporal_maze"]
	if value.native.scene not in scenes or value.rpgScene not in scenes: return false
	if value.networkMode not in ["campus_wifi","cellular","offline"]: return false
	if value.runtimeMode not in ["phone","rpg"]: return false
	if value.chapter4.floor not in ["A1","A2","A3"] or value.chapter4.mode not in ["light","dark"]: return false
	if value.chapter4.timeState not in ["2245_opening","1225_bakery","1850_evening","2245_maintenance","0754_blackout","0755_morning"]: return false
	if float(value.phoneBattery.percent) < 0 or float(value.phoneBattery.percent) > 100: return false
	if float(value.native.settings.volume) < 0 or float(value.native.settings.volume) > 1: return false
	if float(value.native.settings.text_scale) < .5 or float(value.native.settings.text_scale) > 3: return false
	var optional_templates := {
		"c3_reversal_pending":false,
		"alarm_ringing":false,"wake_warned":false,"flower_eight_visible":false,"friend_scatter_pending":false,"tower_key_pending":false,
		"c35_frame":"","c35_voice_stage":"","c35_summary_choice":"","c4_bio":"","c4_context":"","c4_last_dialogue":"","checkpoint_id":"",
		"lib_catalog_results":false,"lib_dialogue_index":0,"lib_selected_photo":"","lib_photo_filter":"","c4_elevator_transport":false,"c4_native_elevator_completed":false,
		"c35_listened":[],"c35_reviewed":[],"c35_voice_selection":[],"c35_photo_selection":[],"c35_route_selection":[],"lib_catalog_result_ids":[],
		"c35_network_filters":{"time":"all","session":"all","area":"all"},"c3_tray_slots":[],"positions":{},"c4_stair_proof":{},"c4_closure_proof":{},
		"save_import":{"kind":"","source_version":0,"normalizer_sha256":"","legacy_completed":false,"proof_facts":[],"source_chapter4":{}}
	}
	for key in optional_templates:
		if not value.native.has(key): continue
		if key == "c3_tray_slots":
			if not value.native[key] is Array: return false
			for slot in value.native[key]:
				if not slot is Dictionary or not (slot.get("x") is int or slot.get("x") is float) or not (slot.get("y") is int or slot.get("y") is float): return false
		elif not _matches_shape(optional_templates[key],value.native[key],0,".native."+key): return false
	for point in value.native.get("positions",{}).values():
		if not point is Dictionary or not (point.get("x") is int or point.get("x") is float) or not (point.get("y") is int or point.get("y") is float): return false

	if int(value.native.chapter) == 4 or value.chapter4.floor in ["A2","A3"] or value.chapter4.completed:
		var facts: Array = value.chapter4.factIds
		if value.chapter4.floor == "A3":
			if not value.native.get("c4_elevator_transport",false): return false
			for fact in ["classroom_104_chalk_residual_observed","classroom_105_terminal_replay_checked","elevator_history_calibrated"]:
				if fact not in facts: return false
			# Active native transport may precede dark history observation. Browser
			# migration still requires the complete source-normalized origin proof.
			if not value.native.get("c4_native_elevator_completed",false) and "elevator_history_observed" not in facts: return false
			if value.native.has("save_import") and not value.native.get("c4_native_elevator_completed",false) and not _valid_import_proof(value,"elevator"): return false
		if value.chapter4.floor == "A2" and ("misaligned_stair_solved" not in facts or not _valid_stair_proof(value)): return false
		if value.chapter4.completed:
			if not value.chapter4.exteriorClosureAcknowledged or "exterior_closure_acknowledged" not in facts: return false
			var closure: Variant = value.native.get("c4_closure_proof",{})
			if not closure is Dictionary: return false
			if closure.get("source") == "browser_save":
				if not _valid_import_proof(value,"closure"): return false
			else:
				if closure.get("consumer") != "ChapterFourStarLampClosure" or not closure.get("acknowledged") is bool or not closure.acknowledged or not (closure.get("playbackMs") is int or closure.get("playbackMs") is float):return false
				# Only the validated controller session writes this mode. Old native
				# proofs without it retain their original5800ms requirement.
				var mode:Variant=closure.get("playbackMode","normal")
				if not mode is String or mode not in ["normal","reduced_motion"]:return false
				if float(closure.playbackMs)<(3600.0 if mode=="reduced_motion" else 5800.0):return false

	for key in value.items:
		if not value.items[key] is bool: return false
	for entry in value.native.log:
		if not entry is Dictionary or not entry.get("text") is String or not entry.get("time") is String: return false
	for fact in value.chapter4.factIds:
		if not fact is String: return false
	if not value.native.player.is_empty():
		if not value.native.player.get("x") is float and not value.native.player.get("x") is int: return false
		if not value.native.player.get("y") is float and not value.native.player.get("y") is int: return false
	return true

func _migration_instance() -> RefCounted:
	if _migration == null and ResourceLoader.exists("res://scripts/save_migration.gd"): _migration = load("res://scripts/save_migration.gd").new()
	return _migration

func _valid_import_proof(value: Dictionary,kind: String) -> bool:
	var service := _migration_instance()
	if service == null: return false
	var key := JSON.stringify([kind,value.native.get("save_import"),value.native.get("c4_stair_proof"),value.native.get("c4_closure_proof"),value.native.get("c4_elevator_transport"),value.chapter4.factIds,value.chapter4.completed]).sha256_text()
	if not _import_proof_cache.has(key):
		if _import_proof_cache.size() > 32: _import_proof_cache.clear()
		_import_proof_cache[key] = service.validate_import_proof(value,kind)
	return bool(_import_proof_cache[key])

func _valid_stair_proof(value: Dictionary) -> bool:
	var proof: Variant = value.native.get("c4_stair_proof",{})
	if not proof is Dictionary: return false
	if proof.get("source") == "browser_save": return _valid_import_proof(value,"stair")
	if proof.get("kind") != "chapter4_stair_campaign" or not proof.get("doorTraversed") is bool or not proof.doorTraversed or not proof.get("levels") is Array or proof.levels.size() != 4: return false
	for record in proof.levels:
		if not record is Dictionary or not record.get("id") is String or not record.get("actions") is Array: return false
		for action in record.actions:
			if not action is Dictionary or not action.get("type") is String: return false
			match action.type:
				"view":
					if not action.get("value") is String: return false
				"walk":
					if not action.get("node") is String: return false
				"step":
					if not action.get("id") is String or not (action.get("delta") is int or action.get("delta") is float) or float(action.delta) not in [-1.0,1.0]: return false
				_: return false
	return load("res://scripts/games/chapter4_stair_model.gd").validate_result(proof)

func save_game() -> bool:
	if developer_mode or _saving or not validate_snapshot(d): return false
	_saving = true
	var clean := d.duplicate(true)
	clean.ui.controlCenterOpen = false
	clean.ui.inventoryOpen = false
	clean.ui.selectedItem = null
	clean.native.selected_item = ""
	var payload := JSON.stringify({"format":"7-55-godot-native", "version":1,"sourceVersion":SOURCE_VERSION,"savedAt":Time.get_datetime_string_from_system(true),"state":clean},"\t")
	# Never write bytes the bounded strict reader cannot reload (including NUL,
	# envelope-adjusted nesting and aggregate size beyond an individual field).
	if payload.to_utf8_buffer().size() > 8*1024*1024 or not load("res://scripts/save_json_guard.gd").new().accepts(payload):
		_saving = false
		return false
	var file := FileAccess.open(SAVE_PATH + ".tmp",FileAccess.WRITE)
	if not file:
		_saving = false
		return false
	file.store_string(payload)
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		_saving = false
		return false
	if not _read_native_save(SAVE_PATH).is_empty():
		var backup := FileAccess.open(BACKUP_PATH,FileAccess.WRITE)
		if backup:
			backup.store_string(FileAccess.get_file_as_string(SAVE_PATH))
			backup.close()
	var error := DirAccess.rename_absolute(ProjectSettings.globalize_path(SAVE_PATH + ".tmp"),ProjectSettings.globalize_path(SAVE_PATH))
	_saving = false
	return error == OK

func _read_native_save(path: String) -> Dictionary:
	if not FileAccess.file_exists(path): return {}
	var file := FileAccess.open(path,FileAccess.READ)
	if not file: return {}
	if file.get_length() > 8*1024*1024:
		file.close()
		return {}
	var raw := file.get_as_text()
	file.close()
	if not load("res://scripts/save_json_guard.gd").new().accepts(raw): return {}
	var envelope = JSON.parse_string(raw)
	if not envelope is Dictionary or envelope.get("format") != "7-55-godot-native": return {}
	if not (envelope.get("version") is int or envelope.get("version") is float) or envelope.version != 1: return {}
	if not validate_snapshot(envelope.get("state")): return {}
	return envelope

func _sanitize_runtime_resume(snapshot: Dictionary) -> void:
	# The source lake rehydrates at its checkpoint, not a stale moving/chasing
	# framebuffer position. This never alters a saved photo recipe or story fact.
	var positions: Dictionary=snapshot.native.get("positions",{})
	for key in positions.keys():
		if str(key).begins_with("qizhen_lake:"): positions.erase(key)
	if snapshot.native.scene=="qizhen_lake": snapshot.native.player={}

func load_game() -> bool:
	for path in [SAVE_PATH,BACKUP_PATH]:
		var envelope := _read_native_save(path)
		if not envelope.is_empty():
			d = merge_defaults(initial(),envelope.state)
			_sanitize_runtime_resume(d)
			if path == BACKUP_PATH: _record("主存档损坏，已恢复上一份有效存档。")
			return true
	return false

func export_save(path: String) -> Error:
	if not validate_snapshot(d): return ERR_INVALID_DATA
	var archive: Dictionary=JOURNAL_ARCHIVE.pack(d)
	if not archive.ok: return archive.error
	var payload := JSON.stringify({"format":"7-55-godot-native","version":1,"sourceVersion":SOURCE_VERSION,"state":d,"journalImages":archive.images},"\t")
	if payload.to_utf8_buffer().size() > MAX_PORTABLE_SAVE_BYTES or not load("res://scripts/save_json_guard.gd").new().accepts(payload): return ERR_INVALID_DATA
	var file := FileAccess.open(path,FileAccess.WRITE)
	if not file: return FileAccess.get_open_error()
	file.store_string(payload)
	file.flush()
	var error := file.get_error()
	file.close()
	return error

func import_save(path: String) -> Dictionary:
	if not FileAccess.file_exists(path): return {"ok":false,"message":"找不到存档文件。"}
	var file := FileAccess.open(path,FileAccess.READ)
	if not file: return {"ok":false,"message":"无法读取存档文件，当前进度未改变。"}
	if file.get_length() > MAX_PORTABLE_SAVE_BYTES:
		file.close()
		return {"ok":false,"message":"文件过大，不是有效存档。"}
	var raw := file.get_as_text()
	file.close()
	var guard = load("res://scripts/save_json_guard.gd").new()
	if not guard.accepts(raw): return {"ok":false,"message":"JSON 格式无效，当前进度未改变。"}
	var envelope = JSON.parse_string(raw)
	if not envelope is Dictionary: return {"ok":false,"message":"存档必须是完整的 JSON 对象。"}
	var candidate: Dictionary = {}
	var message := "存档已导入。"
	var warnings: Array = []
	var pending_stores: Dictionary = {}
	var pending_images: Dictionary = {}
	var portable_media := false
	var store_service: Script
	if envelope.get("format") == "7-55-godot-native":
		if not (envelope.get("version") is int or envelope.get("version") is float) or envelope.version != 1 or not validate_snapshot(envelope.get("state")): return {"ok":false,"message":"原生存档结构或剧情凭据无效，当前进度未改变。"}
		candidate = merge_defaults(initial(),envelope.state)
		if envelope.has("journalImages"):
			var prepared: Dictionary=JOURNAL_ARCHIVE.prepare(candidate,envelope.journalImages)
			if not prepared.ok: return {"ok":false,"message":"存档照片损坏或不完整，当前进度未改变。"}
			pending_images=prepared.images; portable_media=true
	else:
		var migration := _migration_instance()
		if migration == null: return {"ok":false,"message":"浏览器存档迁移组件不可用。"}
		var decoded: Dictionary = migration.decode(raw,initial())
		if not decoded.get("ok",false): return decoded
		candidate = decoded.state
		if not validate_snapshot(candidate): return {"ok":false,"message":"迁移后的存档未通过原生完整性校验，当前进度未改变。"}
		message = str(decoded.get("message","浏览器存档已迁移。"))
		warnings = decoded.get("warnings",[])
		if decoded.get("stores") is Dictionary:
			store_service = load("res://scripts/data/cc98_store.gd")
			pending_stores = {"posts":store_service.load_posts(),"questPostOverrides":store_service.load_quest_overrides()}
			pending_stores.merge(decoded.stores,true)
			if not store_service.validate_bundle(pending_stores):
				warnings.append("CC98 编辑内容未通过校验，已保留本机内容。")
				pending_stores = {}
	_sanitize_runtime_resume(candidate)
	var installed_images: Dictionary={"ok":true,"created":[]}
	if portable_media:
		installed_images=JOURNAL_ARCHIVE.install(candidate,pending_images)
		if not installed_images.ok: return {"ok":false,"message":"存档照片写入失败，当前进度未改变。"}
	var previous := d.duplicate(true)
	var was_developer := developer_mode
	var previous_backup := formal_snapshot.duplicate(true)
	d = candidate
	developer_mode = false
	formal_snapshot = {}
	if not save_game():
		JOURNAL_ARCHIVE.rollback(installed_images.created)
		d = previous
		developer_mode = was_developer
		formal_snapshot = previous_backup
		return {"ok":false,"message":"写入存档失败，当前进度未改变。"}
	if not pending_stores.is_empty() and store_service.import_bundle(pending_stores) != OK: warnings.append("剧情进度已导入，但 CC98 编辑文件写入失败。")
	story_reset.emit()
	changed.emit()
	return {"ok":true,"message":message+("\n"+"\n".join(warnings) if not warnings.is_empty() else ""),"warnings":warnings}

func new_game() -> void:
	var posts = d.get("cc98",{}).duplicate(true)
	d = initial()
	if not posts.is_empty(): d["cc98"] = posts
	developer_mode = false
	story_reset.emit()
	save_game()
	changed.emit()

func begin_preview(chapter: int, scene: String = "") -> void:
	if not developer_mode: formal_snapshot = d.duplicate(true)
	developer_mode = true
	d = initial()
	d.native.chapter = chapter
	d.native.page = "phone_home"
	d.native.scene = scene
	story_reset.emit()
	changed.emit()

func restore_formal() -> void:
	if not developer_mode: return
	d = formal_snapshot.duplicate(true)
	developer_mode = false
	formal_snapshot = {}
	story_reset.emit()
	changed.emit()

func developer_checkpoints() -> Array:
	if not _content_cache.has("_developer_checkpoints"):
		var file := FileAccess.open("res://data/native/developer_checkpoints.json.gz",FileAccess.READ)
		if not file: return []
		var decoded := file.get_buffer(file.get_length()).decompress_dynamic(4*1024*1024,FileAccess.COMPRESSION_GZIP)
		var parsed = JSON.parse_string(decoded.get_string_from_utf8())
		_content_cache["_developer_checkpoints"] = parsed.get("checkpoints",[]) if parsed is Dictionary else []
	return _content_cache["_developer_checkpoints"]

func begin_checkpoint(id: String) -> bool:
	for checkpoint in developer_checkpoints():
		if str(checkpoint.id) != id: continue
		if not developer_mode: formal_snapshot = d.duplicate(true)
		developer_mode = true
		d = merge_defaults(initial(),checkpoint.state)
		d.native.chapter = 4 if id.begins_with("c4") else 3 if id.begins_with("c3") else 2 if id.begins_with("c2") else 1
		d.native.scene = str(d.rpgScene) if d.runtimeMode == "rpg" else ""
		d.native.page = str(d.currentScene)
		var aliases := {"library":"library_app","timeline_recovery":"c35_recovery","voice_memos":"c35_voice","ending":"ending"}
		d.native.page = aliases.get(d.native.page,d.native.page)
		if int(d.native.chapter) == 4: d.native.page = "c4_notes"
		elif int(d.native.chapter) == 3:
			d.native.page = "c3_canteen" if d.rpgScene == "canteen_interior" else "c3_theater" if d.rpgScene == "theater_interior" else "c3_lake" if d.rpgScene == "qizhen_lake" else d.native.page
		if int(d.native.chapter) == 4: d.native.mode = d.chapter4.mode
		elif int(d.native.chapter) == 3:
			d.native.mode = d.canteenHunt.mode if d.rpgScene == "canteen_interior" else d.theaterHunt.mode if d.rpgScene == "theater_interior" else d.qizhenLake.mode
		d.native["checkpoint_id"] = id
		story_reset.emit()
		changed.emit()
		return true
	return false
