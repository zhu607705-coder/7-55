extends Node3D
## Original miniature brush, in chest source pixels. The shaped handle, folded
## ferrule and splayed bristle bundles share the project's material ramps.
const OUTLINE = [Vector3(-73,12,-5),Vector3(-57,12,-11),Vector3(-38,12,-10),Vector3(4,12,-6),Vector3(17,12,-17),Vector3(35,12,-17),Vector3(65,12,-21),Vector3(72,12,-7),Vector3(72,12,7),Vector3(65,12,21),Vector3(35,12,17),Vector3(17,12,17),Vector3(4,12,6),Vector3(-38,12,10),Vector3(-57,12,11),Vector3(-73,12,5)]

func _ready() -> void:
	var wood:=_material("70503b")
	var wood_light:=_material("a1744e")
	var wood_dark:=_material("44332d")
	var steel:=_material("526b7a",.48,.67)
	var steel_edge:=_material("7993a1",.35,.71)
	var steel_dark:=_material("344452",.35,.82)
	var hair:=_material("766e63")
	var hair_light:=_material("a39b87")
	var powder:=_material("a9b577")
	var powder_dark:=_material("72865c")
	_piece("ShapedWoodHandle",_profile([
		Vector3(-73,2,3),Vector3(-69,5,7),Vector3(-57,6,10),Vector3(-42,6,9),
		Vector3(-21,5,7),Vector3(3,4.5,5.5),Vector3(12,5,9),Vector3(21,5.5,15)
	]),wood,Vector3(0,8,0))
	# Long, tapered grain groups describe the handle; no scattered texture dots.
	_strip("HandleGrain",[Vector3(-64,13,-3),Vector3(-38,14,-3),Vector3(-5,12.5,-1),Vector3(-37,14,-1.5)],wood_light)
	_strip("HandleLowerGrain",[Vector3(-56,13.5,3),Vector3(-33,13.5,4),Vector3(-16,12.5,3),Vector3(-39,14,2.5)],wood_dark)
	var hole:=CylinderMesh.new();hole.top_radius=2.3;hole.bottom_radius=2.3;hole.height=.3;hole.radial_segments=12
	_piece("HandleHangingHole",hole,wood_dark,Vector3(-62,14.1,0))
	var rim:=TorusMesh.new();rim.inner_radius=2.5;rim.outer_radius=3.5;rim.rings=16;rim.ring_segments=6
	_piece("WornHoleEdge",rim,wood_light,Vector3(-62,14,0))
	_piece("FoldedMetalFerrule",_profile([Vector3(16,5.5,14),Vector3(18,7.5,17),Vector3(33,7.5,17),Vector3(35,6,16)]),steel,Vector3(0,8,0))
	_piece("FerruleRearFold",_profile([Vector3(16,6,14.5),Vector3(18,8,17.5),Vector3(20,8,17.5)]),steel_dark,Vector3(0,8,0))
	_piece("FerruleFrontLip",_profile([Vector3(32,8,17.6),Vector3(34,8,17.6),Vector3(35,6,16)]),steel_edge,Vector3(0,8,0))
	_strip("FerruleHighlight",[Vector3(21,15.6,-5),Vector3(31,15.6,-5),Vector3(31,15.6,-3.5),Vector3(21,15.6,-3.5)],steel_edge)
	for z: float in [-10,10]:
		var rivet:=SphereMesh.new();rivet.radius=1.45;rivet.height=1.3;rivet.radial_segments=8;rivet.rings=4
		_piece("FerruleRivet",rivet,steel_dark,Vector3(26,14,z))
	# Nine broad, individually splayed tufts make a curved, imperfect edge.
	# The matte powder occupies the tips; the natural hair remains visible.
	_piece("DenseBristleUnderlay",_profile([Vector3(34,4.2,14.5),Vector3(49,4.2,18),Vector3(65,2,18)],0,true),hair,Vector3(0,7,0))
	for index: int in range(9):
		var side:=float(index-4)
		var length:=36.0-absf(side)*1.15-float(index%3)
		var spread:=side*1.0
		var at:=Vector3(34,11,side*3.45)
		var body:=_profile([Vector3(0,.8,1.9),Vector3(18,.9,2.2),Vector3(length,.5,1.8)],spread,true)
		_piece("BristleBundle%d"%index,body,hair_light if index in [2,5] else hair,at)
		var tip_length:=6.0+float(index%3)
		var tips:=_profile([Vector3(length-tip_length,.9,1.8),Vector3(length+.25,.55,1.7)],spread*tip_length/length,true)
		_piece("PowderedTip%d"%index,tips,powder_dark if index in [0,8] else powder,at+Vector3(0,.3,spread*(length-tip_length)/length))

func _material(hex: String, metal:=0.0, roughness:=.95) -> StandardMaterial3D:
	var material:=StandardMaterial3D.new()
	material.albedo_color=Color(hex);material.metallic=metal;material.roughness=roughness
	material.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST
	return material

func _piece(label: String, mesh: Mesh, material: Material, at: Vector3) -> MeshInstance3D:
	var node:=MeshInstance3D.new();node.name=label;node.mesh=mesh;node.material_override=material;node.position=at
	add_child(node);return node

func _strip(label: String, points: Array[Vector3], material: Material) -> void:
	var builder:=SurfaceTool.new();builder.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index: int in range(1,points.size()-1):
		for point: Vector3 in [points[0],points[index+1],points[index]]:builder.add_vertex(point)
	builder.generate_normals();_piece(label,builder.commit(),material,Vector3.ZERO)

func _profile(sections: Array[Vector3], spread:=0.0, flat_top:=false) -> ArrayMesh:
	# Each section is (length position, half height, half width), with eight
	# chamfered sides. The optional spread fans a tuft without stretching it.
	var builder:=SurfaceTool.new();builder.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings: Array[PackedVector3Array]=[]
	for section: Vector3 in sections:
		var ring:=PackedVector3Array()
		var offset:=spread*(section.x-sections[0].x)/(sections[-1].x-sections[0].x)
		for index: int in range(8):
			var angle:=float(index)*TAU/8
			var cross_section:=Vector2(sin(angle),cos(angle))
			if flat_top:cross_section=[Vector2(.65,1),Vector2(1,.78),Vector2(1,-.78),Vector2(.65,-1),Vector2(-.65,-1),Vector2(-1,-.78),Vector2(-1,.78),Vector2(-.65,1)][index]
			ring.append(Vector3(section.x,cross_section.x*section.y,cross_section.y*section.z+offset))
		rings.append(ring)
	for level: int in range(rings.size()-1):
		for index: int in range(8):
			var next: int=(index+1)%8
			for point: Vector3 in [rings[level][index],rings[level+1][next],rings[level+1][index],rings[level][index],rings[level][next],rings[level+1][next]]:builder.add_vertex(point)
	for index: int in range(1,7):
		for point: Vector3 in [rings[0][0],rings[0][index],rings[0][index+1],rings[-1][0],rings[-1][index+1],rings[-1][index]]:builder.add_vertex(point)
	builder.generate_normals();return builder.commit()
