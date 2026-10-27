extends SceneTree
const Scene = preload("res://scenes/library_time.tscn")
const Events = preload("res://kit/capture_inputs.gd")
var view: Control
var events := Events.new()
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	if not ok: failures += 1; push_error("TEST FAILED: " + label)
	else: print("PASS ", label)
func frames(count: int = 2) -> void:
	for i: int in range(count): await process_frame
func touch(id: int, p: Vector2, down: bool, canceled: bool = false) -> void:
	events.touch(id, p, down, canceled); await frames()
func drag(id: int, p: Vector2) -> void:
	events.drag(id, p); await frames()
func tap(p: Vector2) -> void:
	await touch(9, p, true); await touch(9, p, false)
func reset() -> void:
	view.model.reset(); view.pointers.clear(); events.last.clear()
	view.resume_button.hide(); view.reset_button.hide(); view._layout(true)
	for i: int in range(30): view._process(1.0 / 30.0)
	await frames()
func step_observation() -> void:
	for i: int in range(24): view._process(1.0 / 30.0)
func place_window(index: int, position: Vector2) -> void:
	view.history_rects[index].position = position
	view.history_images[index].position = position
func park_two() -> void:
	var first: Vector2 = view.history_rects[0].position + Vector2(70, 190)
	var second: Vector2 = view.history_rects[1].position + Vector2(70, 190)
	await touch(0, first, true); await touch(1, second, true)
	check(view.model.input.owners.get(0) == "history0" and view.model.input.owners.get(1) == "history1", "ordinary two-touch independently grips both history windows")
	await drag(0, first + Vector2(-4, -8)); await drag(1, second + Vector2(20, -118))
	await touch(0, events.last[0], false); await touch(1, events.last[1], false)
	step_observation()
func pull_book(book: int, amount: float = 60) -> void:
	var p: Vector2 = view.book_point(book)
	await touch(6, p, true); await drag(6, p + Vector2(0, amount))
	view._process(1.0 / 30.0); await physics_frame
	await touch(6, p + Vector2(0, amount), false)
func run() -> void:
	root.size = Vector2i(390, 844); view = Scene.instantiate(); root.add_child(view)
	await frames(4); await physics_frame; await physics_frame; view.set_process(false)
	await reset()
	var first: Vector2 = view.history_rects[0].position + Vector2(70, 190)
	var second: Vector2 = view.history_rects[1].position + Vector2(70, 190)
	await touch(0, first, true); await touch(1, second, true); await touch(2, first, true)
	check(view.model.input.owners.size() == 2 and not view.model.input.owners.has(2), "third finger cannot steal a history window")
	await touch(0, second, true)
	check(view.model.input.owners.get(0) == "history0", "duplicate pointer cannot switch historical ownership")
	var emulated := InputEventMouseButton.new(); emulated.device = InputEvent.DEVICE_ID_EMULATION
	emulated.position = view.book_point(4); emulated.button_index = MOUSE_BUTTON_LEFT; emulated.pressed = true
	Input.parse_input_event(emulated); await frames()
	check(not view.model.input.owners.has(-1) and view.model.selected_book == -1, "emulated mouse cannot grab a book alongside real touches")
	await touch(0, first, false, true)
	check(view.model.suspended and view.model.input.owners.is_empty() and view.pointers.is_empty(), "OS cancellation clears all owners and requires explicit resume")
	await touch(1, second, false)
	check(view.model.suspended and not view.model.completed, "stale touch release cannot resume or complete")
	await tap(view.resume_button.get_global_rect().get_center())
	check(not view.model.suspended and view.model.input.owners.is_empty(), "ordinary touch on Continue resumes without old contacts")
	await reset()
	await pull_book(4)
	check(not view.model.completed and view.model.selected_book == -1 and view.current_world.books.size() == 6, "correct book before observation returns safely")
	await reset()
	var before: Array = []
	for id: int in range(6): before.append(view.current_world.books[id].global_transform)
	await park_two()
	check(view.model.observed == [true, true] and not view.model.completed, "visible moved windows grant both fragments but never auto-complete")
	var unchanged := true
	for id: int in range(6): unchanged = unchanged and before[id].is_equal_approx(view.current_world.books[id].global_transform)
	check(unchanged, "moving history windows leaves every present book transform unchanged")
	var history_before: Array = [view.history_worlds[0].books[4].global_transform, view.history_worlds[1].books[4].global_transform]
	await pull_book(3)
	for i: int in range(30): view._process(1.0 / 30.0)
	check(not view.model.completed and view.model.rejected_count == 1 and view.current_world.books.size() == 6, "wrong book is rejected without losing any volume")
	check(view.current_world.books[3].position.distance_to(view.current_world.base_positions[3]) < 0.01, "wrong book visibly returns to its original shelf position")
	await pull_book(4)
	check(view.model.completed and view.model.completion_count == 1, "ordinary present-book pull completes only after both historical fragments")
	check(history_before[0] == view.history_worlds[0].books[4].global_transform and history_before[1] == view.history_worlds[1].books[4].global_transform, "present retrieval leaves both historical books immutable")
	step_observation()
	check(view.model.completion_count == 1, "continued scene frames cannot duplicate retrieval")
	await reset()
	# Geometry setup hides the lower window's clue behind the topmost window.
	place_window(1, view.history_rects[0].position)
	check(not view.history_visible(0), "overlapping upper window blocks historical evidence")
	view.history_images[1].hide()
	check(not view.history_visible(1), "invisible history surface cannot provide evidence")
	var p: Vector2 = view.history_rects[0].position + Vector2(70, 190)
	await touch(0, p, true); await drag(0, p + Vector2(8, 0)); await touch(0, p + Vector2(8, 0), false)
	view.history_images[1].show(); place_window(1, view.history_rects[0].position)
	step_observation()
	check(view.model.moved[0] and not view.model.observed[0] and not view.model.completed, "moved but screen-covered historical clue cannot accumulate observation")
	await reset(); await park_two()
	var book_position: Vector2 = view.book_point(4)
	place_window(1, book_position - view.history_rects[1].size * 0.5)
	check(not view.book_visible(4), "historical overlay hides current target book")
	await touch(4, book_position, true)
	check(view.model.input.owners.get(4) == "history1" and view.model.selected_book == -1, "history window owns its hit and cannot click through into current book")
	await touch(4, book_position, false)
	check(not view.model.completed, "already observed fragments do not bypass an obscured current selection")
	await reset()
	# Sequential ordinary mouse input preserves the two independent window moves.
	for index: int in range(2):
		p = view.history_rects[index].position + Vector2(70, 190)
		var delta := Vector2(-4, -8) if index == 0 else Vector2(20, -118)
		events.mouse_button(p, true); await frames()
		events.mouse_move(p + delta); await frames()
		events.mouse_button(p + delta, false); await frames()
	step_observation()
	p = view.book_point(4)
	events.mouse_button(p, true); await frames(); events.mouse_move(p + Vector2(0, 60)); await frames()
	view._process(1.0 / 30.0); await physics_frame
	events.mouse_button(p + Vector2(0, 60), false); await frames()
	check(view.model.completed and view.model.completion_count == 1, "sequential mouse drags offer the same observation and retrieval path")
	await reset()
	p = view.history_rects[0].position + Vector2(70, 190)
	await touch(0, p, true); view.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	step_observation()
	check(view.model.suspended and view.model.input.owners.is_empty() and view.pointers.is_empty() and not view.model.completed, "backgrounding clears contacts and pauses observation")
	await tap(view.resume_button.get_global_rect().get_center())
	check(not view.model.suspended and view.model.input.owners.is_empty(), "focus return still requires explicit Continue")
	await touch(0, p, true); root.size = Vector2i(844, 390); await frames(5)
	check(view.model.suspended and view.model.input.owners.is_empty() and view.pointers.is_empty(), "resize invalidates drag geometry and requires explicit resume")
	root.size = Vector2i(390, 844); await frames(5); await reset()
	p = view.history_rects[0].position + Vector2(70, 190)
	await touch(0, p, true); await drag(0, Vector2(-5, p.y))
	check(view.model.suspended and view.model.input.owners.is_empty() and view.pointers.is_empty(), "out-of-bounds drag cancels ownership safely")
	check(view.find_children("*", "Label", true, false).is_empty(), "main play surface has no permanent explanation or answer panel")
	print("LIBRARY_INPUT failures=", failures, " real_input_events=true rendered_pixels=false")
	view.queue_free(); await frames(); quit(1 if failures else 0)
