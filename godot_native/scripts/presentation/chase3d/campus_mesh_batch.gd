extends RefCounted
## Static geometry is merged by palette material, rather than one draw per brick.
var surfaces: Dictionary={}
var materials: Dictionary={}
var triangle_count: int=0

func _surface(color: String) -> SurfaceTool:
	if not surfaces.has(color):
		var tool:=SurfaceTool.new();tool.begin(Mesh.PRIMITIVE_TRIANGLES);surfaces[color]=tool
	return surfaces[color]

func triangle(color: String,a: Vector3,b: Vector3,c: Vector3,normal: Vector3) -> void:
	var tool: SurfaceTool=_surface(color)
	for point: Vector3 in [a,c,b]:
		tool.set_normal(normal);tool.add_vertex(point)
	triangle_count+=1

func quad(color: String,a: Vector3,b: Vector3,c: Vector3,d: Vector3,normal: Vector3) -> void:
	triangle(color,a,b,c,normal);triangle(color,a,c,d,normal)

func box(color: String,center: Vector3,dimensions: Vector3,basis: Basis=Basis.IDENTITY) -> void:
	var h: Vector3=dimensions*.5
	var faces: Array=[
		[Vector3(-h.x,h.y,-h.z),Vector3(-h.x,h.y,h.z),Vector3(h.x,h.y,h.z),Vector3(h.x,h.y,-h.z),Vector3.UP],
		[Vector3(-h.x,-h.y,h.z),Vector3(-h.x,-h.y,-h.z),Vector3(h.x,-h.y,-h.z),Vector3(h.x,-h.y,h.z),Vector3.DOWN],
		[Vector3(-h.x,-h.y,h.z),Vector3(h.x,-h.y,h.z),Vector3(h.x,h.y,h.z),Vector3(-h.x,h.y,h.z),Vector3.BACK],
		[Vector3(h.x,-h.y,-h.z),Vector3(-h.x,-h.y,-h.z),Vector3(-h.x,h.y,-h.z),Vector3(h.x,h.y,-h.z),Vector3.FORWARD],
		[Vector3(h.x,-h.y,h.z),Vector3(h.x,-h.y,-h.z),Vector3(h.x,h.y,-h.z),Vector3(h.x,h.y,h.z),Vector3.RIGHT],
		[Vector3(-h.x,-h.y,-h.z),Vector3(-h.x,-h.y,h.z),Vector3(-h.x,h.y,h.z),Vector3(-h.x,h.y,-h.z),Vector3.LEFT]
	]
	for face: Array in faces:quad(color,center+basis*face[0],center+basis*face[1],center+basis*face[2],center+basis*face[3],basis*face[4])

func pole(color: String,start: Vector3,end: Vector3,radius: float,top_radius: float=-1,segments: int=8) -> void:
	var axis: Vector3=(end-start).normalized()
	var tangent: Vector3=axis.cross(Vector3.RIGHT if absf(axis.x)<.9 else Vector3.UP).normalized()
	var other: Vector3=axis.cross(tangent)
	var r: float=radius if top_radius<0 else top_radius
	for i: int in range(segments):
		var a: float=TAU*i/segments;var b: float=TAU*(i+1)/segments
		var u: Vector3=tangent*cos(a)+other*sin(a);var v: Vector3=tangent*cos(b)+other*sin(b)
		quad(color,start+u*radius,start+v*radius,end+v*r,end+u*r,(u+v).normalized())
		triangle(color,end,end+u*r,end+v*r,axis)

func foliage(center: Vector3,radius: Vector3,seed: int,colors: Array[String]) -> void:
	# Small faceted clusters describe a crown; no billboard spheres or random noise.
	for ring: int in range(3):
		var y0: float=-PI*.5+PI*ring/3;var y1: float=-PI*.5+PI*(ring+1)/3
		for side: int in range(8):
			var a: float=TAU*side/8;var b: float=TAU*(side+1)/8
			var p: Array[Vector3]=[]
			for angles: Vector2 in [Vector2(a,y0),Vector2(b,y0),Vector2(b,y1),Vector2(a,y1)]:
				p.append(center+Vector3(cos(angles.x)*cos(angles.y),sin(angles.y),sin(angles.x)*cos(angles.y))*radius)
			var normal: Vector3=((p[0]+p[1]+p[2]+p[3])*.25-center).normalized()
			quad(colors[posmod(seed+side+ring,colors.size())],p[0],p[1],p[2],p[3],normal)

func finish(label: String) -> Node3D:
	var root:=Node3D.new();root.name=label
	for color: String in surfaces:
		var material: StandardMaterial3D=materials.get(color)
		if material==null:
			material=StandardMaterial3D.new();material.albedo_color=Color(color);material.roughness=.94
			materials[color]=material
		var tool: SurfaceTool=surfaces[color];tool.set_material(material)
		var mesh:=MeshInstance3D.new();mesh.name="Palette_"+color;mesh.mesh=tool.commit();root.add_child(mesh)
	root.set_meta("triangles",triangle_count);root.set_meta("palette_surfaces",surfaces.size())
	return root
