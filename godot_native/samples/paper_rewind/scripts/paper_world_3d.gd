extends Node3D
## Real, depth-tested mesh scene. This owns presentation only, never puzzle state.
## Original world x/y/z maps to Godot x/z/y at 100 chart units per metre.
const SceneProjection = preload("res://scripts/paper_scene_projection.gd")
const Model = preload("res://scripts/paper_rewind_model.gd")
const UNIT := 0.01
var camera: Camera3D
var sun: DirectionalLight3D
var stage: Control
var recorded := false
var pocket_front: MeshInstance3D
var pocket_lip: MeshInstance3D
var cover_hinge: Node3D
var paper: MeshInstance3D
var residual: MeshInstance3D
var paper_material: StandardMaterial3D
var residual_material: StandardMaterial3D
var receiver_indicator: MeshInstance3D
var receiver_material: StandardMaterial3D
var frame_materials: Array[StandardMaterial3D] = []
var meshes: Array[MeshInstance3D] = []

static func space(point: Vector3) -> Vector3:
	return Vector3(point.x,point.z,point.y)*UNIT

func setup(owner_stage: Control, is_recorded: bool) -> void:
	stage=owner_stage; recorded=is_recorded
	name="RecordedMeshWorld" if recorded else "CurrentMeshWorld"
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode=Environment.BG_COLOR
	env.background_color=Color("505750")
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color=Color("d8dfdf")
	env.ambient_light_energy=0.65
	env.tonemap_mode=Environment.TONE_MAPPER_LINEAR
	environment.environment=env; add_child(environment)
	sun=DirectionalLight3D.new(); sun.name="WindowDaylight"
	sun.light_color=Color("fff0d4"); sun.light_energy=1.05
	sun.shadow_enabled=true
	sun.shadow_bias=0.1; sun.shadow_normal_bias=1.0
	sun.directional_shadow_mode=DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.directional_shadow_max_distance=35
	add_child(sun)
	sun.position=Vector3(2,6,-4); sun.look_at(Vector3(5,0,8))
	camera=Camera3D.new(); camera.name="SharedOrthographicCamera"
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect=Camera3D.KEEP_HEIGHT
	camera.near=0.05; camera.far=80; camera.current=true
	add_child(camera)
	_build_room()
	_build_folder()
	for texture: Texture2D in stage.FLIGHT:
		frame_materials.append(_material(Color.WHITE,texture))
	paper_material=frame_materials[0]
	paper=_quad("PhysicalPaper",stage._plane_quad(Rect2(-stage.PAPER_SIZE*0.5,stage.PAPER_SIZE),0),paper_material)
	residual_material=_material(Color(0.88,0.86,0.78,0.35),stage.PAPER)
	residual_material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	residual=_quad("LastReachablePaperTrace",stage._plane_quad(Rect2(-stage.PAPER_SIZE*0.5,stage.PAPER_SIZE),0),residual_material)
	residual.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	configure_camera()

func configure_camera() -> void:
	if not camera or stage.size.x<2 or stage.size.y<2: return
	var a: float=SceneProjection.ELEVATION; var b: float=SceneProjection.YAW
	var right := Vector3(cos(b),0,-sin(b))
	var up := Vector3(-sin(a)*sin(b),cos(a),-sin(a)*cos(b))
	var back := right.cross(up)
	var center: Vector3=stage.camera.unproject_plane(stage.size*0.5,0)
	camera.transform=Transform3D(Basis(right,up,back),space(center)+back*30)
	camera.size=stage.size.y/stage.camera.scale*UNIT

func _material(color: Color, texture: Texture2D=null, metallic: float=0.0, roughness: float=0.85) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color=color
	material.roughness=roughness; material.metallic=metallic
	material.cull_mode=BaseMaterial3D.CULL_BACK
	material.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	if texture:
		material.albedo_texture=texture.atlas if texture is AtlasTexture else texture
		material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		material.alpha_scissor_threshold=0.35
	return material

func _quad(label: String, points: Array, material: StandardMaterial3D, texture: Texture2D=null, crop: Rect2=Rect2(0,0,1,1), parent: Node3D=null, reverse: bool=false) -> MeshInstance3D:
	var vertices := PackedVector3Array()
	for point: Vector3 in points: vertices.append(space(point))
	var normal := (vertices[2]-vertices[0]).cross(vertices[1]-vertices[0]).normalized()
	if reverse: normal = -normal
	var uv := PackedVector2Array([crop.position,Vector2(crop.end.x,crop.position.y),crop.end,Vector2(crop.position.x,crop.end.y)])
	if texture is AtlasTexture:
		for i: int in range(4): uv[i]=(texture.region.position+uv[i]*texture.region.size)/texture.atlas.get_size()
	var arrays := []; arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices
	arrays[Mesh.ARRAY_NORMAL]=PackedVector3Array([normal,normal,normal,normal])
	arrays[Mesh.ARRAY_TEX_UV]=uv
	arrays[Mesh.ARRAY_INDEX]=PackedInt32Array([0,2,1,0,3,2] if reverse else [0,1,2,0,2,3])
	var mesh := ArrayMesh.new(); mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var instance := MeshInstance3D.new(); instance.name=label; instance.mesh=mesh; instance.material_override=material
	(parent if parent else self).add_child(instance); meshes.append(instance)
	return instance

func _box(label: String, center: Vector3, dimensions: Vector3, material: StandardMaterial3D) -> MeshInstance3D:
	var mesh := BoxMesh.new(); mesh.size=Vector3(dimensions.x,dimensions.z,dimensions.y)*UNIT
	var instance := MeshInstance3D.new(); instance.name=label; instance.mesh=mesh; instance.material_override=material
	instance.position=space(center); add_child(instance); meshes.append(instance)
	return instance

func _build_room() -> void:
	var plaster := _material(Color("a6ada2"))
	var wood := _material(Color("aa9472"),null,0,0.82)
	var edge := _material(Color("877456"),null,0,0.82)
	var frame := _material(Color("7a8b80"),null,0,0.68)
	_box("Floor",Vector3(400,600,-318),Vector3(2000,1800,36),_material(Color("6f7368")))
	# Four solid wall pieces leave a genuine opening, so daylight/shadows can pass.
	_box("WallLeft",Vector3(-241,-25,250),Vector3(518,50,1100),plaster)
	_box("WallRight",Vector3(944,-25,250),Vector3(1112,50,1100),plaster)
	_box("WallBelowWindow",Vector3(203,-25,-109),Vector3(370,50,382),plaster)
	_box("WallAboveWindow",Vector3(203,-25,669),Vector3(370,50,262),plaster)
	var canopy := AtlasTexture.new(); canopy.atlas=stage.WINDOW_CANOPY; canopy.region=Rect2(603,340,314,395)
	var outside := _material(Color(0.48,0.52,0.47),canopy)
	# Distant background image is explicitly unlit; the room/objects are lit meshes.
	outside.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	var landscape := _quad("DistantCanopy",stage._wall_quad(Rect2(18,82,370,456),-55),outside,canopy)
	landscape.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for x: float in [27.0,379.0]: _box("WindowJamb",Vector3(x,0,310),Vector3(18,42,456),frame)
	for z: float in [91.0,529.0]: _box("WindowRail",Vector3(203,0,z),Vector3(370,42,18),frame)
	_box("WindowMullion",Vector3(201,10,310),Vector3(14,28,420),frame)
	_box("WindowCrossbar",Vector3(203,10,313),Vector3(334,28,14),frame)
	_box("StoneWindowSill",Vector3(203,27,75),Vector3(390,70,14),_material(Color("b8b8a7"),null,0,0.9))
	_box("DeskSolidTop",Vector3(470,570,-18),Vector3(1260,1080,36),wood)
	_box("DeskFrontApron",Vector3(470,1080,-70),Vector3(1230,24,70),edge)
	for x: float in [100.0,870.0]:
		_box("DeskLeg",Vector3(x,1040,-165),Vector3(35,40,270),edge)
	_box("WallReceiver",Vector3(817,21,215),Vector3(174,35,80),_material(Color("626d62")))
	for i: int in range(12): _box("ReceiverSlot",Vector3(744+i*10,40,214),Vector3(3,1,56),_material(Color("343e38")))

	receiver_material=_material(Color("eee8cf"))
	receiver_material.emission_enabled=true
	receiver_indicator=_box("BroadcastIndicator",Vector3(888,40,215),Vector3(7,2,7),receiver_material)

func _build_folder() -> void:
	var r: Rect2=stage.folder_world_rect()
	var card := _material(Color("999b91"),null,0,0.95)
	_box("FolderBaseThickness",Vector3(r.get_center().x,r.get_center().y,3),Vector3(r.size.x,r.size.y,6),card)
	_quad("FolderBaseArtwork",stage._plane_quad(r,6.1),_material(Color.WHITE,stage.folder_base),stage.folder_base)
	var pocket := Rect2(Vector2(r.position.x,r.position.y+r.size.y*stage.folder_pocket_start),Vector2(r.size.x,r.size.y*(1-stage.folder_pocket_start)))
	pocket_front=_quad("RaisedPocketFront",stage._plane_quad(pocket,12),_material(Color.WHITE,stage.folder_base),stage.folder_base,Rect2(0,stage.folder_pocket_start,1,1-stage.folder_pocket_start))
	# Thin folded lip is geometry; the paper is depth-occluded by the actual pocket.
	pocket_lip=_box("PocketFoldThickness",Vector3(pocket.get_center().x,pocket.position.y,11),Vector3(pocket.size.x,1.6,2),card)
	cover_hinge=Node3D.new(); cover_hinge.name="CoverSpineHinge"; cover_hinge.position=space(Vector3(r.position.x,r.position.y,8)); add_child(cover_hinge)
	var cover_rect := Rect2(0,0,r.size.x,r.size.y)
	var front := _material(Color.WHITE,stage.folder_cover)
	front.cull_mode=BaseMaterial3D.CULL_BACK
	_quad("CoverOutside",stage._plane_quad(cover_rect,0.7),front,stage.folder_cover,Rect2(0,0,1,1),cover_hinge)
	var inside := _material(Color.WHITE,stage.folder_inside)
	inside.cull_mode=BaseMaterial3D.CULL_BACK
	_quad("CoverInside",stage._plane_quad(cover_rect,-0.7),inside,stage.folder_inside,Rect2(0,0,1,1),cover_hinge,true)

func update_scene() -> void:
	if not paper: return
	receiver_material.emission=Color("969b90")*0.05 if stage.broadcast_quiet else Color("eee8cf")*0.35
	var opening: float=0.0 if recorded else stage.folder_open_amount
	cover_hinge.rotation.z=opening*PI
	# Closed card pocket is compressed below the cover; opening releases its fold.
	# Fully open height stays at the approved contact/occlusion plane (12 units).
	var pocket_height := lerpf(6.4,12.0,smoothstep(0.08,0.48,opening))
	pocket_front.position.y=(pocket_height-12.0)*UNIT
	pocket_lip.position.y=(pocket_height-1.0)*UNIT
	var time: float=stage.history_time if recorded else stage.model.time
	var point: Vector2=Model.free_position(time) if recorded else stage.model.paper_position()
	var grounded: bool=not recorded and stage.model.catch_time>=0
	var held: bool=not recorded and stage.paper_grip.held
	var collect: float=-1 if recorded else stage.collection_amount
	var center: Vector3=stage.model_to_space(point)
	var collected: bool=not recorded and stage.model.paper_collected
	paper.visible=not collected or (collect>=0 and collect<1)
	if collected and collect>=0:
		center=stage.model_to_space(Model.REST_POINT)
		center.z+=80*smoothstep(0,0.3,collect)
		center.y+=900*smoothstep(0.24,1,collect)
		center.x-=80*smoothstep(0.24,1,collect)
	var angle := 0.0 if grounded or held or stage.reduced_motion else sin(time*2.8)*0.12
	var flutter: float= 0.0 if grounded or held or stage.reduced_motion else sin(time*7.0)*stage.MAX_FLUTTER
	paper.position=space(center)
	# Same planar angle and small pitch as the approved geometry, now actual transforms.
	paper.basis=Basis(Vector3.RIGHT,flutter)*Basis(Vector3.UP,-angle)
	var frame := 0 if grounded or held or stage.reduced_motion else posmod(int(time*7),5)
	paper.material_override=frame_materials[frame]
	residual.visible=not recorded and stage.model.catch_time<0 and time>7.8 and stage.model.mode!="cancelled"
	residual.position=space(stage.model_to_space(Model.free_position(7.8)))
