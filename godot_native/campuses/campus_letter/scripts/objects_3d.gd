extends RefCounted
## Independent scene objects. Geometry never owns sample progression.
const FONT = preload("res://ui_assets/fonts/SelectedCoverage-Regular.otf")
const CHAIR = preload("res://campuses/campus_letter/assets3d/detail/reading_chair.glb")
const TABLE = preload("res://campuses/campus_letter/assets3d/detail/worktable.glb")
const DESK = preload("res://campuses/campus_letter/assets3d/detail/study_desk.glb")
const SUPPORT = preload("res://campuses/campus_letter/assets3d/detail/bridge_support.glb")
const WEIGHT = preload("res://campuses/campus_letter/assets3d/detail/calibration_weight.glb")
const LAMP = preload("res://campuses/campus_letter/assets3d/detail/projection_lamp.glb")
const WHEEL = preload("res://campuses/campus_letter/assets3d/detail/survey_wheel.glb")
const HANDS = preload("res://campuses/campus_letter/assets3d/detail/sculpture_hands.glb")
const READING_LAMP = preload("res://campuses/campus_letter/assets3d/detail/reading_lamp.glb")
const BENCH = preload("res://campuses/campus_letter/assets3d/detail/campus_bench.glb")
const BOOK = preload("res://campuses/campus_letter/assets3d/detail/reading_book.glb")
const WOOD = preload("res://campuses/campus_letter/assets3d/pbr/Wood051_1K-JPG_Color.jpg")
const WOOD_NORMAL = preload("res://campuses/campus_letter/assets3d/pbr/Wood051_1K-JPG_NormalGL.jpg")
const WOOD_ROUGH = preload("res://campuses/campus_letter/assets3d/pbr/Wood051_1K-JPG_Roughness.jpg")
const STONE = preload("res://campuses/campus_letter/assets3d/pbr/Concrete034_1K-JPG_Color.jpg")
const STONE_NORMAL = preload("res://campuses/campus_letter/assets3d/pbr/Concrete034_1K-JPG_NormalGL.jpg")
const STONE_ROUGH = preload("res://campuses/campus_letter/assets3d/pbr/Concrete034_1K-JPG_Roughness.jpg")
const METAL_NORMAL = preload("res://campuses/campus_letter/assets3d/pbr/Metal032_1K-JPG_NormalGL.jpg")
const METAL_ROUGH = preload("res://campuses/campus_letter/assets3d/pbr/Metal032_1K-JPG_Roughness.jpg")
const FABRIC_NORMAL = preload("res://campuses/campus_letter/assets3d/pbr/Fabric041_1K-JPG_NormalGL.jpg")
const FABRIC_ROUGH = preload("res://campuses/campus_letter/assets3d/pbr/Fabric041_1K-JPG_Roughness.jpg")
const WILLOW = preload("res://assets/native_755/ride/rodin/campus_willow_verge.glb")
const CANOPY = preload("res://assets/native_755/ride/rodin/campus_glass_canopy.glb")
const LETTER_BOX = preload("res://campuses/campus_letter/assets3d/detail/letter_box.glb")
static var shared_materials: Dictionary = {}

static func pbr(kind: String) -> StandardMaterial3D:
	if shared_materials.has(kind): return shared_materials[kind]
	var m := StandardMaterial3D.new()
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	m.uv1_triplanar = true
	m.uv1_triplanar_sharpness = 6.0
	m.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	m.normal_enabled = true
	match kind:
		"wood":
			m.albedo_texture=WOOD;m.normal_texture=WOOD_NORMAL;m.roughness_texture=WOOD_ROUGH;m.roughness=.82;m.normal_scale=.20;m.uv1_scale=Vector3(1.15,1.15,1.15)
		"stone":
			m.albedo_color=Color("dddcd7");m.albedo_texture=STONE;m.normal_texture=STONE_NORMAL;m.roughness_texture=STONE_ROUGH;m.roughness=.85;m.normal_scale=.45;m.uv1_scale=Vector3(.85,.85,.85)
		"plaster":
			m.albedo_color=Color("dfdcd4");m.normal_texture=STONE_NORMAL;m.roughness_texture=STONE_ROUGH;m.roughness=.9;m.normal_scale=.18;m.uv1_scale=Vector3(1.4,1.4,1.4)
		"fabric":
			m.albedo_color=Color("56655c");m.normal_texture=FABRIC_NORMAL;m.roughness_texture=FABRIC_ROUGH;m.roughness=.95;m.normal_scale=.28;m.uv1_scale=Vector3(2,2,2)
		"steel", "bronze", "enamel":
			m.albedo_color=Color("bec5c9" if kind=="steel" else ("af8956" if kind=="bronze" else "283b3f"))
			m.metallic=.9 if kind!="enamel" else .3
			m.roughness=.32 if kind=="steel" else (.42 if kind=="bronze" else .65)
			m.normal_texture=METAL_NORMAL;m.normal_scale=.08;m.uv1_scale=Vector3(4,4,4)
			m.roughness_texture=METAL_ROUGH
	shared_materials[kind]=m
	return m

static func material(color: String, metallic: float = 0.0, roughness: float = 0.68) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(color); m.metallic = metallic; m.roughness = roughness
	if color in ["b58a61","ab7650","795f4a"]:
		return pbr("wood")
	if color in ["e6e0cc","c1c0b4"]: return pbr("plaster")
	if color in ["b5b3a4","c1bbab","aeb0a4","b9b6a7","d1c9b6"]: return pbr("stone")
	if color in ["234950","34484a"]: return pbr("enamel")
	if color=="b8c5c5": return pbr("steel")
	if color=="b68c48": return pbr("bronze")
	return m

static func mesh(parent: Node3D, name_: String, geometry: Mesh, pos: Vector3, mat: Material) -> MeshInstance3D:
	var n := MeshInstance3D.new(); n.name = name_; n.mesh = geometry; n.material_override = mat
	parent.add_child(n); n.position = pos
	return n

static func box(parent: Node3D, name_: String, pos: Vector3, size_: Vector3, mat: Material) -> MeshInstance3D:
	var b := BoxMesh.new(); b.size = size_
	var n:=mesh(parent, name_, b, pos, mat)
	if (size_.x>1.0 and size_.z>1.0) or size_.y>.5:
		var body:=StaticBody3D.new();body.name="Solid";n.add_child(body)
		var shape:=CollisionShape3D.new();var volume:=BoxShape3D.new();volume.size=size_;shape.shape=volume;body.add_child(shape)
	return n

static func ball(parent: Node3D, name_: String, pos: Vector3, radius: float, mat: Material) -> MeshInstance3D:
	var s := SphereMesh.new(); s.radius = radius; s.height = radius * 2.0; s.radial_segments = 64; s.rings = 32
	return mesh(parent, name_, s, pos, mat)

static func cylinder(parent: Node3D, name_: String, pos: Vector3, radius: float, height: float, mat: Material) -> MeshInstance3D:
	var c := CylinderMesh.new(); c.top_radius = radius; c.bottom_radius = radius; c.height = height; c.radial_segments = 80
	return mesh(parent, name_, c, pos, mat)

static func rod(parent: Node3D, name_: String, a: Vector3, b: Vector3, radius: float, mat: Material) -> MeshInstance3D:
	var n := cylinder(parent, name_, (a+b)/2.0, radius, a.distance_to(b), mat)
	n.quaternion = Quaternion(Vector3.UP, (b-a).normalized())
	return n

static func ring(parent: Node3D, name_: String, pos: Vector3, radius: float, thickness: float, mat: Material) -> MeshInstance3D:
	var t := TorusMesh.new(); t.inner_radius = radius-thickness; t.outer_radius = radius+thickness; t.rings=80; t.ring_segments=20
	return mesh(parent, name_, t, pos, mat)

static func node(parent: Node3D, name_: String, pos: Vector3 = Vector3.ZERO) -> Node3D:
	var n := Node3D.new(); n.name = name_; parent.add_child(n); n.position = pos; return n

static func pick(parent: Node3D, id: String, center: Vector3, extent: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new(); body.name = "Pick_"+id; body.set_meta("action", id); body.collision_layer = 2; body.collision_mask = 0
	parent.add_child(body); body.position = center
	var collision := CollisionShape3D.new(); var shape := BoxShape3D.new(); shape.size=extent; collision.shape=shape; body.add_child(collision)
	return body

static func label(parent: Node3D, name_: String, _words: String, pos: Vector3, _size: int=42, _color: String="243b40") -> Node3D:
	# Spatial anchors only. The user's brief prohibits text on scene objects.
	return node(parent,name_,pos)

static func imported(parent: Node3D, name_: String, asset: PackedScene, pos: Vector3, scale_: float = 1.0, yaw: float=0) -> Node3D:
	var n:=asset.instantiate() as Node3D; n.name=name_; parent.add_child(n); n.position=pos; n.scale=Vector3.ONE*scale_; n.rotation.y=yaw
	for child in n.find_children("*", "MeshInstance3D", true, false):
		for surface in range(child.mesh.get_surface_count()):
			var source:Material=child.mesh.surface_get_material(surface)
			if source==null:continue
			var kind:String=""
			if "ash" in source.resource_name:kind="wood"
			elif "stainless" in source.resource_name:kind="steel"
			elif "bronze" in source.resource_name:kind="bronze"
			elif "enamel" in source.resource_name:kind="enamel"
			elif "fabric" in source.resource_name:kind="fabric"
			if not kind.is_empty():child.set_surface_override_material(surface,pbr(kind))
	return n


static func bench(parent: Node3D, pos: Vector3, yaw: float = 0.0) -> Node3D:
	return imported(parent,"CampusBench",BENCH,pos,1.0,yaw)

static func envelope(parent: Node3D, pos: Vector3) -> Node3D:
	var n:=node(parent,"Letter",pos); var paper:=material("f3e8c9");var ink:=material("a57540")
	box(n,"PaperEnvelope",Vector3.ZERO,Vector3(.46,.028,.3),paper)
	rod(n,"FlapLeft",Vector3(-.23,.017,-.15),Vector3(0,.017,.05),.0035,ink)
	rod(n,"FlapRight",Vector3(.23,.017,-.15),Vector3(0,.017,.05),.0035,ink)
	return n

static func lamp(parent: Node3D, pos: Vector3) -> Node3D:
	return imported(parent,"RailLamp",LAMP,pos)
