extends SceneTree

const SCENE = preload("res://scenes/paper_rewind.tscn")
const Model = preload("res://scripts/paper_rewind_model.gd")
var checks := 0
var failures := 0
var view: Control
var last_mouse := Vector2.ZERO

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
	else:
		print("PASS ", message)

func _initialize() -> void:
	call_deferred("_run")

func frames(count: int = 3) -> void:
	for index: int in range(count):
		await process_frame

func move_mouse(point: Vector2, held: bool = false) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	motion.relative = point - last_mouse
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT if held else 0
	last_mouse = point
	root.push_input(motion, true)
	await frames(1)

func mouse(point: Vector2, down: bool) -> void:
	await move_mouse(point, down)
	var event := InputEventMouseButton.new()
	event.position = point
	event.global_position = point
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = down
	root.push_input(event, true)
	await frames(1)

func click(control: Control) -> void:
	if view.get_node("Scroll").is_ancestor_of(control):
		view.get_node("Scroll").ensure_control_visible(control)
	await frames(2)
	var point := control.get_global_rect().get_center()
	await mouse(point, true)
	await mouse(point, false)

func reset_scene() -> void:
	if not view.secondary.visible:
		await click(view.options_button)
	await click(view.reset_button)
	await frames(2)

func key(code: Key) -> void:
	for down: bool in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.pressed = down
		root.push_input(event, true)
		await frames(1)

func touch(point: Vector2, down: bool, index: int = 0, cancelled: bool = false) -> void:
	var event := InputEventScreenTouch.new()
	event.position = point
	event.pressed = down
	event.index = index
	event.canceled = cancelled
	Input.parse_input_event(event)
	await frames(2)

func touch_move(from: Vector2, to: Vector2, index: int = 0) -> void:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = to
	event.relative = to - from
	Input.parse_input_event(event)
	await frames(2)

func paper_path_point(at_time: float) -> Vector2:
	return view.stage.global_position + view.stage.world_to_local(Model.free_position(at_time))

func _run() -> void:
	root.size = Vector2i(1100, 760)
	view = SCENE.instantiate()
	root.add_child(view)
	await frames(4)
	view.set_process(false)
	check(view.model.mode == "forward" and view.model.time > 0, "First entry is actual moving paper, not a written start screen")
	view._reset()
	await frames(3)
	check(view.model.mode == "intro" and not view.secondary.visible and not view.slider.is_visible_in_tree(), "Entry has scene objects, not a primary button row or timeline")
	var untouched: Dictionary = view.model.snapshot()
	var old_window: Rect2 = view.stage.history_rect
	var point: Vector2 = view.stage.history_window.get_global_rect().get_center()
	await mouse(point, true)
	await move_mouse(point + Vector2(-150, 55), true)
	await mouse(point + Vector2(-150, 55), false)
	check(view.stage.history_rect != old_window and view.model.snapshot() == untouched, "Pointer moves read-only past frame without changing physical state")
	view.stage.history_window.grab_focus()
	old_window = view.stage.history_rect
	await key(KEY_LEFT)
	check(view.stage.history_rect.position.x < old_window.position.x and view.model.snapshot() == untouched, "Keyboard observation is also read-only")
	view.stage.reset_history()
	await click(view.stage.folder_button)
	check(view.model.folder_open and view.model.mode == "paused", "Physical folder starts interaction; no start button is needed")
	point = view.stage.paper_grip.get_global_rect().get_center()
	await mouse(point, true)
	check(view.model.mode == "paused" and view.stage.paper_grip.held, "Grabbing the actual paper pauses only that object")
	await move_mouse(paper_path_point(1.0), true)
	check(absf(view.model.time - 1.0) < 0.05 and view.model.folder_open, "Captured pointer drags paper far outside initial hit area along its real trajectory")
	check(view.model.completion_count == 0 and view.model.catch_time < 0, "Dragging preview cannot catch or complete")
	await mouse(paper_path_point(1.0), false)
	check(view.model.mode == "forward", "Releasing the paper resumes forward simulation")
	view.model.advance(20); view._refresh()
	check(view.model.mode == "landed" and view.model.completion_count == 0, "Real contact lands but never auto-collects")
	await click(view.stage.paper_grip)
	check(view.model.mode == "solved" and view.model.paper_collected and not view.stage.paper_grip.visible, "Clicking landed paper manually collects it and removes its physical sprite/hit target")
	await reset_scene()
	await click(view.stage.paper_grip)
	view.model.advance(20); view._refresh()
	check(view.model.mode == "failed" and view.stage.paper_grip.visible, "Without folder arrangement paper fails and leaves an accessible trace")
	check(view.stage.get_global_rect().encloses(view.stage.paper_grip.get_global_rect()), "Escaped-paper trace stays reachable inside scene")
	point = view.stage.paper_grip.get_global_rect().get_center()
	await mouse(point, true)
	await move_mouse(paper_path_point(0.5), true)
	await mouse(paper_path_point(0.5), false)
	view.model.advance(20); view._refresh()
	check(view.model.mode == "failed" and view.model.completion_count == 0, "Rewind alone without changed environment still fails")
	await reset_scene()
	view.stage.paper_grip.grab_focus()
	for index: int in range(12):
		await key(KEY_LEFT)
	await key(KEY_F)
	await key(KEY_ENTER)
	view.model.advance(20); view._refresh()
	check(view.model.mode == "landed", "Keyboard object focus performs same rewind/placement/catch")
	await key(KEY_ENTER)
	check(view.model.mode == "solved", "Keyboard object activation manually collects")
	await reset_scene()
	for dimensions: Vector2i in [Vector2i(320, 568), Vector2i(390, 844), Vector2i(844, 390), Vector2i(1280, 720)]:
		root.size = dimensions
		await frames(5)
		check(view.size.x == dimensions.x and view.content.size.x <= dimensions.x, "No horizontal overflow at " + str(dimensions))
		check(view.stage.paper_grip.size.x >= 48 and view.stage.paper_grip.size.y >= 48, "Paper gesture target remains at least 48px at " + str(dimensions))
		check(view.stage.folder_button.size.x >= 44 and view.stage.folder_button.size.y >= 44, "Folder surface remains at least 44px at " + str(dimensions))
		check(Rect2(0, 0, 960, 540).encloses(view.stage.history_rect), "Historical window remains bounded at " + str(dimensions))
		var contact_model := Model.new()
		contact_model.start(); contact_model.seek(0); contact_model.open_folder(); contact_model.play()
		while contact_model.catch_time < 0 and contact_model.mode == "forward": contact_model.advance(Model.TICK)
		var contact_point: Vector2 = view.stage.world_to_local(contact_model.catch_position)
		var physical_page := Rect2(contact_point-view.stage.paper_extent()*0.5,view.stage.paper_extent())
		check(physical_page.intersects(view.stage.open_folder_surface_rect()), "First logical catch visibly touches an actual open folder leaf at " + str(dimensions))
		check(view.stage.folder_leaf_rect().has_point(view.stage.world_to_local(Model.REST_POINT)), "Resting paper is on the visible accepting page at " + str(dimensions))
		check(is_equal_approx(view.stage.folder_leaf_rect().size.y / view.stage.folder_leaf_rect().size.x, sqrt(2.0)), "Folder retains physical A4 proportions at " + str(dimensions))
		for paper_time: float in [0.0, 1.2, 4.8, 6.5, 7.8]:
			view.model.time = paper_time
			var preview: Rect2 = view.stage.thumb_preview_rect()
			check(Rect2(Vector2.ZERO, view.stage.size).encloses(preview.grow(4)) and view.stage.grip_preview.z_index > view.stage.history_window.z_index, "Thumb preview bounded above history at %s / %.1f" % [str(dimensions), paper_time])
		view.model.time = Model.ENTRY_TIME
	root.size = Vector2i(390, 844)
	await frames(5)
	var scroll: ScrollContainer = view.get_node("Scroll")
	scroll.ensure_control_visible(view.stage)
	await frames(2)
	untouched = view.model.snapshot()
	old_window = view.stage.history_rect
	point = view.stage.history_window.get_global_rect().get_center()
	await touch(point, true)
	await touch_move(point, point + Vector2(-35, 30))
	await touch(point + Vector2(-35, 30), false)
	check(view.stage.history_rect != old_window and view.model.snapshot() == untouched, "Single finger moves only the past observation frame")
	view.stage.reset_history()
	point = view.stage.folder_button.get_global_rect().get_center()
	await touch(point, true); await touch(point, false)
	check(view.model.folder_open and view.model.mode == "paused", "Single finger opens physical folder without another hand")
	point = view.stage.paper_grip.get_global_rect().get_center()
	await touch(point, true)
	await touch_move(point, paper_path_point(1.5))
	check(absf(view.model.time - 1.5) < 0.05 and view.stage.paper_grip.held, "Touch capture follows paper across whole curved path")
	await touch(paper_path_point(1.5), false, 0, true)
	var cancelled_time: float = view.model.time
	view.model.advance(20)
	check(view.model.mode == "paused" and view.model.time == cancelled_time and view.model.completion_count == 0, "Cancelled paper drag stays paused; no release-to-play or collect")
	point = view.stage.paper_grip.get_global_rect().get_center()
	await touch(point, true)
	await touch(point, true, 1)
	await touch(point, false, 1)
	check(view.stage.paper_grip.held and view.model.mode == "paused", "Second finger cannot release primary paper gesture")
	view.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	await touch(point, false)
	check(view.model.mode == "paused" and not view.stage.paper_grip.held and view.touch_sessions.is_empty(), "Backgrounding cancels active gesture and preserves arrangement")
	var before_rotate: Dictionary = view.model.snapshot()
	root.size = Vector2i(844, 390)
	await frames(5)
	root.size = Vector2i(390, 844)
	await frames(5)
	check(view.model.snapshot() == before_rotate, "Portrait/landscape changes preserve exact paper/environment state")
	scroll.ensure_control_visible(view.stage)
	await frames(2)
	point = view.stage.paper_grip.get_global_rect().get_center()
	await touch(point, true)
	await touch_move(point, paper_path_point(2.0))
	await touch(paper_path_point(2.0), false)
	view.model.advance(20); view._refresh()
	check(view.model.mode == "landed" and view.model.completion_count == 0, "Single-finger object flow reaches catch without auto-win")
	point = view.stage.paper_grip.get_global_rect().get_center()
	await touch(point, true); await touch(point, false)
	check(view.model.mode == "solved" and not view.stage.paper_grip.visible, "Single-finger tap collects the actual caught paper")
	await reset_scene()
	await click(view.stage.folder_button)
	await click(view.options_button)
	await click(view.reduced)
	await click(view.sound_toggle)
	view.presentation_time = 0
	var before: Dictionary = view.model.snapshot()
	view._process(3.6)
	check(view.stage.broadcast_quiet and view.broadcast_player.volume_db == -80, "Broadcast quiet visual/audio are synchronized")
	check(view.model.snapshot() == before and is_equal_approx(view.stage.history_time, 4.8), "Reduced-motion static record and broadcast never change current paper")
	var wind_time: float = view.stage.environment_time
	view._process(4.5)
	check(not view.stage.broadcast_quiet and view.broadcast_player.volume_db == -36 and view.stage.environment_time > wind_time, "Environment wind/time continues independently of paused paper")
	await click(view.sound_toggle)
	check(not view.broadcast_player.playing, "Optional broadcast sound stops cleanly")
	await click(view.skip_button)
	var stopped: RefCounted = view.model
	view.queue_free()
	await frames(3)
	stopped.advance(50)
	check(stopped.mode == "cancelled" and stopped.completion_count == 0, "Skip and teardown never earn completion")
	print("PAPER_REWIND_INPUT checks=%d failures=%d headless=true visual_acceptance=false physical_mobile=false" % [checks, failures])
	quit(1 if failures else 0)
