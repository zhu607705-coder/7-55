extends RefCounted
## Read-only articulation samples for the native kayak rig. No rendering or physics.
const STROKE_MS: float=680.0
var layers: Dictionary={}
func _load() -> void:
	if not layers.is_empty(): return
	for id: String in ["hull","seated_player"]:
		layers[id]=load("res://assets/native/kayak/"+id+".svg")

static func _ease(value: float) -> float:
	var t:=clampf(value,0,1)
	return t*t*(3-2*t)

static func stroke_pose(side: String,age_ms: float,reverse: bool=false,roll: float=0) -> Dictionary:
	var sign_x: float=-1 if side=="left" else 1
	var t:=clampf(age_ms/STROKE_MS,0,1)
	var phase: String="rest"
	var sweep: float=-.72
	var wet: float=0
	var lift: float=0
	if age_ms>=0 and age_ms<STROKE_MS:
		if t<.18:
			phase="entry";sweep=lerpf(-.72,-1.05,_ease(t/.18));wet=_ease(t/.18)
		elif t<.56:
			phase="pull";sweep=lerpf(-1.05,.82,_ease((t-.18)/.38));wet=1
		elif t<.73:
			phase="exit";sweep=lerpf(.82,1.02,_ease((t-.56)/.17));wet=1-_ease((t-.56)/.17);lift=sin((t-.56)/.17*PI/2)*6
		else:
			phase="recovery";sweep=lerpf(1.02,-.72,_ease((t-.73)/.27));lift=sin((1-t)/.27*PI/2)*6
	if reverse: sweep=-sweep
	var grip:=Vector2(sign_x*(17+wet*3),9+sin(sweep)*9-lift)
	var tip:=grip+Vector2(sign_x*cos(sweep),sin(sweep))*58
	var bend: float=(8*wet*sin(clampf((t-.18)/.38,0,1)*PI)) if side=="left" else 0
	if reverse: bend=-bend
	var shoulder:=Vector2(sign_x*11+roll*3,15)
	var elbow:=shoulder.lerp(grip,.55)+Vector2(sign_x*(8+absf(roll)*3),5)
	return {"phase":phase,"grip":grip,"tip":tip,"shaft_mid":grip.lerp(tip,.55)+Vector2(0,bend),"shoulder":shoulder,"elbow":elbow,"wet":wet,"lift":lift,"bend":bend,"reverse":reverse,"ageMs":age_ms}

static func paddle_poses(pose: Dictionary) -> Dictionary:
	var result: Dictionary={}
	for side: String in ["left","right"]:
		var age: float=10000
		var reverse: bool=false
		var events: Array=pose.get("strokeEvents",[])
		if pose.has("strokeEvents"):
			for i in range(events.size()-1,-1,-1):
				var input: Dictionary=events[i]
				if input.get("side")==side:
					age=(float(pose.get("tick",0))-float(input.get("tick",0)))*1000.0/120.0
					reverse=input.get("direction","")=="reverse"
					break
		elif pose.get("side","")==side:
			age=float(pose.get("strokeAgeMs",10000));reverse=pose.get("direction","")=="reverse"
		result[side]=stroke_pose(side,age,reverse,float(pose.get("roll",0)))
	return result
