extends SceneTree
const Actor=preload("res://scripts/presentation/chase3d/source_rider.gd")
var max_position: float=0
var max_basis: float=0
var comparisons: int=0
func _initialize() -> void:run.call_deferred()
func compare(actor: Node3D,sample: int) -> void:
	for i: int in range(actor.manifest.bones.size()):
		var actual: Transform3D=actor.global_transform.affine_inverse()*actor.source_bone_world(actor.manifest.bones[i].name)
		var expected: Transform3D=actor._bone_matrix(sample,i)
		max_position=maxf(max_position,actual.origin.distance_to(expected.origin))
		max_basis=maxf(max_basis,maxf(actual.basis.x.distance_to(expected.basis.x),maxf(actual.basis.y.distance_to(expected.basis.y),actual.basis.z.distance_to(expected.basis.z))))
		comparisons+=1
func run() -> void:
	var route: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/native_755/ride/source_manifest.json"))
	for entry: Dictionary in route.pedestrians:
		var actor:=Actor.new();actor.asset_directory="res://assets/native_755/ride/";actor.asset_prefix=entry.asset;actor.position=Vector3(6,.04,-130);actor.rotation.y=PI;root.add_child(actor);await process_frame
		for frame: int in [0,12,24,36,47]:
			actor.apply_pose(0,frame/48.0*TAU);compare(actor,frame)
		actor.apply_pose(0,2,true);compare(actor,int(actor.manifest.reducedSample))
		actor.queue_free();await process_frame
	print("SOURCE_PEOPLE_FIDELITY actors=",route.pedestrians.size()," comparisons=",comparisons," max_position=",max_position," max_basis=",max_basis)
	quit(1 if max_position>.0001 or max_basis>.0003 else 0)
