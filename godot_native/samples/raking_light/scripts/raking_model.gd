extends RefCounted
## Runtime-only local puzzle. No save, item, chapter or formal evidence writes.
const HOLD_SECONDS := 1.4
const PAPER_TILT_LIMIT := 18.0
const LAMP_AZIMUTH_LIMIT := 145.0
const LAMP_ELEVATION_MIN := 8.0
const LAMP_ELEVATION_MAX := 82.0
var paper_tilt := Vector2.ZERO
var lamp_azimuth := 28.0
var lamp_elevation := 80.0
var owners: Dictionary = {}
var stable_time := 0.0
var quiet_time := 0.0
var completed := false
var completion_count := 0
var suspended := false
var paper_moved := false
var lamp_moved := false

func start(id: int, object: String) -> bool:
	if suspended or completed or owners.has(id) or object not in ["paper","lamp","history"]: return false
	if owners.values().has(object): return false
	owners[id]=object
	return true

func drag(id: int, delta: Vector2) -> void:
	if not owners.has(id) or suspended or completed or not delta.is_finite(): return
	match owners[id]:
		"paper":
			paper_tilt.x=clampf(paper_tilt.x-delta.y*0.16,-PAPER_TILT_LIMIT,PAPER_TILT_LIMIT)
			paper_tilt.y=clampf(paper_tilt.y+delta.x*0.16,-PAPER_TILT_LIMIT,PAPER_TILT_LIMIT)
			if delta.length()>0.25: paper_moved=true; quiet_time=0; stable_time=0
		"lamp":
			lamp_azimuth=clampf(lamp_azimuth+delta.x*0.40,-LAMP_AZIMUTH_LIMIT,LAMP_AZIMUTH_LIMIT)
			lamp_elevation=clampf(lamp_elevation-delta.y*0.50,LAMP_ELEVATION_MIN,LAMP_ELEVATION_MAX)
			if delta.length()>0.25: lamp_moved=true; quiet_time=0; stable_time=0

func release(id: int) -> void:
	owners.erase(id)

func cancel_all() -> void:
	owners.clear()
	stable_time=0
	quiet_time=0

func suspend() -> void:
	cancel_all()
	suspended=true

func resume() -> void:
	# Explicit resume never restores stale pointers or a partial observation timer.
	cancel_all()
	suspended=false

func reset() -> void:
	cancel_all()
	paper_tilt=Vector2.ZERO; lamp_azimuth=28; lamp_elevation=80
	completed=false; completion_count=0; suspended=false
	paper_moved=false; lamp_moved=false

func update(delta: float, visibility: Dictionary) -> void:
	if suspended or completed: return
	if not is_finite(delta) or delta<=0: return
	if delta>0.25:
		# A stalled/background frame is not evidence of continuous observation.
		stable_time=0; quiet_time=0
		return
	quiet_time+=delta
	# Actual lamp-space normals/coverage come from the same world mesh used to render.
	var contrast: float=visibility.get("contrast",0.0)
	var coverage: float=visibility.get("coverage",0.0)
	var incidence: float=visibility.get("incidence",90.0)
	var visible: bool=is_finite(contrast) and is_finite(coverage) and is_finite(incidence) and contrast>=0.13 and coverage>=0.72 and incidence>=3.0 and incidence<=24.0
	if visible and paper_moved and lamp_moved and quiet_time>=0.20:
		stable_time+=delta
	else: stable_time=0
	if stable_time>=HOLD_SECONDS:
		completed=true; completion_count+=1; owners.clear()
