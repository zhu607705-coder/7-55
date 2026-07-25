extends Node

signal command_received(command: String, payload: Dictionary)
signal bridge_ready()

const PROTOCOL_VERSION := 1
const REACT_SOURCE := "seven-fifty-five-react"
const GODOT_SOURCE := "seven-fifty-five-godot"

var _window: JavaScriptObject
var _json: JavaScriptObject
var _message_callback: JavaScriptObject
var _web_enabled := false


func _ready() -> void:
	_web_enabled = OS.has_feature("web")
	if _web_enabled:
		_window = JavaScriptBridge.get_interface("window")
		_json = JavaScriptBridge.get_interface("JSON")
		_message_callback = JavaScriptBridge.create_callback(_on_window_message)
		_window.addEventListener("message", _message_callback)
		post_message("ready", {
			"protocolVersion": PROTOCOL_VERSION,
			"engine": Engine.get_version_info()
		})
	else:
		print("[GodotBridge] native/headless mode; browser bridge disabled")
	bridge_ready.emit()


func _exit_tree() -> void:
	if _web_enabled and _window != null and _message_callback != null:
		_window.removeEventListener("message", _message_callback)


func post_message(message_type: String, payload: Dictionary = {}) -> void:
	if not _web_enabled:
		return
	var envelope := {
		"source": GODOT_SOURCE,
		"type": message_type,
		"payload": payload
	}
	var encoded := JSON.stringify(envelope)
	JavaScriptBridge.eval("window.parent.postMessage(%s, '*');" % encoded, true)


func post_snapshot(snapshot: Dictionary) -> void:
	post_message("snapshot", snapshot)


func post_event(event_name: String, payload: Dictionary = {}) -> void:
	post_message("event", {
		"name": event_name,
		"payload": payload
	})


func _on_window_message(arguments: Array) -> void:
	if arguments.is_empty() or _json == null:
		return
	var event: JavaScriptObject = arguments[0]
	if event == null:
		return
	var serialized: Variant = _json.stringify(event.data)
	var decoded: Variant = JSON.parse_string(str(serialized))
	if not decoded is Dictionary:
		return
	var message: Dictionary = decoded
	if message.get("source", "") != REACT_SOURCE:
		return
	var message_type := str(message.get("type", ""))
	var raw_payload: Variant = message.get("payload", {})
	var payload: Dictionary = raw_payload if raw_payload is Dictionary else {}
	if message_type == "hydrate":
		var raw_state: Variant = payload.get("state", {})
		if raw_state is Dictionary:
			MigrationState.hydrate(raw_state)
	command_received.emit(message_type, payload)
