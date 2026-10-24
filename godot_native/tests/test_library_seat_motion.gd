extends SceneTree
## Seeded eligible scenes exercise real keyboard/touch input; not campaign proof.
const Motion = preload("res://scripts/presentation/library_seat_motion.gd")
const Library = preload("res://scripts/chapters/library022.gd")
const Picker = preload("res://scripts/world_object_picker.gd")
var checks := 0
var failures := 0
var state: Node
var shell: Control
var world: Control
var output := OS.get_environment("LIBRARY_SEAT_CAPTURE")

func _initialize() -> void: run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error("LIBRARY_SEAT: " + label)
func frames(count: int = 3) -> void:
	for i in range(count): await process_frame
func fresh() -> Dictionary:
	var s: Dictionary = state.initial()
	s.native.chapter = 2; s.native.scene = "library_interior"; s.native.page = "phone_home"; s.native.mode = "light"
	s.runtimeMode = "rpg"; s.rpgScene = "library_interior"; s.rpgCheckpoint = "library_entrance"
	s.actOne.phase = "complete"; s.actOne.movementEnabled = true; s.actOne.controlsInstalled = true
	s.ui.libraryFinalsPhase = "library_entered"; s.ui.libraryFinalsPuzzle.entranceRecordRead = true
	return s

func finish_story(controller: RefCounted, s: Dictionary) -> void:
	var session: RefCounted = controller.story_session(s)
	if session == null: return
	var witness := RefCounted.new()
	check(session.attach(s,witness), "controller-issued story has a real presentation owner")
	for i in range(session.lines.size()): session.advance(s,witness)
	check(controller.dispatch(s,"lib_story_complete",session).has("story_finished"), "authored inspection dialogue completes before pickup")

func model_checks() -> void:
	var motion: RefCounted = Motion.new()
	var controller: RefCounted = Library.new()
	var s: Dictionary = fresh()
	motion.sync(s)
	controller.dispatch(s,"lib_note"); motion.sync(s)
	check(motion.note_ms < 0 and not motion.note_pose().visible, "rejected early note action has no pickup")
	controller.dispatch(s,"lib_backpack"); motion.sync(s)
	var accepted: Dictionary = s.duplicate(true)
	motion.advance(.30)
	check(motion.bag_pose().offset.length() > 2 and motion.bag_pose().angle < -5, "accepted inspection visibly tips the original bag")
	var during: Dictionary = motion.note_pose()
	check(during.position.distance_to(Motion.NOTE_START) > 0 and during.position.distance_to(Motion.NOTE_AT) > 1 and during.bend > 0, "paper slides and bends through intermediate positions")
	var picker: RefCounted = Picker.new()
	check(picker.contains(Motion.paper_geometry(during),during.position), "current paper geometry contains its moving center")
	check(not picker.contains(Motion.paper_geometry(during),during.position+Vector2(60,0)), "moving paper has no remote invisible hit box")
	check(s == accepted, "inspection animation never writes facts or inventory")
	controller.dispatch(s,"lib_note"); motion.sync(s)
	check(motion.note_ms < 0 and not s.items.occupancyNote, "inspection dialogue still gates early collection")
	finish_story(controller,s)
	s.native.mode = "dark"; controller.dispatch(s,"lib_note"); motion.sync(s)
	check(motion.note_ms < 0 and not s.items.occupancyNote, "dark observation cannot animate physical collection")
	s.native.mode = "light"
	controller.dispatch(s,"lib_note"); motion.sync(s)
	check(motion.note_pose().position == during.position, "quick pickup begins at the current moving paper")
	accepted = s.duplicate(true)
	motion.advance(.25)
	check(motion.note_pose().position.y < during.position.y and motion.note_pose().alpha > .9, "pickup lifts the visible paper before fading")
	var age: float = motion.note_ms
	controller.dispatch(s,"lib_note"); motion.sync(s)
	check(motion.note_ms == age, "repeat collection cannot restart the animation")
	motion.advance(-1); motion.advance(NAN)
	check(motion.note_ms == age, "invalid time cannot rewind or corrupt a pose")
	motion.advance(1)
	check(not motion.note_pose().visible and motion.bag_pose().offset == Vector2.ZERO, "paper leaves the table and bag settles")
	check(s == accepted and s.items.occupancyNote, "finishing the visual does not acquire or consume an item")
	controller.dispatch(s,"lib_receipt"); motion.sync(s)
	check(motion.receipt_ms < 0 and motion.receipt_pose().width == 8, "missing arrow leaves the folded receipt in its gap")
	s.items.rightArrow = true
	controller.dispatch(s,"lib_receipt"); motion.sync(s)
	accepted = s.duplicate(true)
	motion.advance(.45)
	var receipt: Dictionary = motion.receipt_pose()
	check(receipt.width > 8 and receipt.width < 42 and receipt.arrowAlpha > .9, "arrow pushes a partly unfolded receipt")
	check(receipt.position.x > Motion.GAP_AT.x and receipt.position.x < Motion.GAP_AT.x+30, "receipt passes continuously through the gap")
	motion.advance(.4)
	check(motion.receipt_pose().width == 42 and motion.receipt_pose().alpha == 1, "extracted receipt remains readable before removal")
	motion.advance(1)
	check(not motion.receipt_pose().visible and s == accepted, "receipt disappears without a second inventory transaction")
	check(s.items.seat022Receipt and not s.items.rightArrow, "original final-use arrow consumption is preserved")
	s = s.duplicate(true); motion.sync(s)
	check(not motion.note_pose().visible and not motion.receipt_pose().visible, "reload restores collected final poses without replay")
	s = fresh(); motion.sync(s); controller.dispatch(s,"lib_backpack"); motion.sync(s); motion.advance(.2)
	s.native.scene = "campus_bootstrap"; motion.sync(s)
	check(motion.inspect_ms < 0 and not motion.note_pose().visible, "leaving the library cancels pending motion")
	s.native.scene = "library_interior"; motion.sync(s)
	check(motion.note_pose().position == Motion.NOTE_AT and motion.inspect_ms < 0, "reentry shows the earned paper at rest")
	s = fresh(); s.native.settings.reduced_motion = true; motion.sync(s)
	controller.dispatch(s,"lib_backpack"); motion.sync(s); motion.advance(.09)
	check(motion.bag_pose().offset == Vector2.ZERO and motion.note_pose().position == Motion.NOTE_AT, "reduced motion omits rocking and sliding")
	motion.advance(.1); finish_story(controller,s); controller.dispatch(s,"lib_note"); motion.sync(s); motion.advance(.19)
	check(not motion.note_pose().visible and s.items.occupancyNote, "reduced pickup reaches the same earned result")
	var view := Control.new(); root.add_child(view); motion.bind_view(view)
	s = fresh(); motion.sync(s); controller.dispatch(s,"lib_backpack"); motion.sync(s)
	view.hide()
	check(motion.inspect_ms < 0, "hiding the surface cancels transient movement")
	view.show(); motion.sync(s)
	check(motion.inspect_ms < 0 and motion.note_pose().position == Motion.NOTE_AT, "showing the surface cannot replay old movement")
	view.queue_free(); await frames()
	check(not motion.active, "destroying the surface releases its presentation")

func fixture(dim: Vector2i, action: String) -> void:
	root.size = dim
	if DisplayServer.get_name() != "headless": DisplayServer.window_set_size(dim)
	state.story_reset.emit(); state.d = fresh(); state.developer_mode = true
	var at := Vector2(1255,470)
	if action != "lib_backpack":
		state.d.ui.libraryFinalsPhase = "occupied_seat_found"
		state.d.ui.libraryFinalsPuzzle.backpackInspected = true
		at = Vector2(1282,470)
	if action == "lib_receipt":
		state.d.ui.libraryFinalsPhase = "evidence_gathering"
		state.d.ui.libraryFinalsPuzzle.occupancyNoteCollected = true
		state.d.items.rightArrow = true; state.d.native.selected_item = "rightArrow"
		at = Vector2(1348,470)
	state.d.native.positions = {"library_interior:":{"x":at.x,"y":at.y}}
	shell = load("res://scenes/main.tscn").instantiate(); root.add_child(shell); await frames(5)
	shell._show_world_mobile(); await frames()
	shell.set_process(false); world = shell.world; world.set_process(false)
	world.player = at; world._sync_player(); world._update_camera(); world._process(0)
	world.transition_alpha = 0
	world.grab_focus(); world.queue_redraw(); await frames()
	check(world.library_layers.rebuild.ready and world.can_stand(at), "fixture uses separated art and valid original floor " + action + str(dim))

func ordinary_input(action: String, touch: bool) -> void:
	if touch:
		var at: Vector2 = Motion.NOTE_AT if action == "lib_note" else Motion.GAP_AT if action == "lib_receipt" else Vector2(1255,407)
		var local: Vector2 = (at-world.camera)*world.zoom+world.size/2
		check(world.exploration_safe_rect(true).has_point(local), "touch point is inside visible play area " + action)
		for down in [true,false]:
			var event := InputEventScreenTouch.new(); event.index = 0; event.position = local; event.pressed = down
			world._gui_input(event); await frames(1)
	else:
		check(world.nearby.get("action", "") == action, "ordinary proximity chooses " + action)
		for down in [true,false]:
			var key := InputEventKey.new(); key.keycode = KEY_SPACE; key.physical_keycode = KEY_SPACE; key.pressed = down
			root.push_input(key,true); await frames(1)
	await frames()

func advance(ms: float) -> void:
	for i in range(int(ms/10)): world.library_layers.tick(.01,state.d)
	world.queue_redraw(); await frames()

func capture(label: String) -> void:
	if output.is_empty() or DisplayServer.get_name() == "headless": return
	world.queue_redraw(); await frames(); await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join("%dx%d_%s.png" % [root.size.x,root.size.y,label]))

func scene_checks() -> void:
	for dim in [Vector2i(1280,720),Vector2i(390,844),Vector2i(844,390)]:
		for action: String in ["lib_backpack","lib_note","lib_receipt"]:
			await fixture(dim,action)
			var layer: RefCounted = world.library_layers
			var original_solids: Array = world.collisions.duplicate(true)
			await capture(action+"_00_before")
			await ordinary_input(action,dim.x<1000)
			layer.sync(state.d)
			var clock: float = layer.seat.inspect_ms if action=="lib_backpack" else layer.seat.note_ms if action=="lib_note" else layer.seat.receipt_ms
			check(clock >= 0, "ordinary input starts physical feedback " + action + str(dim))
			var accepted: Dictionary = state.d.duplicate(true)
			await advance(300); await capture(action+"_01_moving")
			if action=="lib_note":
				var point: Vector2 = (Motion.NOTE_AT-world.camera)*world.zoom+world.size/2
				check(world._pick_target(point).get("id", "") != "occupancy_note", "collected paper is no longer a live target")
			await advance(300); await capture(action+"_02_moving")
			await advance(900); await capture(action+"_03_after")
			check(state.d.items==accepted.items and state.d.ui.libraryFinalsPuzzle==accepted.ui.libraryFinalsPuzzle and world.collisions==original_solids, "visual ticks preserve controller items, facts and solids " + action)
			if is_instance_valid(shell.audio_director): await shell.audio_director.shutdown()
			if is_instance_valid(shell.media_host): await shell.media_host.shutdown()
			shell.queue_free(); await frames()

func run() -> void:
	check(load("res://tests/native_test_isolation.gd").is_isolated_save(), "isolated test profile")
	if failures: quit(1); return
	state = root.get_node("State")
	if not output.is_empty(): DirAccess.make_dir_recursive_absolute(output)
	await model_checks()
	await scene_checks()
	print("Library seat motion: ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)
