extends SceneTree
var checks := 0
var failures: Array[String] = []
var campus: Node2D
var report: Dictionary = {}

func _initialize() -> void: run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label); push_error(label)
func tick() -> void: await physics_frame; await process_frame

func run() -> void:
	# Dummy headless display defaults to 64x64; give the input fixture a real logical map area.
	root.size = Vector2i(1440,900)
	campus = load("res://campuses/buct_changping/scenes/playable.tscn").instantiate()
	root.add_child(campus)
	await tick(); await tick()
	check(campus.initialized, "Production Changping scene initializes")
	var lake: Node2D = campus.lake_surface
	check(is_instance_valid(lake), "Independent water component installs")
	if not is_instance_valid(lake): await finish(); return
	check(lake.name == "LiuLakeMainSurface" and lake.position == Vector2(317, 750), "Water stays at its original source location")
	check(lake.get_child_count() == 1 and lake.water_sprite is Sprite2D, "One sprite, not per-pixel nodes")
	check(lake.find_children("*", "CollisionObject2D", true, false).is_empty(), "Water creates no extra physics or permission")
	check(lake.water_sprite.texture.get_size() == Vector2(163, 108), "Small independently owned water Texture2D")
	check(lake.static_ground.material == campus.south_bridge_surface.cutout_material, "Static background has complementary water cutout")
	var invalid := Node2D.new()
	invalid.set_script(load("res://campuses/buct_changping/scripts/liuhu_water_surface.gd"))
	var original_material: Material = lake.static_ground.material
	var distance_texture: Texture2D = lake.water_material.get_shader_parameter("shore_distance")
	check(not invalid.configure(lake.profile, null, distance_texture, lake.static_ground), "Missing water texture fails before mutation")
	check(not invalid.configure(lake.profile, lake.water_sprite.texture, null, lake.static_ground), "Missing distance texture fails before mutation")
	var broken := Image.create(163,108,false,Image.FORMAT_RGBA8)
	broken.fill(Color(0.2,0.5,0.4,1.0))
	check(not invalid.configure(lake.profile, ImageTexture.create_from_image(broken), distance_texture, lake.static_ground), "Wrong same-sized imported pixel data fails closed")
	check(lake.static_ground.material == original_material and invalid.get_child_count() == 0, "Resource failure never punches original ground or creates partial water")
	invalid.free()
	check(not lake.selected and lake.animation_enabled, "Default subtle motion with no selection")
	check(campus.data.route_waypoints.size() == 41 and campus.data.landmarks.size() == 3, "Original 41 route points and 3 POIs")
	check(campus.walk_polys.size() == 82, "Original paving plus existing east road only")
	check(campus.visitor.display_height == 18 and campus.visitor.speed == 88, "Shared student size and speed retained")
	check(campus.visitor.get_node("FeetCollision").shape.radius == 3, "Original foot collision retained")
	check(is_instance_valid(campus.first_teaching_layer) and is_instance_valid(campus.library_layer) and is_instance_valid(campus.east_road_extension), "Existing building and east-road layers retained")
	var original: Image = campus.SOURCE.get_image()
	var count := 0; var rgb_errors := 0; var hit_errors := 0; var walkable_water := 0
	for y in range(108):
		for x in range(163):
			var pixel: Color = lake.alpha_image.get_pixel(x, y)
			var point := Vector2(317 + x + 0.5, 750 + y + 0.5)
			var expected := pixel.a > 0.5
			if lake.hit_test_alpha(point) != expected: hit_errors += 1
			if expected:
				count += 1
				var src := original.get_pixel(317 + x, 750 + y)
				if pixel.r8 != src.r8 or pixel.g8 != src.g8 or pixel.b8 != src.b8: rgb_errors += 1
				if campus.is_walkable(point): walkable_water += 1
	check(count == 7140, "Exactly 7140 reviewed source-water pixels")
	check(rgb_errors == 0, "Imported opaque RGB is still byte-identical to source")
	check(hit_errors == 0, "Every pixel selection uses actual alpha")
	check(walkable_water == 0, "Every visible water pixel remains non-walkable")
	for point in [Vector2(393,817), Vector2(386,806), Vector2(374,834), Vector2(440,748), Vector2(438,863), Vector2(409,880), Vector2(472,801), Vector2(319,752)]:
		check(not lake.hit_test_alpha(point), "Dry feature/crop exterior does not hit water: " + str(point))
	for i in range(3):
		lake.set_animation_enabled(false); await tick()
		check(not lake.animation_enabled and lake.water_material.get_shader_parameter("animation_enabled") == false, "Static switch " + str(i))
		lake.set_animation_enabled(true); await tick()
		check(lake.animation_enabled and lake.position == Vector2(317,750), "Motion resumes with no displacement " + str(i))
	lake.hide()
	check(not lake.hit_test_alpha(Vector2(400,800)) and lake.static_ground.material == campus.south_bridge_surface.cutout_material, "Hidden independent node leaves real cutout and cannot be selected")
	lake.show()
	# Real mouse/touch input with the original canvas conversion and route state.
	# Freeze actor only for this explicit input fixture; it is not travel evidence.
	campus.visitor.set_physics_process(false); campus.set_process(false)
	campus.camera.position_smoothing_enabled = false
	campus.camera.position = Vector2(420,805)
	campus.camera.zoom = Vector2.ONE * 2.1
	campus.camera.reset_smoothing(); campus.camera.force_update_scroll(); await tick(); await tick()
	report.input_view = {"viewport":[root.size.x,root.size.y],"map_area":str(campus.map_area),"canvas_transform":str(campus.get_canvas_transform()),"lake_screen":str(campus.get_canvas_transform()*Vector2(400,800))}
	print("LIUHU_INPUT_VIEW ",JSON.stringify(report.input_view))
	campus.path_to(Vector2(517,1487))
	var original_path: PackedVector2Array = campus.current_path.duplicate()
	var original_visits: Array = campus.visited.duplicate()
	for touch in [false, true]:
		lake.set_selected(false)
		await pointer(Vector2(400,800), touch)
		check(lake.selected, "Actual input selects water: " + str(touch))
		check(campus.current_path == original_path and campus.visited == original_visits, "Water click never starts/replaces route or creates POI: " + str(touch))
		await pointer(Vector2(393,817), touch)
		check(not lake.selected and campus.current_path == original_path, "Transparent islet deselects, never becomes water/navigation: " + str(touch))
		await pointer(Vector2(400,800), touch)
		await pointer(Vector2(400,800), touch)
		check(lake.selected, "Repeated/emulated water input is idempotent: " + str(touch))
		await pointer(Vector2(319,752), touch)
		check(not lake.selected, "Click outside actual alpha cancels selection: " + str(touch))
		check(campus.status.text == "沿开放的铺装步道探索校园", "Cancellation clears water selection feedback: " + str(touch))
	check(campus.visited == original_visits, "Water interactions do not alter tour visits")
	report.pixel_audit = {"water_pixels":count, "rgb_errors":rgb_errors, "alpha_hit_errors":hit_errors, "walkable_water_pixels":walkable_water}
	report.input_fixture = "Real InputEventMouseButton and InputEventScreenTouch; static actor/camera fixture only, not continuous travel. Existing east-road test supplies travel regression separately."
	await finish()

func pointer(point: Vector2, touch: bool) -> void:
	var screen: Vector2 = campus.get_canvas_transform() * point
	check(campus.map_area.has_point(screen), "Input fixture lies in active map viewport")
	for pressed in [true, false]:
		if touch:
			var event := InputEventScreenTouch.new(); event.index = 0; event.position = screen; event.pressed = pressed
			Input.parse_input_event(event)
		else:
			var event := InputEventMouseButton.new(); event.button_index = MOUSE_BUTTON_LEFT; event.position = screen; event.global_position = screen; event.pressed = pressed
			Input.parse_input_event(event)
		await tick()

func finish() -> void:
	report.checks = checks; report.failures = failures
	var out := OS.get_environment("BUCT_LIUHU_OUTPUT")
	if not out.is_empty():
		var file := FileAccess.open(out.path_join("native-validation.json"), FileAccess.WRITE)
		if file == null: check(false,"Cannot write explicitly requested native evidence")
		else: file.store_string(JSON.stringify(report,"  ") + "\n"); file.close()
	print("BUCT_LIUHU_NATIVE checks=%d failures=%d" % [checks, failures.size()])
	campus.queue_free()
	await process_frame; await process_frame
	quit(0 if failures.is_empty() else 1)
