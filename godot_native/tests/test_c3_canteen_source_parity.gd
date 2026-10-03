extends SceneTree
## Executed-TypeScript controller parity. Spatial placement below is an explicit
## fixture at authored targets, not a claim of player-earned traversal or GUI QA.
const Chapter = preload("res://scripts/chapters/chapter3.gd")
const FIXTURE = "res://tests/fixtures/c3_canteen_devices_source.json"
var checks: int = 0
var errors: int = 0
var scenarios: int = 0
var steps: int = 0
var source: Dictionary = {}

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		errors += 1
		push_error(label)

func merge_fixture(target: Dictionary, patch: Dictionary) -> void:
	for key: Variant in patch:
		if patch[key] is Dictionary and target.get(key) is Dictionary:
			merge_fixture(target[key], patch[key])
		else:
			target[key] = patch[key].duplicate(true) if patch[key] is Dictionary or patch[key] is Array else patch[key]

func initial(oracle: Dictionary, family: String) -> Dictionary:
	var s: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/initial_state.json"))
	merge_fixture(s, oracle)
	var scene: String = "campus_bootstrap" if family == "bike" else "canteen_interior"
	s.native = {"chapter":3, "page":"c3_bike" if family == "bike" else "c3_canteen",
		"scene":scene, "mode":s.canteenHunt.mode, "player":{}, "selected_item":"",
		"log":[], "completed":[], "settings":{"reduced_motion":true}}
	s.rpgScene = scene
	s.runtimeMode = "rpg"
	s.canteenHunt.entryPaperEscaped = true
	return s

func fixture_position(s: Dictionary, chapter: RefCounted, family: String, step: Dictionary) -> String:
	# Controller tests remove distance as an independent variable. The separate
	# pointer/control test suite owns genuine world input and device hit targets.
	if family == "bike":
		var bike_args: Array = source.bike.presentations[0].bike.args
		s.native.player = {"x":bike_args[0], "y":bike_args[1]}
		return "bike"
	var target: String = "ordering_kiosk"
	if family == "drink":
		var item_id: String = str(step.args[0])
		target = ""
		for machine: Dictionary in chapter.world("canteen_interior").constants.CANTEEN_DRINK_MACHINES:
			if str(machine.value) == item_id:
				target = str(machine.id)
				break
	check(not target.is_empty(), "fixture maps source ingredient to authored drink machine")
	var entry: Dictionary = chapter.get_definition("canteen_interior", target, s)
	check(not entry.is_empty(), "fixture has authored target " + target)
	if not entry.is_empty():
		var point: Dictionary = entry.get("stand", {"x":entry.x, "y":entry.y})
		s.native.player = {"x":point.x, "y":point.y}
	return target

func invoke(s: Dictionary, chapter: RefCounted, method: String, args: Array, target: String) -> Dictionary:
	match method:
		"collectDrink": return chapter.dispatch(s, "c3_drink_take:" + target)
		"inspectMenuClue": return chapter.dispatch(s, "c3_menu_observe")
		"selectMenuOption": return chapter.dispatch(s, "c3_order", args[0])
		"inspectBikeLock": return chapter.dispatch(s, "c3_bike_inspect")
		"cleanBikeLock": return chapter.dispatch(s, "c3_bike_clean")
		"payForBike": return chapter.dispatch(s, "c3_bike_pay")
		"startChase": return chapter.dispatch(s, "c3_chase")
	check(false, "unmapped source method " + method)
	return {}

func finish_order_dialogue(s: Dictionary, chapter: RefCounted, result: Dictionary) -> void:
	if not result.get("narrative_owned", false): return
	var session: RefCounted = chapter.narrative_session(s)
	check(session != null and session.sequence_id == "canteen_order", "accepted order owns its existing source dialogue")
	if session == null or session.sequence_id != "canteen_order": return
	var host := Node.new()
	root.add_child(host)
	check(session.attach(s, host), "order fixture attaches genuine narrative host")
	for _frame in range(1000):
		if session.status != "playing": break
		session.frame(s, 100, host)
	check(session.status == "complete", "source order dialogue reaches terminal receipt")
	chapter.dispatch(s, "c3_story_complete", session)
	host.free()

func compare_state(s: Dictionary, baseline: Dictionary, expected: Dictionary, label: String) -> void:
	# Compare entire native inventory/wallet and entire canteen dictionary after
	# applying only the original source delta. Unrelated native state must survive.
	for group: String in ["items", "wallet", "canteenHunt"]:
		var oracle: Dictionary = baseline[group].duplicate(true)
		merge_fixture(oracle, expected[group])
		for key: Variant in oracle:
			check(s[group].get(key) == oracle[key], "%s %s.%s expected %s, got %s" % [label, group, str(key), str(oracle[key]), str(s[group].get(key))])
		for key: Variant in s[group]:
			check(oracle.has(key), "%s cannot add unexpected %s.%s" % [label, group, str(key)])

func compare_result(s: Dictionary, before: Dictionary, step: Dictionary, result: Dictionary, label: String) -> void:
	# Native feedback is a Dictionary rather than a TS result enum. Compare the
	# observable acceptance/transaction contract, without equating feedback shapes.
	check(result.get("handled", false), label + " reaches a handled native action")
	var method: String = str(step.method)
	var outcome: Variant = step.result
	if method == "startChase":
		check(result.has("game") == bool(outcome), label + " starts riding only for source-accepted request")
	elif method == "collectDrink":
		var item_id: String = str(step.args[0])
		check(bool(s.items.get(item_id, false)) == (bool(outcome) or bool(before.items.get(item_id, false))), label + " grant/refusal matches source return")
	elif method == "inspectMenuClue":
		check(bool(s.canteenHunt.menuDarkClueRead) == (bool(outcome) or bool(before.canteenHunt.menuDarkClueRead)), label + " observation result matches source")
	elif method == "selectMenuOption":
		var accepted: bool = str(outcome) in ["correct", "wrong"]
		check(bool(result.get("narrative_owned", false)) == accepted, label + " only accepted source order starts dialogue")
		if accepted:
			check(s.canteenHunt.orderedMenuOption == step.args[0], label + " accepted option stays exact")
	elif method == "inspectBikeLock":
		check(not result.has("game"), label + " inspection cannot start riding")
		if str(outcome) == "code_read": check(s.canteenHunt.bikeCodeRead, label + " source code read is recorded")
		if str(outcome) in ["glare", "payment_ready", "dark_rejected"]:
			check(not str(result.get("message", "")).is_empty(), label + " inspection result stays readable")
	elif method == "cleanBikeLock" and str(outcome) == "cleaned":
		check(s.canteenHunt.bikeLockCleaned and s.items.greaseTissue, label + " successful cleaning retains tissue")
	elif method == "payForBike" and str(outcome) == "paid":
		check(s.canteenHunt.bikePaid, label + " accepted payment records paid fact")
		check(not result.has("game"), label + " payment cannot start riding by itself")

func run_scenario(family: String, sample: Dictionary) -> void:
	scenarios += 1
	var chapter: RefCounted = Chapter.new()
	var s: Dictionary = initial(sample.initial, family)
	var baseline: Dictionary = s.duplicate(true)
	var index: int = 0
	for step: Dictionary in sample.steps:
		steps += 1
		var label: String = "%s/%s step %d %s -> %s" % [family, sample.name, index, step.method, str(step.result)]
		var target: String = fixture_position(s, chapter, family, step)
		var before: Dictionary = s.duplicate(true)
		var result: Dictionary = invoke(s, chapter, str(step.method), step.args, target)
		compare_result(s, before, step, result, label)
		compare_state(s, baseline, step.state, label)
		finish_order_dialogue(s, chapter, result)
		compare_state(s, baseline, step.state, label + " after presentation")
		index += 1
	# Cancel presentation-only pending promo data on scope exit, without consuming
	# its receipt or changing source state in the rejected drink fixture.
	if chapter.story != null: chapter.story.cancel()

func run() -> void:
	check(ProjectSettings.globalize_path("user://").begins_with("/tmp/"), "source parity test uses isolated /tmp profile")
	if errors:
		quit(1)
		return
	source = JSON.parse_string(FileAccess.get_file_as_string(FIXTURE))
	check(source.get("schemaVersion") == 1, "executed-source fixture schema supported")
	check(source.sources.size() == 5 and source.extracted.size() == 3, "source hashes and extracted method provenance present")
	for sample: Dictionary in source.drinkControllerScenarios: run_scenario("drink", sample)
	for sample: Dictionary in source.menu.controllerScenarios: run_scenario("menu", sample)
	for sample: Dictionary in source.bike.controllerScenarios: run_scenario("bike", sample)
	print("C3 canteen executed-source parity: %d scenarios, %d steps, %d checks, %d failures" % [scenarios, steps, checks, errors])
	quit(1 if errors else 0)
