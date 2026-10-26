extends Node3D
## Immutable historical snapshots and a separate present bookshelf, all actual 3D.
const Rig = preload("res://kit/camera_rig.gd")
const FONT = preload("res://assets/MorningNote-Regular.ttf")
const ORDER_NOW := [0,1,2,3,4,5]
const ORDER_THEN := [1,3,2,4,0,5]
const BOOK_X := [-1.64,-0.98,-0.33,0.33,0.98,1.64]
const REFERENCE := Vector3(0.025,0.63,0.70)
var camera: Camera3D
var phase := -1
var books: Dictionary={}
var base_positions: Dictionary={}
var blockers: Array[MeshInstance3D]=[]
var env: Environment
var collision_bodies: Array[StaticBody3D]=[]

func setup(history_phase: int=-1) -> void:
	phase=history_phase
	var environment := WorldEnvironment.new(); env=Environment.new()
	env.background_mode=Environment.BG_COLOR; env.background_color=Color("293e3c")
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color=Color("c9d2bd"); env.ambient_light_energy=0.52
	env.tonemap_mode=Environment.TONE_MAPPER_LINEAR; environment.environment=env; add_child(environment)
	camera=Camera3D.new(); camera.current=true; camera.near=.05; camera.far=60; add_child(camera)
	var sunlight := DirectionalLight3D.new(); sunlight.rotation_degrees=Vector3(-50,-28,0); sunlight.light_color=Color("ffe7ba"); sunlight.light_energy=.85
	sunlight.shadow_enabled=true; sunlight.shadow_bias=.12; sunlight.shadow_normal_bias=1.0; add_child(sunlight)
	var fill := DirectionalLight3D.new(); fill.rotation_degrees=Vector3(-65,145,0); fill.light_color=Color("b2d6d2"); fill.light_energy=.22; add_child(fill)
	_build_room()
	_build_shelf()
	if phase>=0: _build_occluder()

func material(color: Color, roughness: float=.86) -> StandardMaterial3D:
	var m := StandardMaterial3D.new(); m.albedo_color=color; m.roughness=roughness; return m

func box(label: String, center: Vector3, dimensions: Vector3, m: Material, parent: Node3D=null, collides: bool=false) -> MeshInstance3D:
	var node := MeshInstance3D.new(); var mesh := BoxMesh.new(); mesh.size=dimensions
	node.name=label; node.mesh=mesh; node.material_override=m; node.position=center; (parent if parent else self).add_child(node)
	if collides:
		var body := StaticBody3D.new(); var shape := CollisionShape3D.new(); var bounds := BoxShape3D.new(); bounds.size=dimensions; shape.shape=bounds
		node.add_child(body); body.add_child(shape); collision_bodies.append(body)
	return node

func _build_room() -> void:
	var timber := material(Color("71644c")); var steel := material(Color("344e48"))
	box("LibraryFloor",Vector3(0,-.14,0),Vector3(18,.20,18),material(Color("90978a")))
	for x: int in range(-5,6): box("FloorJoin",Vector3(x*1.3,-.032,0),Vector3(.012,.008,18),material(Color("7c877d")))
	box("BackWall",Vector3(0,2.8,-1.05),Vector3(12,6,.20),material(Color("a2ad97")))
	# Peripheral shelves establish a library, not an invented real floor plan.
	for side: int in [-1,1]:
		box("NeighborBookcase",Vector3(side*4.0,1.42,-.36),Vector3(2.0,2.95,.72),steel)
		for row: int in range(3):
			for i: int in range(7):
				box("NeighborVolume",Vector3(side*4.0-.79+i*.25,.47+row*.85,-.005),Vector3(.19,.65,.30),material(Color("777b5c") if i%2 else Color("48675d")))
	box("ReadingTable",Vector3(0,.20,3.05),Vector3(4.0,.18,1.45),timber)
	for x: float in [-1.70,1.70]: box("TableLeg",Vector3(x,-.05,3.05),Vector3(.12,.45,.9),steel)
	box("ReadingMat",Vector3(0,.31,3.05),Vector3(2.1,.035,.98),material(Color("47605a")))
	box("LampFoot",Vector3(-1.38,.35,2.75),Vector3(.40,.07,.35),steel)
	box("LampStem",Vector3(-1.38,.85,2.75),Vector3(.045,1,.045),material(Color("b4ac8b")))
	box("GreenReadingLamp",Vector3(-1.38,1.36,2.75),Vector3(.68,.16,.32),material(Color("365e4b")))
	var light := OmniLight3D.new(); light.position=Vector3(-1.38,1.23,2.75); light.omni_range=2.5; light.light_energy=.45; light.light_color=Color("ffdf9c"); add_child(light)

func _build_shelf() -> void:
	var wood := material(Color("7a6248")); var dark := material(Color("4c5342")); var brass := material(Color("c5aa6c"),.5)
	box("ShelfBack",Vector3(0,1.60,-.38),Vector3(4.46,3.15,.12),dark,null,true)
	for x: float in [-2.18,0,2.18]: box("FixedShelfUpright",Vector3(x,1.56,.13),Vector3(.11,3.15,.95),wood,null,true)
	for y: float in [.53,2.18,3.14]: box("FixedShelfBoard",Vector3(0,y,.12),Vector3(4.46,.12,1.0),wood,null,true)
	box("ShelfPlinth",Vector3(0,.18,.14),Vector3(4.55,.3,1.02),dark,null,true)
	# A brass L and two old screw heads stay fixed through every historical snapshot.
	box("FixedReferenceVertical",Vector3(.025,.79,.705),Vector3(.055,.42,.025),brass)
	box("FixedReferenceHorizontal",Vector3(.20,.60,.705),Vector3(.40,.055,.025),brass)
	for y: float in [.64,.95]: box("ReferenceScrew",Vector3(.025,y,.725),Vector3(.024,.024,.012),material(Color("3b453f")))
	box("ReferenceRibbonClip",Vector3(.33,2.26,.70),Vector3(.19,.18,.035),brass)
	box("ReferenceRibbon",Vector3(.33,2.12,.71),Vector3(.12,.26,.025),material(Color("b06348")))
	var order: Array=ORDER_THEN if phase>=0 else ORDER_NOW
	for slot: int in range(6): _book(order[slot],Vector3(BOOK_X[slot],1.30,.22))
	# Ordinary upper-shelf objects and little leather reading ledgers.
	for i: int in range(11):
		var height := .40+float(i%3)*.07
		box("UpperReferenceBook",Vector3(-1.90+i*.36,2.24+height*.5,-.02),Vector3(.22,height,.48),material(Color("a99b70") if i%3==0 else Color("50675b")))
	var sign := Label3D.new(); sign.text="馆 藏"; sign.font=FONT; sign.font_size=52; sign.pixel_size=.006; sign.modulate=Color("e3d6b4"); sign.position=Vector3(-1.10,3.34,.48); sign.no_depth_test=false; add_child(sign)


func _book(id: int, p: Vector3) -> void:
	var pivot := Node3D.new(); pivot.name="Book_%d"%id; pivot.position=p; add_child(pivot); books[id]=pivot; base_positions[id]=p
	var upper_is_ring := id>=3
	var lower_count := id%3+1
	pivot.set_meta("upper_mark","ring" if upper_is_ring else "triangle"); pivot.set_meta("lower_bars",lower_count)
	var cover := material(Color("627b70")); var ink := material(Color("ebe2c6"))
	box("ClothCover",Vector3.ZERO,Vector3(.49,1.36,.56),cover,pivot,true)
	box("PaperPages",Vector3(.02,0,-.02),Vector3(.42,1.28,.48),material(Color("c5c1a7")),pivot)
	box("Spine",Vector3(0,0,.286),Vector3(.49,1.36,.025),cover,pivot)
	for y: float in [-.57,.57]: box("BindingBand",Vector3(0,y,.306),Vector3(.47,.035,.022),ink,pivot)
	if upper_is_ring:
		var ring := MeshInstance3D.new(); var mesh := TorusMesh.new(); mesh.inner_radius=.105; mesh.outer_radius=.143; mesh.rings=24; mesh.ring_segments=12
		ring.mesh=mesh; ring.material_override=ink; ring.position=Vector3(0,.27,.32); ring.rotation.x=PI*.5; pivot.add_child(ring)
	else:
		var a := Vector2(0,.42); var b := Vector2(-.15,.16); var c := Vector2(.15,.16)
		_line(pivot,a,b,ink); _line(pivot,b,c,ink); _line(pivot,c,a,ink)
	for bar: int in range(lower_count): box("LowerBar",Vector3(0,-.18-bar*.105,.32),Vector3(.27,.038,.025),ink,pivot)

func _line(parent: Node3D, a: Vector2, b: Vector2, m: Material) -> void:
	var segment := box("TriangleInlay",Vector3((a.x+b.x)*.5,(a.y+b.y)*.5,.32),Vector3(.035,a.distance_to(b),.025),m,parent)
	segment.rotation.z=-atan2(b.x-a.x,b.y-a.y)

func _build_occluder() -> void:
	var tote := material(Color("435f62")); var paper := material(Color("bcae8b"))
	if phase==0:
		# A full opaque return tote blocks the lower symbol, not the upper symbol.
		blockers.append(box("MorningReturnTote",Vector3(.98,1.20,1.03),Vector3(1.72,.88,.32),tote,null,true))
		box("ToteRim",Vector3(.98,1.67,1.03),Vector3(1.78,.06,.38),material(Color("91a39b")),null,true)
		for x: float in [.14,1.80]: box("ToteHandle",Vector3(x,1.78,1.04),Vector3(.06,.20,.06),tote,null,true)
	else:
		# A hanging folio masks the upper symbol. Its bottom edge leaves the bars visible.
		blockers.append(box("AfternoonHangingFolio",Vector3(.98,2.16,1.02),Vector3(1.72,.65,.08),paper,null,true))
		box("FolioBinder",Vector3(.98,2.50,1.02),Vector3(1.78,.08,.12),material(Color("806b52")),null,true)
		for x: float in [.05,1.75]: box("FolioClip",Vector3(x,2.59,1.02),Vector3(.05,.18,.10),material(Color("bdab76")),null,true)

func configure_camera(viewport_size: Vector2) -> void:
	if phase>=0:
		Rig.configure(camera,viewport_size,Vector3(.72,1.44,.57),2.36,2.3)
	else:
		var focus := Vector3(0,1.42,.80)
		if viewport_size.y>viewport_size.x: focus+=Vector3(-.106,.643,-.759)*1.35
		Rig.configure(camera,viewport_size,focus,5.35,5.2)

func update_current(book: int, amount: float, complete: bool, delta: float) -> void:
	if phase>=0: return
	for id: int in books:
		var goal: Vector3=base_positions[id]
		if id==book: goal.z+=amount*.90
		if complete and id==4: goal=Vector3(.35,.58,3.05)
		books[id].position=books[id].position.lerp(goal,1.0-exp(-maxf(delta,0)*14.0))
		var angle := -PI*.5 if complete and id==4 else 0.0
		books[id].rotation.x=lerp_angle(books[id].rotation.x,angle,1.0-exp(-maxf(delta,0)*9.0))

func screen_point(p: Vector3) -> Vector2: return camera.unproject_position(p)

func glyph_point(top: bool) -> Vector3:
	return books[4].to_global(Vector3(0,.27 if top else -.24,.34))

func fragment_probes(top: bool) -> Array[Vector3]:
	var probes: Array[Vector3]=[]
	# Validate the complete exposed mark, not a blank point in the ring's hole.
	if top:
		for offset: Vector2 in [Vector2(-.14,.27),Vector2(.14,.27),Vector2(0,.41),Vector2(0,.13)]:
			probes.append(books[4].to_global(Vector3(offset.x,offset.y,.34)))
	else:
		for y: float in [-.18,-.285]:
			for x: float in [-.13,.13]: probes.append(books[4].to_global(Vector3(x,y,.34)))
	probes.append(REFERENCE)
	return probes

func visible_from_camera(p: Vector3) -> bool:
	var screen := camera.unproject_position(p)
	var q := PhysicsRayQueryParameters3D.create(camera.project_ray_origin(screen),p)
	q.collide_with_areas=false
	return get_world_3d().direct_space_state.intersect_ray(q).is_empty()

func book_polygon(id: int) -> PackedVector2Array:
	var result := PackedVector2Array()
	for p: Vector3 in [Vector3(-.245,-.68,.325),Vector3(.245,-.68,.325),Vector3(.245,.68,.325),Vector3(-.245,.68,.325)]: result.append(screen_point(books[id].to_global(p)))
	return result
