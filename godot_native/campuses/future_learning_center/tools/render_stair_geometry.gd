extends SceneTree
## Deterministic orthographic reference, used to constrain the raster art pass.
var stage:Node3D
var camera:Camera3D
var route:Array[Vector3]=[]
const COUNT:=12
const RUN:=.40
const RISE:=.14
func _initialize()->void:build.call_deferred()
func box(at:Vector3,size_value:Vector3,color:Color)->void:
	var node:=MeshInstance3D.new();var mesh:=BoxMesh.new();mesh.size=size_value;node.mesh=mesh
	var mat:=StandardMaterial3D.new();mat.albedo_color=color;mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;mat.roughness=.95;node.material_override=mat
	stage.add_child(node);node.position=at
func beam(a:Vector3,b:Vector3,thickness:float)->void:
	var node:=MeshInstance3D.new();var mesh:=BoxMesh.new();mesh.size=Vector3(thickness,thickness,a.distance_to(b));node.mesh=mesh
	var mat:=StandardMaterial3D.new();mat.albedo_color=Color("a9ada8");mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;node.material_override=mat
	stage.add_child(node);node.position=(a+b)/2;node.look_at(b,Vector3.UP)
func rail(a:Vector3,b:Vector3)->void:
	beam(a+Vector3.UP*.86,b+Vector3.UP*.86,.045)
	for i:int in 13:
		var at:Vector3=a.lerp(b,i/12.0);box(at+Vector3.UP*.42,Vector3(.027,.84,.027),Color("a9ada8"))
func build()->void:
	stage=Node3D.new();root.add_child(stage)
	var world:=WorldEnvironment.new();world.environment=Environment.new();world.environment.background_mode=Environment.BG_COLOR;world.environment.background_color=Color("26313a");world.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;world.environment.ambient_light_color=Color("e8e0c8");world.environment.ambient_light_energy=.8;stage.add_child(world)
	var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-55,-30,0);sun.light_energy=.7;sun.shadow_enabled=true;stage.add_child(sun)
	# Lower west landing, east half landing and upper west landing.
	box(Vector3(-3.10,-.12,1.1),Vector3(1.4,.24,1.8),Color("aba9a3"))
	box(Vector3(3.10,COUNT*RISE-.12,0),Vector3(1.4,.24,4.0),Color("aba9a3"))
	box(Vector3(-3.10,COUNT*RISE*2-.12,-1.1),Vector3(1.4,.24,1.8),Color("aba9a3"))
	route.append(Vector3(-3.1,0,1.1));route.append(Vector3(-2.55,0,1.1))
	for i:int in COUNT:
		var x:float=-2.4+(i+.5)*RUN;var h:float=(i+1)*RISE
		box(Vector3(x,h-.11,1.1),Vector3(RUN,.22,1.8),Color("a39f98"))
		box(Vector3(x-RUN/2+.018,h+.004,1.1),Vector3(.036,.009,1.8),Color("7c7e7b"))
		route.append(Vector3(x,h,1.1))
	route.append(Vector3(2.65,COUNT*RISE,1.1));route.append(Vector3(3.1,COUNT*RISE,1.1));route.append(Vector3(3.1,COUNT*RISE,-1.1));route.append(Vector3(2.55,COUNT*RISE,-1.1))
	for i:int in COUNT:
		var x:float=2.4-(i+.5)*RUN;var h:float=COUNT*RISE+(i+1)*RISE
		box(Vector3(x,h-.11,-1.1),Vector3(RUN,.22,1.8),Color("a39f98"))
		box(Vector3(x+RUN/2-.018,h+.004,-1.1),Vector3(.036,.009,1.8),Color("7c7e7b"))
		route.append(Vector3(x,h,-1.1))
	route.append(Vector3(-2.65,COUNT*RISE*2,-1.1));route.append(Vector3(-3.1,COUNT*RISE*2,-1.1))
	# Plain rear wall and gray-framed window, lower front wall cut away.
	box(Vector3(0,2.25,-2.17),Vector3(7.8,4.5,.18),Color("e8e0c8"))
	box(Vector3(.1,3.65,-2.055),Vector3(3.1,1.4,.06),Color("344452"))
	box(Vector3(.1,3.65,-2.01),Vector3(2.92,1.23,.03),Color("54717b"))
	for x:float in [-1.36,.1,1.56]:box(Vector3(x,3.65,-1.98),Vector3(.045,1.23,.035),Color("a6aaa5"))
	box(Vector3(.1,3.65,-1.98),Vector3(2.92,.045,.035),Color("a6aaa5"))
	rail(Vector3(-2.4,RISE,.2),Vector3(2.4,COUNT*RISE,.2))
	rail(Vector3(2.4,COUNT*RISE+RISE,-.2),Vector3(-2.4,COUNT*RISE*2,-.2))
	rail(Vector3(3.7,COUNT*RISE,-1.95),Vector3(3.7,COUNT*RISE,1.95))
	rail(Vector3(-3.7,COUNT*RISE*2,-1.95),Vector3(-3.7,COUNT*RISE*2,-.22))
	camera=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=12.8;camera.keep_aspect=Camera3D.KEEP_WIDTH;stage.add_child(camera);camera.position=Vector3(0,13,12);camera.look_at(Vector3(0,1.8,0));camera.current=true
	for i:int in 8:await process_frame
	await RenderingServer.frame_post_draw
	var out:=OS.get_environment("FLC_GEOMETRY_DIR");DirAccess.make_dir_recursive_absolute(out)
	root.get_texture().get_image().save_png(out.path_join("stairs_orthographic_geometry.png"))
	var points:Array=[]
	for p:Vector3 in route:
		var q:=camera.unproject_position(p);points.append([q.x,q.y])
	var file:=FileAccess.open(out.path_join("stairs_geometry.json"),FileAccess.WRITE);file.store_string(JSON.stringify({"size":[root.size.x,root.size.y],"path":points,"stepsPerFlight":COUNT,"rise":RISE,"run":RUN,"projection":"orthogonal; no yaw; fixed scale"},"  "));file.close();quit()
