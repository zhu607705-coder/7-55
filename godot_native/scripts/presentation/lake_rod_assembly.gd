extends RefCounted
## Read-only object poses, never inventory or controller state.
const DURATION_MS: float=7200
const TIP:=Vector3(.45,0,0)
const FRAME:=Vector3(.95,0,0)
const CLASP_LOCAL:=Vector3(.2569,.0312,-.2554)
const CLASP:=FRAME+CLASP_LOCAL
static func _ease(t: float) -> float:
	var p:=clampf(t,0,1)
	return p*p*(3-2*p)
static func sample(ms: float) -> Dictionary:
	var frame_t:=_ease((ms-400)/1600)
	var wrap:=clampf((ms-2250)/1150,0,1)
	var tension:=_ease((ms-3400)/400)
	var clasp_t:=_ease((ms-4050)/600)
	var detent: float=sin(clampf((ms-4650)/200,0,1)*TAU)*.028 if ms>=4650 and ms<4850 else 0.0
	var tug_t:=clampf((ms-5250)/1000,0,1)
	var flex:=sin(tug_t*TAU)*.055 if ms>=5250 and ms<6250 else 0.0
	var stow:=_ease((ms-6400)/800)
	var phase: String="frame" if ms<2000 else "rope" if ms<3800 else "clasp" if ms<5000 else "tug" if ms<6400 else "stow"
	var frame:=Vector3(1.24,.32,-.68).lerp(FRAME,frame_t)+Vector3(0,flex,0)
	var rotation:=Vector3(0,lerpf(-.55,0,frame_t),lerpf(.1,0,frame_t))
	var clasp:=Vector3(1.42,.15,.7).lerp(frame+CLASP_LOCAL,clasp_t)+Vector3(0,detent,0)
	return {"phase":phase,"frame":frame,"frame_rotation":rotation,"frame_contact":frame_t>=1,"wrap":wrap,"tension":tension,"clasp":clasp,"clasp_contact":ms>=4850,"detent":detent,"tug":flex,"stow":stow,"rod_tip":TIP+Vector3(0,flex,0),"frame_socket":frame+Basis.from_euler(rotation)*Vector3(-.5,0,0),"done":ms>=DURATION_MS}
