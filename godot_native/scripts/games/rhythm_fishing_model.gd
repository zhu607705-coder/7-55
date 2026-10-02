extends RefCounted
## Deterministic lake-rhythm-v4 port. Audio and rendering never own the clock.
const INPUT_LIMIT: int=4096
var chart_id: String="locker_key"
var beat_sec: float=0.6
var beat_pattern: Array=[1,1,1,1]
var timing_scale: float=1.0
var fish_motion_scale: float=1.0
var rhythm_name: String="四拍收放"
var difficulty: int=1
var assist: bool=false
var notes: Array=[]
var phase: String="idle"
var stage: String="casting"
var elapsed: float=0.0
var physics_tick: int=0
var cast_at: float=-1.0
var held_at: float=-1.0
var controls: Dictionary={}
var tension: float=40.0
var line_x: float=-0.5
var tracking_seconds: float=0.0
var cast_attempts: int=0
var combo: int=0
var max_combo: int=0
var judged: int=0
var inputs: Array=[]
var cue: String="左右移动浮漂，对准鱼影；按住蓄力，松手抛竿"
var failure: String=""
var final_result: Dictionary={}

func configure(id: String, chart: Dictionary, assistance: bool=false) -> void:
	chart_id=id
	beat_sec=float(chart.get("beatSeconds",0.6))
	beat_pattern=chart.get("beatPattern",[1,1,1,1]).duplicate()
	timing_scale=float(chart.get("timingScale",1))
	fish_motion_scale=float(chart.get("fishMotionScale",1))
	rhythm_name=chart.get("rhythmName","四拍收放")
	difficulty=int(chart.get("difficulty",1))
	assist=assistance
	var index: int=0
	for note: Dictionary in chart.get("notes",[]):
		if index>=64: break
		var at: float=phrase_time(float(note.beat))
		notes.append({"index":index,"timeSec":at,"spawnSec":at-1.6,"judgment":"","holding":false})
		index+=1
	if notes.is_empty(): fail("invalid_chart")

func phrase_time(beat: float) -> float:
	var whole: int=int(floor(beat))
	var index: int=whole%4
	var partial: float=0
	for i: int in range(index): partial+=float(beat_pattern[i])
	return (floor(whole/4.0)*4+partial+(beat-whole)*float(beat_pattern[index]))*beat_sec

func rhythm_position(at: float) -> Vector2:
	if cast_at<0: return Vector2.ZERO
	var since: float=maxf(0,at-cast_at)
	if since<4*beat_sec: return Vector2(int(floor(since/beat_sec))%4,fmod(since/beat_sec,1))
	var pos: float=fmod((since-4*beat_sec)/beat_sec,4)
	for beat: int in range(4):
		if pos<float(beat_pattern[beat]) or beat==3: return Vector2(beat,minf(1,pos/float(beat_pattern[beat])))
		pos-=float(beat_pattern[beat])
	return Vector2.ZERO

func fish_at(at: float) -> float:
	if cast_at<0: return 0.42+sin(at*0.6)*0.07
	var t: float=maxf(0,at-cast_at-4*beat_sec)*fish_motion_scale
	return clampf(0.59*sin(t*1.05+0.8)+0.12*sin(t*2.1+0.2),-0.8,0.8)

func fish_x() -> float: return fish_at(physics_tick/120.0)
func aligned() -> bool: return absf(line_x-fish_x()) <= (0.34 if assist else 0.25)
func rushing_at(at: float) -> bool: return stage=="fighting" and int(rhythm_position(at).x)==1
func good_window() -> float: return (0.35 if assist else 0.28)*timing_scale
func cast_power() -> float: return 0.0 if held_at<0 else clampf((elapsed-held_at)/1.2,0,1)
func current_note() -> Dictionary:
	for note: Dictionary in notes:
		if note.judgment=="": return note
	return {}
func lift_ready() -> bool:
	var note: Dictionary=current_note()
	return stage=="fighting" and not note.is_empty() and absf(float(note.timeSec)-elapsed)<=good_window()

func press(action: String) -> void:
	if controls.has(action) or phase not in ["idle","running"]: return
	if phase=="idle": phase="running"
	advance_to(elapsed)
	if phase!="running" or not record("press",action): return
	controls[action]=true
	if action=="hook":
		held_at=elapsed
		var note: Dictionary=current_note()
		if not note.is_empty(): note.holding=true
		cue="蓄到绿色范围，松手抛竿" if stage=="casting" else ("它在猛拽，松手放线！" if rushing_at(elapsed) else "左右跟住鱼影，按住收线")

func release(action: String) -> void:
	if not controls.has(action) or phase!="running": return
	advance_to(elapsed)
	if phase!="running" or not record("release",action): return
	controls.erase(action)
	if action!="hook": return
	var held_for: float=elapsed-held_at if held_at>=0 else 0.0
	held_at=-1
	for note: Dictionary in notes: note.holding=false
	if stage=="casting":
		cast_attempts+=1
		var power: float=held_for/1.2
		if absf(line_x-fish_x())>(0.4 if assist else 0.3):
			cue="抛偏了：左右移动浮漂，先对准鱼影"
			return
		if power<0.3 or power>0.9:
			cue="太轻了：按住蓄到绿色范围再松手" if power<0.3 else "太重了：这次早一点松手"
			return
		stage="count_in"
		cast_at=elapsed
		tracking_seconds=0
		for note: Dictionary in notes:
			note.timeSec+=elapsed+4*beat_sec
			note.spawnSec+=elapsed+4*beat_sec
		cue="跟着预备拍：稳、放、收、提"
		return
	if stage!="fighting": return
	var note: Dictionary=current_note()
	if note.is_empty(): return
	var error: float=(elapsed-float(note.timeSec))*1000
	if absf(error)>good_window()*1000+0.000001:
		cue="放线缓一缓，等鱼影闪金再收竿"
		return
	var stable: bool=tracking_seconds>=(0.25 if assist else 0.42)-0.000001 and aligned()
	var held_enough: bool=held_for>=0.24-0.000001
	var safe_line: bool=tension<88
	var magnitude: float=absf(error)
	var judgment: String="miss"
	if stable and held_enough and safe_line:
		judgment="perfect" if magnitude<=100*timing_scale+0.000001 else ("great" if magnitude<=190*timing_scale+0.000001 else "good")
	judge(note,judgment,elapsed)
	if judgment=="miss": cue="鱼影没跟住：左右控线，再择机收竿" if not stable else ("线太紧了：猛拽时松手放线" if not safe_line else "收线太短：先按住稳住，再松手")

func neutral() -> void:
	if not controls.is_empty() and phase=="running":
		advance_to(elapsed)
		if phase=="running": record("neutral","hook")
	controls.clear()
	held_at=-1
	for note: Dictionary in notes: note.holding=false

func update(delta: float) -> void:
	if phase=="running": advance_to(elapsed+maxf(0,delta))

func advance_to(at: float) -> void:
	if phase!="running": return
	elapsed=maxf(elapsed,at)
	if elapsed>180:
		fail("hook_escaped")
		return
	var target: int=int(floor(elapsed*120+0.0000001))
	while physics_tick<target and phase=="running":
		physics_tick+=1
		var time: float=physics_tick/120.0
		var dt: float=1.0/120.0
		var axis: float=float(controls.has("right"))-float(controls.has("left"))
		line_x=clampf(line_x+axis*1.3*dt,-1,1)
		if stage=="count_in" and cast_at>=0 and time>=cast_at+4*beat_sec: stage="fighting"
		if stage!="fighting": continue
		var matched: bool=absf(line_x-fish_at(time))<=(0.34 if assist else 0.25)
		var reeling: bool=controls.has("hook")
		if matched and reeling and not rushing_at(time): tracking_seconds+=dt
		else: tracking_seconds=maxf(0,tracking_seconds-dt*(0.15 if matched else 0.8))
		var pull: float=(45.0 if rushing_at(time) else (6.0 if matched else 17.0)) if reeling else -22.0
		tension=clampf(tension+pull*dt,15,100)
		if tension>=100:
			fail("line_snapped")
			break
		var note: Dictionary=current_note()
		if not note.is_empty() and time>float(note.timeSec)+good_window()+0.0000001: judge(note,"miss",time)

func record(type: String, action: String) -> bool:
	if inputs.size()>=INPUT_LIMIT:
		fail("hook_escaped")
		return false
	inputs.append({"type":type,"action":action,"timeSec":elapsed})
	return true

func judge(note: Dictionary, judgment: String, at: float) -> void:
	if note.judgment!="" or phase!="running": return
	note.judgment=judgment
	note.holding=false
	judged+=1
	tracking_seconds=0
	if judgment=="miss":
		combo=0
		tension=minf(100,tension+22)
		cue="脱了一钩，先跟住鱼影再提竿"
	else:
		combo=mini(1000000,combo+1)
		max_combo=maxi(max_combo,combo)
		tension=maxf(15,tension-(9 if judgment=="perfect" else 6))
		cue="收近了！留意下一次猛拽"
	if tension>=100:
		fail("line_snapped")
		return
	if judged==notes.size(): complete(at)

func complete(at: float) -> void:
	phase="completed"
	controls.clear()
	held_at=-1
	var counts: Dictionary={"perfect":0,"great":0,"good":0,"miss":0}
	for note: Dictionary in notes: counts[note.judgment]+=1
	var accuracy: float=(counts.perfect+counts.great*0.85+counts.good*0.6)/notes.size()
	var hit: int=counts.perfect+counts.great+counts.good
	var passed: bool=hit>=int(ceil(notes.size()*0.75))
	var grade: String=("S" if accuracy>=0.9 else ("A" if accuracy>=0.75 else "B")) if passed else "C"
	final_result={"chartId":chart_id,"spotId":chart_id,"grade":grade,"passed":passed,"success":passed,"accuracy":accuracy,"perfect":counts.perfect,"great":counts.great,"good":counts.good,"miss":counts.miss,"maxCombo":max_combo,"finalTension":round(tension*1000)/1000,"protocol":"lake-rhythm-v4","assist":assist,"finishedAtSec":at,"inputs":inputs.duplicate(true),"notes_hit":hit,"total_notes":notes.size()}

func fail(reason: String) -> void:
	phase="failed"
	failure=reason
	controls.clear()
	held_at=-1
	cue="鱼线断了，松线后再试" if reason=="line_snapped" else "鱼逃走了，再试一次"

static func load_chart(id: String) -> Dictionary:
	var file: FileAccess=FileAccess.open("res://data/source/chapter3-qizhen-fishing.charts.json",FileAccess.READ)
	if file==null: return {}
	var parsed: Variant=JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary: return {}
	return parsed.get("charts",{}).get(id,{})

static func validate_result(value: Dictionary, expected_id: String) -> bool:
	if value.get("protocol")!="lake-rhythm-v4" or value.get("chartId")!=expected_id or value.get("passed")!=true or not value.get("assist") is bool: return false
	if not value.get("inputs") is Array or value.inputs.size()<8 or value.inputs.size()>INPUT_LIMIT: return false
	if not (value.get("finishedAtSec") is float or value.get("finishedAtSec") is int): return false
	var finish: float=float(value.finishedAtSec)
	if not is_finite(finish) or finish<0 or finish>180: return false
	var chart: Dictionary=load_chart(expected_id)
	if chart.is_empty(): return false
	var replay: RefCounted=load("res://scripts/games/rhythm_fishing_model.gd").new()
	replay.configure(expected_id,chart,value.assist)
	var last: float=-1
	for event: Variant in value.inputs:
		if not event is Dictionary or event.get("type") not in ["press","release","neutral"] or event.get("action") not in ["left","right","hook"]: return false
		if not (event.get("timeSec") is float or event.get("timeSec") is int): return false
		var time: float=float(event.timeSec)
		if not is_finite(time) or time<last or time<0 or time>finish+0.000001: return false
		if last<0 and (event.type!="press" or absf(time)>0.000001): return false
		if replay.phase in ["completed","failed"]: return false
		replay.advance_to(time)
		if event.type=="press": replay.press(event.action)
		elif event.type=="release": replay.release(event.action)
		else: replay.neutral()
		last=time
	replay.advance_to(finish)
	var verified: Dictionary=replay.final_result
	if verified.is_empty() or verified.passed!=true: return false
	for key: String in ["grade","perfect","great","good","miss","maxCombo","finalTension"]:
		if verified.get(key)!=value.get(key): return false
	return (value.get("accuracy") is float or value.get("accuracy") is int) and absf(verified.accuracy-float(value.accuracy))<0.000001
