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
class SyncPlatform extends Platform:
	# Platform-only scheduling model: the first request may be lost. It does not
	# write a database or alter a game clock; runtime always passes real ticks.
	var official_requests := 0
	var release_after := 0
	var observed_bytes := PackedByteArray()
	func _force_save_sync() -> void:
		official_requests += 1
		if release_after > 0 and official_requests == release_after:
			observed_bytes = state.bytes.duplicate()
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
func verify_bounded_sync(state: FakeState) -> void:
	var bridge := SyncPlatform.new()
	var host := FakeHost.new()
	bridge.state = state; bridge._persistence_host = host
	var old := "older durable bytes".to_utf8_buffer()
	state.bytes = "latest native bytes after a lost sync request".to_utf8_buffer()
	bridge.observed_bytes = old; bridge.release_after = 2
	var writes_before := state.writes
	bridge.request_save()
	var first: Dictionary = bridge.read_save_persistence()
	check(first.syncRequests == 1 and first.lastSyncMs == first.startedMs and bridge.official_requests == 1, "initial save records one official request, not a commit")
	bridge._on_save_observation([first.token, bridge.observed_bytes, ""])
	check(bridge._save_pending, "losing the initial sync leaves old observed bytes pending")
	bridge._advance_save_sync(first.startedMs + 1999)
	check(bridge.official_requests == 1, "1999ms cannot issue another sync request")
	bridge._advance_save_sync(first.startedMs + 2000)
	var resent: Dictionary = bridge.read_save_persistence()
	check(resent.syncRequests == 2 and resent.lastSyncMs == first.startedMs + 2000 and bridge.official_requests == 2, "2000ms boundary renews only the official sync request")
	check(resent.token == first.token and resent.digest == first.digest and resent.startedMs == first.startedMs and host.requests.size() == 1, "renewal retains token, byte identity, start time and original watchdog")
	check(state.writes == writes_before + 1 and FileAccess.get_sha256(state.SAVE_PATH) == first.digest, "sync renewal never repeats State save or changes native bytes")
	bridge._on_save_observation([first.token - 1, state.bytes, ""])
	check(bridge._save_pending, "old-generation exact bytes cannot acknowledge the renewed attempt")
	bridge._on_save_observation([first.token, bridge.observed_bytes, ""])
	check(not bridge._save_pending and bridge._save_acknowledged_digest == first.digest, "a subsequent sync succeeds only when readonly observation supplies exact current bytes")
	bridge._advance_save_sync(first.startedMs + 4000)
	check(bridge.official_requests == 2, "accepted attempt stops further sync requests immediately")
	var detached: Dictionary = bridge.read_save_persistence()
	detached.syncRequests = 999; detached.lastSyncMs = -1
	check(bridge.read_save_persistence().syncRequests == 2 and bridge.read_save_persistence().lastSyncMs == first.startedMs + 2000, "sync diagnostics are detached read-only request metadata")
	bridge.release_after = 0; bridge.observed_bytes = old
	bridge.request_save(); var failing: Dictionary = bridge.read_save_persistence()
	var total_before := bridge.official_requests
	for offset in range(2000, 62001, 2000):
		bridge._advance_save_sync(failing.startedMs + offset)
		bridge._on_save_observation([failing.token, old, ""])
	var bounded: Dictionary = bridge.read_save_persistence()
	check(bounded.pending and bounded.syncRequests == 30 and bridge.official_requests == total_before + 29, "unchanged old bytes never succeed and official requests stop at thirty")
	check(bounded.lastSyncMs == failing.startedMs + 58000 and bounded.startedMs == failing.startedMs and bounded.token == failing.token and host.requests.size() == 2, "no request reaches or extends the original sixty-second deadline")
	check(state.writes == writes_before + 2, "all forty requests still use one State write per explicit save")
	bridge._on_save_observation([failing.token, null, "timeout"])
	bridge._advance_save_sync(failing.startedMs + 30000)
	bridge._on_save_observation([failing.token, state.bytes, ""])
	check(not bridge._save_pending and bridge._save_error == "timeout" and bridge._save_acknowledged_digest == first.digest and bridge.official_requests == total_before + 29, "timeout stops renewal and late exact bytes cannot turn failure into success")
	bridge.request_save(); var disposed: Dictionary = bridge.read_save_persistence()
	total_before = bridge.official_requests
	bridge._exit_tree(); bridge._advance_save_sync(disposed.startedMs + 2000)
	bridge._on_save_observation([disposed.token, state.bytes, ""])
	check(bridge.official_requests == total_before and not bridge._save_pending and bridge._persistence_host == null, "dispose stops renewal and invalidates late exact observations")
	bridge.free()
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
	verify_bounded_sync(state)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(state.SAVE_PATH))
	bridge.free(); state.free()
	print("Web save receipt ", "PASS" if failures == 0 else "FAIL", " ", checks, " checks")
	quit(0 if failures == 0 else 1)
