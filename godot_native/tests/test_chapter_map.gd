extends SceneTree

const Map = preload("res://scripts/chapters/chapter_map.gd")
var _checks := 0
var _failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _check(ok: bool, description: String) -> void:
	_checks += 1
	if ok: return
	_failures += 1
	push_error(description)

func _run() -> void:
	if not load("res://tests/native_test_isolation.gd").is_isolated_save():
		push_error("Chapter map requires an isolated save.")
		quit(2)
		return
	var state := root.get_node("State")
	state.new_game()
	state.act("c1_start_alarm")
	_check(state.chapter_map_view().nodes.morning == "ready","accepted alarm action captures a real chapter checkpoint")
	state.act("c1_dismiss_alarm")
	state.act("c1_wake")
	state.act("c1_enter_home")
	_check(state.d.native.page == "phone_home","ordinary phone progression works")
	var primary := FileAccess.get_file_as_bytes(state.SAVE_PATH)
	_check(state.begin_chapter_replay("morning"),"earned milestone opens through the player-facing State path")
	_check(state.d.native.page == "alarm" and state.is_chapter_replaying(),"rewind opens the same playable alarm")
	state.act("c1_dismiss_alarm")
	_check(state.d.native.page == "desktop" and FileAccess.get_file_as_bytes(state.SAVE_PATH) == primary,"replay plays independently of the formal file")
	_check(state.return_from_chapter_replay() and state.d.native.page == "phone_home","discard returns to the original screen")
	_check(state.begin_chapter_replay("morning"),"same checkpoint can be replayed repeatedly")
	_check(state.adopt_chapter_replay() and state.d.native.page == "alarm","explicit adoption writes the current replay")
	_check(state.load_game() and state.d.native.page == "alarm" and state.chapter_map_view().restore,"ordinary reload uses the rewritten path and retains undo")
	_check(state.restore_chapter_map_prior() and state.d.native.page == "phone_home","previous route restores as a complete snapshot")
	_check(state.load_game() and state.d.native.page == "phone_home","restored route survives reload")
	_check(not state.begin_chapter_replay("gate"),"undiscovered checkpoints cannot be opened")

	var start: Dictionary = state.initial()
	start.native.chapter = 2
	start.actOne.cc98Login.authenticated = true
	start.ui.libraryFinalsPhase = "evidence_gathering"
	start.native.page = "cc98"
	start.currentScene = "cc98"
	start.items.occupancyNote = true
	start.ui.libraryFinalsPuzzle.occupancyNoteCollected = true
	_check(Map.statuses(start).get("rules") == null,"branch details stay hidden before the junction")
	state.d = start
	state.act("lib_investigate","occupancyNote")
	_check(state.chapter_map_view().nodes.junction == "ready" and state.chapter_map_view().nodes.visit == "blocked","the real investigation action unlocks its map and preserves the dependency")
	var map := preload("res://scripts/ui/chapter_map_view.gd").new()
	map.setup(state.chapter_map_view())
	root.add_child(map)
	await process_frame
	var junction := map.find_child("ChapterMapStop_junction",true,false) as Button
	var visit := map.find_child("ChapterMapStop_visit",true,false) as Button
	_check(junction != null and visit != null and not visit.is_visible_in_tree(),"junction starts collapsed")
	junction.pressed.emit()
	_check(visit.is_visible_in_tree() and not visit.disabled,"opening the junction reveals the inspectable gated branch")
	visit.pressed.emit()
	_check(not map.find_child("ChapterMapReplay",true,false).visible,"a gated observation never opens replay")
	map.queue_free()
	await process_frame
	print("Chapter map: ",_checks," checks, ",_failures," failures")
	quit(1 if _failures else 0)
