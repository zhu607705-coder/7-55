extends "res://scripts/presentation/chase_transition_clock.gd"
## Native 3D playback of original source geometry and sampled IK/bone transforms.
## Clock/ownership/UI come from the separately tested presentation-only base.
## This is not a browser wrapper: Godot renders the original GLB-based mesh scene.
const MaterialAdapter=preload("res://scripts/presentation/chase3d/source_material_adapter.gd")
const CampusEnvironment=preload("res://scripts/presentation/chase3d/zijingang_campus_environment.gd")
var campus_scenery: Dictionary={}
const RiderActions=preload("res://scripts/presentation/chase3d/campus_rider_actions.gd")
var rider_actions:=RiderActions.new()
var action_pose: Dictionary={}
const CampusHuman=preload("res://scripts/presentation/chase3d/campus_human_rig.gd")
const CampusPelican=preload("res://scripts/presentation/chase3d/campus_pelican_rig.gd")
const FinePixel=preload("res://scripts/presentation/chase3d/fine_pixel_style.gd")
const FeatherTransition=preload("res://scripts/presentation/chase3d/pelican_transform.gd")
var pelican_enabled: bool=true
var feather_transition: Control
var campus_human: Node3D
var rider_saddle: MeshInstance3D
var rider_bicycle: Node3D
var source_hip_height_range:=Vector2.ZERO
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
var _rendered_fraction: float=-1

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
	view3d.msaa_3d=Viewport.MSAA_DISABLED if pelican_enabled and not validation_reference else Viewport.MSAA_4X
	add_child(view3d)
	source_root=packed.instantiate();source_root.physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF;view3d.add_child(source_root)
	_register_source_node(source_root)
	material_adapter.adapt_scene(source_root)
	for camera: Camera3D in source_root.find_children("*","Camera3D",true,false):camera.current=false
	for light: Light3D in source_root.find_children("*","Light3D",true,false):light.hide()
	if not validation_reference:
		var builder:=CampusEnvironment.new()
		for clip: String in ["start","finish"]:
			var scenery: Node3D=builder.build_transition(clip);view3d.add_child(scenery);scenery.hide();campus_scenery[clip]=scenery
		builder.free()
		campus_human=CampusPelican.new() if pelican_enabled else CampusHuman.new()
		campus_human.name="CampusPelican" if pelican_enabled else "CampusHuman";view3d.add_child(campus_human)
	source_animation=source_root.find_children("*","AnimationPlayer",true,false)[0]
	source_animation.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	# Godot may normalize imported bone axes. Preserve that fixed bind-space
	# mapping while using the original source IK world matrices for every frame.
	for i: int in range(source_poses.bones.size()):
		var name: String=source_poses.bones[i].name
		var entry: Dictionary=source_bones[name]
		var native: Transform3D=entry.skeleton.global_transform*entry.skeleton.get_bone_global_pose(entry.bone)
		bone_corrections[name]=_source_matrix(source_poses.stages.start.boneWorld[0][i]).affine_inverse()*native
		if str(source_poses.bones[i].originalName)=="Hips":
			source_hip_height_range=Vector2(float(source_poses.stages.start.boneWorld[0][i][13]),float(source_poses.stages.start.boneWorld[40][i][13]))
	if not validation_reference:
		var full_manifest: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/derived/chase_transition_3d/source_transition.json"))
		var player_root: Node3D
		for record: Dictionary in full_manifest.nodes:
			if str(record.originalName)=="canteen-chase-player":player_root=source_nodes.get(record.name);break
		for record: Dictionary in full_manifest.nodes:
			if str(record.originalName)!="canteen-chase-shaped-saddle":continue
			var candidate: Node=source_nodes.get(record.name)
			if player_root!=null and candidate is MeshInstance3D and player_root.is_ancestor_of(candidate):rider_saddle=candidate;break
		rider_actions.configure(source_poses,str(player_root.name))
		for record: Dictionary in full_manifest.nodes:
			if str(record.originalName)!="canteen-chase-bicycle-root":continue
			var candidate: Node=source_nodes.get(record.name)
			if player_root.is_ancestor_of(candidate):rider_bicycle=candidate;break
		assert(rider_bicycle!=null,"Bike lean must rotate the entire authored bicycle")
		assert(rider_saddle!=null,"Rebuilt transition requires the actual rider saddle")
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
	if pelican_enabled and not validation_reference:
		FinePixel.apply(surface)
		feather_transition=FeatherTransition.new();feather_transition.name="PaperFeatherTransformation"
		film.add_child(feather_transition);feather_transition.configure(view3d,campus_human)
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

func saddle_world_top() -> Vector3:
	var bounds: AABB=rider_saddle.get_aabb()
	return rider_saddle.to_global(bounds.get_center()+Vector3(0,bounds.size.y*.5,0))

func source_frame_position(seconds: float) -> float:
	return seconds*FPS if validation_reference else RiderActions.source_frame(stage,seconds)

func source_frame_seconds(at: float) -> float:
	return at/FPS if validation_reference else RiderActions.seconds_at(stage,at)

func _redraw() -> void:
	super._redraw()
	if source_animation==null or stage.is_empty():return
	var fraction: float=0 if validation_reference or reduced_motion else clampf(source_frame_position(elapsed)-frame,0,1)
	render_source_frame(stage,frame,fraction)
	pause_cover.visible=paused

## The sampled timeline is frame-indexed exactly like the source overlay. No
## elapsed simulation value, collision or controller proof enters this renderer.
func render_source_frame(which: String,at: int,fraction: float=0) -> void:
	if source_animation==null or not source_manifest.stages.has(which):return
	var index: int=clampi(at,0,source_manifest.stages[which].size()-1)
	var next: int=mini(index+1,source_manifest.stages[which].size()-1)
	# Keep authored camera cuts; interpolate continuous shots at display cadence.
	var weight: float=clampf(fraction,0,1) if source_manifest.stages[which][index].camera==source_manifest.stages[which][next].camera else 0
	var motion_weight: float=0.0 if validation_reference else clampf(fraction,0,1)
	if which==_active_clip and index==_rendered_frame and is_equal_approx(motion_weight,_rendered_fraction):return
	# Frame-indexed source transforms avoid GLTF importer's 30fps resampling and
	# track reduction. This is the exact authored 24fps pose table, not a new IK.
	for i: int in range(source_poses.dynamic.size()):
		var node: Node=source_nodes.get(source_poses.dynamic[i])
		if not node is Node3D:continue
		var v: Array=source_poses.stages[which].local[index][i]
		var w: Array=source_poses.stages[which].local[next][i]
		var a:=Transform3D(Basis(Quaternion(v[3],v[4],v[5],v[6])).scaled(Vector3(v[7],v[8],v[9])),Vector3(v[0],v[1],v[2]))
		var b:=Transform3D(Basis(Quaternion(w[3],w[4],w[5],w[6])).scaled(Vector3(w[7],w[8],w[9])),Vector3(w[0],w[1],w[2]))
		node.transform=a.interpolate_with(b,motion_weight)
	for i: int in range(source_poses.bones.size()):
		var name: String=source_poses.bones[i].name
		var entry: Dictionary=source_bones[name]
		var world_pose: Transform3D=_source_matrix(source_poses.stages[which].boneWorld[index][i]).interpolate_with(_source_matrix(source_poses.stages[which].boneWorld[next][i]),motion_weight)*bone_corrections[name]
		entry.skeleton.set_bone_global_pose(entry.bone,entry.skeleton.global_transform.affine_inverse()*world_pose)
	_active_clip=which
	var sample: Dictionary=source_manifest.stages[which][index]
	for i: int in range(source_manifest.nodes.size()):
		var name: String=source_manifest.nodes[i].name
		var node: Node=source_nodes.get(name)
		if node is Node3D and not node is Light3D:node.visible=bool(sample.visible[i])
	if not validation_reference:
		for record: Dictionary in source_manifest.nodes:
			if str(record.originalName) in ["canteen-transition-start-world","canteen-transition-finish-world"]:
				var old_scenery: Node3D=source_nodes.get(record.name)
				if old_scenery!=null:old_scenery.hide()
		for clip: String in campus_scenery:campus_scenery[clip].visible=clip==which and str(sample.camera) not in ["grip_pedal_macro","brake_wheel_macro"]
		for node: Node in source_root.find_children("*","MeshInstance3D",true,false):
			# Imported human meshes carry Skin; bicycle and props are static meshes.
			if node.skin!=null:node.hide()
		# Lean the actual bike about its tyre contact plane before reading grips,
		# saddle and pedals. Parking follows its wheel direction instead of sliding.
		var source_at: float=index+motion_weight
		var bike_pose: Transform3D=rider_bicycle.global_transform
		var lean: float=RiderActions.bicycle_lean(which,source_at)
		var yaw: float=RiderActions.bicycle_yaw(source_at) if which=="finish" else 0
		var rotation_basis: Basis=Basis(Vector3.UP,yaw)*Basis(Vector3.BACK,lean)
		var pivot:=Vector3(bike_pose.origin.x,0,bike_pose.origin.z)
		rider_bicycle.global_transform=Transform3D(rotation_basis*bike_pose.basis,pivot+rotation_basis*(bike_pose.origin-pivot))
		if which=="finish" and source_at>=107:rider_bicycle.position.x=.55*smoothstep(107,112,source_at)
		var joints: Dictionary={}
		for id: String in ["Hips","Torso","Head"]:joints[id]=_original_bone_transform(id).origin
		joints.seat=saddle_world_top()
		joints.ride_blend=clampf(inverse_lerp(source_hip_height_range.x,source_hip_height_range.y,joints.Hips.y),0,1)
		for side: String in ["L","R"]:
			var hand: Vector3=source_world_transform("leftHandContact" if side=="L" else "rightHandContact").origin
			var grip: Vector3=source_world_transform("leftGripContact" if side=="L" else "rightGripContact").origin
			# Detached hand controls are not physical grip constraints while walking.
			joints["hand"+side]=grip if hand.distance_to(grip)<.005 else _original_bone_transform("Wrist"+side).origin
			joints["foot"+side]=source_world_transform("leftFootContact" if side=="L" else "rightFootContact").origin
		var grips: Dictionary={};var pedals: Dictionary={}
		for side: String in ["L","R"]:
			grips[side]=source_world_transform("leftGripContact" if side=="L" else "rightGripContact").origin
			pedals[side]=source_world_transform("leftPedalContact" if side=="L" else "rightPedalContact").origin
		action_pose=rider_actions.retarget(which,source_at,joints,grips,pedals)
		campus_human.apply_transition(action_pose)
	var p: Array=sample.cameraPosition;var q: Array=sample.cameraQuaternion
	var following: Dictionary=source_manifest.stages[which][next]
	var np: Array=following.cameraPosition;var nq: Array=following.cameraQuaternion
	source_camera.position=Vector3(p[0],p[1],p[2]).lerp(Vector3(np[0],np[1],np[2]),weight)
	source_camera.quaternion=Quaternion(q[0],q[1],q[2],q[3]).slerp(Quaternion(nq[0],nq[1],nq[2],nq[3]),weight)
	source_camera.fov=lerpf(float(sample.cameraFov),float(following.cameraFov),weight)
	source_environment.background_color=Color.hex((int(sample.background)<<8)|255)
	source_environment.tonemap_exposure=float(sample.exposure)
	var macro: bool=str(sample.camera) in ["grip_pedal_macro","brake_wheel_macro"]
	source_environment.fog_enabled=not macro
	source_sun.light_energy=(1.8 if macro else 2.4)/PI
	source_fill.light_energy=(.68 if macro else .38)/PI
	source_portrait.light_energy=(.66 if macro else .46)/PI
	if feather_transition!=null:feather_transition.update_pose(which,index+motion_weight,source_camera,reduced_motion,action_pose)
	_rendered_frame=index
	_rendered_fraction=motion_weight
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

func _original_bone_transform(original: String) -> Transform3D:
	for record: Dictionary in source_poses.bones:
		if record.originalName==original:
			var entry: Dictionary=source_bones[record.name]
			return entry.skeleton.global_transform*entry.skeleton.get_bone_global_pose(entry.bone)*bone_corrections[record.name].affine_inverse()
	return Transform3D.IDENTITY

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
	campus_scenery.clear()
	campus_human=null
	if is_instance_valid(feather_transition):
		feather_transition.hide();feather_transition.queue_free()
	feather_transition=null

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
