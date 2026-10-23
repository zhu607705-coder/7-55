extends SceneTree
const Rider=preload("res://scripts/presentation/chase3d/source_rider.gd")
var failures: int=0
func check(ok: bool,message: String) -> void:
	if not ok:failures+=1;push_error(message)
func _initialize() -> void:run.call_deferred()
func run() -> void:
	var state: Node=root.get_node("State");var before: String=JSON.stringify(state.d)
	var rider:=Rider.new();rider.asset_directory="res://assets/native_755/ride/";root.add_child(rider);await process_frame
	var bird: Node3D=rider.campus_human
	check(bird.name=="CampusPelican" and bird.skeleton.get_bone_count()==17,"actual production uses the 17-bone original pelican")
	check(bird.skeleton.get_bone_parent(bird.bone_ids.Head)==bird.bone_ids.Neck,"long neck and head belong to one real skeleton")
	check(bird.find_children("*","CollisionObject3D",true,false).is_empty(),"bird is presentation only")
	var error: float=0;var length_error: float=0;var seat_error: float=0
	for steer: float in [-.32,0,.32]:
		for frame: int in range(121):
			rider.apply_pose(steer,TAU*frame/120.0)
			seat_error=maxf(seat_error,bird.surface_contact("seat","").distance_to(rider.saddle_contact()))
			for side: String in ["L","R"]:
				var left: bool=side=="L"
				var grip: Vector3=rider.to_local(rider.reference_world("leftGrip" if left else "rightGrip").origin)
				var pedal: Vector3=rider.to_local(rider.reference_world("leftPedal" if left else "rightPedal").origin)
				error=maxf(error,maxf(bird.surface_contact("hand",side).distance_to(grip),bird.surface_contact("foot",side).distance_to(pedal)))
				for chain: Array in [["Shoulder","Elbow"],["Elbow","Wrist"],["Hip","Knee"],["Knee","Foot"]]:
					length_error=maxf(length_error,absf(bird.joint_point(chain[0]+side).distance_to(bird.joint_point(chain[1]+side))-bird.rests[chain[0]+side].distance_to(bird.rests[chain[1]+side])))
	check(error<.002,"actual wing tips and web soles follow grips/pedals without stretching; max="+str(error))
	check(length_error<.002,"wing and leg bone lengths remain fixed; max="+str(length_error))
	check(seat_error<.018,"body remains anchored to actual saddle; max="+str(seat_error))
	rider.apply_pose(.15,1.3,true);var pose: String=var_to_str(bird.skeleton.get_bone_global_pose(bird.bone_ids.Head))
	rider.apply_pose(.15,1.3,true);check(var_to_str(bird.skeleton.get_bone_global_pose(bird.bone_ids.Head))==pose,"reduced pose has no independent clock")
	check(JSON.stringify(state.d)==before,"rendering has not changed saves, items or progression")
	print("PELICAN_CONTACTS failures=",failures," contact=",error," lengths=",length_error," seat=",seat_error)
	rider.queue_free();await process_frame;quit(1 if failures else 0)
