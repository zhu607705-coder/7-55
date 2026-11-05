extends SceneTree
## Retired charging boundaries: no controller action, callback or presentation
## clock may create power. Real world targets and unrelated story facts remain.
const Chapter = preload("res://scripts/chapters/chapter3.gd")
var checks := 0
var failures := 0
var state: Dictionary
var controller: RefCounted
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func fixture(percent: int, reduced: bool) -> void:
	state = root.get_node("State").initial()
	state.native.chapter = 3; state.native.page = "c3_theater"; state.native.scene = "theater_interior"; state.native.mode = "light"
	state.native.player = {"x": 665.0, "y": 790.0}
	state.native.settings.reduced_motion = reduced
	state.native.host = {"phone_modal_open": false, "minigame_open": false, "focused": true, "world_visible": true}
	state.rpgScene = "theater_interior"; state.runtimeMode = "rpg"; state.theaterHunt.active = true
	state.theaterHunt.phase = "program_search"; state.phoneBattery.percent = percent
	state.ui.brightness = 100; state.ui.musicPlaying = true
	controller = Chapter.new()
func run() -> void:
	root.get_node("State").developer_mode = true
	for reduced in [false, true]:
		for percent in [0, 1, 7, 87, 100]:
			fixture(percent, reduced)
			var before: Dictionary = state.duplicate(true)
			for action in ["c3_target:theater_charging_station", "c3_charge_result"]:
				for receipt: Variant in [null, {"elapsed_ms": 2200, "success": true}, {"elapsed_ms": 999999, "success": true}]:
					var result: Dictionary = controller.dispatch(state, action, receipt)
					check(not result.has("world_effect"), "retired action never creates a cable or timer: " + action)
					check(state == before, "retired action and repeated forged callbacks preserve battery, music, brightness and story: " + action)
			for phase in ["entry_ticket", "program_search", "prop_setup", "spotlight_ready", "complete"]:
				state.theaterHunt.phase = phase
				var targets: Array = controller.targets("theater_interior", state)
				check(not targets.is_empty(), "theater retains ordinary physical interactions in " + phase)
				var charging_found := false
				for target: Dictionary in targets:
					if target.get("id", "") == "theater_charging_station": charging_found = true
				check(not charging_found, "retired station cannot be reached through visible world targets in " + phase)
			check(state.phoneBattery.keys() == ["percent"] and state.phoneBattery.percent == percent, "no charging bookkeeping or synthetic power returns")
	print("CHARGING_FEEDBACK ", checks, " checks; ", failures, " failures")
	quit(1 if failures else 0)
