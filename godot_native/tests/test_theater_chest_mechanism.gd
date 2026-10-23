extends SceneTree
const Chapter = preload("res://scripts/chapters/chapter3.gd")
var checks: int = 0
var failures: int = 0

func _initialize() -> void: run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("THEATER_CHEST_MECHANISM: " + label)

func initial() -> Dictionary:
	var state: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/initial_state.json"))
	state.native = {"chapter": 3, "scene": "theater_interior", "page": "c3_theater", "mode": "light", "player": {"scene": "theater_interior", "x": 294, "y": 228}, "settings": {}, "log": [], "completed": []}
	state.runtimeMode = "rpg"; state.rpgScene = "theater_interior"; state.rpgCheckpoint = "theater_stage"
	state.theaterHunt.merge({"active": true, "admitted": true, "phase": "prop_setup", "mode": "light", "propBoxOpened": true}, true)
	state.items.fluorescentBrush = true; state.items.spotlightRemote = true
	return state

func begin(chapter: RefCounted, state: Dictionary) -> Dictionary:
	var result: Dictionary = chapter.dispatch(state, "c3_chest_begin")
	check(result.get("accepted", false) and result.get("ephemeral", false), "ordinary source chest issues runtime-only mechanism")
	return result.get("mechanism", {})

func act(chapter: RefCounted, state: Dictionary, token: Dictionary, action: String, extra: Dictionary = {}) -> Dictionary:
	var value: Dictionary = extra.duplicate(true)
	value.session = token.duplicate(true)
	return chapter.dispatch(state, "c3_chest_" + action, value)

func solve(chapter: RefCounted, state: Dictionary, token: Dictionary) -> Dictionary:
	for index: int in range(3):
		check(act(chapter, state, token, "place", {"piece": ["butterfly", "lamp", "fan"][index], "slot": index}).get("accepted", false), "place authored symbol %d" % index)
	check(act(chapter, state, token, "place", {"piece": "crank", "slot": "axle"}).get("accepted", false), "mount crank")
	var rotated: Dictionary = act(chapter, state, token, "turn", {"direction": 1})
	check(rotated.get("accepted", false) and rotated.mechanism.slots == ["fan", "butterfly", "lamp"], "crank rotates physical symbol order")
	return act(chapter, state, token, "open")

func mutate_context(state: Dictionary, fault: String) -> void:
	match fault:
		"distance": state.native.player.x = 1500
		"dark": state.native.mode = "dark"
		"unadmitted": state.theaterHunt.admitted = false
		"inactive": state.theaterHunt.active = false
		"closed": state.theaterHunt.propBoxOpened = false
		"phase": state.theaterHunt.phase = "spotlight_ready"
		"runtime": state.runtimeMode = "phone"
		"scene": state.native.scene = "qizhen_lake"
		"rpg_scene": state.rpgScene = "qizhen_lake"
		"checkpoint": state.rpgCheckpoint = "elsewhere"

func run() -> void:
	var chapter = Chapter.new()
	var state: Dictionary = initial()
	var before: String = JSON.stringify(state)
	var mechanism: Dictionary = begin(chapter, state)
	check(JSON.stringify(state) == before, "begin does not mutate any save field")
	if mechanism.is_empty(): quit(1); return
	var token: Dictionary = mechanism.session
	check(begin(chapter, state).session == token, "repeated begin retains mounted session")
	mechanism.slots[0] = "fan"; mechanism.session.nonce = "copy-edit"
	check(begin(chapter, state).slots == ["", "", ""], "returned arrays cannot mutate authoritative model")
	token = begin(chapter, state).session
	check(not act(chapter, state, token, "open").accepted, "empty mechanism does not release drawer")
	check(not act(chapter, state, token, "turn", {"direction": 1}).accepted, "wheel requires its crank")
	var inspected: Dictionary = act(chapter, state, token, "inspect")
	check(inspected.accepted and inspected.mechanism.clue_open and inspected.mechanism.clue_order == ["fan", "butterfly", "lamp"], "clue card reveals matching symbol order")
	check(not act(chapter, state, token, "inspect").mechanism.clue_open, "clue closes locally")
	for invalid: Dictionary in [{"piece": "fan", "slot": -1}, {"piece": "fan", "slot": 3}, {"piece": "fan", "slot": 1.5}, {"piece": "fan", "slot": true}, {"piece": "fan", "slot": "0"}, {"piece": "invalid", "slot": 0}, {"piece": "crank", "slot": 0}]:
		check(not act(chapter, state, token, "place", invalid).accepted, "reject malformed placement " + JSON.stringify(invalid))
	act(chapter, state, token, "place", {"piece": "fan", "slot": 0})
	act(chapter, state, token, "place", {"piece": "butterfly", "slot": 1})
	var swapped: Dictionary = act(chapter, state, token, "place", {"piece": "fan", "slot": 1})
	check(swapped.mechanism.slots == ["butterfly", "fan", ""], "moving a placed tile swaps without duplication")
	var replaced: Dictionary = act(chapter, state, token, "place", {"piece": "lamp", "slot": 0})
	check(replaced.mechanism.remaining.has("butterfly") and replaced.mechanism.slots == ["lamp", "fan", ""], "displaced tile returns to floor")
	var opened: Dictionary = solve(chapter, state, token)
	check(opened.accepted and opened.mechanism.drawer_open, "valid physical arrangement reveals vent diagram")
	check(act(chapter, state, token, "open").accepted, "drawer open is idempotent")
	check(not act(chapter, state, token, "turn", {"direction": 1}).accepted, "opened drawer freezes wheel")
	check(JSON.stringify(state) == before, "complete mechanism has no story, evidence, inventory or save writes")
	check(act(chapter, state, token, "cancel").cancelled, "matching close retires session")
	check(not act(chapter, state, token, "open").accepted, "closed session cannot reopen drawer")
	var fresh: Dictionary = begin(chapter, state)
	check(fresh.session != token and fresh.slots == ["", "", ""] and not fresh.drawer_open, "reopening resets local pieces with a new capability")
	check(not act(chapter, state, token, "cancel").cancelled and begin(chapter, state).session == fresh.session, "old cancellation does not retire newer session")
	var forged: Dictionary = fresh.session.duplicate(true); forged.nonce = "forged"
	var rejection: Dictionary = act(chapter, state, forged, "inspect")
	check(not rejection.accepted and not rejection.has("mechanism"), "forged capability neither mutates model nor leaks replacement token")
	check(not Chapter.new().dispatch(state, "c3_chest_open", {"session": fresh.session}).accepted, "fresh controller cannot restore runtime session from saved state")
	for fault: String in ["distance", "dark", "unadmitted", "inactive", "closed", "phase", "runtime", "scene", "rpg_scene"]:
		state = initial(); mutate_context(state, fault); before = JSON.stringify(state)
		check(not chapter.dispatch(state, "c3_chest_begin").accepted and JSON.stringify(state) == before, "begin rejects " + fault)
	for fault: String in ["distance", "dark", "unadmitted", "inactive", "closed", "phase", "runtime", "scene", "rpg_scene", "checkpoint", "owner"]:
		state = initial(); token = begin(chapter, state).session
		if fault == "owner": state = state.duplicate(true)
		else: mutate_context(state, fault)
		before = JSON.stringify(state)
		check(not act(chapter, state, token, "inspect").accepted and JSON.stringify(state) == before, "every action rejects stale " + fault)
	# The existing scanner and vent remain the only item/progression transactions.
	state = initial(); state.theaterHunt.propBoxOpened = false; state.items.fluorescentBrush = false; state.items.temporaryTheaterTicket = true
	var scanner: Dictionary = chapter.get_definition("theater_interior", "theater_prop_scanner", state)
	state.native.player = scanner.stand.duplicate()
	check(Vector2(state.native.player.x, state.native.player.y) == Vector2(420, 218) and not chapter.can_operate(state, "theater_interior", "theater_prop_box"), "authored scanner stand lies outside the separate box proximity")
	chapter.dispatch(state, "c3_target:theater_prop_scanner")
	check(state.theaterHunt.propBoxOpened and state.items.fluorescentBrush and not state.items.temporaryTheaterTicket, "original scanner still exchanges ticket for brush immediately")
	before = JSON.stringify(state); token = begin(chapter, state).session
	check(act(chapter, state, token, "inspect").accepted and JSON.stringify(state) == before, "scanner stand can inspect mechanism after original scan without moving player or changing rewards")
	check(not act(chapter, state, token, "open").accepted, "fresh drawer remains locked independently of existing brush reward")
	var vent: Dictionary = chapter.get_definition("theater_interior", "theater_backstage_vent", state)
	state.native.player = vent.stand.duplicate()
	chapter.dispatch(state, "c3_target:theater_backstage_vent")
	check(state.theaterHunt.paperDusted and state.theaterHunt.phase == "spotlight_ready" and not state.items.fluorescentBrush, "unsolved optional mechanism does not become a new mainline gate")
	await test_state_boundary()
	print("THEATER_CHEST_MECHANISM: %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)

func test_state_boundary() -> void:
	var global_state: Node = root.get_node("State")
	global_state.d = global_state.initial(); global_state.d.merge(initial(), true)
	global_state.modules[1] = Chapter.new()
	var events: Dictionary = {"changed": 0}
	var listener: Callable = func(): events.changed += 1
	global_state.changed.connect(listener)
	var before: String = JSON.stringify(global_state.d)
	var opened: Dictionary = global_state.act("c3_chest_begin")
	check(opened.get("accepted", false), "real State dispatch accepts source chest")
	if opened.has("mechanism"):
		var token: Dictionary = opened.mechanism.session
		global_state.act("c3_chest_open", {"session": token})
		global_state.act("c3_chest_inspect", {"session": token})
		check(events.changed == 0 and JSON.stringify(global_state.d) == before, "real State rejection/inspection skips save log and changed emission")
		check(global_state.cancel_progressive_activity("c3_chest_cancel", {"session": token}), "modal teardown can retire exact capability outside normal dispatch")
		check(not global_state.act("c3_chest_inspect", {"session": token}).get("accepted", false), "cancelled global session cannot act")
		opened = global_state.act("c3_chest_begin")
		global_state._invalidate_progressive_activities()
		check(not global_state.act("c3_chest_open", {"session": opened.mechanism.session}).get("accepted", false), "shared navigation invalidation retires chest session")
	global_state.changed.disconnect(listener)
	await process_frame
