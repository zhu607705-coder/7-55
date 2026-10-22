extends SceneTree
const View=preload("res://scripts/presentation/chase3d/source_chase_3d.gd")
const Model=preload("res://scripts/games/chase_stunt_model.gd")
var checks:=0
var failures:=0
func _initialize() -> void:run.call_deferred()
func check(value: bool,message: String) -> void:
	checks+=1
	if not value:failures+=1;push_error(message)
func model_snapshot(model: RefCounted) -> String:
	var value: Dictionary={}
	for property: Dictionary in model.get_property_list():
		if property.usage&PROPERTY_USAGE_SCRIPT_VARIABLE:value[property.name]=model.get(property.name)
	return JSON.stringify(value)
func run() -> void:
	var view:=View.new();view.asset_directory="res://assets/native_755/ride/";view.size=Vector2(960,540);root.add_child(view);await process_frame
	var model:=Model.new()
	for sample: Dictionary in view.manifest.camera_samples:
		model.distance=sample.distance
		var before:=model_snapshot(model)
		for i in range(90):view.render_model(model,1.0/60)
		check(model_snapshot(model)==before,"render and camera settling never mutate simulation")
		var point: Array=sample.position;var q: Array=sample.quaternion
		check(view.camera.position.distance_to(Vector3(point[0],point[1],point[2]))<.0001,"source camera position at "+str(sample.distance))
		check(absf(view.camera.fov-sample.fov)<.0001,"source camera FOV at "+str(sample.distance))
		check(view.camera.quaternion.angle_to(Quaternion(q[0],q[1],q[2],q[3]))<.001,"source camera orientation at "+str(sample.distance))
		var rear: Vector3=view.hero.reference_world("rearWheel").origin
		var front: Vector3=view.hero.reference_world("frontWheel").origin
		check(absf((rear.z-view.hero.position.z)/1.05-.72*1.28/1.05)<.0001,"rear wheel is behind model origin by source .878m")
		check(absf((front.z-view.hero.position.z)/1.05+.72*1.28/1.05)<.0001,"front wheel is ahead of model origin by source .878m")
		check(view.chunks.size()<11,"world uses bounded authored chunk streaming")
		await process_frame
	# Visibility follows source obstacle distance; native geometry never adds collision authority.
	view.reset_view();model=Model.new();model.distance=41.9;model.lane=2;model.tick=1
	view.render_model(model,1.0/60)
	check(view.obstacles.has("rush-0-2"),"source cone remains visible just before its42m contact plane")
	var cone: Node3D=view.obstacles["rush-0-2"]
	check(absf(cone.position.z-(-42*1.05))<.00001,"cone world origin matches authored collision distance")
	model.update(.03);view.render_model(model,.03)
	check(model.collisions==1 and model.lives==2,"unchanged source model alone registers crossing collision")
	check(not view.obstacles.has("rush-0-2"),"behind-plane obstacle retires using source visibility rule")
	view.queue_free();await process_frame
	print("SOURCE_WORLD_CAMERA_CONTACTS checks=",checks," failures=",failures);quit(1 if failures else 0)
