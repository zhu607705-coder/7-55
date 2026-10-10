extends RefCounted
## Pure, scene-local choreography. The Library controller still owns every fact.
## Durations fit the retained 810 ms service window before its 900 ms dialogue.
const TOTAL_MS: float=810.0
const REDUCED_MS: float=270.0
const RECEIVE_MS: float=300.0
const PAPER_REST:=Vector2(-24,24)
const PAPER_RETURN:=Vector2(-78,24)
const PAPER_SIZE:=Vector2(46,28)
const STAMP_X: float=-35.0
const STAMP_REST_Y: float=7.0
const CONTACT_Y: float=26.0
const CONTACT_MS: float=140.0
const RELEASE_MS: float=230.0
const CLEAR_MS: float=350.0
const RETURN_MS: float=420.0
const RETURN_END_MS: float=720.0
const STAMP_SCALE: float=0.46
# Original 64 x 88 PNG: visible alpha rows [3,84). The ink edge is row 83.
const STAMP_SOURCE_CONTACT_Y: float=84.0

static func smooth(value: float) -> float:
	var t: float=clampf(value,0,1)
	return t*t*(3.0-2.0*t)

static func sample(stamp_ms: float,scan_ms: float,reduced: bool=false) -> Dictionary:
	var time: float=stamp_ms*(TOTAL_MS/REDUCED_MS) if reduced else stamp_ms
	var paper:=PAPER_REST
	var bottom: float=STAMP_REST_Y
	var pressure: float=0
	var ink: float=0
	var alpha: float=1
	var phase: String="idle"
	var visible: bool=scan_ms>=0 or stamp_ms>=0
	if stamp_ms<0 and scan_ms>=0:
		phase="receiving" if scan_ms<RECEIVE_MS else "checking"
		paper=PAPER_RETURN.lerp(PAPER_REST,smooth(scan_ms/(100.0 if reduced else RECEIVE_MS)))
	elif stamp_ms>=0:
		if time<CONTACT_MS:
			phase="descending"; bottom=lerpf(STAMP_REST_Y,CONTACT_Y,smooth(time/CONTACT_MS))
		elif time<RELEASE_MS:
			phase="pressing"; pressure=smooth((time-CONTACT_MS)/40.0)
			bottom=CONTACT_Y+pressure*0.8; ink=pressure
		elif time<CLEAR_MS:
			phase="lifting"
			var release: float=smooth((time-RELEASE_MS)/(CLEAR_MS-RELEASE_MS))
			pressure=1-release; bottom=lerpf(CONTACT_Y+0.8,STAMP_REST_Y,release); ink=1
		elif time<RETURN_MS: phase="reveal"; ink=1
		elif time<RETURN_END_MS:
			phase="returning"; ink=1
			paper=PAPER_REST.lerp(PAPER_RETURN,smooth((time-RETURN_MS)/(RETURN_END_MS-RETURN_MS)))
		else:
			phase="handoff"; ink=1; paper=PAPER_RETURN
			alpha=1-smooth((time-RETURN_END_MS)/(TOTAL_MS-RETURN_END_MS))
	var mark: Vector2=paper+Vector2(STAMP_X-PAPER_REST.x,CONTACT_Y-PAPER_REST.y)
	return {"phase":phase,"paper":paper,"paperSize":PAPER_SIZE,"visible":visible,"alpha":alpha,"pressure":pressure,"ink":ink,"mark":mark,"contact":Vector2(STAMP_X,CONTACT_Y+pressure*0.8),"stampBottom":Vector2(STAMP_X,bottom),"stampScale":STAMP_SCALE,"stampRect":Rect2(Vector2(STAMP_X-32*STAMP_SCALE,bottom-STAMP_SOURCE_CONTACT_Y*STAMP_SCALE),Vector2(64,88)*STAMP_SCALE)}

static func paper_point(local: Vector2,pose: Dictionary) -> Vector2:
	# Only the sheet flexes locally under the registered foot. No global squash.
	var mark_local: Vector2=Vector2(pose.mark)-Vector2(pose.paper)
	var distance: float=local.distance_to(mark_local)
	var flex: float=(1-smooth(distance/15.0))*float(pose.pressure)*0.8
	return Vector2(pose.paper)+local+Vector2(0,flex)
