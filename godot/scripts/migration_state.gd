extends Node

signal state_changed(snapshot: Dictionary)

const STATE_VERSION := 1

var _state: Dictionary = {
	"version": STATE_VERSION,
	"runtimeMode": "rpg",
	"rpgScene": "campus_bootstrap",
	"rpgCheckpoint": "campus_spawn",
	"currentScene": "phone_home",
	"themeMode": "normal",
	"networkMode": "campus_wifi",
	"quest": {
		"id": "migration_bootstrap",
		"title": "Godot 迁移",
		"objective": "验证校园地图与人物控制",
		"completed": 0,
		"total": 1
	},
	"canteenHunt": {
		"active": false,
		"phase": "tracking",
		"mode": "light"
	}
}


func hydrate(next_state: Dictionary) -> void:
	_state = next_state.duplicate(true)
	_state["version"] = STATE_VERSION
	state_changed.emit(snapshot())


func merge_patch(patch: Dictionary) -> void:
	_deep_merge(_state, patch)
	_state["version"] = STATE_VERSION
	state_changed.emit(snapshot())


func snapshot() -> Dictionary:
	return _state.duplicate(true)


func value(key: String, fallback: Variant = null) -> Variant:
	return _state.get(key, fallback)


func _deep_merge(target: Dictionary, patch: Dictionary) -> void:
	for key in patch.keys():
		var incoming: Variant = patch[key]
		if incoming is Dictionary and target.get(key) is Dictionary:
			_deep_merge(target[key], incoming)
		else:
			target[key] = incoming
