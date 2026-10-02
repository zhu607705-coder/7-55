extends RefCounted
## Runtime-only, controller-issued LibraryStoryOverlay session. Never writes save facts.
## Every speaker/text pair is loaded verbatim from library-finals.content.json.
var sequence_id: String
var lines: Array=[]
var durations_ms: Array=[]
var status: String="issued"
var line_index: int=0
var elapsed_ms: float=0
var host_id: int=0
var bound_state: Dictionary
var paused: bool=false
var requires_confirmation: bool=false
var completion_source: String=""
var cue_queue: Array=[]

func _init(state: Dictionary={}, id: String="", authored: Array=[]) -> void:
	bound_state=state; sequence_id=id; lines=authored.duplicate(true)
	requires_confirmation=id=="cc98_evidence_set_completed"
	for line: Dictionary in lines:
		durations_ms.append(text_duration(str(line.text)))

static func text_duration(text: String) -> int:
	# Source counts non-whitespace graphemes. All 53 authored Chinese lines
	# contain BMP graphemes only; no combining sequences or emoji clusters.
	var visible: int=0
	for character: String in text:
		if not character.strip_edges().is_empty(): visible+=1
	return clampi(1600+120*visible,2400,6500)

func valid(s: Dictionary) -> bool:
	if not is_same(s,bound_state) or int(s.get("native",{}).get("chapter",1))!=2: return false
	var p: Dictionary=s.get("ui",{}).get("libraryFinalsPuzzle",{})
	var phase: String=str(s.get("ui",{}).get("libraryFinalsPhase","idle"))
	if phase in ["idle","friend_contacted"]: return false
	match sequence_id:
		"library_entered": return phase=="library_entered"
		"library_occupied_seat_found": return p.get("backpackInspected",false)
		"cc98_occupation_post_opened": return p.get("investigationOpened",false)
		"library_catalog_match_found": return p.get("callNumberCollected",false)
		"library_archived_rule_recovered","library_front_desk_proof_request": return phase=="evidence_gathering" and p.get("archivedRuleRead",false)
		"library_bag_nonperson_proof_issued": return p.get("nonPersonProofStamped",false)
		"tiyi_presence_proof_issued": return p.get("presenceProofCollected",false)
		"cc98_evidence_set_completed": return phase in ["bd_briefing","top_ten_rising"] and p.get("cc98UploadedEvidenceIds",[]).size()==4
		"cc98_top_ten_reached": return phase in ["top_ten_reached","recovery_application"] and p.get("bdCount",0)==3
		"library_seat_release_pass_issued": return phase=="pass_ready" and p.get("evictionPassGenerated",false)
		"library_backpack_evicted": return p.get("backpackEvicted",false)
	return false

func attach(s: Dictionary,host: Object) -> bool:
	if status!="issued" or host==null or lines.is_empty() or not valid(s): return false
	host_id=host.get_instance_id(); status="playing"; _line_cue(); return true

func authorized(s: Dictionary,host: Object) -> bool:
	return host!=null and host.get_instance_id()==host_id and valid(s) and status=="playing"

func frame(s: Dictionary,delta_ms: float,host: Object,focused: bool=true) -> void:
	if not valid(s): cancel(); return
	paused=not focused
	if paused or not authorized(s,host) or not is_finite(delta_ms) or delta_ms<=0: return
	# No multi-line catch-up: the browser schedules a fresh timeout for each line.
	elapsed_ms+=minf(delta_ms,100)
	if elapsed_ms>=float(durations_ms[line_index]): _advance("timer")

func advance(s: Dictionary,host: Object) -> void:
	if paused or not authorized(s,host): return
	_advance("user")

func _advance(source: String) -> void:
	if line_index>=lines.size()-1:
		if requires_confirmation and source!="user": return
		status="complete"; completion_source=source; return
	line_index+=1; elapsed_ms=0; _line_cue()

func consume(s: Dictionary) -> bool:
	if status!="complete" or host_id==0 or not valid(s): return false
	if requires_confirmation and completion_source!="user": return false
	status="consumed"; return true

func cancel() -> void:
	if status!="consumed": status="cancelled"

func _line_cue() -> void:
	cue_queue.append({"id":"library_story_line","payload":{"subtitleKey":"library_story_%s_%02d" % [sequence_id,line_index+1]}})

func take_cues() -> Array:
	var out: Array=cue_queue.duplicate(true); cue_queue.clear(); return out

func snapshot() -> Dictionary:
	if lines.is_empty(): return {}
	return {"sequenceId":sequence_id,"lineIndex":line_index,"lineCount":lines.size(),"speaker":lines[line_index].speaker,"text":lines[line_index].text,"durationMs":durations_ms[line_index],"requiresConfirmation":requires_confirmation and line_index==lines.size()-1,"paused":paused}
