extends SceneTree
## Continuous source shots interpolate; cuts and controller-owned clock stay exact.
const Presenter=preload("res://scripts/presentation/chase_transition_3d_presenter.gd")
var checks: int=0
var failures: int=0
func _initialize() -> void:run.call_deferred()
func check(value: bool,message: String) -> void:
	checks+=1
	if not value:failures+=1;push_error(message)
func run() -> void:
	root.get_node("State").developer_mode=true
	var view:=Presenter.new();view.pelican_enabled=false;view.manual_clock=true;root.add_child(view)
	await process_frame
	var worst_segment: float=0
	var segment_case: String=""
	var worst_grip: float=0
	var grip_case: String=""
	var worst_neck: float=0
	var worst_body: float=0
	var worst_seat: float=0
	for stage: String in ["start","finish"]:
		view.play(stage)
		for frame: int in range(view.source_manifest.stages[stage].size()-1):
			var a: Dictionary=view.source_manifest.stages[stage][frame]
			var b: Dictionary=view.source_manifest.stages[stage][frame+1]
			view.render_source_frame(stage,frame,.5)
			var pa:=Vector3(a.cameraPosition[0],a.cameraPosition[1],a.cameraPosition[2])
			var pb:=Vector3(b.cameraPosition[0],b.cameraPosition[1],b.cameraPosition[2])
			var expected: Vector3=pa.lerp(pb,.5) if a.camera==b.camera else pa
			check(view.source_camera.position.distance_to(expected)<.0001,"continuous camera midpoint or intact cut at "+stage+str(frame))
			var human: Node3D=view.campus_human
			worst_neck=maxf(worst_neck,absf(human.joint_point("Head").distance_to(human.joint_point("Neck"))-human.rests.Head.distance_to(human.rests.Neck)))
			worst_body=maxf(worst_body,absf(human.joint_point("Hips").distance_to(human.joint_point("Torso"))-human.rests.Hips.distance_to(human.rests.Torso)))
			if float(view.action_pose.ride_blend)>=1:
				worst_seat=maxf(worst_seat,human.to_global(human.surface_contact("seat","")).distance_to(view.saddle_world_top()))
			for side: String in ["L","R"]:
				if view.action_pose.hand_constraints.has(side):
					var grip: Vector3=view.action_pose.hand_constraints[side]
					var error: float=human.to_global(human.surface_contact("hand",side)).distance_to(grip)
					if error>worst_grip:worst_grip=error;grip_case=str([stage,frame,side])
				for chain: Array in [["Shoulder","Elbow"],["Elbow","Wrist"],["Hip","Knee"],["Knee","Foot"]]:
					var p: Vector3=human.joint_point(chain[0]+side)
					var q: Vector3=human.joint_point(chain[1]+side)
					var ra: Vector3=human.rests[chain[0]+side]
					var rb: Vector3=human.rests[chain[1]+side]
					var error: float=absf(p.distance_to(q)-ra.distance_to(rb))
					if error>worst_segment:worst_segment=error;segment_case=str([stage,frame,side,chain,p,q])
	check(worst_segment<.002,"mount/dismount preserves limb lengths; error="+str(worst_segment)+" case="+segment_case)
	check(worst_grip<.002,"physical grip constraints stay attached during mount/dismount; error="+str(worst_grip)+" case="+grip_case)
	check(worst_neck<.002,"retargeting preserves the new neck/head spacing; error="+str(worst_neck))
	check(worst_body<.002,"retargeting preserves hip-to-chest body length; error="+str(worst_body))
	check(worst_seat<.002,"seated transition frames use the same saddle contact as live riding; error="+str(worst_seat))
	view.play("start");view.elapsed=.41999;view.advance(.00001)
	check(view.frame==10 and is_equal_approx(view._rendered_fraction,view.source_frame_position(.42)-10),"production renders fractional source time at display cadence")
	view.set_paused(true)
	var frozen: Transform3D=view.source_camera.transform
	view.advance(.5)
	check(view.source_camera.transform==frozen and is_equal_approx(view.elapsed,.42),"pause freezes source clock and camera")
	view.dispose();view.queue_free();await process_frame
	print("CAMPUS_TRANSITION_SMOOTHING checks=",checks," failures=",failures)
	quit(1 if failures else 0)
