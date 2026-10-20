extends Node
## Browser capabilities only. State remains the sole save/progression authority.
signal import_finished(message: String)
signal save_feedback(message: String)
const IMPORT_PATH := "user://web-save-import.json"
const EXPORT_PATH := "user://web-save-export.json"
const MAX_SAVE_BYTES := 48 * 1024 * 1024
const SNAPSHOT_INTERVAL := 0.25
const SAVE_SYNC_INTERVAL_MS := 500
const SAVE_ATTEMPT_MS := 20000
const MAX_SAVE_SYNC_REQUESTS := 40
var shell: Control
var state: Node
var _browser: JavaScriptObject
var _file_callback: JavaScriptObject
var _visibility_callback: JavaScriptObject
var _snapshot_left := 0.0
var _document_hidden := false
var _content_loading := false
var _suspended := false
var _hidden_audio: Array[Dictionary] = []
var _hidden_director: WeakRef
var _owns_director_pause := false
var _persistence_host: Variant
var _save_callback: JavaScriptObject
var _save_token := 0
var _save_digest := ""
var _save_observed_digest := ""
var _save_acknowledged_digest := ""
var _save_pending := false
var _save_error := ""
var _save_explicit := false
var _save_started_ms := 0
var _save_sync_requests := 0
var _save_last_sync_ms := 0

func setup(owner_shell: Control, owner_state: Node) -> void:
	shell = owner_shell
	state = owner_state
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not OS.has_feature("web"): return
	# Keep the transport private; the public surface can only read a fresh copy.
	# A callback cannot return a value across Godot's JS bridge, hence the cache.
	JavaScriptBridge.eval("""(() => {
		let snapshot = '{}';
		let input = null;
		let visibilityHandler = null;
		let saveWatch = null;
		let saveUncommitted = false;
		const beforeUnload = event => {
			if (!saveUncommitted) return;
			event.preventDefault(); event.returnValue = '';
		};
		window.addEventListener('beforeunload', beforeUnload);
		function cancelSaveWatch() {
			if (saveWatch && saveWatch.timer) clearTimeout(saveWatch.timer);
			if (saveWatch && saveWatch.timeout) clearTimeout(saveWatch.timeout);
			saveWatch = null;
		}
		Object.defineProperty(window, '__GODOT_755__', {
			configurable: true,
			value: Object.freeze({ snapshot: () => JSON.parse(snapshot) })
		});
		window.__GODOT_755_HOST__ = {
			publish: raw => { snapshot = raw; },
			install: receive => {
				input = document.createElement('input');
				input.type = 'file'; input.accept = '.json,application/json';
				input.id = 'godot-save-import'; input.hidden = true;
				input.addEventListener('change', () => {
					const file = input.files && input.files[0];
					if (!file) return;
					if (file.size > 48 * 1024 * 1024) { receive('', 'too_large'); return; }
					const reader = new FileReader();
					reader.onload = () => receive(String(reader.result), '');
					reader.onerror = () => receive('', 'read_error');
					reader.readAsText(file, 'UTF-8');
				});
				document.body.appendChild(input);
			},
			chooseFile: () => { input.value = ''; input.click(); },
			observeVisibility: receive => {
				visibilityHandler = () => receive(document.hidden);
				document.addEventListener('visibilitychange', visibilityHandler);
				visibilityHandler();
			},
			readLegacySave: index => {
				const keys = ['seven_fifty_five_state', 'seven_fifty_five_state_backup'];
				try { return index === 0 || index === 1 ? (localStorage.getItem(keys[index]) || '') : ''; }
				catch (_) { return ''; }
			},
			watchSave: (token, absolutePath, receive) => {
				cancelSaveWatch(); saveUncommitted = true;
				const watch = { token, timer: null, timeout: null, deadline: Date.now() + 20000 };
				saveWatch = watch;
				const current = () => saveWatch === watch;
				const fail = code => {
					if (!current()) return;
					cancelSaveWatch(); receive(token, null, code);
				};
				watch.timeout = setTimeout(() => fail('timeout'), 20000);
				if (!/^\\/userfs\\/(?:[^/]+\\/)*save\\.json$/.test(absolutePath) || absolutePath.split('/').includes('..')) { fail('invalid_path'); return; }
				if (typeof indexedDB === 'undefined') { fail('unavailable'); return; }
				async function read() {
					if (!current()) return;
					if (Date.now() >= watch.deadline) { fail('timeout'); return; }
					let db;
					try {
						db = await new Promise((resolve, reject) => {
							const request = indexedDB.open('/userfs');
							request.onupgradeneeded = () => { request.transaction.abort(); reject(new Error('missing_database')); };
							request.onsuccess = () => resolve(request.result);
							request.onerror = () => reject(request.error);
						});
						if (!current()) return;
						if (!db.objectStoreNames.contains('FILE_DATA')) throw new Error('missing_store');
						const value = await new Promise((resolve, reject) => {
							const tx = db.transaction('FILE_DATA', 'readonly');
							const request = tx.objectStore('FILE_DATA').get(absolutePath);
							tx.oncomplete = () => resolve(request.result);
							tx.onerror = tx.onabort = () => reject(tx.error || new Error('read_failed'));
						});
						if (!current()) return;
						if (value && value.contents != null) {
							const raw = value.contents;
							const bytes = ArrayBuffer.isView(raw) ? new Uint8Array(raw.buffer, raw.byteOffset, raw.byteLength) : raw instanceof ArrayBuffer ? new Uint8Array(raw) : null;
							if (!bytes || bytes.byteLength > 8 * 1024 * 1024) throw new Error('invalid_contents');
							// The native owner hashes the actual bytes. This also works on
							// ordinary HTTP, where WebCrypto is unavailable.
							receive(token, bytes, '');
						}
					} catch (_) { fail('read_failed'); return; }
					finally { if (db) db.close(); }
					if (current()) watch.timer = setTimeout(read, 100);
				}
				watch.timer = setTimeout(read, 0);
			},
			finishSave: (token, accepted) => {
				if (!saveWatch || saveWatch.token !== token) return;
				cancelSaveWatch(); if (accepted) saveUncommitted = false;
			},
			dispose: () => {
				cancelSaveWatch();
				window.removeEventListener('beforeunload', beforeUnload);
				if (input) input.remove();
				if (visibilityHandler) document.removeEventListener('visibilitychange', visibilityHandler);
				delete window.__GODOT_755__;
			}
		};
	})()""", true)
	_browser = JavaScriptBridge.get_interface("__GODOT_755_HOST__")
	JavaScriptBridge.eval("delete window.__GODOT_755_HOST__", true)
	_file_callback = JavaScriptBridge.create_callback(_on_browser_file)
	_browser.install(_file_callback)
	_visibility_callback = JavaScriptBridge.create_callback(_on_browser_visibility)
	_browser.observeVisibility(_visibility_callback)
	_save_callback = JavaScriptBridge.create_callback(_on_save_observation)
	_persistence_host = _browser
	_publish_snapshot()

func _current_save_digest() -> String:
	return FileAccess.get_sha256(state.SAVE_PATH) if state != null and FileAccess.file_exists(state.SAVE_PATH) else ""

func _force_save_sync() -> void:
	# Official Godot API requests a sync; only the independently observed backing
	# database bytes below constitute completion, rather than FileAccess.close().
	if OS.has_feature("web"): JavaScriptBridge.force_fs_sync()

func _request_save_sync(now_ms: int) -> void:
	# These are official sync requests, never a claim that IDB committed bytes.
	_save_sync_requests += 1
	_save_last_sync_ms = now_ms
	_force_save_sync()

func _advance_save_sync(now_ms: int) -> void:
	if not _save_pending or _persistence_host == null: return
	# Keep the original attempt and JS watchdog. Slow frames cannot turn this
	# into extra State writes, new tokens, or a continuously extended deadline.
	if now_ms - _save_started_ms >= SAVE_ATTEMPT_MS or _save_sync_requests >= MAX_SAVE_SYNC_REQUESTS: return
	if now_ms - _save_last_sync_ms >= SAVE_SYNC_INTERVAL_MS: _request_save_sync(now_ms)

func _begin_save_persistence(digest: String, explicit: bool = false) -> int:
	_save_token += 1
	_save_digest = digest
	_save_observed_digest = ""
	_save_pending = true
	_save_error = ""
	_save_explicit = _save_explicit or explicit
	_save_started_ms = Time.get_ticks_msec()
	_save_sync_requests = 0
	_save_last_sync_ms = _save_started_ms
	if explicit: save_feedback.emit("正在保存…")
	_request_save_sync(_save_started_ms)
	_persistence_host.watchSave(_save_token, ProjectSettings.globalize_path(state.SAVE_PATH), _save_callback)
	return _save_token

func _observe_save_digest(digest: String) -> void:
	# Do not retry a failed observation every frame. An explicit Save or a new
	# successful native write starts a fresh bounded attempt.
	if _persistence_host != null and not digest.is_empty() and digest != _save_digest:
		_begin_save_persistence(digest)

func _on_save_observation(args: Array) -> void:
	if args.size() != 3 or typeof(args[0]) not in [TYPE_INT, TYPE_FLOAT] or int(args[0]) != _save_token or not _save_pending: return
	var error := str(args[2])
	if not error.is_empty():
		_finish_save_persistence(false, error)
		return
	var bytes: PackedByteArray
	if args[1] is PackedByteArray: bytes = args[1]
	elif args[1] is JavaScriptObject and JavaScriptBridge.is_js_buffer(args[1]): bytes = JavaScriptBridge.js_buffer_to_packed_byte_array(args[1])
	else: return
	var hashing := HashingContext.new()
	hashing.start(HashingContext.HASH_SHA256)
	hashing.update(bytes)
	_save_observed_digest = hashing.finish().hex_encode()
	if _save_observed_digest == _save_digest: _finish_save_persistence(true, "")

func _finish_save_persistence(accepted: bool, error: String) -> void:
	_save_pending = false
	_save_error = error
	if accepted: _save_acknowledged_digest = _save_digest
	if _persistence_host != null: _persistence_host.finishSave(_save_token, accepted)
	if _save_explicit:
		save_feedback.emit("已保存" if accepted else "保存尚未完成，请重试或导出存档；暂时不要刷新页面。")
	_save_explicit = false

func request_save() -> void:
	if not state.save_game():
		save_feedback.emit("测试会话不覆盖正式存档")
		return
	var digest := _current_save_digest()
	if _persistence_host == null or digest.is_empty():
		save_feedback.emit("保存尚未完成，请重试或导出存档；暂时不要刷新页面。")
		return
	_begin_save_persistence(digest, true)

func read_save_persistence() -> Dictionary:
	return {"pending": _save_pending, "token": _save_token, "digest": _save_digest, "observedDigest": _save_observed_digest, "acknowledgedDigest": _save_acknowledged_digest, "error": _save_error, "startedMs": _save_started_ms, "syncRequests": _save_sync_requests, "lastSyncMs": _save_last_sync_ms}

func _on_browser_visibility(args: Array) -> void:
	if args.size() == 1 and args[0] is bool: _apply_visibility(args[0])

func _remember_audio(node: Node) -> void:
	if node is AudioStreamPlayer and node.has_stream_playback():
		var director: Node = shell.audio_director
		var prefix_paused: bool = is_instance_valid(director) and director.is_ancestor_of(node) and director._id_paused(str(node.get_meta("cue_id", "")))
		_hidden_audio.append({"player": weakref(node), "playback": weakref(node.get_stream_playback()), "manual_paused": node.stream_paused and not prefix_paused})
	for child: Node in node.get_children(): _remember_audio(child)

func _same_hidden_playback(record: Dictionary) -> AudioStreamPlayer:
	var player: AudioStreamPlayer = record.player.get_ref()
	var playback: AudioStreamPlayback = record.playback.get_ref()
	if not is_instance_valid(player) or player.is_queued_for_deletion() or playback == null or not player.has_stream_playback(): return null
	return player if player.get_stream_playback() == playback else null

func _apply_visibility(hidden: bool) -> void:
	_document_hidden = hidden
	_apply_suspension(hidden or _content_loading)

func set_content_loading(loading: bool) -> void:
	_content_loading = loading
	_apply_suspension(_document_hidden or loading)

func _apply_suspension(hidden: bool) -> void:
	if hidden == _suspended:
		# SceneTree resume may notify its audio players while another owner
		# (such as a hidden browser tab) still needs them paused.
		if hidden:
			for record: Dictionary in _hidden_audio:
				var player := _same_hidden_playback(record)
				if player != null: player.stream_paused = true
		_publish_snapshot()
		return
	_suspended = hidden
	if hidden:
		_hidden_audio.clear()
		_remember_audio(shell)
		var director: Node = shell.audio_director
		if is_instance_valid(director):
			_hidden_director = weakref(director)
			_owns_director_pause = director.pause_for_platform()
		# Deliver the existing cancellation/pause boundary before background time
		# can enter an audition fallback, charge session, or active pointer hold.
		shell.propagate_notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
		shell.propagate_notification(NOTIFICATION_WM_WINDOW_FOCUS_OUT)
		if is_instance_valid(shell.active_game) and shell.active_game.get_script().resource_path == "res://scripts/games/prologue_interception.gd": shell.active_game._pause()
		_release_browser_input()
		for record: Dictionary in _hidden_audio:
			var player := _same_hidden_playback(record)
			if player != null: player.stream_paused = true
	else:
		var director: Node = _hidden_director.get_ref() if _hidden_director != null else null
		if is_instance_valid(director) and _owns_director_pause: director.resume_from_platform()
		shell.propagate_notification(NOTIFICATION_APPLICATION_FOCUS_IN)
		shell.propagate_notification(NOTIFICATION_WM_WINDOW_FOCUS_IN)
		for record: Dictionary in _hidden_audio:
			var player := _same_hidden_playback(record)
			if player == null: continue
			var owner_paused: bool = is_instance_valid(director) and director.is_ancestor_of(player) and (director._platform_pause_at >= 0 or director._id_paused(str(player.get_meta("cue_id", ""))))
			player.stream_paused = bool(record.manual_paused) or owner_paused
		_hidden_audio.clear()
		_hidden_director = null
		_owns_director_pause = false
	# rAF may stop completely in the background. Publish this event's result
	# synchronously rather than presenting a stale cached foreground snapshot.
	_publish_snapshot()

func _release_browser_input() -> void:
	# Input's C++ release_pressed_events is not a public GDScript API. Release
	# the physical controls used by this runtime through the normal event port.
	for code: int in [KEY_W, KEY_A, KEY_S, KEY_D, KEY_Q, KEY_E, KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT, KEY_SPACE, KEY_ENTER, KEY_SHIFT]:
		if not Input.is_physical_key_pressed(code) and not Input.is_key_pressed(code): continue
		var event := InputEventKey.new()
		event.keycode = code; event.physical_keycode = code; event.pressed = false
		Input.parse_input_event(event)
	for action: StringName in InputMap.get_actions(): Input.action_release(action)

func request_import() -> void:
	if OS.has_feature("web") and _browser != null: _browser.chooseFile()

func legacy_save_available() -> bool:
	return _browser != null and (not str(_browser.readLegacySave(0)).is_empty() or not str(_browser.readLegacySave(1)).is_empty())

func import_legacy_save() -> Dictionary:
	if _browser == null: return {"ok": false, "message": "未找到原网页存档。"}
	for index: int in 2:
		var raw := str(_browser.readLegacySave(index))
		if raw.is_empty(): continue
		var result := import_text(raw)
		if result.get("ok", false):
			if index == 1: result.message = "已从原网页版备份恢复。\n" + str(result.message)
			return result
	return {"ok": false, "message": "原网页存档未通过校验，当前进度与原网页数据均已保留。"}

func export_save() -> Error:
	var error: Error = state.export_save(EXPORT_PATH)
	if error != OK: return error
	var bytes := FileAccess.get_file_as_bytes(EXPORT_PATH)
	DirAccess.remove_absolute(EXPORT_PATH)
	if OS.has_feature("web"):
		JavaScriptBridge.download_buffer(bytes, "7-55-godot-save.json", "application/json")
	return OK

func _on_browser_file(args: Array) -> void:
	if args.size() != 2: return
	if str(args[1]) == "too_large":
		import_finished.emit("文件过大，不是有效存档。")
		return
	if not str(args[1]).is_empty():
		import_finished.emit("无法读取存档文件，当前进度未改变。")
		return
	# The same bounded importer validates both native and legacy browser saves.
	# No browser callback can supply an action, checkpoint, or progression flag.
	import_finished.emit(str(import_text(str(args[0])).message))

func import_text(text: String) -> Dictionary:
	if text.to_utf8_buffer().size() > MAX_SAVE_BYTES:
		return {"ok": false, "message": "文件过大，不是有效存档。"}
	var file := FileAccess.open(IMPORT_PATH, FileAccess.WRITE)
	if file == null: return {"ok": false, "message": "无法读取存档文件，当前进度未改变。"}
	file.store_string(text)
	file.close()
	var result: Dictionary = state.import_save(IMPORT_PATH)
	DirAccess.remove_absolute(IMPORT_PATH)
	return result

func storage_note() -> String:
	if not OS.is_userfs_persistent(): return "浏览器未提供持久存储；请导出存档以保留进度。"
	return "进度保存在当前浏览器中；清理网站数据会移除存档，可导出备份。"

func download_picture(image: Image) -> void:
	if OS.has_feature("web"): JavaScriptBridge.download_buffer(image.save_png_to_buffer(), "7-55-screenshot.png", "image/png")

func _process(delta: float) -> void:
	if not OS.has_feature("web") or _browser == null: return
	_advance_save_sync(Time.get_ticks_msec())
	_snapshot_left -= delta
	if _snapshot_left <= 0:
		_snapshot_left = SNAPSHOT_INTERVAL
		_publish_snapshot()

func _publish_snapshot() -> void:
	if _browser != null:
		_observe_save_digest(_current_save_digest())
		_browser.publish(JSON.stringify(read_snapshot()))

func _rect(value: Rect2) -> Dictionary:
	return {"x": value.position.x, "y": value.position.y, "width": value.size.x, "height": value.size.y}

func _json_value(value: Variant) -> Variant:
	if value is Vector2 or value is Vector2i: return {"x": value.x, "y": value.y}
	if value is Vector3 or value is Vector3i: return {"x": value.x, "y": value.y, "z": value.z}
	if value is Rect2: return _rect(value)
	if value is Dictionary:
		var result: Dictionary = {}
		for key: Variant in value: result[str(key)] = _json_value(value[key])
		return result
	if value is Array:
		var result: Array = []
		for item: Variant in value: result.append(_json_value(item))
		return result
	if value == null or value is bool or value is int or value is float or value is String: return value
	return null

func _properties(object: Object, names: Array) -> Dictionary:
	var result: Dictionary = {}
	if not is_instance_valid(object): return result
	for property: Dictionary in object.get_property_list():
		if property.name in names: result[property.name] = _json_value(object.get(property.name))
	return result

func _control_rect(control: Control) -> Rect2:
	var rect := control.get_global_rect()
	if control.get_viewport() == shell.world_viewport:
		var surface: Rect2 = shell.world_view.get_global_rect()
		var factor: Vector2 = surface.size / Vector2(shell.world_viewport.size)
		rect = Rect2(surface.position + rect.position * factor, rect.size * factor)
	return rect

func _visible_controls(node: Node, controls: Array, audio: Array, video: Array) -> void:
	if node is Control and node.is_visible_in_tree() and (node.get_viewport() != shell.world_viewport or shell.world_frame.is_visible_in_tree()) and (node is BaseButton or node is LineEdit or node is Label):
		var text := str(node.text) if node is Button or node is Label or node is LineEdit else ""
		controls.append({"name": str(node.name), "text": text, "type": node.get_class(), "rect": _rect(_control_rect(node)), "disabled": node.disabled if node is BaseButton else false})
	if node is AudioStreamPlayer:
		audio.append({"name": str(node.name), "playing": node.playing, "paused": node.stream_paused, "position": node.get_playback_position() if node.playing else 0.0, "stream": node.stream.resource_path if node.stream != null else "", "asset": str(node.get_meta("asset", "")), "cueId": str(node.get_meta("cue_id", "")), "channel": str(node.get_meta("channel", "")), "length": node.stream.get_length() if node.stream != null else 0.0})
	if node is VideoStreamPlayer:
		video.append({"name": str(node.name), "playing": node.is_playing(), "paused": node.paused, "position": node.stream_position, "stream": node.stream.resource_path if node.stream != null else ""})
	for child: Node in node.get_children(): _visible_controls(child, controls, audio, video)

func read_snapshot() -> Dictionary:
	var controls: Array = []
	var audio: Array = []
	var video: Array = []
	_visible_controls(shell, controls, audio, video)
	var game: Dictionary = {}
	if is_instance_valid(shell.active_game):
		var active: Control = shell.active_game
		game = _properties(active, ["phase", "elapsed", "blocks", "misses", "hold_ms", "paused", "dragging", "done", "dialogue_index", "display_scale", "field", "mode", "running", "chase_presentation_error"])
		game["script"] = active.get_script().resource_path
		game["rect"] = _rect(active.get_global_rect())
		if game.has("field"):
			var field: Rect2 = active.get("field")
			game["field"] = _rect(active.get_global_transform() * field)
		if active.get_script().resource_path == "res://scripts/games/prologue_interception.gd":
			game["session"] = _properties(active.session, ["phase", "board_x", "stage", "completed_stages", "total_misses", "reviewing", "cards", "collected", "hint"])
			game.session["missing"] = active.session.missing()
			game.session["current"] = active.session.current().duplicate(true)
		if active.get_script().resource_path == "res://scripts/ui/minigame_host.gd" and active.mode == "chase":
			game["model"] = _properties(active.model, ["status", "distance", "lane", "charge", "air_height", "air_velocity", "collisions", "tick"])
			if is_instance_valid(active.native_chase_view):
				var view: Control = active.native_chase_view
				game["nativeChaseView"] = _properties(view, ["ready3d", "presented", "failure_reason", "animation_seconds", "viewport_resolution"])
				game.nativeChaseView["heroPosition"] = _json_value(view.hero.position) if is_instance_valid(view.hero) else null
				game.nativeChaseView["meshInstances"] = view.viewport3d.find_children("*", "MeshInstance3D", true, false).size() if is_instance_valid(view.viewport3d) else 0
	var world: Dictionary = {}
	if is_instance_valid(shell.world):
		world = _properties(shell.world, ["scene_id", "player", "last_zone", "last_vehicle", "subtitle", "subtitle_left", "nearby"])
		world["visible"] = shell.world_frame.is_visible_in_tree()
		world["rect"] = _rect(shell.world_view.get_global_rect())
	var save := FileAccess.get_file_as_string(state.SAVE_PATH) if FileAccess.file_exists(state.SAVE_PATH) else ""
	var content: Dictionary = shell.get_node("/root/WebContent").read_snapshot()
	if content.get("retryVisible", false): controls.append({"name": "RetryRequiredContent", "text": "重试", "type": "Button", "rect": content.retryRect, "disabled": false})
	return {"engine": "Godot", "version": Engine.get_version_info().string, "web": OS.has_feature("web"), "documentHidden": _document_hidden, "content": content, "savePersistence": read_save_persistence(), "persistentStorageAvailable": OS.is_userfs_persistent(), "state": state.d.duplicate(true), "visibleControls": controls, "activeGame": game, "world": world, "phoneRect": _rect(shell.phone.get_global_rect()), "viewport": _rect(shell.get_viewport_rect()), "audio": audio, "video": video, "saveDigest": save.sha256_text() if not save.is_empty() else "", "developerToolsAvailable": state.developer_tools_available()}

func _exit_tree() -> void:
	if _browser != null: _browser.dispose()
	_browser = null
	_file_callback = null
	_visibility_callback = null
	_persistence_host = null
	_save_callback = null
	_save_token += 1
	_save_pending = false
