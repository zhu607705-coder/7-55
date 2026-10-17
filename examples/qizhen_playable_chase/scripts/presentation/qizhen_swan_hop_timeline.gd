extends RefCounted
## Pose sequence + short ballistic hop. No game state, saves, or chase authority.
const DURATION: float=7.0
const TAKEOFF: float=2.52
const LANDING: float=3.38
const HEIGHT: float=32.0
const KEY_TIMES: Array[float]=[0.0,1.2,1.4,1.6,1.8,2.0,2.2,2.4,2.52,2.72,2.94,3.16,3.38,3.63,3.87,4.12]
const START:=Vector2(860,420)
const END:=Vector2(815,430)
var elapsed: float=0
var paused: bool=false
var launch_count: int=0
var landing_count: int=0

func reset() -> void:
	elapsed=0;paused=false;launch_count=0;landing_count=0

func advance(dt: float) -> void:
	if paused or not is_finite(dt) or dt<=0:return
	var old: float=elapsed
	elapsed=minf(DURATION,elapsed+dt)
	if old<TAKEOFF and elapsed>=TAKEOFF:launch_count+=1
	if old<LANDING and elapsed>=LANDING:landing_count+=1

func position_at(t: float) -> Vector2:
	return START.lerp(END,smoothstep(2.4,3.6,t))

func pose() -> Dictionary:
	var frame: int=0
	for i: int in range(KEY_TIMES.size()):
		if elapsed>=KEY_TIMES[i]:frame=i
	var air: float=clampf((elapsed-TAKEOFF)/(LANDING-TAKEOFF),0,1)
	var height: float=4*HEIGHT*air*(1-air) if elapsed>=TAKEOFF and elapsed<=LANDING else 0.0
	var state: String="折翅浮水"
	if frame in [1,2]:state="蓄力 · 翼根抬起"
	elif frame in [3,4,5]:state="翼尖逐步展开"
	elif frame==6:state="完整展翅"
	elif frame in [7,8]:state="下拍蹬水"
	elif frame in [9,10,11]:state="短暂离水"
	elif frame==12:state="落水缓冲"
	elif frame in [13,14]:state="逐步收翅"
	elif frame==15:state="收翅恢复平游"
	return {"frame":frame,"point":position_at(elapsed),"height":height,"state":state,"launch_age":elapsed-TAKEOFF,"landing_age":elapsed-LANDING}
