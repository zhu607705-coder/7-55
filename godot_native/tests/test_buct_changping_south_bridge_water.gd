extends SceneTree
var checks := 0
var failures: Array[String] = []
var campus: Node2D
const WATER = preload("res://campuses/buct_changping/scripts/south_bridge_water_surface.gd")
func _initialize() -> void: run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:failures.append(label);push_error(label)
func tick() -> void:await physics_frame;await process_frame
func run() -> void:
	root.size = Vector2i(1440,900)
	campus = load("res://campuses/buct_changping/scenes/playable.tscn").instantiate()
	root.add_child(campus);await tick();await tick()
	var segment: Node2D = campus.south_bridge_surface
	var main: Node2D = campus.lake_surface
	check(campus.initialized and is_instance_valid(segment) and is_instance_valid(main), "Both production water layers initialize")
	if not is_instance_valid(segment):await finish();return
	var ground: Sprite2D = segment.static_ground
	check(segment.position == Vector2(395,867) and segment.water_sprite.texture.get_size() == Vector2(24,21), "Fixed 24x21 source crop")
	check(segment.get_child_count() == 1 and segment.water_sprite.material == null, "One static Sprite2D without a motion shader")
	check(segment.find_children("*", "CollisionObject2D", true, false).is_empty(), "No new collision or traversal authority")
	check(ground.material == segment.cutout_material and main.cutout_material != segment.cutout_material, "Atomic compound cutout retains original main-owner material")
	check(main.animation_enabled and main.position == Vector2(317,750), "Main animation and position unchanged")
	var original: Image = campus.SOURCE.get_image()
	var count := 0;var errors := 0;var walkable := 0;var hit_errors := 0
	for y in range(21):
		for x in range(24):
			var p: Color = segment.alpha_image.get_pixel(x,y)
			var point := Vector2(395+x+0.5,867+y+0.5)
			if segment.hit_test_alpha(point) != (p.a > 0.5):hit_errors += 1
			if p.a > 0.5:
				count += 1
				var source := original.get_pixel(395+x,867+y)
				if p.r8 != source.r8 or p.g8 != source.g8 or p.b8 != source.b8:errors += 1
				if campus.is_walkable(point):walkable += 1
	check(count == 72 and errors == 0, "72 imported opaque RGB pixels match original bytes")
	check(walkable == 0 and hit_errors == 0, "Every water pixel alpha-selects and remains non-walkable")
	for point in [Vector2(403,862),Vector2(406,869),Vector2(398,878),Vector2(414,882),Vector2(405,887),Vector2(405,896),Vector2(400,800)]:
		check(not segment.hit_test_alpha(point), "Excluded bridge/bank/next water/main water: " + str(point))
	for i in range(3):
		segment.hide();check(not segment.hit_test_alpha(Vector2(404,878)) and ground.material == segment.cutout_material, "Hidden segment leaves a real segment-only cutout")
		segment.show();check(segment.hit_test_alpha(Vector2(404,878)) and segment.position == Vector2(395,867), "Show restores same fixed alpha")
	check(WATER.install(campus.world,main) == null and ground.material == segment.cutout_material, "Duplicate install rejected without mutation")
	var invalid := Node2D.new();invalid.set_script(WATER)
	check(not invalid.configure(segment.profile,null,ground,main), "Missing texture fails closed")
	var bad := Image.create(24,21,false,Image.FORMAT_RGBA8);bad.fill(Color.WHITE)
	check(not invalid.configure(segment.profile,ImageTexture.create_from_image(bad),ground,main), "Wrong same-sized pixels fail closed")
	var wrong: Dictionary = segment.profile.duplicate(true);wrong.crop_source_xywh[0] = 396
	check(not invalid.configure(wrong,segment.water_sprite.texture,ground,main), "Moved registration fails closed")
	check(invalid.get_child_count() == 0 and ground.material == segment.cutout_material, "All failures preserve complete original ownership")
	invalid.free()
	campus.visitor.set_physics_process(false);campus.set_process(false)
	campus.camera.position_smoothing_enabled = false;campus.camera.position = Vector2(420,842);campus.camera.zoom = Vector2.ONE*2.1
	campus.camera.reset_smoothing();campus.camera.force_update_scroll();await tick();await tick()
	campus.path_to(Vector2(517,1487));var path: PackedVector2Array = campus.current_path.duplicate()
	for touch in [false,true]:
		await pointer(Vector2(404.5,878.5),touch)
		check(segment.selected and not main.selected and campus.current_path == path, "Real input selects static water, not travel")
		await pointer(Vector2(398.5,878.5),touch)
		check(not segment.selected and campus.current_path == path, "Transparent bank cancels without travel")
		await pointer(Vector2(404.5,878.5),touch);await pointer(Vector2(400.5,800.5),touch)
		check(main.selected and not segment.selected and campus.current_path == path, "Main selection remains independent")
		await pointer(Vector2(404.5,878.5),touch)
		check(segment.selected and not main.selected, "Back to segment clears main selection")
	# Removal order 1: segment first restores the untouched main cutout.
	segment.free();check(ground.material == main.cutout_material, "Segment removal restores exactly original main cutout")
	segment = WATER.install(campus.world,main);campus.south_bridge_surface = segment
	check(is_instance_valid(segment) and ground.material == segment.cutout_material, "Reinstall is safe after removal")
	# Removal order 2: main first restores main pixels but retains segment cutout.
	main.free();campus.lake_surface = null
	check(ground.material == segment.cutout_material and segment.cutout_material.get_shader_parameter("main_installed") == false, "Main-first removal restores main pixels and keeps segment separated")
	segment.free();campus.south_bridge_surface = null
	check(ground.material == null, "Last owner removal restores untouched full ground")
	# A foreign material installed later is never overwritten by component cleanup.
	main = load("res://campuses/buct_changping/scripts/liuhu_water_surface.gd").install(campus.world);campus.lake_surface = main
	segment = WATER.install(campus.world,main);campus.south_bridge_surface = segment
	var foreign := CanvasItemMaterial.new();ground.material = foreign;segment.free();campus.south_bridge_surface = null
	check(ground.material == foreign, "Cleanup respects newer foreign owner")
	ground.material = main.cutout_material
	check(campus.data.route_waypoints.size() == 41 and campus.data.landmarks.size() == 3 and campus.walk_polys.size() == 83, "Original route and POIs unchanged; accepted east and north road paving retained")
	await finish()
func pointer(point: Vector2,touch: bool) -> void:
	var screen: Vector2 = campus.get_canvas_transform()*point
	check(campus.map_area.has_point(screen), "Input fixture in map viewport")
	for pressed in [true,false]:
		if touch:
			var e := InputEventScreenTouch.new();e.index = 0;e.position = screen;e.pressed = pressed;Input.parse_input_event(e)
		else:
			var e := InputEventMouseButton.new();e.button_index = MOUSE_BUTTON_LEFT;e.position = screen;e.global_position = screen;e.pressed = pressed;Input.parse_input_event(e)
		await tick()
func finish() -> void:
	var report := {"checks":checks,"failures":failures}
	var out := OS.get_environment("BUCT_SOUTH_BRIDGE_OUTPUT")
	if not out.is_empty():
		var f := FileAccess.open(out.path_join("native-validation.json"),FileAccess.WRITE)
		if f == null:check(false,"Requested evidence must be writable")
		else:f.store_string(JSON.stringify(report,"  ")+"\n");f.close()
	print("BUCT_SOUTH_BRIDGE_NATIVE ",JSON.stringify(report))
	campus.queue_free();await process_frame;await process_frame
	quit(0 if failures.is_empty() else 1)
