extends RefCounted
## Ephemeral visual pose only. Never validates an answer or writes State.
const DURATION := .18
var position := Vector2.ZERO
var angle := 0.0
var start_position := Vector2.ZERO
var start_angle := 0.0
var target_position := Vector2.ZERO
var target_angle := 0.0
var elapsed := DURATION
var flash_elapsed := .2
var initialized := false
var completed := false
var transitions := 0
var reduced_motion := false
func seed_pose(point: Vector2,radians: float,done: bool) -> void:
	position=point;angle=radians;start_position=point;start_angle=radians;target_position=point;target_angle=radians
	elapsed=DURATION;flash_elapsed=.2;initialized=true;completed=done
func retarget(point: Vector2,radians: float,done: bool) -> void:
	if not initialized:seed_pose(point,radians,done);return
	if done and not completed:flash_elapsed=0
	completed=done
	if point.is_equal_approx(target_position) and is_equal_approx(radians,target_angle):return
	start_position=position;start_angle=angle;target_position=point;target_angle=radians;elapsed=0;transitions+=1
	if reduced_motion:position=point;angle=radians;elapsed=DURATION
func advance(delta: float) -> void:
	var dt:=maxf(0,delta)
	elapsed=minf(DURATION,elapsed+dt);flash_elapsed=minf(.2,flash_elapsed+dt)
	var t:=1.0 if reduced_motion else smoothstep(0,DURATION,elapsed)
	position=start_position.lerp(target_position,t);angle=lerp_angle(start_angle,target_angle,t)
	if elapsed>=DURATION:position=target_position;angle=target_angle
func success_alpha() -> float:return 0.0 if flash_elapsed>=.2 else .55*sin(PI*flash_elapsed/.2)
