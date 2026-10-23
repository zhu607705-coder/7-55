extends SceneTree
## Seeded eligible Library fixture, real State/World input, no campaign claim.
const Printer = preload("res://scripts/ui/library_printer_object.gd")
const Rebuild = preload("res://scripts/ui/library_object_rebuild.gd")
var checks := 0
var failures := 0
var state: Node
var shell: Control
var world: Control
var observed: Array = []
var snapshots: Array = []
var output := OS.get_environment("LIBRARY_PRINTER_CAPTURE")

func _initialize() -> void: run.call_deferred()
func frames(count: int = 3) -> void:
	for index in range(count): await process_frame
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error("LIBRARY_PRINTER: " + label)
func story(state_value: Dictionary) -> Dictionary:
	return {"items":state_value.items.duplicate(true), "puzzle":state_value.ui.libraryFinalsPuzzle.duplicate(true), "phase":state_value.ui.libraryFinalsPhase, "checkpoint":state_value.rpgCheckpoint}
func fixture(dim: Vector2i) -> void:
	root.size = dim
	if DisplayServer.get_name() != "headless": DisplayServer.window_set_size(dim)
	state.story_reset.emit()
	state.d = state.initial(); state.developer_mode = true
	state.d.native.chapter = 2; state.d.native.scene = "library_interior"; state.d.native.page = "phone_home"
	state.d.runtimeMode = "rpg"; state.d.rpgScene = "library_interior"; state.d.rpgCheckpoint = "library_entrance"
	state.d.actOne.phase = "complete"; state.d.ui.libraryFinalsPhase = "evidence_gathering"
	state.d.ui.libraryFinalsPuzzle.libraryVisitedPoints = ["entrance"]
	state.d.native.positions = {"library_interior:":{"x":890.0,"y":625.0}}
	shell = load("res://scenes/main.tscn").instantiate(); root.add_child(shell)
	await frames(5)
	shell._show_world_mobile(); await frames()
	shell.set_process(false); world = shell.world; world.set_process(false)
	world.player = Vector2(890,625); world._sync_player(); world._update_camera(); world._process(0)
	world.library_layers.printer.bind_view(world)
	world.grab_focus(); world.queue_redraw(); await frames()
	check(world.scene_id == "library_interior" and world.can_stand(world.player), "fixture starts on original clear floor near printer")
	check(world.nearby.get("action", "") == "lib_printer", "original nearest-object resolver selects printer")

func inspect() -> void:
	for pressed in [true,false]:
		var key := InputEventKey.new(); key.keycode = KEY_SPACE; key.physical_keycode = KEY_SPACE; key.pressed = pressed
		root.push_input(key,true); await frames(1)
	await frames()

func capture(label: String) -> void:
	var printer: RefCounted = world.library_layers.printer
	snapshots.append({"viewport":[root.size.x,root.size.y],"phase":label,"presentation":printer.snapshot(),"player":[world.player.x,world.player.y]})
	if output.is_empty() or DisplayServer.get_name() == "headless": return
	world.queue_redraw(); await frames(); await RenderingServer.frame_post_draw
	var stem := "%dx%d_%s" % [root.size.x,root.size.y,label]
	root.get_texture().get_image().save_png(output.path_join(stem+".png"))
	var image: Image = world.get_viewport().get_texture().get_image()
	var at: Vector2 = (Vector2(826,568)-world.camera)*world.zoom+world.size/2
	var crop := Rect2i(Vector2i(at)-Vector2i(70,85),Vector2i(140,170)).intersection(Rect2i(Vector2i.ZERO,image.get_size()))
	if crop.has_area(): image.get_region(crop).save_png(output.path_join(stem+"_source_crop.png"))

func geometry_check(printer: RefCounted, geometry: Dictionary) -> void:
	var original: Image = geometry.texture.get_image()
	if original.is_compressed(): original.decompress()
	var composite: Image = Image.create(original.get_width(),original.get_height(),false,original.get_format())
	composite.fill(Color.TRANSPARENT)
	var pieces: Array = printer.parts(geometry)
	for part: Dictionary in pieces:
		check(not part.has("color"), "closed source has no procedural replacement pixels")
		var rect: Rect2 = part.source
		composite.blit_rect(original,Rect2i(rect),Vector2i(rect.position))
		check(is_equal_approx(part.rect.size.x/rect.size.x,part.rect.size.y/rect.size.y), "all cut parts preserve uniform source-pixel density")
	check(original.get_region(Rect2i(geometry.source)).get_data() == composite.get_region(Rect2i(geometry.source)).get_data(), "closed body, drawer and latch reconstruct exact original sprite bytes")

func run() -> void:
	check(load("res://tests/native_test_isolation.gd").is_isolated_save(), "isolated save profile")
	if failures: quit(1); return
	state = root.get_node("State")
	state.action_completed.connect(func(action: String,_before: Dictionary,_next: Dictionary,result: Dictionary): observed.append({"action":action,"message":result.get("message", "")}))
	if not output.is_empty(): DirAccess.make_dir_recursive_absolute(output)
	for dim in [Vector2i(1280,720),Vector2i(390,844),Vector2i(844,390)]:
		await fixture(dim)
		var layer: RefCounted = world.library_layers
		var printer: RefCounted = layer.printer
		check(layer.rebuild.ready and printer.snapshot().stateConnected, "real generated printer and original State observer are bound")
		var geometry: Dictionary = layer.rebuild.geometry("printer",layer.rebuild.bounds("printer"))
		var solids: Array = world.collisions.duplicate(true)
		geometry_check(printer,geometry)
		await capture("00_closed")
		var before: Dictionary = story(state.d)
		await inspect()
		check(not observed.is_empty() and observed[-1].action == "lib_printer" and observed[-1].message == Printer.OBSERVATION, "ordinary focused Space reaches accepted original observation")
		check(printer.playing and printer.inspections == 1 and not layer.blocks_movement() and not world._scene_presentation_blocks(), "one inspect starts independent motion without a movement gate")
		check(story(state.d) == before, "accepted observation adds no item, puzzle fact, phase or checkpoint")
		var accepted: Dictionary = state.d.duplicate(true)
		printer.advance(.30); await capture("01_pulling")
		var age: float = printer.elapsed_ms
		await inspect()
		check(printer.inspections == 1 and printer.elapsed_ms == age, "repeated ordinary inspect cannot stack or restart an active drawer")
		accepted = state.d.duplicate(true)
		printer.advance(.34); await capture("02_paper_exposed")
		check(printer.pose().offset == Printer.TRAVEL and printer.pose().phase == "open", "open drawer reveals paper during the short settle")
		for part: Dictionary in printer.parts(geometry):
			if part.has("texture"): check(is_equal_approx(part.rect.size.x/part.source.size.x,part.rect.size.y/part.source.size.y), "animated parts never stretch the original image")
		printer.advance(-1); printer.advance(NAN)
		check(is_equal_approx(printer.elapsed_ms,640), "invalid time cannot rewind or corrupt the sequence")
		printer.advance(.40); await capture("03_closing")
		printer.advance(.50); await capture("04_closed")
		check(not printer.playing and printer.pose().offset == Vector2.ZERO and printer.parts(geometry).size() > 1, "completion settles every part at the original source pose")
		check(state.d == accepted and world.collisions == solids, "animation ticks never write game state or collision geometry")
		geometry_check(printer,geometry)
		await inspect(); check(printer.playing and printer.inspections == 2, "a later fresh inspect may replay after the first sequence settles")
		world.hide(); check(not printer.playing, "hiding world for phone cancels disposable motion immediately")
		world.show(); world.grab_focus(); await inspect()
		check(printer.playing, "visible world accepts an ordinary new inspect")
		state.d = state.d.duplicate(true); layer.sync(state.d)
		check(not printer.playing and printer.snapshot().stateConnected, "loaded equivalent save restores closed pose and current State ownership")
		state.d.native.settings.reduced_motion = true; layer.sync(state.d)
		await inspect(); check(printer.playing and printer.pose().offset == Printer.TRAVEL, "reduced motion uses one brief stable open pose")
		printer.advance(.18); check(not printer.playing, "reduced motion settles without a wait or action lock")
		state.d.native.settings.reduced_motion = false
		state.d.native.scene = "campus_bootstrap"; layer.sync(state.d)
		state.act("lib_printer")
		check(not printer.playing and not printer.snapshot().stateConnected and not Printer.accepted("lib_printer",state.d,state.d,state.last_result), "original outside-library refusal cannot animate or retain its observer")
		state.d.native.scene = "library_interior"; layer.sync(state.d)
		var connection_count: int = state.action_completed.get_connections().size()
		var disposable: RefCounted = Printer.new(); disposable.sync(state.d,true); disposable.bind_view(world)
		var weak: WeakRef = weakref(disposable)
		check(state.action_completed.get_connections().size() == connection_count+1, "temporary presentation owns one read-only notification")
		disposable = null
		check(weak.get_ref() == null and state.action_completed.get_connections().size() == connection_count, "weak notification allows RefCounted destruction and disconnects without a cycle")
		state.act("lib_printer"); check(printer.playing, "scene teardown fixture begins with an accepted observation")
		await shell.shutdown(); shell.queue_free(); await frames()
		check(not printer.playing and not printer.snapshot().stateConnected, "world tree exit clears pose and disconnects State even while a test retains the layer")
		printer.dispose()
	if not output.is_empty():
		var file := FileAccess.open(output.path_join("capture.json"),FileAccess.WRITE)
		file.store_string(JSON.stringify({"scope":"Seeded eligible Library; actual Main/World focused Space and original State action; frozen authorized presentation poses; not an earned campaign or physical mobile test", "engine":Engine.get_version_info(),"checks":checks,"failures":failures,"snapshots":snapshots,"actions":observed},"  "))
	print("LIBRARY_PRINTER_OBJECT: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
