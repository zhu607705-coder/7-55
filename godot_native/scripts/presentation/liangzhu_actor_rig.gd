extends Node2D
## Complete cel artwork plus real FK attachment bones; no weighted mesh deformation.
const NATIVE_CELL=Vector2i(120,160)
const NATIVE_FOOT=Vector2(60,150)
const PIXELS_PER_UNIT=5.0
const SECONDARY_LIMIT_DEGREES=6.0
const ATLAS_SHA256="41b42f9486ecbec2745239daa3a75937055105ff73a2da6eb22cc07db7a0ff32"
const ORDER=["Hip","Torso","Head","LeftShoulder","LeftElbow","LeftWrist","RightShoulder","RightElbow","RightWrist","LeftKnee","LeftFoot","RightKnee","RightFoot"]
const PARENTS={"Hip":"","Torso":"Hip","Head":"Torso","LeftShoulder":"Torso","LeftElbow":"LeftShoulder","LeftWrist":"LeftElbow","RightShoulder":"Torso","RightElbow":"RightShoulder","RightWrist":"RightElbow","LeftKnee":"Hip","LeftFoot":"LeftKnee","RightKnee":"Hip","RightFoot":"RightKnee"}
# Authored source-cell pixels. Covered hip/knee/foot supports are inferred, not anatomy claims.
# Per pose: Hip,Torso,Head,LShoulder,LElbow,LWrist,RShoulder,RElbow,RWrist,LKnee,LFoot,RKnee,RFoot.
const POSES=[
	[
		[Vector2(60,119),Vector2(60,89),Vector2(64,64),Vector2(49,89),Vector2(48,103),Vector2(58,108),Vector2(71,89),Vector2(76,103),Vector2(74,108),Vector2(51,136),Vector2(50,149),Vector2(69,136),Vector2(72,149)],
		[Vector2(60,119),Vector2(58,89),Vector2(63,64),Vector2(47,89),Vector2(34,106),Vector2(25,117),Vector2(70,89),Vector2(77,98),Vector2(79,105),Vector2(49,136),Vector2(42,149),Vector2(69,136),Vector2(74,149)],
		[Vector2(61,119),Vector2(61,85),Vector2(64,63),Vector2(48,85),Vector2(35,87),Vector2(34,70),Vector2(74,85),Vector2(91,89),Vector2(109,90),Vector2(52,137),Vector2(48,149),Vector2(69,137),Vector2(75,149)],
		[Vector2(60,119),Vector2(61,90),Vector2(67,70),Vector2(49,90),Vector2(55,100),Vector2(65,98),Vector2(73,90),Vector2(79,99),Vector2(75,95),Vector2(51,136),Vector2(49,149),Vector2(69,136),Vector2(72,149)]
	],
	[
		[Vector2(60,120),Vector2(60,91),Vector2(63,65),Vector2(48,91),Vector2(48,106),Vector2(55,111),Vector2(72,91),Vector2(78,105),Vector2(74,113),Vector2(50,138),Vector2(48,149),Vector2(70,138),Vector2(73,149)],
		[Vector2(60,120),Vector2(59,91),Vector2(63,65),Vector2(47,91),Vector2(33,108),Vector2(23,117),Vector2(71,91),Vector2(79,102),Vector2(79,109),Vector2(49,138),Vector2(40,149),Vector2(69,138),Vector2(73,149)],
		[Vector2(60,120),Vector2(59,88),Vector2(62,65),Vector2(47,88),Vector2(31,90),Vector2(33,67),Vector2(72,88),Vector2(89,84),Vector2(109,80),Vector2(50,138),Vector2(46,149),Vector2(70,138),Vector2(75,149)],
		[Vector2(60,120),Vector2(60,92),Vector2(64,71),Vector2(48,92),Vector2(55,103),Vector2(62,101),Vector2(72,92),Vector2(78,104),Vector2(73,99),Vector2(50,138),Vector2(48,149),Vector2(70,138),Vector2(73,149)]
	]
]
var skeleton:Skeleton2D
var bones:Dictionary={}
var sockets:Dictionary={}
var frame:=0
var row:=0
var flipped:=false
var secondary_degrees:=0.0

func _init()->void:
	skeleton=Skeleton2D.new();skeleton.name="Skeleton2D";add_child(skeleton)
	for id:String in ORDER:
		var bone:=Bone2D.new();bone.name=id;bone.set_autocalculate_length_and_angle(false);bone.set_length(1.0)
		var parent_id:String=PARENTS[id]
		if parent_id.is_empty():skeleton.add_child(bone)
		else:bones[parent_id].add_child(bone)
		bones[id]=bone
	for side:String in ["Left","Right"]:
		var sleeve:=Bone2D.new();sleeve.name=side+"SleeveSecondary";sleeve.set_autocalculate_length_and_angle(false);sleeve.set_length(3.0)
		bones[side+"Elbow"].add_child(sleeve);bones[str(sleeve.name)]=sleeve
		var tip:=Marker2D.new();tip.name=side+"SleeveTip";tip.position=Vector2(0,3.0);sleeve.add_child(tip);sockets[str(tip.name)]=tip
		var socket:=Marker2D.new();socket.name="FanSocket" if side=="Right" else "LeftFanSocket"
		bones[side+"Wrist"].add_child(socket);sockets[str(socket.name)]=socket
	var anchor:=Marker2D.new();anchor.name="FootAnchor";add_child(anchor);sockets["FootAnchor"]=anchor
	_apply_joints(0,0,true)

static func valid_pose(pose_frame:int,pose_row:int,foot:Vector2)->bool:
	return pose_frame>=0 and pose_frame<4 and pose_row>=0 and pose_row<2 and foot.is_finite()

static func authored_joints(pose_frame:int,pose_row:int)->Dictionary:
	if not valid_pose(pose_frame,pose_row,Vector2.ZERO):return {}
	var result:Dictionary={}
	for i:int in ORDER.size():result[ORDER[i]]=POSES[pose_row][pose_frame][i]
	return result

static func _joint_local(joints:Dictionary,id:String)->Vector2:
	var point:Vector2=joints[id]
	return (point-NATIVE_FOOT)/PIXELS_PER_UNIT

# Shared FK sampling for a historical launch frame. Live props use the actual nodes below.
static func sample_socket(pose_frame:int,pose_row:int,foot:Vector2,flip:bool,_time_ms:float=0.0,_reduced:bool=false,socket_name:String="FanSocket")->Vector2:
	if not valid_pose(pose_frame,pose_row,foot):return foot
	if socket_name=="FootAnchor":return foot
	if socket_name not in ["FanSocket","LeftFanSocket"]:return foot
	var joints:Dictionary=authored_joints(pose_frame,pose_row)
	var id:String="RightWrist" if socket_name=="FanSocket" else "LeftWrist"
	var chain:=Transform2D.IDENTITY
	while not id.is_empty():
		var parent_id:String=PARENTS[id]
		var offset:Vector2=_joint_local(joints,id)
		if not parent_id.is_empty():offset-=_joint_local(joints,parent_id)
		chain=Transform2D(0.0,offset)*chain;id=parent_id
	var reflection:=Transform2D(Vector2(-1 if flip else 1,0),Vector2(0,1),foot)
	return (reflection*chain).origin

func configure_pose(pose_frame:int,pose_row:int,foot:Vector2,flip:bool,time_ms:float=0.0,reduced:bool=false)->bool:
	if not valid_pose(pose_frame,pose_row,foot) or not is_finite(time_ms):return false
	frame=pose_frame;row=pose_row;flipped=flip
	transform=Transform2D(Vector2(-1 if flip else 1,0),Vector2(0,1),foot)
	_apply_joints(frame,row,false)
	# Secondary endpoints only; the cel and grip never receive procedural deformation.
	set_secondary_sleeve_angle(0.0 if reduced else sin(time_ms/900.0)*3.0)
	return true

func _apply_joints(pose_frame:int,pose_row:int,record_rest:bool)->void:
	var joints:Dictionary=authored_joints(pose_frame,pose_row)
	for id:String in ORDER:
		var parent_id:String=PARENTS[id]
		var offset:Vector2=_joint_local(joints,id)
		if not parent_id.is_empty():offset-=_joint_local(joints,parent_id)
		var bone:Bone2D=bones[id]
		bone.transform=Transform2D(0.0,offset)
		if record_rest:bone.rest=bone.transform
	for side:String in ["Left","Right"]:
		var sleeve:Bone2D=bones[side+"SleeveSecondary"]
		sleeve.transform=Transform2D.IDENTITY
		if record_rest:sleeve.rest=sleeve.transform

func set_secondary_sleeve_angle(degrees:float)->void:
	secondary_degrees=clampf(degrees if is_finite(degrees) else 0.0,-SECONDARY_LIMIT_DEGREES,SECONDARY_LIMIT_DEGREES)
	for side:String in ["Left","Right"]:
		var sleeve:Bone2D=bones[side+"SleeveSecondary"]
		sleeve.rotation=deg_to_rad(secondary_degrees*(1.0 if side=="Left" else -1.0))

func attachment_global_transform(socket_name:String="FanSocket")->Transform2D:
	if not sockets.has(socket_name):return global_transform
	var marker:Marker2D=sockets[socket_name]
	return marker.global_transform

# In the rig parent's coordinate system, not in cel pixels or screen pixels.
func attachment_local(socket_name:String="FanSocket")->Transform2D:
	if not sockets.has(socket_name):return transform
	var marker:Marker2D=sockets[socket_name]
	return transform*marker.get_relative_transform_to_parent(self)

func geometry_snapshot()->Dictionary:
	var socket:Transform2D=attachment_local()
	return {"kind":"cel+rig-hybrid","weightedMesh":false,"frame":frame,"row":row,"flip":flipped,"nativeFoot":[60,150],"pixelsPerUnit":PIXELS_PER_UNIT,"boneCount":bones.size(),"fanHand":"right","fanSocket":[socket.origin.x,socket.origin.y],"secondaryDegrees":secondary_degrees,"atlasSha256":ATLAS_SHA256}
