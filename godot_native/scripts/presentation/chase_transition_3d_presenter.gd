extends "res://scripts/presentation/chase_transition_clock.gd"
## Native 3D playback of original source geometry and sampled IK/bone transforms.
## Clock/ownership/UI come from the separately tested presentation-only base.
## This is not a browser wrapper: Godot renders the original GLB-based mesh scene.
const MaterialAdapter=preload("res://scripts/presentation/chase3d/source_material_adapter.gd")
var material_adapter:=MaterialAdapter.new()
var ready3d: bool=false
var failure_reason: String=""
const SCENE_PATH := "res://assets/derived/chase_transition_3d/source_geometry.scn"
const MANIFEST_PATH := "res://assets/derived/chase_transition_3d/source_runtime.json"
var view3d: SubViewport
var source_root: Node3D
var source_animation: AnimationPlayer
var source_camera: Camera3D
var source_environment: Environment
var source_sun: DirectionalLight3D
var source_fill: DirectionalLight3D
var source_portrait: DirectionalLight3D
var surface: TextureRect
var pause_cover: ColorRect
var validation_reference: bool=false
var source_manifest: Dictionary={}
var source_poses: Dictionary={}
var bone_corrections: Dictionary={}
var source_nodes: Dictionary={}
var source_bones: Dictionary={}
var _active_clip: String=""
var _rendered_frame: int=-1

func _ready() -> void:
	super._ready()
	source_manifest=JSON.parse_string(FileAccess.get_file_as_string("res://assets/derived/chase_transition_3d/source_transition.json" if validation_reference else MANIFEST_PATH))
	source_poses=JSON.parse_string(FileAccess.get_file_as_string("res://assets/derived/chase_transition_3d/source_pose_frames.json"))
	if not source_manifest is Dictionary or not source_poses is Dictionary:
		failure_reason="原始骑行动画数据缺失。";return
	var packed: PackedScene=load(SCENE_PATH)
	if packed==null:failure_reason="原始骑行动画资源缺失。";return
	view3d=SubViewport.new();view3d.name="OriginalTransitionViewport"
	view3d.size=Vector2i(960,540);view3d.own_world_3d=true
	view3d.render_target_update_mode=SubViewport.UPDATE_DISABLED
	view3d.msaa_3d=Viewport.MSAA_4X
	add_child(view3d)
	source_root=packed.instantiate();source_root.physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF;view3d.add_child(source_root)
	_register_source_node(source_root)
	material_adapter.adapt_scene(source_root)
	for camera: Camera3D in source_root.find_children("*","Camera3D",true,false):camera.current=false
	for light: Light3D in source_root.find_children("*","Light3D",true,false):light.hide()
	source_animation=source_root.find_children("*","AnimationPlayer",true,false)[0]
	source_animation.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	# Godot may normalize imported bone axes. Preserve that fixed bind-space
	# mapping while using the original source IK world matrices for every frame.
	for i: int in range(source_poses.bones.size()):
		var name: String=source_poses.bones[i].name
		var entry: Dictionary=source_bones[name]
		var native: Transform3D=entry.skeleton.global_transform*entry.skeleton.get_bone_global_pose(entry.bone)
		bone_corrections[name]=_source_matrix(source_poses.stages.start.boneWorld[0][i]).affine_inverse()*native
	source_camera=Camera3D.new();source_camera.name="AuthoredSourceCamera"
	source_camera.near=.1;source_camera.far=180;source_camera.keep_aspect=Camera3D.KEEP_HEIGHT
	view3d.add_child(source_camera);source_camera.current=true
	var world_environment:=WorldEnvironment.new()
	source_environment=Environment.new();source_environment.background_mode=Environment.BG_COLOR
	source_environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	source_environment.ambient_light_color=Color("b7caba");source_environment.ambient_light_energy=2.0/PI
	source_environment.tonemap_mode=Environment.TONE_MAPPER_ACES
	source_environment.fog_mode=Environment.FOG_MODE_DEPTH
	source_environment.fog_light_color=Color("dce6df")
	source_environment.fog_depth_begin=38
	source_environment.fog_depth_end=105
	source_environment.fog_depth_curve=1
	world_environment.environment=source_environment;view3d.add_child(world_environment)
	source_sun=_light("ffecd3",2.4,Vector3(8,14,7),Vector3(0,1.2,-8))
	source_fill=_light("b3d7e8",.38,Vector3(-9,6,-7),Vector3.ZERO)
	source_portrait=_light("ffd7ba",.46,Vector3(0,4.5,-8),Vector3.ZERO)
	_light("d7e9ff",.34,Vector3(-4,9,11),Vector3.ZERO)
	surface=TextureRect.new();surface.name="Native3DSourceFilm";surface.texture=view3d.get_texture()
	surface.size=LOGICAL_SIZE;surface.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	surface.mouse_filter=Control.MOUSE_FILTER_IGNORE;film.add_child(surface)
	pause_cover=ColorRect.new();pause_cover.color=Color(.025,.05,.07,.56);pause_cover.size=LOGICAL_SIZE
	pause_cover.mouse_filter=Control.MOUSE_FILTER_IGNORE;film.add_child(pause_cover);pause_cover.hide()
	ready3d=true
	_redraw()

func _register_source_node(node: Node) -> void:
	source_nodes[str(node.name)]=node
	# Keep the authored source geometry at its original detail level.
	if node is GeometryInstance3D:node.lod_bias=1000000.0
	if node is Skeleton3D:
		for bone: int in range(node.get_bone_count()):source_bones[node.get_bone_name(bone)]={"skeleton":node,"bone":bone}
	for child: Node in node.get_children():_register_source_node(child)

## Godot LIGHT_COLOR includes energy*PI; Three directional irradiance does not.
## https://docs.godotengine.org/en/4.4/tutorials/shaders/shader_reference/spatial_shader.html
func _light(hex: String,energy: float,point: Vector3,target: Vector3) -> DirectionalLight3D:
	var light:=DirectionalLight3D.new();light.light_color=Color(hex);light.light_energy=energy/PI
	view3d.add_child(light);light.position=point;light.look_at(target,Vector3.UP)
	light.shadow_enabled=false
	return light

func _redraw() -> void:
	super._redraw()
	if source_animation==null or stage.is_empty():return
	render_source_frame(stage,frame)
	pause_cover.visible=paused

## The sampled timeline is frame-indexed exactly like the source overlay. No
## elapsed simulation value, collision or controller proof enters this renderer.
func render_source_frame(which: String,at: int) -> void:
	if source_animation==null or not source_manifest.stages.has(which):return
	var index: int=clampi(at,0,source_manifest.stages[which].size()-1)
	if which==_active_clip and index==_rendered_frame:return
	# Frame-indexed source transforms avoid GLTF importer's 30fps resampling and
	# track reduction. This is the exact authored 24fps pose table, not a new IK.
	for i: int in range(source_poses.dynamic.size()):
		var node: Node=source_nodes.get(source_poses.dynamic[i])
		if not node is Node3D:continue
		var v: Array=source_poses.stages[which].local[index][i]
		node.transform=Transform3D(Basis(Quaternion(v[3],v[4],v[5],v[6])).scaled(Vector3(v[7],v[8],v[9])),Vector3(v[0],v[1],v[2]))
	for i: int in range(source_poses.bones.size()):
		var name: String=source_poses.bones[i].name
		var entry: Dictionary=source_bones[name]
		var world_pose: Transform3D=_source_matrix(source_poses.stages[which].boneWorld[index][i])*bone_corrections[name]
		entry.skeleton.set_bone_global_pose(entry.bone,entry.skeleton.global_transform.affine_inverse()*world_pose)
	_active_clip=which
	var sample: Dictionary=source_manifest.stages[which][index]
	for i: int in range(source_manifest.nodes.size()):
		var name: String=source_manifest.nodes[i].name
		var node: Node=source_nodes.get(name)
		if node is Node3D and not node is Light3D:node.visible=bool(sample.visible[i])
	var p: Array=sample.cameraPosition;var q: Array=sample.cameraQuaternion
	source_camera.position=Vector3(p[0],p[1],p[2])
	source_camera.quaternion=Quaternion(q[0],q[1],q[2],q[3])
	source_camera.fov=float(sample.cameraFov)
	source_environment.background_color=Color.hex((int(sample.background)<<8)|255)
	source_environment.tonemap_exposure=float(sample.exposure)
	var macro: bool=str(sample.camera) in ["grip_pedal_macro","brake_wheel_macro"]
	source_environment.fog_enabled=not macro
	source_sun.light_energy=(1.8 if macro else 2.4)/PI
	source_fill.light_energy=(.68 if macro else .38)/PI
	source_portrait.light_energy=(.66 if macro else .46)/PI
	_rendered_frame=index
	view3d.render_target_update_mode=SubViewport.UPDATE_ONCE

func draw_film(_canvas: CanvasItem) -> void:
	# The viewport texture owns all scene pixels. Never show the former 2D rig.
	pass

func source_world_transform(name: String) -> Transform3D:
	var index: int=int(source_manifest.referenceNodes.get(name,-1))
	if index<0:return Transform3D.IDENTITY
	var id: String="source_%05d"%index
	if source_bones.has(id):
		var entry: Dictionary=source_bones[id]
		return entry.skeleton.global_transform*entry.skeleton.get_bone_global_pose(entry.bone)*bone_corrections.get(id,Transform3D.IDENTITY).affine_inverse()
	var node: Node=source_nodes.get(id)
	return node.global_transform if node is Node3D else Transform3D.IDENTITY

static func _source_matrix(v: Array) -> Transform3D:
	return Transform3D(Basis(Vector3(v[0],v[1],v[2]),Vector3(v[4],v[5],v[6]),Vector3(v[8],v[9],v[10])),Vector3(v[12],v[13],v[14]))

func dispose() -> void:
	if view3d!=null:view3d.render_target_update_mode=SubViewport.UPDATE_DISABLED
	super.dispose()

func release_render_world() -> void:
	if is_instance_valid(view3d):
		view3d.render_target_update_mode=SubViewport.UPDATE_DISABLED
		view3d.queue_free()
	view3d=null;source_animation=null;source_root=null
	source_nodes.clear();source_bones.clear();bone_corrections.clear()

func play(next_stage: String,retry: bool=false,reduce: bool=false) -> bool:
	if not ready3d:
		stage=next_stage;status="failed";show();_layout()
		caption.text="动画资源未能载入，可退出后重试。已保存的进度保持不变。"
		pause_button.disabled=true;skip_button.disabled=true
		return false
	return super.play(next_stage,retry,reduce)

func cancel() -> void:
	if status=="failed":status="cancelled";hide();cancelled.emit(stage)
	else:super.cancel()
