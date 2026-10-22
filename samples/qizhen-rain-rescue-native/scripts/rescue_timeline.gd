extends RefCounted
## Standalone presentation model. Never imports State or emits a story result.
const Geometry=preload("res://scripts/rescue_pose_geometry.gd")
const DURATION: float=15.0
const FALL: float=2.05
const SPLASH: float=2.65
const THROW: float=3.55
const CATCH: float=4.60
const DOCK: float=7.70
const LIFT: float=8.40
const LANDED: float=10.45
const TOWEL: float=11.45
const WALK: float=12.70
var elapsed: float=0.0
var paused: bool=false
var finished: bool=false
var run_id: int=1
var terminal_count: int=0
var outcome: String=""

func reset() -> void:
	elapsed=0.0;paused=false;finished=false;terminal_count=0;outcome="";run_id+=1

func advance(dt: float) -> bool:
	if paused or finished or dt<=0:return false
	elapsed=minf(DURATION,elapsed+dt)
	if elapsed>=DURATION:return finish("played")
	return false

func finish(reason: String) -> bool:
	if finished:return false
	elapsed=DURATION;finished=true;terminal_count+=1;outcome=reason
	return true

func skip() -> bool:return finish("skipped_preview")

static func phase_at(t: float) -> String:
	if t<FALL:return "wind"
	if t<SPLASH:return "fall"
	if t<THROW:return "hold_hull"
	if t<CATCH:return "throw_ring"
	if t<DOCK:return "tow_to_dock"
	if t<LIFT:return "secure_contact"
	if t<LANDED:return "two_person_lift"
	if t<TOWEL:return "on_dock"
	if t<WALK:return "towel"
	if t<DURATION:return "wet_steps"
	return "safe_wet_idle"

static func blend(t: float,a: float,b: float) -> float:return smoothstep(a,b,t)

static func point_at(t: float) -> Vector2:
	# Anchor at upper torso. The head stays visible after the short initial splash.
	if t<FALL:return Vector2(812,553).lerp(Vector2(852,542),blend(t,0,FALL))
	if t<SPLASH:return Vector2(852,542).lerp(Vector2(880,564),blend(t,FALL,SPLASH))+Vector2(0,-18*sin(clampf((t-FALL)/(SPLASH-FALL),0,1)*PI))
	if t<CATCH:return Vector2(880,564)+Vector2(0,sin((t-SPLASH)*4)*1.1)
	if t<DOCK:return Vector2(880,564).lerp(Vector2(782,562),blend(t,CATCH,DOCK))
	if t<LIFT:return Vector2(782,562)
	if t<LANDED:return Vector2(782,562).lerp(Vector2(727,548),blend(t,LIFT,LANDED))+Vector2(0,-16*sin(blend(t,LIFT,LANDED)*PI))
	if t<WALK:return Vector2(727,548)
	return Vector2(727,548).lerp(Vector2(710,580),blend(t,WALK,DURATION))

static func boat_at(t: float) -> Vector2:
	if t<FALL:return point_at(t)+Vector2(0,17)
	return Vector2(852,559).lerp(Vector2(862,530),blend(t,FALL,SPLASH))+Vector2(sin(t*.7)*1.4,cos(t)*.8)

static func teacher_at(t: float) -> Vector2:
	if t<6.40:return Vector2(713,493)
	if t<DOCK:return Vector2(713,493).lerp(point_at(DOCK)+Vector2(-56,6),blend(t,6.40,DOCK))
	if t<LANDED:return point_at(t)+Vector2(-56,6)
	return (point_at(LANDED)+Vector2(-56,6)).lerp(Vector2(684,510),blend(t,LANDED,TOWEL))

static func officer_at(t: float) -> Vector2:
	var contact_root: Vector2=ring_at(clampf(t,DOCK,LANDED))+Geometry.RING_CONTACT_OFFSET-Geometry.OFFICER_HAND_OFFSET
	if t<5.8:return Vector2(700,594)
	if t<DOCK:return Vector2(700,594).lerp(contact_root,blend(t,5.8,DOCK))
	if t<LANDED:return contact_root
	return contact_root.lerp(Vector2(674,575),blend(t,LANDED,TOWEL))

static func ring_at(t: float) -> Vector2:
	if t<THROW:return teacher_at(t)+Vector2(20,-5)
	if t<CATCH:
		var p: float=clampf((t-THROW)/(CATCH-THROW),0,1)
		return (teacher_at(THROW)+Vector2(20,-5)).lerp(point_at(CATCH)+Vector2(0,2),p)+Vector2(0,-68*sin(p*PI))
	if t<LIFT:return point_at(t)+Vector2(0,2)
	if t<LANDED:return (point_at(LIFT)+Vector2(0,2)).lerp(Vector2(782,578),blend(t,LIFT,LANDED))
	return Vector2(782,578).lerp(Vector2(787,578),blend(t,LANDED,TOWEL))

func pose() -> Dictionary:
	var t: float=elapsed
	return {"time":t,"phase":phase_at(t),"player":point_at(t),"boat":boat_at(t),"teacher":teacher_at(t),"officer":officer_at(t),"ring":ring_at(t),"waterline":576.0,"wet":t>=SPLASH,"landed":t>=LANDED,"hand_contact":t>=DOCK and t<LANDED,"finished":finished,"run_id":run_id}
