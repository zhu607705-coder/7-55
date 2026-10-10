extends Control
## Original source meshes/IK/world coordinates rendered by native Godot.
## This view consumes model state only. It never updates simulation or progression.
signal presentation_ready
signal presentation_failed(reason: String)

const Rider=preload("res://scripts/presentation/chase3d/source_rider.gd")
const MaterialAdapter=preload("res://scripts/presentation/chase3d/source_material_adapter.gd")
var material_adapter:=MaterialAdapter.new()
var source_materials: bool=true
const WORLD_PER_METER: float=1.05
const LANE_WIDTH: float=3.35
var asset_directory: String="res://assets/"
var view_paused: bool=false
var disposed: bool=false
var failure_reason: String=""
var presented: bool=false
var gameplay_active: bool=true
var fitted_size:=Vector2(960,540)
var viewport3d: SubViewport
var world: Node3D
var hero: Node3D
var camera: Camera3D
var environment: Environment
var sun: DirectionalLight3D
var surface: TextureRect
var manifest: Dictionary
var chunks: Dictionary={}
var obstacles: Dictionary={}
var stunt_objects: Dictionary={}
var pedestrians: Dictionary={}
var paper: Node3D
var bell: Node3D
var shield: Node3D
var bell_material: StandardMaterial3D
var clear_starts: Dictionary={}
var animation_seconds: float=0
var pedal_phase: float=0
var wheel_phase: float=0
var previous_distance: float=0
var previous_x: float=0
var previous_tick: int=0
var smoothed_velocity: float=0
var body_steer: float=0
var handlebar_steer: float=0
var body_roll: float=0
var reduced_motion: bool=false
var ready3d: bool=false
var enable_live_shadows: bool=false
var shadow_enabled_at_start: bool=false
var quality: String="high"
var measured_frames: int=0
var measured_frame_ms: float=0
var last_collisions: int=0
var collision_flash: float=0
var viewport_resolution:=Vector2i(960,540)

## Configure once before add_child. This API owns presentation only.
## Internal resolution remains16:9; the containing Control may have any size.
func configure(options: Dictionary={}) -> bool:
	if is_inside_tree() or disposed:return false
	asset_directory=str(options.get("asset_directory",asset_directory)).trim_suffix("/")+"/"
	reduced_motion=bool(options.get("reduced_motion",false))
	source_materials=bool(options.get("source_materials",true))
	enable_live_shadows=bool(options.get("live_shadows",true))
	var width: int=maxi(16,int(options.get("render_width",960)))
	viewport_resolution=Vector2i(width,maxi(9,roundi(width*9.0/16.0)))
	return true

func set_paused(value: bool) -> void:
	view_paused=value
	if value and is_instance_valid(viewport3d):viewport3d.render_target_update_mode=SubViewport.UPDATE_DISABLED

## Call once after the host updates the model. elapsed is the presentation delta
## from the same frame, in seconds. No internal timer advances the scene.
func update_view(model: RefCounted,elapsed: float,paused: bool=false,started: bool=true) -> void:
	gameplay_active=started
	set_paused(paused)
	if disposed or not ready3d or (view_paused and presented):return
	render_model(model,elapsed,view_paused)

func dispose() -> void:
	if disposed:return
	disposed=true;ready3d=false
	if is_instance_valid(viewport3d):viewport3d.render_target_update_mode=SubViewport.UPDATE_DISABLED
	queue_free()

func _fail(reason: String) -> void:
	failure_reason=reason;ready3d=false
	presentation_failed.emit(reason)
	push_error(reason)

func _preflight() -> bool:
	var manifest_path: String=asset_directory+"source_manifest.json"
	if not FileAccess.file_exists(manifest_path):_fail("Missing original3D source manifest: "+manifest_path);return false
	var data: Variant=JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
	if not data is Dictionary or not data.has("world_chunks") or not data.has("assets") or not data.has("pedestrians"):
		_fail("Invalid original3D source manifest: "+manifest_path);return false
	manifest=data
	var required: Array[String]=["rider_geometry.scn","rider_pose_manifest.json","rider_bone_poses.bin","rider_local_poses.bin","paper.scn","fx_bellRing.scn","fx_trayShield.scn","stunt_ramp.scn","stunt_tray.scn","stunt_gust.scn"]
	for kind: String in ["cone","barrier","car","bicycle","runner","crowd"]:required.append("hazard_"+kind+".scn")
	for entry: Dictionary in manifest.world_chunks:required.append(entry.asset+".scn")
	for entry: Dictionary in manifest.pedestrians:
		if not entry.has("asset"):_fail("Missing original3D actor binding: "+str(entry.id));return false
		for suffix: String in ["_geometry.scn","_pose_manifest.json","_bone_poses.bin","_local_poses.bin"]:required.append(entry.asset+suffix)
	for path: String in required:
		if not FileAccess.file_exists(asset_directory+path):_fail("Missing original3D asset: "+asset_directory+path);return false
	return true

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	if not _preflight():return
	viewport3d=SubViewport.new();viewport3d.name="NativeSourceChase3D";viewport3d.own_world_3d=true;viewport3d.size=viewport_resolution
	viewport3d.msaa_3d=Viewport.MSAA_2X;viewport3d.render_target_update_mode=SubViewport.UPDATE_DISABLED;add_child(viewport3d)
	world=Node3D.new();world.name="SourceWorld";viewport3d.add_child(world)
	hero=Rider.new();hero.asset_directory=asset_directory;hero.name="SourceRider";world.add_child(hero)
	if source_materials:material_adapter.adapt_scene(hero)
	camera=Camera3D.new();camera.keep_aspect=Camera3D.KEEP_HEIGHT;camera.near=.1;camera.far=150;camera.fov=51;world.add_child(camera);camera.current=true
	var env:=WorldEnvironment.new();environment=Environment.new();environment.background_mode=Environment.BG_COLOR;environment.background_color=Color("c4dfe4")
	environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;environment.ambient_light_color=Color("b7caba");environment.ambient_light_energy=2.0/PI
	environment.tonemap_mode=Environment.TONE_MAPPER_ACES;environment.tonemap_exposure=1.02
	environment.fog_enabled=true;environment.fog_mode=Environment.FOG_MODE_DEPTH;environment.fog_light_color=Color("d6e4df");environment.fog_depth_begin=45;environment.fog_depth_end=120;environment.fog_depth_curve=1
	env.environment=environment;world.add_child(env)
	sun=_light("ffecd3",2.4,Vector3(7,15,6),Vector3.ZERO)
	sun.shadow_enabled=enable_live_shadows;shadow_enabled_at_start=enable_live_shadows
	_set_hero_shadow(not enable_live_shadows)
	_light("a7d2e4",.38,Vector3(-8,7,-8),Vector3.ZERO)
	_light("ffd7ba",.28,Vector3(0,4.5,-8),Vector3.ZERO)
	paper=_asset("paper");world.add_child(paper)
	bell=_asset("fx_bellRing");world.add_child(bell)
	bell_material=_instance_effect_material(bell)
	shield=_asset("fx_trayShield");world.add_child(shield);_instance_effect_material(shield)
	surface=TextureRect.new();surface.texture=viewport3d.get_texture();surface.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;surface.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;surface.mouse_filter=Control.MOUSE_FILTER_IGNORE;surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(surface)
	ready3d=true
	presentation_ready.emit()

func _light(color: String,energy: float,point: Vector3,target: Vector3) -> DirectionalLight3D:
	var light:=DirectionalLight3D.new();light.light_color=Color(color);light.light_energy=energy/PI;light.shadow_enabled=false;world.add_child(light);light.position=point;light.look_at(target);return light

func _asset(id: String) -> Node3D:
	var result: Node3D=load(asset_directory+id+".scn").instantiate()
	for light: Light3D in result.find_children("*","Light3D",true,false):light.light_energy/=PI
	if manifest.assets.has(id):
		for record: Dictionary in manifest.assets[id].get("nodes",[]):
			if not record.has("worldMinZ"):continue
			var mesh: Node=result.find_child(record.name,true,false)
			if mesh!=null:mesh.set_meta("source_min_z",record.worldMinZ);mesh.set_meta("source_max_z",record.worldMaxZ)
	if source_materials:material_adapter.adapt_scene(result)
	return result

func _instance_effect_material(effect: Node3D) -> StandardMaterial3D:
	var mesh: MeshInstance3D=effect if effect is MeshInstance3D else effect.find_children("*","MeshInstance3D",true,false)[0]
	var material: StandardMaterial3D=mesh.get_active_material(0).duplicate()
	material.depth_draw_mode=BaseMaterial3D.DEPTH_DRAW_DISABLED
	mesh.material_override=material
	return material

func reset_view() -> void:
	if not ready3d or disposed:return
	presented=false;view_paused=false
	animation_seconds=0;pedal_phase=0;wheel_phase=0;previous_distance=0;previous_x=0;previous_tick=0;smoothed_velocity=0;body_steer=0;handlebar_steer=0;body_roll=0;clear_starts.clear();last_collisions=0;collision_flash=0
	camera.position=Vector3.ZERO;camera.fov=51
	for node: Node in obstacles.values():node.queue_free()
	for node: Node in stunt_objects.values():node.queue_free()
	obstacles.clear();stunt_objects.clear()
	for node: Node in pedestrians.values():node.queue_free()
	pedestrians.clear()

func response(rate: float,delta: float) -> float:return 1-exp(-rate*maxf(0,delta))

func render_model(model: RefCounted,delta: float=-1,paused: bool=false) -> void:
	if disposed or not ready3d or model==null or (paused and presented):return
	if model.tick<previous_tick or model.distance<previous_distance:reset_view()
	var dt: float=clampf((model.tick-previous_tick)/120.0 if delta<0 else delta,0,.25)
	if paused:dt=0
	if gameplay_active and not paused and model.status=="running" and not reduced_motion:animation_seconds+=dt
	var z: float=-model.distance*WORLD_PER_METER;var x: float=(model.lane-1)*LANE_WIDTH
	_update_chunks(z)
	var lane_velocity: float=(x-previous_x)/dt if dt>0 else 0
	previous_x=x
	if reduced_motion:smoothed_velocity=0;body_steer=0
	else:
		smoothed_velocity=lerpf(smoothed_velocity,lane_velocity,response(14,dt))
		body_steer=lerpf(body_steer,clampf(-smoothed_velocity*.032,-.28,.28),response(12,dt))
	handlebar_steer=lerpf(handlebar_steer,body_steer*1.1,response(16,dt))
	body_roll=lerpf(body_roll,body_steer*.45,response(12,dt))
	var wheel_delta: float=maxf(0,model.distance-previous_distance)*WORLD_PER_METER/(.5*1.28)
	wheel_phase-=wheel_delta
	if not reduced_motion and not paused:pedal_phase+=wheel_delta/2.2
	var bob: float=0 if reduced_motion else .008*(.5-cos(pedal_phase*2)*.5)
	hero.position=Vector3(x,.08+bob+model.air_height,z)
	hero.rotation=Vector3(-.12 if model.air_height>.05 else model.charge*.06,0,body_roll)
	hero.apply_pose(handlebar_steer,0 if reduced_motion else pedal_phase);hero.spin_wheels(wheel_phase)
	_update_obstacles(model);_update_stunts(model);_update_pedestrians(model.distance)
	if enable_live_shadows:
		sun.position=Vector3(7,15,z+8);sun.look_at(Vector3(x*.18,1.15,z-10),Vector3.UP)
	paper.position=Vector3((model.paper_lane-1)*3.4,3.25+sin(animation_seconds*5.2)*.28,z-model.paper_gap)
	paper.rotation=Vector3(0,sin(animation_seconds*3.1)*.3,sin(animation_seconds*4.4)*.12)
	var camera_ease: float=1 if reduced_motion else response(5.5,dt)
	camera.position.x=lerpf(camera.position.x,x*.34+1.7,camera_ease)
	var progress: float=clampf((model.distance+70)/755,0,1)
	var target_fov: float=53 if reduced_motion else 53+progress*5+(7 if model.boost>0 else 0)
	camera.fov=lerpf(camera.fov,target_fov,camera_ease)
	var camera_bob: float=0 if reduced_motion else sin(animation_seconds*(7+progress*3))*.012
	camera.position=Vector3(camera.position.x,3.85+camera_bob+model.air_height*.35,z+8.1)
	camera.look_at(Vector3(x*.46,1.1,z-13.5),Vector3.UP)
	if model.collisions>last_collisions:collision_flash=.22
	collision_flash=maxf(0,collision_flash-dt);last_collisions=model.collisions
	environment.background_color=Color("b86868") if collision_flash>0 else Color("c4dfe4")
	previous_distance=model.distance;previous_tick=model.tick
	presented=true
	viewport3d.render_target_update_mode=SubViewport.UPDATE_ONCE

func _update_chunks(z: float) -> void:
	var keep: Dictionary={}
	for entry: Dictionary in manifest.world_chunks:
		var ahead: float=65 if quality=="light" else (85 if quality=="balanced" else 115)
		var active: bool=entry.shared or (entry.max_z>=z-ahead and entry.min_z<=z+20)
		if not active:continue
		keep[entry.asset]=true
		if not chunks.has(entry.asset):var node: Node3D=_asset(entry.asset);world.add_child(node);chunks[entry.asset]=node
		for mesh: MeshInstance3D in chunks[entry.asset].find_children("*","MeshInstance3D",true,false):
			if mesh.has_meta("source_min_z"):mesh.visible=float(mesh.get_meta("source_max_z"))>=z-ahead and float(mesh.get_meta("source_min_z"))<=z+20
	for id: String in chunks.keys():
		if not keep.has(id):chunks[id].queue_free();chunks.erase(id)

func _update_obstacles(model: RefCounted) -> void:
	var active: Dictionary={}
	for obstacle: Dictionary in model.obstacles:
		var ahead: float=obstacle.distance-model.distance
		if ahead<=0 or ahead>96:continue
		active[obstacle.id]=true
		if not obstacles.has(obstacle.id):var node: Node3D=_asset("hazard_"+obstacle.kind);world.add_child(node);obstacles[obstacle.id]=node
		var node: Node3D=obstacles[obstacle.id];var x: float=(obstacle.lane-1)*LANE_WIDTH
		if obstacle.kind=="runner":
			var p: float=clampf((1-ahead/96-.28)/.68,0,1);p=p*p*(3-2*p)
			x=lerpf(-7.2 if obstacle.side<0 else 7.2,(obstacle.lane-1)*LANE_WIDTH,p)
			node.rotation.y=-PI/2 if obstacle.side<0 else PI/2;node.position.y=absf(sin(animation_seconds*10))*.05
		node.position.x=x;node.position.z=-obstacle.distance*WORLD_PER_METER
		if model.cleared.has(obstacle.id):
			if not clear_starts.has(obstacle.id):clear_starts[obstacle.id]=animation_seconds
			var p: float=1 if reduced_motion else clampf((animation_seconds-clear_starts[obstacle.id])/.55,0,1)
			node.position.x+=(-1 if obstacle.lane<1 else 1)*p*6;node.rotation.z=p*(.45 if obstacle.lane<1 else -.45);node.visible=p<1
		else:node.visible=true;node.rotation.z=0
	for id: String in obstacles.keys():
		if not active.has(id):obstacles[id].queue_free();obstacles.erase(id)

func _update_stunts(model: RefCounted) -> void:
	var active: Dictionary={}
	for ramp: Dictionary in manifest.ramps:
		if ramp.distance<model.distance-8 or ramp.distance>model.distance+100:continue
		active[ramp.id]=true
		if not stunt_objects.has(ramp.id):var node: Node3D=_asset("stunt_ramp");world.add_child(node);stunt_objects[ramp.id]=node
		stunt_objects[ramp.id].position=Vector3((ramp.lane-1)*LANE_WIDTH,.01,-ramp.distance*WORLD_PER_METER)
	for i: int in range(manifest.pickups.size()):
		var item: Dictionary=manifest.pickups[i]
		if item.distance<model.distance-3 or item.distance>model.distance+100 or model.collected.has(i):continue
		active[item.id]=true
		if not stunt_objects.has(item.id):var node: Node3D=_asset("stunt_"+item.kind);world.add_child(node);stunt_objects[item.id]=node
		stunt_objects[item.id].position=Vector3((item.lane-1)*LANE_WIDTH,1.6+sin(animation_seconds*3)*.16,-item.distance*WORLD_PER_METER);stunt_objects[item.id].rotation.y=animation_seconds*1.3
	for id: String in stunt_objects.keys():
		if not active.has(id):stunt_objects[id].queue_free();stunt_objects.erase(id)
	bell.visible=model.bell_pulse>0;bell.position=Vector3(hero.position.x,.14,hero.position.z-3);bell.scale=Vector3.ONE*(1+(1-model.bell_pulse)*10)
	bell_material.albedo_color=Color("fbe5a2",model.bell_pulse*.72)
	shield.visible=model.shield;shield.position=hero.position+Vector3(0,1.3,0);shield.rotation.y=animation_seconds*1.7

func _update_pedestrians(distance: float) -> void:
	var active: Dictionary={}
	for entry: Dictionary in manifest.pedestrians:
		if not entry.has("asset"):continue
		var ahead: float=entry.distance-distance
		if ahead<=0 or ahead>96:continue
		active[entry.id]=true
		if not pedestrians.has(entry.id):
			var person:=Rider.new();person.asset_directory=asset_directory;person.asset_prefix=entry.asset;world.add_child(person);pedestrians[entry.id]=person
			if source_materials:material_adapter.adapt_scene(person)
		var person: Node3D=pedestrians[entry.id]
		var direction: int=-1 if (int(entry.seed)&1)==0 else 1
		var walk_phase: float=fposmod(animation_seconds*.68+entry.phase*1.9+(int(entry.seed)%13)*.17,3.8)
		person.position=Vector3(entry.side*(6.45+entry.laneOffset*1.45),.04,-entry.distance*WORLD_PER_METER+(walk_phase-1.9)*direction)
		person.rotation.y=0 if direction<0 else PI
		var clip_time: float=0 if reduced_motion else animation_seconds+entry.phase*PI/5.7
		person.apply_pose(0,fposmod(clip_time,entry.walk_duration)/entry.walk_duration*TAU,reduced_motion)
	for id: String in pedestrians.keys():
		if not active.has(id):pedestrians[id].queue_free();pedestrians.erase(id)

func _set_hero_shadow(visible_shadow: bool) -> void:
	for record: Dictionary in hero.manifest.nodes:
		if record.original=="canteen-chase-rider-shadow" and hero.nodes.has(record.name):hero.nodes[record.name].visible=visible_shadow

## Caller may submit measured renderer time; these are the original source's
##24-frame thresholds, clipping distances and fallback shadow policy.
func observe_frame_time(milliseconds: float) -> void:
	if milliseconds<=0 or milliseconds>1000 or measured_frames>=50:return
	measured_frames+=1;measured_frame_ms+=milliseconds
	if measured_frames!=24:return
	var mean: float=measured_frame_ms/measured_frames
	quality="light" if mean>65 else ("balanced" if mean>34 else "high")
	if quality=="high":return
	enable_live_shadows=false;sun.shadow_enabled=false;_set_hero_shadow(true)
	camera.far=92 if quality=="light" else 115
	environment.fog_depth_begin=34;environment.fog_depth_end=camera.far-4
	fit_resolution(fitted_size)

## Source handleResize clamps CSS width to480..960, at a native pixel ratio of1.
## Geometry, camera aspect and source16:9 composition do not change on rotation.
func fit_resolution(available: Vector2) -> void:
	fitted_size=available
	var fitted: float=minf(available.x,available.y*16.0/9.0)
	var width: int=clampi(roundi(fitted),480,960)
	# Original source light tier uses pixelRatio .78 after CSS-size clamp.
	var ratio: float=.78 if quality=="light" else 1.0
	var next_size:=Vector2i(roundi(width*ratio),roundi(width*9.0/16.0*ratio))
	if viewport_resolution==next_size:return
	viewport_resolution=next_size
	if is_instance_valid(viewport3d):viewport3d.size=next_size;presented=false
