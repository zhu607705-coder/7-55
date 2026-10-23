extends Node
## Presentation-only content availability. Never changes State, quests or saves.
signal blocking_changed(blocking: bool)
signal content_changed
const FAMILIES := ["chapter2", "chapter3", "chapter35", "chapter4", "campus_shared", "campus_chaoyang", "campus_haidian", "campus_changping"]
const STORY_FAMILIES := ["chapter2", "chapter3", "chapter35", "chapter4"]
const ReleaseContent = preload("res://scripts/release_content_policy.gd")
const Ui = preload("res://scripts/ui/native_ui_theme.gd")
var _host: Variant
var _callback: JavaScriptObject
var _enabled := false
var _fatal_error := ""
var _packs: Dictionary = {}
var _families: Dictionary = {}
var _waiters: Dictionary = {}
var _next_waiter := 0
var _blocking := false
var _prefetch_started := false
var _prefetch_families: Array = []
var _prefetch_window_set := false
var _prefetch_window_supported := false
var _overlay: CanvasLayer
var _cover: Control
var _card: PanelContainer
var _detail: Label
var _progress: ProgressBar
var _retry: Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not OS.has_feature("web"): return
	_host = JavaScriptBridge.get_interface("__GODOT_755_CONTENT_HOST__")
	if not _require_web_host(_host): return
	var supports_window: bool = bool(JavaScriptBridge.eval("typeof window.__GODOT_755_CONTENT_HOST__.setPrefetchFamilies === 'function'", true))
	JavaScriptBridge.eval("delete window.__GODOT_755_CONTENT_HOST__", true)
	var raw: Variant = JSON.parse_string(str(_host.manifest()))
	if not raw is Dictionary or not _configure_manifest(raw, _host, supports_window):
		_enabled = true
		_fatal_error = "游戏尚未准备完成，请重新加载页面后重试。当前进度已保留。"
		_show_fatal()
		return
	_callback = JavaScriptBridge.create_callback(_on_pack_received)
	_host.install(_callback)

func _require_web_host(host: Variant) -> bool:
	# A cached old HTML loader can receive a newly published core-only PCK.
	# Treating that combination as a complete monolithic Web export would allow
	# play with missing later resources. Only native keeps monolithic fallback.
	if host != null: return true
	_enabled = true
	_fatal_error = "页面需要更新，请重新加载后继续。当前进度已保留。"
	_show_fatal()
	return false

func _safe_file(value: Variant) -> bool:
	if not value is String or value.is_empty() or value.begins_with("/") or value.contains("\\") or value.contains(":") or value.contains("?") or value.contains("#"): return false
	for index: int in value.length():
		if value.unicode_at(index) < 32 or value.unicode_at(index) == 127: return false
	for part: String in value.split("/"):
		if part in ["", ".", ".."]: return false
	return true

func _valid_digest(value: Variant) -> bool:
	if not value is String or value.length() != 64: return false
	for character: String in value:
		if character not in "0123456789abcdef": return false
	return true

func _valid_file(record: Dictionary) -> bool:
	var bytes: Variant = record.get("bytes")
	return _safe_file(record.get("file")) and _valid_digest(record.get("sha256")) and typeof(bytes) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(bytes)) and float(bytes) == int(bytes) and int(bytes) > 0 and int(bytes) <= 1024 * 1024 * 1024

func _valid_id(value: Variant) -> bool:
	if not value is String or value.is_empty() or value.length() > 100: return false
	for character: String in value:
		if character not in "abcdefghijklmnopqrstuvwxyz0123456789_": return false
	return true

func _configure_manifest(value: Dictionary, host: Variant, supports_window: bool = false) -> bool:
	# Also exercised with an isolated transport in tests. No test hook is exposed
	# through the browser's read-only public observation surface.
	_enabled = true
	_fatal_error = "游戏资源目录无法读取，请重新打开页面。"
	if value.get("schema") != "755-web-content-v1" or not value.get("core") is Dictionary or not _valid_file(value.core) or not value.get("packs") is Array or not value.get("backgroundOrder") is Array: return false
	var packs: Dictionary = {}
	var families: Dictionary = {}
	var files: Dictionary = {str(value.core.file): true}
	for item: Variant in value.packs:
		if not item is Dictionary or not _valid_id(item.get("id")) or item.id == "core" or not ReleaseContent.family_available(item.get("family")) or not _valid_file(item) or packs.has(item.id) or files.has(item.file): return false
		packs[item.id] = {"id": item.id, "family": item.family, "file": item.file, "bytes": int(item.bytes), "sha256": item.sha256, "status": "missing", "error": ""}
		if not families.has(item.family): families[item.family] = []
		families[item.family].append(item.id)
		files[item.file] = true
	var seen: Dictionary = {}
	for family: Variant in value.backgroundOrder:
		if not ReleaseContent.family_available(family) or seen.has(family): return false
		seen[family] = true
	_packs = packs
	_families = families
	_host = host
	_prefetch_window_supported = supports_window or (host != null and not host is JavaScriptObject and host.has_method("setPrefetchFamilies"))
	_fatal_error = ""
	return true

static func required_families(snapshot: Dictionary) -> Array:
	# Earlier content remains available to old inventories, photo albums and
	# returns to prior scenes. This conservative dependency is intentional.
	var native: Dictionary = snapshot.get("native", {})
	var page := str(native.get("page", ""))
	var scene := str(native.get("scene", ""))
	var chapter: int = int(native.get("chapter", 1))
	var level: int = 4 if chapter >= 4 else 2 if chapter >= 3 else 1 if chapter >= 2 else 0
	if scene in ["dorm_hub", "campus_bootstrap", "library_interior"] or page.begins_with("library_"): level = maxi(level, 1)
	# Old imports may remember an app before updating the numeric chapter.
	# The first-chapter CC98 network notice itself still needs no later pack.
	if page=="photos" or (page in ["cc98","cc98_login"] and str(snapshot.get("actOne",{}).get("phase","prologue"))!="prologue"): level=maxi(level,1)
	if scene in ["canteen_interior", "theater_interior"] or page.begins_with("c3_"): level = maxi(level, 2)
	var lake: Dictionary = snapshot.get("qizhenLake", {})
	if scene in ["campus_qizhen_loop", "qizhen_lake"] or page.begins_with("c35_") or bool(lake.get("active", false)) or str(lake.get("phase", "inactive")) not in ["", "inactive"]: level = maxi(level, 3)
	# A player may leave the restored replay page for the phone home and then
	# reload. Main resumes this accepted replay independently of the saved page;
	# the controller issues its film without first changing native.chapter.
	var recovered: Dictionary = snapshot.get("chapterThreeInterlude", {})
	if lake.get("phase", "") == "complete" and recovered.get("phase", "") == "replay_ready" and bool(recovered.get("replayUnlocked", false)): level = 4
	if scene == "duan_yongping_temporal_maze" or page.begins_with("c4_") or bool(snapshot.get("chapter4", {}).get("prologueSeen", false)): level = 4
	return ["chapter2", "chapter3", "chapter35", "chapter4"].slice(0, level)

func _required_ids(families: Array) -> Array:
	var result: Array = []
	for family: Variant in families:
		for id: String in _families.get(str(family), []):
			if id not in result: result.append(id)
	return result

func _ids_ready(ids: Array) -> bool:
	for id: String in ids:
		if _packs[id].status != "ready": return false
	return true

func ready_for_state(snapshot: Dictionary) -> bool:
	return not _enabled or (_fatal_error.is_empty() and _ids_ready(_required_ids(required_families(snapshot))))

func ensure_state(snapshot: Dictionary) -> bool:
	var required := required_families(snapshot)
	var ready := await ensure_families(required)
	if ready and _enabled and _host != null:
		_set_prefetch_window(snapshot)
	return ready

static func next_prefetch_families(snapshot: Dictionary) -> Array:
	var required := required_families(snapshot)
	return [STORY_FAMILIES[required.size()]] if required.size() < STORY_FAMILIES.size() else []

func _set_prefetch_window(snapshot: Dictionary) -> void:
	# Old cached HTML/JS may accompany a newer core. Optional warming needs the
	# bounded-window capability; ordinary request/retry remains compatible.
	if not _prefetch_window_supported: return
	var next := next_prefetch_families(snapshot)
	if _prefetch_window_set and next == _prefetch_families: return
	_prefetch_window_set = true
	_prefetch_families = next
	_host.setPrefetchFamilies(JSON.stringify(next))

func ensure_families(families: Array) -> bool:
	# Admission precedes the native monolithic fallback as well: loading a Web
	# story-only PCK with a native editor binary must not reopen stripped content.
	for family: Variant in families:
		if not ReleaseContent.family_available(family): return false
	if not _enabled: return true
	if not _fatal_error.is_empty():
		_show_fatal()
		return false
	var ids := _required_ids(families)
	if _ids_ready(ids): return true
	_next_waiter += 1
	var token := _next_waiter
	_waiters[token] = ids.duplicate()
	_update_overlay()
	_request_missing(ids)
	while not _ids_ready(ids):
		await content_changed
		if not is_inside_tree(): return false
	_waiters.erase(token)
	_update_overlay()
	return true

func _request_missing(ids: Array) -> void:
	var wanted: Array = []
	for id: String in ids:
		if _packs[id].status != "missing": continue
		_packs[id].status = "requested"
		wanted.append(id)
	if not wanted.is_empty() and _host != null: _host.request(JSON.stringify(wanted))

func _expected_path(id: String) -> String:
	return "/755-content/" + str(_packs[id].sha256) + ".pck"

func _mount_pack(filename: String) -> bool:
	return ProjectSettings.load_resource_pack(filename, false)

func _on_pack_received(args: Array) -> void:
	if args.size() != 3 or not args[0] is String or not _packs.has(args[0]): return
	var id: String = args[0]
	var record: Dictionary = _packs[id]
	var already_ready: bool = record.status == "ready"
	var error := ""
	if not args[2] is String or not str(args[2]).is_empty(): error = "网络暂时不可用，请重试。"
	elif not args[1] is String or str(args[1]) != _expected_path(id): error = "资源位置校验失败，请重试。"
	else:
		var filename: String = args[1]
		var file := FileAccess.open(filename, FileAccess.READ)
		if file == null: error = "资源尚未下载完整，请重试。"
		else:
			var actual_bytes := file.get_length()
			file.close()
			if actual_bytes != int(record.bytes): error = "资源长度校验失败，请重试。"
			elif FileAccess.get_sha256(filename) != record.sha256: error = "资源内容校验失败，请重试。"
			elif not already_ready and not _mount_pack(filename): error = "资源暂时无法打开，请重试。"
	# A bad late duplicate is rejected for caching but cannot retire a mounted
	# pack that was already verified. Mount each accepted pack at most once.
	if not already_ready:
		_packs[id].status = "ready" if error.is_empty() else "error"
		_packs[id].error = error
	if _host != null: _host.acknowledge(id, error.is_empty(), error)
	_update_overlay()
	content_changed.emit()

func start_prefetch() -> void:
	if not _enabled or not _fatal_error.is_empty() or _prefetch_started or _host == null or not _prefetch_window_supported: return
	_prefetch_started = true
	var state := get_node_or_null("/root/State")
	_set_prefetch_window(state.d if state != null else {})
	_host.startPrefetch()

func is_blocking() -> bool:
	return _blocking

func read_snapshot() -> Dictionary:
	var packs: Array = []
	var ready_families: Array = []
	for id: String in _packs:
		var record: Dictionary = _packs[id]
		packs.append({"id": id, "family": record.family, "bytes": record.bytes, "status": record.status, "error": record.error})
	for family: String in _families:
		if _ids_ready(_families[family]): ready_families.append(family)
	var required := _waiting_ids()
	var total: int = 0
	var loaded: int = 0
	for id: String in required:
		total += int(_packs[id].bytes)
		if _packs[id].status == "ready": loaded += int(_packs[id].bytes)
	var retry_visible: bool = is_instance_valid(_retry) and _retry.is_visible_in_tree()
	var retry_rect: Rect2 = _retry.get_global_rect() if retry_visible else Rect2()
	return {"enabled": _enabled, "monolithic": not _enabled, "blocking": _blocking, "prefetchStarted": _prefetch_started, "prefetchFamilies": _prefetch_families.duplicate(), "manifestError": _fatal_error, "readyFamilies": ready_families, "requiredIds": required, "requiredBytes": total, "loadedBytes": loaded, "packs": packs, "retryVisible": retry_visible, "retryRect": {"x": retry_rect.position.x, "y": retry_rect.position.y, "width": retry_rect.size.x, "height": retry_rect.size.y}}.duplicate(true)

func _waiting_ids() -> Array:
	var result: Array = []
	for ids: Array in _waiters.values():
		for id: String in ids:
			if id not in result: result.append(id)
	return result

func _set_blocking(value: bool) -> void:
	if _blocking == value: return
	_blocking = value
	blocking_changed.emit(value)

func _build_overlay() -> void:
	if is_instance_valid(_overlay): return
	_overlay = CanvasLayer.new(); _overlay.layer = 200; _overlay.name = "RequiredContentLoading"; add_child(_overlay)
	_cover = Control.new(); _cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); _cover.mouse_filter = Control.MOUSE_FILTER_STOP; _overlay.add_child(_cover)
	var wash := ColorRect.new(); wash.color = Color("f3eddf"); wash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); wash.mouse_filter = Control.MOUSE_FILTER_IGNORE; _cover.add_child(wash)
	var margin := MarginContainer.new(); margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge: String in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + edge, 24)
	_cover.add_child(margin)
	var center := CenterContainer.new(); margin.add_child(center)
	_card = PanelContainer.new(); _card.add_theme_stylebox_override("panel", Ui.box(Color("fff9ec"), Color("b9b0a0"), 1, 12, Vector2(24, 24))); center.add_child(_card)
	var column := VBoxContainer.new(); column.add_theme_constant_override("separation", 18); _card.add_child(column)
	var font := preload("res://scripts/ui/native_typography.gd").body_font() as Font
	_card.theme = Ui.make_theme(font, 18, 18)
	var title := Label.new(); title.text = "正在准备下一段旅程"; title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; title.add_theme_color_override("font_color", Color("263c34")); column.add_child(title)
	_detail = Label.new(); _detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; _detail.add_theme_font_size_override("font_size", 15); _detail.add_theme_color_override("font_color", Color("52645b")); column.add_child(_detail)
	_progress = ProgressBar.new(); _progress.show_percentage = false; _progress.custom_minimum_size.y = 8; column.add_child(_progress)
	_retry = Button.new(); _retry.text = "重试"; _retry.custom_minimum_size.y = 48; Ui.apply_button(_retry); _retry.pressed.connect(_retry_required); column.add_child(_retry)
	_cover.resized.connect(_layout_overlay); _layout_overlay()

func _layout_overlay() -> void:
	if is_instance_valid(_card): _card.custom_minimum_size.x = maxf(0, minf(460, get_viewport().get_visible_rect().size.x - 48))

func _show_fatal() -> void:
	_build_overlay(); _overlay.show(); _set_blocking(true)
	_detail.text = _fatal_error; _progress.hide()
	_retry.text = "重新加载"; _retry.show(); _retry.grab_focus.call_deferred()

func _update_overlay() -> void:
	if not _fatal_error.is_empty():
		_show_fatal()
		return
	var needed := _waiting_ids()
	var missing := false
	for id: String in needed:
		if _packs[id].status != "ready": missing = true
	if not missing:
		if is_instance_valid(_overlay): _overlay.hide()
		_set_blocking(false)
		return
	_build_overlay(); _overlay.show(); _set_blocking(true)
	_progress.show(); _retry.text = "重试"
	var total := 0
	var loaded := 0
	var failed := false
	for id: String in needed:
		total += int(_packs[id].bytes)
		if _packs[id].status == "ready": loaded += int(_packs[id].bytes)
		if _packs[id].status == "error": failed = true
	_detail.text = ("网络或资源校验暂未完成，重试后将继续当前进度。\n" if failed else "稍等片刻，已准备的内容不会重复下载。\n") + "%.1f / %.1f MB" % [float(loaded) / 1000000.0, float(total) / 1000000.0]
	_progress.max_value = maxf(1, float(total)); _progress.value = float(loaded)
	_retry.visible = failed

func _retry_required() -> void:
	if not _fatal_error.is_empty():
		_reload_browser()
		return
	var ids: Array = []
	for id: String in _waiting_ids():
		if _packs[id].status != "error": continue
		_packs[id].status = "requested"; _packs[id].error = ""; ids.append(id)
	if not ids.is_empty() and _host != null: _host.retry(JSON.stringify(ids))
	_update_overlay()
	content_changed.emit()

func _reload_browser() -> void:
	# Explicit button action only; no automatic reload/retry loop. A native
	# focused test can exercise the fatal UI without invoking JavaScriptBridge.
	if OS.has_feature("web"): JavaScriptBridge.eval("window.location.reload()", true)
