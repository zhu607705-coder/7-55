extends "res://tests/capture_ui_redesign.gd"
## Actual source sessions. Fixtures select existing lines, never author dialogue or
## earn progression. Paused frames use the production host's focus gate.
const DisplayFixture = preload("res://tests/zh_text_fixture.gd")

func run() -> void:
	validate_only = validate_only or "--validate-only" in OS.get_cmdline_user_args()
	if DisplayServer.get_name() == "headless" and not validate_only: quit(2); return
	create_timer(180.0).timeout.connect(func(): push_error("Dialogue capture deadline exceeded"); quit(2))
	if not load("res://tests/native_test_isolation.gd").is_isolated_save(): quit(2); return
	Engine.max_fps = 30
	output = OS.get_environment("UI_CAPTURE_DIR")
	if output.is_empty(): quit(2); return
	DirAccess.make_dir_recursive_absolute(output)
	state = root.get_node("State")
	state.developer_mode = true
	for dimensions: Vector2i in [Vector2i(1440,900),Vector2i(390,844),Vector2i(568,320)]:
		DisplayServer.window_set_size(dimensions); root.size = dimensions
		await capture_c3(dimensions, false)
		await capture_c3(dimensions, true)
		await capture_library(dimensions, false)
		await capture_library(dimensions, true)
	var file := FileAccess.open(output.path_join("captures.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t")); file.close()
	if is_instance_valid(shell): await shell.shutdown(); shell.queue_free(); await frames(2)
	print("SELECTED_DIALOGUE_CAPTURE ",report.size()," fixtures; failed=",capture_failed)
	quit(1 if capture_failed else 0)

func select_line(lines: Array, longest: bool) -> int:
	var selected := 0
	for index in range(1,lines.size()):
		var length := str(lines[index].text).length()
		var previous := str(lines[selected].text).length()
		if (longest and length > previous) or (not longest and length < previous): selected = index
	return selected

func capture_c3(dimensions: Vector2i, longest: bool) -> void:
	fixture_note = "DEV actual auntie controller intent; authored timed line; no completion receipt"
	state.d = state.initial()
	state.d.native.chapter = 3; state.d.native.scene = "canteen_interior"; state.d.native.page = "c3_canteen"
	state.d.rpgScene = "canteen_interior"; state.d.runtimeMode = "rpg"
	state.d.actOne.movementEnabled = true; state.d.actOne.phase = "complete"; state.d.actOne.inventoryRecovered = true
	state.d.items.gamepad = true
	state.d.canteenHunt.active = true; state.d.canteenHunt.phase = "tray_search"; state.d.canteenHunt.entryPaperEscaped = true
	state.d.native.settings.volume = 0
	await fresh_shell(dimensions)
	shell.world.set_process(false); shell.c3_scene_host.set_process(false)
	var host: Control = shell.c3_narrative_host
	host.set_process(false)
	shell.world.player = shell.world._find_safe(Vector2(1466,608))
	shell.world._sync_player(); shell.world._update_camera()
	state.act("c3_target:auntie"); host.tick(0,true)
	if not require_fixture(host.current != null and host.current.sequence_id == "canteen_tray_intro","actual auntie session issued"): return
	var session: RefCounted = host.current
	var selected := select_line(session.lines,longest)
	var target := float(session.lines[selected].atMs) + 1.0
	while session.elapsed_ms < target and session.status == "playing": host.tick(minf(100.0,target-session.elapsed_ms),true)
	shell._layout(); host.view.tick()
	require_fixture(host.blocks_input() and not host.blocks_movement(),"timed dialogue preserves interaction/movement split")
	require_fixture(host.view.body.text == str(session.snapshot().text),"C3 displays exact current source line")
	require_fixture(host.view.find_children("*","Button",true,false).is_empty(),"automatic C3 dialogue has no invented advance button")
	var prefix := "%dx%d-c3-" % [dimensions.x,dimensions.y]
	await capture_dialogue(prefix + ("long" if longest else "short"),host)
	if longest:
		var before := float(session.elapsed_ms)
		host.tick(100,false)
		require_fixture(session.paused and session.elapsed_ms == before,"C3 actual focus pause freezes authored clock")
		await capture_dialogue(prefix + "paused",host)
	require_fixture(not state.d.canteenHunt.trayTaskStarted,"C3 capture does not complete tray introduction")

func capture_library(dimensions: Vector2i, longest: bool) -> void:
	fixture_note = "DEV original library source session; authorized host attach/advance; not earned campaign completion"
	state.d = state.initial()
	state.d.native.chapter = 2; state.d.native.scene = "library_interior"; state.d.native.page = "phone_home"
	state.d.runtimeMode = "rpg"; state.d.rpgScene = "library_interior"; state.d.actOne.phase = "complete"
	state.d.ui.libraryFinalsPhase = "library_entered"
	state.d.native.settings.volume = 0
	await fresh_shell(dimensions)
	var host: Control = shell.library_story_host
	host.set_process(false); shell.world.set_process(false)
	host.reset()
	shell.world.player = Vector2(334,736); shell.world._sync_player(); shell.world._update_camera()
	var source: Dictionary = DisplayFixture.library(JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/library_story_source.json")))
	var session: RefCounted = load("res://scripts/presentation/library_story_session.gd").new(state.d,"library_entered",source.sequences.library_entered)
	if not require_fixture(session.attach(state.d,host),"original library session authorized"): return
	host.current = session; host.view.session = session
	var selected := select_line(session.lines,longest)
	for unused in range(selected): host._advance()
	shell._layout(); host.view.tick()
	if not require_fixture(host.current == session and session.status == "playing","library selected line remains owned by actual host"): return
	require_fixture(host.view.body.text == str(session.lines[selected].text),"library exact source text without invented copy")
	var prefix := "%dx%d-library-" % [dimensions.x,dimensions.y]
	await capture_dialogue(prefix + ("long" if longest else "short"),host)
	if longest:
		var before := float(session.elapsed_ms)
		host.tick(100,false)
		require_fixture(session.paused and session.elapsed_ms == before,"library actual focus pause freezes clock")
		await capture_dialogue(prefix + "paused",host)

func capture_dialogue(id: String, host: Control) -> void:
	var before := float(host.current.elapsed_ms)
	await capture(id)
	require_fixture(host.current != null and host.current.elapsed_ms == before,"capture frames do not advance suspended host processing")
	var row: Dictionary = report.back()
	row["sequence"] = host.current.sequence_id
	row["paused"] = host.current.paused
	row["text"] = host.view.body.text
	row["speaker"] = host.view.speaker.text
	row["panel_rect"] = str(host.view.panel.get_global_rect())
	row["prompt"] = host.view.prompt.text if "prompt" in host.view else ""
	row["elapsed_ms"] = before
