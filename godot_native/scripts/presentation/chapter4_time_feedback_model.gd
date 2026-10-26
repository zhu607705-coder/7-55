extends RefCounted
## Earned-fact presentation only. No controller, persistence or input authority.
const SCENE := "duan_yongping_temporal_maze"
const FACTS := {
	"comparison":"a1_time_route_compared",
	"restoration":"room204_projection_completed",
	"minute":"final_minute_installed",
}
const DURATIONS := {"comparison":1.1,"restoration":1.2,"minute":1.1}
const REPLAY_SECONDS := 7*3600+47*60+5
const RECORD_SECONDS := 7*3600+55*60

static func cue_for(action: String,previous: Dictionary,current: Dictionary) -> String:
	if not action.begins_with("c4_") or current.get("native",{}).get("scene","")!=SCENE: return ""
	var before: Dictionary=previous.get("chapter4",{})
	var after: Dictionary=current.get("chapter4",{})
	if not before.get("prologueSeen",false) or not after.get("prologueSeen",false): return ""
	for cue: String in FACTS:
		if FACTS[cue] in before.get("factIds",[]) or FACTS[cue] not in after.get("factIds",[]): continue
		if cue=="comparison" and after.get("phase","")=="room204_restore": return cue
		if cue=="restoration" and action=="c4_projection_done" and after.get("phase","")=="room204_restore" and after.get("floor","")=="A2": return cue
		if cue=="minute" and action=="c4_install_minute" and after.get("phase","")=="morning_checkin" and after.get("floor","")=="A1": return cue
	return ""

static func settle_ease(value: float) -> float:
	var t:=clampf(value,0,1)
	return t*t*(3-2*t)

static func sample(cue: String,seconds: float,reduced: bool=false) -> Dictionary:
	var duration: float=DURATIONS.get(cue,1.0)
	var t:=clampf(seconds/duration,0,1)
	# Reduced motion holds a fully legible static result; never animates a fade,
	# clock hand, placement or connecting trace. The host simply removes it.
	var settle:=1.0 if reduced else settle_ease(t/.48)
	return {"duration":duration,"progress":t,"settle":settle,
		"alpha":1.0 if reduced else 1.0-settle_ease((t-.82)/.18),
		"offset":0.0 if reduced else 14.0*(1.0-settle),
		"minute_angle":lerpf(54.0,55.0,settle)*TAU/60.0,
		"phone_alpha":1.0 if reduced else settle_ease((t-.56)/.18),
		"delta_seconds":RECORD_SECONDS-REPLAY_SECONDS}
