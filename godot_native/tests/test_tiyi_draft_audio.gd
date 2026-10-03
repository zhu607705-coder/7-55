extends SceneTree
## Real State/action_completed -> AudioDirector dispatch. Dummy audio is not audible QA.
const Director=preload("res://scripts/media/audio_director.gd")
var state: Node
var director: Node
var checks=0
var failures=0
var cases: Array=[]
var published: Array=[]
var played: Array=[]
const CUE="tiyi_audit_value_changed"
const KEYS={"arrival":"auditArrivalMinutes","notice":"auditPublicNoticeFloor","proofs":"auditProofCount"}
func _initialize() -> void: run.call_deferred()
func frames() -> void:
	await process_frame; await process_frame
func check(ok: bool,label: String) -> void:
	checks+=1; cases.append({"check":label,"passed":ok})
	if not ok: failures+=1; push_error(label)
func fresh(phase: String="evidence_gathering",opened: bool=true,passed: bool=false) -> void:
	state.story_reset.emit(); state.d=state.initial(); state.d.native.chapter=2; state.d.native.page="tiyi"
	state.d.actOne.phase="complete"; state.d.networkMode="cellular"; state.d.ui.libraryFinalsPhase=phase
	state.d.ui.libraryFinalsPuzzle.investigationOpened=opened
	state.d.ui.libraryFinalsPuzzle.presenceProofCollected=passed
	state.get_phone_entry_session(); director.reset(); published.clear(); played.clear()
func run() -> void:
	state=root.get_node("State"); state.developer_mode=true
	director=Director.new(); root.add_child(director); director.setup(func(): return state.d)
	state.action_completed.connect(director.update_state)
	director.cue_published.connect(func(id,payload):
		if id==CUE: published.append(payload.duplicate(true)))
	director.playback_started.connect(func(channel,asset):
		if channel!="sfx" or asset!="01_global_ui_button_tap_confirm": return
		for entry in director.effects:
			if entry.asset==asset: played.append({"gain":entry.gain,"rate":entry.player.pitch_scale,"volume":db_to_linear(entry.player.volume_db),"playing":entry.player.playing}))
	var authored: Dictionary=director.source.events[CUE].cues[0]
	check(authored.channel=="sfx" and authored.asset=="01_global_ui_button_tap_confirm" and is_equal_approx(authored.volume,.28) and is_equal_approx(authored.playbackRate,1.22),"exact authored cue gain and pitch")
	var oracle: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/tiyi_audit_oracle.json"))
	for row: Dictionary in oracle.drafts:
		fresh(row.phase,row.opened,row.passed)
		var expected=state.d.duplicate(true)
		for key in row.puzzle: expected.ui.libraryFinalsPuzzle[key]=row.puzzle[key]
		# Only the setter fields are in scope; this fixture deliberately has no source evidence.
		expected.ui.libraryFinalsPuzzle.entranceRecordRead=false; expected.ui.libraryFinalsPuzzle.archivedRuleRead=false
		state.act("lib_audit_value",{"field":row.field,"value":row.value}); await frames()
		var changed=bool(row.accepted) and int(row.value)!=0
		var event_ok=published==[{"field":row.sourceField,"value":int(row.value)}] if changed else published.is_empty()
		check(event_ok and JSON.parse_string(JSON.stringify(state.d))==JSON.parse_string(JSON.stringify(expected)) and played.size()==int(changed),"source event/state case "+str(checks))
	for field in KEYS:
		fresh(); var before=state.d.duplicate(true)
		state.act("lib_audit_value",{"field":field,"value":5}); await frames()
		var expected=before.duplicate(true); expected.ui.libraryFinalsPuzzle[KEYS[field]]=5
		check(JSON.parse_string(JSON.stringify(state.d))==JSON.parse_string(JSON.stringify(expected)),"only named numeric draft changes: "+field)
		check(played.size()==1 and played[0].playing,"one actual player starts: "+field)
		check(played.size()==1 and is_equal_approx(played[0].gain,.28) and is_equal_approx(played[0].rate,1.22) and absf(played[0].volume-.168)<.0001,"authored gain x master .6 and rate: "+field)
		published.clear(); played.clear(); before=state.d.duplicate(true)
		state.act("lib_audit_value",{"field":field,"value":5}); await frames()
		check(published.is_empty() and played.is_empty() and state.d==before,"same-value edit remains silent: "+field)
	for invalid in [null,{}, {"field":"unknown","value":1},{"field":"arrival","value":true},{"field":"arrival","value":"7"},{"field":"arrival","value":1.5}]:
		fresh(); var before=state.d.duplicate(true); state.act("lib_audit_value",invalid); await frames()
		check(state.d==before and published.is_empty() and played.is_empty(),"invalid edit silent "+JSON.stringify(invalid))
	for phase in ["library_entered","top_ten_rising","top_ten_reached","pass_ready"]:
		fresh(phase); var before=state.d.duplicate(true); state.act("lib_audit_value",{"field":"arrival","value":7}); await frames()
		check(state.d==before and published.is_empty() and played.is_empty(),"phase-locked edit: "+phase)
	fresh(); state.d.native.settings.effects=false
	state.act("lib_audit_value",{"field":"arrival","value":7}); await frames()
	check(state.d.ui.libraryFinalsPuzzle.auditArrivalMinutes==7 and published.size()==1 and played.is_empty(),"muted effects persist the draft without playback")
	state.action_completed.disconnect(director.update_state); await director.shutdown(); director.queue_free(); await frames()
	var path=OS.get_environment("TIYI_AUDIO_QA_REPORT")
	if path.is_empty(): path="user://tiyi-draft-audio.json"
	var file=FileAccess.open(path,FileAccess.WRITE)
	if file==null: failures+=1; push_error("Cannot write report: "+path)
	else: file.store_string(JSON.stringify({"provenance":"reconstructed recovery-2","checks":checks,"failures":failures,"audible_acceptance":false,"cases":cases},"\t")); file.close()
	print("TIYI_AUDIO: ",checks," checks; ",failures," failures"); quit(1 if failures else 0)
