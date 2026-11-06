extends "res://scripts/platform/cloud_saves.gd"
signal persist_released
var hold_persist := false
var persist_waiting := false
var pending_value := false
var uploads := 0
var uploaded_bundles: Array = []
var failures: Array = []
func _ready() -> void:
	set_process(false)
	get_tree().root.get_node("State").snapshot_saved.connect(_mark_dirty)
func _set_transport_pending(value: bool) -> void:
	pending_value = value
func _set_status(value: String) -> void:
	status_text = value
func _failure(result: Dictionary, _allow_guest: bool = false) -> void:
	failures.append(result.duplicate(true))
	_set_status("同步失败")
func _persist(_captured: Dictionary) -> bool:
	if hold_persist:
		persist_waiting = true
		await persist_released
		persist_waiting = false
	return true
func _upload(captured: Dictionary, kind: String = "save") -> Dictionary:
	uploads += 1
	uploaded_bundles.append(captured.bundle.duplicate(true))
	_pending = {"kind": kind, "input": {"bundle": captured.bundle.duplicate(true)}}
	return {"ok": true, "data": {"revision": uploads, "current": {"digest": _digest(captured.bundle), "savedAt": "2026-11-06T00:00:00Z"}}}
