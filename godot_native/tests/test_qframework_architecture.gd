extends SceneTree
## Compare the new command/query boundary against authored chapter controllers.
const GameArchitecture = preload("res://scripts/architecture/game_architecture.gd")
const Action = preload("res://scripts/architecture/commands/story_action_command.gd")
const Query = preload("res://scripts/architecture/queries/chapter_query.gd")
const ChapterScripts = [preload("res://scripts/chapters/chapter4.gd"), preload("res://scripts/chapters/chapter3.gd"), preload("res://scripts/chapters/chapter1_2.gd")]
var checks := 0
var failures := 0
var completions := 0
var notifications := 0

func _initialize() -> void: call_deferred("run")
func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error("QFRAMEWORK: " + label)

func controllers() -> Array:
	var result: Array = []
	for script in ChapterScripts: result.append(script.new())
	return result

func canonical(value: Variant) -> Variant:
	if value is Object:
		return {"runtime_type": value.get_script().resource_path if value.get_script() else value.get_class()}
	if value is Dictionary:
		var result: Dictionary = {}
		for key in value: result[key] = canonical(value[key])
		return result
	if value is Array:
		var result: Array = []
		for entry in value: result.append(canonical(entry))
		return result
	return value

# The existing independent domain controllers are the behavior oracle.
func reference_dispatch(modules: Array, data: Dictionary, action: String) -> Dictionary:
	if action != "lib_story_complete":
		for module in modules:
			if module.get("library") != null and module.library.story_session(data, 0) != null:
				return {"status": "locked", "result": {"handled": true, "message": ""}}
	if action not in ["c3_story_complete", "c3_promo_visual_complete", "c3_reversal_visual_complete", "c3_reversal_inspect_closed"]:
		for module in modules:
			if module.has_method("narrative_session") and module.narrative_session(data, 0) != null:
				return {"status": "locked", "result": {"handled": true, "message": ""}}
	for module in modules:
		var result: Dictionary = module.dispatch(data, action, null)
		if not result.is_empty(): return {"status": "accepted", "result": result}
	return {"status": "unhandled", "result": {"handled": false, "message": "这个操作暂时不可用。"}}

func run() -> void:
	var state = root.get_node("State")
	var architecture = GameArchitecture.new()
	root.add_child(architecture)
	var model = architecture.get_model("Progression")
	var system = architecture.get_system("Chapters")
	check(architecture.get_node("Model/Progression") == model, "official model lifecycle")
	check(architecture.get_node("System/Chapters") == system, "official system lifecycle")
	check(architecture.get_node("Utility/Content") == architecture.get_utility("Content"), "official utility lifecycle")
	var checkpoints: Array = state.developer_checkpoints()
	check(checkpoints.size() == 117, "all authored checkpoint snapshots available")
	var attempts := 0
	for checkpoint in checkpoints:
		var data: Dictionary = state.merge_defaults(state.initial(), checkpoint.state)
		model.snapshot = data.duplicate(true)
		system.modules = controllers()
		var before: Dictionary = model.snapshot.duplicate(true)
		var page: String = str(data.native.page)
		var actions: Array = architecture.send_query(Query.new("actions", page))
		for kind in ["pages", "view", "targets", "objective", "snapshot"]:
			architecture.send_query(Query.new(kind, page))
		check(model.snapshot == before, str(checkpoint.id) + " queries preserve progression")
		var detached: Dictionary = architecture.send_query(Query.new("snapshot"))
		detached.native.page = "detached"
		check(model.snapshot.native.page != "detached", "snapshot query cannot mutate model")
		var ids: Array = ["qframework_unknown_action"]
		for entry in actions.slice(0, 3): ids.append(str(entry.id))
		for action: String in ids:
			model.snapshot = data.duplicate(true)
			system.modules = controllers()
			var oracle_data := data.duplicate(true)
			var expected := reference_dispatch(controllers(), oracle_data, action)
			var command = Action.new(action)
			var actual: Dictionary = architecture.send_command(command)
			check(command.architecture == null, "completed command releases architecture")
			check(actual.status == expected.status and canonical(actual.result) == canonical(expected.result), str(checkpoint.id) + " result " + action)
			check(canonical(model.snapshot) == canonical(oracle_data), str(checkpoint.id) + " state " + action)
			if actual.has("previous"):
				check(actual.previous == data, "command records pre-dispatch snapshot")
			attempts += 1
	# Exercise the production facade, synchronous return and legacy event bridge.
	state.developer_mode = true
	state.d = state.initial()
	state.action_completed.connect(func(_a, _p, _n, _r): completions += 1)
	state.changed.connect(func(): notifications += 1)
	var result: Dictionary = state.act("c1_start_alarm")
	check(result.get("handled", false) and completions == 1, "ordinary State action completes synchronously once")
	check(notifications == 1, "ordinary action retains one changed notification")
	check(is_same(state.d, state.game_architecture().get_model("Progression").snapshot), "State.d aliases the only model")
	var replacement: Dictionary = state.initial()
	state.d = replacement
	check(is_same(replacement, state.game_architecture().get_model("Progression").snapshot), "load/import dictionary replacement reaches model")
	var count := notifications
	state.select_item("not_owned")
	check(notifications == count and state.d.native.selected_item.is_empty(), "unowned selection is rejected")
	state.select_item("")
	check(notifications == count + 1, "selection event returns through system bridge")
	state.open_page("phone_home")
	check(state.d.native.page == "phone_home" and notifications == count + 2, "navigation command updates shared model once")
	var locked_mode_state := JSON.stringify(state.d)
	state.toggle_mode()
	check(JSON.stringify(state.d) == locked_mode_state and notifications == count + 2, "mode command leaves a pre-022 save untouched")
	state.d.native.chapter = 3
	state.toggle_mode()
	check(state.d.native.mode == "dark" and state.d.qizhenLake.mode == "dark", "mode command synchronizes authored domains")
	var surface_notifications := notifications
	state.d.native.scene = "dorm_hub"
	state.resume_world_surface()
	check(state.d.runtimeMode == "rpg" and notifications == surface_notifications, "world return retains silent save-before-layout")
	state.record_world_position("dorm_hub", "dorm_hub:", Vector2(500, 700), Vector2(510, 1400))
	check(state.d.native.positions["dorm_hub:"] == {"x": 500.0, "y": 700.0}, "world anchor keeps its checkpoint key")
	check(state.d.native.player == {"scene": "dorm_hub", "x": 510.0, "y": 1400.0, "world_x": 500.0, "world_y": 700.0}, "legacy player fields preserve authored and world coordinates")
	var position_snapshot: Dictionary = state.read_snapshot()
	state.record_world_position("library_interior", "library_interior:", Vector2.ONE, Vector2.ONE)
	state.record_world_position("dorm_hub", "dorm_hub:", Vector2.INF, Vector2.ONE)
	check(state.d == position_snapshot and notifications == surface_notifications, "stale or invalid position cannot touch the active checkpoint")
	state.show_phone_home()
	check(state.d.runtimeMode == "phone" and state.d.native.page == "phone_home" and notifications == surface_notifications + 1, "phone navigation commits the mode and home page together")
	architecture.queue_free()
	await process_frame
	print("QFramework architecture: %d checks, %d checkpoint action comparisons, %d failures" % [checks, attempts, failures])
	quit(1 if failures else 0)
