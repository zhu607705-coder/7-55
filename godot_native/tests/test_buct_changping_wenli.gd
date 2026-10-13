extends SceneTree
## Actual production scene; fixture poses never add navigation permissions.
var checks := 0
var failures: Array[String] = []
func _initialize() -> void: _run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label);push_error(label)
func _run() -> void:
	var scene: PackedScene = load("res://campuses/buct_changping/scenes/playable.tscn")
	var original_data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://campuses/buct_changping/data/layers.json"))
	var original: Dictionary = {}
	for item in original_data.objects:
		if str(item.id) == "wenli_building": original = item
	for cycle in range(2):
		var campus = scene.instantiate();root.add_child(campus)
		await process_frame;await physics_frame;await process_frame
		var body = campus.get_node_or_null("RegisteredCampus/IndependentRegisteredObjects/WenliRGBA")
		check(body != null, "Formal Changping scene installs independent Wenli body")
		if body == null:campus.queue_free();await process_frame;continue
		campus.visitor.set_physics_process(false)
		var old = campus.objects.get_node("wenli_building")
		check(old.get_child_count() == 3, "Only three original physics children remain")
		check(old.position == Vector2(original.anchor[0],original.anchor[1]), "Original collision group transform unchanged")
		for i in range(3):
			var physical = old.get_node("GroundFootprint%d" % i)
			check(physical is StaticBody2D and physical.collision_layer == 1, "Original body remains active")
			check(physical.get_child_count() == 1, "No duplicate collider")
			var shape: CollisionPolygon2D = physical.get_child(0)
			var expected: Array = original.footprints[i]
			check(shape.polygon.size() == expected.size(), "Original collider vertex count unchanged")
			for j in range(expected.size()):
				check(shape.to_global(shape.polygon[j]).is_equal_approx(Vector2(expected[j][0],expected[j][1])), "Exact original world-space collider vertex")
		check(body.get_meta("retired_legacy_visual_children") == 4, "Only four old UV visual parts retired")
		check(body.get_meta("disabled_approximate_underlays") == 4, "Four known old approximate covers disabled")
		check(campus.world.has_node("WenliInferredGroundWithinOriginalBodyOnly"), "Bounded inferred ground remains independent of body visibility")
		check(body.profile.surface_count == 5, "Five explicit visual foot surfaces")
		check(body.get_diagnostics().production_has_mipmaps, "Production imported raw body has mipmaps")
		check(body.body_passes.size() == 2, "Only two complementary actor depth passes allocated")
		for sprite in body.body_passes:
			check(sprite.texture == body.body_texture, "All passes share complete immutable PNG")
			check(sprite.scale == Vector2.ONE * body.image_scale, "Uniform rendering scale")
		for point in body.profile.transparent_probes_source_xy:
			var p := Vector2(point[0],point[1])
			check(not body.hit_test_alpha(p), "Courtyard or exterior true alpha rejects picking")
			check(campus.landmark_at(p) != "wenli_building", "No bounding-box or legacy courtyard selection")
		for point in body.profile.high_confidence_courtyard_core_source_xy:
			check(not body.hit_test_alpha(Vector2(point[0],point[1])), "Three source-backed high-confidence courtyard cores stay transparent")
		check(body.hit_test_alpha(Vector2(704,782)), "Source central low-roof probe remains opaque")
		for point in body.profile.opaque_probes_source_xy:
			var p := Vector2(point[0],point[1])
			check(body.hit_test_alpha(p), "Solid surfaces including central low roof are pickable")
			check(campus.landmark_at(p) == "wenli_building", "Formal picker uses exact body alpha")
		var visited_before: int = campus.visited.size()
		campus.show_landmark("wenli_building")
		check(campus.info_id == "wenli_building" and campus.info_title.text == "文理楼" and body.selected, "Wenli information selects same visual body")
		check(campus.visited.size() == visited_before, "New exterior card does not invent a fourth tour goal")
		campus.close_info();check(not body.selected, "Close clears selection")
		body.hide();check(not body.hit_test_alpha(Vector2(706,779)), "Hidden body is not selectable")
		check(campus.world.get_node("WenliInferredGroundWithinOriginalBodyOnly").visible, "Hiding body leaves inferred substrate visible")
		body.show()
		check(campus.data.route_waypoints.size() == 41 and campus.data.landmarks.size() == 3, "Original guide and three original POIs unchanged")
		check(campus.data.occluders.size() == 10, "Original canopy owners unchanged")
		check(not campus.is_walkable(Vector2(718,780)), "Transparency adds no courtyard access")
		check(not campus.is_walkable(Vector2(691,777)), "Central low roof does not become a route")
		check(campus.is_walkable(Vector2(769,810)), "Existing east road remains usable beside Wenli")
		check(campus.visitor.speed == 88.0 and campus.visitor.display_height == 18.0, "Existing student speed and size unchanged")
		check(campus.visitor.get_node("FeetCollision").shape.radius == 3.0, "Existing radius3 feet unchanged")
		for probe in [{"name":"south","start":Vector2(710,850),"motion":Vector2(0,-40)},{"name":"north","start":Vector2(710,793),"motion":Vector2(0,40)},{"name":"west","start":Vector2(655,791),"motion":Vector2(35,0)},{"name":"east","start":Vector2(770,790),"motion":Vector2(-35,0)}]:
			campus.visitor.position = probe.start;await physics_frame
			var collision = campus.visitor.move_and_collide(probe.motion,true)
			check(collision != null, "Original physical feet stop from " + str(probe.name))
			if collision != null:
				print("WENLI_CONTACT ",probe.name," position=",campus.visitor.position + collision.get_travel())
				check(collision.get_travel().length() < probe.motion.length(), "No physical wall crossing")
		campus.return_to_gate();check(campus.visitor.position == Vector2(515,1510), "Return-to-gate remains exact")
		var refs: Array[WeakRef] = [];_collect(campus,refs)
		old = null;body = null;campus.queue_free();campus = null
		await process_frame;await physics_frame;await process_frame
		for ref in refs:check(ref.get_ref() == null,"All campus nodes release on exit")
	print("BUCT_CHANGPING_WENLI checks=%d failures=%d"%[checks,failures.size()])
	for failure in failures:print("FAIL: "+failure)
	quit(0 if failures.is_empty() else 1)
func _collect(node: Node, refs: Array[WeakRef]) -> void:
	refs.append(weakref(node))
	for child in node.get_children():_collect(child,refs)
