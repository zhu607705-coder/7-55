extends RefCounted
## Runtime-only controller-issued capability. Do not serialize into GameState.
## The retained object identity, actual monotonic elapsed time, registered live
## presenter and source state guards are all required for controller consumption.
const Model=preload("res://scripts/media/c3_rain_rescue_model.gd")
var _phase: String="issued"
var _reduced: bool=false
var _initial: Vector2=Model.APPROACH_POINT
var _presenter: WeakRef
var _started_ms: int=-1
var _cinematic_started_ms: int=-1
var _rescued_ms: int=-1
var _outcome: String=""
var _reason: String=""
var _bound_state: Dictionary
var _paused_at: int=-1

static func eligible(s: Dictionary) -> bool:
	var q: Dictionary=s.get("qizhenLake",{})
	return s.get("runtimeMode")=="rpg" and s.get("rpgScene")=="qizhen_lake" and s.get("native",{}).get("scene")=="qizhen_lake" and q.get("active",false) and q.get("phase")=="boarding_tutorial" and q.get("zone")=="dock" and q.get("vehicle")=="on_foot" and q.get("rainWarningSeen",false) and not q.get("rainSafetyCleared",false) and not q.get("rainRescueCompleted",false)

func configure(reduced_motion: bool=false, initial_player: Vector2=Model.APPROACH_POINT, state: Dictionary={}) -> void:
	if _phase!="issued": return
	_bound_state=state
	_reduced=reduced_motion
	_initial=initial_player if initial_player.is_finite() else Model.APPROACH_POINT

func begin(presenter: Node) -> bool:
	if _phase!="issued" or not is_instance_valid(presenter) or not presenter.is_inside_tree(): return false
	_presenter=weakref(presenter)
	_started_ms=Time.get_ticks_msec()
	_phase="route"
	return true

func _owns(presenter: Node) -> bool:
	return _presenter!=null and _presenter.get_ref()==presenter and is_instance_valid(presenter) and presenter.is_inside_tree()

func sample(presenter: Node, focused: bool=true) -> Dictionary:
	if not _owns(presenter): return {}
	var now: int=Time.get_ticks_msec()
	if not focused:
		if _paused_at<0: _paused_at=now
		return snapshot()
	if _paused_at>=0:
		var delay: int=now-_paused_at
		_started_ms+=delay
		if _cinematic_started_ms>=0: _cinematic_started_ms+=delay
		if _rescued_ms>=0: _rescued_ms+=delay
		_paused_at=-1
	if _phase=="route" and now-_started_ms>=Model.pre_cinematic_ms(_reduced):
		_phase="cinematic"
		_cinematic_started_ms=now
	if _phase=="cinematic" and now-_cinematic_started_ms>=Model.WATCHDOG_MS:
		finish_cinematic(presenter,"fallback","watchdog")
	if _phase=="rescued" and now-_rescued_ms>=Model.timing(_reduced).rescueHoldMs: _phase="complete"
	return snapshot()

func finish_cinematic(presenter: Node, result: String, reason: String="") -> bool:
	if not _owns(presenter) or _paused_at>=0 or _phase!="cinematic" or result not in ["video","fallback","skipped"]: return false
	# A video-ended callback is not credible before the actual asset could end.
	if result=="video" and Time.get_ticks_msec()-_cinematic_started_ms<Model.VIDEO_DURATION_MS-80: return false
	_outcome=result
	_reason=reason
	_rescued_ms=Time.get_ticks_msec()
	_phase="rescued"
	return true

func snapshot() -> Dictionary:
	var now: int=_paused_at if _paused_at>=0 else Time.get_ticks_msec()
	var pose: Dictionary=Model.pose_at(maxi(0,now-_started_ms),_reduced,_initial)
	if _phase in ["rescued","complete","consumed"]: pose=Model.rescued_pose(maxi(0,now-_rescued_ms),_reduced)
	return {"phase":_phase,"reduced":_reduced,"pose":pose,"outcome":_outcome,"reason":_reason,"elapsedMs":maxi(0,now-_started_ms),"cinematicMs":maxi(0,now-_cinematic_started_ms) if _cinematic_started_ms>=0 else 0}

func reduced_motion() -> bool: return _reduced
func phase() -> String: return _phase

func cancel() -> void:
	if _phase=="consumed": return
	_phase="cancelled"
	_presenter=null

func consume(s: Dictionary) -> bool:
	if _phase!="complete" or _presenter==null or not is_instance_valid(_presenter.get_ref()) or not eligible(s) or (not _bound_state.is_empty() and not is_same(s,_bound_state)): return false
	if _started_ms<0 or _rescued_ms<0 or Time.get_ticks_msec()-_started_ms<Model.duration_ms(_reduced) or Time.get_ticks_msec()-_rescued_ms<Model.timing(_reduced).rescueHoldMs: return false
	_phase="consumed"
	_presenter=null
	return true
