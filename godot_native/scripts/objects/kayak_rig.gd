extends Node2D
## Presentation-only native rig. Model input history is sampled, never advanced here.
const Pose=preload("res://scripts/ui/kayak_visual.gd")
const SOURCE_SCALE: float=0.52
var sampled_pose: Dictionary={}

func configure_view(point: Vector2,zoom: float,pose: Dictionary) -> void:
	position=point
	rotation=float(pose.get("heading",-PI/2))+PI/2
	scale=Vector2.ONE*zoom*SOURCE_SCALE
	modulate.a=float(pose.get("alpha",1))
	apply_pose(pose)

func apply_pose(pose: Dictionary) -> void:
	var roll:=clampf(float(pose.get("roll",0)),-1,1)
	var body: Node2D=$BodyRoll
	body.position=Vector2(0,float(pose.get("bodyY",roll*5)))
	body.rotation=deg_to_rad(float(pose.get("bodyAngle",roll*8)))
	body.scale=pose.get("bodyScale",Vector2.ONE)
	body.modulate.a=float(pose.get("bodyAlpha",1))
	$BodyRoll/SeatedPlayer.position=Vector2(roll*3,0)
	$Wake.apply_speed(float(pose.get("speed",0)))
	sampled_pose=Pose.paddle_poses(pose)
	for side: String in ["left","right"]:
		var title: String=side.capitalize()
		var paddle: Node2D=body.get_node(title+"Paddle")
		var arm: Node2D=body.get_node(title+"Arm")
		paddle.apply_pose(sampled_pose[side])
		arm.apply_pose(sampled_pose[side])

func hand_grip(side: String) -> Marker2D:
	return get_node("BodyRoll/"+side.capitalize()+"Arm/ShoulderPivot/ElbowPivot/Hand/Grip")

func paddle_grip(side: String) -> Marker2D:
	return get_node("BodyRoll/"+side.capitalize()+"Paddle/Grip")
