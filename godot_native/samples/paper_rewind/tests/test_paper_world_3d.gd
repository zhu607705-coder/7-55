extends SceneTree
const SCENE=preload("res://scenes/paper_rewind.tscn")
const WorldScene=preload("res://scripts/paper_world_3d.gd")
var checks:=0
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error(label)
	else: print("WORLD_3D_PASS ",label)
func run() -> void:
	var view: Control=SCENE.instantiate(); root.add_child(view)
	await process_frame
	view.set_process(false)
	for extent: Vector2i in [Vector2i(390,844),Vector2i(320,568),Vector2i(844,390)]:
		root.size=extent; view.size=extent; view._layout()
		await process_frame; await process_frame
		var stage: Control=view.stage
		for point: Vector3 in [Vector3.ZERO,Vector3(480,650,0),Vector3(300,500,180),Vector3(18,12,538),Vector3(1100,1110,-36)]:
			var actual: Vector2=stage.current_world.camera.unproject_position(WorldScene.space(point))
			check(actual.distance_to(stage.camera.project(point))<0.01,"Camera3D agrees with input projection at %s / %s"%[extent,point])
		var p: Vector2=stage.folder_leaf_rect().get_center()
		var ray_origin: Vector3=stage.current_world.camera.project_ray_origin(p)
		var ray_direction: Vector3=stage.current_world.camera.project_ray_normal(p)
		var hit: Vector3=ray_origin+ray_direction*((0.06-ray_origin.y)/ray_direction.y)
		check(hit.distance_to(WorldScene.space(stage.camera.unproject_plane(p,6)))<0.001,"Real camera ray equals exact folder plane inverse / %s"%extent)
	var stage: Control=view.stage
	check(stage.current_viewport.find_world_3d()!=stage.past_viewport.find_world_3d(),"Current and history have separate World3D")
	check(stage.current_world.paper!=stage.past_world.paper,"No mutable physical paper shared with history")
	check(stage.current_world.frame_materials[0]!=stage.past_world.frame_materials[0],"Mutable materials are isolated")
	var pose: Transform3D=stage.current_world.paper.transform
	var before: Dictionary=view.model.snapshot()
	stage.history_time=2.7; stage.refresh()
	check(stage.current_world.paper.transform==pose and view.model.snapshot()==before,"History time changes neither current mesh nor model")
	check(stage.current_world.sun.shadow_enabled,"Actual directional-light shadow map enabled")
	check(stage.current_world.paper.material_override.transparency==BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR,"Paper alpha silhouette participates in depth and shadows")
	var arrays: Array=stage.current_world.paper.mesh.surface_get_arrays(0)
	check(arrays[Mesh.ARRAY_NORMAL][0].dot(Vector3.UP)>0.99,"Paper face normal points above desk after axis swap")
	check(stage.current_world.meshes.size()<70,"Mesh count is bounded for the small mobile scene")
	print("PAPER_WORLD_3D checks=%d failures=%d actual_render=false"%[checks,failures])
	view.queue_free(); await process_frame
	quit(1 if failures else 0)
