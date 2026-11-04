extends SceneTree
## Prerequisites below are declared checkpoints; all tested rewards and receipts
## come from the existing controllers, never from the presentation model.
const Feedback = preload("res://scripts/presentation/npc_interaction_feedback.gd")
const Bindings = preload("res://scripts/presentation/npc_feedback_bindings.gd")
const CanteenFixture = preload("res://tests/canteen_native_fixture.gd")
const Metrics = preload("res://scripts/player_metrics.gd")
const C4_SCENE := "duan_yongping_temporal_maze"
var checks := 0
var failures := 0

class PresentationHost extends Control:
	# Only shell visibility/modal ownership is simulated. State and world remain real.
	var world_frame: Control
	var active_game: Node
	var world_effect: Node
	var modal: Node
	var phone_document: Node
	var c3_narrative_host: Node
	var c3_scene_host: Node
	var library_story_host: Node

class FilmOwner extends Node:
	func owns_world_contract() -> bool: return true
	func blocks_input() -> bool: return true
	func blocks_movement() -> bool: return true

func _initialize() -> void: run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("NPC_PIXEL_FEEDBACK: " + label)

func has_effect(model: RefCounted, id: String, kind: String) -> bool:
	return model.effects.any(func(effect: Dictionary) -> bool: return effect.id == id and effect.kind == kind)

func test_model() -> void:
	var state := {"items": {"campusCard": true}, "chapter": 2}
	var before := state.duplicate(true)
	var model: RefCounted = Feedback.new()
	model.bind("library", state)
	model.advance(0.08, "clerk")
	check(model.effects.is_empty(), "a passing frame does not flash an approach cue")
	model.advance(0.05, "clerk")
	check(has_effect(model, "clerk", "approach"), "stable proximity earns one approach cue")
	model.advance(0.5, "clerk")
	model.advance(4.0, "clerk")
	check(model.effects.is_empty(), "remaining beside a person does not loop the cue")
	model.reset(); model.bind("library", state)
	model.advance(0.13, "clerk")
	model.advance(0.5, "")
	model.advance(0.13, "clerk")
	check(model.effects.is_empty(), "radius edge re-entry does not retrigger within cooldown")
	model.advance(0.2, ""); model.advance(0.13, "clerk")
	check(model.effects.is_empty(), "repeated boundary jitter remains quiet")
	model.advance(0.85, ""); model.advance(0.13, "clerk")
	check(has_effect(model, "clerk", "approach"), "a later distinct approach can be acknowledged")
	var old_clock: float = model.clock
	model.advance(-1.0, "clerk")
	check(model.clock == old_clock, "negative elapsed input cannot rewind presentation")
	check(model.play("clerk", "dialogue") and has_effect(model, "clerk", "dialogue"), "accepted speech replaces approach")
	check(model.play("clerk", "complete", "receipt-a") and has_effect(model, "clerk", "complete"), "earned completion takes priority over speech")
	check(not model.play("clerk", "dialogue") and not model.play("clerk", "approach"), "lower priority cues cannot obscure success")
	check(not model.play("clerk", "complete", "receipt-a"), "same success receipt cannot replay immediately")
	model.advance(1.0, "", false)
	check(model.effects.is_empty() and not model.play("clerk", "complete", "receipt-a"), "an expired success receipt stays consumed in its owner")
	model.play("one", "complete", "one"); model.play("two", "complete", "two"); model.play("three", "complete", "three")
	check(model.effects.size() == 3, "the cue pool has three bounded slots")
	check(not model.play("four", "approach") and model.effects.size() == 3, "a low priority fourth cue cannot displace completions")
	check(model.play("four", "complete", "four") and model.effects.size() == 3, "new success remains bounded without a particle backlog")
	check(not model.play("", "dialogue") and not model.play("clerk", "unknown"), "invalid cue requests are inert")
	model.bind("library", state)
	check(model.effects.size() == 3, "an ordinary refresh preserves the same live owner")
	model.bind("library", state.duplicate(true))
	check(model.effects.is_empty() and model.completed.is_empty(), "same-scene load replaces the owner and retires transient receipts")
	model.play("clerk", "dialogue"); model.bind("other-floor", state)
	check(model.effects.is_empty(), "context handoff retires previous actors")
	check(state == before, "model timing and consumption cannot mutate gameplay state")

func test_pixels_and_placement() -> void:
	var all_colors: Dictionary = {}
	for kind: String in ["approach", "dialogue", "complete"]:
		var duration: float = Feedback.DURATIONS[kind]
		var frames: Array[int] = []
		var integer_geometry := true
		var positive_geometry := true
		var reduced_static := true
		for index: int in range(8):
			var age := duration * (float(index) + 0.5) / 8.0
			var frame: int = Feedback.frame_for(kind, age, false)
			frames.append(frame)
			reduced_static = reduced_static and Feedback.frame_for(kind, age, true) == 3
			var pixels: Array = Feedback.pixels(kind, frame)
			check(not pixels.is_empty(), kind + " has a real drawable frame " + str(index))
			for pixel: Dictionary in pixels:
				var rect: Rect2 = pixel.rect
				var color: Color = pixel.color
				integer_geometry = integer_geometry and rect.position == rect.position.round() and rect.size == rect.size.round()
				positive_geometry = positive_geometry and rect.has_area() and rect.position.is_finite() and rect.end.is_finite() and color.a > 0 and color.a <= 1
				all_colors[color.to_html(false)] = true
		check(frames == [0, 1, 2, 3, 4, 5, 6, 7], kind + " uses eight finite ordered frames")
		check(integer_geometry and positive_geometry, kind + " uses finite integer pixel clusters")
		check(reduced_static, kind + " reduced-motion cue keeps one static pose for its lifetime")
		check(Feedback.frame_for(kind, -0.1, false) == -1 and Feedback.frame_for(kind, duration, false) == -1, kind + " has no negative or post-expiry frame")
	check(all_colors.size() == 4, "all three motifs share four restrained colors")
	check(Feedback.pixels("dialogue", -1).is_empty() and Feedback.pixels("complete", 8).is_empty(), "invalid frame lookup cannot paint leftovers")
	var actor := Rect2(110, 90, 32, 52)
	var safe := Rect2(0, 0, 320, 240)
	var layout: Dictionary = Feedback.placement(actor, Vector2.ZERO, 1.0, safe)
	check(not layout.is_empty() and safe.encloses(layout.bounds) and not layout.bounds.intersects(actor), "preferred placement clears the actual actor silhouette")
	var excluded: Array[Rect2] = [layout.bounds.grow(1)]
	var side: Dictionary = Feedback.placement(actor, Vector2.ZERO, 1.0, safe, excluded)
	check(not side.is_empty() and not side.bounds.intersects(excluded[0]) and not side.bounds.intersects(actor), "blocked headroom moves the cue into a clear side position")
	check(Feedback.placement(actor, Vector2.ZERO, 1.0, Rect2(0, 0, 10, 10)).is_empty(), "no safe placement omits the cue instead of covering controls")

func prepare_deduction(state: Node) -> void:
	check(state.begin_checkpoint("c4-755-room204-1850"), "known C4 prerequisite checkpoint exists")
	state.d.chapter4.floor = "A2"
	state.d.chapter4.mode = "light"; state.d.native.mode = "light"
	state.d.native.page = "c4_device"; state.d.native.c4_context = "deduction"
	state.d.chapter4.factIds.erase("elevator_stop_chain_reconstructed")
	for fact: String in ["elevator_history_observed", "elevator_a2_call_record_observed", "elevator_a3_arrival_record_observed"]:
		if fact not in state.d.chapter4.factIds: state.d.chapter4.factIds.append(fact)

func test_controller_bindings(state: Node) -> void:
	check(Bindings.target_id("canteen_interior", {"id": "initial-queue-npc-2", "action": "c3_target:initial-queue-npc-2"}) == "initial-queue-npc-2", "authored queue actor can own a cue")
	check(Bindings.target_id("canteen_interior", {"id": "initial-queue-npc-02", "action": "c3_target:initial-queue-npc-02"}).is_empty(), "fabricated NPC suffix is rejected")
	check(Bindings.target_id(C4_SCENE, {"id": "a3_reference_teacher", "action": "c4_reference"}).is_empty(), "observation action cannot impersonate teacher dialogue")
	check(Bindings.target_id("library_interior", {"id": "front_desk", "action": "lib_front_desk", "decorative": true}).is_empty(), "decoration cannot become an interaction actor")
	for tray: String in ["tray_clean_01", "tray_blue_03"]:
		CanteenFixture.install(state)
		state.d.canteenHunt.returnedTrayIds = ["tray_blue_01", "tray_blue_02"]
		state.d.canteenHunt.carriedTrayIds = [tray]
		state.d.native.player = {"x": 1466.0, "y": 608.0}
		var before: Dictionary = state.d.duplicate(true)
		var result: Dictionary = state.act("c3_target:auntie")
		var id: String = Bindings.completion_target("c3_target:auntie", before, state.d, result)
		check(bool(result.get("narrative_owned", false)), "real return controller resolves the declared " + tray + " fixture")
		check(id == ("auntie" if tray == "tray_blue_03" else ""), "completion follows three correct trays, not returned-array length: " + tray)
		check(Bindings.completion_target("c3_target:auntie", before, state.d, {"handled": false}).is_empty(), "unhandled reply cannot manufacture completion")
	prepare_deduction(state)
	var before: Dictionary = state.d.duplicate(true)
	var wrong: Dictionary = state.act("c4_deduce", {"arrival": "A2", "unserved": "A3"})
	check(Bindings.completion_target("c4_deduce", before, state.d, wrong).is_empty(), "handled wrong deduction is not success")
	var result: Dictionary = state.act("c4_deduce", {"arrival": "A3", "unserved": "A2"})
	check(Bindings.completion_target("c4_deduce", before, state.d, result) == "a2_elevator_attendant", "real validated deduction creates one completion transition")
	before = state.d.duplicate(true)
	result = state.act("c4_deduce", {"arrival": "A3", "unserved": "A2"})
	check(Bindings.completion_target("c4_deduce", before, state.d, result).is_empty(), "repeated persisted C4 fact is not another task completion")

func finish_canteen_dialogue(state: Node) -> void:
	var story: RefCounted = state.get_c3_narrative_session()
	check(story != null, "real tray controller owns its authored dialogue")
	if story == null: return
	var owner := Node.new(); root.add_child(owner)
	check(story.attach(state.d, owner), "real narrative accepts one presentation owner")
	for index: int in range(1000):
		if story.status == "complete": break
		story.frame(state.d, 50, owner, true)
	state.act("c3_story_complete", story)
	check(story.status == "consumed", "authored dialogue finishes through its real capability")
	owner.free()

func test_world_paths(state: Node) -> void:
	check(state.begin_checkpoint("c4-755-room204-1850"), "teacher checkpoint opens")
	var world: Control = load("res://scripts/world.gd").new()
	world.size = Vector2(960, 540); root.add_child(world); world.set_process(false)
	world.chapter4_layers.phases.tick(0, state.d)
	var found: Array = world.targets.filter(func(target: Dictionary) -> bool: return target.id == "a3_reference_teacher")
	check(found.size() == 1, "real world exposes its one authored teacher")
	if found.is_empty(): world.free(); return
	var teacher: Dictionary = found[0]
	var point := Vector2(teacher.position[0], teacher.position[1])
	var chapter_before: Dictionary = state.d.chapter4.duplicate(true)
	world.player = Vector2(200, 700); world._try_interact(teacher)
	check(world.npc_feedback.effects.is_empty(), "too-far world interaction cannot emit speech")
	world.nearby = teacher; world._tick_npc_feedback(0.15)
	check(world.npc_feedback.effects.is_empty(), "stale nearby selection cannot flash from outside actual radius")
	world.player = point - Metrics.FOOT_CENTER_OFFSET + Vector2(0, 35)
	world._tick_npc_feedback(0.15)
	check(has_effect(world.npc_feedback, "a3_reference_teacher", "approach"), "actual nearby teacher receives the dwell cue")
	world._try_interact(teacher)
	check(has_effect(world.npc_feedback, "a3_reference_teacher", "dialogue"), "accepted real teacher reply reaches feedback")
	check(state.d.chapter4 == chapter_before and not has_effect(world.npc_feedback, "a3_reference_teacher", "complete"), "ordinary conversation grants no fact or completion")
	var clock: float = world.npc_feedback.clock
	var age: float = world.npc_feedback.effects[0].age
	world.notification(NOTIFICATION_APPLICATION_FOCUS_OUT); world._tick_npc_feedback(0.5)
	check(world.npc_feedback.clock == clock and world.npc_feedback.effects[0].age == age, "application focus loss freezes cue lifetime")
	world.notification(NOTIFICATION_APPLICATION_FOCUS_IN); world._tick_npc_feedback(0.05)
	check(world.npc_feedback.clock > clock, "returning focus resumes active elapsed time")
	world.hide()
	check(world.npc_feedback.effects.is_empty(), "hiding the world immediately retires its cues")
	world.show(); world.nearby = {}; world._tick_npc_feedback(0)
	check(world.npc_feedback.effects.is_empty(), "showing the world does not replay old cues")
	world.npc_feedback.play("a3_reference_teacher", "dialogue")
	state.d = state.d.duplicate(true); world.refresh_world()
	check(world.npc_feedback.effects.is_empty() and state.d.chapter4 == chapter_before, "same-scene state replacement clears presentation and preserves facts")
	world.npc_feedback.play("a3_reference_teacher", "dialogue")
	state.d.chapter4.floor = "A2"; world.refresh_world()
	check(world.npc_feedback.effects.is_empty(), "floor change cannot retain previous floor actor cues")
	var host := PresentationHost.new(); root.add_child(host)
	host.world_frame = Control.new(); host.add_child(host.world_frame)
	world.host_node = host
	world.npc_feedback.play("a2_elevator_attendant", "dialogue")
	host.world_frame.hide(); world._tick_npc_feedback(0)
	check(world.npc_feedback.effects.is_empty(), "hidden shell frame clears cues across a viewport boundary")
	host.world_frame.show()
	world.npc_feedback.play("a2_elevator_attendant", "dialogue")
	host.c3_narrative_host = FilmOwner.new(); host.add_child(host.c3_narrative_host)
	world._tick_npc_feedback(0)
	check(world.npc_feedback.effects.is_empty(), "an authored film owns the world without added NPC effects")
	host.c3_narrative_host.free(); host.c3_narrative_host = null
	world.npc_feedback.play("a2_elevator_attendant", "dialogue"); world.presentation_actor_hidden = true
	world._tick_npc_feedback(0)
	check(world.npc_feedback.effects.is_empty(), "a hidden presentation actor cannot leak its cue")
	world.presentation_actor_hidden = false
	prepare_deduction(state); world.refresh_world(); host.world_frame.hide()
	state.act("c4_deduce", {"arrival": "A3", "unserved": "A2"})
	check(not world._npc_completion_waiting.is_empty() and world.npc_feedback.effects.is_empty(), "real phone deduction holds a short receipt while its world is hidden")
	host.world_frame.show(); world._tick_npc_feedback(0.01)
	check(has_effect(world.npc_feedback, "a2_elevator_attendant", "complete") and world._npc_completion_waiting.is_empty(), "return to the same live deduction consumes the completion receipt once")
	world.npc_feedback.clear_visuals()
	state.act("c4_deduce", {"arrival": "A3", "unserved": "A2"})
	check(world.npc_feedback.effects.is_empty(), "repeated real deduction signal cannot re-award completion feedback")
	prepare_deduction(state); world.refresh_world(); host.world_frame.hide()
	state.act("c4_deduce", {"arrival": "A3", "unserved": "A2"})
	state.d = state.d.duplicate(true); world.refresh_world(); host.world_frame.show(); world.nearby = {}; world._tick_npc_feedback(0)
	check(world._npc_completion_waiting.is_empty() and world.npc_feedback.effects.is_empty(), "loading a completed same-scene save cannot replay a queued receipt")
	world.host_node = null; host.free()
	CanteenFixture.install(state)
	state.d.canteenHunt.returnedTrayIds = ["tray_blue_01", "tray_blue_02"]
	state.d.canteenHunt.carriedTrayIds = ["tray_blue_03"]
	world.refresh_world(); world.player = Vector2(1466, 608); world._sync_player()
	var aunties: Array = world.targets.filter(func(target: Dictionary) -> bool: return target.id == "auntie")
	check(aunties.size() == 1 and world.npc_feedback.effects.is_empty(), "scene handoff exposes the actual auntie without old floor cues")
	if not aunties.is_empty():
		var wallet_before: int = int(state.d.wallet.cashCents)
		world._try_interact(aunties[0])
		check(state.d.canteenHunt.returnedTrayIds.has("tray_blue_03") and state.d.items.cafeteriaWages, "third tray completes through the real world and original controller")
		check(int(state.d.wallet.cashCents) == wallet_before + 200, "controller awards the original wages exactly once")
		check(has_effect(world.npc_feedback, "auntie", "complete"), "actual action_completed signal reaches NPC success without dialogue overriding it")
		world._tick_npc_feedback(1.0)
		check(world.npc_feedback.effects.is_empty(), "world success cue expires while the existing dialogue continues")
		finish_canteen_dialogue(state)
		world._try_interact(aunties[0])
		check(not has_effect(world.npc_feedback, "auntie", "complete") and int(state.d.wallet.cashCents) == wallet_before + 200, "later ordinary conversation cannot replay completed task or wages")
	world.npc_feedback.play("auntie", "complete", "teardown")
	root.remove_child(world)
	check(world.npc_feedback.effects.is_empty() and world.npc_feedback.completed.is_empty(), "world teardown retires effects and receipts")
	check(not state.action_completed.is_connected(Callable(world, "_npc_action_completed")), "retired world disconnects its completion listener")
	world.free()

func run() -> void:
	create_timer(30).timeout.connect(func(): push_error("NPC_PIXEL_FEEDBACK: watchdog"); quit(2))
	var state: Node = root.get_node("State")
	state.developer_mode = true
	test_model()
	test_pixels_and_placement()
	test_controller_bindings(state)
	test_world_paths(state)
	await process_frame
	print("NPC_PIXEL_FEEDBACK: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
