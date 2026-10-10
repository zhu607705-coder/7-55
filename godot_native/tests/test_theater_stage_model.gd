extends SceneTree
const View=preload("res://scripts/presentation/theater_stage_view.gd")
const Model=preload("res://scripts/games/c3_spotlight_model.gd")
var checks:=0
var failures:=0
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error("THEATER STAGE: "+label)
func mesh_count(node:Node)->int:
	var count:int=1 if node is MeshInstance3D else 0
	for child:Node in node.get_children():count+=mesh_count(child)
	return count
func run()->void:
	var view:=View.new();root.add_child(view);await process_frame
	var stage:Node3D=view.stage
	check(stage.lamp is Node3D and stage.lamp_head.get_parent()==stage.lamp,"followspot has a physical yoke and separate tilt pivot")
	check(stage.key_light is SpotLight3D and stage.key_light.shadow_enabled,"followspot is an actual shadow-casting spot light")
	check(stage.beam.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,"dust beam never casts an opaque false shadow")
	check(stage.floor_atlas.resource_path=="res://assets/rpg/interiors/theater_interior.png","wood reads the original theater source material")
	check(view.viewport.size==Vector2i(960,540),"fixed logical scene resolution retains fine pixel samples")
	check(view.viewport.positional_shadow_atlas_size<=512,"pixel style has a bounded shadow texture budget")
	check(mesh_count(stage)<=90,"static geometry is batched rather than hundreds of independent floor draws")
	var nodes:int=stage.get_child_count()
	var rules:=Model.new()
	for round_id in 3:
		var state:Dictionary=rules.create(round_id)
		var snapshot:Dictionary=state.duplicate(true)
		var points:Array=Model.FOOD.duplicate();points.append_array([Vector2(71,145),Vector2(889,396),state.head,rules.mouth(state)])
		for point:Vector2 in points:
			var world:Vector3=stage.world_point(point)
			check(absf(world.y)<.0001,"all gameplay coordinates raycast to the same floor plane")
			check(stage.camera.unproject_position(world).distance_to(point)<.001,"camera projection retains exact source anchor")
		for tick in 20:stage.update_pose(state,tick*.1)
		check(state==snapshot,"modeled scene never mutates source gameplay")
		check(stage.get_child_count()==nodes,"pose updates do not leak scene nodes")
	var state:Dictionary=rules.create(0)
	stage.update_pose(state,0);var before:Basis=stage.lamp_head.global_basis
	state.head=Vector2(800,350);stage.update_pose(state,0)
	check(not before.is_equal_approx(stage.lamp_head.global_basis),"real articulated lamp follows the target")
	check((-stage.lamp_head.global_basis.z).dot((stage.target_world-stage.lamp_head.global_position).normalized())>.999,"beam and spot forward axis aim at the same world target")
	view.queue_free();await process_frame
	print("THEATER_STAGE_MODEL: %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
