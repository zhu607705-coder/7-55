extends RefCounted
## Anchor 52: the accepted wheel-cover fact drives a 200ms local hinge.
## Never writes story state, consumes an item, or delays another interaction.
const DURATION_MS:=200.0
const OPEN_ANGLE:=-42.0
const FACT:="cart_wheel_cover_opened"
var state_owner:Dictionary={}
var context_key:=""
var opened:=false
var elapsed_ms:=DURATION_MS
var started_ms:=-1

func _facts(state:Dictionary)->Array:
	var value:Variant=state.get("chapter4",{}).get("factIds",[])
	return value if value is Array else []
func _key(state:Dictionary)->String:
	var c:Dictionary=state.get("chapter4",{})
	return str([c.get("floor",""),c.get("phase",""),c.get("timeState",""),c.get("mode","")])
func _now(value:int)->int:return Time.get_ticks_msec() if value<0 else value
func _sync(state:Dictionary,now:int)->void:
	var next:bool=FACT in _facts(state)
	var key:=_key(state)
	if not is_same(state,state_owner) or key!=context_key:
		state_owner=state;context_key=key;opened=next;cancel();return
	if next!=opened:
		opened=next
		elapsed_ms=0.0 if opened else DURATION_MS
		started_ms=now if opened else -1
	if "cart_wheel_repaired" in _facts(state):cancel()
func cancel()->void:
	elapsed_ms=DURATION_MS;started_ms=-1
func tick(delta:float,state:Dictionary,now_ms:=-1)->void:
	var previous_start:=started_ms
	_sync(state,_now(now_ms))
	# This delta precedes a newly observed controller fact. Start at 0ms;
	# only later frames may advance this accepted hinge interval.
	if started_ms!=previous_start:return
	if is_finite(delta):elapsed_ms=minf(DURATION_MS,elapsed_ms+clampf(delta,0,.05)*1000.0)
func sample(state:Dictionary,now_ms:=-1)->Dictionary:
	var now:=_now(now_ms)
	_sync(state,now)
	var elapsed:=elapsed_ms
	# After a hidden/paused interval, an accepted result resumes at its final
	# pose instead of replaying a stale half-open cover. No callback is queued.
	if started_ms>=0:elapsed=maxf(elapsed,minf(DURATION_MS,maxf(0,now-started_ms)))
	var reduced:bool=bool(state.get("native",{}).get("settings",{}).get("reduced_motion",false))
	if reduced:
		cancel();elapsed=DURATION_MS
	var amount:=1.0 if reduced else smoothstep(0,DURATION_MS,elapsed)
	var progress:=amount if opened else 0.0
	return {"angle_degrees":OPEN_ANGLE*progress,"progress":progress,"opened":opened,"moving":opened and progress<1.0,"visible":"cart_wheel_repaired" not in _facts(state)}
