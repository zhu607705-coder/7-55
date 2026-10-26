extends Node3D
## Both current and recorded worlds use independent meshes, materials and lights.
## The marks are depressed vertices with finite-difference normals, not ink/shader reveal.
const ELEVATION := deg_to_rad(50.0)
const YAW := deg_to_rad(8.0)
const PAPER_SIZE := Vector2(3.35,2.40)
const PAPER_CENTER := Vector3(-0.30,0.53,0.30)
const GROOVE_WIDTH := 0.033
const GROOVE_DEPTH := 0.018
const PATH := [Vector2(-0.98,0.65),Vector2(-0.98,-0.45),Vector2(-0.40,-0.87),Vector2(0.22,-0.45),Vector2(0.22,0.65),Vector2(-0.98,0.65),Vector2(-0.39,0.65),Vector2(-0.39,0.16),Vector2(0.83,0.16),Vector2(0.83,-0.30),Vector2(1.14,-0.30)]
var camera: Camera3D
var paper_pivot: Node3D
var paper: MeshInstance3D
var lamp: SpotLight3D
var lamp_head: Node3D
var lamp_base: MeshInstance3D
var lamp_arm: MeshInstance3D
var door_hinge: Node3D
var pins: Array[MeshInstance3D]=[]
var is_recorded := false
var env: Environment
var lamp_material: StandardMaterial3D
var groove_probes: Array[Dictionary]=[]

static func groove_height(p: Vector2) -> float:
	var d := 10.0
	for i: int in range(PATH.size()-1):
		var a: Vector2=PATH[i]; var b: Vector2=PATH[i+1]
		var q := a+(b-a)*clampf((p-a).dot(b-a)/(b-a).length_squared(),0,1)
		d=minf(d,p.distance_to(q))
	# A small ring is the destination symbol; it is a prototype, not a real room map.
	d=minf(d,absf(p.distance_to(Vector2(1.12,-0.30))-0.13))
	return -GROOVE_DEPTH*exp(-pow(d/GROOVE_WIDTH,2.0))

static func surface_normal(p: Vector2) -> Vector3:
	const H := 0.002
	return Vector3(-(groove_height(p+Vector2(H,0))-groove_height(p-Vector2(H,0)))/(2*H),1,-(groove_height(p+Vector2(0,H))-groove_height(p-Vector2(0,H)))/(2*H)).normalized()

func setup(recorded: bool=false) -> void:
	is_recorded=recorded
	var environment := WorldEnvironment.new(); env=Environment.new()
	env.background_mode=Environment.BG_COLOR; env.background_color=Color("263633")
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color=Color("bfcdc6"); env.ambient_light_energy=0.23
	env.tonemap_mode=Environment.TONE_MAPPER_LINEAR
	environment.environment=env; add_child(environment)
	camera=Camera3D.new(); camera.projection=Camera3D.PROJECTION_ORTHOGONAL; camera.current=true
	camera.near=0.05; camera.far=60; add_child(camera)
	var fill := DirectionalLight3D.new(); fill.rotation_degrees=Vector3(-80,-25,0); fill.light_energy=0.34; fill.light_color=Color("c9d9de"); add_child(fill)
	_build_room()
	paper_pivot=Node3D.new(); paper_pivot.position=PAPER_CENTER; add_child(paper_pivot)
	paper=MeshInstance3D.new(); paper.name="DepressedPaperSurface"; paper.mesh=_paper_mesh(); paper.material_override=material(Color("e8dfc5"),0.93)
	paper_pivot.add_child(paper)
	var back := box("PaperUnderside",Vector3(0,-0.028,0),Vector3(PAPER_SIZE.x,0.018,PAPER_SIZE.y),material(Color("c8bca4")),paper_pivot)
	back.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Two visible brass edge tabs are handles, not buttons that solve the puzzle.
	for x: float in [-1.51,1.51]: box("PaperEdgeGrip",Vector3(x,0.012,0.83),Vector3(0.22,0.025,0.42),material(Color("b7985c"),0.55),paper_pivot)
	lamp_material=material(Color("526c62"),0.43)
	lamp_base=box("MovableLampBase",Vector3.ZERO,Vector3(0.52,0.10,0.48),lamp_material)
	lamp_arm=box("LampArm",Vector3.ZERO,Vector3(0.07,1,0.07),material(Color("afae97"),0.4))
	lamp_head=Node3D.new(); lamp_head.name="LampShadeGrip"; add_child(lamp_head)
	var shade := MeshInstance3D.new(); var cone := CylinderMesh.new(); cone.top_radius=0.14; cone.bottom_radius=0.31; cone.height=0.30
	shade.mesh=cone; shade.material_override=lamp_material; shade.rotation.x=PI*0.5; lamp_head.add_child(shade)
	var bulb := material(Color("fff2c2")); bulb.emission_enabled=true; bulb.emission=Color("ffe4a2")*1.2
	box("VisibleBulb",Vector3(0,0,-0.155),Vector3(0.28,0.14,0.03),bulb,lamp_head)
	lamp=SpotLight3D.new(); lamp.name="ActualRakingLamp"; lamp.light_color=Color("ffe8b7"); lamp.light_energy=5.2
	lamp.spot_range=7.0; lamp.spot_angle=51.0; lamp.spot_attenuation=0.35; lamp.spot_angle_attenuation=0.4
	lamp.shadow_enabled=true; lamp.shadow_bias=0.015; lamp.shadow_normal_bias=0.035
	lamp.position=Vector3(0,0,-0.22); lamp_head.add_child(lamp)
	for i: int in range(PATH.size()-1):
		var a: Vector2=PATH[i]; var b: Vector2=PATH[i+1]; var tangent: Vector2=(b-a).normalized()
		groove_probes.append({"p":(a+b)*0.5,"side":Vector2(-tangent.y,tangent.x)*GROOVE_WIDTH*0.75})

func material(color: Color, roughness: float=0.85) -> StandardMaterial3D:
	var m := StandardMaterial3D.new(); m.albedo_color=color; m.roughness=roughness
	return m

func box(label: String, center: Vector3, dimensions: Vector3, m: Material, parent: Node3D=null) -> MeshInstance3D:
	var node := MeshInstance3D.new(); var mesh := BoxMesh.new(); mesh.size=dimensions
	node.name=label; node.mesh=mesh; node.material_override=m; node.position=center
	(parent if parent else self).add_child(node); return node

func _build_room() -> void:
	var wood := material(Color("72634c")); var steel := material(Color("344740")); var wall := material(Color("849184"))
	box("ClassroomFloor",Vector3(0,-1.70,0),Vector3(16,0.2,16),material(Color("515c51")))
	box("DeskTop",Vector3(0,-0.08,0.15),Vector3(5.8,0.16,4.9),wood)
	box("FrontApron",Vector3(0,-0.38,2.48),Vector3(5.7,0.45,0.10),material(Color("524c3e")))
	for x: float in [-2.5,2.5]:
		for z: float in [-1.7,2.2]: box("DeskLeg",Vector3(x,-0.89,z),Vector3(0.12,1.65,0.12),steel)
	box("PaperCradle",Vector3(-0.30,0.21,0.30),Vector3(3.75,0.18,2.75),material(Color("354b44")))
	box("BackWall",Vector3(-1,1.0,-3.8),Vector3(7,5.5,0.18),wall)
	box("Blackboard",Vector3(-1.55,1.65,-3.66),Vector3(3.85,1.65,0.08),material(Color("25443d")))
	box("ChalkRail",Vector3(-1.55,0.77,-3.52),Vector3(4.0,0.10,0.20),wood)
	for i: int in range(3): box("Chalk",Vector3(-2.5+i*0.30,0.84,-3.51),Vector3(0.18,0.04,0.04),material(Color("dad8b8")))
	# A physical local preview hatch opens after sustained observation; no router call.
	box("PreviewFrameLeft",Vector3(2.07,1.12,-3.65),Vector3(0.12,2.0,0.22),wood)
	box("PreviewFrameRight",Vector3(3.18,1.12,-3.65),Vector3(0.12,2.0,0.22),wood)
	box("PreviewFrameTop",Vector3(2.62,2.1,-3.65),Vector3(1.22,0.12,0.22),wood)
	box("UnvisitedPreview",Vector3(2.62,1.12,-3.70),Vector3(1.02,1.90,0.05),material(Color("b2b89a")))
	door_hinge=Node3D.new(); door_hinge.position=Vector3(2.12,1.12,-3.48); add_child(door_hinge)
	box("LocalPreviewDoor",Vector3(0.50,0,0),Vector3(1,1.86,0.11),material(Color("425e52")),door_hinge)
	box("PreviewHandle",Vector3(0.86,-0.13,0.11),Vector3(0.06,0.19,0.05),material(Color("c1ab72")),door_hinge)
	# A strip of paper tabs rises gradually, giving a diegetic stability cue.
	for i: int in range(3): pins.append(box("ObservationTab",Vector3(1.68,0.16,0.65-i*0.38),Vector3(0.13,0.04,0.25),material(Color("c1b18a"))))
	box("StoolSeat",Vector3(-2.0,-0.75,3.30),Vector3(1.2,0.14,0.65),wood)

func _paper_mesh() -> ArrayMesh:
	const NX := 160
	const NZ := 120
	var v := PackedVector3Array(); var n := PackedVector3Array(); var index := PackedInt32Array()
	for j: int in range(NZ+1):
		for i: int in range(NX+1):
			var p := Vector2((float(i)/NX-0.5)*PAPER_SIZE.x,(float(j)/NZ-0.5)*PAPER_SIZE.y)
			v.append(Vector3(p.x,groove_height(p),p.y)); n.append(surface_normal(p))
	for j: int in range(NZ):
		for i: int in range(NX):
			var a := j*(NX+1)+i; var b := a+1; var c := a+NX+1; var d := c+1
			index.append_array(PackedInt32Array([a,b,c,b,d,c]))
	var arrays := []; arrays.resize(Mesh.ARRAY_MAX); arrays[Mesh.ARRAY_VERTEX]=v; arrays[Mesh.ARRAY_NORMAL]=n; arrays[Mesh.ARRAY_INDEX]=index
	var mesh := ArrayMesh.new(); mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays); return mesh

func configure_camera(viewport_size: Vector2, history: bool=false) -> void:
	var right := Vector3(cos(YAW),0,-sin(YAW))
	var up := Vector3(-sin(ELEVATION)*sin(YAW),cos(ELEVATION),-sin(ELEVATION)*cos(YAW))
	var back := right.cross(up)
	camera.transform=Transform3D(Basis(right,up,back),Vector3(0,0.45,-0.15)+back*22)
	camera.size=maxf(5.0,6.7*viewport_size.y/maxf(viewport_size.x,1))
	if history: camera.size=3.3

func update_scene(tilt: Vector2, azimuth: float, elevation: float, progress: float, complete: bool, delta: float=0.0) -> void:
	paper_pivot.basis=Basis(Vector3.RIGHT,deg_to_rad(tilt.x))*Basis(Vector3.FORWARD,deg_to_rad(tilt.y))
	var az := deg_to_rad(azimuth); var el := deg_to_rad(elevation)
	var lowest := 0.0
	for x: float in [-PAPER_SIZE.x*0.5,PAPER_SIZE.x*0.5]:
		for z: float in [-PAPER_SIZE.y*0.5,PAPER_SIZE.y*0.5]: lowest=minf(lowest,(paper_pivot.basis*Vector3(x,-0.04,z)).y)
	paper_pivot.position.y=maxf(PAPER_CENTER.y,0.33-lowest)
	var lamp_point := paper_pivot.position+Vector3(cos(az)*cos(el),sin(el),sin(az)*cos(el))*2.95
	lamp_head.position=lamp_point; lamp_head.look_at(paper_pivot.position)
	lamp_base.position=Vector3(lamp_point.x,0.07,lamp_point.z)
	lamp_arm.position=(lamp_point+lamp_base.position)*0.5
	lamp_arm.scale.y=lamp_point.y-lamp_base.position.y
	for i: int in range(pins.size()): pins[i].position.y=0.16+0.18*clampf(progress*3.0-i,0,1)
	door_hinge.rotation.y=move_toward(door_hinge.rotation.y,deg_to_rad(-82.0) if complete else 0.0,maxf(delta,0)*1.4)

func visibility_metrics() -> Dictionary:
	var direction := (lamp.global_position-paper_pivot.global_position).normalized()
	var normal := paper_pivot.basis*Vector3.UP
	var incidence := rad_to_deg(asin(clampf(normal.dot(direction),-1,1)))
	var contrast := 0.0
	for probe: Dictionary in groove_probes:
		var p: Vector2=probe.p; var side: Vector2=probe.side
		var n1 := paper_pivot.basis*surface_normal(p+side); var n2 := paper_pivot.basis*surface_normal(p-side)
		contrast+=absf(maxf(0,n1.dot(direction))-maxf(0,n2.dot(direction)))
	contrast/=maxf(1,groove_probes.size())
	var coverage := 0.0
	for x: float in [-1.5,0,1.5]:
		for z: float in [-1.05,0,1.05]:
			var p := paper_pivot.to_global(Vector3(x,0,z))
			var ray := (p-lamp.global_position).normalized()
			if ray.dot(-lamp.global_basis.z)>cos(deg_to_rad(lamp.spot_angle)) and p.distance_to(lamp.global_position)<lamp.spot_range: coverage+=1.0/9.0
	if not lamp.visible or lamp.light_energy<=0: contrast=0; coverage=0
	return {"contrast":contrast,"incidence":incidence,"coverage":coverage}

func screen_point(world_point: Vector3) -> Vector2:
	return camera.unproject_position(world_point)
