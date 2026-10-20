extends SceneTree
## Actual tiny PCK mounts, async family waits and failed transport integrity.
const Coordinator = preload("res://scripts/platform/web_content.gd")
var checks := 0
var failures := 0
var fixture_directory := ""
var original_bytes: Dictionary = {}
class Transport extends RefCounted:
	var requests: Array = []
	var retries: Array = []
	var acknowledgements: Array = []
	var prefetches := 0
	func request(raw: String) -> void: requests.append(JSON.parse_string(raw))
	func retry(raw: String) -> void: retries.append(JSON.parse_string(raw))
	func acknowledge(id: String, accepted: bool, message: String) -> void: acknowledgements.append({"id": id, "accepted": accepted, "message": message})
	func startPrefetch() -> void: prefetches += 1
class Probe extends "res://scripts/platform/web_content.gd":
	var directory := ""
	var mounts := 0
	var reject_mount := false
	var reloads := 0
	func _expected_path(id: String) -> String: return directory.path_join(str(_packs[id].sha256) + ".pck")
	func _mount_pack(filename: String) -> bool:
		mounts += 1
		return false if reject_mount else super._mount_pack(filename)
	func _reload_browser() -> void: reloads += 1

func _initialize() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error("WEB CONTENT: " + message)
func write_file(filename: String, bytes: PackedByteArray) -> void:
	var file := FileAccess.open(filename, FileAccess.WRITE); file.store_buffer(bytes); file.close()
func record(id: String, family: String) -> Dictionary:
	var source := fixture_directory.path_join(id + ".txt")
	write_file(source, ("Actual isolated content " + id).to_utf8_buffer())
	var filename := fixture_directory.path_join(id + ".pck")
	var packer := PCKPacker.new()
	check(packer.pck_start(filename) == OK and packer.add_file("res://755_content_test/" + id + ".txt", source) == OK and packer.flush() == OK, "test fixture is an actual official PCK " + id)
	var bytes := FileAccess.get_file_as_bytes(filename)
	var digest := FileAccess.get_sha256(filename)
	var destination := fixture_directory.path_join(digest + ".pck")
	check(DirAccess.rename_absolute(filename, destination) == OK, "fixture path uses its actual SHA-256")
	original_bytes[id] = bytes
	return {"id": id, "family": family, "file": "packs/" + id + ".pck", "bytes": bytes.size(), "sha256": digest}
func manifest(records: Array) -> Dictionary:
	return {"schema": "755-web-content-v1", "core": {"file": "core.pck", "bytes": 1, "sha256": "0".repeat(64)}, "packs": records.duplicate(true), "backgroundOrder": ["chapter2", "chapter3", "chapter35", "chapter4"]}
func begin_wait(coordinator: Node, families: Array, result: Array) -> void:
	result.append(await coordinator.ensure_families(families))
func new_probe(records: Array, host: Transport) -> Probe:
	var result := Probe.new(); result.directory = fixture_directory; root.add_child(result)
	check(result._configure_manifest(manifest(records), host), "valid fixed-family manifest is accepted")
	return result
func deliver(coordinator: Probe, id: String, error := "") -> void:
	coordinator._on_pack_received([id, coordinator._expected_path(id), error])

func test_recovered_replay(state: Node) -> void:
	# Full checked-in source state, not a fabricated chapter-four completion.
	# Only the ordinary phone navigation fields are varied below.
	var file := FileAccess.open("res://data/native/developer_checkpoints.json.gz", FileAccess.READ)
	var decoded: Variant = JSON.parse_string(file.get_buffer(file.get_length()).decompress_dynamic(4 * 1024 * 1024, FileAccess.COMPRESSION_GZIP).get_string_from_utf8())
	file.close()
	var replay: Dictionary = {}
	for checkpoint: Dictionary in decoded.get("checkpoints", []):
		if checkpoint.id == "c4-prologue": replay = state.merge_defaults(state.initial(), checkpoint.state)
	check(not replay.is_empty(), "complete source replay fixture is available")
	if replay.is_empty(): return
	replay.native.chapter = 3; replay.native.scene = ""; replay.native.page = "phone_home"; replay.runtimeMode = "phone"
	check(replay.qizhenLake.phase == "complete" and replay.chapterThreeInterlude.phase == "replay_ready" and replay.chapterThreeInterlude.replayUnlocked and not replay.chapter4.prologueSeen, "full source state satisfies Main's existing replay admission predicate")
	var saved := replay.duplicate(true)
	var controller: RefCounted = load("res://scripts/chapters/chapter4.gd").new()
	var result: Dictionary = controller.dispatch(replay, "c4_prologue")
	check(result.get("game", {}).get("kind") == "prologue" and str(result.get("game", {}).get("video", "")).contains("chapter4-prologue/"), "real controller admits a C4 film while saved native chapter is still three")
	check(replay == saved and replay.native.page == "phone_home" and replay.native.chapter == 3, "admission does not rewrite the saved page or chapter before issuing media")
	for page: String in ["phone_home", "c35_recovery", "c35_voice", "photos", "c4_notes"]:
		replay.native.page = page
		check(Coordinator.required_families(replay) == ["chapter2", "chapter3", "chapter35", "chapter4"], "accepted replay loads C4 resources across ordinary saved phone pages: " + page)
	replay.native.page = "phone_home"
	var locked := replay.duplicate(true); locked.chapterThreeInterlude.replayUnlocked = false
	check(Coordinator.required_families(locked) == ["chapter2", "chapter3", "chapter35"], "replay_ready phase without the controller unlock does not request C4")
	locked = replay.duplicate(true); locked.chapterThreeInterlude.phase = "destination_verified"
	check(Coordinator.required_families(locked).size() == 3, "earlier destination confirmation does not request C4")
	locked = replay.duplicate(true); locked.qizhenLake.phase = "tool_chain"
	check(Coordinator.required_families(locked).size() == 3, "an unfinished lake cannot promote the replay content requirement")

func run() -> void:
	if not load("res://tests/native_test_isolation.gd").is_isolated_save():
		push_error("WEB_CONTENT_TEST_ISOLATION_REQUIRED"); quit(2); return
	fixture_directory = ProjectSettings.globalize_path("user://web-content-unit")
	DirAccess.make_dir_recursive_absolute(fixture_directory)
	var state: Node = root.get_node("State")
	state.d = state.initial(); check(state.save_game(), "isolated baseline save commits")
	var before: Dictionary = state.d.duplicate(true)
	var primary := FileAccess.get_file_as_bytes(state.SAVE_PATH)
	var backup := FileAccess.get_file_as_bytes(state.BACKUP_PATH) if FileAccess.file_exists(state.BACKUP_PATH) else PackedByteArray()
	var fallback := Coordinator.new(); root.add_child(fallback)
	check(await fallback.ensure_state({"native": {"chapter": 4}}), "native monolithic fallback grants all existing content")
	check(fallback.ready_for_state({"native": {"chapter": 4}}) and not fallback.is_blocking() and fallback.read_snapshot().monolithic, "fallback has no overlay, download or altered readiness")
	var missing_host := Probe.new(); root.add_child(missing_host)
	check(not missing_host._require_web_host(null), "a Web loader without its content host fails closed instead of declaring a full monolithic pack")
	check(not await missing_host.ensure_state(before) and not missing_host.ready_for_state(before), "missing Web host blocks even fresh C1 so a partial core cannot start as a full export")
	check(missing_host.is_blocking() and missing_host._overlay.visible and missing_host._retry.visible and missing_host._retry.text == "重新加载", "missing-host recovery visibly offers a real reload button")
	await process_frame; await process_frame
	check(missing_host.reloads == 0, "fatal compatibility mismatch never automatically reloads in a loop")
	missing_host._retry.pressed.emit()
	check(missing_host.reloads == 1, "only the explicit fatal recovery button requests a page reload")
	missing_host.queue_free()
	var invalid_manifest := Probe.new(); root.add_child(invalid_manifest)
	check(not invalid_manifest._configure_manifest({"schema": "stale-manifest"}, Transport.new()) and not await invalid_manifest.ensure_families([]), "invalid manifest remains a blocked loader failure")
	check(invalid_manifest._retry.visible and invalid_manifest._retry.text == "重新加载" and invalid_manifest.reloads == 0, "invalid manifest offers explicit reload without scheduling one")
	invalid_manifest._retry.pressed.emit()
	check(invalid_manifest.reloads == 1, "invalid-manifest reload uses the same explicit recovery action")
	invalid_manifest.queue_free()
	var native_fatal := Coordinator.new(); root.add_child(native_fatal)
	native_fatal._enabled = true; native_fatal._fatal_error = "isolated fatal fixture"
	check(not await native_fatal.ensure_families([]), "native fixture can exercise the fatal overlay without browser capabilities")
	native_fatal._retry.pressed.emit()
	check(state.d == before and FileAccess.get_file_as_bytes(state.SAVE_PATH) == primary, "native fatal-button boundary invokes no JavaScript or progression changes")
	native_fatal.queue_free()
	check(Coordinator.required_families(before).is_empty(), "fresh C1 never waits for deferred chapter resources")
	check(Coordinator.required_families({"native": {"chapter": 2}}) == ["chapter2"], "C2 requires its own family")
	check(Coordinator.required_families({"native": {"chapter": 3}}) == ["chapter2", "chapter3"], "C3 conservatively retains earlier item and return art")
	check(Coordinator.required_families({"native": {"chapter": 3, "scene": "qizhen_lake"}}) == ["chapter2", "chapter3", "chapter35"], "lake scene distinguishes C3.5 from shared numeric chapter")
	check(Coordinator.required_families({"native": {"chapter": 3, "page": "c35_voice"}}).size() == 3, "phone-only interlude restore requires C3.5 media")
	check(Coordinator.required_families({"native": {"chapter": 1, "page": "c4_notes"}}).size() == 4, "ordinary later phone save retains cumulative content requirements")
	check(Coordinator.required_families({"native": {"chapter": 4}}) == ["chapter2", "chapter3", "chapter35", "chapter4"], "C4 requires every prior family, not independent campuses")
	test_recovered_replay(state)
	var a := record("chapter2_unit_a", "chapter2")
	var b := record("chapter2_unit_b", "chapter2")
	var c := record("chapter3_unit_c", "chapter3")
	var d := record("chapter4_unit_d", "chapter4")
	for invalid: Dictionary in [{"key": "family", "value": "unknown"}, {"key": "id", "value": "../escape"}, {"key": "sha256", "value": "broken"}, {"key": "file", "value": "../escape.pck"}, {"key": "bytes", "value": 1.5}]:
		var broken := a.duplicate(true); broken[invalid.key] = invalid.value
		var rejected := Probe.new(); root.add_child(rejected)
		check(not rejected._configure_manifest(manifest([broken]), Transport.new()) and not rejected.ready_for_state(before), "invalid manifest fails closed: " + str(invalid.key))
		rejected.queue_free()
	var duplicate := Probe.new(); root.add_child(duplicate)
	check(not duplicate._configure_manifest(manifest([a, a]), Transport.new()), "duplicate pack ids are rejected")
	duplicate.queue_free()
	var host := Transport.new()
	var coordinator := new_probe([a, b, c, d], host)
	var blocking_events: Array = []
	coordinator.blocking_changed.connect(func(value: bool): blocking_events.append(value))
	var first: Array = []; var second: Array = []
	begin_wait(coordinator, ["chapter2"], first)
	begin_wait(coordinator, ["chapter2"], second)
	check(coordinator.is_blocking() and coordinator._overlay.visible and host.requests == [[a.id, b.id]], "concurrent waits share one request and a visible required-content overlay")
	check(first.is_empty() and second.is_empty(), "a family cannot resolve with chunks still missing")
	var detached: Dictionary = coordinator.read_snapshot()
	detached.packs[0].status = "ready"; detached.requiredIds.clear()
	check(coordinator.read_snapshot().packs[0].status == "requested" and coordinator.read_snapshot().requiredIds.size() == 2, "read-only snapshots detach nested pack and waiter arrays")
	write_file(coordinator._expected_path(a.id), PackedByteArray([1, 2, 3]))
	deliver(coordinator, a.id)
	check(coordinator.mounts == 0 and not host.acknowledgements.back().accepted and coordinator._retry.visible, "wrong file size is rejected before mounting and exposes retry")
	coordinator._request_missing([a.id, b.id])
	check(host.requests.size() == 1, "an error never causes a per-frame automatic redownload")
	coordinator._retry_required()
	check(host.retries == [[a.id]] and not coordinator._retry.visible, "user retry targets only the failed chunk")
	var changed: PackedByteArray = original_bytes[a.id].duplicate(); changed[changed.size() - 1] ^= 1
	write_file(coordinator._expected_path(a.id), changed); deliver(coordinator, a.id)
	check(coordinator.mounts == 0 and not host.acknowledgements.back().accepted, "same-length wrong SHA-256 bytes are rejected before mounting")
	coordinator._retry_required()
	coordinator._on_pack_received([a.id, coordinator._expected_path(a.id) + ".wrong", ""])
	check(coordinator.mounts == 0 and not host.acknowledgements.back().accepted, "a callback cannot mount a different absolute path")
	coordinator._retry_required()
	write_file(coordinator._expected_path(a.id), original_bytes[a.id]); deliver(coordinator, a.id)
	check(coordinator.mounts == 1 and host.acknowledgements.back().accepted and FileAccess.get_file_as_string("res://755_content_test/" + a.id + ".txt").ends_with(a.id), "actual valid PCK is verified, mounted and only then acknowledged")
	check(first.is_empty() and second.is_empty() and not coordinator.ready_for_state({"native": {"chapter": 2}}), "first mounted chunk does not prematurely unlock its family")
	deliver(coordinator, b.id)
	await process_frame
	check(first == [true] and second == [true] and coordinator.ready_for_state({"native": {"chapter": 2}}), "all chunks release every waiting consumer")
	check(not coordinator.is_blocking() and not coordinator._overlay.visible and blocking_events == [true, false], "overlay and blocking lease retire after the whole family mounts")
	var count := host.requests.size()
	check(await coordinator.ensure_families(["chapter2"]), "a later consumer of an already ready family succeeds")
	check(host.requests.size() == count and not coordinator.is_blocking(), "ready content is never requested or covered again")
	coordinator._on_pack_received([a.id, coordinator._expected_path(a.id), "late network failure"])
	check(coordinator.ready_for_state({"native": {"chapter": 2}}) and coordinator.mounts == 2 and not host.acknowledgements.back().accepted, "late failed duplicate is not cached and cannot revoke verified mounted content")
	coordinator.start_prefetch(); coordinator.start_prefetch()
	check(host.prefetches == 1, "background prefetch starts idempotently")
	deliver(coordinator, c.id, "network down")
	check(not coordinator.is_blocking() and not coordinator._overlay.visible, "background download failure stays silent while content is not required")
	deliver(coordinator, c.id)
	check(coordinator.mounts == 3 and "chapter3" in coordinator.read_snapshot().readyFamilies and not coordinator.is_blocking(), "background arrival verifies and mounts without interrupting current play")
	var fourth: Array = []
	begin_wait(coordinator, ["chapter4"], fourth)
	coordinator.reject_mount = true; deliver(coordinator, d.id)
	check(coordinator.mounts == 4 and fourth.is_empty() and coordinator._retry.visible and not host.acknowledgements.back().accepted, "a validated file that cannot mount remains blocked and is never cached as accepted")
	coordinator.reject_mount = false; coordinator._retry_required(); deliver(coordinator, d.id)
	await process_frame
	check(coordinator.mounts == 5 and fourth == [true] and not coordinator.is_blocking(), "user retry can recover a mount failure without restarting the current chapter")
	check(not await coordinator.ensure_families(["untrusted_family"]), "unexpected family request is rejected")
	var backup_after := FileAccess.get_file_as_bytes(state.BACKUP_PATH) if FileAccess.file_exists(state.BACKUP_PATH) else PackedByteArray()
	check(state.d == before and FileAccess.get_file_as_bytes(state.SAVE_PATH) == primary and backup_after == backup, "availability, rejection, retries and mounting never change story or either save")
	coordinator.queue_free(); fallback.queue_free()
	await process_frame
	print("WEB_CONTENT: ", checks, " checks; ", failures, " failures")
	quit(1 if failures else 0)
