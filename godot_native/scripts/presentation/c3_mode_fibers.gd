extends RefCounted
## CanteenInteriorScene.createDarkModeLayer / playModeTransition, presentation only.
## No timer, random call, controller dispatch, inventory write, or completion event.
const POINTS := [Vector2(790,218),Vector2(82,250),Vector2(1380,850),Vector2(1235,227)]
const COLOR := Color("8be6ff",.92)
const DEPTH := 1602.0
const FADE_MS := 220.0
const REDUCED_FADE_MS := 120.0
var scene_id := ""
var mode := ""
var initialized := false
var reduced := false
var defense_hidden := false
var clock_ms := 0.0
var fade_ms := INF
var fade_duration := FADE_MS
var fade_from: Array[float] = [0.0,0.0,0.0,0.0]
var loop_ms: Array[float] = [0.0,0.0,0.0,0.0]
var loop_backward: Array[bool] = [false,false,false,false]
var loop_mix: Array[float] = [0.0,0.0,0.0,0.0]

func sync(state: Dictionary,reset: bool=false) -> void:
	var native: Dictionary=state.get("native",{})
	var next_scene:=str(native.get("scene",""))
	var next_mode:=str(native.get("mode","light"))
	var next_reduced:=bool(native.get("settings",{}).get("reduced_motion",false))
	var blocking:=str(state.get("canteenHunt",{}).get("phase",""))=="exit_blocking"
	if reset or not initialized or scene_id!=next_scene:
		initialized=true; scene_id=next_scene; mode=next_mode; reduced=next_reduced
		clock_ms=0; fade_ms=INF; defense_hidden=blocking
		loop_ms=[0.0,0.0,0.0,0.0]; loop_backward=[false,false,false,false]; loop_mix=[0.0,0.0,0.0,0.0]
		fade_from=[0.0,0.0,0.0,0.0]
		return
	if next_mode!=mode:
		for i in range(4): fade_from[i]=0.0 if next_mode=="dark" else _alpha(i)
		mode=next_mode; fade_ms=0; fade_duration=REDUCED_FADE_MS if next_reduced else FADE_MS
		# Source finishDefense hides fibers until an actual mode switch or reentry.
		defense_hidden=blocking
	reduced=next_reduced
	if reduced and fade_ms!=INF: fade_duration=REDUCED_FADE_MS
	if blocking:
		defense_hidden=true; fade_ms=INF

func tick(delta: float,state: Dictionary) -> void:
	sync(state)
	if scene_id!="canteen_interior": return
	var dt:=maxf(0,delta)*1000
	clock_ms+=dt
	if fade_ms!=INF: fade_ms+=dt
	# World owns this clock. Hidden phone/world and SceneTree pause supply no tick.
	# Reduced motion keeps four readable static source points instead of flicker.
	if reduced or dt<=0: return
	for i in range(4):
		var duration:=420.0+i*37.0
		loop_ms[i]+=dt
		# Phaser's default Stepped ease has ONE step. It is not a sine/bob loop.
		# Preserve the one-frame start pose whenever a backward leg ends.
		var completed:=loop_ms[i]>=duration
		var progress:=clampf(loop_ms[i]/duration,0,1)
		if loop_backward[i]: progress=1.0-progress
		loop_mix[i]=0.0 if progress<=0 else 1.0
		if completed:
			loop_ms[i]-=duration; loop_backward[i]=not loop_backward[i]

func _alpha(index: int) -> float:
	var idle:=.9 if reduced else lerpf(.2,.95,loop_mix[index])
	if fade_ms==INF: return idle if mode=="dark" else 0.0
	var delay:=0.0 if reduced else minf(80,index*9.0)
	var ratio:=clampf((fade_ms-delay)/fade_duration,0,1)
	if fade_ms<=fade_duration+delay: return lerpf(fade_from[index],.9 if mode=="dark" else 0.0,ratio)
	return idle if mode=="dark" else 0.0

func entries() -> Array:
	var result: Array=[]
	if scene_id!="canteen_interior" or defense_hidden: return result
	for i in range(4):
		var delay:=0.0 if reduced else minf(80,i*9.0)
		if mode!="dark" and (fade_ms==INF or fade_ms>=fade_duration+delay): continue
		var mix_value:=0.0 if reduced else loop_mix[i]
		result.append({"id":"mode_fiber_"+str(i),"kind":"circle","point":POINTS[i]+Vector2(11 if i%2==0 else -9,-9)*mix_value,"radius":2+i%2,"color":COLOR,"alpha":_alpha(i),"depth":DEPTH})
	return result
