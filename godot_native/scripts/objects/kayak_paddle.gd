extends Node2D
## Grip is the transform origin. Only the willow's shaft can bend.
@export_enum("left","right") var side: String="left"
var phase: String="rest"
var reverse:=false
func apply_pose(pose: Dictionary) -> void:
	phase=str(pose.phase);reverse=bool(pose.reverse)
	var grip: Vector2=pose.grip
	var tip: Vector2=pose.tip
	var middle: Vector2=pose.shaft_mid
	position=grip
	rotation=(tip-grip).angle()
	var local_tip: Vector2=(tip-grip).rotated(-rotation)
	var local_middle: Vector2=(middle-grip).rotated(-rotation)
	$ShaftOutline.points=PackedVector2Array([Vector2.ZERO,local_middle,local_tip])
	$Shaft.points=$ShaftOutline.points
	$BladePivot.position=local_tip
	$BladePivot.rotation=(tip-middle).angle()-rotation
	# Water stays level in body space even while the paddle rotates about the hand.
	$WaterContact.position=local_tip
	$WaterContact.rotation=-rotation
	var wet: float=float(pose.wet)
	$WaterContact/Ripple.visible=wet>.01
	$WaterContact/Ripple.modulate.a=wet
	$WaterContact/Surface.visible=wet>.01
	$WaterContact/Surface.modulate.a=wet
	$WaterContact/Drops.visible=phase=="exit"
	$WaterContact/Drops.modulate.a=1-float(pose.lift)/9
