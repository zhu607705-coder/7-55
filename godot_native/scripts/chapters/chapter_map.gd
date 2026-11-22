extends RefCounted
## Player checkpoints come from accepted actions, never from developer fixtures.
const Guard = preload("res://scripts/save_json_guard.gd")
const CHECKPOINTS := {
	"morning": ["寝室醒来", 1, "回到闹钟响起时", "alarm", "alarm-clock"],
	"code": ["找回签到码", 1, "回到签到码散落后", "phone_home", "phone"],
	"voice": ["拦住旁白", 1, "回到签到之后", "ending", "signpost"],
	"campus": ["进入第二章", 2, "回到朋友发来新消息时", "phone_home", "map"],
	"gate": ["入馆核对", 2, "回到基础馆入口", "", "id-card"],
	"junction": ["022 调查", 2, "回到调查帖打开时", "cc98", "signpost"],
	"notice": ["提交公示", 2, "回到阅读公示后的确认说明", "cc98", "clipboard"],
	"seat": ["座位恢复", 2, "回到填写恢复申请前", "library_recovery", "chair"],
}
const CAPTURE_ACTIONS := {
	"c1_start_alarm":"morning", "c1_scatter_complete":"code", "c1_checkin":"voice",
	"c1_intervention_result":"campus", "lib_enter":"gate", "lib_investigate":"junction",
	"lib_story_complete":"notice", "lib_bd_submit":"seat",
}
const MAX_RECORD_CHARS := 180000
const MAX_DECODED := 4 * 1024 * 1024

static func data(snapshot: Dictionary) -> Dictionary:
	return snapshot.get("native", {}).get("chapter_map", {"records": {}, "previous": ""})

static func valid(value: Variant) -> bool:
	if not value is Dictionary or value.size() != 2: return false
	var records: Variant = value.get("records")
	if not records is Dictionary or not _valid_text(value.get("previous")): return false
	for id in records:
		if not CHECKPOINTS.has(id) or not _valid_text(records[id]) or records[id].is_empty(): return false
	return true

static func _valid_text(value: Variant) -> bool:
	return value is String and value.length() <= MAX_RECORD_CHARS

static func encode(snapshot: Dictionary) -> String:
	var bytes := JSON.stringify(snapshot).to_utf8_buffer()
	if bytes.size() > MAX_DECODED: return ""
	var result := Marshalls.raw_to_base64(bytes.compress(FileAccess.COMPRESSION_DEFLATE))
	return result if result.length() <= MAX_RECORD_CHARS else ""

static func decode(encoded: String) -> Dictionary:
	if encoded.is_empty() or not _valid_text(encoded): return {}
	var raw := Marshalls.base64_to_raw(encoded).decompress_dynamic(MAX_DECODED, FileAccess.COMPRESSION_DEFLATE).get_string_from_utf8()
	if raw.is_empty() or not Guard.new().accepts(raw): return {}
	var value: Variant = JSON.parse_string(raw)
	return value if value is Dictionary else {}

static func _earned(id: String, s: Dictionary) -> bool:
	var p: Dictionary = s.ui.libraryFinalsPuzzle
	match id:
		"morning": return s.native.get("alarm_ringing", false) or s.native.page != "alarm"
		"code": return s.flags.codeScattered
		"voice": return s.flags.checkinDone
		"campus": return int(s.native.chapter) >= 2
		"gate": return "entrance" in p.libraryVisitedPoints
		"junction": return p.investigationOpened
		"notice": return p.preBdBriefingSeen
		"seat": return s.ui.libraryFinalsPhase in ["top_ten_reached", "recovery_application", "pass_ready", "backpack_removed", "seat_recovered"]
	return false

static func record(s: Dictionary, before: Dictionary, action: String, result: Dictionary) -> void:
	var id: String = CAPTURE_ACTIONS.get(action, "")
	if id.is_empty() or int(s.native.chapter) != CHECKPOINTS[id][1] or _earned(id,before) or not _earned(id, s): return
	if id == "notice" and result.get("story_finished") != "cc98_evidence_set_completed": return
	if id == "gate" and s.rpgCheckpoint != "library_entrance": return
	if id == "seat" and s.ui.libraryFinalsPhase != "top_ten_reached": return
	var map := data(s)
	if map.records.has(id): return
	var checkpoint := s.duplicate(true)
	checkpoint.native.erase("chapter_map")
	if id == "code":
		checkpoint.native.page = "phone_home"
		checkpoint.currentScene = "phone_home"
	if id == "gate":
		checkpoint.native.player = {}
		checkpoint.native.get("positions", {}).erase("library_interior")
	var encoded := encode(checkpoint)
	if encoded.is_empty(): return
	if not s.native.has("chapter_map"): s.native.chapter_map = map
	map.records[id] = encoded

static func statuses(s: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	var records: Dictionary = data(s).records
	for id: String in CHECKPOINTS:
		var earned := _earned(id,s)
		result[id] = "ready" if earned and records.has(id) else "seen" if earned else "future"
	var p: Dictionary = s.ui.libraryFinalsPuzzle
	if p.investigationOpened:
		result["rules"] = "done" if p.archivedRuleRead else "open"
		result["bag"] = "done" if p.nonPersonProofStamped else "open"
		result["receipt"] = "done" if p.seatReceiptCollected else "open"
		result["visit"] = "done" if p.presenceProofCollected else "open" if p.archivedRuleRead else "blocked"
	return result

static func current_stop(s: Dictionary) -> String:
	if int(s.native.chapter) == 1:
		if s.flags.checkinDone: return "voice"
		return "code" if s.flags.codeScattered else "morning"
	if int(s.native.chapter) == 2:
		for id: String in ["seat","notice","junction","gate","campus"]:
			if _earned(id,s): return id
	return ""
