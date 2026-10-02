extends RefCounted
## Current LibraryFinalsController + puzzle JSON, excluding retired archaeology route.
const EVIDENCE = {"archived_leave_rule":"archivedLeaveRule", "bag_non_person_proof":"bagNonPersonProof", "seat_022_receipt":"seat022Receipt", "library_presence_proof":"libraryPresenceProof"}
const RECOVERY = ["bag_non_person_proof", "seat_022_receipt", "library_presence_proof"]
const BD_IDS = ["bd-rule-count", "bd-identity-zero", "bd-seat-tail", "bd-arrival-minutes"]
var content: Dictionary = {}
const SceneSession = preload("res://scripts/presentation/c3_scene_session.gd")
var opening_session: RefCounted

const StorySession = preload("res://scripts/presentation/library_story_session.gd")
var current_story: RefCounted
var story_queue: Array=[]
var delayed_stories: Array=[]
var story_state: Dictionary={}
var front_desk_hint_index: int=0

func _bind_story_state(s: Dictionary) -> void:
	if is_same(s,story_state): return
	if current_story!=null: current_story.cancel()
	current_story=null; story_queue.clear(); delayed_stories.clear(); story_state=s; front_desk_hint_index=0

func _request_story(s: Dictionary,id: String,delay_ms: float=0) -> void:
	_bind_story_state(s)
	# The source event map includes library_route_unlocked, but no authored
	# sequence has that ID. Final 022 has its existing C3 opening owner.
	if not _data().get("storyDialogues",{}).has(id): return
	if current_story!=null and current_story.sequence_id==id and current_story.status not in ["cancelled","consumed"]: return
	if story_queue.has(id): return
	for entry: Dictionary in delayed_stories:
		if entry.id==id: return
	if delay_ms>0: delayed_stories.append({"id":id,"remainingMs":delay_ms})
	else: story_queue.append(id)

func story_session(s: Dictionary,delta_ms: float=0) -> RefCounted:
	_bind_story_state(s)
	if not _active(s):
		if current_story!=null: current_story.cancel()
		current_story=null; story_queue.clear(); delayed_stories.clear(); return null
	for i in range(delayed_stories.size()-1,-1,-1):
		delayed_stories[i].remainingMs-=clampf(delta_ms,0,100) if is_finite(delta_ms) else 0
		if delayed_stories[i].remainingMs<=0:
			story_queue.append(delayed_stories[i].id); delayed_stories.remove_at(i)
	if current_story!=null:
		if current_story.valid(s) and current_story.status not in ["cancelled","consumed"]: return current_story
		current_story.cancel(); current_story=null
	# App.tsx recovery restores incomplete acknowledged briefings after reload.
	var p: Dictionary=_p(s)
	if p.archivedRuleRead and not p.archivedRuleBriefingSeen and _phase(s)=="evidence_gathering": _request_story(s,"library_archived_rule_recovered")
	elif not p.preBdBriefingSeen and _all(p.cc98UploadedEvidenceIds,EVIDENCE.keys()) and _phase(s) in ["bd_briefing","top_ten_rising"]: _request_story(s,"cc98_evidence_set_completed")
	elif _phase(s)=="pass_ready" and p.evictionPassGenerated and not p.passBriefingSeen: _request_story(s,"library_seat_release_pass_issued")
	while not story_queue.is_empty():
		var id: String=story_queue.pop_front()
		var issued: RefCounted=StorySession.new(s,id,_data().storyDialogues[id])
		if issued.valid(s): current_story=issued; return current_story
	return null

func _finish_story(s: Dictionary,value: Variant) -> Dictionary:
	if not value is StorySession or value!=current_story: return _ok("当前剧情条件已变化，请返回任务目标后重试。")
	var p: Dictionary=_p(s)
	# A genuine presentation receipt is necessary, but progression conditions
	# are independently rechecked here, as in LibraryFinalsController.
	match value.sequence_id:
		"library_archived_rule_recovered","library_front_desk_proof_request":
			if _phase(s)!="evidence_gathering" or not p.archivedRuleRead: return _ok("当前剧情条件已变化，请返回任务目标后重试。")
		"cc98_evidence_set_completed":
			if _phase(s) not in ["bd_briefing","top_ten_rising"] or not _all(p.cc98UploadedEvidenceIds,EVIDENCE.keys()): return _ok("当前剧情条件已变化，请返回任务目标后重试。")
		"library_seat_release_pass_issued":
			if _phase(s)!="pass_ready" or not p.evictionPassGenerated: return _ok("当前剧情条件已变化，请返回任务目标后重试。")
	if not value.consume(s): return _ok("当前剧情条件已变化，请返回任务目标后重试。")
	match value.sequence_id:
		"library_archived_rule_recovered": p.archivedRuleBriefingSeen=true
		"library_front_desk_proof_request": p.frontDeskProofRequestSeen=true
		"cc98_evidence_set_completed":
			p.preBdBriefingSeen=true; s.ui.libraryFinalsPhase="top_ten_rising"
		"library_seat_release_pass_issued": p.passBriefingSeen=true
	return _ok("",{"story_finished":value.sequence_id})

func scene_session(s: Dictionary) -> RefCounted:
	if not SceneSession.pending_opening(s):
		if opening_session != null: opening_session.cancel()
		opening_session = null
		return null
	if opening_session == null or not opening_session.valid(s) or opening_session.status in ["cancelled","consumed"]:
		if opening_session != null: opening_session.cancel()
		opening_session = SceneSession.new(s,"opening",bool(s.native.get("settings",{}).get("reduced_motion",false)))
	return opening_session


func _data() -> Dictionary:
	if content.is_empty():
		var path = "res://data/source/library-finals.content.json"
		if FileAccess.file_exists(path): content = JSON.parse_string(FileAccess.get_file_as_string(path))
	return content

func _ok(message: String, extra: Dictionary = {}) -> Dictionary:
	var r = {"handled":true,"message":message}
	r.merge(extra, true)
	return r

func _phase(s: Dictionary) -> String: return str(s.ui.libraryFinalsPhase)
func _p(s: Dictionary) -> Dictionary: return s.ui.libraryFinalsPuzzle
func _active(s: Dictionary) -> bool: return int(s.native.get("chapter",1)) == 2 and _phase(s) != "idle"
func _a(id: String, label: String, input: String = "", options: Array = []) -> Dictionary:
	var r = {"id":id,"label":label}
	if input != "": r.input = input
	if not options.is_empty(): r.options = options
	return r
func _unique(values: Array, v: Variant) -> void:
	if not values.has(v): values.append(v)
func _all(values: Array, keys: Array) -> bool:
	for k in keys:
		if not values.has(k): return false
	return true
func _go(s: Dictionary, page: String, text: String = "") -> Dictionary:
	s.native.page = page
	return _ok(text, {"page":page})
func _world(s: Dictionary, scene: String, text: String = "") -> Dictionary:
	s.native.scene = scene
	s.rpgScene = scene
	s.runtimeMode = "rpg"
	return _ok(text,{"scene":scene})

func pages(s: Dictionary) -> Array:
	var out: Array = []
	if ["reservation_required", "movement_ready", "complete"].has(s.actOne.phase) or s.ui.librarySeatReserved: out.append({"id":"library_app","label":"图书馆服务"})
	if not _active(s): return out
	if _p(s).occupancyNoteCollected: out.append({"id":"library_archive","label":"已取得的材料"})
	if _p(s).catalogUnlocked: out.append({"id":"library_catalog","label":"馆藏检索"})
	if _p(s).backpackInspected and _p(s).investigationOpened: out.append({"id":"photos","label":"照片"})
	if _phase(s) in ["top_ten_reached","recovery_application","pass_ready","backpack_removed","seat_recovered"]: out.append({"id":"library_recovery","label":"座位恢复申请"})
	return out

func view(page: String, s: Dictionary) -> Dictionary:
	var p = _p(s)
	var d = _data()
	if page == "library_app": return {"title":"图书馆 · 座位预约", "body":"基础馆\n负一层书库　160 座\n一层书库　160 座\n二层书库　160 座\n" + ("已预约　一层书库 022" if s.ui.librarySeatReserved else "选择馆舍、阅览室与座位")}
	if not _active(s): return {}
	match page:
		"library_archive":
			var rows: Array = []
			if p.occupancyNoteCollected: rows.append({"title":"占座纸条","body":"本人离开三分钟，精神仍在座位上。临时离座规则详见 CC98。"})
			if p.archivedRuleRead: rows.append({"title":"旧版离座规则","body":"三项证明：本人到馆、座位凭据、占用物非本人。公开公示后可恢复座位。"})
			if p.nonPersonProofStamped: rows.append({"title":"书包非本人证明","body":"对象：022 座位占用书包\n认证结论：非本人\n姓名 / 学号：无 / 无\n盖章来源：基础馆物品身份盖章机\n经核验，该书包无姓名、无学号，不具备独立占用座位的身份条件。\n本证明仅证明书包。持有人仍需另交到馆材料。"})
			if p.seatReceiptCollected: rows.append({"title":"022 座位凭据","body":"座位编号：022\n区域：一层书库\n时间：07:55\n凭据状态：离座中 · 待公示\n当前占用物：书包。恢复处理需提交论坛公示。"})
			if p.presenceProofCollected: rows.append({"title":"本人来过证明","body":"到馆时长：7 分钟\n公示编号：47\n证明数量：3\n记录状态：补录成功\n访问轨迹与 022 座位凭据的时间记录一致。到馆已确认，座位使用仍需单独申请。"})
			return {"title":"已取得的材料","body":"材料提交后，内容仍保留在这里。","rows":rows}
		"library_record": return {"title":"入馆记录", "body":"07:55：进入基础馆\n08:02：到达一层书库 022\n一层书库 022：存在未闭合会话\n最后活动：未知\n\n08:02 − 07:55"}
		"library_rule": return {"title":"旧版离座规则", "body":"期末周修订版 · 已归档\n适用范围：座位被非本人随身物持续占用\n目标座位：022\n恢复申请须同时具备三类证明：\n一、本人确实到馆；\n二、目标座位与凭据一致；\n三、当前占用物不具备本人身份。\n规则依据须先完成公开公示。"}
		"library_catalog":
			var rows: Array = []
			if s.native.get("lib_catalog_results", false):
				for r in d.get("library",{}).get("catalogResults",[]):
					if not s.native.get("lib_catalog_result_ids",[]).has(r.id): continue
					rows.append({"title":r.title, "body":"%s\n%s　%s\n%s\n%s" % [r.author,r.callNumber,r.year,r.location,r.note]})
			return {"title":"馆藏检索", "body":"请输入题名 / 作者 / 索书号", "rows":rows}
		"photos":
			if not p.photoCaptured: return {"title":"照片 · 取证", "body":"没有书包照片。请在 022 附近拍摄。"}
			return {"title":"IMG_0755.JPG", "body":"对象类型：书包；状态：长期占座；本人属性：不成立" if p.photoDimmed else "书包标签曝光过度。调整屏幕亮度后核对。"}
		"tiyi":
			if not p.investigationOpened: return {}
			if s.networkMode != "cellular": return {"title":"浙大体艺", "body":"当前网络无法完成加载。需要移动数据。"}
			var route = "寝室 → 图书馆入口 → 022 → 前台 → 书架背面 → 022"
			return {"title":"本人来过证明补录单", "body":route + "\n到座耗时（分钟）\n公示编号\n规则要求的证明数量\n请核对门禁记录、论坛公示与旧版规则。"}
		"cc98":
			if not s.actOne.cc98Login.authenticated or s.networkMode != "campus_wifi": return {}
			if not p.investigationOpened: return {"title":"CC98 · 搜索", "body":"搜索帖子、版面与校园资料。\n搜索框可以接收纸条。"}
			var forum: Dictionary = d.get("cc98", {})
			var rows: Array = []
			for r in forum.get("storyReplies",[]): rows.append({"title":"%s 楼 · %s" % [r.floor,r.author], "body":str(r.get("quote", "")) + "\n" + r.text})
			for r in forum.get("optionalAc01Replies",[]): rows.append({"title":"%s 楼 · %s" % [r.floor,r.author],"body":r.text})
			var body = str(forum.get("post",{}).get("body",""))
			body += "\n已上传 %s / 4 项\n" % p.cc98UploadedEvidenceIds.size()
			if _all(p.cc98UploadedEvidenceIds, EVIDENCE.keys()):
				body += str(forum.get("bdPassword",{}).get("meaning","")) + "\n" + str(forum.get("bdPassword",{}).get("prompt",""))
				for e in forum.get("evidenceSlots",[]): body += "\n" + e.label
				for r in forum.get("bdPassword",{}).get("posts",[]): rows.append({"title":"%s 楼 · %s　[%s]" % [r.floor,r.author,r.digit], "body":r.text})
				body += "\n当前口令：" + _password_display(p.bdSelectedPostIds)
				if p.bdCount >= 3: body += "\n十大排名　01"
			return {"title":str(forum.get("post",{}).get("title","022 的书包占座三天了")),"body":body,"rows":rows}
		"library_recovery":
			return {"title":"022 座位恢复申请", "body":"申请材料\n本人来过证明　书包非本人证明　022 座位小票\n已提交 %s / 3 项\n旧版规则通过 CC98 公开记录核验。" % p.recoverySubmittedEvidenceIds.size()}
		"library_022_dialogue":
			var lines: Array = d.get("library",{}).get("dialogue022",[])
			var i = int(s.native.get("lib_dialogue_index",0))
			if i < lines.size(): return {"title":"022", "body":str(lines[i].speaker) + "：" + str(lines[i].text)}
			return {"title":"022", "body":"纸条离开了座位。"}
	return {}

func actions(page: String, s: Dictionary) -> Array:
	if page == "library_app" and s.actOne.phase == "reservation_required": return [{"id":"c2_reserve","label":"提交预约","inputs":[{"id":"library","label":"馆舍","type":"choice","options":["主馆","基础馆"]},{"id":"room","label":"阅览室","type":"choice","options":["负一层书库","一层书库","二层书库"]},{"id":"seat","label":"座位号","type":"text"}]}]
	if not _active(s): return []
	var p = _p(s)
	match page:
		"library_record": return [_a("lib_record", "记下入馆记录")] if not p.entranceRecordRead else []
		"library_rule": return [_a("lib_read_rule", "阅读旧版离座规则")] if p.archivedRuleCollected and not p.archivedRuleRead else []
		"library_catalog":
			var out = [_a("lib_catalog_search", "检索馆藏", "text")]
			if s.native.get("lib_catalog_results",false):
				var options: Array = []
				for r in _data().get("library",{}).get("catalogResults",[]):
					if s.native.get("lib_catalog_result_ids",[]).has(r.id): options.append({"id":r.id,"label":r.title})
				out.append(_a("lib_catalog_select", "打开馆藏条目", "choice", options))
			return out
		"photos":
			if not p.photoCaptured: return []
			return [_a("lib_dim_photo", "核对照片中的标签")] + ([_a("lib_item_report", "用旧照补全物品报告")] if s.native.get("lib_selected_photo","")=="seat_022_clue" and not p.itemReportGenerated else [])
		"tiyi": return [{"id":"lib_audit","label":"提交补录单","inputs":[{"id":"arrival","label":"到座耗时（分钟）","type":"number"},{"id":"notice","label":"公示编号","type":"number"},{"id":"proofs","label":"证明数量","type":"number"}]}] if p.investigationOpened and s.networkMode == "cellular" and not p.presenceProofCollected else []
		"cc98":
			if not s.actOne.cc98Login.authenticated or s.networkMode != "campus_wifi": return []
			if not p.investigationOpened: return [_a("lib_investigate", "将占座纸条放入搜索框", "choice", [{"id":"occupancyNote","label":"占座纸条"}])]
			var out: Array = []
			var ac_options: Array = []
			for r in _data().get("cc98",{}).get("optionalAc01Replies",[]):
				if not p.optionalAc01Floors.has(int(r.floor)): ac_options.append({"id":str(int(r.floor)),"label":"%s 楼 · %s" % [int(r.floor),r.author]})
			if not ac_options.is_empty(): out.append(_a("lib_optional_ac01","折叠一条闲聊回复","choice",ac_options))
			if _phase(s) == "evidence_gathering":
				var opts: Array = []
				for e in _data().get("cc98",{}).get("evidenceSlots",[]):
					if s.items[EVIDENCE[e.id]] and not p.cc98UploadedEvidenceIds.has(e.id): opts.append({"id":e.id,"label":e.label})
				if not opts.is_empty(): out.append(_a("lib_upload", "上传证据", "choice", opts))
			if _phase(s) == "bd_briefing": out.append(_a("lib_bd_briefing", "阅读公开确认说明"))
			if _phase(s) == "top_ten_rising":
				var opts: Array = []
				for r in _data().get("cc98",{}).get("bdPassword",{}).get("posts",[]): opts.append({"id":r.id,"label":"%s 楼 · %s　bd" % [r.floor,r.author]})
				out.append(_a("lib_bd_select", "对数字回复 bd", "choice", opts))
				out.append(_a("lib_bd_undo", "撤回最后一次 bd"))
				out.append(_a("lib_bd_submit", "核验热度口令"))
			return out
		"library_recovery":
			if _phase(s) == "top_ten_reached": return [_a("lib_recovery_open", "填写恢复申请")]
			if _phase(s) == "recovery_application":
				var opts: Array = []
				for e in _data().get("cc98",{}).get("evidenceSlots",[]):
					if RECOVERY.has(e.id) and s.items[EVIDENCE[e.id]]: opts.append({"id":e.id,"label":e.label})
				return [_a("lib_recovery_upload", "提交申请材料", "choice", opts), _a("lib_generate_pass", "申请解除占座凭证")]
		"library_022_dialogue": return [_a("lib_dialogue_next", "继续对话")] if p.playerSeated and p.nextQuestId == null else []
	return []

func dispatch(s: Dictionary, action: String, value: Variant = null) -> Dictionary:
	if not action.begins_with("lib_"): return {}
	if not _active(s): return _ok("图书馆调查尚未开放。")
	if action=="lib_story_complete": return _finish_story(s,value)
	if story_session(s)!=null: return _ok("请先完成当前对话。")
	var p = _p(s)
	var phase = _phase(s)
	var items: Dictionary = s.items
	if SceneSession.pending_opening(s) and action not in ["lib_dialogue_open","lib_dialogue_next","lib_opening_complete"]: return _ok("请先完成 022 转场。")
	if action in ["lib_note","lib_shelf","lib_photo","lib_scan","lib_receipt","lib_apply_pass","lib_sit"] and s.native.get("mode","light") != "light": return _ok("深色观察不执行物理操作。请切换到浅色操作。")
	if action in ["lib_investigate", "lib_upload", "lib_bd_briefing", "lib_bd_select", "lib_bd_undo", "lib_bd_submit"] and (s.networkMode != "campus_wifi" or not s.actOne.cc98Login.authenticated): return _ok("请在校园网完成 CC98 统一身份认证。")
	match action:
		"lib_enter":
			if s.actOne.phase != "complete": return _ok("需要先从寝室出发。")
			if phase == "library_route_unlocked":
				s.ui.libraryFinalsPhase = "library_entered"
				_request_story(s,"library_entered")
			_unique(p.libraryVisitedPoints,"entrance")
			s.rpgCheckpoint = "library_entrance"
			return _world(s,"library_interior")
		"lib_exit":
			if s.native.scene != "library_interior": return _ok("你不在图书馆里。")
			s.rpgCheckpoint = "campus_library_gate"
			return _world(s,"campus_bootstrap")
		"lib_open_record":
			if s.native.scene != "library_interior": return _ok("需要靠近入口记录屏。")
			return _go(s,"library_record")
		"lib_record":
			if phase != "library_entered" or s.native.scene != "library_interior": return _ok("现在不能写入入馆记录。")
			p.entranceRecordRead = true
			_unique(p.clueIds,"arrival_7_minutes")
			return _ok("门禁记录已记下。022 存在未闭合会话。")
		"lib_backpack":
			if not p.entranceRecordRead or phase not in ["library_entered","occupied_seat_found"] or s.native.scene != "library_interior": return _ok("先核对闸机上的入馆记录。")
			if p.backpackInspected: return _ok("")
			p.backpackInspected = true
			s.ui.libraryFinalsPhase = "occupied_seat_found"
			_unique(p.libraryVisitedPoints,"seat_022")
			_request_story(s,"library_occupied_seat_found")
			return _ok("")
		"lib_note":
			if phase != "occupied_seat_found" or not p.backpackInspected or p.occupancyNoteCollected: return _ok("现在没有可以取下的纸条。")
			p.occupancyNoteCollected = true
			items.occupancyNote = true
			s.ui.libraryFinalsPhase = "evidence_gathering"
			_unique(p.clueIds,"occupancy_note")
			return _ok("获得占座纸条：本人离开三分钟，精神仍在座位上。临时离座规则详见 CC98。")
		"lib_investigate":
			if phase != "evidence_gathering" or not p.occupancyNoteCollected or not items.occupancyNote or str(value) != "occupancyNote": return _ok("搜索框需要那张占座纸条。")
			p.investigationOpened = true
			items.occupancyNote = false
			_unique(p.clueIds,"public_notice_floor_47")
			_request_story(s,"cc98_occupation_post_opened")
			return _ok("")
		"lib_optional_ac01":
			var floor_number = int(str(value))
			if not p.investigationOpened or floor_number not in [3,6,9,15,21] or p.optionalAc01Floors.has(floor_number): return _ok("这条回复不属于可折叠的闲聊。")
			p.optionalAc01Floors.append(floor_number)
			return _ok("闲聊已折叠，不影响公开证据。")
		"lib_catalog_terminal":
			if phase != "evidence_gathering" or not p.investigationOpened: return _ok("终端可检索馆藏；先从调查帖确认有关题名。")
			p.catalogUnlocked = true
			_unique(p.libraryVisitedPoints,"catalog_terminal")
			return _go(s,"library_catalog")
		"lib_catalog_search":
			var query = str(value).strip_edges().replace(" ","").replace("《","").replace("》","")
			# Search remains functional; collecting story evidence still requires the terminal fact.
			if query.is_empty(): return _ok("请输入题名 / 作者 / 索书号。")
			var ids: Array = []
			var clue_match = query.length() >= 3 and ("三分钟离座法".begins_with(query) or query.begins_with("三分钟离座法"))
			for r in _data().get("library",{}).get("catalogResults",[]):
				var text = str(r.title)+str(r.author)+str(r.callNumber)+str(r.publisher)+str(r.location)
				if clue_match or text.to_lower().contains(query.to_lower()): ids.append(r.id)
			s.native.lib_catalog_result_ids = ids
			s.native.lib_catalog_results = not ids.is_empty()
			if not ids.is_empty() and phase == "evidence_gathering" and p.investigationOpened and p.catalogUnlocked and query.begins_with("三分钟离座法"): p.catalogSearchCompleted = true
			return _ok("找到 %s 条馆藏记录。" % ids.size() if not ids.is_empty() else "没有匹配的馆藏，请检查题名。")
		"lib_catalog_select":
			if phase != "evidence_gathering" or not p.catalogSearchCompleted or p.callNumberCollected: return _ok("还没有经过核验的馆藏搜索记录。")
			if str(value) != "three-minute-leave-method":
				for r in _data().get("library",{}).get("catalogResults",[]):
					if r.id == str(value): return _ok(r.note)
				return _ok("没有找到该馆藏条目。")
			p.callNumberCollected = true
			items.callNumber755 = true
			_unique(p.clueIds,"call_number_755")
			_request_story(s,"library_catalog_match_found")
			return _ok("获得索书号 I247.55 / 755。")
		"lib_shelf":
			if phase != "evidence_gathering" or not p.callNumberCollected or not items.callNumber755 or p.archivedRuleCollected or s.native.scene != "library_interior": return _ok("书架夹层需要对应的索书号。")
			p.archivedRuleCollected = true
			items.callNumber755 = false
			items.archivedLeaveRule = true
			_unique(p.libraryVisitedPoints,"shelf_755")
			_unique(p.clueIds,"archived_leave_rule")
			return _go(s,"library_rule","夹层打开，获得旧版离座规则。")
		"lib_read_rule":
			if phase != "evidence_gathering" or not p.archivedRuleCollected: return _ok("先找回旧版规则。")
			if p.archivedRuleRead: return _ok("")
			p.archivedRuleRead = true
			_unique(p.clueIds,"three_proof_requirements")
			_request_story(s,"library_archived_rule_recovered")
			return _ok("")
		"lib_photo":
			if phase != "evidence_gathering" or not p.backpackInspected or not p.investigationOpened or s.native.scene != "library_interior": return _ok("先确认调查对象，再在书包附近拍照。")
			p.photoCaptured = true
			return _go(s,"photos","已保存 IMG_0755.JPG。")
		"lib_dim_photo":
			if phase != "evidence_gathering" or not p.photoCaptured: return _ok("还没有书包照片。")
			if float(s.ui.brightness) > 20: return _ok("标签依然曝光过度。")
			p.photoDimmed = true
			return _ok("标签可读了：对象类型为书包，本人属性不成立。")
		"lib_photo_filter":
			if str(value) not in ["recent","campus_life"]: return _ok("没有这个相册分类。")
			s.native.lib_photo_filter = str(value)
			s.native.lib_selected_photo = ""
			return _ok("")
		"lib_view_photo":
			if not p.photoCaptured: return _ok("先拍摄 022 书包。")
			var photo_data = JSON.parse_string(FileAccess.get_file_as_string("res://data/native_phone_photos.json"))
			for photo in photo_data:
				if photo.id == str(value):
					s.native.lib_selected_photo = str(value)
					return _go(s,"photos")
			return _ok("找不到这张相片。")
		"lib_close_photo":
			s.native.lib_selected_photo = ""
			return _ok("")
		"lib_item_report":
			if phase != "evidence_gathering" or not p.photoCaptured or not p.photoDimmed or p.itemReportGenerated: return _ok("需要清晰可读的标签才能识别。")
			if s.native.get("lib_selected_photo","") != "seat_022_clue": return _ok("找到同一只 022 书包的旧照，核对半包纸出现的时间。")
			p.itemReportGenerated = true
			p.lostFoundStage = "ready"
			items.itemRecognitionReport = true
			return _ok("获得物品识别报告。")
		"lib_front_desk":
			if s.native.scene!="library_interior": return _ok("需要靠近前台。")
			_unique(p.libraryVisitedPoints,"front_desk")
			if not p.archivedRuleRead: return _ok("前台正在整理失物记录，目前没有需要办理的材料。")
			if not p.nonPersonProofStamped and not p.frontDeskProofRequestSeen:
				_request_story(s,"library_front_desk_proof_request"); return _ok("")
			if p.frontDeskProofRequestSeen and not p.itemReportGenerated:
				var hints: Array=["前台：请出示物品识别报告。","玩家：我用肉眼看不行吗？","前台：肉眼不是本部门认可设备。","系统：你看，眼睛又输了。"]
				var index: int=clampi(front_desk_hint_index,0,hints.size()-1)
				front_desk_hint_index=mini(index+1,hints.size()-1)
				return _ok(hints[index])
			if int(p.nonPersonProofStamped)+int(p.seatReceiptCollected)+int(p.presenceProofCollected)>=3: return _ok("三项证明已齐，上传给大家看看。")
			return _ok({"missing_report":"前台：先在照片页面生成物品识别报告，再拿来核验。","ready":"前台：把物品识别报告递到柜台上，我核验后盖章。","scanning":"前台正在核对报告，请等她完成盖章。","stamped":"前台：非本人证明已经盖好，继续补齐另外两项材料。"}.get(p.lostFoundStage,""))
		"lib_scan":
			if phase != "evidence_gathering" or not items.itemRecognitionReport or not p.itemReportGenerated or p.nonPersonProofStamped or s.native.scene != "library_interior": return _ok("盖章机需要物品识别报告。")
			p.lostFoundStage = "scanning"
			return _ok("",{"game":{"script":"res://scripts/games/identity_stamp.gd","on_success":"lib_scan_result","title":"物品身份盖章机","viewport":[430,820]}})
		"lib_scan_result":
			if phase != "evidence_gathering" or p.lostFoundStage != "scanning" or not items.itemRecognitionReport or not value is Dictionary: return _ok("没有有效扫描任务。")
			if float(value.get("scanMs",0)) < 720 or value.get("identityChecks",[]) != [false,false,false] or not value.get("stamped",false): return _ok("扫描或盖章未完成。")
			p.nonPersonProofStamped = true
			p.lostFoundStage = "stamped"
			_unique(p.libraryVisitedPoints,"lost_found")
			items.itemRecognitionReport = false
			items.bagNonPersonProof = true
			_request_story(s,"library_bag_nonperson_proof_issued",900)
			return _ok("获得书包非本人证明。")
		"lib_receipt":
			if s.native.scene != "library_interior" or not items.rightArrow or p.seatReceiptCollected: return _ok("手指够不到夹缝里的小票。")
			p.seatReceiptCollected = true
			items.rightArrow = false
			items.seat022Receipt = true
			_unique(p.libraryVisitedPoints,"seat_022")
			return _ok("右移箭头把小票推出夹缝。获得 022 座位小票。")
		"lib_audit":
			if s.networkMode != "cellular": return _ok("浙大体艺需要移动数据。")
			if phase != "evidence_gathering" or not p.investigationOpened or not p.entranceRecordRead or not p.archivedRuleRead or p.presenceProofCollected: return _ok("缺少门禁记录、论坛公示或旧版规则。")
			if value is Dictionary: value = [str(value.get("arrival","")),str(value.get("notice","")),str(value.get("proofs",""))]
			var parts: Array = value if value is Array else Array(str(value).replace("/"," ").replace(","," ").replace("，"," ").split(" ",false))
			p.auditAttemptCount += 1
			if parts.size() != 3 or str(parts[0]) != "7" or str(parts[1]) != "47" or str(parts[2]) != "3":
				return _ok("补录参数与原始记录不一致。" if p.auditAttemptCount == 1 else "三项分别对应到座耗时、公示编号和旧规的证明数量。" if p.auditAttemptCount == 2 else "请重新核对门禁时间、CC98 楼主编辑与规则原件。")
			p.auditArrivalMinutes = 7
			p.auditPublicNoticeFloor = 47
			p.auditProofCount = 3
			p.presenceProofCollected = true
			items.libraryPresenceProof = true
			_request_story(s,"tiyi_presence_proof_issued")
			return _ok("")
		"lib_upload":
			var e = str(value)
			if phase != "evidence_gathering" or not EVIDENCE.has(e) or not items.get(EVIDENCE.get(e,""),false) or p.cc98UploadedEvidenceIds.has(e): return _ok("需要未上传的有效证据原件。")
			if e == "archived_leave_rule" and not p.archivedRuleRead: return _ok("先阅读旧版规则。")
			p.cc98UploadedEvidenceIds.append(e)
			if e == "archived_leave_rule": items.archivedLeaveRule = false
			if _all(p.cc98UploadedEvidenceIds,EVIDENCE.keys()):
				s.ui.libraryFinalsPhase = "bd_briefing"
				_request_story(s,"cc98_evidence_set_completed")
			return _ok("证据已加入公开记录。")
		"lib_bd_briefing":
			if phase != "bd_briefing" or not _all(p.cc98UploadedEvidenceIds,EVIDENCE.keys()): return _ok("四项证据尚未齐全。")
			_request_story(s,"cc98_evidence_set_completed")
			return _ok("")
		"lib_bd_select":
			if phase != "top_ten_rising" or not p.preBdBriefingSeen or not _all(p.cc98UploadedEvidenceIds,EVIDENCE.keys()): return _ok("公开确认尚未开放。")
			var valid = false
			for r in _data().get("cc98",{}).get("bdPassword",{}).get("posts",[]):
				if str(value) == r.id: valid = true
			if not valid or p.bdSelectedPostIds.has(str(value)) or p.bdSelectedPostIds.size() >= 4: return _ok("请选择四条不同的数字回复；可以撤回。")
			p.bdSelectedPostIds.append(str(value))
			return _ok("bd 已写入口令。")
		"lib_bd_undo":
			if phase != "top_ten_rising" or p.bdSelectedPostIds.is_empty(): return _ok("没有可撤回的 bd。")
			p.bdSelectedPostIds.pop_back()
			return _ok("最后一项已撤回。")
		"lib_bd_submit":
			if phase != "top_ten_rising" or not p.preBdBriefingSeen or not _all(p.cc98UploadedEvidenceIds,EVIDENCE.keys()) or p.bdSelectedPostIds.size() != 4: return _ok("口令需要四项，且四项证据必须齐全。")
			p.bdPasswordAttemptCount += 1
			if p.bdSelectedPostIds != BD_IDS:
				p.bdSelectedPostIds.clear()
				return _ok("数字的来源或顺序不匹配。" if p.bdPasswordAttemptCount == 1 else "按上传栏从上到下匹配证据对应的数字，不要混入公示号、索书号或排名。")
			p.bdCount = 3
			p.appliedBdReplyIds = ["reply-seat-ticket","reply-visit-proof","reply-bag-nonperson"]
			s.ui.libraryFinalsPhase = "top_ten_reached"
			_request_story(s,"cc98_top_ten_reached")
			return _ok("")
		"lib_recovery_open":
			if phase != "top_ten_reached" or p.bdCount != 3: return _ok("需要先完成公开确认。")
			s.ui.libraryFinalsPhase = "recovery_application"
			return _go(s,"library_recovery")
		"lib_recovery_upload":
			var e = str(value)
			if phase != "recovery_application" or not RECOVERY.has(e) or not items.get(EVIDENCE.get(e,""),false) or p.recoverySubmittedEvidenceIds.has(e): return _ok("申请需要相应证明原件。")
			p.recoverySubmittedEvidenceIds.append(e)
			items[EVIDENCE[e]] = false
			return _ok("申请材料已收取；原件内容仍可从提交记录查看。")
		"lib_generate_pass":
			if phase != "recovery_application" or not _all(p.recoverySubmittedEvidenceIds,RECOVERY) or p.evictionPassGenerated: return _ok("三项申请材料尚未齐全。")
			p.evictionPassGenerated = true
			items.seatReleasePass = true
			s.ui.libraryFinalsPhase = "pass_ready"
			_request_story(s,"library_seat_release_pass_issued")
			return _ok("")
		"lib_apply_pass":
			if phase != "pass_ready" or not p.evictionPassGenerated or not items.seatReleasePass or s.native.scene != "library_interior": return _ok("书包只接受有效的解除占座 PASS。")
			p.backpackEvicted = true
			items.seatReleasePass = false
			s.ui.libraryFinalsPhase = "backpack_removed"
			_request_story(s,"library_backpack_evicted")
			return _ok("")
		"lib_sit":
			if phase != "backpack_removed" or not p.backpackEvicted or s.native.scene != "library_interior": return _ok("座位仍被占用。")
			p.playerSeated = true
			s.ui.librarySelectedSeat = "022"
			s.ui.librarySeatReserved = true
			s.ui.libraryFinalsPhase = "seat_recovered"
			s.native.lib_dialogue_index = 0
			return _go(s,"library_022_dialogue")
		"lib_dialogue_open":
			if not p.playerSeated: return _ok("先坐到 022。")
			return _go(s,"library_022_dialogue")
		"lib_dialogue_next":
			# The opening host owns advance/skip; legacy phone intents cannot grant
			# the chapter or omit the authored transition beats.
			if not SceneSession.pending_opening(s): return _ok("没有新的 022 会话。")
			scene_session(s)
			return _ok("")
		"lib_opening_complete":
			if not value is SceneSession or value != opening_session or value.kind != "opening" or not value.consume(s): return _ok("022 转场尚未完成。")
			p.nextQuestId = "chapter_three_canteen_hunt"
			_unique(p.clueIds,"borrowed_attendance_record")
			s.ui.libraryFinalsPhase = "friend_contacted"
			_unique(s.ui.seenChapterIntros,"chapter_three")
			# LibraryFinalsController.complete022Dialogue starts a fresh hunt.
			var initial: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/initial_state.json"))
			s.canteenHunt = initial.canteenHunt.duplicate(true)
			s.canteenHunt.active = true
			s.canteenHunt.phase = "tracking"
			s.native.chapter = 3
			s.native.page = "phone_home"
			s.currentScene = "phone_home"
			s.rpgCheckpoint = "campus_library_gate"
			return _world(s,"campus_bootstrap","")

	return _ok("当前阶段没有这个操作。")

func _password_display(ids: Array) -> String:
	var digits: Array = []
	for id in ids:
		for r in _data().get("cc98",{}).get("bdPassword",{}).get("posts",[]):
			if r.id == id: digits.append(str(r.digit))
	while digits.size() < 4: digits.append("□")
	return " ".join(digits)

func objective(s: Dictionary) -> String:
	var p = _p(s)
	match _phase(s):
		"idle", "library_route_unlocked": return "前往基础图书馆寻找系统的朋友"
		"library_entered": return "前往一层书库寻找 022" if p.entranceRecordRead else "读取图书馆入馆记录"
		"occupied_seat_found": return "检查 022 书包旁的纸条"
		"evidence_gathering":
			if not p.investigationOpened: return "用占座纸条调查 CC98"
			if not p.archivedRuleRead: return "找到并阅读旧版离座规则"
			return "补齐座位恢复证明，并加入 CC98 公开记录（%s / 4）" % p.cc98UploadedEvidenceIds.size()
		"bd_briefing", "top_ten_rising": return "根据已上传证据核验数字回复"
		"top_ten_reached", "recovery_application": return "向图书馆提交座位恢复申请"
		"pass_ready": return "把解除占座 PASS 用在 022 书包上"
		"backpack_removed": return "坐到恢复的 022 座位"
		"seat_recovered": return "与 022 交谈"
	return ""

func targets(scene: String, s: Dictionary) -> Array:
	if not _active(s): return []
	if story_session(s)!=null: return []
	if scene == "campus_bootstrap":
		var path = "res://data/source/maps/zijingang-campus-runtime.json"
		var map: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else {}
		var gate: Dictionary = map.get("libraryGate",{"x":2600,"y":2100,"radius":160})
		return [{"id":"library_gate","label":"进入基础图书馆","position":[gate.x,gate.y],"radius":gate.radius,"action":"lib_enter"}]
	if scene != "library_interior": return []
	if SceneSession.pending_opening(s): return []
	var p = _p(s)
	var out: Array = [{"id":"library_exit","label":"离开图书馆","position":[715,842],"radius":72.0,"action":"lib_exit"}]
	out.append(_target("entrance_record","查看入馆记录",[750,727],[673,693,154,68],64,"lib_open_record"))
	out.append(_target("front_desk","前台工作人员",[334,594],[174,519,320,150],64,"lib_front_desk"))
	out.append(_target("catalog_terminal","馆藏检索终端",[653,555],[597,507,112,96],70,"lib_catalog_terminal"))
	if p.itemReportGenerated and not p.nonPersonProofStamped: out.append(_target("identity_machine","物品身份盖章机",[334,594],[174,519,320,150],64,"lib_scan","itemRecognitionReport"))
	if p.callNumberCollected and not p.archivedRuleCollected: out.append(_target("library_shelf_755","文学书架夹层",[548,230],[486,125,124,210],64,"lib_shelf","callNumber755"))
	if p.entranceRecordRead and not p.backpackInspected: out.append(_target("backpack","检查占座书包",[1255,407],[1237,375,36,64],100,"lib_backpack"))
	if p.backpackInspected and not p.occupancyNoteCollected: out.append(_target("occupancy_note","拿起占座纸条",[1282,422],[1261,406,42,32],80,"lib_note"))
	if p.investigationOpened and not p.photoCaptured: out.append(_target("bag_photo","拍摄书包标签",[1255,407],[1237,375,36,64],120,"lib_photo"))
	if not p.seatReceiptCollected: out.append(_target("seat_022_gap","桌面夹缝",[1368,445],[1335,422,66,46],56,"lib_receipt","rightArrow"))
	if _phase(s) == "pass_ready": out.append(_target("backpack_pass","对书包使用解除占座 PASS",[1255,407],[1237,375,36,64],100,"lib_apply_pass","seatReleasePass"))
	if p.backpackEvicted: out.append(_target("seat_022_chair","与 022 交谈" if p.playerSeated else "坐到 022",[1302,500],[1262,468,80,64],56,"lib_dialogue_open" if p.playerSeated else "lib_sit"))
	return out

func _target(id: String, label: String, position: Array, bounds: Array, radius: float, action: String, item: String = "") -> Dictionary:
	var t = {"id":id,"label":label,"position":position,"bounds":bounds,"radius":radius,"action":action}
	if action in ["lib_note","lib_shelf","lib_photo","lib_scan","lib_receipt","lib_apply_pass","lib_sit"]: t.mode = "light"
	if not item.is_empty():
		t.item = item
		t.mode = "light"
	return t
