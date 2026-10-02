extends RefCounted
## Literal port of src/modules/QizhenSwanChasePressureModel.ts.
const PROFILES: Dictionary={"release_warning":{"near":90.0,"far":348.0},"tracking":{"near":168.0,"far":440.0},"charge_warning":{"near":142.0,"far":348.0},"charge":{"near":268.0,"far":500.0},"recovery":{"near":132.0,"far":352.0}}
static func initial(player_y: float) -> Dictionary:
	return {"phase":"release_warning","phaseElapsedMs":0.0,"cycleIndex":0,"aimY":finite_or(player_y,0),"segment":"opening"}
static func finite_or(value: Variant,fallback: float) -> float:
	return float(value) if (value is float or value is int) and is_finite(float(value)) else fallback
static func segment_at(progress: float) -> String:
	var p: float=clampf(finite_or(progress,0),0,1)
	return "final_bank" if p>=0.78 else ("mid_channel" if p>=0.24 else "opening")
static func profile(phase: String,segment: String) -> Dictionary:
	var result: Dictionary=PROFILES[phase].duplicate()
	if segment=="final_bank" and phase not in ["release_warning","charge_warning"]:
		result.near+=18 if phase=="charge" else 12
		result.far+=20 if phase=="charge" else 14
	return result
static func danger(gap_value: Variant,catch_value: Variant,near_value: Variant,far_value: Variant) -> Dictionary:
	var catch_distance: float=finite_or(catch_value,0)
	var near_distance: float=maxf(catch_distance+1,finite_or(near_value,catch_distance+1))
	var far_distance: float=maxf(near_distance+1,finite_or(far_value,near_distance+1))
	var gap: float=finite_or(gap_value,far_distance)
	var risk: float=1-clampf((gap-catch_distance)/maxf(1,far_distance-catch_distance),0,1)
	return {"riskRatio":risk,"dangerBand":"critical" if gap<=near_distance+22 else ("pressured" if gap<=catch_distance+(far_distance-catch_distance)*0.57 else "safe")}
static func next_phase(source: Dictionary,input: Dictionary,dt: float,segment: String) -> String:
	var elapsed: float=maxf(0,finite_or(input.elapsedSeconds,0)*1000)
	if elapsed<1100: return "release_warning"
	var after: float=float(source.phaseElapsedMs)+dt
	if source.phase=="release_warning": return "tracking"
	if source.phase=="charge_warning": return "charge" if input.catchReady and after>=620 else "charge_warning"
	var max_gap: float=finite_or(input.farDistance,360)+24
	var gap: float=finite_or(input.actualGap,max_gap+1)
	var readable: bool=gap>=finite_or(input.catchDistance,0)+18 and gap<=max_gap
	if not input.catchReady:
		return "charge_warning" if source.phase=="tracking" and source.cycleIndex==0 and elapsed>=2700 and readable else "tracking"
	if source.phase=="charge": return "recovery" if after>=560 else "charge"
	if source.phase=="recovery": return "tracking" if after>=760 else "recovery"
	var tracking_ms: float=980 if segment=="final_bank" else (1580 if segment=="mid_channel" else 1900)
	return "charge_warning" if after>=tracking_ms and readable else "tracking"
static func step(source: Dictionary,input: Dictionary) -> Dictionary:
	var dt: float=clampf(finite_or(input.deltaMs,0),0,100)
	var segment: String=segment_at(finite_or(input.progressRatio,0))
	var phase: String=next_phase(source,input,dt,segment)
	var changed: bool=phase!=source.phase
	var segment_changed: bool=segment!=source.segment
	var aim: float=source.aimY
	var player_y: float=finite_or(input.playerY,aim)
	if phase=="charge_warning" and changed: aim=player_y
	elif phase not in ["charge_warning","charge"]: aim=lerpf(aim,player_y,1-exp(-5.4*dt/1000))
	var state: Dictionary={"phase":phase,"phaseElapsedMs":0.0 if changed else source.phaseElapsedMs+dt,"cycleIndex":source.cycleIndex+int(source.phase=="recovery" and phase=="tracking"),"aimY":aim,"segment":segment}
	var speed_profile: Dictionary=profile(phase,segment)
	var factor: float=clampf((finite_or(input.actualGap,input.farDistance)-float(input.nearDistance))/maxf(1,float(input.farDistance)-float(input.nearDistance)),0,1)
	factor=factor*factor*(3-2*factor)
	var cue: String="none"
	if segment_changed and segment=="final_bank": cue="final_bank"
	elif changed:
		if phase=="release_warning": cue="release"
		elif phase=="charge_warning": cue="telegraph"
		elif phase=="charge": cue="surge"
	var boost: float={"charge":0.2,"charge_warning":0.1,"recovery":-0.08}.get(phase,0.0)+(0.08 if segment=="final_bank" else 0.0)
	var period: float=maxf(46,float({"charge":54,"charge_warning":76,"recovery":126,"release_warning":138}.get(phase,102))-(10 if segment=="final_bank" else 0))
	var result: Dictionary={"state":state,"phaseChanged":changed,"segmentChanged":segment_changed,"targetSpeed":lerpf(speed_profile.near,speed_profile.far,factor),"speedProfile":speed_profile,"lateralSwayScale":{"release_warning":0.3,"charge_warning":0.08,"charge":0.02,"recovery":0.5}.get(phase,1.0),"visualIntensityBoost":boost,"wingBeatPeriodMs":period,"cue":cue}
	result.merge(danger(input.actualGap,input.catchDistance,input.nearDistance,input.farDistance))
	return result
