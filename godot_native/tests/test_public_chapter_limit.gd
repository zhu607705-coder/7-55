extends SceneTree

const Content = preload("res://scripts/platform/web_content.gd")
const Policy = preload("res://scripts/release_content_policy.gd")

var failures := 0

func _initialize() -> void:
	run.call_deferred()

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func run() -> void:
	if not preload("res://tests/native_test_isolation.gd").is_isolated_save():
		quit(2)
		return
	var state: Node = root.get_node("State")
	var content := Content.new()
	root.add_child(content)
	var manifest := {"schema": "755-web-content-v1", "core": {"file": "index.pck", "bytes": 1, "sha256": "a".repeat(64)}, "packs": [], "backgroundOrder": [], "publicChapterLimit": 2}
	var inconsistent := manifest.duplicate(true)
	inconsistent.packs = [{"id": "chapter3_001", "family": "chapter3", "file": "content/chapter3.pck", "bytes": 1, "sha256": "b".repeat(64)}]
	check(not content._configure_manifest(inconsistent, null), "capped manifest must reject a later pack")
	var wire_manifest: Dictionary = JSON.parse_string(JSON.stringify(manifest))
	check(content._configure_manifest(wire_manifest, null) and Policy.chapter_available(2) and not Policy.chapter_available(3), "serialized public manifest activates chapter limit")
	var fresh: Dictionary = state.initial()
	check(Policy.permits_snapshot(fresh), "first chapter and dormant later defaults remain playable")
	var later := fresh.duplicate(true)
	later.native.chapter = 3
	check(not await content.ensure_state(later), "later chapter cannot enter through load or cache admission")
	later.native.chapter = 2
	later.native.scene = "qizhen_lake"
	check(not Policy.permits_snapshot(later), "a later scene in an old save cannot bypass the cap with chapter 2")
	state.d = fresh
	state.d.native.merge({"chapter": 2, "scene": "library_interior", "page": "library_world"}, true)
	state.d.runtimeMode = "rpg"
	state.d.rpgScene = "library_interior"
	state.d.actOne.phase = "complete"
	state.d.ui.libraryFinalsPhase = "backpack_removed"
	state.d.ui.libraryFinalsPuzzle.backpackEvicted = true
	var completed: Dictionary = state.act("lib_sit")
	check(str(completed.message).contains("第二章完成") and state.d.ui.libraryFinalsPuzzle.playerSeated, "physical seat completion saves the chapter two milestone and explains the limit")
	check(state.get_scene_session() == null and state.d.native.chapter == 2 and not state.d.canteenHunt.active, "seat completion cannot launch chapter three or grant canteen progression")
	state.act("lib_opening_complete")
	state.act("c3_enter_canteen")
	state.open_scene("duan_yongping_temporal_maze")
	check(state.d.native.chapter == 2 and state.d.native.scene == "library_interior" and not state.d.canteenHunt.active, "later actions and direct navigation cannot bypass the edition limit")
	check(str(state.objective()).contains("第二章已完成"), "completed chapter stays visible as the current objective")
	manifest.erase("publicChapterLimit")
	check(content._configure_manifest(manifest, null) and Policy.chapter_available(4) and state.get_scene_session() != null, "the full edition can continue the same saved seat milestone")
	content.queue_free()
	print("PUBLIC_CHAPTER_LIMIT: ", failures, " failures")
	quit(1 if failures else 0)
