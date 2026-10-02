extends RefCounted
## Runtime-only controller-issued capability. This model never writes story state.
## Source: ChapterThreeOpeningOverlay.tsx and CanteenInteriorScene.ts.
const PAPER_ORIGIN := Vector2(1053,302)
const TRIGGER_RADIUS := 360.0
const CAPTIONS := {
	"record_scan":"短暂加载后：", "mode_unlock":"获得功能：外观模式切换",
	"paper_burst":"纸条突然从 022 座位详情页弹出，贴着图书馆窗缝飞走。",
	"exit_observation":"切到深色模式，看到纸条脚印通向出口。",
	"cart_clear":"切回浅色模式，发现出口被书车挡住。",
	"route_confirm":"再次切到深色模式，确认脚印通向食堂。",
	"arrival":"离开图书馆，在校园里继续追踪纸条。"}
var kind: String
var reduced_motion: bool=false
var status: String="issued"
var bound_state: Dictionary
var host_id: int=0
var beats: Array=[]
var lines: Array=[]
var beat_index: int=0
var beat_elapsed_ms: float=0
var elapsed_ms: float=0
var idle_ms: float=0
var skipped: bool=false
var paused: bool=false
var cue_queue: Array=[]
var trigger_player := Vector2.ZERO
var trigger_paper := PAPER_ORIGIN
var trigger_angle: float=-2.0
var route: Array=[]
var route_start_ms: float=0
var escape_end_ms: float=0
var completion_ms: float=0
var prompt_lines: Array=[]
var emitted: Dictionary={}

func _init(state: Dictionary={}, type: String="opening", reduce: bool=false) -> void:
	bound_state=state; kind=type; reduced_motion=reduce
	if kind=="opening":
		lines=JSON.parse_string(FileAccess.get_file_as_string("res://data/source/library-finals.content.json")).library.dialogue022
		_add_lines(0,8,"conversation"); _beat("record_scan",1350,850)
		_add_lines(8,18,"record_escape"); _beat("mode_unlock",1700,1050)
		_add_lines(18,22,"mode_explanation"); _beat("paper_burst",1000,850)
		_add_lines(22,26,"paper_dialogue"); _beat("exit_observation",900,850)
		_beat("cart_clear",900,850); _beat("route_confirm",600,500); _beat("arrival",1300,900)
	else:
		prompt_lines=JSON.parse_string(FileAccess.get_file_as_string("res://data/source/chapter3-canteen.content.json")).entryDialogue
		route_start_ms=(160 if reduce else 820)+(1120 if reduce else 2380)
		var points: Array=[Vector2(944,300),Vector2(186,274),Vector2(92,252),Vector2(92,252),Vector2(166,252),Vector2(166,82),Vector2(166,-56)]
		var durations: Array=[190,1120,260,200,230,430,220]
		var angles: Array=[-6,-9,68,68,-10,-88,-88]
		var easings: Array=["sine_in","linear","quad_out","hold","quad_in_out","cubic_in","cubic_in"]
		var start: float=route_start_ms
		for i in range(points.size()):
			var duration: float=maxf(120,float(durations[i])*0.62) if reduce else float(durations[i])
			route.append({"point":points[i],"durationMs":duration,"startMs":start,"angle":angles[i],"ease":easings[i]}); start+=duration
		escape_end_ms=start
		completion_ms=start+(100+160+40 if reduce else 500+720+40)

func _add_lines(first: int,last: int,phase: String) -> void:
	for i in range(first,mini(last,lines.size())):
		# JavaScript .length counts UTF-16 code units, not Unicode code points.
		var length: int=str(lines[i].text).to_utf16_buffer().size()/2
		beats.append({"phase":phase,"durationMs":clampi(760+length*48,1200,1900),"lineIndex":i})
func _beat(phase: String,normal: int,reduced: int) -> void:
	beats.append({"phase":phase,"durationMs":reduced if reduced_motion else normal,"lineIndex":null,"caption":CAPTIONS[phase]})

static func pending_canteen(s: Dictionary) -> bool:
	var c: Dictionary=s.get("canteenHunt",{})
	return s.get("native",{}).get("scene","")=="canteen_interior" and c.get("active",false) and c.get("phase","")=="tray_search" and not c.get("entryPaperEscaped",false)
static func pending_opening(s: Dictionary) -> bool:
	var p: Dictionary=s.get("ui",{}).get("libraryFinalsPuzzle",{})
	return s.get("native",{}).get("scene","")=="library_interior" and s.get("ui",{}).get("libraryFinalsPhase","")=="seat_recovered" and p.get("playerSeated",false) and p.get("nextQuestId")==null
func valid(s: Dictionary) -> bool:
	return is_same(s,bound_state) and (pending_opening(s) if kind=="opening" else pending_canteen(s))
func attach(s: Dictionary, host: Object) -> bool:
	if status!="issued" or not valid(s) or host==null: return false
	host_id=host.get_instance_id(); status="playing" if kind=="opening" else "waiting"
	if kind=="opening": _cue("chapter_three_opening_started"); _opening_cue()
	return true
func authorized(s: Dictionary,host: Object) -> bool:
	return host!=null and host.get_instance_id()==host_id and valid(s) and status not in ["cancelled","consumed"]
func cancel() -> void:
	if status!="consumed": status="cancelled"
func idle_pose() -> Dictionary:
	var duration: float=620 if reduced_motion else 900
	var p: float=fposmod(idle_ms/duration,2); p=p if p<=1 else 2-p
	p=(1-cos(p*PI))/2
	return {"point":PAPER_ORIGIN+Vector2(0,-3*p),"angle":lerpf(-2,2,p),"scale":0.76,"frame":-1,"visible":true}
func post_collision(s: Dictionary,player: Vector2,host: Object,focused: bool=true) -> bool:
	if kind!="canteen" or status!="waiting" or not authorized(s,host) or not focused: return false
	var actual: Variant=s.get("native",{}).get("player",{})
	if actual is Dictionary and actual.has("canteen_interior"): actual=actual.canteen_interior
	if not actual is Dictionary or not actual.has("x") or not actual.has("y"): return false
	var state_player:=Vector2(float(actual.x),float(actual.y))
	if not player.is_finite() or not state_player.is_finite() or player.distance_to(state_player)>0.01: return false
	var point: Vector2=idle_pose().point
	if player.distance_to(point)>TRIGGER_RADIUS: return false
	trigger_player=player; trigger_paper=point; trigger_angle=float(idle_pose().angle); status="playing"; elapsed_ms=0
	return true
func frame(s: Dictionary,delta_ms: float,host: Object,focused: bool=true) -> void:
	if not authorized(s,host): cancel(); return
	paused=not focused
	if paused or not is_finite(delta_ms) or delta_ms<=0 or status in ["complete","consumed"]: return
	# Source requestAnimationFrame limits visible catch-up to 100ms.
	var delta: float=minf(delta_ms,100)
	if status=="waiting": idle_ms+=delta; return
	if kind=="opening": _advance_opening(delta); return
	var before: float=elapsed_ms; elapsed_ms+=delta
	_cross(before,elapsed_ms,160 if reduced_motion else 820,"canteen_entry_paper_spotted")
	_cross(before,elapsed_ms,route_start_ms,"canteen_entry_paper_escape_started")
	if elapsed_ms>=completion_ms: status="complete"
func _cross(before: float,after: float,at: float,id: String) -> void:
	if before<at and after>=at: _cue(id)
func _advance_opening(delta: float) -> void:
	var remaining: float=clampf(delta,0,60000)
	while remaining>0 and status=="playing":
		var beat: Dictionary=beats[beat_index]
		var step: float=minf(remaining,minf(34,maxf(0,float(beat.durationMs)-beat_elapsed_ms)))
		remaining-=step; beat_elapsed_ms+=step; elapsed_ms+=step
		if beat_elapsed_ms+0.01<float(beat.durationMs): continue
		beat_index+=1; beat_elapsed_ms=0
		if beat_index>=beats.size(): status="complete"; break
		_opening_cue()
func advance_current(s: Dictionary,host: Object) -> void:
	if kind!="opening" or status!="playing" or paused or not authorized(s,host): return
	beat_elapsed_ms=float(beats[beat_index].durationMs); _advance_opening(1)
func skip_to_arrival(s: Dictionary,host: Object) -> void:
	if kind!="opening" or status!="playing" or paused or not authorized(s,host): return
	skipped=true; beat_index=beats.size()-1; beat_elapsed_ms=0; _opening_cue()
func _opening_cue() -> void:
	var beat: Dictionary=beats[beat_index]
	if beat.lineIndex!=null: _cue("library_story_line",{"subtitleKey":"library_story_library_friend_contacted_%02d" % (int(beat.lineIndex)+1)})
	else: _cue("chapter_three_opening_"+str(beat.phase),{"beatIndex":beat_index,"beatCount":beats.size()})
func _cue(id: String,payload: Dictionary={}) -> void:
	cue_queue.append({"id":id,"payload":payload})
func take_cues() -> Array:
	var result: Array=cue_queue.duplicate(true); cue_queue.clear(); return result
func consume(s: Dictionary) -> bool:
	if status!="complete" or not valid(s): return false
	if kind=="opening" and beat_index<beats.size(): return false
	if kind=="canteen" and elapsed_ms<completion_ms: return false
	status="consumed"; return true
func snapshot() -> Dictionary:
	if kind=="opening":
		var i: int=mini(beat_index,beats.size()-1); var beat: Dictionary=beats[i]
		var progress: float=1 if status in ["complete","consumed"] else clampf(beat_elapsed_ms/float(beat.durationMs),0,1)
		var line: Dictionary=lines[int(beat.lineIndex)] if beat.lineIndex!=null else {}
		var speaker: String=str(line.get("speaker","地点" if beat.phase=="arrival" else "剧情"))
		var tone: String={"玩家":"player","系统":"system","纸条":"narrator"}.get(speaker,"seat" if not line.is_empty() else "system")
		return {"phase":beat.phase,"beatIndex":i,"beatCount":beats.size(),"beatProgress":progress,"overallProgress":(i+progress)/beats.size(),"lineIndex":beat.lineIndex,"speaker":speaker,"text":line.get("text",beat.get("caption","")),"tone":tone,"paused":paused,"skipped":skipped,"completionRequested":status in ["complete","consumed"]}
	return {"phase":status,"elapsedMs":elapsed_ms,"paper":paper_pose(),"camera":camera_pose(),"prompt":prompt_at(),"blocksInput":status=="playing"}
func paper_pose() -> Dictionary:
	if status=="waiting" or status=="issued": return idle_pose()
	var position: Vector2=trigger_paper; var angle: float=trigger_angle
	var surprise: float=elapsed_ms-(160 if reduced_motion else 820)
	if elapsed_ms<route_start_ms:
		var hop: float=55 if reduced_motion else 105
		if surprise>=0 and surprise<hop*2:
			var p: float=surprise/hop; p=p if p<=1 else 2-p
			# Phaser Back.Out overshoot, mirrored for the yoyo.
			position.y-=12*(1+2.70158*pow(p-1,3)+1.70158*pow(p-1,2))
		elif surprise>=hop*2 and surprise<hop*2+(45 if reduced_motion else 62)*8:
			var p: float=fposmod((surprise-hop*2)/(45 if reduced_motion else 62),2); position.x-=6*(p if p<=1 else 2-p)
		return {"point":position,"angle":angle,"scale":0.76,"frame":-1,"visible":true}
	angle=-6
	for segment: Dictionary in route:
		if elapsed_ms<float(segment.startMs)+float(segment.durationMs):
			var p: float=_ease(clampf((elapsed_ms-float(segment.startMs))/float(segment.durationMs),0,1),segment.ease)
			position=position.lerp(segment.point,p); angle=lerpf(angle,float(segment.angle),p); break
		position=segment.point; angle=float(segment.angle)
	return {"point":position,"angle":angle,"scale":0.82,"frame":int((elapsed_ms-route_start_ms)/(120 if reduced_motion else 78))%4,"visible":elapsed_ms<escape_end_ms}
func camera_pose() -> Dictionary:
	if status in ["waiting","issued"]: return {"target":trigger_player,"zoom":1.18,"followPlayer":true}
	var focus: Vector2=Vector2(lerpf(trigger_paper.x,trigger_player.x,0.24),lerpf(trigger_paper.y,trigger_player.y,0.38))
	var discovery: float=120 if reduced_motion else 520
	if elapsed_ms<route_start_ms: return {"target":trigger_player.lerp(focus,_ease(clampf(elapsed_ms/discovery,0,1),"sine_in_out")),"zoom":lerpf(1.18,1.22,_ease(clampf(elapsed_ms/discovery,0,1),"sine_in_out")),"followPlayer":false}
	if elapsed_ms<escape_end_ms: return {"target":paper_pose().point-Vector2(0,24),"zoom":1.22,"followPaper":true,"followPlayer":false,"lerp":0.075,"deadzone":Vector2(100,68)}
	var pause_ms: float=100 if reduced_motion else 500; var return_ms: float=160 if reduced_motion else 720
	var p: float=_ease(clampf((elapsed_ms-escape_end_ms-pause_ms)/return_ms,0,1),"sine_in_out")
	return {"target":Vector2(166,-80).lerp(trigger_player,p),"zoom":lerpf(1.22,1,p),"followPlayer":elapsed_ms>=completion_ms,"returning":true}
func speech_bubbles() -> Array:
	var out: Array=[]
	var surprise: float=160 if reduced_motion else 820
	var specs: Array=[
		{"at":surprise+(120 if reduced_motion else 360),"duration":1050.0,"text":"玩家：找到了。","speaker":"玩家","tone":"player","point":trigger_player+Vector2(0,-72),"width":108},
		{"at":surprise+(620 if reduced_motion else 1420),"duration":760.0,"text":"纸条：！","speaker":"纸条","tone":"narrator","point":trigger_paper+Vector2(43,-32),"width":70}]
	if status not in ["playing","complete","consumed"]: return out
	for entry: Dictionary in specs:
		var age: float=elapsed_ms-float(entry.at)
		var fade: float=50 if reduced_motion else 120
		if age<0 or age>=float(entry.duration)+fade: continue
		var entrance: float=clampf(age/(60 if reduced_motion else 110),0,1)
		entry.alpha=minf(entrance,clampf((float(entry.duration)+fade-age)/fade,0,1))
		entry.scale=lerpf(0.86,1,1+2.70158*pow(entrance-1,3)+1.70158*pow(entrance-1,2))
		out.append(entry)
	return out
func prompt_at() -> Dictionary:
	var prompts: Array=speech_bubbles()
	return {} if prompts.is_empty() else prompts[0]
func alarm_pose() -> Dictionary:
	if status!="playing": return {}
	var age: float=elapsed_ms-(160 if reduced_motion else 820)
	var fade: float=60 if reduced_motion else 110
	var hold: float=80 if reduced_motion else 300
	if age<0 or age>=fade*2+hold: return {}
	var p: float=minf(clampf(age/fade,0,1),clampf((fade*2+hold-age)/fade,0,1))
	return {"point":trigger_paper+Vector2(0,-47-5*p),"alpha":p}
func _ease(p: float,id: String) -> float:
	match id:
		"sine_in": return 1-cos(p*PI/2)
		"sine_in_out": return (1-cos(p*PI))/2
		"quad_out": return 1-(1-p)*(1-p)
		"quad_in_out": return 2*p*p if p<0.5 else 1-pow(-2*p+2,2)/2
		"cubic_in": return p*p*p
		"hold": return 0
	return p
