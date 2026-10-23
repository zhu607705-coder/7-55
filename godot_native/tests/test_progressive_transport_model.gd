extends SceneTree
## Test-only paths never enter the runtime snapshot, hints or level catalog.
const Model = preload("res://scripts/games/progressive_transport_model.gd")
const SOLUTIONS := "res://tests/fixtures/progressive-transport-solutions.json"
var checks := 0
var failures := 0
var fixtures: Dictionary = {}

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, detail: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("PROGRESSIVE TRANSPORT: " + detail)

func walk(model: RefCounted, actions: Array, label: String) -> void:
	for i: int in range(actions.size()):
		var result: Dictionary = model.apply(actions[i])
		check(result.get("accepted", false), label + " legal action " + str(i) + ": " + str(actions[i]))

func stage_paths(id: String) -> Array:
	return fixtures.puzzles[id].stages

func enter_stage(id: String, index: int) -> RefCounted:
	var model = Model.new(id)
	for i: int in range(index):
		walk(model, stage_paths(id)[i], id + " enter stage " + str(i))
		check(model.apply("continue").accepted, "completed stage accepts explicit Continue")
	return model

func test_trace_boundary() -> void:
	for id: String in ["power_topology", "evacuation_route", "lake_logistics"]:
		var model = Model.new(id)
		var before: Dictionary = model.snapshot()
		check(before.stageCount == 3 and not before.complete and not before.stageComplete, id + " starts at unfinished first layout")
		check(not model.apply("continue").accepted and not model.apply("wait").accepted, id + " Continue/wait cannot replace play")
		check(not model.apply("undo").accepted, id + " no undo before a real action")
		check(model.proof().actions.is_empty(), id + " rejected attempts do not enter proof")
		var empty: Dictionary = Model.replay(id, [])
		check(empty.valid and not empty.completed and empty.controllerValue.is_empty(), id + " empty well-typed trace grants no answer")
		var digest: String = Model.layout_digest(id)
		check(digest.length() == 64 and digest == Model.layout_digest(id), id + " stable authored layout digest")
	check(Model.layout_digest("unknown") == "", "unknown layout has no digest")
	check(not Model.replay("unknown", []).valid, "unknown puzzle rejected")
	for malformed: Variant in [null, {}, "right", [1], ["wait"], ["continue"], ["undo"]]:
		check(not Model.replay("power_topology", malformed).valid, "malformed or illegal trace rejected: " + str(malformed))
	var oversized: Array = []
	oversized.resize(Model.MAX_ACTIONS + 1)
	oversized.fill("restart")
	check(not Model.replay("power_topology", oversized).valid, "trace over 4096 rejected before replay")

func test_pressure_exit_and_isolation() -> void:
	var model = Model.new("power_topology")
	walk(model, ["up", "right", "right", "right", "right", "down"], "actor temporarily occupies plate")
	var state: Dictionary = model.snapshot()
	check(state.plates[0].active and state.gates[0].open, "actor occupancy physically opens gate")
	check(not state.localGoal and not state.stageComplete, "person on plate cannot replace module goal or actor exit")
	check(model.apply("up").accepted and not model.snapshot().gates[0].open, "leaving plate closes unoccupied gate")
	model = Model.new("power_topology")
	walk(model, ["right", "right", "right"], "put module on plate")
	state = model.snapshot()
	check(state.localGoal and state.exitReady and not state.stageComplete and not state.complete, "module at target still requires actor to reach exit")
	check(not model.apply("continue").accepted, "local object goal alone cannot advance stage")
	var copy: Dictionary = model.snapshot()
	copy.objects[0].x = 99
	copy.actor.x = 99
	copy.tiles.clear()
	check(model.snapshot().objects[0].x == 5 and model.snapshot().actor.x == 4 and model.snapshot().tiles.size() == 4, "snapshot is defensive for objects, actor and board")
	var proof: Dictionary = model.proof()
	proof.actions.clear()
	check(model.proof().actions.size() == 3, "proof cannot mutate live action log")
	var other = Model.new("power_topology")
	var lake = Model.new("lake_logistics")
	check(other.snapshot().objects[0].x == 3 and lake.snapshot().objects[0].x == 3, "independent instances and puzzle IDs do not share occupancy")
	var count: int = model.proof().actions.size()
	check(not model.apply("right").accepted and model.proof().actions.size() == count, "wall-blocked push changes neither position nor trace")

func test_undo_restart_operation_side() -> void:
	var model = Model.new("power_topology")
	check(model.apply("right").accepted, "ordinary move for restart test")
	var before: Dictionary = model.snapshot()
	check(model.apply("restart").accepted and model.snapshot().actor.x == 1, "restart resets only current layout")
	check(model.apply("undo").accepted, "restart itself is undoable")
	check(model.snapshot().actor == before.actor and model.snapshot().objects == before.objects, "undo restart restores precise actor and objects")
	var replayed: Dictionary = Model.replay("power_topology", model.proof().actions)
	check(replayed.valid and replayed.snapshot.actor == before.actor, "restart/undo semantics replay deterministically")
	model = enter_stage("power_topology", 2)
	walk(model, ["down", "right", "right", "right", "right"], "plausible one-push-too-far wrong route")
	check(model.snapshot().objects[1].x == 6, "wrong route can occupy corner beyond desired target")
	walk(model, ["up", "right"], "inspect corner from above")
	var count: int = model.proof().actions.size()
	check(not model.apply("down").accepted and model.proof().actions.size() == count, "missing operation side cannot be bypassed by pushing through wall")
	check(model.apply("undo").accepted, "wrong path remains locally reversible")
	check(model.apply("restart").accepted and model.snapshot().stageIndex == 2, "restart preserves two prior completed layouts")
	check(model.apply("undo").accepted and model.snapshot().stageIndex == 2, "undo restart stays in same completed-prefix boundary")
	model = enter_stage("power_topology", 1)
	check(not model.apply("undo").accepted and model.snapshot().stageIndex == 1, "cannot undo Continue into already-finished layout")

func test_width_and_return() -> void:
	var model = enter_stage("lake_logistics", 1)
	check(model.snapshot().actor.kind == "boat" and model.snapshot().objects[0].width == 2, "lake variant retains boat and wider physical tool")
	check(model.apply("down").accepted, "wide tool can approach narrow opening")
	var count: int = model.proof().actions.size()
	check(not model.apply("down").accepted, "one-cell opening rejects complete two-cell footprint")
	check(model.snapshot().objects[0].y == 3 and model.proof().actions.size() == count, "partial-footprint failure is atomic")
	check(model.apply("undo").accepted and model.snapshot().objects[0].y == 2, "width mistake has ordinary local undo")
	model = Model.new("evacuation_route")
	walk(model, stage_paths("evacuation_route")[0].slice(0, 7), "reach record without returning")
	check(model.snapshot().checkpoints[0].visited and model.snapshot().localGoal, "actual excursion records checkpoint")
	check(not model.snapshot().stageComplete and not model.apply("continue").accepted, "record and object goal cannot stand in for returning person")
	model = enter_stage("lake_logistics", 2)
	check(not model.snapshot().localGoal and not model.snapshot().complete, "home tool and boat at spawn do not bypass outbound delivery")
	walk(model, stage_paths("lake_logistics")[2].slice(0, 13), "reach actual delivery record")
	check(model.snapshot().checkpoints[0].visited and not model.snapshot().localGoal, "delivery alone cannot skip same-tool recovery")

func test_visible_circuit_data() -> void:
	var model = enter_stage("power_topology", 2)
	var state: Dictionary = model.snapshot()
	check(state.connectionDetails.size() == 7 and state.circuitZones.size() == 5, "final layout exposes seven real links and original five visible zones")
	var contacts: Dictionary = {}
	for detail: Dictionary in state.connectionDetails:
		check(not detail.active and state.connections[detail.id] == "off", "untouched link exposes actual off state: " + str(detail.id))
		check(state.circuitZones.any(func(zone: Dictionary) -> bool: return zone.id == detail.from) and state.circuitZones.any(func(zone: Dictionary) -> bool: return zone.id == detail.to), "link endpoints refer to visible authored zones")
		check(str(detail.contact.label).begins_with("接点 ") and not detail.has("expected"), "contact exposes neutral label rather than desired answer")
		contacts[detail.contactId] = true
	check(contacts.size() == 4 and not state.has("expectedConnections"), "contact metadata groups physical positions without publishing the target edge set")
	state.connectionDetails[0].contact.x = 99
	state.circuitZones[0].label = "mutated"
	check(model.snapshot().connectionDetails[0].contact.x == 5 and model.snapshot().circuitZones[0].label == "大厅", "visible graph metadata is defensive")
	walk(model, stage_paths("power_topology")[2], "visible contacts final layout")
	state = model.snapshot()
	for detail: Dictionary in state.connectionDetails:
		check(detail.active == (state.connections[detail.id] == "on") and detail.contact.active == detail.active, "visual link and physical contact share actual occupancy: " + str(detail.id))

func test_three_stage_replay() -> void:
	var expected_edges := {"hall__west_corridor": "on", "hall__east_corridor": "on", "west_corridor__bakery_back_area": "on", "east_corridor__classroom_zone": "on", "bakery_back_area__classroom_zone": "on", "west_corridor__east_corridor": "off", "hall__classroom_zone": "off"}
	var expected_route := {"a": "lecture_202_door", "b": "east_corridor", "c": "transport_core", "d": "main_stair_down"}
	for id: String in ["power_topology", "evacuation_route", "lake_logistics"]:
		var model = Model.new(id)
		for i: int in range(3):
			check(model.snapshot().stageIndex == i, id + " exact stage boundary " + str(i))
			walk(model, stage_paths(id)[i], id + " solution stage " + str(i))
			check(model.snapshot().stageComplete, id + " actual exit completes stage " + str(i))
			check(model.snapshot().complete == (i == 2), id + " total completion only after final actual exit")
			if i < 2: check(model.apply("continue").accepted, id + " explicit transition " + str(i))
		var proof: Dictionary = model.proof()
		var result: Dictionary = Model.replay(id, proof.actions)
		check(result.valid and result.completed, id + " bounded real trace independently replays")
		check(result.snapshot.actor == model.snapshot().actor and result.snapshot.objects == model.snapshot().objects, id + " replay equals actual final board")
		if id == "power_topology":
			check(result.controllerValue == expected_edges, "physical contacts derive exact original seven-edge state")
		elif id == "evacuation_route":
			check(result.controllerValue == expected_route and result.snapshot.checkpointOrder == expected_route.values(), "actual four-place route derives original authored values")
		else:
			check(result.controllerValue.is_empty() and result.snapshot.localOnly, "lake side game has no main-story result or inventory value")
		var shortened: Array = proof.actions.duplicate()
		shortened.pop_back()
		var incomplete: Dictionary = Model.replay(id, shortened)
		check(incomplete.valid and not incomplete.completed and incomplete.controllerValue.is_empty(), id + " missing final actor step cannot claim controller result")
		check(model.apply("undo").accepted and not model.snapshot().complete, id + " completion remains undoable before controller handoff")
		var mixed: Array = proof.actions.duplicate()
		mixed.insert(0, "continue")
		check(not Model.replay(id, mixed).valid, id + " valid suffix cannot hide illegal prefix")

func run() -> void:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(SOLUTIONS))
	check(parsed is Dictionary and parsed.has("puzzles"), "test-only solution fixture available")
	if not parsed is Dictionary or not parsed.has("puzzles"):
		quit(1)
		return
	fixtures = parsed
	test_trace_boundary()
	test_pressure_exit_and_isolation()
	test_undo_restart_operation_side()
	test_width_and_return()
	test_visible_circuit_data()
	test_three_stage_replay()
	print("PROGRESSIVE_TRANSPORT_MODEL: ", checks, " checks, ", failures, " failures")
	quit(1 if failures else 0)
