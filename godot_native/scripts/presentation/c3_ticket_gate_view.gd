extends RefCounted
## Runtime-only acrylic wings. Admission/collisions remain controller-owned.
const Metrics=preload("res://scripts/player_metrics.gd")
const PASSAGE:=Rect2(774,650,126,80)
const APPROACH:=Rect2(754,620,166,190)
const CLEAR_HOLD_MS:=450.0
var openness:float=0
var hold_ms:float=0
var admitted_seen:bool=false
var session_clock:float=INF
func player(s:Dictionary)->Vector2:
	var p:Dictionary=s.native.get("player",{})
	return Vector2(p.get("x",0),p.get("y",0))
func near(s:Dictionary)->bool:return APPROACH.intersects(Metrics.foot_rect(player(s)))
func occupied(s:Dictionary)->bool:return PASSAGE.intersects(Metrics.foot_rect(player(s)))
func reset(s:Dictionary)->void:
	admitted_seen=bool(s.theaterHunt.admitted)
	openness=1.0 if admitted_seen and near(s) else 0.0
	hold_ms=CLEAR_HOLD_MS if openness>0 else 0.0
	session_clock=INF
func tick(ms:float,s:Dictionary,session:RefCounted=null)->void:
	if not bool(s.theaterHunt.admitted):reset(s);return
	var dt:float=clampf(ms,0,100)
	if session!=null and session.sequence_id=="theater_admission" and session.valid(s) and session.status in ["issued","playing","complete"]:
		var now:float=session.elapsed_ms
		dt=clampf(now-(session_clock if is_finite(session_clock) else 0.0),0,1000)
		session_clock=now
	else:session_clock=INF
	admitted_seen=true
	var motion_ms:float=dt
	if near(s):hold_ms=CLEAR_HOLD_MS
	else:
		var waiting:float=minf(hold_ms,dt)
		hold_ms-=waiting;motion_ms-=waiting
	var target:float=1.0 if near(s) or hold_ms>0 else 0.0
	var duration:float=120.0 if bool(s.native.settings.reduced_motion) else 420.0
	# Never sweep a closing/opening panel through a valid admitted foot body.
	# The wider approach zone normally opens before this safety strip is reached.
	if occupied(s):openness=1.0
	else:openness=move_toward(openness,target,motion_ms/duration)
func pose()->Dictionary:
	var eased:float=(1-cos(openness*PI))/2
	return {"open_ratio":eased,"left_inner":lerpf(833.0,789.0,eased),"right_inner":lerpf(836.0,880.0,eased)}
