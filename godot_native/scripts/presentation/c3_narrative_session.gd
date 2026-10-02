extends RefCounted
## Timed source queueDialogue capability. No saved facts, callbacks or input authority.
## CanteenInteriorScene.queueDialogue, TheaterInteriorScene.queueDialogue and
## QizhenLoopScene.queueTransitionSubtitles remain the timing/content oracle.
var bound_state: Dictionary
var spec: Dictionary
var sequence_id: String=""
var scene: String=""
var status: String="issued"
var host_id: int=0
var elapsed_ms: float=0
var paused: bool=false
var lines: Array=[]
var duration_ms: float=0
var cue_queue: Array=[]
var emitted_lines: int=0
var reduced: bool=false
var runtime: Dictionary={}
var origin:=Vector2.ZERO
var motion_origin:=Vector2.INF
var audio_keys: Dictionary={}
var visual_acknowledged: bool=false
var inspector_acknowledged: bool=false
var inspector_opened: bool=false
var inspector_closed_by_host: bool=false
var inspector_at_ms: float=INF
var shards: Array=[]

func _init(s: Dictionary={},request: Dictionary={}) -> void:
	bound_state=s; spec=request.duplicate(true); sequence_id=str(spec.get("id",""))
	scene=str(spec.get("scene",s.get("native",{}).get("scene","")))
	reduced=bool(s.get("native",{}).get("settings",{}).get("reduced_motion",false))
	var audio: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/native/audio-director-source.json"))
	audio_keys=audio.get("chapter3KeysBySubtitle",{})
	var start: float=float(spec.get("delayMs",0))
	var authored: Array=spec.get("lines",[])
	var durations: Array=spec.get("durations",[])
	for index in range(authored.size()):
		var text: String=str(authored[index])
		var duration: float=float(durations[index]) if index<durations.size() else (theater_duration(text) if scene=="theater_interior" else float(spec.get("stepMs",2500))-120)
		lines.append({"text":text,"atMs":start,"durationMs":duration})
		start+=duration+120
	duration_ms=start+float(spec.get("tailMs",0))
	if sequence_id=="theater_reversal":
		visual_acknowledged=bool(spec.get("visualCompleted",false))
		inspector_at_ms=float(lines[2].atMs)
		for i in range(8): shards.append({"x":480+randi_range(-120,120),"y":330+randi_range(20,100),"angle":i*27,"width":12+(i%3)*4})
	if sequence_id=="qizhen_approach":
		runtime=JSON.parse_string(FileAccess.get_file_as_string("res://data/worlds.json")).worlds.campus_qizhen_loop.manifest.qizhen.approachTransition
		duration_ms=160+float(spec.completeAtMs)
	elif sequence_id=="canteen_escape":
		runtime=JSON.parse_string(FileAccess.get_file_as_string("res://data/worlds.json")).worlds.canteen_interior.constants.CANTEEN_SOUTHEAST_EXIT_DOOR
		var p: Variant=spec.get("paperStart",[1053,302])
		origin=Vector2(clampf(float(p[0]),28,1644),clampf(float(p[1]),16,923))

static func theater_duration(text: String) -> int:
	var colon: int=text.find("：")
	var spoken: String=text.substr(colon+1) if colon>=0 else text
	var visible: int=0
	for character: String in spoken:
		if not character.strip_edges().is_empty(): visible+=1
	return clampi(1600+120*visible,2400,6500)

func valid(s: Dictionary) -> bool:
	if not is_same(s,bound_state) or s.get("native",{}).get("scene","")!=scene: return false
	if int(s.get("native",{}).get("chapter",3))!=3: return false
	if sequence_id=="qizhen_approach":
		return s.qizhenLake.active and s.qizhenLake.phase=="location_search" and not s.qizhenLake.locationBriefingSeen
	if sequence_id=="canteen_escape": return s.canteenHunt.phase=="chase_ready"
	if sequence_id=="canteen_promo": return s.canteenHunt.active and s.canteenHunt.promoDrinkPlaced and s.canteenHunt.phase in ["tray_search","drink_mix","menu_order","pickup_search","chase_ready"]
	if sequence_id=="theater_reversal":
		return s.native.get("c3_reversal_pending",false)==true and ((s.theaterHunt.phase=="reversal" and s.theaterHunt.spotlightRound>=3) or (s.theaterHunt.phase=="complete" and s.theaterHunt.decoyRevealed and s.qizhenLake.active))
	if sequence_id=="canteen_tray_intro": return not s.canteenHunt.trayTaskStarted
	return true
func attach(s: Dictionary,host: Object) -> bool:
	if status!="issued" or host==null or not valid(s) or lines.is_empty(): return false
	host_id=host.get_instance_id(); status="playing"; _publish_due_lines(); return true
func authorized(s: Dictionary,host: Object) -> bool:
	return valid(s) and host!=null and host.get_instance_id()==host_id and status=="playing"
func frame(s: Dictionary,delta_ms: float,host: Object,focused: bool=true) -> void:
	if not valid(s): cancel(); return
	paused=not focused
	if paused or not authorized(s,host) or not is_finite(delta_ms) or delta_ms<=0: return
	var limit_ms: float=minf(duration_ms,inspector_at_ms) if sequence_id=="theater_reversal" and not inspector_acknowledged else duration_ms
	elapsed_ms=minf(limit_ms,elapsed_ms+minf(delta_ms,100))
	if sequence_id=="theater_reversal" and not inspector_acknowledged and elapsed_ms>=inspector_at_ms: status="inspecting"
	_publish_due_lines()
	if elapsed_ms>=duration_ms: status="complete"
func _publish_due_lines() -> void:
	while emitted_lines<lines.size() and elapsed_ms>=float(lines[emitted_lines].atMs):
		if sequence_id=="theater_reversal" and emitted_lines>=2 and not inspector_acknowledged: break
		var text: String=lines[emitted_lines].text
		var key: String=str(audio_keys.get(_normalize(text),""))
		if not key.is_empty(): cue_queue.append({"id":"chapter3_story_line","payload":{"subtitleKey":key}})
		emitted_lines+=1
static func _normalize(text: String) -> String:
	var whitespace:=RegEx.new(); whitespace.compile("\\s+")
	return whitespace.sub(text.strip_edges()," ",true)
func take_cues() -> Array:
	var result: Array=cue_queue.duplicate(true); cue_queue.clear(); return result
func consume_visual(s: Dictionary) -> bool:
	if sequence_id not in ["canteen_promo","theater_reversal"] or visual_acknowledged or host_id==0 or status not in ["playing","complete"] or not valid(s) or elapsed_ms<float(spec.delayMs): return false
	visual_acknowledged=true; return true
func mark_inspector_opened(s: Dictionary,host: Object) -> bool:
	if sequence_id!="theater_reversal" or status!="inspecting" or inspector_opened or not visual_acknowledged or not valid(s) or host==null or host.get_instance_id()!=host_id: return false
	inspector_opened=true; return true
func mark_inspector_closed(s: Dictionary,host: Object) -> bool:
	if sequence_id!="theater_reversal" or status!="inspecting" or not inspector_opened or not valid(s) or host==null or host.get_instance_id()!=host_id: return false
	inspector_closed_by_host=true; return true
func consume_inspector(s: Dictionary) -> bool:
	if status!="inspecting" or not valid(s) or not inspector_closed_by_host or inspector_acknowledged: return false
	inspector_acknowledged=true; status="playing"; _publish_due_lines(); return true
func consume(s: Dictionary) -> bool:
	if status!="complete" or host_id==0 or not valid(s) or elapsed_ms<duration_ms: return false
	if sequence_id in ["canteen_promo","theater_reversal"] and not visual_acknowledged: return false
	if sequence_id=="theater_reversal" and not inspector_acknowledged: return false
	status="consumed"; return true
func cancel() -> void:
	if status!="consumed": status="cancelled"
func blocks_movement() -> bool:
	if sequence_id=="qizhen_approach": return true
	if sequence_id=="theater_reversal": return elapsed_ms<float(spec.delayMs)
	if sequence_id=="canteen_escape":
		return elapsed_ms<float(spec.delayMs) or elapsed_ms>=float(lines[-1].atMs)+float(lines[-1].durationMs)+120
	return false
func snapshot() -> Dictionary:
	var current: Dictionary={}
	for entry: Dictionary in lines:
		if elapsed_ms>=float(entry.atMs) and elapsed_ms<float(entry.atMs)+float(entry.durationMs): current=entry
	var text: String=str(current.get("text",""))
	var colon: int=text.find("：")
	return {"sequenceId":sequence_id,"text":text.substr(colon+1) if colon>=0 else text,"rawText":text,"speaker":text.substr(0,colon) if colon>=0 else "","paused":paused,"elapsedMs":elapsed_ms,"lineIndex":maxi(0,emitted_lines-1)}
func player_pose() -> Vector2:
	if sequence_id=="qizhen_approach":
		var p:=Vector2(runtime.start.x,runtime.start.y)
		var at: float=160
		for waypoint: Dictionary in runtime.waypoints:
			var target:=Vector2(waypoint.x,waypoint.y)
			if elapsed_ms<at+float(waypoint.durationMs):
				var ratio: float=clampf((elapsed_ms-at)/float(waypoint.durationMs),0,1)
				return p.lerp(target,(1-cos(ratio*PI))/2)
			p=target; at+=float(waypoint.durationMs)
		return p
	if sequence_id=="canteen_escape" and motion_origin!=Vector2.INF:
		var start: float=float(lines[-1].atMs)+float(lines[-1].durationMs)+120
		var door_wait: float=46 if reduced else 175
		var ratio: float=clampf((elapsed_ms-start-door_wait)/(120.0 if reduced else 300.0),0,1)
		return motion_origin.lerp(Vector2(runtime.exitPoint.x,runtime.exitPoint.y),floorf(ratio*10)/10)
	return Vector2.INF
func paper_pose() -> Dictionary:
	if sequence_id=="qizhen_approach":
		var t: float=elapsed_ms-160
		var progress: float=clampf(t/4550,0,1)
		var p:=Vector2(runtime.paperStart.x,runtime.paperStart.y).lerp(Vector2(runtime.paperStop.x,runtime.paperStop.y),(1-cos(progress*PI))/2)
		var fade: float=clampf((t-4550)/720,0,1)
		return {"point":p-Vector2(0,18*fade),"scale":1+sin(elapsed_ms/115)*0.08,"angle":lerpf(-8,18,progress),"alpha":1-fade if t>=0 else 0.0,"wet":true}
	if sequence_id=="canteen_escape":
		var p: float=clampf(elapsed_ms/(160.0 if reduced else 760.0),0,1)
		return {"point":origin.lerp(Vector2(1380,852),p*p),"scale":lerpf(1.16,0.56,p),"angle":86*p,"alpha":1.0 if elapsed_ms<float(spec.delayMs) else 0.0,"wet":false}
	return {}
func trail() -> Array:
	if sequence_id!="qizhen_approach": return []
	var out: Array=[]
	var start:=Vector2(runtime.paperStart.x+28,runtime.paperStart.y+4)
	var end:=Vector2(runtime.paperStop.x-120,runtime.paperStop.y+4)
	var count: int=maxi(6,int(floor((end.x-start.x)/float(runtime.trailSpacing))))
	var t: float=elapsed_ms-160
	for i in range(count+1):
		var visible_at: float=float(spec.paperLeadMs)+i*95
		var fade_at: float=float(spec.trailFadeAtMs)+i*34
		if t<visible_at or t>=fade_at+900: continue
		var p: Vector2=start.lerp(end,float(i)/count)+Vector2(0,sin(i*1.7)*3)
		var alpha: float=lerpf(.72,.18,clampf((t-visible_at)/860,0,1))*(1-clampf((t-fade_at)/900,0,1))
		out.append({"point":p,"alpha":alpha,"width":15 if i%3==0 else 9,"height":5 if i%2==0 else 4})
	return out
