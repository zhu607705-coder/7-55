extends SceneTree
const BUILDING = preload("res://campuses/buct/scripts/court_north_building.gd")
const PROFILE := "res://campuses/buct/data/court-north-profile.json"
var checks := 0
var failures: Array[String] = []
var report: Array[Dictionary] = []

func _initialize() -> void: run.call_deferred()

func check(value: bool, label: String) -> void:
	checks += 1
	report.append({"pass": value, "label": label})
	if not value:
		failures.append(label)
		push_error(label)

func run() -> void:
	var profile: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PROFILE))
	var texture: Texture2D = load(str(profile.body_asset))
	for cycle in range(3):
		var stage := Node2D.new()
		stage.y_sort_enabled = true
		root.add_child(stage)
		var body = BUILDING.new()
		stage.add_child(body)
		check(body.configure(profile, texture), "Configure exact body cycle %d" % cycle)
		await process_frame
		check(body.body_passes.size() == 2, "Two compact complementary body passes")
		check(body.collision_shapes.size() == profile.collision_polygons_source_xy.size(), "Only traced wall contact polygons")
		check(body.body_texture.get_image().has_mipmaps(), "Production body mipmaps present")
		check(body.alpha_bytes.size() == body.raw_size.x * body.raw_size.y, "CPU retains only one alpha byte per source pixel")
		check(body.depth_texture.get_width() == body.raw_size.x and body.depth_texture.get_height() == 1, "One width-by-one RF footline texture")
		check(body.get_child_count() == 3, "Only two draw nodes and one physical body")
		for probe in profile.pick_probes_source_xy:
			check(body.hit_test_alpha(Vector2(probe[0], probe[1])) == bool(probe[2]), "Actual-alpha pick " + str(probe))
		for feet in profile.depth_test_foot_y:
			body.update_actor_foot(float(feet), true)
			var partition := true
			var order := true
			for raw_depth in body.column_depths:
				var depth: float = body.global_position.y + body.body_local_origin.y + raw_depth * body.image_scale
				var owners := 0
				for sprite in body.body_passes:
					if not sprite.visible: continue
					var material: ShaderMaterial = sprite.material
					if depth > float(material.get_shader_parameter("depth_lower")) and depth <= float(material.get_shader_parameter("depth_upper")):
						owners += 1
						order = order and ((depth > float(feet)) == (sprite.global_position.y > float(feet)))
				partition = partition and owners == 1
			check(partition, "No gap or double draw at foot " + str(feet))
			check(order, "Exact per-column foot order at " + str(feet))
		if cycle == 0:
			var actor := CharacterBody2D.new()
			actor.collision_layer = 0
			actor.collision_mask = 1
			var shape := CollisionShape2D.new()
			var circle := CircleShape2D.new()
			circle.radius = 3.0
			shape.shape = circle
			actor.add_child(shape)
			stage.add_child(actor)
			for x in profile.collision_test_x:
				var front: float = body.depth_y_at_world_x(float(x))
				actor.position = Vector2(float(x), front + 12.0)
				await physics_frame
				var encountered := false
				for step in range(22):
					await physics_frame
					encountered = actor.move_and_collide(Vector2(0, -1)) != null or encountered
				check(encountered and actor.position.y >= front + 2.65, "Radius-three feet stop at visible wall x=" + str(x))
			actor.position = Vector2(profile.roof_clear_probe[0], profile.roof_clear_probe[1])
			await physics_frame
			check(actor.move_and_collide(Vector2(1, 0)) == null, "Roof projection itself is not a collider; test-only position")
		var weak: WeakRef = weakref(body)
		stage.queue_free()
		await process_frame
		await process_frame
		check(weak.get_ref() == null, "Body node released cycle %d" % cycle)
	var app = load("res://campuses/buct/scenes/playable.tscn").instantiate()
	root.add_child(app)
	await process_frame
	check(is_instance_valid(app.court_north), "Object installed on complete campus")
	check(app.court_north.name == "west_courts_north_bar", "Original neutral object identity retained")
	check(app.objects.get_node("west_courts_north_bar") == app.court_north, "Exactly one authoritative court-north body")
	check(app.court_north.get_node_or_null("SourcePixelSilhouette") == null, "Old UV body retired")
	check(not app.world.get_node("CleanUnderlay_west_courts_north_bar").visible, "Approximate full-footprint ground retired")
	check(profile.ground_repairs.size() == 1, "Exactly one bounded background repair")
	var repair: Sprite2D = app.world.get_node_or_null("CourtNorthMinimalNorthEdgeRepair")
	check(repair != null, "Masked background repair installed")
	if repair != null:
		check(repair.position == Vector2(447, 433) and repair.scale == Vector2.ONE and not repair.centered, "Repair exact source registration; no independent stretch")
		check(repair.texture.get_size() == Vector2(56, 16), "Repair remains the bounded 56x16 source ROI")
		check(repair.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST and repair.z_index == -10, "Exact nearest-filtered source cells stay behind objects")
		check(repair.get_child_count() == 0, "Repair adds no collisions or interactive children")
		var repair_image: Image = repair.texture.get_image()
		check(not repair_image.has_mipmaps(), "Repair import preserves exact non-mipped mask")
		repair_image.convert(Image.FORMAT_RGBA8)
		print("COURT_NORTH_REPAIR_IMPORTED class=",repair.texture.get_class()," rgba_bytes=",repair_image.get_data().size()," mipmaps=",repair_image.has_mipmaps())
		var alpha := PackedByteArray()
		var opaque := 0
		var binary := true
		for y in range(16):
			for x in range(56):
				var a := roundi(repair_image.get_pixel(x, y).a * 255.0)
				alpha.append(a)
				opaque += int(a == 255)
				binary = binary and a in [0, 255]
		check(binary and opaque == 201, "Production texture has exactly 201 opaque source cells")
		var hash := HashingContext.new()
		hash.start(HashingContext.HASH_SHA256)
		hash.update(alpha)
		check(hash.finish().hex_encode() == "42993fb428a3495f9a84fe35753cbe9db14445d4cb754cca5eede239266102e7", "Production alpha equals frozen authorized mask")
		hash.start(HashingContext.HASH_SHA256)
		hash.update(repair_image.get_data())
		check(hash.finish().hex_encode() == "c8a8d0a2039be5b02f8459c5c341a19ee6aa964d90ce82a41d7b65849ec912b0", "Production imported repair matches masked PNG byte-for-byte")
	check(app.court_north.profile.body_image_to_world.scale == 137.0 / 1710.0, "Frozen body uniform scale unchanged after cleanup")
	check(app.court_north.profile.body_image_to_world.origin == [437.7450292397661, 430.92105263157896], "Frozen body origin unchanged after cleanup")
	var visited_before: Array = app.visited.duplicate()
	var progress_before: String = app.progress.text
	for i in range(3):
		app.show_landmark("west_courts_north_bar")
		check(app.info_id == "west_courts_north_bar" and app.info_panel.visible and app.court_north.selected, "Neutral card selection cycle %d" % i)
		check(not app.ui_controls.library_toggle.visible and not app.ui_controls.library_reset.visible, "No whole-building hide or move controls")
		app.close_info()
		check(not app.info_panel.visible and not app.court_north.selected, "Close restores normal map")
	check(app.visited == visited_before and app.progress.text == progress_before, "Original three-POI visit count unchanged")
	for probe in profile.pick_probes_source_xy:
		if bool(probe[2]):
			check(app.landmark_at(Vector2(probe[0], probe[1])) == "west_courts_north_bar", "Normal-map roof selection")
		else:
			check(app.landmark_at(Vector2(probe[0], probe[1])) != "west_courts_north_bar", "Normal-map transparent exterior does not select")
	check(app.data.route_waypoints.size() == 29 and app.data.walkable_polygons.size() == 57, "Original guide and accepted road network preserved")
	check(app.objects.has_node("library_west_avenue_west_canopy"), "Existing southeast canopy preserved")
	check(not app.is_walkable(Vector2(535, 515)), "Southern basketball court remains closed")
	check(app.visitor.character_visual.target_height == 18.0, "Accepted student remains 18 source pixels")
	app.show_landmark("west_inner_l_block")
	check(app.info_id == "west_inner_l_block" and not app.court_north.selected, "Existing L card still works")
	app.close_info()
	app.return_to_gate()
	check(app.visitor.position == Vector2(app.data.spawn[0], app.data.spawn[1]), "Return to gate preserves spawn")
	app.queue_free()
	await process_frame
	var out := OS.get_environment("BUCT_COURT_NORTH_EVIDENCE_DIR")
	if not out.is_empty():
		if not out.is_absolute_path() or DirAccess.make_dir_recursive_absolute(out) != OK:
			printerr("COURT_NORTH_EVIDENCE_WRITE_FAILED: expected a writable absolute output directory")
			quit(2)
			return
		var file := FileAccess.open(out.path_join("headless-results.json"), FileAccess.WRITE)
		if file == null:
			printerr("COURT_NORTH_EVIDENCE_WRITE_FAILED: ", FileAccess.get_open_error())
			quit(2)
			return
		file.store_string(JSON.stringify({"checks": checks, "failures": failures, "results": report}, "  "))
		file.flush()
		if file.get_error() != OK:
			printerr("COURT_NORTH_EVIDENCE_WRITE_FAILED: ", file.get_error())
			quit(2)
			return
	print("BUCT_COURT_NORTH: ", checks, " checks; ", failures.size(), " failures")
	quit(0 if failures.is_empty() else 1)
