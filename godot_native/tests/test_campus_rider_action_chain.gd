extends SceneTree
## Check the actual skinned skeleton: planted feet must stop in world space
## while the hips travel, and swing feet must lift before changing support.
const Presenter=preload("res://scripts/presentation/chase_transition_3d_presenter.gd")
const Actions=preload("res://scripts/presentation/chase3d/campus_rider_actions.gd")
var failures: int=0
var checks: int=0
var pelican_mode: bool=false
func check_avatar(_view: Control) -> void:pass
func lowest_sole(avatar: Node3D,side: String) -> float:return avatar.surface_contact("foot",side).y
func _initialize() -> void:run.call_deferred()
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func run() -> void:
	var state: Node=root.get_node("State");state.developer_mode=true
	var before: String=JSON.stringify(state.d)
	var view:=Presenter.new();view.pelican_enabled=pelican_mode;view.manual_clock=true;root.add_child(view);await process_frame
	check_avatar(view)
	var worst_contact: float=0;var worst_slide: float=0;var worst_floor: float=0
	var worst_case: String="";var lift: float=0;var support_samples: int=0;var stepping_samples: int=0
	var reversed_knee: float=0
	var hip_disconnect: float=0
	var floor_case: String=""
	var worst_root_speed: float=0
	var speed_case: String=""
	for stage: String in ["start","finish"]:
		view.play(stage)
		var previous: Dictionary={};var previous_root:=Vector3.ZERO;var previous_time: float=0
		var duration: float=Actions.seconds_at(stage,view.last_frame())
		for tick: int in range(int(duration*120)+1):
			var seconds: float=tick/120.0;var source_frame: float=Actions.source_frame(stage,seconds)
			view.render_source_frame(stage,int(source_frame),source_frame-int(source_frame))
			var pose: Dictionary=view.action_pose;var human: Node3D=view.campus_human
			var root_point: Vector3=human.to_global(human.joint_point("Hips"))
			if tick>0 and (stage=="start" and source_frame<=23 or stage=="finish" and source_frame>=90):
				var velocity: float=Vector2(root_point.x-previous_root.x,root_point.z-previous_root.z).length()/(seconds-previous_time)
				if velocity>worst_root_speed:worst_root_speed=velocity;speed_case=str([stage,source_frame,root_point,previous_root])
			previous_root=root_point;previous_time=seconds
			for side: String in ["L","R"]:
				var actual: Vector3=human.to_global(human.surface_contact("foot",side))
				var hip: Vector3=human.joint_point("Hip"+side);var knee: Vector3=human.joint_point("Knee"+side);var ankle: Vector3=human.joint_point("Foot"+side)
				var pelvis_pose: Transform3D=human.global_transform.affine_inverse()*human.skeleton.global_transform*human.skeleton.get_bone_global_pose(human.bone_ids.Hips)
				var pelvis_basis: Basis=pelvis_pose.basis*human.bind_bases.Hips.inverse()
				hip_disconnect=maxf(hip_disconnect,hip.distance_to(pelvis_pose.origin+pelvis_basis*(human.rests["Hip"+side]-human.rests.Hips)))
				var thigh: Vector3=(knee-hip).normalized();var shin: Vector3=(ankle-knee).normalized()
				reversed_knee=maxf(reversed_knee,thigh.cross(shin).dot(pelvis_basis*Vector3.RIGHT))
				var free_swing: bool=pose.has("leg_swing"+side) and pose["leg_swing"+side].progress>0 and pose["leg_swing"+side].progress<1
				var error: float=0 if free_swing else actual.distance_to(pose["foot"+side])
				if error>worst_contact:worst_contact=error;worst_case=str([stage,source_frame,side,actual,pose["foot"+side]])
				var sole_y: float=lowest_sole(human,side)
				if -sole_y>worst_floor:worst_floor=-sole_y;floor_case=str([stage,source_frame,side,actual])
				if pose.foot_planted.has(side):
					if pose.foot_planted[side]:
						support_samples+=1
						if previous.has(side) and previous[side].planted:
							# A different landing may begin only after a swing interval.
							worst_slide=maxf(worst_slide,actual.distance_to(previous[side].point))
					else:stepping_samples+=1;lift=maxf(lift,actual.y)
				previous[side]={"point":actual,"planted":pose.foot_planted.get(side,false)}
	check(worst_contact<.002,"constrained soles reach every floor/pedal target; max="+str(worst_contact)+" case="+worst_case)
	check(worst_slide<.002,"actual stance soles stay fixed while hips travel; max slide="+str(worst_slide))
	check(worst_floor<.002,"soles never pass below the ground; penetration="+str(worst_floor)+" case="+floor_case)
	check(support_samples>300 and stepping_samples>100 and lift>.15,"both world-space support and visible foot lift exist")
	check(worst_root_speed<6,"production choreography has bounded walking/root speed; max="+str(worst_root_speed))
	check(hip_disconnect<.002,"both thigh roots inherit the actual pelvis transform; separation="+str(hip_disconnect))
	check(reversed_knee<.002,"knees never flex in the reverse anatomical direction; reverse="+str(reversed_knee))
	view.play("finish");view.elapsed=9;view.advance(.01);view.set_paused(true)
	var stopped: Transform3D=view.campus_human.skeleton.get_bone_global_pose(view.campus_human.bone_ids.FootL)
	view.advance(.25)
	check(view.campus_human.skeleton.get_bone_global_pose(view.campus_human.bone_ids.FootL)==stopped,"pause freezes the real planted skeleton")
	view.render_source_frame("start",28,0)
	var independent_root: Vector3=view.campus_human.joint_point("Hips")
	var raised_foot: Dictionary=view.action_pose.duplicate(true);raised_foot.footL.y+=.15
	view.campus_human.apply_transition(raised_foot)
	check(view.campus_human.joint_point("Hips").distance_to(independent_root)<.00001,"lifting a foot target cannot pull or reposition the master pelvis")
	view.render_source_frame("finish",view.frame,view.source_frame_position(view.elapsed)-view.frame)
	var pose_at_seek: Dictionary=view.action_pose.duplicate(true)
	view.render_source_frame("start",55,.3);view.render_source_frame("finish",view.frame,view.source_frame_position(view.elapsed)-view.frame)
	check(view.action_pose==pose_at_seek,"seeking/reentry reconstructs the same pose without a second clock")
	check(JSON.stringify(state.d)==before,"new action chain writes no story state, inventory, proof or save")
	print("PELICAN_ACTION_CHAIN" if pelican_mode else "HUMAN_ROLLBACK_ACTION_CHAIN"," checks=",checks," failures=",failures," contact=",worst_contact," slide=",worst_slide," ground=",worst_floor," lift=",lift," hip_disconnect=",hip_disconnect," knee_reverse=",reversed_knee," speed=",worst_root_speed," case=",speed_case)
	view.dispose();view.queue_free();await process_frame;quit(1 if failures else 0)
