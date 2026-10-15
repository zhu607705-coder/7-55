extends SceneTree
## Run with the editor binary --main-pack <release.pck> --script <absolute path>.
## Export templates ignore --script; this validates real packaged resources.
var checks := 0
var failures: Array[String] = []
var finished := false
var expects_squirrel := false
var squirrel_present := false
var state: Node
var snapshot: Dictionary

func _initialize() -> void:
	create_timer(120).timeout.connect(func():
		if not finished:
			check(false, "Exported campus contract exceeded 120 seconds")
			finish())
	run.call_deferred()

func frames(count := 5) -> void:
	for i in range(count): await process_frame

func check(ok: bool, label: String) -> bool:
	checks += 1
	if not ok:
		failures.append(label)
		push_error(label)
	return ok

func finish() -> void:
	if finished: return
	finished = true
	var result := {"checks": checks, "failures": failures,
		"status": "passed" if failures.is_empty() else "failed",
		"expects_squirrel": expects_squirrel, "squirrel_present": squirrel_present,
		"scope": "Real release PCK resources, chooser pointers, physical walking, scene retirement and story resume; not a hardware performance test"}
	var output := OS.get_environment("BUCT_EXPORTED_QA_DIR")
	if output.is_absolute_path():
		DirAccess.make_dir_recursive_absolute(output)
		var file := FileAccess.open(output.path_join("result.json"), FileAccess.WRITE)
		if file == null:
			printerr("Cannot write exported campus report")
			quit(1)
			return
		file.store_string(JSON.stringify(result, "  "))
	print("EXPORTED_CAMPUSES " + JSON.stringify(result))
	quit(0 if failures.is_empty() else 1)

func click(control: Control) -> void:
	if not is_instance_valid(control):
		check(false, "Expected pointer control is missing")
		finish()
		return
	var point := control.get_global_transform_with_canvas() * (control.size / 2)
	for down in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		root.push_input(event)
	await frames()

func scene_is(path: String) -> bool:
	return check(is_instance_valid(current_scene) and current_scene.scene_file_path == path,
		"Actual chooser reaches " + path)

func chooser() -> bool:
	return scene_is("res://scenes/entry.tscn")

func run() -> void:
	expects_squirrel = OS.get_environment("BUCT_REQUIRE_SQUIRREL") == "1" or ResourceLoader.exists("res://campuses/buct/scripts/ambient_squirrel.gd")
	if not check(not FileAccess.file_exists("res://campuses/buct_changping/assets/approved-changping.png"), "PCK omits raw source PNG; imported texture is the integrity authority"):
		finish(); return
	state = root.get_node_or_null("State")
	if not check(state != null, "Pack initializes the original State autoload"):
		finish(); return
	state.d = state.initial()
	state.d.native.page = "phone_home"
	state.d.currentScene = "phone_home"
	snapshot = state.d.duplicate(true)
	root.size = Vector2i(1280, 720)
	root.set_meta("entry_arguments_consumed", true)
	if not check(change_scene_to_file("res://scenes/entry.tscn") == OK, "Pack loads chooser"):
		finish(); return
	await frames()
	if not chooser(): finish(); return
	await click(current_scene.changping_button)
	if finished or not scene_is("res://campuses/buct_changping/scenes/playable.tscn"):
		finish(); return
	var campus = current_scene
	if not check(campus.initialized, "Exported Changping initializes"):
		finish(); return
	var regions: Array = [campus.wenli_hd_region, campus.north_hd_region, campus.north_large_hd_region, campus.north_west_upper_hd_region]
	regions.append_array(campus.west_hd_regions)
	check(regions.size() == 6, "Exactly six exported HD owners are registered")
	for region in regions:
		check(is_instance_valid(region) and region.get_diagnostics().active, "Exported HD owner is active without silent fallback")
	if not check(is_instance_valid(campus.north_west_upper_hd_region), "Exported sixth region exists"):
		finish(); return
	check(campus.north_west_upper_hd_region.bodies.has("dorm_nw_02"), "Independent original NW dorm body is in the PCK")
	check(campus.walk_polys.size() == 83, "Export retains 83 road polygons")
	check(campus.path_to(Vector2(666, 548)), "Export preserves continuous south-to-north road connectivity")
	campus.current_path.clear()
	var start: Vector2 = campus.visitor.position
	check(campus.path_to(Vector2(666, 548)), "Physical visitor path starts at original spawn on the north route")
	var illegal := 0
	for i in range(120):
		await physics_frame
		await process_frame
		if not campus.is_walkable(campus.visitor.position): illegal += 1
	check(campus.visitor.position.distance_to(start) > 40, "Actual exported character physically walks more than 40 source pixels")
	check(illegal == 0, "Every sampled exported walking position remains legal")
	await click(campus.ui_controls.reset)
	check(campus.visitor.position == start, "Pointer reset restores the original south-gate spawn")
	await click(campus.ui_controls.nearby)
	check(not campus.info_id.is_empty(), "Exported landmark card opens through real pointer input")
	await click(campus.ui_controls.close)
	check(campus.info_id.is_empty(), "Exported landmark card closes")
	var campus_ref: WeakRef = weakref(campus)
	var region_refs: Array[WeakRef] = []
	for region in regions:
		if is_instance_valid(region): region_refs.append(weakref(region))
	regions.clear()
	await click(campus.return_button)
	if not chooser(): finish(); return
	check(campus_ref.get_ref() == null, "Changping scene retires after actual return")
	for reference in region_refs: check(reference.get_ref() == null, "Exported HD owner is freed on return")
	check(state.d == snapshot, "Changping does not change story state")
	await click(current_scene.campus_button)
	if not scene_is("res://campuses/buct/scenes/playable.tscn"):
		finish(); return
	var chaoyang = current_scene
	var squirrel_ref: WeakRef
	if expects_squirrel:
		var squirrel = chaoyang.get("ambient_squirrel")
		squirrel_present = is_instance_valid(squirrel)
		if not check(squirrel_present, "Expected combined-build squirrel is packaged and installed"):
			finish(); return
		squirrel_ref = weakref(squirrel)
	await click(chaoyang.ui_controls.back)
	if not chooser(): finish(); return
	if expects_squirrel: check(squirrel_ref.get_ref() == null, "Exported squirrel retires on return")
	check(state.d == snapshot, "Chaoyang preserves story state")
	await click(current_scene.haidian_button)
	if not scene_is("res://campuses/buct_haidian/scenes/playable.tscn"):
		finish(); return
	var haidian = current_scene
	if not check(haidian.initialized, "Exported Haidian initializes"):
		finish(); return
	await click(haidian.return_button)
	if not chooser(): finish(); return
	check(state.d == snapshot, "Haidian preserves story state")
	await click(current_scene.story_button)
	if not scene_is("res://scenes/main.tscn"):
		finish(); return
	check(state.d.native.page == "phone_home", "Story Continue resumes the original fixture page")
	if current_scene.has_method("shutdown"): await current_scene.shutdown()
	current_scene.queue_free()
	await frames()
	finish()
