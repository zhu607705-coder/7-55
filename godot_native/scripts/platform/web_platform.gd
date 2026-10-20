extends Node
## Browser capabilities only. State remains the sole save/progression authority.
signal import_finished(message: String)
const IMPORT_PATH := "user://web-save-import.json"
const EXPORT_PATH := "user://web-save-export.json"
const MAX_SAVE_BYTES := 48 * 1024 * 1024
const SNAPSHOT_INTERVAL := 0.25
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
			dispose: () => {
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
	_publish_snapshot()

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
	_snapshot_left -= delta
	if _snapshot_left <= 0:
		_snapshot_left = SNAPSHOT_INTERVAL
		_publish_snapshot()

func _publish_snapshot() -> void:
	if _browser != null: _browser.publish(JSON.stringify(read_snapshot()))

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
	return {"engine": "Godot", "version": Engine.get_version_info().string, "web": OS.has_feature("web"), "documentHidden": _document_hidden, "content": content, "persistentStorageAvailable": OS.is_userfs_persistent(), "state": state.d.duplicate(true), "visibleControls": controls, "activeGame": game, "world": world, "phoneRect": _rect(shell.phone.get_global_rect()), "viewport": _rect(shell.get_viewport_rect()), "audio": audio, "video": video, "saveDigest": save.sha256_text() if not save.is_empty() else "", "developerToolsAvailable": state.developer_tools_available()}

func _exit_tree() -> void:
	if _browser != null: _browser.dispose()
	_browser = null
	_file_callback = null
	_visibility_callback = null
