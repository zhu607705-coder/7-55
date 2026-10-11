extends RefCounted
## Deterministic, presentation-only key poses. The controller has already committed.
const DURATION_MS: float=4200
const TIP:=Vector2(58,-72)
const FRAME:=Vector2(58,-105)
const CLASP:=Vector2(82,-111)
static func _ease(t: float) -> float:
	var p:=clampf(t,0,1)
	return p*p*(3-2*p)
static func sample(ms: float) -> Dictionary:
	var frame_t:=_ease((ms-200)/700)
	var wrap_t:=clampf((ms-900)/1000,0,1)
	var clasp_t:=_ease((ms-1900)/700)
	var tug_t:=clampf((ms-2700)/650,0,1)
	var tug:=sin(tug_t*TAU)*5 if ms>=2700 and ms<3350 else 0.0
	var stow:=_ease((ms-3550)/650)
	var phase: String="frame" if ms<900 else "rope" if ms<1900 else "clasp" if ms<2700 else "tug" if ms<3550 else "stow"
	return {"phase":phase,"frame":Vector2(153,27).lerp(FRAME,frame_t),"frame_contact":frame_t>=1,"wrap":wrap_t,"clasp":Vector2(149,-116).lerp(CLASP,clasp_t),"clasp_contact":clasp_t>=1,"tug":tug,"stow":stow,"rod_tip":TIP,"frame_socket":Vector2(153,27).lerp(FRAME,frame_t)+Vector2(0,33),"done":ms>=DURATION_MS}
