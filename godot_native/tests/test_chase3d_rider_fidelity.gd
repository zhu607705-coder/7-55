extends SceneTree
var rider: Node3D
var max_position: float=0
var max_basis: float=0
var max_rotation: float=0
var failures: int=0
var checks: int=0
func _initialize() -> void:run.call_deferred()
func matrix(v: Array) -> Transform3D:
	return Transform3D(Basis(Vector3(v[0],v[1],v[2]),Vector3(v[4],v[5],v[6]),Vector3(v[8],v[9],v[10])),Vector3(v[12],v[13],v[14]))
func compare(a: Transform3D,b: Transform3D,label: String="") -> void:
	max_rotation=maxf(max_rotation,a.basis.orthonormalized().get_rotation_quaternion().angle_to(b.basis.orthonormalized().get_rotation_quaternion()))
	checks+=1;max_position=maxf(max_position,a.origin.distance_to(b.origin))
	max_basis=maxf(max_basis,maxf(a.basis.x.distance_to(b.basis.x),maxf(a.basis.y.distance_to(b.basis.y),a.basis.z.distance_to(b.basis.z))))
func run() -> void:
	rider=load("res://scripts/presentation/chase3d/source_rider.gd").new();rider.asset_directory="res://assets/native_755/ride/";root.add_child(rider);await process_frame
	# Exact source grid nodes, both steering extremes, full pedaling loop.
	for steer: float in [-.35,-.28,-.14,0,.14,.28,.35]:
		for phase: int in range(0,97,4):
			rider.apply_pose(steer,phase/96.0*TAU)
			var row: int=int(round((steer-float(rider.manifest.steers[0]))/.035))*97+(phase%96)
			for i: int in range(rider.manifest.bones.size()):compare(rider.source_bone_world(rider.manifest.bones[i].name),rider._bone_matrix(row,i))
	print("GRID_FIDELITY checks=",checks," max_position=",max_position," max_basis=",max_basis," max_rotation_radians=",max_rotation)
	if max_position>.00002 or max_basis>.0003:failures+=1
	max_position=0;max_basis=0;checks=0
	for sample: Dictionary in rider.manifest.offgrid:
		rider.apply_pose(sample.steer,sample.phase)
		for i: int in range(rider.manifest.bones.size()):compare(rider.source_bone_world(rider.manifest.bones[i].name),matrix(sample.boneWorld[i]),str(rider.manifest.bones[i].original))
		for id: String in sample.references:compare(rider.reference_world(id),matrix(sample.references[id]),id)
	print("OFFGRID_FIDELITY checks=",checks," max_position=",max_position," max_basis=",max_basis," max_rotation_radians=",max_rotation)
	if max_position>.005 or max_rotation>.01:failures+=1
	rider.queue_free();await process_frame
	print("SOURCE_RIDER_FIDELITY failures=",failures);quit(1 if failures else 0)
