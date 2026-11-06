extends SceneTree
## Real coordinator + State snapshots; only external transport is controlled.

var checks := 0
var failures := 0
var state: Node
var cloud: Node

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("CLOUD SYNC RACE: " + label)

func fixture() -> void:
	if is_instance_valid(cloud):
		cloud.free()
	state.d = state.initial()
	state.developer_mode = false
	state.persistence_ready = true
	check(state.save_game(), "fixture has a valid persisted snapshot")
	cloud = load("res://tests/cloud_sync_controlled_transport.gd").new()
	root.add_child(cloud)
	cloud.member_id = "11111111-1111-4111-8111-111111111111"
	cloud.ready_for_play = true
	cloud.head = {"revision": 1, "current": {"savedAt": "2026-11-06T00:00:00Z"}}
	cloud._last_local_digest = cloud._digest(state.capture_cloud_bundle().bundle)
	cloud._dirty = true
	cloud.pending_value = true

func begin_wait() -> void:
	cloud.hold_persist = true
	cloud.flush()
	check(cloud.persist_waiting and cloud._busy, "flush is suspended inside durability acknowledgement")

func release_wait() -> void:
	cloud.hold_persist = false
	cloud.persist_released.emit()
	await process_frame

func run() -> void:
	if not preload("res://tests/native_test_isolation.gd").is_isolated_save():
		quit(2)
		return
	state = root.get_node("State")
	fixture()
	begin_wait()
	# A real navigation write emits snapshot_saved while flush is suspended.
	state.open_page("phone_home")
	check(cloud._dirty, "navigation marks newer progress dirty during persist")
	var latest_digest: String = cloud._digest(state.capture_cloud_bundle().bundle)
	await release_wait()
	check(cloud._dirty and cloud.pending_value, "deduplicated old snapshot cannot acknowledge newer progress")
	check(not cloud.status_text.begins_with("云端已保存"), "newer progress does not show a false cloud receipt")
	check(cloud.uploads == 0 and not cloud._busy, "old acknowledged bytes are not reuploaded and coordinator unlocks")
	await cloud.flush()
	check(cloud.uploads == 1 and cloud._last_local_digest == latest_digest, "next flush uploads the new navigation snapshot")
	check(not cloud._dirty and not cloud.pending_value, "new exact acknowledgement clears pending")
	await cloud.flush()
	check(cloud.uploads == 1 and not cloud._dirty, "unchanged state does not produce a duplicate upload")

	fixture()
	begin_wait()
	await release_wait()
	check(cloud.uploads == 0 and not cloud._dirty and not cloud.pending_value, "unchanged deduplicated snapshot can become clean")
	check(cloud.status_text.begins_with("云端已保存"), "unchanged durable bytes retain the existing receipt")

	# Capture failure must not become a clean result on either successful path.
	for upload_required: bool in [false, true]:
		fixture()
		if upload_required:
			state.open_page("phone_home")
		begin_wait()
		state.d.phoneBattery.percent = -1
		check(not state.capture_cloud_bundle().get("ok", false), "invalid latest state exercises actual capture rejection")
		await release_wait()
		check(cloud._dirty and cloud.pending_value, "capture failure preserves pending after upload=" + str(upload_required))
		check(not cloud.status_text.begins_with("云端已保存") and not cloud.failures.is_empty(), "capture failure reports failure, not a clean receipt")
		check(not cloud._busy, "capture failure releases busy state")

	fixture()
	begin_wait()
	cloud._epoch += 1
	cloud._busy = false
	cloud.status_text = "账号已切换"
	await release_wait()
	check(cloud._dirty and cloud.pending_value and cloud.uploads == 0, "old epoch cannot clear pending or upload")
	check(cloud.status_text == "账号已切换", "old epoch cannot replace the new account status")
	cloud.free()
	print("CLOUD_SYNC_RACE: ", checks, " checks; ", failures, " failures")
	quit(1 if failures else 0)
