extends RefCounted
## Read-only bindings from existing NPC actions and painted actors to feedback.
## The caller first applies the world's ordinary distance and input locks.
## These selectors never accept an intent, award a task or load actor artwork.

const C4_SCENE := "duan_yongping_temporal_maze"
const C4_ACTIONS := {
	"a1_front_desk_attendant": "c4_front_desk",
	"a2_elevator_attendant": "c4_deduction",
	"a3_reference_teacher": "c4_reference_teacher",
}
const FRONT_DESK_TIMES := {
	"bakery_hour_hand": "1225_bakery",
	"room204_restore": "1850_evening",
	"morning_checkin": "0755_morning",
	"exterior_closure": "0755_morning",
}
const TRAYS := ["tray_blue_01", "tray_blue_02", "tray_blue_03"]
const STOP_CHAIN := "elevator_stop_chain_reconstructed"

static func target_id(scene_id: String, target: Dictionary) -> String:
	var id := str(target.get("id", ""))
	var action := str(target.get("action", ""))
	if bool(target.get("decorative", false)): return ""
	if scene_id == "library_interior":
		return id if id == "front_desk" and action == "lib_front_desk" else ""
	if scene_id == C4_SCENE:
		return id if C4_ACTIONS.has(id) and action == str(C4_ACTIONS[id]) else ""
	if scene_id != "canteen_interior" or action != "c3_target:" + id: return ""
	if id in ["auntie", "initial-counter-npc"]: return id
	for prefix: String in ["initial-queue-npc-", "initial-seated-npc-"]:
		if id.begins_with(prefix):
			var suffix := id.trim_prefix(prefix)
			if suffix.is_valid_int() and int(suffix) >= 0 and str(int(suffix)) == suffix:
				return id
	return ""

static func dialogue_accepted(scene_id: String, target: Dictionary, result: Dictionary, state: Dictionary) -> bool:
	var id := target_id(scene_id, target)
	if id.is_empty() or not bool(result.get("handled", false)): return false
	var native: Dictionary = state.get("native", {})
	if str(native.get("scene", "")) != scene_id: return false
	if scene_id == "canteen_interior":
		var canteen: Dictionary = state.get("canteenHunt", {})
		if not bool(canteen.get("active", false)) or native.get("mode", "") != "light": return false
		var phases: Array = ["tray_search", "drink_mix", "menu_order", "pickup_search", "chase_ready"] if id == "auntie" else ["tray_search", "drink_mix"]
		# Ordinary NPC dialogue is owned by a timed narrative and has no message.
		# A handled rejection or an ambiguous short reply is not that receipt.
		return canteen.get("phase", "") in phases and bool(result.get("narrative_owned", false))
	if scene_id == "library_interior":
		var ui: Dictionary = state.get("ui", {})
		var puzzle: Dictionary = ui.get("libraryFinalsPuzzle", {})
		# Queued library stories return no positive receipt. Leave those to their
		# existing story host; acknowledge only a normal, visible desk reply here.
		return int(native.get("chapter", 0)) == 2 and str(ui.get("libraryFinalsPhase", "idle")) != "idle" and "front_desk" in puzzle.get("libraryVisitedPoints", []) and not str(result.get("message", "")).is_empty()
	var chapter: Dictionary = state.get("chapter4", {})
	if not bool(chapter.get("prologueSeen", false)) or bool(chapter.get("completed", false)): return false
	if id == "a1_front_desk_attendant":
		var phase := str(chapter.get("phase", ""))
		return chapter.get("floor", "") == "A1" and FRONT_DESK_TIMES.has(phase) and chapter.get("timeState", "") == FRONT_DESK_TIMES[phase] and not str(result.get("message", "")).is_empty()
	if chapter.get("phase", "") != "room204_restore" or chapter.get("timeState", "") != "1850_evening": return false
	if id == "a2_elevator_attendant":
		return chapter.get("floor", "") == "A2" and result.get("page", "") == "c4_device" and native.get("c4_context", "") == "deduction"
	return chapter.get("floor", "") == "A3" and not str(result.get("message", "")).is_empty()

static func completion_target(action: String, previous: Dictionary, next: Dictionary, result: Dictionary) -> String:
	if not bool(result.get("handled", false)): return ""
	var before_native: Dictionary = previous.get("native", {})
	var after_native: Dictionary = next.get("native", {})
	var scene := str(after_native.get("scene", ""))
	if str(before_native.get("scene", "")) != scene: return ""
	if action == "c3_target:auntie" and scene == "canteen_interior":
		var before: Dictionary = previous.get("canteenHunt", {})
		var after: Dictionary = next.get("canteenHunt", {})
		if not bool(after.get("active", false)) or after_native.get("mode", "") != "light" or not bool(result.get("narrative_owned", false)): return ""
		return "auntie" if _tray_count(before) < TRAYS.size() and _tray_count(after) == TRAYS.size() else ""
	if action == "c4_deduce" and scene == C4_SCENE:
		var before: Dictionary = previous.get("chapter4", {})
		var after: Dictionary = next.get("chapter4", {})
		if before.get("floor", "") != "A2" or after.get("floor", "") != "A2" or after.get("phase", "") != "room204_restore" or after.get("mode", "") != "light": return ""
		return "a2_elevator_attendant" if STOP_CHAIN not in before.get("factIds", []) and STOP_CHAIN in after.get("factIds", []) else ""
	return ""

static func _tray_count(canteen: Dictionary) -> int:
	var count := 0
	for id: String in TRAYS:
		if id in canteen.get("returnedTrayIds", []): count += 1
	return count

static func geometry(world: Control, id: String) -> Dictionary:
	if not is_instance_valid(world) or id.is_empty(): return {}
	var picker: Variant = world.get("object_picker")
	if picker != null:
		var surfaces: Array = picker.get("surfaces")
		for index in range(surfaces.size() - 1, -1, -1):
			var surface: Dictionary = surfaces[index]
			if id not in surface.get("ids", []) or not bool(surface.get("painted", true)): continue
			var actor := _actor_bounds(surface.get("geometry", {}))
			if not actor.is_empty(): return actor
	var canteen: Variant = world.get("native_canteen")
	if is_instance_valid(canteen) and canteen.has_method("is_active") and canteen.is_active() and canteen.has_method("target_geometry"):
		return _actor_bounds(canteen.target_geometry(id))
	return {}

static func _actor_bounds(raw: Dictionary) -> Dictionary:
	# The same target can also own a counter's broad interaction surface. Only
	# a painted sprite has the texture and frame rectangle needed for its head.
	if not raw.get("texture") is Texture2D or not raw.get("rect") is Rect2: return {}
	var transform: Transform2D = raw.get("transform", Transform2D.IDENTITY)
	var bounds: Rect2 = transform * raw.rect
	if not bounds.has_area() or not bounds.position.is_finite() or not bounds.end.is_finite(): return {}
	return {"bounds": bounds}
