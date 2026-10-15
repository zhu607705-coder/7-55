extends SceneTree
## A deterministic fixture routes real input through the Viewport, then advances
## only the game's existing clock. No phase, paddle, block, or proof assignments.
const Game = preload("res://scripts/games/prologue_interception.gd")
var checks := 0
var failures := 0
var game: Control
var events: Array = []
var results: Array = []
var observations: Array = []
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	observations.append({"check":message,"pass":ok,"phase":game.phase,"blocks":game.blocks,"misses":game.misses,"focus":str(root.gui_get_focus_owner())})
	if not ok: failures += 1; push_error("PROLOGUE FOCUS: " + message)
func frames(n: int = 2) -> void:
	for i in n: await process_frame
func tick(seconds: float) -> void:
	for i in int(round(seconds / .01)): game._process(.01)
func until_phase(target: String, seconds: float = 25.0) -> bool:
	for i in int(round(seconds / .01)):
		if game.phase == target: return true
		game._process(.01)
	return game.phase == target
func key(code: Key, down: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code; event.physical_keycode = code; event.pressed = down
	Input.parse_input_event(event)
	await frames(1)
func press(code: Key) -> void:
	await key(code, true); await key(code, false)
func click_at(point: Vector2) -> void:
	var motion := InputEventMouseMotion.new(); motion.position = point
	root.push_input(motion, true)
	for down in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT; event.pressed = down
		event.position = point; event.global_position = point
		root.push_input(event, true); await frames(1)
func click_continue() -> void:
	game._process(0)
	await click_at(game.resume_button.get_global_rect().get_center())
	game._process(0)
	await frames()
func count(id: String) -> int:
	return events.filter(func(e: Dictionary) -> bool: return e.id == id).size()
func run() -> void:
	root.size = Vector2i(430, 820)
	game = Game.new(); game.size = Vector2(430, 820)
	root.add_child(game); game.set_process(false)
	game.presentation_requested.connect(func(id: String, payload: Dictionary) -> void: events.append({"id":id,"payload":payload.duplicate(true)}))
	game.finished.connect(func(result: Dictionary) -> void: results.append(result.duplicate(true)))
	game.start({"resume":true}); game._process(0); await frames()
	check(root.gui_get_focus_owner() == game, "startup owns keyboard focus")
	await key(KEY_D, true)
	check(Input.is_physical_key_pressed(KEY_D), "physical held D is delivered through Input")
	check(until_phase("failed"), "three actual collision misses reach failure")
	await key(KEY_D, false)
	check(game.misses == 3 and game.blocks == 0, "initial failure is earned without proof writes")
	game._process(0); await click_at(game.retry.get_global_rect().get_center())
	check(game.phase == "deploy" and game.blocks == 0 and game.misses == 0, "pointer Retry resets round through the public control")
	check(root.gui_get_focus_owner() == game, "Retry restores root focus")
	await key(KEY_A, true)
	check(until_phase("impact", 5), "held A catches the first orb")
	await key(KEY_A, false)
	check(game.blocks == 1 and game.misses == 0, "first catch is a real collision")
	await press(KEY_ESCAPE)
	check(game.paused, "Escape pauses after the first catch")
	var frozen: float = game.elapsed
	tick(.5)
	check(game.elapsed == frozen, "pause freezes the game clock")
	await click_continue()
	check(not game.paused, "pointer Continue resumes")
	check(root.gui_get_focus_owner() == game, "Continue immediately restores root keyboard focus")
	await key(KEY_D, true); tick(.36)
	check(until_phase("impact", 4), "held D remains usable after Continue")
	await key(KEY_D, false)
	check(game.blocks == 2 and game.misses == 0, "second catch remains a real collision")
	await press(KEY_ESCAPE)
	check(game.paused, "Escape pauses again after Continue without a playfield click")
	# A failed baseline can recover with the same physical playfield click as CUA,
	# allowing the remaining hold checks to run without writing game state.
	if not game.paused:
		await click_at(Vector2(game.field.position.x + game.field.size.x * game.paddle / 100.0, 150)); await press(KEY_ESCAPE)
	await click_continue()
	check(root.gui_get_focus_owner() == game, "second Continue restores root keyboard focus")
	await key(KEY_A, true); tick(.54); await key(KEY_A, false)
	check(until_phase("lock", 4), "third orb reaches the lock through keyboard collision")
	check(game.blocks == 3 and game.misses == 0, "three catches preserve source completion requirements")
	await press(KEY_ESCAPE)
	check(game.paused, "Escape also pauses the lock")
	if not game.paused:
		await click_at(Vector2(215, 150)); await press(KEY_ESCAPE)
	await click_continue()
	check(root.gui_get_focus_owner() == game, "lock Continue restores Space input ownership")
	await key(KEY_SPACE, true); tick(.5)
	check(game.holding and game.hold_ms >= 499 and game.phase == "lock", "Space accumulates a partial hold immediately after Continue")
	await key(KEY_SPACE, false)
	check(not game.holding and game.hold_ms == 0 and results.is_empty(), "short Space release resets the hold and cannot finish")
	await key(KEY_SPACE, true); tick(.5); await press(KEY_ESCAPE)
	check(game.paused and not game.holding and game.hold_ms == 0, "pausing an active hold clears it")
	await key(KEY_SPACE, false); await click_continue()
	await key(KEY_SPACE, true); tick(1.39)
	check(game.phase == "lock" and results.is_empty(), "a fresh hold cannot succeed before 1400ms")
	tick(.02)
	check(game.phase == "caught" and game.hold_ms == 1400, "fresh full Space hold succeeds after repeated resumes")
	await key(KEY_SPACE, false)
	check(count("prologue_narrator_caught") == 1, "successful hold emits one caught cue")
	check(until_phase("whiteout", 11), "ordinary ending reaches whiteout")
	tick(.71)
	check(results.size() == 1 and results[0].interceptedCount == 3 and results[0].lockHeldMs == 1400 and results[0].whiteoutCompleted, "normal ending reports exact earned proof once")
	var report := OS.get_environment("PROLOGUE_FOCUS_REPORT")
	if not report.is_empty():
		var file := FileAccess.open(report, FileAccess.WRITE)
		file.store_string(JSON.stringify({"checks":checks,"failures":failures,"observations":observations,"events":events,"results":results},"  "))
	game.queue_free(); await frames()
	print("NATIVE_PROLOGUE_FOCUS_INPUT: ", checks, " checks; ", failures, " failures")
	quit(1 if failures else 0)
