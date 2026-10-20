extends SceneTree
## Isolated byte receipts, never real story progression or browser storage.
const Platform = preload("res://scripts/platform/web_platform.gd")
var checks := 0
var failures := 0
class FakeState extends Node:
	const SAVE_PATH := "user://receipt-unit-save.json"
	var bytes := PackedByteArray()
	var writes := 0
	func save_game() -> bool:
		writes += 1
		var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
		if file == null: return false
		file.store_buffer(bytes)
		file.close()
		return true
class FakeHost extends RefCounted:
	var requests: Array = []
	var completions: Array = []
	func watchSave(token: int, filename: String, _callback: Variant) -> void: requests.append({"token": token, "filename": filename})
	func finishSave(token: int, accepted: bool) -> void: completions.append({"token": token, "accepted": accepted})
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error("SAVE RECEIPT: " + message)
func digest(bytes: PackedByteArray) -> String:
	var hashing := HashingContext.new()
	hashing.start(HashingContext.HASH_SHA256)
	hashing.update(bytes)
	return hashing.finish().hex_encode()
func _initialize() -> void: call_deferred("run")
func run() -> void:
	# The runner must have its own user directory; refuse the canonical game save.
	if not load("res://tests/native_test_isolation.gd").is_isolated_save():
		push_error("SAVE_RECEIPT_TEST_ISOLATION_REQUIRED"); quit(2); return
	var state := FakeState.new()
	var bridge := Platform.new()
	var host := FakeHost.new()
	var messages: Array[String] = []
	bridge.state = state
	bridge._persistence_host = host
	bridge.save_feedback.connect(func(message: String): messages.append(message))
	var a := "first native save".to_utf8_buffer()
	var b := "next native save".to_utf8_buffer()
	state.bytes = a
	bridge.request_save()
	var first: Dictionary = bridge.read_save_persistence()
	check(state.writes == 1, "only the native State save API writes the file")
	check(first.pending and first.digest == digest(a), "explicit save binds the actual native bytes and starts pending")
	check(messages == ["正在保存…"], "memory write alone never announces saved")
	bridge._on_save_observation([first.token, b, ""])
	check(bridge._save_pending and bridge._save_acknowledged_digest.is_empty(), "old or mismatched disk bytes cannot acknowledge a write")
	check(messages == ["正在保存…"], "mismatched disk bytes preserve pending feedback")
	bridge._on_save_observation([first.token, a, ""])
	check(not bridge._save_pending and bridge._save_acknowledged_digest == digest(a), "matching actual-byte receipt completes")
	check(messages.back() == "已保存" and host.completions.back().accepted, "saved is emitted only after the exact receipt")
	state.bytes = b
	bridge.request_save()
	var second: Dictionary = bridge.read_save_persistence()
	check(second.token > first.token and second.pending, "consecutive writes receive distinct generations")
	bridge._on_save_observation([first.token, a, ""])
	bridge._on_save_observation([first.token, null, "timeout"])
	check(bridge._save_pending and bridge._save_digest == digest(b) and bridge._save_error.is_empty(), "old success and failure callbacks cannot claim or reject a newer save")
	var before_file := FileAccess.get_sha256(state.SAVE_PATH)
	bridge._on_save_observation([second.token, null, "timeout"])
	check(not bridge._save_pending and bridge._save_error == "timeout", "bounded transport timeout is a visible failure")
	check(messages.back() != "已保存" and not host.completions.back().accepted, "timeout cannot emit a false success")
	check(FileAccess.get_sha256(state.SAVE_PATH) == before_file and state.writes == 2, "receipt failure preserves native bytes without another State write")
	bridge.request_save()
	var retry: Dictionary = bridge.read_save_persistence()
	check(retry.token > second.token and retry.pending and retry.error.is_empty(), "explicit retry clears the failure with a fresh generation")
	bridge._on_save_observation([retry.token, b, ""])
	check(not bridge._save_pending and messages.back() == "已保存", "retry succeeds only with the new exact receipt")
	var requests_before := host.requests.size()
	var detached := bridge.read_save_persistence()
	detached.pending = true; detached.digest = "forged"
	check(not bridge.read_save_persistence().pending and bridge._save_digest == digest(b) and host.requests.size() == requests_before, "read-only snapshots are detached and trigger no I/O")
	bridge._observe_save_digest(digest(a))
	var automatic: Dictionary = bridge.read_save_persistence()
	var message_count := messages.size()
	check(automatic.pending and state.writes == 3, "automatic observation never adds another State save")
	bridge._observe_save_digest(digest(a))
	check(host.requests.size() == requests_before + 1, "unchanged file observations do not restart their bounded attempt")
	bridge._on_save_observation([automatic.token, a, ""])
	check(messages.size() == message_count and not bridge._save_pending, "automatic persistence acknowledgements stay silent")
	bridge._observe_save_digest(digest(b))
	var failing: Dictionary = bridge.read_save_persistence()
	bridge._on_save_observation([failing.token, null, "read_failed"])
	requests_before = host.requests.size()
	bridge._observe_save_digest(digest(b))
	check(host.requests.size() == requests_before and bridge._save_error == "read_failed", "failed observations do not retry every frame")
	bridge._observe_save_digest(digest(a))
	var last_token := bridge._save_token
	bridge._exit_tree()
	bridge._on_save_observation([last_token, a, ""])
	check(not bridge._save_pending and bridge._save_token > last_token and bridge._persistence_host == null, "exit invalidates callbacks and releases private transport references")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(state.SAVE_PATH))
	bridge.free(); state.free()
	print("Web save receipt ", "PASS" if failures == 0 else "FAIL", " ", checks, " checks")
	quit(0 if failures == 0 else 1)
