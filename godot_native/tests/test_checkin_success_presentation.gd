extends SceneTree
## Focused native lifecycle/input checks. Explicit ticks are unit-test clocks;
## graphical browser captures separately accept the rendered Web presentation.
const Game = preload("res://scripts/games/prologue_interception.gd")
const SuccessView = preload("res://scripts/ui/checkin_success_view.gd")
var checks = 0
var failures = 0
var game: Control
var finished: Array = []
var cues: Array = []
var observations: Array = []

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	observations.append({"check":label,"passed":ok})
	if not ok:
		failures += 1
		push_error("CHECKIN SUCCESS: " + label)

func frames(count: int = 2) -> void:
	for _frame in count: await process_frame

func tick(seconds: float) -> void:
	var remaining = seconds
	while remaining > 0.00001:
		var step = minf(0.1, remaining)
		game._process(step)
		remaining -= step
	game._process(0.0)

func key(code: Key, down: bool) -> void:
	var event = InputEventKey.new()
	event.keycode = code; event.physical_keycode = code; event.pressed = down
	root.push_input(event, true)

func press(code: Key) -> void:
	key(code, true); await frames(); key(code, false); await frames()

func click(button: Button) -> void:
	var point = button.get_global_rect().get_center()
	var event = InputEventMouseButton.new()
	event.position = point; event.global_position = point
	event.button_index = MOUSE_BUTTON_LEFT; event.pressed = true
	root.push_input(event, true); await frames(3)
	event = InputEventMouseButton.new()
	event.position = point; event.global_position = point
	event.button_index = MOUSE_BUTTON_LEFT; event.pressed = false
	root.push_input(event, true); await frames()
	game._process(0.0)

func prepare(request: Dictionary = {}) -> void:
	if is_instance_valid(game): game.queue_free(); await frames(3)
	root.size = Vector2i(430, 820)
	game = Game.new(); game.size = Vector2(430, 820)
	root.add_child(game); game.set_process(false)
	game.finished.connect(func(result: Dictionary): finished.append(result))
	game.presentation_requested.connect(func(id: String, payload: Dictionary): cues.append({"id":id,"payload":payload}))
	game.start(request); game._process(0.0); await frames()

func accepted_state_unchanged(before: Dictionary, label: String) -> void:
	check(root.get_node("State").d == before, label)

func run() -> void:
	if not load("res://tests/native_test_isolation.gd").is_isolated_save():
		push_error("Check-in presentation test requires the native isolated save fixture")
		quit(2); return
	var before: Dictionary = root.get_node("State").d.duplicate(true)
	await prepare()
	check(game.phase == "success" and not game.done, "fresh accepted presentation starts at success without a terminal result")
	check(game.success_view is SuccessView and game.success_view.visible, "the success beat owns a separate native presentation view")
	var paper: TextureRect = game.success_view.find_child("CheckinReceiptPaper", true, false)
	var seal: Control = game.success_view.find_child("CheckinPrintedStamp", true, false)
	check(is_instance_valid(paper) and is_instance_valid(seal) and paper != seal and paper.get_parent() == seal.get_parent(), "paper and printed lettering are distinct scene objects sharing the receipt transform")
	check(paper.texture is AtlasTexture and not (seal is TextureRect) and game.success_view.headline.get_parent() == seal and game.success_view.headline.text == "签到成功", "the success stamp uses live monochrome lettering without a gemstone or checkmark image")
	var mask: Control = game.success_view.find_child("CheckinPrintMask", true, false)
	var slot: Control = game.success_view.find_child("CheckinPrinterSlot", true, false)
	check(is_instance_valid(mask) and mask.clip_contents and is_instance_valid(slot), "the paper exits a real top printer slot through a clipping mask")
	tick(0.25)
	var early: Dictionary = game.success_view.read_presentation()
	tick(0.9)
	var settled: Dictionary = game.success_view.read_presentation()
	check(early.receipt_position.y < settled.receipt_position.y and early.print_progress < settled.print_progress and early.visible_paper_height < settled.visible_paper_height, "the owning clock feeds more paper downward through the top slot")
	check(is_zero_approx(game.success_view.receipt.rotation) and game.success_view.seal.scale == Vector2.ONE, "printing keeps the receipt aligned and prints the stamp without an airborne drop")
	check(game.phase == "success" and not game.success_continue.visible and game.success_continue.text == "收起回执", "printing has no unexplained Continue control over its incomplete receipt")
	await press(KEY_ESCAPE); game._process(0.0)
	check(game.paused and game.success_view.pause_card.visible and not game.success_continue.visible, "real root Escape pauses success and leaves only the resume action")
	var frozen_elapsed: float = game.elapsed
	var frozen_pose: Dictionary = game.success_view.read_presentation()
	tick(3.0)
	check(is_equal_approx(game.elapsed, frozen_elapsed) and game.success_view.read_presentation() == frozen_pose and game.phase == "success", "paused presentation freezes its clock and object poses without timing out")
	await click(game.resume_button)
	check(not game.paused and not game.success_view.pause_card.visible , "real pointer Resume restores the same success beat")
	tick(0.8)
	check(game.success_continue.visible, "only a fully printed receipt exposes its named dismiss action")
	check(game.elapsed > frozen_elapsed, "resumed success advances from the retained clock")
	await click(game.success_continue)
	check(game.phase == "error" and not game.success_view.visible and not game.success_continue.visible, "real success Continue hides its objects and reveals the existing coordinate error")
	check(finished.is_empty() and game.blocks == 0 and game.session.captures.is_empty(), "success Continue cannot create interception or chapter proof")
	accepted_state_unchanged(before, "success input and pause never mutate the shared story state")

	await prepare()
	tick(SuccessView.DURATION - 0.05)
	check(game.phase == "success", "automatic success remains visible until its authored duration")
	var printed: Dictionary = game.success_view.read_presentation()
	check(printed.print_complete and printed.print_progress == 1.0 and printed.visible_paper_height >= 300.0, "the whole receipt and success stamp finish printing before the original story handoff")
	tick(0.1)
	check(game.phase == "error" and finished.is_empty(), "automatic duration advances only the local coordinate-error beat")
	tick(1.8)
	check(game.phase == "error", "success retains the original readable coordinate-error duration")
	tick(0.15)
	check(game.phase == "red", "the existing coordinate error reaches its original red transition")
	for _step in 100:
		if game.phase != "red": break
		game._process(0.01)
	game._process(0.0)
	check(game.phase == "blackout" and cues.back().id == "prologue_blackout_started" and cues.back().payload.durationMs == 7000, "success hands off to the existing authored seven-second blackout cue")
	tick(6.9)
	check(game.phase == "blackout", "the visual success change cannot shorten the seven-second blackout")
	tick(0.2)
	check(game.phase == "deploy" and game.session.completed_stages == 0 and finished.is_empty(), "blackout reaches the original unsolved word-interception stage")
	accepted_state_unchanged(before, "automatic success and the unsolved word game preserve shared story facts")

	for code: Key in [KEY_ENTER, KEY_SPACE]:
		await prepare()
		await press(code); game._process(0.0)
		check(game.phase == "error" and finished.is_empty(), "real root keyboard Continue advances only the local success beat: " + str(code))

	await prepare({"reduced_motion":true})
	tick(0.1)
	var reduced_early: Dictionary = game.success_view.read_presentation()
	tick(1.5)
	var reduced_late: Dictionary = game.success_view.read_presentation()
	check(reduced_early.reduced_motion and reduced_late.reduced_motion and reduced_early.receipt_position == reduced_late.receipt_position and reduced_early.seal_scale == reduced_late.seal_scale, "explicit reduced-motion settings keep receipt and seal poses static")
	check(reduced_early.print_complete and reduced_late.print_complete and reduced_early.visible_paper_height == reduced_late.visible_paper_height, "reduced motion shows a fully printed receipt immediately without a hidden or partial result")
	check(game.success_view.receipt.modulate.a == 1.0 and game.success_view.seal.modulate.a == 1.0 and game.success_view.headline.modulate.a == 1.0, "reduced motion presents the complete confirmation without waiting for an animation")
	await click(game.success_continue)
	check(game.phase == "error" and finished.is_empty(), "reduced-motion Continue retains the same authored handoff")

	await prepare({"resume":true})
	check(game.phase == "blackout" and not game.success_view.visible and not game.success_continue.visible, "resuming an already accepted check-in never replays its success animation")
	tick(7.1)
	check(game.phase == "deploy" and finished.is_empty(), "already accepted check-in resumes the existing unsolved interception flow")
	accepted_state_unchanged(before, "resume and reduced settings cannot grant or regress story facts")
	var view_ref = weakref(game.success_view)
	var action_ref = weakref(game.success_continue)
	var cue_count = cues.size()
	game.queue_free(); await frames(4)
	check(view_ref.get_ref() == null and action_ref.get_ref() == null and root.find_child("CheckinSuccessPresentation", true, false) == null, "leaving the game releases success objects and input controls")
	check(cues.size() == cue_count + 1 and cues.back().id == "prologue_scene_closed" and finished.is_empty(), "scene disposal publishes only its existing cleanup cue without a completion callback")
	root.focus_exited.emit(); await frames()
	accepted_state_unchanged(before, "disposal leaves the isolated shared story state unchanged")
	print("CHECKIN_SUCCESS_PRESENTATION: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
