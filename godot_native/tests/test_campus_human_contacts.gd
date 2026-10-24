extends SceneTree
## Read actual skeleton poses over the production bicycle's complete pedal cycle.
const Rider=preload("res://scripts/presentation/chase3d/source_rider.gd")
var failures: int=0
var checks: int=0
func _initialize() -> void:run.call_deferred()
func check(value: bool,message: String) -> void:
	checks+=1
	if not value:failures+=1;push_error(message)
func run() -> void:
	var rider:=Rider.new();rider.asset_directory="res://assets/native_755/ride/"
	rider.pelican_enabled=false # Retained human rollback rig, not production avian acceptance.
	if "--candidate" in OS.get_cmdline_user_args():rider.human_asset_path="res://docs/art/reference/student_v3/candidate/campus_student_rigged.glb"
	root.add_child(rider)
	await process_frame
	var human: Node3D=rider.campus_human
	check(is_instance_valid(human),"production rider exposes the replacement contact rig")
	var worst: float=0
	var worst_segment: float=0
	var worst_shoulder_span: float=0
	var worst_neck_shoulder: float=0
	var worst_seat: float=0
	var worst_spine: float=0
	var segment_case: String=""
	for steer: float in [-.32,0,.32]:
		for frame: int in range(121):
			rider.apply_pose(steer,TAU*frame/120)
			worst_seat=maxf(worst_seat,human.surface_contact("seat","").distance_to(rider.saddle_contact()))
			worst_spine=maxf(worst_spine,absf(human.joint_point("Hips").distance_to(human.joint_point("Torso"))-(human.rests.Torso-human.rests.Hips).length()))
			var left_shoulder: Vector3=human.joint_point("ShoulderL")
			var right_shoulder: Vector3=human.joint_point("ShoulderR")
			var rest_span: float=human.rests.ShoulderL.distance_to(human.rests.ShoulderR)
			worst_shoulder_span=maxf(worst_shoulder_span,absf(left_shoulder.distance_to(right_shoulder)-rest_span))
			var rest_gap: float=human.rests.Head.distance_to((human.rests.ShoulderL+human.rests.ShoulderR)*.5)
			var posed_gap: float=human.joint_point("Head").distance_to((left_shoulder+right_shoulder)*.5)
			worst_neck_shoulder=maxf(worst_neck_shoulder,absf(posed_gap-rest_gap))
			for side: String in ["L","R"]:
				var left: bool=side=="L"
				var wrist: Vector3=human.surface_contact("hand",side)
				var sole: Vector3=human.surface_contact("foot",side)
				var grip: Vector3=rider.to_local(rider.reference_world("leftGrip" if left else "rightGrip").origin)
				var pedal: Vector3=rider.to_local(rider.reference_world("leftPedal" if left else "rightPedal").origin)
				worst=maxf(worst,maxf(wrist.distance_to(grip),sole.distance_to(pedal)))
				for chain: Array in [["Shoulder","Elbow"],["Elbow","Wrist"],["Hip","Knee"],["Knee","Foot"]]:
					var a: Vector3=human.joint_point(chain[0]+side)
					var b: Vector3=human.joint_point(chain[1]+side)
					var rest_a: Vector3=human.rests[chain[0]+side]
					var rest_b: Vector3=human.rests[chain[1]+side]
					var error: float=absf(a.distance_to(b)-rest_a.distance_to(rest_b))
					if error>worst_segment:
						worst_segment=error;segment_case=str([steer,frame,chain,side,a,b])
	check(worst<.0001,"actual calibrated palm/sole anchors remain on grips/pedals; error="+str(worst))
	check(worst_segment<.002,"two-bone chains preserve anatomical segment lengths; error="+str(worst_segment)+" case="+segment_case)
	check(worst_shoulder_span<.002,"actual shoulder girdle retains source shoulder breadth; error="+str(worst_shoulder_span))
	check(worst_neck_shoulder<.002,"actual neck-to-shoulder spacing retains source anatomy; error="+str(worst_neck_shoulder))
	check(worst_seat<.018,"calibrated pelvic seat anchor stays on the physical saddle; error="+str(worst_seat))
	check(worst_spine<.002,"hip-to-chest body length is preserved; error="+str(worst_spine))
	# The previous regression lowered the girdle while hand contacts still passed.
	# Prove the new spacing gate rejects that independent anatomical failure.
	var healthy_gap: float=human.joint_point("Head").distance_to((human.joint_point("ShoulderL")+human.joint_point("ShoulderR"))*.5)
	for side: String in ["L","R"]:human._pose("Shoulder"+side,human.joint_point("Shoulder"+side)+Vector3(0,-.16,0))
	var collapsed_gap: float=human.joint_point("Head").distance_to((human.joint_point("ShoulderL")+human.joint_point("ShoulderR"))*.5)
	check(absf(collapsed_gap-healthy_gap)>.05,"shoulder-spacing detector rejects the previous lowered-girdle failure")
	rider.apply_pose(0,0,true)
	var frozen: String=var_to_str(human.skeleton.get_bone_global_pose(human.bone_ids.Head))
	rider.apply_pose(0,0,true)
	check(frozen==var_to_str(human.skeleton.get_bone_global_pose(human.bone_ids.Head)),"reduced-motion repeated pose is deterministic")
	check(human.find_children("*","CollisionObject3D",true,false).is_empty(),"human skin adds no hidden simulation bodies")
	rider.queue_free();await process_frame
	print("CAMPUS_HUMAN_CONTACTS checks=",checks," failures=",failures," worst_contact=",worst," worst_segment=",worst_segment)
	quit(1 if failures else 0)
