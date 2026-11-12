extends AbstractSystem
## Domain controllers keep their authored dispatch order and proof validation.
## No dependency on State, Main, world nodes, UI or persistence callbacks.
signal navigation_changed(persist: bool)
var modules: Array = []
var d: Dictionary:
	get: return get_model("Progression").snapshot

func get_system_name() -> String: return "Chapters"
func init() -> void:
	for path in ["res://scripts/chapters/chapter4.gd", "res://scripts/chapters/chapter3.gd", "res://scripts/chapters/chapter1_2.gd"]:
		if ResourceLoader.exists(path):
			var script = load(path)
			if script and script.can_instantiate(): modules.append(script.new())

func dispatch(action: String, value: Variant = null) -> Dictionary:
	var data: Dictionary = get_model("Progression").snapshot
	if action != "lib_story_complete" and library_session() != null:
		return {"status": "locked", "result": {"handled": true, "message": ""}}
	if action not in ["c3_story_complete", "c3_promo_visual_complete", "c3_reversal_visual_complete", "c3_reversal_inspect_closed"] and narrative_session() != null:
		return {"status": "locked", "result": {"handled": true, "message": ""}}
	var previous := data.duplicate(true)
	for module in modules:
		if not module.has_method("dispatch"): continue
		var result: Dictionary = module.dispatch(data, action, value)
		if not result.is_empty():
			return {"status": "accepted", "previous": previous, "result": result}
	return {"status": "unhandled", "result": {"handled": false, "message": "这个操作暂时不可用。"}}

func library_session(delta_ms: float = 0) -> RefCounted:
	for module in modules:
		if module.get("library") != null:
			return module.library.story_session(get_model("Progression").snapshot, delta_ms)
	return null

func narrative_session(delta_ms: float = 0) -> RefCounted:
	for module in modules:
		if module.has_method("narrative_session"):
			return module.narrative_session(get_model("Progression").snapshot, delta_ms)
	return null

func query(kind: String, key: String = "") -> Variant:
	var data: Dictionary = get_model("Progression").snapshot
	if kind == "snapshot": return get_model("Progression").read_snapshot()
	var result: Array = []
	var seen: Dictionary = {}
	for module in modules:
		match kind:
			"pages", "actions":
				if not module.has_method(kind): continue
				var entries: Array = module.pages(data) if kind == "pages" else module.actions(key, data)
				for entry in entries:
					if entry is Dictionary and not seen.has(entry.get("id", "")):
						seen[entry.id] = true
						result.append(entry)
			"view":
				if module.has_method("view"):
					var view: Dictionary = module.view(key, data)
					if not view.is_empty(): return view.duplicate(true)
			"targets":
				if module.has_method("targets"): result.append_array(module.targets(key, data))
			"objective":
				if module.has_method("objective"):
					var text: String = module.objective(data)
					if not text.is_empty(): return text
	if kind == "view": return {"title": "7:55", "body": "请选择一个应用。"}
	if kind == "objective": return "调查被打散的签到记录。"
	return result.duplicate(true)

func lake_module() -> RefCounted:
	for module in modules:
		if module.get("lake")!=null: return module.lake
	return null

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

func get_phone_entry_session() -> RefCounted:
	for module in modules:
		if module.has_method("phone_entry_session"): return module.phone_entry_session(d)
	return null

func invalidate_progressive_activities() -> void:
	for module in modules:
		if module.has_method("invalidate_chest_mechanism"):
			module.invalidate_chest_mechanism()
		if module.has_method("invalidate_rehearsal_session"):
			module.invalidate_rehearsal_session()
		if module.has_method("invalidate_progressive_session"):
			module.invalidate_progressive_session()
	var lake = lake_module()
	if lake != null:
		lake.invalidate_logistics_session()
		lake.invalidate_fishing_session()

func open_page(page: String) -> void:
	if input_locked(): return
	if d.actOne.phase == "prologue" and d.flags.checkinDone and page != "ending": return
	invalidate_progressive_activities()
	# P10's revealed flower digit is local to its mounted page.
	if str(d.native.page)=="bonsai" and page!="bonsai": d.native.erase("flower_eight_visible")
	d.native.page = page
	get_phone_entry_session()
	var app := source_app(page)
	if not app.is_empty(): d.currentScene = app
	navigation_changed.emit(true)

func open_scene(scene: String) -> void:
	if input_locked(): return
	invalidate_progressive_activities()
	d.native.scene = scene
	d.rpgScene = scene
	d.runtimeMode = "rpg"
	navigation_changed.emit(true)

static func mode_switch_unlocked(snapshot: Dictionary) -> bool:
	# The 022 handoff advances the native chapter only after its session commits.
	return int(snapshot.get("native",{}).get("chapter",1)) >= 3

func toggle_mode() -> void:
	if not mode_switch_unlocked(d) or input_locked(): return
	invalidate_progressive_activities()
	d.native.mode = "dark" if d.native.mode == "light" else "light"
	d.themeMode = "dark" if d.native.mode == "dark" else "normal"
	d.chapter4.mode = d.native.mode
	d.canteenHunt.mode = d.native.mode
	d.theaterHunt.mode = d.native.mode
	d.qizhenLake.mode = d.native.mode
	navigation_changed.emit(true)

func select_item(id: String) -> void:
	if input_locked(): return
	if id.is_empty():
		d.native.selected_item = ""
		d.ui.selectedItem = null
		navigation_changed.emit(false)
		return
	if not d.items.get(id,false): return
	d.native.selected_item = id
	d.ui.selectedItem = id
	navigation_changed.emit(false)

func input_locked() -> bool:
	return library_session() != null or narrative_session() != null

func navigate(operation: String, value: String) -> void:
	match operation:
		"open_page": open_page(value)
		"open_scene": open_scene(value)
		"toggle_mode": toggle_mode()
		"select_item": select_item(value)
