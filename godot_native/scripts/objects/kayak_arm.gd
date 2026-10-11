extends Node2D
## The shoulder and elbow are real transform pivots. Hand and paddle share one grip.
func apply_pose(pose: Dictionary) -> void:
	var shoulder: Vector2=pose.shoulder
	var elbow: Vector2=pose.elbow
	var grip: Vector2=pose.grip
	position=shoulder
	var upper: Vector2=elbow-shoulder
	$ShoulderPivot.rotation=upper.angle()
	$ShoulderPivot/Outline.points=PackedVector2Array([Vector2.ZERO,Vector2(upper.length(),0)])
	$ShoulderPivot/Skin.points=$ShoulderPivot/Outline.points
	$ShoulderPivot/ElbowPivot.position=Vector2(upper.length(),0)
	var forearm: Vector2=grip-elbow
	$ShoulderPivot/ElbowPivot.rotation=forearm.angle()-upper.angle()
	$ShoulderPivot/ElbowPivot/Outline.points=PackedVector2Array([Vector2.ZERO,Vector2(forearm.length(),0)])
	$ShoulderPivot/ElbowPivot/Skin.points=$ShoulderPivot/ElbowPivot/Outline.points
	$ShoulderPivot/ElbowPivot/Hand.position=Vector2(forearm.length(),0)
	$ShoulderPivot/ElbowPivot/Hand.rotation=-forearm.angle()
