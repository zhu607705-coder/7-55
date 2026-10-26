extends SceneTree

const SCENE = preload("res://scenes/paper_rewind.tscn")
const Model = preload("res://scripts/paper_rewind_model.gd")
var checks := 0
var failures := 0
var view: Control

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
	else:
		print("PASS ", message)

func _initialize() -> void:
	call_deferred("_run")

func frames(count: int = 2) -> void:
	for index: int in range(count):
		await process_frame

func touch(id: int, point: Vector2, down: bool, cancelled: bool = false) -> void:
	var event := InputEventScreenTouch.new()
	event.index = id
	event.position = point
	event.pressed = down
	event.canceled = cancelled
	Input.parse_input_event(event)
	await frames()

func drag(id: int, from: Vector2, to: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = id
	event.position = to
	event.relative = to - from
	Input.parse_input_event(event)
	await frames()

func path_point(at_time: float) -> Vector2:
	return view.stage.global_position + view.stage.world_to_local(Model.free_position(at_time))

func setup_hold() -> void:
	# Fresh-scene fixture; actual input begins on the physical page, never a button.
	view._reset()
	await frames(3)
	var from: Vector2 = view.stage.paper_grip.get_global_rect().get_center()
	await touch(0, from, true)
	await drag(0, from, path_point(1.2))

func _run() -> void:
	root.size = Vector2i(390, 844)
	view = SCENE.instantiate()
	root.add_child(view)
	await frames(4)
	view.set_process(false)
	await setup_hold()
	var left: Vector2 = path_point(1.2)
	var right: Vector2 = view.stage.folder_button.get_global_rect().get_center()
	check(left.x < root.size.x * 0.35 and right.x > root.size.x * 0.55, "Two-hand grip and physical folder occupy distinct left/right reach areas")
	await touch(1, right, true)
	check(view.touch_sessions[0].target == "paper" and view.touch_sessions[1].target == "folder", "Different fingers independently own different real objects")
	await touch(1, right, false)
	check(view.model.folder_open and view.stage.paper_grip.held and view.model.mode == "paused", "Right-hand folder release changes environment without releasing left paper")
	var held_time: float = view.model.time
	view.model.advance(30)
	check(view.model.time == held_time and view.model.completion_count == 0, "No reflex deadline while left hand holds paper")
	await touch(0, left, false)
	check(view.model.mode == "forward" and not view.stage.paper_grip.held, "Only releasing paper's owning finger resumes paper")
	view.model.advance(20); view._refresh()
	check(view.model.mode == "landed" and view.model.completion_count == 0, "Two-hand arrangement causes real catch, not automatic completion")
	var caught: Vector2 = view.stage.paper_grip.get_global_rect().get_center()
	await touch(0, caught, true); await touch(0, caught, false)
	check(view.model.paper_collected and view.model.completion_count == 1, "Manual scene-object collection completes two-hand flow once")
	await setup_hold()
	right = view.stage.folder_button.get_global_rect().get_center()
	await touch(1, right, true)
	await touch(0, left, false)
	check(view.touch_sessions.has(1) and view.model.mode == "forward" and not view.model.folder_open, "Releasing left first preserves right object's ownership")
	view.model.advance(0.5)
	await touch(1, right, false)
	view.model.advance(20); view._refresh()
	check(view.model.mode == "landed" and view.model.folder_open, "Opposite release order still works within wide spatial opportunity")
	await setup_hold()
	right = view.stage.folder_button.get_global_rect().get_center()
	await touch(1, right, true)
	await touch(1, right, false, true)
	check(not view.model.folder_open and view.stage.paper_grip.held and view.touch_sessions.has(0), "Cancelling right hand leaves left capture intact and does not open folder")
	await touch(0, left, false)
	view.model.advance(20); view._refresh()
	check(view.model.mode == "failed" and view.model.completion_count == 0, "Cancelled arrangement cannot earn a catch")
	await setup_hold()
	await touch(1, right, true)
	await touch(0, left, false, true)
	await touch(1, right, false)
	check(view.model.folder_open and view.model.mode == "paused" and not view.stage.paper_grip.held, "Cancelling left hand pauses only paper; right hand can finish its placement")
	held_time = view.model.time
	view.model.advance(30)
	check(view.model.time == held_time and view.model.completion_count == 0, "Other-finger release cannot resume a cancelled paper gesture")
	await setup_hold()
	await touch(1, left, true)
	check(view.touch_sessions[1].target == "blocked", "Same-object second finger cannot steal paper capture")
	await touch(0, left, false)
	held_time = view.model.time
	await touch(1, right, false)
	check(view.model.mode == "forward" and view.model.time == held_time and not view.model.folder_open, "Rejected same-object finger cannot activate folder on release elsewhere")
	await setup_hold()
	var window: Vector2 = view.stage.history_window.get_global_rect().get_center()
	var previous_window: Rect2 = view.stage.history_rect
	await touch(1, window, true)
	await drag(1, window, window + Vector2(-20, 10))
	check(view.stage.history_rect != previous_window and view.stage.paper_grip.held and view.model.mode == "paused", "Second hand may inspect read-only past while first owns paper")
	await touch(1, window + Vector2(-20, 10), false, true)
	check(view.stage.paper_grip.held and view.touch_sessions.has(0), "Cancelling observation does not cancel another object's gesture")
	await setup_hold()
	await touch(1, right, true)
	view.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	await touch(0, left, false); await touch(1, right, false)
	check(view.touch_sessions.is_empty() and view.model.mode == "paused" and not view.model.folder_open and not view.stage.paper_grip.held, "Backgrounding cancels all owners; stale releases cannot activate anything")
	await setup_hold()
	await touch(1, right, true)
	var before: Dictionary = view.model.snapshot()
	root.size = Vector2i(844, 390)
	await frames(5)
	await touch(0, left, false); await touch(1, right, false)
	check(view.touch_sessions.is_empty() and view.model.snapshot() == before, "Orientation cancels all gestures but preserves exact model/environment")
	root.size = Vector2i(390, 844)
	await frames(5)
	await setup_hold()
	var fake := InputEventMouseButton.new()
	fake.device = -1
	fake.position = left
	fake.global_position = left
	fake.button_index = MOUSE_BUTTON_LEFT
	fake.pressed = false
	root.push_input(fake, true)
	await frames()
	check(view.stage.paper_grip.held and view.model.mode == "paused", "Emulated mouse release cannot duplicate/terminate a touch-owned gesture")
	# Independent review counterexamples retained as delivery regressions.
	view._reset()
	await frames(3)
	var untouched: Dictionary = view.model.snapshot()
	view.stage.history_rect.position = Vector2(580, 160)
	view.stage._layout_history()
	var covered_paper: Vector2 = view.stage.paper_grip.get_global_rect().get_center()
	await touch(0, covered_paper, true)
	check(view.touch_sessions[0].target == "history", "top read-only window owns a press above physical paper")
	await drag(0, covered_paper, covered_paper + Vector2(-20, 0))
	await touch(0, covered_paper + Vector2(-20, 0), false)
	check(view.model.snapshot() == untouched, "dragging overlay over physical paper cannot start or mutate it")
	await setup_hold()
	right = view.stage.folder_button.get_global_rect().get_center()
	await touch(1, right, true)
	view._reset()
	await touch(0, left, false); await touch(1, right, false)
	check(view.model.mode == "intro" and not view.model.folder_open and view.touch_sessions.is_empty(), "full reset clears both owners and suppresses stale releases")
	await setup_hold()
	await touch(1, right, true)
	view._cancel()
	await touch(0, left, false); await touch(1, right, false)
	check(view.model.mode == "cancelled" and view.model.completion_count == 0 and view.touch_sessions.is_empty(), "skip with two held objects cannot resurrect or complete")
	for dimensions: Vector2i in [Vector2i(320,568),Vector2i(844,390)]:
		root.size = dimensions
		await frames(5)
		view._reset()
		await frames(3)
		view.get_node("Scroll").ensure_control_visible(view.stage)
		await frames(3)
		var page: Vector2 = view.stage.paper_grip.get_global_rect().get_center()
		await touch(0, page, true)
		await drag(0, page, path_point(1.2))
		var folder: Vector2 = view.stage.folder_button.get_global_rect().get_center()
		await touch(1, folder, true); await touch(1, folder, false)
		await touch(0, path_point(1.2), false)
		view.model.advance(20); view._refresh()
		check(view.model.mode == "landed", "two-hand physical flow catches at " + str(dimensions))
		var page_end: Vector2 = view.stage.paper_grip.get_global_rect().get_center()
		await touch(0, page_end, true); await touch(0, page_end, false, true)
		check(view.model.mode == "landed" and not view.model.paper_collected, "cancellation of collection never collects at " + str(dimensions))
		await touch(0, page_end, true); await touch(0, page_end, false)
		check(view.model.mode == "solved" and view.model.completion_count == 1, "explicit retry tap collects once at " + str(dimensions))

	view._cancel()
	view.queue_free()
	await frames()
	print("PAPER_REWIND_TWO_HANDS checks=%d failures=%d headless=true physical_mobile=false" % [checks, failures])
	quit(1 if failures else 0)
