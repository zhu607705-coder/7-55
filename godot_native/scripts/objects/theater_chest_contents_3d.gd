extends Node3D
## A presentation-only orthographic miniature. One world unit is one chest
## source pixel; the enclosing transparent SubViewport owns its render target.
const KIT_PATH="res://assets/native/theater_chest_20261023/puzzle_kit.png"
const WOOD_PATH="res://assets/native/theater_chest_20261023/prop_chest_overhead_body_v2.png"
const PowderBrush=preload("res://scripts/objects/theater_powder_brush.gd")
const ATLAS={"fan":Rect2(108,65,351,338),"butterfly":Rect2(605,65,351,338),"lamp":Rect2(1110,65,351,338),"rotor":Rect2(33,452,506,502)}
const CENTERS={"fan":Vector2(370,480),"butterfly":Vector2(418,511),"lamp":Vector2(397,552)}
const STAGING={"fan":Vector2(580,453),"butterfly":Vector2(705,447),"lamp":Vector2(830,455)}
const PINS={"fan":1,"butterfly":2,"lamp":3}
const POSES={"fan":Vector3(10,-18,-8),"butterfly":Vector3(13,12,9),"lamp":Vector3(-8,-12,10)}
const HEIGHTS={"fan":20.0,"butterfly":49.0,"lamp":18.0}
const SLOT_CENTERS=[Vector2(620,606),Vector2(701.406388,747),Vector2(538.593612,747)]
const ROTOR_CENTER=Vector2(620,700)
const TOKEN_SCALE=92.0/130.0
const CRANK_SCALE=.78
const DRAWER_RECT=Rect2(855,766,300,110)
var latch: Node3D
var brush: Node3D
var camera: Camera3D
var kit: Texture2D
var wood: Texture2D
var tokens: Dictionary={}
var token_faces: Dictionary={}
var rotor: Node3D
var crank: Node3D
var brass: StandardMaterial3D
var dark_brass: StandardMaterial3D
var drawer_board: MeshInstance3D
var drawer_board_mesh: PlaneMesh
var drawer_board_material: StandardMaterial3D
var snapshot: Dictionary={}
var _state: Dictionary={}

func _ready() -> void:
	kit=_texture(KIT_PATH);wood=_texture(WOOD_PATH)
	brass=_material(Color("a17b3c"),.48,.8)
	dark_brass=_material(Color("70502b"),.25,.9)
	_build_camera_and_light()
	_build_floor()
	_build_drawer()
	_build_paper_slips()
	_build_rotor()
	for id: String in ["fan","butterfly","lamp"]:_build_token(id)
	_build_crank()
	_build_washers()
	_build_latch_and_brush()
	update_presentation(_state)

func _texture(path: String) -> Texture2D:
	if FileAccess.file_exists(path+".import"):return load(path)
	var pixels:=Image.load_from_file(path)
	return null if pixels.is_empty() else ImageTexture.create_from_image(pixels)

func _material(color: Color, metallic:=0.0, roughness:=1.0) -> StandardMaterial3D:
	var material:=StandardMaterial3D.new()
	material.albedo_color=color;material.metallic=metallic;material.roughness=roughness
	material.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST
	return material

func _art_material(texture: Texture2D, region: Rect2) -> StandardMaterial3D:
	var material:=_material(Color.WHITE)
	material.albedo_texture=texture
	material.uv1_scale=Vector3(region.size.x/texture.get_width(),region.size.y/texture.get_height(),1)
	material.uv1_offset=Vector3(region.position.x/texture.get_width(),region.position.y/texture.get_height(),0)
	material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	material.alpha_scissor_threshold=.2
	return material

func _build_camera_and_light() -> void:
	camera=Camera3D.new();camera.name="OverheadCamera"
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=1086
	camera.keep_aspect=Camera3D.KEEP_HEIGHT;camera.near=1;camera.far=3000
	camera.position=Vector3(724,1600,543);add_child(camera)
	camera.look_at(Vector3(724,0,543),Vector3(0,0,-1));camera.current=true
	var environment:=Environment.new()
	environment.background_mode=Environment.BG_COLOR;environment.background_color=Color.TRANSPARENT
	environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color=Color.WHITE;environment.ambient_light_energy=.78
	environment.tonemap_mode=Environment.TONE_MAPPER_LINEAR
	var world_environment:=WorldEnvironment.new();world_environment.environment=environment;add_child(world_environment)
	var key:=DirectionalLight3D.new();key.name="UpperLeftContactLight"
	key.position=Vector3(-450,1500,-550);add_child(key)
	key.look_at(Vector3(724,0,543),Vector3.UP)
	key.light_color=Color("fff1d9");key.light_energy=.58
	key.shadow_enabled=true;key.directional_shadow_max_distance=2400
	key.directional_shadow_mode=DirectionalLight3D.SHADOW_ORTHOGONAL
	key.shadow_bias=.02;key.shadow_normal_bias=.2

func _plane(parent: Node3D, dimensions: Vector2, at: Vector3, material: Material, node_name: String) -> MeshInstance3D:
	var mesh:=PlaneMesh.new();mesh.size=dimensions
	var node:=MeshInstance3D.new();node.name=node_name;node.mesh=mesh;node.material_override=material
	node.position=at;parent.add_child(node);return node

func _build_floor() -> void:
	# Keep the physical floor around an actual opening. The underlying 2D
	# recess/paper is visible through it after its separate board slides away.
	for patch: Rect2 in [Rect2(270,383,908,383),Rect2(270,766,585,110),Rect2(1155,766,23,110),Rect2(270,876,908,8)]:
		_floor_patch(patch)

func _floor_patch(patch: Rect2) -> void:
	var floor_material:=_art_material(wood,patch)
	floor_material.albedo_color=Color(.75,.75,.75)
	var center:=patch.get_center()
	var floor:=_plane(self,patch.size,Vector3(center.x,0,center.y),floor_material,"ShadowReceivingWoodFloor")
	floor.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _build_drawer() -> void:
	var edge_wood:=_art_material(wood,Rect2(400,415,250,130))
	edge_wood.albedo_color=Color(.66,.66,.66)
	_box(self,Vector3(5,10,110),Vector3(857.5,2,821),edge_wood,"DrawerLeftWall")
	_box(self,Vector3(5,10,110),Vector3(1152.5,2,821),edge_wood,"DrawerRightWall")
	_box(self,Vector3(300,10,5),Vector3(1005,2,768.5),edge_wood,"DrawerRearWall")
	_box(self,Vector3(300,10,5),Vector3(1005,2,873.5),edge_wood,"DrawerFrontLip")
	drawer_board_material=_art_material(wood,DRAWER_RECT)
	drawer_board_material.albedo_color=Color(.75,.75,.75)
	drawer_board=_plane(self,DRAWER_RECT.size,Vector3(1005,.4,821),drawer_board_material,"SlidingFalseBottom")
	drawer_board_mesh=drawer_board.mesh as PlaneMesh
	var handle_material:=_art_material(kit,Rect2(190,85,170,45))
	handle_material.albedo_color=Color(.78,.78,.78);handle_material.metallic=.35;handle_material.roughness=.82
	for x: float in [951,1059]:
		_rod(self,Vector3(x,0,858),Vector3(x,16,858),3.5,handle_material,"DrawerHandlePost")
	_rod(self,Vector3(951,16,858),Vector3(1059,16,858),4,handle_material,"DrawerPullRail")

func _update_drawer(amount: float) -> void:
	var progress:=clampf(amount,0,1)
	var depth:=DRAWER_RECT.size.y*(1.0-progress)
	drawer_board.visible=depth>.05
	if not drawer_board.visible:return
	drawer_board_mesh.size=Vector2(DRAWER_RECT.size.x,depth)
	drawer_board.position=Vector3(DRAWER_RECT.get_center().x,.4,DRAWER_RECT.position.y+DRAWER_RECT.size.y*progress+depth*.5)
	drawer_board_material.uv1_scale=Vector3(DRAWER_RECT.size.x/wood.get_width(),depth/wood.get_height(),1)

func _box(parent: Node3D, dimensions: Vector3, at: Vector3, material: Material, node_name: String) -> MeshInstance3D:
	var mesh:=BoxMesh.new();mesh.size=dimensions
	var node:=MeshInstance3D.new();node.name=node_name;node.mesh=mesh;node.material_override=material
	node.position=at;parent.add_child(node);return node

func _build_paper_slips() -> void:
	var paper:=_material(Color("bba681"))
	for index: int in range(2):
		var slip:=_box(self,Vector3(172,1.4,103),Vector3(405+index*8,2+index*2,523-index*8),paper,"LoosePaperSlip"+str(index))
		slip.rotation.y=deg_to_rad(21-index*8)
	var fold:=_box(self,Vector3(40,1,29),Vector3(480,8,558),_material(Color("d5c19b")),"RaisedPaperFold")
	fold.rotation=Vector3(deg_to_rad(-24),deg_to_rad(21),0)

func _mesh_node(parent: Node3D, mesh: Mesh, material: Material, at: Vector3, node_name: String) -> MeshInstance3D:
	var node:=MeshInstance3D.new();node.name=node_name;node.mesh=mesh;node.material_override=material;node.position=at
	parent.add_child(node);return node

func _beveled_plate(width: float, depth: float, height: float) -> ArrayMesh:
	var builder:=SurfaceTool.new();builder.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings: Array[PackedVector3Array]=[]
	for level: int in range(4):
		var inset:=2.0 if level in [0,3] else 0.0
		var x:=width*.5-inset;var z:=depth*.5-inset;var bevel:=9.0
		var y: float=[0.0,2.0,height-2.0,height][level]
		rings.append(PackedVector3Array([Vector3(-x+bevel,y,-z),Vector3(x-bevel,y,-z),Vector3(x,y,-z+bevel),Vector3(x,y,z-bevel),Vector3(x-bevel,y,z),Vector3(-x+bevel,y,z),Vector3(-x,y,z-bevel),Vector3(-x,y,-z+bevel)]))
	for level: int in range(3):
		for index: int in range(8):
			var following: int=(index+1)%8
			for vertex: Vector3 in [rings[level][index],rings[level+1][index],rings[level+1][following],rings[level][index],rings[level+1][following],rings[level][following]]:builder.add_vertex(vertex)
	for index: int in range(8):
		for vertex: Vector3 in [Vector3(0,height,0),rings[3][(index+1)%8],rings[3][index]]:builder.add_vertex(vertex)
	builder.generate_normals();return builder.commit()

func _build_token(id: String) -> void:
	var token:=Node3D.new();token.name=id.capitalize()+"Token";add_child(token);tokens[id]=token
	_mesh_node(token,_beveled_plate(130,125,15),brass,Vector3.ZERO,"ExtrudedBrassBevel")
	var face:=_art_material(kit,ATLAS[id]);token_faces[id]=face
	_plane(token,Vector2(130,125),Vector3(0,15.15,0),face,"EngravedTopFace")
	# Deep dark keyways along the upper edge match the socket's brass teeth.
	for index: int in range(PINS[id]):
		var x: float=(index-(PINS[id]-1)*.5)*23
		_box(token,Vector3(13,3,23),Vector3(x,16,-52),dark_brass,"Keyway%d"%index)

func _build_rotor() -> void:
	rotor=Node3D.new();rotor.name="PhysicalRotor";rotor.position=Vector3(620,2,700);add_child(rotor)
	var cylinder:=CylinderMesh.new();cylinder.top_radius=163;cylinder.bottom_radius=165;cylinder.height=17;cylinder.radial_segments=64
	_mesh_node(rotor,cylinder,dark_brass,Vector3(0,8.5,0),"RotorThickness")
	_plane(rotor,Vector2(330,330.0*502/506),Vector3(0,17.1,0),_art_material(kit,ATLAS.rotor),"EngravedRotorTop")
	# The raised socket rims are geometry; their wood recesses remain on the
	# authored top plate, aligned with the controller's canonical slot centers.
	for index: int in range(3):
		var local: Vector2=SLOT_CENTERS[index]-ROTOR_CENTER
		var recess:=_art_material(wood,Rect2(600,600,94,94))
		recess.albedo_color=Color(.48,.48,.48)
		_plane(rotor,Vector2(94,94),Vector3(local.x,18.4,local.y),recess,"SocketWoodRecess")
		for tooth: int in range([2,3,1][index]):
			var offset: float=(tooth-([2,3,1][index]-1)*.5)*23*TOKEN_SCALE
			_box(rotor,Vector3(8,7,14),Vector3(local.x+offset,23,local.y-43),brass,"SocketTooth%d_%d"%[index,tooth])
		for side: int in [-1,1]:
			_box(rotor,Vector3(7,5,108),Vector3(local.x+side*50.5,21,local.y),brass,"SocketSide")
			_box(rotor,Vector3(108,5,7),Vector3(local.x,21,local.y+side*50.5),brass,"SocketEnd")

func _rod(parent: Node3D, from: Vector3, to: Vector3, radius: float, material: Material, node_name: String) -> void:
	var cylinder:=CylinderMesh.new();cylinder.top_radius=radius;cylinder.bottom_radius=radius;cylinder.height=from.distance_to(to);cylinder.radial_segments=16
	var node:=_mesh_node(parent,cylinder,material,(from+to)*.5,node_name)
	node.quaternion=Quaternion(Vector3.UP,(to-from).normalized())

func _build_crank() -> void:
	crank=Node3D.new();crank.name="PhysicalCrank";add_child(crank)
	var worn_brass:=_art_material(kit,Rect2(190,85,170,45))
	worn_brass.albedo_color=Color(.78,.78,.78);worn_brass.metallic=.35;worn_brass.roughness=.82
	var wood_grain:=_art_material(wood,Rect2(400,415,250,130))
	wood_grain.albedo_color=Color(.78,.78,.78);wood_grain.roughness=.95
	_rod(crank,Vector3(0,1,0),Vector3(0,45,0),15,dark_brass,"AxlePin")
	_rod(crank,Vector3(0,44,0),Vector3(85,44,0),10,worn_brass,"CrankArm")
	_rod(crank,Vector3(85,44,0),Vector3(85,44,52),10,worn_brass,"CrankElbow")
	_rod(crank,Vector3(85,36,0),Vector3(85,52,0),13,worn_brass,"ElbowJointCollar")
	_rod(crank,Vector3(85,44,52),Vector3(148,44,52),16,wood_grain,"WoodGrip")
	_rod(crank,Vector3(85,44,52),Vector3(91,44,52),17,worn_brass,"GripInnerFerrule")
	_rod(crank,Vector3(146,44,52),Vector3(154,44,52),17,worn_brass,"GripEndCap")
	var groove:=_material(Color("3b261b"),0,.95)
	for index: int in range(3):
		var x:=103.0+index*12
		_rod(crank,Vector3(x,44,52),Vector3(x+1.5,44,52),16.25,groove,"GripGroove"+str(index))

func _build_washers() -> void:
	for index: int in range(2):
		var ring:=TorusMesh.new();ring.inner_radius=10;ring.outer_radius=17;ring.rings=32;ring.ring_segments=8
		var node:=_mesh_node(self,ring,brass,Vector3(1111+index*20,5+index*5,560+index*12),"LooseBrassWasher"+str(index))
		node.rotation.x=deg_to_rad(index*13)

func _build_latch_and_brush() -> void:
	_box(self,Vector3(92,6,15),Vector3(846,4,782),dark_brass,"LatchGuide")
	for x: float in [812,846]:
		_box(self,Vector3(9,19,27),Vector3(x,10,782),brass,"LatchGuideCollar")
	latch=Node3D.new();latch.name="RetractingLatch";add_child(latch)
	_rod(latch,Vector3(770,14,719),Vector3(823,14,782),5,brass,"CamConnectingRod")
	_box(latch,Vector3(100,8,11),Vector3(842,13,782),brass,"LockTongue")
	brush=PowderBrush.new();brush.name="FluorescentBrush";brush.position=Vector3(936,-20,814)
	brush.rotation.y=deg_to_rad(11);add_child(brush)

func update_state(value: Dictionary, selected: String="", hovered: String="", turn_angle: float=0.0, clue_flip: float=0.0, drawer_amount: float=0.0, placement_piece: String="", placement_from: Vector2=Vector2.ZERO, placement_to: Vector2=Vector2.ZERO, placement_amount: float=0.0, pickup_amount: float=0.0, held_piece: String="", held_offset: Vector2=Vector2.ZERO, held_lift: float=0.0) -> void:
	update_presentation({"snapshot":value,"selected":selected,"hovered":hovered,"turn_angle":turn_angle,"clue_flip":clue_flip,"drawer_amount":drawer_amount,"placement_piece":placement_piece,"placement_from":placement_from,"placement_to":placement_to,"placement_amount":placement_amount,"pickup_amount":pickup_amount,"held_piece":held_piece,"held_offset":held_offset,"held_lift":held_lift})

func update_presentation(value: Dictionary) -> void:
	_state=value.duplicate(true)
	if not is_instance_valid(rotor):return
	snapshot=value.get("snapshot",{}).duplicate(true)
	_update_drawer(float(value.get("drawer_amount",1.0 if bool(snapshot.get("drawer_open",false)) else 0.0)))
	var turn:=float(value.get("turn_angle",0.0))
	var base:=float(snapshot.get("turns",0))*TAU/3.0
	rotor.rotation.y=-(base+turn)
	var release:=clampf((base+turn)/(TAU/3.0),0,1)
	latch.position=Vector3(-50*release,0,-12*release)
	var pickup:=float(value.get("pickup_amount",0))
	brush.visible=not bool(snapshot.get("brush_taken",false)) or pickup>0 and pickup<1
	brush.position=Vector3(936+pickup*200,-20+sin(pickup*PI)*150,814-pickup*190)
	brush.scale=Vector3.ONE*(1.0-pickup*.6)
	var remaining: Array=snapshot.get("remaining",["fan","butterfly","lamp","crank"])
	var slots: Array=snapshot.get("slots",["","",""])
	var flying:=str(value.get("placement_piece",""))
	var selected_id:=str(value.get("selected",""))
	for id: String in tokens:
		var node: Node3D=tokens[id]
		var slot:=slots.find(id)
		node.visible=id in remaining or slot>=0 or flying==id
		if slot>=0:
			var point: Vector2=ROTOR_CENTER+(SLOT_CENTERS[slot]-ROTOR_CENTER).rotated(turn)
			node.position=Vector3(point.x,23,point.y);node.rotation=Vector3(0,-(base+turn),0);node.scale=Vector3.ONE*TOKEN_SCALE
		else:
			var cleared: bool=id in snapshot.get("cleared",[])
			var point: Vector2=STAGING[id] if cleared else CENTERS[id];var pose: Vector3=Vector3(0,0,0) if cleared else POSES[id]
			var lift:=65.0 if id==selected_id else 0.0
			node.position=Vector3(point.x,(23.0 if cleared else float(HEIGHTS[id]))+lift,point.y)
			node.rotation=Vector3(deg_to_rad(pose.x),-deg_to_rad(pose.y),deg_to_rad(pose.z));node.scale=Vector3.ONE*TOKEN_SCALE
		if flying==id:
			var amount:=clampf(float(value.get("placement_amount",0.0)),0,1)
			var destination: Vector2=value.get("placement_to",CENTERS[id])
			# Start with the actual current pose, including fitted size or a
			# selected loose piece's lift. No full-size reset at animation start.
			node.position=node.position.lerp(Vector3(destination.x,23,destination.y),amount)+Vector3.UP*sin(amount*PI)*45
			node.quaternion=node.quaternion.slerp(Quaternion.from_euler(Vector3(0,-(base+turn),0)),amount)
			node.scale=Vector3.ONE*TOKEN_SCALE
		var selected: bool=id==selected_id or id==str(value.get("hovered",""))
		var face: StandardMaterial3D=token_faces[id]
		face.emission_enabled=selected;face.emission=Color("8c6936");face.emission_energy_multiplier=.18
		_apply_held(node,id,value)
	crank.visible="crank" in remaining or bool(snapshot.get("crank_installed",false)) or flying=="crank"
	if bool(snapshot.get("crank_installed",false)):
		crank.position=Vector3(620,23,700);crank.rotation=Vector3(0,-(base+turn-PI*.25),0);crank.scale=Vector3.ONE*CRANK_SCALE
	else:
		var offset: Vector2=Vector2(70,26).rotated(deg_to_rad(20))*CRANK_SCALE
		var lift:=65.0 if selected_id=="crank" else 0.0
		crank.position=Vector3(1000-offset.x,8+lift,490-offset.y);crank.rotation=Vector3(deg_to_rad(5),deg_to_rad(-20),deg_to_rad(-6));crank.scale=Vector3.ONE*CRANK_SCALE
	if flying=="crank":
		var amount:=clampf(float(value.get("placement_amount",0)),0,1)
		var destination: Vector2=value.get("placement_to",ROTOR_CENTER)
		# The loose mesh origin is its pin, not its visible bounds' center.
		# Interpolate that exact pin pose into the mounted axle pose.
		crank.position=crank.position.lerp(Vector3(destination.x,23,destination.y),amount)+Vector3.UP*sin(amount*PI)*45
		crank.quaternion=crank.quaternion.slerp(Quaternion.from_euler(Vector3(0,-(base+turn-PI*.25),0)),amount)
		crank.scale=Vector3.ONE*CRANK_SCALE
	_apply_held(crank,"crank",value)

func _apply_held(node: Node3D, id: String, value: Dictionary) -> void:
	if str(value.get("held_piece",""))!=id:return
	var offset: Vector2=value.get("held_offset",Vector2.ZERO)
	node.position+=Vector3(offset.x,float(value.get("held_lift",0)),offset.y)

func projected_anchor(id: String) -> Vector2:
	var node: Node3D=brush if id=="brush" else crank if id=="crank" else tokens.get(id)
	if not is_instance_valid(node) or not is_instance_valid(camera):return Vector2.ZERO
	return camera.unproject_position(node.global_position)

func projected_polygon(id: String) -> PackedVector2Array:
	var polygon:=PackedVector2Array()
	if not is_instance_valid(camera):return polygon
	var node: Node3D=brush if id=="brush" else crank if id=="crank" else tokens.get(id)
	if not is_instance_valid(node) or not node.visible:return polygon
	var points: Array[Vector3]=[]
	if id=="brush":points.assign(PowderBrush.OUTLINE)
	elif id=="crank":
		points=[Vector3(-16,47,-16),Vector3(99,47,-16),Vector3(99,60,35),Vector3(157,60,35),Vector3(157,60,69),Vector3(69,60,69),Vector3(69,47,15),Vector3(-16,47,15)]
	else:
		points=[Vector3(-56,15.2,-62.5),Vector3(56,15.2,-62.5),Vector3(65,15.2,-53.5),Vector3(65,15.2,53.5),Vector3(56,15.2,62.5),Vector3(-56,15.2,62.5),Vector3(-65,15.2,53.5),Vector3(-65,15.2,-53.5)]
	for point: Vector3 in points:polygon.append(camera.unproject_position(node.to_global(point)))
	return polygon
