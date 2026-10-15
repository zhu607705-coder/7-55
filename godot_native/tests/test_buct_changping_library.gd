extends SceneTree
## Automated production-scene fixture. Off-route poses never change navigation.
var checks := 0
var failures: Array[String] = []
func _initialize() -> void: _run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message);push_error(message)
func _run() -> void:
	var scene: PackedScene = load("res://campuses/buct_changping/scenes/playable.tscn")
	var profile: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://campuses/buct_changping/data/library_registration.json"))
	var layers: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://campuses/buct_changping/data/layers.json"))
	var original: Dictionary = {}
	for item in layers.objects:
		if str(item.id) == "library": original = item
	for cycle in range(2):
		var campus = scene.instantiate()
		root.add_child(campus)
		await process_frame;await physics_frame;await process_frame
		var body = campus.get_node_or_null("RegisteredCampus/IndependentRegisteredObjects/LibraryRGBA")
		check(body != null, "Actual formal scene installs one independent library body")
		if body == null:
			campus.queue_free();await process_frame;continue
		campus.visitor.set_physics_process(false)
		var old = campus.objects.get_node("library")
		check(old.get_child_count() == 2, "Only the original two physical nodes remain under library")
		check(old.position == Vector2(original.anchor[0], original.anchor[1]), "Original collision-group position unchanged")
		for i in range(original.footprints.size()):
			var physical = old.get_node("GroundFootprint%d" % i)
			check(physical is StaticBody2D and physical.collision_layer == 1, "Original native ground-foot physics remains active")
			check(physical.get_child_count() == 1, "No replacement or duplicate collider")
			var shape: CollisionPolygon2D = physical.get_child(0)
			var expected: Array = original.footprints[i] if i == 0 else profile.replacement_east_footprint_source_xy
			check(shape.polygon.size() == expected.size(), "Ground-foot vertex count matches its approved contact contract")
			for j in range(shape.polygon.size()):
				var point: Array = expected[j]
				check(shape.to_global(shape.polygon[j]).is_equal_approx(Vector2(point[0], point[1])), "Ground-foot vertex and transform match approved contact")
		check(body.get_meta("retired_legacy_visual_children") == 4, "Exactly known silhouette, guard, west and east source layers retired")
		check(body.get_meta("disabled_approximate_underlays") == 1, "Only the exact old library body paving cover disabled")
		check(campus.world.get_node("StaticSourceGroundShadows").has_node("library_GroundShadow_1"), "Original separate library source shadow retained")
		check(campus.data.occluders.size() == 10, "Existing route canopies unchanged")
		var diagnostics: Dictionary = body.get_diagnostics()
		check(diagnostics.production_has_mipmaps, "Actual imported production texture has mipmaps")
		check(diagnostics.body_passes_allocated <= 8, "At most eight total shared-texture passes")
		check(diagnostics.surface_count == 2, "Two independent real-face depth fields")
		check(diagnostics.depth_texture_bytes == body.raw_size.x * 2 * 4, "Two-row depth field byte budget")
		for sprite in body.body_passes:
			check(sprite.texture == body.body_texture, "Every pass shares the original complete PNG texture")
			check(sprite.scale == Vector2.ONE * body.image_scale, "Exactly uniform scale on every body pass")
		for point in profile.transparent_probes_source_xy:
			var p := Vector2(point[0], point[1])
			check(not body.hit_test_alpha(p), "Transparent southeast exterior or padding rejects body selection")
			check(campus.landmark_at(p) != "library", "Legacy broad polygon cannot select transparent recess")
		for point in profile.opaque_probes_source_xy:
			var p := Vector2(point[0], point[1])
			check(body.hit_test_alpha(p), "Actual solid facade and triangular glass remain selectable")
			check(campus.landmark_at(p) == "library", "Formal selection uses actual library alpha")
		campus.show_landmark("library")
		check(campus.info_title.text == "图书馆" and body.selected, "Library information and visual selection agree")
		campus.close_info();check(not body.selected, "Closing information clears library selection")
		check(campus.data.route_waypoints.size() == 41, "No added guide waypoint")
		var endpoint: Array = campus.data.route_waypoints[-1]
		check(Vector2(endpoint[0], endpoint[1]) == Vector2(566,816), "Original guide endpoint remains unchanged")
		check(campus.is_walkable(Vector2(566,816)), "Original southern library approach remains walkable")
		check(not campus.is_walkable(Vector2(600,790)), "Recess transparency adds no new route permission")
		check(not campus.is_walkable(Vector2(559,744)), "Opaque glass roof remains outside the permitted route")
		check(body.get_meta("corrected_library_east_ground_foot"), "Only library-owned east contact is corrected")
		var circle := CircleShape2D.new();circle.radius = 3.0
		var query := PhysicsShapeQueryParameters2D.new();query.shape = circle;query.collision_mask = 1
		for free_point in [Vector2(588,798), Vector2(600,790)]:
			query.transform = Transform2D(0.0, free_point)
			check(campus.get_world_2d().direct_space_state.intersect_shape(query).is_empty(), "Radius3 physical fixture can stand in transparent recess without enabling route")
		for point in [Vector2(600,776), Vector2(602,779)]:
			var blocked := false
			for polygon in campus.blockers:
				if Geometry2D.is_point_in_polygon(point, polygon): blocked = true
			check(not blocked, "Navigation blockers no longer retain the displaced legacy east barrier")
		check(campus.visitor.speed == 88.0 and campus.visitor.display_height == 18.0, "Accepted student height and walking speed preserved")
		check(campus.visitor.get_node("FeetCollision").shape.radius == 3.0, "Accepted student feet radius preserved")
		for probe in profile.collision_probes:
			campus.visitor.position = Vector2(probe.start[0], probe.start[1])
			await physics_frame
			var collision = campus.visitor.move_and_collide(Vector2(probe.motion[0], probe.motion[1]), true)
			check(collision != null, "Native feet stop at " + str(probe.name))
			if collision != null:
				var stop: Vector2 = campus.visitor.position + collision.get_travel()
				print("LIBRARY_CONTACT ", probe.name, " stop_y=", stop.y, " expected_radius3_support=", probe.expected_stop_y)
				check(absf(stop.y - float(probe.expected_stop_y)) < 0.3, "Contact matches radius3 physical support at " + str(probe.name))
		for directional in [{"name":"south", "start":Vector2(550,814), "motion":Vector2(0,-40)}, {"name":"north", "start":Vector2(550,773), "motion":Vector2(0,40)}, {"name":"west", "start":Vector2(510,792), "motion":Vector2(40,0)}, {"name":"east", "start":Vector2(589,804.5), "motion":Vector2(-40,0)}]:
			campus.visitor.position = directional.start
			await physics_frame
			var hit = campus.visitor.move_and_collide(directional.motion, true)
			check(hit != null, "Radius3 native feet stop from " + str(directional.name))
			if hit != null: check(hit.get_travel().length() < directional.motion.length(), "Four-way fixture cannot cross the physical wall")
		campus.return_to_gate()
		check(campus.visitor.position == Vector2(515,1510) and campus.info_id == "", "Returning to south gate clears information and restores original spawn")
		var refs: Array[WeakRef] = []
		_collect(campus, refs)
		old = null;body = null;campus.queue_free();campus = null
		await process_frame;await physics_frame;await process_frame
		for ref in refs: check(ref.get_ref() == null, "All campus descendants release after exit")
	print("BUCT_CHANGPING_LIBRARY checks=%d failures=%d" % [checks,failures.size()])
	for message in failures: print("FAIL: " + message)
	quit(0 if failures.is_empty() else 1)
func _collect(node: Node, refs: Array[WeakRef]) -> void:
	refs.append(weakref(node))
	for child in node.get_children(): _collect(child, refs)
