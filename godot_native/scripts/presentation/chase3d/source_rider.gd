extends Node3D
## Native source mesh + original sampled IK, with a fixed glTF bone-bind correction.
var asset_directory: String="res://assets/"
var asset_prefix: String="rider"
var manifest: Dictionary
var bone_data: PackedFloat32Array
var local_data: PackedFloat32Array
var visual: Node3D
var nodes: Dictionary={}
var bones: Dictionary={}
var corrections: Dictionary={}
var last_steer: float=INF
var last_phase: float=INF

func _ready() -> void:
	manifest=JSON.parse_string(FileAccess.get_file_as_string(asset_directory+asset_prefix+"_pose_manifest.json"))
	bone_data=FileAccess.get_file_as_bytes(asset_directory+asset_prefix+"_bone_poses.bin").to_float32_array()
	local_data=FileAccess.get_file_as_bytes(asset_directory+asset_prefix+"_local_poses.bin").to_float32_array()
	visual=load(asset_directory+asset_prefix+"_geometry.scn").instantiate();add_child(visual)
	_register(visual)
	var center: int=int(manifest.steers.size()/2)*(int(manifest.phaseFrames)+1)
	for i: int in range(manifest.bones.size()):
		var name: String=manifest.bones[i].name
		assert(bones.has(name),"Missing source bone "+name)
		var entry: Dictionary=bones[name]
		var imported: Transform3D=global_transform.affine_inverse()*entry.skeleton.global_transform*entry.skeleton.get_bone_global_pose(entry.bone)
		corrections[name]=_bone_matrix(center,i).affine_inverse()*imported
	for source: Dictionary in manifest.nodes:
		var node: Node=nodes.get(source.name)
		if node is Node3D: node.visible=source.visible
	apply_pose(0,0)

func _register(node: Node) -> void:
	nodes[str(node.name)]=node
	if node is Skeleton3D:
		for index: int in range(node.get_bone_count()): bones[node.get_bone_name(index)]={"skeleton":node,"bone":index}
	if node is AnimationPlayer: node.active=false
	for child: Node in node.get_children(): _register(child)

func _bone_matrix(sample: int,index: int) -> Transform3D:
	var at: int=(sample*manifest.bones.size()+index)*16
	return Transform3D(Basis(Vector3(bone_data[at],bone_data[at+1],bone_data[at+2]),Vector3(bone_data[at+4],bone_data[at+5],bone_data[at+6]),Vector3(bone_data[at+8],bone_data[at+9],bone_data[at+10])),Vector3(bone_data[at+12],bone_data[at+13],bone_data[at+14]))

func _local_matrix(sample: int,index: int) -> Transform3D:
	var at: int=(sample*manifest.dynamic.size()+index)*10
	return Transform3D(Basis(Quaternion(local_data[at+3],local_data[at+4],local_data[at+5],local_data[at+6])).scaled(Vector3(local_data[at+7],local_data[at+8],local_data[at+9])),Vector3(local_data[at],local_data[at+1],local_data[at+2]))

func _indices(steer: float,phase: float) -> Dictionary:
	var count: int=manifest.steers.size()
	var s: float=clampf((steer-float(manifest.steers[0]))/float(manifest.steers[1]-manifest.steers[0]),0,count-1) if count>1 else 0
	var s0: int=mini(count-2,int(floor(s))) if count>1 else 0;var sw: float=s-s0
	var s1: int=s0+1 if count>1 else 0
	var frames: int=int(manifest.phaseFrames)
	var p: float=fposmod(phase,TAU)/TAU*frames
	var p0: int=mini(frames-1,int(floor(p)));var pw: float=p-p0
	return {"ids":[s0*(frames+1)+p0,s0*(frames+1)+p0+1,s1*(frames+1)+p0,s1*(frames+1)+p0+1],"pw":pw,"sw":sw}

func apply_pose(steer: float,phase: float,reduced: bool=false) -> void:
	if manifest.is_empty():return
	# Model clock owns phase. Repeated or paused rendering cannot advance it.
	last_steer=steer;last_phase=phase
	var index: Dictionary=_indices(steer,phase)
	if reduced and manifest.has("reducedSample"):
		var sample: int=int(manifest.reducedSample)
		index={"ids":[sample,sample,sample,sample],"pw":0.0,"sw":0.0}
	var ids: Array=index.ids
	for i: int in range(manifest.dynamic.size()):
		var node: Node=nodes.get(manifest.dynamic[i])
		if not node is Node3D:continue
		var a: Transform3D=_local_matrix(ids[0],i).interpolate_with(_local_matrix(ids[1],i),index.pw)
		var b: Transform3D=_local_matrix(ids[2],i).interpolate_with(_local_matrix(ids[3],i),index.pw)
		node.transform=a.interpolate_with(b,index.sw)
	var skeleton_spaces: Dictionary={}
	for entry: Dictionary in bones.values():
		if not skeleton_spaces.has(entry.skeleton):skeleton_spaces[entry.skeleton]=entry.skeleton.global_transform.affine_inverse()*global_transform
	for i: int in range(manifest.bones.size()):
		var name: String=manifest.bones[i].name;var entry: Dictionary=bones[name]
		var a: Transform3D=_bone_matrix(ids[0],i).interpolate_with(_bone_matrix(ids[1],i),index.pw)
		var b: Transform3D=_bone_matrix(ids[2],i).interpolate_with(_bone_matrix(ids[3],i),index.pw)
		var target: Transform3D=skeleton_spaces[entry.skeleton]*a.interpolate_with(b,index.sw)*corrections[name]
		entry.skeleton.set_bone_global_pose(entry.bone,target)

func spin_wheels(angle: float) -> void:
	for id: String in ["rearWheel","frontWheel"]:
		var node: Node3D=nodes[manifest.references[id]]
		node.rotation.x=angle

func source_bone_world(name: String) -> Transform3D:
	var entry: Dictionary=bones[name]
	return entry.skeleton.global_transform*entry.skeleton.get_bone_global_pose(entry.bone)*corrections[name].affine_inverse()

func reference_world(id: String) -> Transform3D:
	return nodes[manifest.references[id]].global_transform
