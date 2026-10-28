extends SceneTree
## Headless geometry/light verification. This does not substitute for pixel review.
const World=preload("res://scripts/raking_world.gd")
const Model=preload("res://scripts/raking_model.gd")
var checks:=0
var failures:=0

func _initialize() -> void: call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error("TEST FAILED: "+label)
	else: print("PASS ",label)

func make_world(recorded: bool) -> Node3D:
	var viewport:=SubViewport.new(); viewport.size=Vector2i(390,600); viewport.own_world_3d=true
	root.add_child(viewport)
	var world=World.new(); viewport.add_child(world); world.setup(recorded)
	world.configure_camera(Vector2(390,600),recorded)
	return world

func run() -> void:
	var current=make_world(false)
	var history=make_world(true)
	await process_frame
	current.update_scene(Vector2.ZERO,28,55,0,false)
	history.update_scene(Vector2(8,-7),-35,15,0,false)
	check(current.get_world_3d()!=history.get_world_3d(),"Recorded and current geometry live in separate World3D instances")
	check(current.paper.mesh!=history.paper.mesh and current.paper.material_override!=history.paper.material_override and current.lamp!=history.lamp,"History shares no mutable mesh, material or light with the current scene")
	var transform: Transform3D=current.paper_pivot.transform
	var lamp_pose: Transform3D=current.lamp.global_transform
	history.update_scene(Vector2(14,11),100,25,1,true,0.1)
	check(current.paper_pivot.transform==transform and current.lamp.global_transform==lamp_pose,"Changing a recorded world cannot write current paper or light")
	check(current.camera.projection==Camera3D.PROJECTION_ORTHOGONAL,"Existing orthographic projection is preserved")
	var back: Vector3=current.camera.global_basis.z
	check(absf(rad_to_deg(asin(back.y))-50)<0.01,"Camera elevation is the approved 50 degrees")
	check(absf(rad_to_deg(atan2(current.camera.global_basis.x.z,current.camera.global_basis.x.x))+8)<0.01,"Camera yaw is the approved 8 degrees")
	var arrays: Array=current.paper.mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
	var min_y:=0.0; var max_y:=-1.0; var varying_normals:=false
	for i: int in range(vertices.size()):
		min_y=minf(min_y,vertices[i].y); max_y=maxf(max_y,vertices[i].y)
		if normals[i].dot(Vector3.UP)<0.97: varying_normals=true
	check(vertices.size()>1000 and min_y<-0.01 and absf(max_y)<0.001,"Paper contains real shallow depressed vertices rather than a printed mark")
	check(varying_normals,"Depressed sides have genuinely varying surface normals")
	check(current.paper.material_override is StandardMaterial3D and current.paper.material_override.shading_mode!=BaseMaterial3D.SHADING_MODE_UNSHADED,"Paper is a physically lit material, not an unlit reveal layer")
	check(current.paper.material_override.albedo_texture==null,"The clue pattern is not hidden in a reveal texture")
	check(current.lamp is SpotLight3D and current.lamp.shadow_enabled,"Movable lamp is a real shadow-casting spotlight")
	var initial: Dictionary=current.visibility_metrics()
	check(initial.incidence>24,"Entry lamp is not already at a successful raking angle")
	var best: Dictionary={}; var best_pose:=Vector3.ZERO
	for azimuth: float in [-100,-60,-30,0,30,60,100]:
		for elevation: float in [8,12,16,20,24]:
			current.update_scene(Vector2(8,-7),azimuth,elevation,0,false)
			var visibility: Dictionary=current.visibility_metrics()
			if visibility.contrast>=0.13 and visibility.coverage>=0.72 and visibility.incidence>=3 and visibility.incidence<=24:
				best=visibility; best_pose=Vector3(azimuth,elevation,visibility.incidence)
	check(not best.is_empty(),"There is a physically valid lighting arrangement within reachable input limits")
	if not best.is_empty():
		current.update_scene(Vector2(8,-7),best_pose.x,best_pose.y,0,false)
		var model=Model.new(); model.start(0,"paper"); model.drag(0,Vector2(1,1)); model.release(0)
		model.start(1,"lamp"); model.drag(1,Vector2(1,1)); model.release(1)
		for frame: int in range(60): model.update(1.0/30.0,current.visibility_metrics())
		check(model.completed,"Actual mesh-normal and lamp coverage metrics can complete a stable local observation")
		current.lamp.light_energy=0
		var dark: Dictionary=current.visibility_metrics()
		check(dark.contrast==0 and dark.coverage==0,"Turning the physical lamp off invalidates completion evidence")
		current.lamp.light_energy=5.2
		current.lamp.visible=false
		check(current.visibility_metrics().coverage==0,"A hidden lamp cannot count as actual illumination")
		current.lamp.visible=true
	# The real paper must stay above its physical cradle throughout allowed motion.
	var minimum:=100.0
	for x: float in [-18,0,18]:
		for z: float in [-18,0,18]:
			current.update_scene(Vector2(x,z),28,15,0,false)
			for px: float in [-World.PAPER_SIZE.x*0.5,World.PAPER_SIZE.x*0.5]:
				for pz: float in [-World.PAPER_SIZE.y*0.5,World.PAPER_SIZE.y*0.5]:
					minimum=minf(minimum,current.paper_pivot.to_global(Vector3(px,-0.04,pz)).y)
	check(minimum>=0.30,"Paper underside does not penetrate the cradle throughout the allowed tilt range")
	print("RAKING_WORLD checks=",checks," failures=",failures," rendered_pixels=false valid_pose=",best_pose," metrics=",best)
	current.get_parent().queue_free(); history.get_parent().queue_free(); await process_frame
	quit(1 if failures else 0)
