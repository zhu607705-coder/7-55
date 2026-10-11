@tool
extends Node3D
## Native, independently transformable close-up props. Presentation only.
## Meshes are baked in lake_assembly_parts.tscn; this builder also permits regeneration.
## Local units: rod tip (.45,0,0), frame socket (-.5,0,0) at frame origin (.95,0,0).
## Hands point along local -Z. Palm normal is +Y; sleeve extends along +Z.

const FRAME_REST := Vector3(.95, 0, 0)
const ROPE_REST := Vector3(.45, 0, 0)
## Chord-centered position and roll seat both soles on the actual faceted oval rim.
const CLASP_SEAT := Vector3(.2569, .0312, -.2554)
const CLASP_REST := FRAME_REST + CLASP_SEAT
const CLASP_YAW := 2.627
const CLASP_ROLL := .056
const SHAFT_START := -1.22
const SHAFT_END := .45

@export_range(0.0, 1.0) var wrap_progress: float = 1.0
@export_range(0.0, 1.0) var rope_tension: float = 1.0
@export_range(-1.0, 1.0) var rod_flex: float = 0.0

var _materials: Dictionary = {}
var _rope_tip := Vector3.ZERO
var _built := false
var _last_wrap: float = -1.0
var _last_tension: float = -1.0
var _last_flex: float = INF

func _ready() -> void:
	ensure_geometry()
	set_rope_progress(wrap_progress, rope_tension)
	set_rod_flex(rod_flex)

func ensure_geometry() -> void:
	if has_node("Rod/Shaft"):
		_built = true
		return
	build_geometry()

func build_geometry() -> void:
	for child: Node in get_children():
		remove_child(child)
		child.free()
	_materials.clear()
	_last_wrap = -1.0
	_last_tension = -1.0
	_last_flex = INF
	_build_rod()
	_build_frame()
	_build_rope()
	_build_clasp()
	_build_hand("LeftHand", -1.0)
	_build_hand("RightHand", 1.0)
	get_node("LeftHand").position = Vector3(-1.35, .13, .20)
	get_node("RightHand").position = Vector3(.39, .15, .27)
	_built = true
	set_rope_progress(wrap_progress, rope_tension)
	set_hand_grip(&"left", .65)
	set_hand_grip(&"right", .45)

func get_anchor(anchor_name: StringName) -> Marker3D:
	var paths := {
		&"rod_tip": "Rod/TipAnchor", &"rod_grip": "Rod/GripAnchor",
		&"frame_socket": "Frame/SocketAnchor", &"clasp_seat": "Frame/ClaspSeatAnchor",
		&"clasp_contact": "MagneticClasp/ContactAnchor", &"rope_tip": "Rope/FreeEndAnchor",
		&"frame_grip": "Frame/GripAnchor", &"clasp_grip": "MagneticClasp/GripAnchor",
		&"red_pole_contact": "MagneticClasp/RedPoleContact", &"blue_pole_contact": "MagneticClasp/BluePoleContact",
		&"left_grasp": "LeftHand/GripAnchor", &"right_grasp": "RightHand/GripAnchor"
	}
	return get_node_or_null(paths.get(anchor_name, "")) as Marker3D

func set_rope_progress(wrap: float, tighten: float = 0.0) -> void:
	wrap_progress = clampf(wrap, 0.0, 1.0)
	rope_tension = clampf(tighten, 0.0, 1.0)
	if not _built or not has_node("Rope/CordCore"):
		return
	if is_equal_approx(_last_wrap, wrap_progress) and is_equal_approx(_last_tension, rope_tension):
		return
	_last_wrap = wrap_progress
	_last_tension = rope_tension
	var points := _cord_path(rope_tension)
	# Reveal actual successive arc lengths, not a scaling cylinder or a flat stroke.
	var reveal_count: int = maxi(3, int(lerpf(13.0, float(points.size()), wrap_progress)))
	points.resize(mini(reveal_count, points.size()))
	var core := get_node("Rope/CordCore") as MeshInstance3D
	core.mesh = _tube_mesh(points, .012, 7)
	for braid_index in range(3):
		var strand_points := PackedVector3Array()
		for i in range(points.size()):
			var direction := _path_direction(points, i)
			var normal := _path_normal(direction)
			var binormal := direction.cross(normal).normalized()
			var phase := float(i) * 1.72 + TAU * float(braid_index) / 3.0
			strand_points.append(points[i] + (normal * cos(phase) + binormal * sin(phase)) * .0108)
		(get_node("Rope/Braid%d" % braid_index) as MeshInstance3D).mesh = _tube_mesh(strand_points, .0024, 5)
	_rope_tip = points[points.size() - 1]
	(get_node("Rope/FreeEndAnchor") as Marker3D).position = _rope_tip
	var end := get_node("Rope/HeatSealedEnd") as MeshInstance3D
	end.position = _rope_tip
	end.visible = wrap_progress > .98

func set_rod_flex(amount: float) -> void:
	rod_flex = clampf(amount, -1.0, 1.0)
	if not has_node("Rod/Shaft"):
		return
	if is_equal_approx(_last_flex, rod_flex):
		return
	_last_flex = rod_flex
	var points := PackedVector3Array()
	var radii := PackedFloat32Array()
	for i in range(25):
		var t := float(i) / 24.0
		points.append(Vector3(lerpf(SHAFT_START, SHAFT_END, t), _flex_y(t), 0))
		radii.append(lerpf(.043, .020, t))
	(get_node("Rod/Shaft") as MeshInstance3D).mesh = _tube_mesh(points, 1.0, 10, radii)
	(get_node("Rod/TipAnchor") as Marker3D).position = Vector3(SHAFT_END, _flex_y(1.0), 0)
	for name_string in ["TipFerrule", "Guide0", "Guide1", "Guide2", "Binding0", "Binding1", "Binding2"]:
		var part := get_node_or_null("Rod/" + name_string) as Node3D
		if part == null:
			continue
		var t := clampf((part.position.x - SHAFT_START) / (SHAFT_END - SHAFT_START), 0.0, 1.0)
		part.position.y = _flex_y(t)
		part.rotation.z = rod_flex * .19 * t * t
	for i in range(3):
		var grain_node := get_node_or_null("Rod/WoodGrain%d" % i) as MeshInstance3D
		if grain_node == null:
			continue
		var grain := PackedVector3Array()
		for j in range(14):
			var t := float(j) / 13.0
			var x := lerpf(-1.21, .30, t)
			var radius := lerpf(.0435, .022, t)
			var angle := -.50 + float(i) * 1.05 + sin(t * 7.0 + float(i)) * .06
			grain.append(Vector3(x, cos(angle) * radius + _flex_y((x - SHAFT_START) / (SHAFT_END - SHAFT_START)), sin(angle) * radius))
		grain_node.mesh = _tube_mesh(grain, .0017, 4)

func set_hand_grip(side: StringName, amount: float) -> void:
	var hand_name := "LeftHand" if String(side).to_lower() in ["left", "lefthand"] else "RightHand"
	var hand := get_node_or_null(hand_name) as Node3D
	if hand == null:
		return
	var grip := clampf(amount, 0.0, 1.0)
	for finger_index in range(4):
		var finger := hand.get_node("Finger%d" % finger_index) as Node3D
		finger.rotation.x = lerpf(-.08, -1.20 + float(finger_index) * .06, grip)
		(finger.get_node("Middle") as Node3D).rotation.x = lerpf(-.10, -1.30, grip)
		(finger.get_node("Middle/Tip") as Node3D).rotation.x = lerpf(-.08, -.82, grip)
	var thumb := hand.get_node("Thumb") as Node3D
	thumb.rotation.x = lerpf(-.12, -.62, grip)
	(thumb.get_node("Tip") as Node3D).rotation.x = lerpf(-.12, -.85, grip)

func _flex_y(t: float) -> float:
	return .12 * rod_flex * t * t * t

func _build_rod() -> void:
	var rod := _node(self, "Rod")
	var wood := _material("VarnishedWarmBrown", Color("a16b37"), .66)
	var dark_wood := _material("WornDarkGrain", Color("604b32"), .88)
	var grip := _material("CharcoalGrip", Color("292b2a"), .94)
	var grip_rib := _material("WornGripRibs", Color("42463f"), .92)
	var metal := _material("BrushedReelMetal", Color("9aaca6"), .46, .65)
	var dark_metal := _material("ReelGunmetal", Color("465354"), .62, .72)
	var copper := _material("ReelWarmEdge", Color("b2a17c"), .56, .48)
	var spool_gold := _material("SpoolGoldLine", Color("bc9b4f"), .58, .34)
	_mesh(rod, "Shaft", ArrayMesh.new(), wood)
	_cylinder(rod, "GripBody", Vector3(-1.50, 0, 0), .068, .059, .53, grip, Vector3(0, 0, PI / 2), 12)
	_cylinder(rod, "ButtCap", Vector3(-1.782, 0, 0), .069, .069, .034, dark_metal, Vector3(0, 0, PI / 2), 12)
	_cylinder(rod, "ButtMetalLip", Vector3(-1.76, 0, 0), .071, .071, .018, metal, Vector3(0, 0, PI / 2), 12)
	for i in range(14):
		var x := -1.74 + float(i) * .035
		_cylinder(rod, "GripRib%02d" % i, Vector3(x, 0, 0), .070 - float(i) * .0006, .070 - float(i) * .0006, .010, grip_rib, Vector3(0, 0, PI / 2), 12)
	for i in range(3):
		var x := -.84 + float(i) * .53
		var binding := _node(rod, "Binding%d" % i)
		binding.position.x = x
		_cylinder(binding, "ThreadWrap", Vector3.ZERO, .043 - float(i) * .009, .043 - float(i) * .009, .075, dark_wood, Vector3(0, 0, PI / 2), 10)
		for edge_sign in [-1.0, 1.0]:
			_cylinder(binding, "MetalEdge%d" % int(edge_sign), Vector3(edge_sign * .037, 0, 0), .045 - float(i) * .009, .045 - float(i) * .009, .009, copper, Vector3(0, 0, PI / 2), 10)
		var guide := _node(rod, "Guide%d" % i)
		guide.position.x = x
		var guide_radius := .045 - float(i) * .009
		_tube(guide, "Eye", _circle_path(Vector3(0, -.066 + float(i) * .010, 0), guide_radius, guide_radius, "yz", 20), .006, metal, 6)
		_tube(guide, "Foot", PackedVector3Array([Vector3(-.025, -.020, 0), Vector3(-.01, -.063, 0), Vector3(.01, -.063, 0), Vector3(.028, -.020, 0)]), .006, dark_metal, 6)
	var ferrule := _node(rod, "TipFerrule")
	ferrule.position.x = .395
	_cylinder(ferrule, "TipCollar", Vector3.ZERO, .025, .025, .11, metal, Vector3(0, 0, PI / 2), 10)
	# Narrow geometric grain streaks follow the shaft rather than a flat item texture.
	for i in range(3):
		var grain := PackedVector3Array()
		for j in range(14):
			var t := float(j) / 13.0
			var r := lerpf(.0435, .022, t)
			var angle := -.50 + float(i) * 1.05 + sin(t * 7.0 + float(i)) * .06
			grain.append(Vector3(lerpf(-1.21, .30, t), cos(angle) * r, sin(angle) * r))
		_tube(rod, "WoodGrain%d" % i, grain, .0017, dark_wood, 4)
	var reel := _node(rod, "Reel")
	reel.position = Vector3(-1.10, -.155, .012)
	_tube(reel, "SeatFoot", PackedVector3Array([Vector3(-.12, .115, 0), Vector3(.10, .115, 0)]), .019, dark_metal, 8)
	_tube(reel, "BentStem", PackedVector3Array([Vector3(.04, .115, 0), Vector3(.065, .04, 0), Vector3(0, .0, 0)]), .023, metal, 8)
	_cylinder(reel, "SpoolCore", Vector3.ZERO, .077, .077, .102, dark_metal, Vector3(PI / 2, 0, 0), 16)
	_cylinder(reel, "GoldLineBand", Vector3.ZERO, .080, .080, .083, spool_gold, Vector3(PI / 2, 0, 0), 20)
	for side in [-1.0, 1.0]:
		_cylinder(reel, "SpoolFlange%d" % int(side), Vector3(0, 0, side * .056), .103, .103, .019, metal, Vector3(PI / 2, 0, 0), 16)
		_cylinder(reel, "FlangeInset%d" % int(side), Vector3(0, 0, side * .067), .077, .077, .008, dark_metal, Vector3(PI / 2, 0, 0), 16)
	for i in range(7):
		_tube(reel, "WoundLine%d" % i, _circle_path(Vector3(0, 0, -.038 + float(i) * .012), .079, .079, "xy", 24), .0037, copper, 5)
	_cylinder(reel, "Axle", Vector3(0, 0, .09), .018, .018, .058, metal, Vector3(PI / 2, 0, 0), 10)
	_tube(reel, "CrankArm", PackedVector3Array([Vector3(0, 0, .121), Vector3(-.077, -.077, .124), Vector3(-.10, -.080, .146)]), .014, metal, 6)
	_cylinder(reel, "CrankKnob", Vector3(-.10, -.080, .178), .031, .027, .075, grip, Vector3(PI / 2, 0, 0), 10)
	_marker(rod, "TipAnchor", Vector3(.45, 0, 0))
	_marker(rod, "GripAnchor", Vector3(-1.44, 0, 0))
	set_rod_flex(0.0)

func _build_frame() -> void:
	var frame := _node(self, "Frame")
	frame.position = FRAME_REST
	var iron := _material("OxidizedGunmetal", Color("5e696b"), .78, .58)
	var edge := _material("WornMetalEdges", Color("a2aaa6"), .62, .68)
	var rust := _material("OldOxide", Color("6b5842"), .97, .15)
	var mesh_material := _material("WeatheredNetTwine", Color("9b9478"), .97)
	var dark_mesh := _material("NetShadowFibres", Color("756f58"), .98)
	# A missing rim segment and bent cut tips make the broken item recognizable.
	var oval := PackedVector3Array()
	for i in range(81):
		var angle := lerpf(.19, TAU - .11, float(i) / 80.0)
		oval.append(Vector3(cos(angle) * .45, sin(angle * 3.0) * .009, sin(angle) * .34))
	_tube(frame, "BentOvalRim", oval, .025, iron, 8)
	_tube(frame, "SplitRimLipA", PackedVector3Array([oval[0], oval[0] + Vector3(.025, .018, -.013)]), .017, edge, 6)
	_tube(frame, "SplitRimLipB", PackedVector3Array([oval[-1], oval[-1] + Vector3(.022, -.026, .005)]), .018, rust, 6)
	# The socket is hollow. Its distinct inner wall remains visible during alignment.
	var socket_points := PackedVector3Array([Vector3(-.61, 0, 0), Vector3(-.38, 0, 0)])
	_tube(frame, "SocketOuterWall", socket_points, .063, iron, 12)
	var inner := _tube(frame, "SocketInnerWall", socket_points, .046, dark_mesh, 12)
	(inner.material_override as StandardMaterial3D).cull_mode = BaseMaterial3D.CULL_DISABLED
	for x in [-.61, -.39]:
		_tube(frame, "SocketRim%s" % str(x).replace(".", "_"), _circle_path(Vector3(x, 0, 0), .055, .055, "yz", 18), .008, edge, 6)
	_tube(frame, "SocketWeld", PackedVector3Array([Vector3(-.41, .025, -.045), Vector3(-.34, .018, -.075)]), .011, rust, 6)
	_tube(frame, "SocketWeldBack", PackedVector3Array([Vector3(-.41, -.025, .045), Vector3(-.34, -.018, .075)]), .010, iron, 6)
	# True crossed, sagging mesh. Each diagonal remains a separately addressable strand.
	for orientation in range(2):
		for line_index in range(-7, 8):
			var strand := PackedVector3Array()
			var piece := 0
			for step in range(-36, 37):
				var x := float(step) * .015
				var z := x * (.74 if orientation == 0 else -.74) + float(line_index) * .083
				var ellipse := x * x / (.427 * .427) + z * z / (.319 * .319)
				var torn := x > .11 and z > -.115 and z < .07 + (x - .11) * .42
				if ellipse < 1.0 and not torn:
					var sag := -.032 - .16 * pow(maxf(0.0, 1.0 - ellipse), .75)
					strand.append(Vector3(x, sag + (.004 if orientation == 0 else -.004), z))
				elif strand.size() > 1:
					_tube(frame, "Net%d_%02d_%d" % [orientation, line_index + 7, piece], strand, .0040, mesh_material if orientation == 0 else dark_mesh, 5)
					strand = PackedVector3Array()
					piece += 1
				else:
					strand = PackedVector3Array()
			if strand.size() > 1:
				_tube(frame, "Net%d_%02d_%d" % [orientation, line_index + 7, piece], strand, .0040, mesh_material if orientation == 0 else dark_mesh, 5)
	for i in range(7):
		var x := .11 + float(i) * .042
		var z := -.10 + sin(float(i) * 1.9) * .025
		_tube(frame, "TornMeshTail%d" % i, PackedVector3Array([Vector3(x, -.105, z), Vector3(x + .015, -.16, z + .017), Vector3(x + .002, -.196 - float(i % 2) * .028, z + .010)]), .0042, mesh_material, 5)
	# Sparse lashings and irregular oxide patches are geometry with their own depth.
	for i in range(13):
		var angle := .28 + float(i) * .47
		var center := Vector3(cos(angle) * .447, 0, sin(angle) * .338)
		var ring := PackedVector3Array()
		for j in range(13):
			var a := TAU * float(j) / 12.0
			ring.append(center + Vector3(cos(angle) * cos(a) * .029, sin(a) * .029, sin(angle) * cos(a) * .029))
		_tube(frame, "NetLashing%02d" % i, ring, .0045, mesh_material, 5)
		if i % 3 == 0:
			_sphere(frame, "OxidePatch%d" % i, center + Vector3(0, .017, 0), Vector3(.048, .008, .030), rust)
	_marker(frame, "SocketAnchor", Vector3(-.5, 0, 0))
	_marker(frame, "ClaspSeatAnchor", CLASP_SEAT)
	_marker(frame, "GripAnchor", Vector3(cos(.7) * .45, sin(2.1) * .009, sin(.7) * .34))

func _build_rope() -> void:
	var rope := _node(self, "Rope")
	rope.position = ROPE_REST
	var cream := _material("CreamNylonCord", Color("ded7b8"), .92)
	var braid := _material("RaisedNylonBraid", Color("f2e6c6"), .90)
	_mesh(rope, "CordCore", ArrayMesh.new(), cream)
	for i in range(3):
		_mesh(rope, "Braid%d" % i, ArrayMesh.new(), braid if i != 1 else cream)
	_sphere(rope, "HeatSealedEnd", Vector3.ZERO, Vector3(.014, .014, .017), _material("CordEnd", Color("b9ad8a"), .83))
	_marker(rope, "FreeEndAnchor", Vector3.ZERO)

func _cord_path(tension: float) -> PackedVector3Array:
	var points := PackedVector3Array()
	var radius := lerpf(.118, .074, tension)
	for i in range(17):
		var t := float(i) / 16.0
		points.append(Vector3(lerpf(-.35, -.095, t), lerpf(.10, radius, t) + sin(t * PI) * .045 * (1.0 - tension), lerpf(.23, 0.0, t)))
	for i in range(161):
		var t := float(i) / 160.0
		var angle := t * TAU * 3.35
		points.append(Vector3(lerpf(-.095, .083, t), cos(angle) * radius, sin(angle) * radius))
	# An over-under figure-eight finishes in a double crossing above the socket.
	var last := points[-1]
	var knot_scale := lerpf(1.65, 1.0, tension)
	for i in range(73):
		var t := float(i) / 72.0
		var a := t * TAU
		var knot := Vector3(.096 + sin(a) * .051 * knot_scale, .087 + cos(a) * .017 + cos(a * 2.0) * .007, .027 + sin(a * 2.0) * .032 * knot_scale)
		points.append(last.lerp(knot, minf(1.0, t * 14.0)))
	var knot_end := points[-1]
	for i in range(1, 25):
		var t := float(i) / 24.0
		points.append(knot_end.lerp(Vector3(.39, .056, .20), t) + Vector3(0, sin(t * PI) * lerpf(.080, .016, tension), sin(t * PI) * .029))
	return points

func _build_clasp() -> void:
	var clasp := _node(self, "MagneticClasp")
	clasp.position = CLASP_REST
	clasp.rotation = Vector3(0, CLASP_YAW, CLASP_ROLL)
	var red := _material("WornRedEnamel", Color("b94737"), .57, .22)
	var blue := _material("WornBlueEnamel", Color("327aab"), .58, .22)
	var steel := _material("MagnetPoleSteel", Color("c0cac2"), .39, .76)
	var worn_steel := _material("ChippedMagnetSteel", Color("858a81"), .76, .48)
	for side in [-1.0, 1.0]:
		var path := PackedVector3Array([Vector3(side * .10, .034, .016), Vector3(side * .10, .034, .104)])
		for i in range(1, 13):
			var angle := float(i) / 12.0 * PI / 2.0
			path.append(Vector3(side * cos(angle) * .10, .034, .104 + sin(angle) * .10))
		_tube(clasp, "RedHorseshoeHalf" if side < 0 else "BlueHorseshoeHalf", path, .035, red if side < 0 else blue, 8, PI / 8)
		_beveled_box(clasp, "PoleShoe%d" % int(side), Vector3(side * .10, .021, .010), Vector3(.067, .063, .041), .007, steel)
		_tube(clasp, "PoleWear%d" % int(side), PackedVector3Array([Vector3(side * .1 - .021, .069, .034), Vector3(side * .1 + .018, .069, .034)]), .0026, steel, 4)
		for chip_index in range(2):
			var chip := _beveled_box(clasp, "EnamelChip%d_%d" % [int(side), chip_index], Vector3(side * (.10 + .003 * float(chip_index)), .0671, .066 + float(chip_index) * .047), Vector3(.014 - float(chip_index) * .005, .0018, .008), .0008, worn_steel)
			chip.rotation.y = side * .3
	_beveled_box(clasp, "BridgeSleeve", Vector3(0, .034, .203), Vector3(.061, .074, .065), .008, worn_steel)
	_cylinder(clasp, "BridgeRivet", Vector3(0, .076, .203), .016, .017, .012, steel, Vector3.ZERO, 10)
	# A tiny separate steel latch pivots to show the mechanical detent if desired.
	var detent := _node(clasp, "DetentPivot")
	detent.position = Vector3(-.10, .035, .003)
	_cylinder(detent, "HingePin", Vector3.ZERO, .011, .011, .079, steel, Vector3.ZERO, 8)
	_beveled_box(detent, "LatchTongue", Vector3(.026, 0, -.011), Vector3(.060, .016, .025), .004, steel)
	_marker(clasp, "ContactAnchor", Vector3.ZERO)
	_marker(clasp, "GripAnchor", Vector3(0, .034, .204))
	_marker(clasp, "RedPoleContact", Vector3(-.10, -.0105, .010))
	_marker(clasp, "BluePoleContact", Vector3(.10, -.0105, .010))

func _build_hand(hand_name: String, thumb_sign: float) -> void:
	var hand := _node(self, hand_name)
	var skin := _material("WarmTanSkin", Color("bd8f69"), .97)
	var skin_light := _material("KnuckleLight", Color("cca47d"), .96)
	var nail := _material("MutedFingernail", Color("d9bc98"), .93)
	var blue := _material("BlueSleeve", Color("385f84"), .98)
	var blue_light := _material("BlueSleeveSeam", Color("527ca0"), .97)
	var cuff := _material("DarkBlueCuff", Color("2a465d"), .99)
	# Tapered octagonal cross-sections give hands and cloth real bevels without block silhouettes.
	_loft(hand, "Palm", [Vector3(0, 0, -.090), Vector3(0, 0, -.060), Vector3(0, 0, .080), Vector3(0, 0, .120)], [Vector2(.097, .036), Vector2(.112, .047), Vector2(.084, .041), Vector2(.072, .036)], skin)
	_loft(hand, "Wrist", [Vector3(0, 0, .08), Vector3(0, 0, .24)], [Vector2(.072, .035), Vector2(.069, .038)], skin)
	_loft(hand, "Sleeve", [Vector3(0, 0, .21), Vector3(0, 0, .25), Vector3(-.005, -.010, .42), Vector3(.012, -.018, .68)], [Vector2(.090, .058), Vector2(.105, .068), Vector2(.116, .078), Vector2(.128, .090)], blue)
	_loft(hand, "Cuff", [Vector3(0, 0, .198), Vector3(0, 0, .237)], [Vector2(.087, .055), Vector2(.096, .060)], cuff)
	_tube(hand, "SleeveTopSeam", PackedVector3Array([Vector3(.043, .064, .253), Vector3(.044, .071, .42), Vector3(.056, .074, .65)]), .0028, blue_light, 5)
	for i in range(3):
		_tube(hand, "CuffRib%d" % i, PackedVector3Array([Vector3(-.074 + float(i) * .055, .050, .20), Vector3(-.074 + float(i) * .055, .057, .233)]), .0035, blue_light, 5)
	for finger_index in range(4):
		var finger := _node(hand, "Finger%d" % finger_index)
		finger.position = Vector3(-.079 + float(finger_index) * .052, -.004, -.085 + absf(float(finger_index) - 1.5) * .012)
		var length := [.073, .090, .085, .064][finger_index] as float
		_finger_segment(finger, "Proximal", length, .024, skin, skin_light)
		var middle := _node(finger, "Middle")
		middle.position.z = -length
		_finger_segment(middle, "MiddlePhalanx", length * .75, .021, skin, skin_light)
		var tip := _node(middle, "Tip")
		tip.position.z = -length * .75
		_finger_segment(tip, "Distal", length * .66, .019, skin, skin_light)
		_sphere(tip, "Nail", Vector3(0, .018, -length * .41), Vector3(.013, .0025, .017), nail)
	var thumb := _node(hand, "Thumb")
	thumb.position = Vector3(thumb_sign * .083, -.006, .060)
	thumb.rotation.y = -thumb_sign * .92
	_finger_segment(thumb, "ThumbBase", .088, .031, skin, skin_light)
	var thumb_tip := _node(thumb, "Tip")
	thumb_tip.position.z = -.083
	_finger_segment(thumb_tip, "ThumbDistal", .075, .026, skin, skin_light)
	_sphere(thumb_tip, "ThumbNail", Vector3(0, .025, -.040), Vector3(.017, .0027, .023), nail)
	_marker(hand, "GraspAnchor", Vector3(0, -.06, -.07))
	_marker(hand, "GripAnchor", Vector3(0, -.06, -.07))

func _finger_segment(parent: Node3D, name_string: String, length: float, radius: float, skin: Material, knuckle: Material) -> void:
	_loft(parent, name_string, [Vector3.ZERO, Vector3(0, 0, -length * .18), Vector3(0, 0, -length * .80), Vector3(0, 0, -length)], [Vector2(radius * .82, radius * .82), Vector2(radius, radius * .90), Vector2(radius * .88, radius * .84), Vector2(radius * .68, radius * .70)], skin)
	_sphere(parent, name_string + "Knuckle", Vector3(0, 0, -.003), Vector3(radius * .86, radius * .85, radius * .73), knuckle)

func _node(parent: Node, name_string: String) -> Node3D:
	var node := Node3D.new()
	node.name = name_string
	parent.add_child(node)
	node.owner = self
	return node

func _marker(parent: Node, name_string: String, point: Vector3) -> Marker3D:
	var node := Marker3D.new()
	node.name = name_string
	node.position = point
	parent.add_child(node)
	node.owner = self
	return node

func _material(name_string: String, color: Color, roughness: float, metallic: float = 0.0) -> StandardMaterial3D:
	if _materials.has(name_string):
		return _materials[name_string] as StandardMaterial3D
	var material := StandardMaterial3D.new()
	material.resource_name = name_string
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	_materials[name_string] = material
	return material

func _mesh(parent: Node, name_string: String, geometry: Mesh, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = name_string
	instance.mesh = geometry
	instance.material_override = material
	parent.add_child(instance)
	instance.owner = self
	return instance

func _tube(parent: Node, name_string: String, points: PackedVector3Array, radius: float, material: Material, sides: int = 8, phase: float = 0.0) -> MeshInstance3D:
	return _mesh(parent, name_string, _tube_mesh(points, radius, sides, PackedFloat32Array(), phase), material)

func _cylinder(parent: Node, name_string: String, point: Vector3, top_radius: float, bottom_radius: float, height: float, material: Material, angles: Vector3, sides: int) -> MeshInstance3D:
	var geometry := CylinderMesh.new()
	geometry.top_radius = top_radius
	geometry.bottom_radius = bottom_radius
	geometry.height = height
	geometry.radial_segments = sides
	geometry.rings = 1
	var instance := _mesh(parent, name_string, geometry, material)
	instance.position = point
	instance.rotation = angles
	return instance

func _sphere(parent: Node, name_string: String, point: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var geometry := SphereMesh.new()
	geometry.radius = 1.0
	geometry.height = 2.0
	geometry.radial_segments = 10
	geometry.rings = 5
	var instance := _mesh(parent, name_string, geometry, material)
	instance.position = point
	instance.scale = size
	return instance

func _beveled_box(parent: Node, name_string: String, point: Vector3, size: Vector3, bevel: float, material: Material) -> MeshInstance3D:
	var mesh_instance := _loft(parent, name_string, [Vector3(0, 0, -size.z * .5), Vector3(0, 0, -size.z * .5 + bevel), Vector3(0, 0, size.z * .5 - bevel), Vector3(0, 0, size.z * .5)], [Vector2(size.x * .5 - bevel, size.y * .5 - bevel), Vector2(size.x * .5, size.y * .5), Vector2(size.x * .5, size.y * .5), Vector2(size.x * .5 - bevel, size.y * .5 - bevel)], material)
	mesh_instance.position = point
	return mesh_instance

func _loft(parent: Node, name_string: String, centers: Array, widths: Array, material: Material) -> MeshInstance3D:
	var vertices := PackedVector3Array()
	var indices := PackedInt32Array()
	var section := [Vector2(-.72, -1), Vector2(.72, -1), Vector2(1, -.65), Vector2(1, .65), Vector2(.72, 1), Vector2(-.72, 1), Vector2(-1, .65), Vector2(-1, -.65)]
	for i in range(centers.size()):
		for corner: Vector2 in section:
			var width: Vector2 = widths[i]
			vertices.append((centers[i] as Vector3) + Vector3(corner.x * width.x, corner.y * width.y, 0))
	for i in range(centers.size() - 1):
		for j in range(8):
			var a := i * 8 + j
			var b := i * 8 + (j + 1) % 8
			var c := (i + 1) * 8 + j
			var d := (i + 1) * 8 + (j + 1) % 8
			indices.append_array(PackedInt32Array([a, c, b, b, c, d]))
	for i in range(1, 7):
		indices.append_array(PackedInt32Array([0, i, i + 1]))
		var last := (centers.size() - 1) * 8
		indices.append_array(PackedInt32Array([last, last + i + 1, last + i]))
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var reverse: bool = (centers[-1] as Vector3).z < (centers[0] as Vector3).z
	for triangle in range(0, indices.size(), 3):
		var order := [0, 2, 1] if reverse else [0, 1, 2]
		for offset: int in order:
			surface.add_vertex(vertices[indices[triangle + offset]])
	surface.generate_normals()
	return _mesh(parent, name_string, surface.commit(), material)

func _tube_mesh(points: PackedVector3Array, radius: float, sides: int = 8, radii: PackedFloat32Array = PackedFloat32Array(), phase: float = 0.0) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	if points.size() < 2:
		return mesh
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	for i in range(points.size()):
		var direction := _path_direction(points, i)
		var normal := _path_normal(direction)
		var binormal := direction.cross(normal).normalized()
		var r := radius if radii.is_empty() else radii[i]
		for side in range(sides):
			var angle := TAU * float(side) / float(sides) + phase
			var radial := normal * cos(angle) + binormal * sin(angle)
			vertices.append(points[i] + radial * r)
			normals.append(radial)
	for i in range(points.size() - 1):
		for side in range(sides):
			var a := i * sides + side
			var b := i * sides + (side + 1) % sides
			var c := (i + 1) * sides + side
			var d := (i + 1) * sides + (side + 1) % sides
			indices.append_array(PackedInt32Array([a, c, b, b, c, d]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func _path_direction(points: PackedVector3Array, index: int) -> Vector3:
	var delta := points[mini(index + 1, points.size() - 1)] - points[maxi(index - 1, 0)]
	return delta.normalized() if delta.length_squared() > .00000001 else Vector3.RIGHT

func _path_normal(direction: Vector3) -> Vector3:
	return direction.cross(Vector3.UP if absf(direction.dot(Vector3.UP)) < .94 else Vector3.FORWARD).normalized()

func _circle_path(center: Vector3, radius_a: float, radius_b: float, plane: String, segments: int) -> PackedVector3Array:
	var points := PackedVector3Array()
	for i in range(segments + 1):
		var angle := TAU * float(i) / float(segments)
		var a := cos(angle) * radius_a
		var b := sin(angle) * radius_b
		points.append(center + (Vector3(a, b, 0) if plane == "xy" else Vector3(0, a, b)))
	return points
