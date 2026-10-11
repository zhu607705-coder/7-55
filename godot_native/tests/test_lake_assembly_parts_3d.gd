extends SceneTree
## Asset-free geometry/rig checks. No controller, state singleton or texture imports needed.
const PartsScene = preload("res://scenes/objects/lake_assembly_parts.tscn")
var checks := 0
var failures := 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("LAKE 3D PARTS: " + label)

func run() -> void:
	var parts: Node3D = PartsScene.instantiate()
	root.add_child(parts)
	for name_string in ["Rod", "Frame", "Rope", "MagneticClasp", "LeftHand", "RightHand"]:
		check(parts.get_node(name_string) is Node3D, "independent part " + name_string)
	check(parts.get_node("Rod/Shaft") is MeshInstance3D, "rod uses native mesh")
	check(parts.get_anchor("rod_tip").global_position.is_equal_approx(parts.get_anchor("frame_socket").global_position), "socket meets rod tip")
	check(parts.get_anchor("clasp_seat").global_position.is_equal_approx(parts.get_anchor("clasp_contact").global_position), "clasp contact matches rim")
	check(parts.get_anchor("frame_grip").position.distance_to(Vector3(.34418, .00777, .21903)) < .0001, "frame grasp is centered on intact rim")
	check(parts.get_anchor("clasp_grip").position.is_equal_approx(Vector3(0, .034, .204)), "clasp grasp is centered on bridge")
	check(parts.get_anchor("rod_grip").position.is_equal_approx(Vector3(-1.44, 0, 0)), "rod grasp uses handle centerline")
	# Marker equality alone cannot prove two wide soles touch a curved, uneven rim.
	var rim := parts.get_node("Frame/BentOvalRim") as MeshInstance3D
	for pole in ["red_pole_contact", "blue_pole_contact"]:
		var sole: Vector3 = parts.get_anchor(pole).global_position
		var surface_height := rim_height_below(rim, sole)
		check(is_finite(surface_height), "pole projects onto actual rim triangles " + pole)
		check(sole.y - surface_height <= 0.0 and sole.y - surface_height >= -.004, "physical sole seats without hovering or deep clipping " + pole)
	check(parts.get_node("LeftHand/GripAnchor").position.is_equal_approx(Vector3(0, -.06, -.07)), "left grasp local anchor")
	check(parts.get_node("RightHand/GripAnchor").position.is_equal_approx(Vector3(0, -.06, -.07)), "right grasp local anchor")
	var meshes: Array = parts.find_children("*", "MeshInstance3D", true, false)
	check(meshes.size() > 100 and meshes.size() < 300, "sensible bounded mesh/node budget")
	var vertex_count := 0
	for instance: MeshInstance3D in meshes:
		check(instance.mesh != null and instance.mesh.get_surface_count() > 0, "nonempty mesh " + str(instance.name))
		check(instance.owner == parts, "baked editable owner " + str(instance.name))
		check(instance.material_override is StandardMaterial3D, "native GLES material " + str(instance.name))
		for surface_index in range(instance.mesh.get_surface_count()):
			var arrays := instance.mesh.surface_get_arrays(surface_index)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			vertex_count += vertices.size()
			var finite := true
			for vertex: Vector3 in vertices:
				finite = finite and vertex.is_finite()
			check(finite, "finite coordinates " + str(instance.name))
	check(vertex_count < 40000, "geometry stays below 40k vertices")
	var core := parts.get_node("Rope/CordCore") as MeshInstance3D
	var previous_count := 0
	for progress in [0.0, .2, .4, .6, .8, 1.0]:
		parts.set_rope_progress(progress, 0.0)
		var count: int = core.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size()
		check(count > previous_count, "continuous rope reveal increases geometry")
		previous_count = count
		check(parts.get_anchor("rope_tip").position.is_finite(), "free end tracks reveal")
	parts.set_rope_progress(1.0, 0.0)
	var loose_size := core.mesh.get_aabb().size
	parts.set_rope_progress(1.0, 1.0)
	check(core.mesh.get_aabb().size.y < loose_size.y, "tightening draws wraps onto socket")
	var stable_mesh := core.mesh
	parts.set_rope_progress(1.0, 1.0)
	check(core.mesh == stable_mesh, "held pose does not allocate replacement rope")
	parts.set_rod_flex(1.0)
	check(is_equal_approx(parts.get_anchor("rod_tip").position.y, .12), "rod flex moves actual tip")
	parts.set_rod_flex(-1.0)
	check(is_equal_approx(parts.get_anchor("rod_tip").position.y, -.12), "rod rebound is symmetric")
	parts.set_rod_flex(0.0)
	check(parts.get_anchor("rod_tip").global_position.is_equal_approx(parts.get_anchor("frame_socket").global_position), "flex recovery restores contact")
	for side in ["left", "right"]:
		var hand_name := "LeftHand" if side == "left" else "RightHand"
		parts.set_hand_grip(side, 0.0)
		var finger := parts.get_node(hand_name + "/Finger1/Middle/Tip") as Node3D
		var open_tip := finger.global_position
		parts.set_hand_grip(side, 1.0)
		check(finger.global_position.distance_to(open_tip) > .06, "articulated grip moves joints " + side)
		check(parts.get_node(hand_name + "/Thumb/Tip").rotation.x < -.8, "thumb closes " + side)
	var initial_count := parts.get_child_count()
	for i in range(12):
		parts.set_rope_progress(float(i) / 11.0, float(i) / 11.0)
		parts.set_rod_flex(sin(float(i)))
	check(parts.get_child_count() == initial_count, "animation never duplicates objects")
	parts.queue_free()
	await process_frame
	check(not is_instance_valid(parts), "owned parts clean up with presentation")
	print("LAKE 3D PARTS: ", checks, " checks, ", failures, " failures; ", meshes.size(), " meshes / ", vertex_count, " vertices")
	quit(1 if failures > 0 else 0)

func rim_height_below(rim: MeshInstance3D, sole: Vector3) -> float:
	var faces := rim.mesh.get_faces()
	var highest := -INF
	for i in range(0, faces.size(), 3):
		var hit = Geometry3D.ray_intersects_triangle(sole + Vector3.UP * .3, Vector3.DOWN, rim.to_global(faces[i]), rim.to_global(faces[i + 1]), rim.to_global(faces[i + 2]))
		if hit != null:
			highest = maxf(highest, hit.y)
	return highest
