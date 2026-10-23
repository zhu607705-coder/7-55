extends RefCounted
## Deterministic presentation choreography. Feet are planted in world space;
## elapsed time, saves and gameplay remain owned by the existing host.
const START_TIME: Array[Vector2]=[Vector2(0,0),Vector2(10,10.0/24),Vector2(23,1.45),Vector2(40,3),Vector2(70,4.25),Vector2(90,5.25)]
const FINISH_TIME: Array[Vector2]=[Vector2(0,0),Vector2(40,40.0/24),Vector2(55,2.5),Vector2(66,3.25),Vector2(90,5),Vector2(107,8.6),Vector2(120,14.4),Vector2(132,14.9)]
const STEP_LENGTH: float=.78
const HALF_STANCE: float=.205
var poses: Dictionary
var hip_index: int
var player_index: int
var paths: Dictionary={}

static func source_frame(stage: String,seconds: float) -> float:
	var knots: Array[Vector2]=START_TIME if stage=="start" else FINISH_TIME
	for i: int in range(1,knots.size()):
		if seconds<=knots[i].y:return lerpf(knots[i-1].x,knots[i].x,clampf(inverse_lerp(knots[i-1].y,knots[i].y,seconds),0,1))
	return knots.back().x

static func seconds_at(stage: String,frame: float) -> float:
	var knots: Array[Vector2]=START_TIME if stage=="start" else FINISH_TIME
	for i: int in range(1,knots.size()):
		if frame<=knots[i].x:return lerpf(knots[i-1].y,knots[i].y,clampf(inverse_lerp(knots[i-1].x,knots[i].x,frame),0,1))
	return knots.back().y

func configure(source_poses: Dictionary,player_name: String) -> void:
	poses=source_poses
	player_index=poses.dynamic.find(player_name)
	assert(player_index>=0,"Action path requires the authored player root")
	for i: int in range(poses.bones.size()):
		if poses.bones[i].originalName=="Hips":hip_index=i;break
	for stage: String in ["start","finish"]:
		var first: float=10 if stage=="start" else 90
		var last: float=23 if stage=="start" else 120
		var points: Array[Vector3]=[];var distances: Array[float]=[0.0]
		for i: int in range(int((last-first)*8)+1):
			var point: Vector3=walk_root(stage,first+i/8.0);point.y=0
			if not points.is_empty():distances.append(distances.back()+point.distance_to(points.back()))
			points.append(point)
		paths[stage]={"points":points,"distances":distances,"first":first,"last":last}

func original_hip(stage: String,frame: float) -> Vector3:
	var frames: Array=poses.stages[stage].boneWorld
	var index: int=clampi(int(frame),0,frames.size()-1);var next: int=mini(index+1,frames.size()-1)
	var a: Array=frames[index][hip_index];var b: Array=frames[next][hip_index]
	return Vector3(a[12],a[13],a[14]).lerp(Vector3(b[12],b[13],b[14]),frame-index)

func walk_root(stage: String,frame: float) -> Vector3:
	if stage=="start":return original_hip(stage,0).lerp(original_hip(stage,23),smoothstep(10,23,frame))
	var raw: Vector3=original_hip(stage,clampf(frame,90,120))
	var at: float=minf(frame,107)
	var player: Vector3=_player_position(at)
	var hip: Vector3=original_hip("finish",at)
	var delta: Vector3=Basis(Vector3.UP,bicycle_yaw(at))*(hip-player)-(hip-player)
	return raw+delta*(1-smoothstep(107,120,frame))

func _player_position(frame: float) -> Vector3:
	var frames: Array=poses.stages.finish.local
	var i: int=clampi(int(frame),0,frames.size()-1);var n: int=mini(i+1,frames.size()-1)
	var a: Array=frames[i][player_index];var b: Array=frames[n][player_index]
	return Vector3(a[0],a[1],a[2]).lerp(Vector3(b[0],b[1],b[2]),frame-i)

static func bicycle_yaw(frame: float) -> float:
	return atan2(-4.8,1.2)*smoothstep(90,96,frame)

static func bicycle_lean(stage: String,frame: float) -> float:
	if stage=="start":return .14*(1-smoothstep(30,40,frame))
	return .22*smoothstep(55,66,frame)*(1-smoothstep(82,90,frame))+.06*smoothstep(90,96,frame)

func path_point(stage: String,distance: float) -> Vector3:
	var path: Dictionary=paths[stage];var ds: Array=path.distances
	distance=clampf(distance,0,ds.back())
	var lo: int=0;var hi: int=ds.size()-1
	while hi-lo>1:
		var mid: int=(lo+hi)/2
		if ds[mid]<distance:lo=mid
		else:hi=mid
	return path.points[lo].lerp(path.points[hi],clampf(inverse_lerp(ds[lo],ds[hi],distance),0,1)) if ds[hi]-ds[lo]>.00001 else path.points[hi]

func path_distance(stage: String,frame: float) -> float:
	var path: Dictionary=paths[stage]
	var index: float=clampf((frame-path.first)*8,0,path.distances.size()-1)
	return lerpf(path.distances[int(index)],path.distances[mini(int(index)+1,path.distances.size()-1)],index-int(index))

func path_yaw(stage: String,distance: float) -> float:
	# Turn from the path tangent, with anticipation across the parking corner.
	var direction: Vector3=path_point(stage,distance+.28)-path_point(stage,distance-.28)
	return atan2(-direction.x,-direction.z) if direction.length_squared()>.000001 else 0

func footstep(stage: String,frame: float,side: String) -> Dictionary:
	var path: Dictionary=paths[stage];var total: float=path.distances.back()
	var distance: float=path_distance(stage,frame)
	# One settling step gathers the trailing foot while the pelvis comes to rest.
	var travel: float=distance+STEP_LENGTH*smoothstep(path.last-2,path.last,frame)
	var steps: int=0 if travel<STEP_LENGTH*.5 else 1+int(floor((travel-STEP_LENGTH*.5)/STEP_LENGTH))
	var parity: int=0 if side=="L" else 1
	var active_step: int=steps if steps%2==parity else steps-1
	var land_distance: float=minf(total,(active_step+1)*STEP_LENGTH)
	var before_distance: float=maxf(0,(active_step-1)*STEP_LENGTH)
	var start_distance: float=0 if active_step==0 else (active_step-.5)*STEP_LENGTH
	var step_span: float=STEP_LENGTH*.5 if active_step==0 else STEP_LENGTH
	var progress: float=clampf((travel-start_distance)/step_span/.72,0,1) if active_step>=0 else 1
	var from: Vector3=_foot_anchor(stage,before_distance,side)
	var to: Vector3=_foot_anchor(stage,land_distance,side) if active_step>=0 else from
	var foot: Vector3=from.lerp(to,smoothstep(0,1,progress))
	foot.y=sin(PI*progress)*.18 if progress<1 else 0
	var yaw: float=lerp_angle(_anchor_yaw(stage,before_distance),_anchor_yaw(stage,land_distance),smoothstep(0,1,progress))
	return {"point":foot,"yaw":yaw,"planted":progress>=1 or active_step<0,"stride":travel/STEP_LENGTH}

func _anchor_yaw(stage: String,distance: float) -> float:
	return 0.0 if stage=="start" or distance<.0001 else path_yaw(stage,distance)

func _foot_anchor(stage: String,distance: float,side: String) -> Vector3:
	var yaw: float=_anchor_yaw(stage,distance)
	return path_point(stage,distance)+Basis(Vector3.UP,yaw)*Vector3(-HALF_STANCE if side=="L" else HALF_STANCE,0,-.10)

func retarget(stage: String,frame: float,joints: Dictionary,grips: Dictionary,pedals: Dictionary) -> Dictionary:
	var result: Dictionary=joints.duplicate(true)
	result.hand_constraints={};result.foot_planted={}
	if stage=="start" and frame<=23 or stage=="finish" and frame>=90:
		var pelvis: Vector3=walk_root(stage,frame)
		result.Hips=pelvis;result.Torso=pelvis+Vector3.UP;result.ride_blend=0.0
		var distance: float=path_distance(stage,frame)
		var yaw: float=0 if stage=="start" else path_yaw(stage,distance)
		if stage=="finish":yaw=lerp_angle(0,yaw,smoothstep(90,94,frame))
		result.body_yaw=yaw
		for side: String in ["L","R"]:
			var foot: Dictionary=footstep(stage,frame,side)
			# At the beginning of a turn, planted soles keep their own orientation.
			result["foot"+side]=foot.point;result["foot_yaw"+side]=0.0 if stage=="start" else foot.yaw
			result.foot_planted[side]=foot.planted
			result["free_arm"+side]=0.0
			result.walk_phase=foot.stride*.5+.42
			result.walk_weight=smoothstep(90,94,frame)*(1-smoothstep(118,120,frame)) if stage=="finish" else smoothstep(10,12,frame)*(1-smoothstep(20,23,frame))
		if stage=="start":
			var reach: float=smoothstep(14,23,frame)
			result.arm_reach=reach
			result.Torso=pelvis+(joints.Torso-joints.Hips)
			for side: String in ["L","R"]:
				if reach>=1:result.hand_constraints[side]=grips[side]
		elif frame<108:
			# Right hand guides the near grip; left arm counter-swings naturally.
			result.hand_constraints.R=grips.L
			result.pushing=true
			result.Torso=pelvis+Vector3(0,1,-.35)
		elif frame<111:
			result.handR=grips.L;result.hand_blendR=1-smoothstep(107,111,frame)
		return result
	if stage=="start":
		result.ride_blend=smoothstep(23,40,frame)
		result.body_blend=smoothstep(23,33,frame)
		result.pelvis_seat_blend=smoothstep(33,40,frame)
		result.pelvis_turn=-.16*sin(PI*smoothstep(23,40,frame))
		var left_ground: Vector3=_foot_anchor("start",paths.start.distances.back(),"L")
		var right_ground: Vector3=_foot_anchor("start",paths.start.distances.back(),"R")
		result.footL=left_ground.lerp(pedals.L,smoothstep(33,40,frame))
		result.footR=_leg_over(right_ground,pedals.R,smoothstep(23,33,frame),joints.seat.z+1.35)
		result.leg_swingR={"progress":smoothstep(23,33,frame),"from":right_ground,"to":pedals.R}
		if frame>=40:result.footL=pedals.L;result.footR=pedals.R
		result.hand_constraints={"L":grips.L,"R":grips.R}
		result.leg_poleR=Vector3(.5,.02,-1)
		result.foot_pitchR=-.45*sin(PI*smoothstep(23,33,frame))
	else:
		result.body_blend=1-smoothstep(73,86,frame)
		result.body_side_lean=.08*sin(PI*smoothstep(55,82,frame))
		result.pelvis_seat_blend=1-smoothstep(55,66,frame)
		result.pelvis_turn=-.16*sin(PI*smoothstep(66,82,frame))
		var parked: Vector3=walk_root("finish",90)
		result.Hips.x=lerpf(joints.seat.x,parked.x,smoothstep(55,82,frame))
		result.Hips.z=lerpf(joints.Hips.z,parked.z,smoothstep(55,66,frame))
		var left_ground: Vector3=parked+Vector3(-HALF_STANCE,0,-.10);left_ground.y=0
		var right_ground: Vector3=parked+Vector3(HALF_STANCE,0,-.10);right_ground.y=0
		result.footL=pedals.L.lerp(left_ground,smoothstep(55,66,frame))
		result.footR=_leg_over(pedals.R,right_ground,smoothstep(66,82,frame),joints.seat.z+1.35)
		result.leg_swingR={"progress":smoothstep(66,82,frame),"from":pedals.R,"to":right_ground}
		result.leg_poleR=Vector3(.5,.02,-1)
		result.foot_pitchR=-.45*sin(PI*smoothstep(66,82,frame))
		result.hand_constraints={"L":grips.L,"R":grips.R}
		# Release the far grip only after the supporting foot has reached ground.
		if frame>76:
			result.hand_constraints.erase("R");result.free_armR=0.0
			result.hand_blendR=1-smoothstep(76,82,frame)
		if frame>=82:
			result.handR=grips.L;result.hand_blendR=smoothstep(82,90,frame)
		if frame>=86:
			result.hand_constraints.erase("L");result.free_armL=0.0;result.hand_blendL=1-smoothstep(86,90,frame)
	return result

static func _leg_over(from: Vector3,to: Vector3,progress: float,rear: float) -> Vector3:
	var point: Vector3=from.lerp(to,progress)
	point.y=lerpf(point.y,1.76,sin(PI*progress))
	point.z=lerpf(point.z,rear,sin(PI*progress))
	return point
