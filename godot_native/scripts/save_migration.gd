extends RefCounted
## Browser save compatibility. All progression normalization comes from the exact
## source-generated program; only native presentation/provenance is added here.
const JsonGuard = preload("res://scripts/save_json_guard.gd")
const Normalizer = preload("res://scripts/save_normalizer_vm.gd")
const PROGRAM_PATH := "res://data/native/save_normalizer.json"
const PRIMARY_KEY := "seven_fifty_five_state"
const BACKUP_KEY := "seven_fifty_five_state_backup"
const POSTS_KEY := "seven-fifty-five.cc98-posts.v2"
const QUEST_POSTS_KEY := "seven-fifty-five.cc98-quest-post-overrides.v1"
const MAX_BYTES := 8 * 1024 * 1024
const ELEVATOR_FACTS := ["classroom_104_chalk_residual_observed", "classroom_105_terminal_replay_checked", "elevator_history_observed", "elevator_history_calibrated"]
var _program: Dictionary = {}
var _checked_bytes := 0
var _checked_nodes := 0

func decode(payload: Variant, defaults: Dictionary) -> Dictionary:
	var parsed := _parse(payload)
	if not parsed.ok: return parsed
	var value: Dictionary = parsed.value
	if _same(value.get("format"),"7-55-godot-native"):
		return {"ok":false,"message":"原生存档应通过原生结构校验器加载。"}
	if _same(value.get("format"),"7-55-browser-storage"):
		if not value.get("storage") is Dictionary: return _invalid("浏览器备份缺少 storage 对象。")
		return _decode_storage(value.storage,defaults)
	if value.has(PRIMARY_KEY) or value.has(BACKUP_KEY): return _decode_storage(value,defaults)
	return _decode_one(value,defaults)

func decode_with_backup(primary: Variant, backup: Variant, defaults: Dictionary) -> Dictionary:
	var result := decode(primary,defaults)
	if result.ok:
		result["source_selection"] = "primary"
		return result
	var recovered := decode(backup,defaults)
	if recovered.ok:
		recovered["source_selection"] = "backup"
		recovered["warnings"] = ["主存档无效，已从有效备份恢复。"]
		recovered["message"] = "已从浏览器备份恢复进度。"
	return recovered

func _decode_storage(storage: Dictionary, defaults: Dictionary) -> Dictionary:
	var result := decode_with_backup(storage.get(PRIMARY_KEY),storage.get(BACKUP_KEY),defaults)
	if not result.ok: return result
	var stores: Dictionary = {}
	for entry in [[POSTS_KEY,"posts",TYPE_ARRAY],[QUEST_POSTS_KEY,"questPostOverrides",TYPE_DICTIONARY]]:
		if not storage.has(entry[0]): continue
		var data: Variant = storage[entry[0]]
		if data is String: data = JSON.parse_string(data) if JsonGuard.new().accepts(data) else null
		if typeof(data) == entry[2] and _safe_json(data): stores[entry[1]] = data.duplicate(true)
		else:
			var warnings: Array = result.get("warnings",[])
			warnings.append("CC98 编辑数据格式无效，未替换已有内容。")
			result["warnings"] = warnings
	if not stores.is_empty(): result["stores"] = stores
	return result

func _parse(payload: Variant) -> Dictionary:
	var value: Variant = payload
	if payload is String:
		if payload.to_utf8_buffer().size() > MAX_BYTES: return _invalid("存档文件过大。")
		if not JsonGuard.new().accepts(payload): return _invalid("JSON 格式无效，当前进度未改变。")
		var json := JSON.new()
		if json.parse(payload) != OK: return _invalid("JSON 无法解析，当前进度未改变。")
		value = json.data
	if not value is Dictionary or not _safe_json(value): return _invalid("存档结构无效，当前进度未改变。")
	return {"ok":true,"value":value}

func _safe_json(value: Variant, depth: int = 0) -> bool:
	if depth == 0: _checked_bytes = 0; _checked_nodes = 0
	_checked_nodes += 1
	_checked_bytes += 8
	if depth > 24 or _checked_nodes > 200000 or _checked_bytes > MAX_BYTES: return false
	if value is Dictionary:
		if value.size() > 10000: return false
		for key in value:
			if not key is String: return false
			_checked_bytes += key.to_utf8_buffer().size()
			if not _safe_json(value[key],depth+1): return false
	elif value is Array:
		if value.size() > 10000: return false
		for entry in value:
			if not _safe_json(entry,depth+1): return false
	elif value is String:
		for index in range(value.length()):
			if value.unicode_at(index) == 0: return false
		_checked_bytes += value.to_utf8_buffer().size()
		if _checked_bytes > MAX_BYTES: return false
	elif value is int or value is float:
		if not is_finite(float(value)): return false
	elif value != null and not value is bool: return false
	return true

func _decode_one(payload: Dictionary, defaults: Dictionary) -> Dictionary:
	if _program.is_empty():
		var data = JSON.parse_string(FileAccess.get_file_as_string(PROGRAM_PATH))
		if not data is Dictionary or data.get("format") != "7-55-native-normalization-ir" or data.get("version") != 1 or not data.get("program") is Array:
			return _invalid("存档迁移数据不可用。")
		_program = data
	var vm := Normalizer.new()
	if not vm.initialize(_program.program):
		var reason: String = vm.failure
		vm.release()
		return _invalid("存档迁移初始化失败。",reason)
	var initial := defaults.duplicate(true)
	initial.erase("native")
	initial.erase("cc98")
	var normalized = vm.invoke("normalizeBrowserSave",[payload.duplicate(true),initial])
	if not vm.failure.is_empty() or not normalized is Dictionary:
		var reason: String = vm.failure
		vm.release()
		return _invalid("存档版本或内容无效，当前进度未改变。",reason)
	var clean = vm.invoke("createPersistentSnapshot",[normalized])
	var failure: String = vm.failure
	vm.release()
	if not failure.is_empty() or not clean is Dictionary or not _safe_json(clean): return _invalid("存档迁移未能安全完成。",failure)
	var version := _version(payload.get("version",0))
	var saved: Dictionary = payload.get("state",{}) if payload.has("version") or payload.has("state") else payload
	var c: Dictionary = saved.get("chapter4",{}) if saved.get("chapter4") is Dictionary else {}
	var legacy_completed: bool = version < 25 and (_same(c.get("completed"),true) or _same(c.get("phase"),"complete"))
	var raw_facts: Array = c.get("factIds",[]) if c.get("factIds") is Array else []
	var facts: Array = clean.chapter4.factIds
	var provenance := {"kind":"browser_save","source_version":version,"normalizer_sha256":str(_program.sourceHashes.get("src/core/SaveStore.ts","")),"legacy_completed":legacy_completed,"proof_facts":[],"source_chapter4":c.duplicate(true)}
	for fact in ELEVATOR_FACTS + ["a3_reference_observed","misaligned_stair_solved"]:
		if fact in raw_facts and fact in facts: provenance.proof_facts.append(fact)
	var native: Dictionary = {"settings":defaults.get("native",{}).get("settings",{}).duplicate(true)}
	# Never inherit native proof, coordinates, stale dialogs, or developer flags.
	native["chapter"] = _chapter(clean)
	native["page"] = _page(clean,int(native.chapter))
	native["scene"] = str(clean.rpgScene) if clean.runtimeMode == "rpg" else ""
	native["mode"] = clean.chapter4.mode if native.chapter == 4 else "dark" if clean.themeMode == "dark" else "light"
	native["player"] = {}
	native["selected_item"] = ""
	native["log"] = []
	native["completed"] = []
	native["save_import"] = provenance
	for field in ["c4_stair_proof","c4_closure_proof","c4_elevator_transport","positions","checkpoint_id"]: native.erase(field)
	var elevator: bool = legacy_completed
	if not elevator:
		elevator = true
		for fact in ELEVATOR_FACTS:
			if fact not in provenance.proof_facts: elevator = false
	if elevator: native["c4_elevator_transport"] = true
	if legacy_completed or ("a3_reference_observed" in provenance.proof_facts and "misaligned_stair_solved" in provenance.proof_facts):
		native["c4_stair_proof"] = {"source":"browser_save","source_version":version,"fact":"misaligned_stair_solved","normalizer_sha256":provenance.normalizer_sha256,"legacy_completed":legacy_completed}
	if clean.chapter4.completed:
		native["c4_closure_proof"] = {"source":"browser_save","source_version":version,"fact":"exterior_closure_acknowledged","normalizer_sha256":provenance.normalizer_sha256}
	clean["native"] = native
	if defaults.get("cc98") is Dictionary: clean["cc98"] = defaults.cc98.duplicate(true)
	return {"ok":true,"state":clean,"message":"网页版存档已迁移。","source_version":version,"warnings":[]}

func _version(value: Variant) -> int:
	# Same Number coercion as the source (numeric strings and singleton arrays).
	var vm := Normalizer.new()
	var result: float = vm._number(value)
	return int(result) if is_finite(result) else 0

func _chapter(state: Dictionary) -> int:
	if state.chapter4.prologueSeen or state.chapter4.completed: return 4
	if state.canteenHunt.active or state.theaterHunt.active or state.qizhenLake.active or state.chapterThreeInterlude.phase != "inactive": return 3
	# The movement prelude is already Chapter 2. Imported saves bypass the
	# native prologue-completion action that normally installs this marker.
	# Classifying only the completed prelude leaves its later library gate inert.
	if state.actOne.phase != "prologue" or state.ui.libraryFinalsPhase != "idle": return 2
	return 1

func _page(state: Dictionary, chapter: int) -> String:
	var page: String = state.currentScene
	var aliases := {"timeline_recovery":"c35_recovery","voice_memos":"c35_voice"}
	if page in aliases: return aliases[page]
	if page == "zjuding" and str(state.ui.zjudingPage).begins_with("library"): return "library_app"
	if chapter == 4 and page == "phone_home": return "c4_notes"
	return page

func _invalid(message: String, detail: String = "") -> Dictionary:
	var result := {"ok":false,"message":message}
	if not detail.is_empty(): result["detail"] = detail
	return result

func validate_import_proof(state: Dictionary, kind: String = "stair") -> bool:
	# Consistency proof, not cryptographic anti-cheat. The retained original C4
	# record is normalized again; a phase or a nonempty dict alone never suffices.
	var native = state.get("native")
	if not native is Dictionary or not native.get("save_import") is Dictionary: return false
	var origin: Dictionary = native.save_import
	if not _same(origin.get("kind"),"browser_save") or not origin.get("source_chapter4") is Dictionary: return false
	if not origin.get("normalizer_sha256") is String or not origin.get("legacy_completed") is bool or not origin.get("proof_facts") is Array or not _safe_json(origin): return false
	for fact in origin.proof_facts:
		if not fact is String: return false
	var version = origin.get("source_version")
	if not (version is int or version is float) or version != floor(float(version)) or (version != 0 and (version < 2 or version > 35)): return false
	var defaults = JSON.parse_string(FileAccess.get_file_as_string("res://data/initial_state.json"))
	if not defaults is Dictionary: return false
	var source := {"version":version,"state":{"chapter4":origin.source_chapter4}}
	if version == 0: source = {"chapter4":origin.source_chapter4}
	var result := _decode_one(source,defaults)
	if not result.ok: return false
	var expected: Dictionary = result.state.native.save_import
	if origin.get("normalizer_sha256") != expected.normalizer_sha256 or origin.get("legacy_completed") != expected.legacy_completed: return false
	if origin.get("proof_facts") != expected.proof_facts: return false
	var chapter = state.get("chapter4")
	if not chapter is Dictionary or not chapter.get("factIds") is Array: return false
	if kind == "elevator":
		if not _same(native.get("c4_elevator_transport"),true) or not _same(result.state.native.get("c4_elevator_transport"),true): return false
		for fact in ELEVATOR_FACTS:
			if fact not in chapter.factIds: return false
		return true
	var field := "c4_closure_proof" if kind == "closure" else "c4_stair_proof"
	if kind not in ["closure","stair"] or not native.get(field) is Dictionary or not result.state.native.get(field) is Dictionary: return false
	# JSON files reload integer-valued numbers as floats. Compare JSON values,
	# not Godot's strict nested int/float identity; object key order is irrelevant.
	if JSON.parse_string(JSON.stringify(native[field])) != JSON.parse_string(JSON.stringify(result.state.native[field])): return false
	if kind == "closure": return _same(chapter.get("completed"),true) and "exterior_closure_acknowledged" in chapter.factIds
	return "misaligned_stair_solved" in chapter.factIds and "a3_reference_observed" in chapter.factIds

func _same(a: Variant, b: Variant) -> bool:
	return typeof(a) == typeof(b) and a == b
