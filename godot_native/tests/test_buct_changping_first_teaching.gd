extends SceneTree
var checks := 0
var failures: Array[String] = []
func _initialize() -> void:
	_run.call_deferred()
func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures.append(message);push_error(message)
func _run() -> void:
	var scene: PackedScene = load("res://campuses/buct_changping/scenes/playable.tscn")
	var reference: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://campuses/buct_changping/data/first_teaching_registration.json"))
	for cycle in range(2):
		var campus = scene.instantiate()
		root.add_child(campus)
		await process_frame;await physics_frame;await process_frame
		var body = campus.get_node_or_null("RegisteredCampus/IndependentRegisteredObjects/FirstTeachingRGBA")
		check(body != null, "Actual formal Changping scene installs native first teaching")
		if body == null:
			campus.queue_free();await process_frame;continue
		var old = campus.objects.get_node("main_building")
		check(old.get_child_count() == 2, "Only two frozen physical bodies remain under old main_building")
		for child in old.get_children():check(child is StaticBody2D and child.collision_layer == 1, "Old ground collision remains active")
		check(body.get_meta("disabled_approximate_underlays") == 3, "Only exact original arc/bar/spine paving covers disabled")
		check(campus.world.get_node("StaticSourceGroundShadows").has_node("main_building_GroundShadow_1"), "Actual original ground shadow retained")
		var info: Dictionary = body.get_diagnostics()
		check(info.production_has_mipmaps, "Actual production body Texture carries mipmaps")
		check(info.body_passes_allocated <= 8, "At most eight TOTAL depth passes")
		check(info.surface_count == 3 and info.depth_texture_bytes == 21060, "Independent three-row physical depth table")
		check(info.surface_texture_bytes == 1572480, "Single full-size one-byte surface field")
		for sprite in body.body_passes:check(sprite.texture == body.body_texture, "All passes share original whole PNG texture")
		for p in [Vector2(450,1139),Vector2(469,1143),Vector2(476,1151),Vector2(560,1142),Vector2(579,1145),Vector2(562,1157)]:
			check(not body.hit_test_alpha(p), "Transparent original courtyard rejects body selection")
			check(campus.landmark_at(p) != "main_building", "Old broad source polygon cannot select courtyard")
		var opaque_point := Vector2(520,1180)
		check(body.hit_test_alpha(opaque_point), "Opaque central building selects by real alpha")
		check(campus.landmark_at(opaque_point) == "main_building", "Formal landmark selection uses new alpha")
		campus.show_landmark("main_building")
		check(campus.info_title.text == "第一教学楼" and body.selected, "Verified Chinese building name and selection")
		campus.close_info();check(not body.selected, "Closing information clears body cue")
		var id_image: Image = body.surface_texture.get_image()
		for pair in reference.semantic_probe_pairs:
			var x := int(pair.raw_x)
			check(roundi(id_image.get_pixel(x,200).r * 255.0) == 1, "Rear courtyard-facing wall has independent surface ID")
			check(roundi(id_image.get_pixel(x,650).r * 255.0) == 3, "Front crescent has distinct surface ID in same column")
			check(float(pair.rear_world_foot) < 1160 and float(pair.front_world_foot) > 1160, "Actor foot between rear and front masses has opposite ordering")
		body.update_actor_foot(1160, true)
		check(body.get_diagnostics().body_passes_active == 2, "Middle-courtyard depth fixture splits real faces, no navigation added")
		check(campus.is_walkable(Vector2(517,1210)), "Existing southern POI approach stays walkable")
		check(not campus.is_walkable(Vector2(520,1180)), "Building is still non-walkable")
		check(campus.visitor.speed == 88.0 and campus.visitor.display_height == 18.0, "Student walking speed stays frozen")
		var weak: Array[WeakRef] = []
		_collect(campus, weak)
		id_image = null;old = null;body = null;campus.queue_free();campus = null
		await process_frame;await physics_frame;await process_frame
		for ref in weak:check(ref.get_ref() == null, "Every campus, ground-fragment, body/pass and original-shadow descendant released after exit")
	print("BUCT_CHANGPING_FIRST_TEACHING checks=%d failures=%d" % [checks,failures.size()])
	for item in failures:print("FAIL: " + item)
	quit(0 if failures.is_empty() else 1)
func _collect(node: Node, refs: Array[WeakRef]) -> void:
	refs.append(weakref(node))
	for child in node.get_children():_collect(child,refs)
