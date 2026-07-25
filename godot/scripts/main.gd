extends Node2D

const CAMPUS_RUNTIME_SCRIPT := preload("res://scripts/campus_runtime.gd")

var _campus_runtime


func _ready() -> void:
	_ensure_input_actions()
	_campus_runtime = Node2D.new()
	_campus_runtime.name = "CampusRuntime"
	_campus_runtime.set_script(CAMPUS_RUNTIME_SCRIPT)
	add_child(_campus_runtime)
	WebBridge.command_received.connect(_on_bridge_command)


func _on_bridge_command(command: String, payload: Dictionary) -> void:
	if command == "set_paused":
		var paused := bool(payload.get("paused", false))
		_campus_runtime.process_mode = Node.PROCESS_MODE_DISABLED if paused else Node.PROCESS_MODE_INHERIT


func _ensure_input_actions() -> void:
	_ensure_key_action("move_left", [KEY_A, KEY_LEFT])
	_ensure_key_action("move_right", [KEY_D, KEY_RIGHT])
	_ensure_key_action("move_up", [KEY_W, KEY_UP])
	_ensure_key_action("move_down", [KEY_S, KEY_DOWN])
	_ensure_key_action("move_run", [KEY_SHIFT])


func _ensure_key_action(action: StringName, keycodes: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.2)
	for keycode in keycodes:
		var event := InputEventKey.new()
		event.physical_keycode = int(keycode)
		if not InputMap.action_has_event(action, event):
			InputMap.action_add_event(action, event)
