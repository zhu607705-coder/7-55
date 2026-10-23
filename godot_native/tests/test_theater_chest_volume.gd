extends SceneTree
## Real miniature geometry in an isolated SubViewport. This test checks source
## projection and continuous physical poses, without reading/writing game State.
const Volume = preload("res://scripts/objects/theater_chest_contents_3d.gd")
var checks: int = 0
var failures: int = 0
var view: SubViewport
var volume: Node3D

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("THEATER_CHEST_VOLUME: " + label)

func frames(count: int = 2) -> void:
	for index: int in count:
		await process_frame

func snapshot(slots: Array = ["", "", ""], installed: bool = false, turns: int = 0) -> Dictionary:
	var remaining: Array = []
	for piece: String in ["fan", "butterfly", "lamp"]:
		if piece not in slots: remaining.append(piece)
	if not installed: remaining.append("crank")
	return {"slots": slots.duplicate(), "remaining": remaining, "crank_installed": installed, "turns": turns, "clue_open": false, "drawer_open": false}

func object_for(piece: String) -> Node3D:
	return volume.crank if piece == "crank" else volume.tokens[piece]

func check_pose(actual: Transform3D, expected: Transform3D, label: String, position_tolerance: float = 0.02) -> void:
	check(actual.origin.distance_to(expected.origin) <= position_tolerance, label + " position remains continuous (delta %.4f)" % actual.origin.distance_to(expected.origin))
	var actual_rotation := actual.basis.orthonormalized().get_rotation_quaternion()
	var expected_rotation := expected.basis.orthonormalized().get_rotation_quaternion()
	check(actual_rotation.angle_to(expected_rotation) < 0.002, label + " rotation remains continuous")
	check(actual.basis.get_scale().distance_to(expected.basis.get_scale()) < 0.0001, label + " physical size remains continuous")

func collect_3d(parent: Node, result: Array[WeakRef]) -> void:
	for child: Node in parent.get_children():
		if child is Node3D: result.append(weakref(child))
		collect_3d(child, result)

func polygon_area(points: PackedVector2Array) -> float:
	var twice_area := 0.0
	for index: int in points.size():
		twice_area += points[index].cross(points[(index + 1) % points.size()])
	return absf(twice_area) * 0.5

func test_projection() -> void:
	var camera: Camera3D = volume.camera
	check(camera.projection == Camera3D.PROJECTION_ORTHOGONAL, "miniature uses an orthographic camera")
	check((-camera.global_basis.z).distance_to(Vector3.DOWN) < 0.00001, "camera points exactly down, without a 45-degree view")
	for source: Vector2 in [Vector2(270, 383), Vector2(724, 633.5), Vector2(1178, 884)]:
		var projected := camera.unproject_position(Vector3(source.x, 0, source.y))
		check(projected.distance_to(source) < 0.05, "floor source point %s projects at 1:1" % source)
		var raised := camera.unproject_position(Vector3(source.x, 110, source.y))
		check(raised.distance_to(projected) < 0.05, "height changes depth without moving the top-down hotspot")

func test_volume_and_stack() -> void:
	volume.update_state(snapshot())
	var heights: Array[float] = []
	for piece: String in ["fan", "butterfly", "lamp"]:
		var node := object_for(piece)
		heights.append(node.position.y)
		var body: MeshInstance3D = node.get_node("ExtrudedBrassBevel")
		check(body.mesh is ArrayMesh and body.mesh.get_aabb().size.y > 5, piece + " has an extruded mesh rather than a flat sprite")
		var arrays: Array = body.mesh.surface_get_arrays(0)
		check(arrays[Mesh.ARRAY_VERTEX].size() > 36 and arrays[Mesh.ARRAY_NORMAL].size() > 0, piece + " has beveled faces with lighting normals")
		check(absf(body.mesh.get_aabb().size.x * node.scale.x - 92.0) < 0.01, piece + " keeps its authored physical width")
	check(absf(heights[0] - heights[1]) > 10 and absf(heights[1] - heights[2]) > 10 and heights[0] != heights[2], "loose pieces occupy distinct actual heights")
	for pair: Array in [["fan", "butterfly"], ["butterfly", "lamp"]]:
		var intersections: Array[PackedVector2Array] = Geometry2D.intersect_polygons(volume.projected_polygon(pair[0]), volume.projected_polygon(pair[1]))
		var overlap := 0.0
		for polygon: PackedVector2Array in intersections: overlap += polygon_area(polygon)
		check(overlap > 1, "%s and %s visibly overlap in projection" % pair)
	for piece: String in ["fan", "butterfly", "lamp", "crank"]:
		volume.update_state(snapshot())
		var rest: Transform3D = object_for(piece).transform
		volume.update_state(snapshot(), "", piece)
		check_pose(object_for(piece).transform, rest, piece + " hover")
		volume.update_state(snapshot(), piece)
		var lifted: Transform3D = rest
		lifted.origin += Vector3.UP * 65
		check_pose(object_for(piece).transform, lifted, piece + " selected lift")
	var receivers := volume.find_children("ShadowReceivingWoodFloor*", "MeshInstance3D", true, false)
	check(not receivers.is_empty(), "real floor meshes receive contact shadows")
	for receiver: MeshInstance3D in receivers:
		var material := receiver.material_override as StandardMaterial3D
		check(material != null and material.albedo_texture != null and material.shading_mode != BaseMaterial3D.SHADING_MODE_UNSHADED, "floor receives light over its source wood texture")
	var light: DirectionalLight3D = volume.get_node("UpperLeftContactLight")
	check(light.shadow_enabled and light.light_energy > 0, "miniature contains an active shadow-casting light")

func test_placement(piece: String, before: Dictionary, after: Dictionary, label: String) -> void:
	# Capture both actual endpoint poses independently of the flight code. This
	# catches late orientation/size snaps without repeating its interpolation.
	volume.update_state(after)
	var target: Transform3D = object_for(piece).transform
	volume.update_state(before, piece)
	var source: Transform3D = object_for(piece).transform
	var from := Vector2(source.origin.x, source.origin.z)
	var to := Vector2(target.origin.x, target.origin.z)
	volume.update_state(before, piece, "", 0, 0, 0, piece, from, to, 0)
	check_pose(object_for(piece).transform, source, label + " start")
	for amount: float in [0.25, 0.5, 0.75]:
		volume.update_state(before, piece, "", 0, 0, 0, piece, from, to, amount)
		var in_flight: Transform3D = object_for(piece).transform
		check(in_flight.basis.get_scale().distance_to(source.basis.get_scale()) < 0.0001, label + " keeps physical size throughout flight")
		var direct_height := lerpf(source.origin.y, target.origin.y, amount)
		check(in_flight.origin.y > direct_height + 1, label + " lifts above its direct placement path")
	volume.update_state(before, piece, "", 0, 0, 0, piece, from, to, 1)
	var last_frame: Transform3D = object_for(piece).transform
	volume.update_state(after)
	check_pose(last_frame, object_for(piece).transform, label + " committed endpoint")
	check(source.basis.get_scale().distance_to(target.basis.get_scale()) < 0.0001, label + " fits its socket without shrinking the object")

func test_turn() -> void:
	var before := snapshot(["butterfly", "lamp", "fan"], true)
	volume.update_state(before, "", "", TAU / 3.0)
	var endpoints: Dictionary = {}
	for piece: String in ["fan", "butterfly", "lamp", "crank"]:
		endpoints[piece] = object_for(piece).transform
	var rotor_endpoint: Transform3D = volume.rotor.transform
	volume.update_state(snapshot(["fan", "butterfly", "lamp"], true, 1))
	for piece: String in ["fan", "butterfly", "lamp", "crank"]:
		check_pose(endpoints[piece], object_for(piece).transform, piece + " turn handoff", 3.0)
	check_pose(rotor_endpoint, volume.rotor.transform, "rotor turn handoff")

func test_drawer() -> void:
	volume.update_state(snapshot())
	var board: MeshInstance3D = volume.get_node("SlidingFalseBottom")
	var mesh := board.mesh as PlaneMesh
	var full_depth := mesh.size.y
	var front_edge := board.position.z + full_depth * 0.5
	check(board.visible and full_depth > 50, "closed compartment has a physical covering board")
	volume.update_state(snapshot(), "", "", 0, 0, 0.5)
	check(board.visible and mesh.size.y < full_depth and mesh.size.y > 0, "sliding board reveals part of the actual opening")
	check(absf(board.position.z + mesh.size.y * 0.5 - front_edge) < 0.01, "board slides under the fixed front lip")
	volume.update_state(snapshot(), "", "", 0, 0, 1)
	check(not board.visible, "fully open compartment exposes its contents without a covering plane")
	volume.update_state(snapshot())
	check(board.visible and is_equal_approx(mesh.size.y, full_depth), "fresh view restores the closed board geometry")

func run() -> void:
	var baseline: Array[WeakRef] = []
	collect_3d(root, baseline)
	view = SubViewport.new()
	view.name = "ChestVolumeTestViewport"
	view.size = Vector2i(1448, 1086)
	view.transparent_bg = true
	view.own_world_3d = true
	view.gui_disable_input = true
	root.add_child(view)
	volume = Volume.new()
	view.add_child(volume)
	await frames()
	test_projection()
	test_volume_and_stack()
	test_placement("fan", snapshot(), snapshot(["", "fan", ""]), "loose fan placement")
	test_placement("fan", snapshot(["fan", "", ""], true, 2), snapshot(["", "", "fan"], true, 2), "fitted fan relocation")
	test_placement("crank", snapshot(["fan", "butterfly", "lamp"], false, 1), snapshot(["fan", "butterfly", "lamp"], true, 1), "crank installation")
	test_turn()
	test_drawer()
	var owned: Array[WeakRef] = []
	collect_3d(view, owned)
	check(owned.size() > 10, "test mounted actual geometry, lights and camera")
	var view_ref: WeakRef = weakref(view)
	view.queue_free()
	await frames(3)
	check(view_ref.get_ref() == null, "closing frees the isolated SubViewport")
	var released := true
	for reference: WeakRef in owned:
		if reference.get_ref() != null: released = false
	check(released, "closing releases every owned 3D node")
	var after: Array[WeakRef] = []
	collect_3d(root, after)
	check(after.size() == baseline.size(), "no miniature nodes escape into the surrounding scene tree")
	print("THEATER_CHEST_VOLUME: %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)
