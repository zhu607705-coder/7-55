extends SceneTree
## Real production renderer, isolated DEV fixtures, never campaign completion.
var shell: Control
var state: Node
var report: Array = []
var output: String
var capture_failed := false
var validate_only := OS.get_environment("UI_CAPTURE_VALIDATE") == "1"
var fixture_note := "DEV fixture; not earned campaign completion"
func _initialize() -> void: run.call_deferred()
func frames(count: int = 6) -> void:
	for unused in count: await process_frame
func capture(id: String) -> void:
	await frames()
	var button_audit: Dictionary={}
	if root.has_node("TactileButtons"):
		button_audit=audit_buttons(root)
		if not button_audit.missing.is_empty():
			capture_failed=true;push_error("Unstyled actual UI buttons: "+str(button_audit.missing))
	if validate_only:
		report.append({"id":id,"fixture":fixture_note,"validation_only":true,"button_audit":button_audit})
		return
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var path := output.path_join(id + ".png")
	var error := image.save_png(path)
	report.append({"id":id,"width":image.get_width(),"height":image.get_height(),"error":error,"fixture":fixture_note,"button_audit":button_audit})
	if error != OK:
		capture_failed = true
		push_error("Screenshot failed: " + path)
func run() -> void:
	if DisplayServer.get_name() == "headless" and not validate_only: quit(2); return
	# Bound every fixture, including unexpected script failures or render stalls.
	create_timer(180.0).timeout.connect(func(): push_error("UI capture deadline exceeded"); quit(2))
	if not load("res://tests/native_test_isolation.gd").is_isolated_save(): quit(2); return
	Engine.max_fps = 30
	output = OS.get_environment("UI_CAPTURE_DIR")
	if output.is_empty(): quit(2); return
	DirAccess.make_dir_recursive_absolute(output)
	state = root.get_node("State")
	state.developer_mode = true
	state.d = state.initial()
	for dimensions: Vector2i in [Vector2i(1440,900),Vector2i(390,844)]:
		DisplayServer.window_set_size(dimensions); root.size=dimensions
		var entry: Control=load("res://scenes/entry.tscn").instantiate()
		root.add_child(entry); await frames()
		await capture("%dx%d-entry"%[dimensions.x,dimensions.y])
		entry.queue_free(); await frames()
		# Retained legacy components: not the user-selected low-occlusion surfaces.
		if ResourceLoader.exists("res://tests/ui_design_specimen.gd"):
			var specimen:Control=load("res://tests/ui_design_specimen.gd").new()
			root.add_child(specimen);await frames()
			fixture_note="Legacy unselected phone/device material specimen; not selected HUD/dialogue/journal acceptance"
			await capture("%dx%d-legacy-component-specimen"%[dimensions.x,dimensions.y])
			specimen.queue_free();await frames()
			fixture_note="DEV fixture; not earned campaign completion"
	shell = load("res://scenes/main.tscn").instantiate()
	root.add_child(shell)
	await frames()
	for dimensions: Vector2i in [Vector2i(1440,900),Vector2i(390,844)]:
		DisplayServer.window_set_size(dimensions)
		root.size = dimensions
		shell.size = Vector2(dimensions)
		for sample: Array in [["c2-dorm-exit","phone_home"],["c2-dorm-exit","zjuding"],["c2-dorm-exit","library_app"],["c2-dorm-exit","settings"],["c3-interlude-reboot","c35_recovery"],["c3-interlude-reboot","c35_network"],["c3-interlude-reboot","c35_voice"]]:
			if not state.begin_checkpoint(sample[0]): push_error("Unknown checkpoint"); quit(2); return
			state.d.native.scene = ""
			state.d.native.page = sample[1]
			state.d.native.settings.volume = 0
			state.d.networkMode = "campus_wifi"
			state.d.phoneBattery.percent = 100
			shell.mobile_world = false
			shell._refresh()
			await frames()
			# Settle the real 1500ms app-entry presentation before page capture.
			shell._process(2.0)
			await frames()
			shell._layout()
			await capture("%dx%d-%s" % [dimensions.x,dimensions.y,sample[1]])
		state.begin_checkpoint("c2-dorm-exit")
		shell._refresh()
		shell.mobile_world = true
		shell._layout()
		await frames(30)
		shell.world.transition_alpha = 0
		shell.world.queue_redraw()
		await capture("%dx%d-world" % [dimensions.x,dimensions.y])
		shell.compact_inventory_open=true; shell._layout()
		await capture("%dx%d-world-inventory" % [dimensions.x,dimensions.y])
		shell._show_journal()
		await capture("%dx%d-journal" % [dimensions.x,dimensions.y])
		shell._close_modal()
		shell._show_settings()
		await capture("%dx%d-pause" % [dimensions.x,dimensions.y])
		shell._close_modal()
		shell._show_inventory()
		await capture("%dx%d-inventory" % [dimensions.x,dimensions.y])
		shell._close_modal()
		var body: VBoxContainer = shell._modal_base("调查记录")
		body.add_child(shell._label("在现场收集证据，再回到这里核对。",17))
		await capture("%dx%d-short-dialog" % [dimensions.x,dimensions.y])
		shell._close_modal()
		await capture_interactions(dimensions)
	# Short-height landscape validates the device/control budget independently of input hardware.
	for compact_landscape:Vector2i in [Vector2i(667,375),Vector2i(568,320)]:
		DisplayServer.window_set_size(compact_landscape);root.size=compact_landscape
		await capture_interactions(compact_landscape)
	var file := FileAccess.open(output.path_join("captures.json"),FileAccess.WRITE)
	if file == null: push_error("Cannot write capture report"); quit(2); return
	file.store_string(JSON.stringify(report,"\t")); file.close()
	await shell.shutdown()
	shell.queue_free()
	await frames()
	print("UI_FIXTURE_VALIDATION_COMPLETE " if validate_only else "UI_CAPTURE_COMPLETE ",report.size())
	quit(1 if capture_failed else 0)


func require_fixture(ok: bool, message: String) -> bool:
	if not ok:
		capture_failed = true
		push_error("UI fixture: " + message)
	return ok

func fresh_shell(dimensions: Vector2i) -> void:
	if is_instance_valid(shell):
		await shell.shutdown()
		shell.queue_free()
		await frames(3)
	root.size = dimensions
	shell = load("res://scenes/main.tscn").instantiate()
	root.add_child(shell)
	shell.mobile_world = true
	shell._refresh()
	await frames(6)
	shell._layout()
	shell.world.transition_alpha = 0
	shell.world.queue_redraw()

func fixture_checkpoint(id: String) -> bool:
	return require_fixture(state.begin_checkpoint(id), "unknown checkpoint " + id)

func press_key(code: Key) -> void:
	for down in [true,false]:
		var event := InputEventKey.new()
		event.keycode = code; event.physical_keycode = code; event.pressed = down
		root.push_input(event)
	await frames(4)

func capture_interactions(dimensions: Vector2i) -> void:
	var prefix := "%dx%d-" % [dimensions.x,dimensions.y]
	# Each row is a fresh isolated DEV fixture, not a continuous/earned replay.
	fixture_note = "DEV checkpoint c2-library-gate; actual campus; not earned completion"
	if not fixture_checkpoint("c2-library-gate"): return
	await fresh_shell(dimensions)
	await capture(prefix + "campus-map")

	fixture_note = "DEV c2-dorm-exit + owned headphone/waterDrop; read-only comparison; not earned completion"
	if not fixture_checkpoint("c2-dorm-exit"): return
	state.d.items.headphone = true; state.d.items.waterDrop = true
	await fresh_shell(dimensions)
	shell._show_observation_comparison()
	var comparison = shell.observation_comparison_session
	comparison.clear()
	var first: bool = comparison.choose("item:headphone")
	var second: bool = comparison.choose("item:waterDrop")
	if require_fixture(first and second and comparison.compare() and is_instance_valid(shell.modal), "comparison opens with two source cards"):
		var view = shell.modal.find_child("ObservationComparison",true,false)
		if require_fixture(is_instance_valid(view), "comparison renderer exists"):
			view._render()
			await capture(prefix + "clue-comparison")

	fixture_note = "DEV c2-occupancy-note + owned occupancyNote; actual inspection; not earned completion"
	if not fixture_checkpoint("c2-occupancy-note"): return
	state.d.items.occupancyNote = true
	await fresh_shell(dimensions)
	shell._inspect_item_by_id("occupancyNote")
	if require_fixture(is_instance_valid(shell.modal), "item inspection opens"):
		await capture(prefix + "item-document")

	fixture_note = "DEV library stamped-proof source session; actual dialogue host; not earned completion"
	state.d = state.initial()
	state.d.native.chapter = 2; state.d.native.scene = "library_interior"; state.d.native.page = "phone_home"
	state.d.runtimeMode = "rpg"; state.d.rpgScene = "library_interior"; state.d.actOne.phase = "complete"
	state.d.ui.libraryFinalsPhase = "evidence_gathering"
	state.d.ui.libraryFinalsPuzzle.nonPersonProofStamped = true
	await fresh_shell(dimensions)
	shell.library_story_host.set_process(false); shell.world.set_process(false)
	shell.world.player = Vector2(334,736); shell.world._sync_player(); shell.world._update_camera()
	var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/library_story_source.json"))
	var session: RefCounted = load("res://scripts/presentation/library_story_session.gd").new(state.d,"library_bag_nonperson_proof_issued",source.sequences.library_bag_nonperson_proof_issued)
	if require_fixture(session.attach(state.d,shell.library_story_host), "source library dialogue attaches"):
		shell.library_story_host.current = session; shell.library_story_host.view.session = session
		shell._layout(); await frames()
		shell.library_story_host.view.tick()
		await capture(prefix + "library-dialogue")

	fixture_note = "DEV theater kiosk authored stand + delivered commission; real Space and wrong 0123 submit; not earned completion"
	state.d = state.initial()
	state.d.native.chapter = 3; state.d.native.scene = "theater_interior"; state.d.native.page = "c3_theater"
	state.d.rpgScene = "theater_interior"; state.d.runtimeMode = "rpg"; state.d.native.mode = "light"
	state.d.canteenHunt.active = true; state.d.canteenHunt.phase = "tray_search"; state.d.canteenHunt.entryPaperEscaped = true
	state.d.theaterHunt.active = true; state.d.theaterHunt.phase = "entry_ticket"; state.d.theaterHunt.mode = "light"
	state.d.theaterHunt.ticketCodeRead = true; state.d.theaterHunt.cc98TicketCommissionPhase = "delivered"
	var chapter = load("res://scripts/chapters/chapter3.gd").new()
	var definition: Dictionary = chapter.get_definition("theater_interior","theater_ticket_kiosk",state.d)
	var stand: Dictionary = definition.get("stand",{"x":definition.x,"y":definition.y})
	state.d.native.player = {"x":stand.x,"y":stand.y,"scene":"theater_interior"}
	await fresh_shell(dimensions)
	shell.world.player = Vector2(stand.x,stand.y); shell.world._sync_player(); shell.world._update_camera(); shell.world._process(0)
	var found := false
	for candidate in shell.world.targets:
		if str(candidate.id) == "theater_ticket_kiosk": shell.world.nearby = candidate; found = true
	if require_fixture(found, "theater authored target exists"):
		shell.world.grab_focus()
		await press_key(KEY_SPACE)
		if require_fixture(is_instance_valid(shell.c3_device_panel), "Space opens actual theater device"):
			for digit in [KEY_0,KEY_1,KEY_2,KEY_3]: await press_key(digit)
			await press_key(KEY_ENTER)
			if require_fixture(is_instance_valid(shell.c3_device_panel) and state.d.theaterHunt.ticketCodeAttempts == 1, "wrong device submit stays open with feedback"):
				await capture(prefix + "theater-device-error")

	fixture_note = "DEV c4-755-room204-1850 missing-film lock; actual controller intent; not earned completion"
	if not fixture_checkpoint("c4-755-room204-1850"): return
	await fresh_shell(dimensions)
	state.act("c4_device_media_alignment")
	await frames(4)
	if require_fixture(is_instance_valid(shell.modal), "C4 media device mounts"):
		if require_fixture(shell.modal.session.view_kind() == "locked", "C4 missing-film lock is actual source state"):
			await capture(prefix + "c4-device-locked")
	shell._close_modal()
	fixture_note = "DEV fixture; not earned campaign completion"

func audit_buttons(node: Node) -> Dictionary:
	var audit: Dictionary={"styled":[],"objects_or_surfaces":[],"missing":[]}
	for child: Node in node.get_children(true):
		if child is Button and child.is_visible_in_tree():
			var script: Script=child.get_script()
			var path: String=script.resource_path if script!=null else ""
			var exempt: bool=bool(child.get_meta("tactile_exempt",false))
			for suffix: String in ["phone_drop_button.gd","inventory_item.gd","clock_visual_card.gd"]:
				if path.ends_with(suffix):exempt=true
			var identity: String=str(child.get_path())
			if exempt:audit.objects_or_surfaces.append(identity)
			elif child.get_node_or_null("TactileMaterialState")!=null:
				audit.styled.append({"path":identity,"variant":child.get_meta("tactile_variant"),"size":child.get_meta("tactile_size"),"disabled":child.disabled})
				if child.name=="NativeModalClose":
					var face: StyleBox=child.get_theme_stylebox("normal")
					var text_width: float=child.get_theme_font("font").get_string_size(child.text,HORIZONTAL_ALIGNMENT_LEFT,-1,child.get_theme_font_size("font_size")).x
					if text_width+face.get_margin(SIDE_LEFT)+face.get_margin(SIDE_RIGHT)>child.size.x+.01:
						capture_failed=true;push_error("Modal close label wraps: "+identity)
			else:audit.missing.append(identity)
		var nested: Dictionary=audit_buttons(child)
		for key: String in audit:audit[key].append_array(nested[key])
	return audit
