extends SceneTree
const Library=preload("res://scripts/chapters/library022.gd")
const Session=preload("res://scripts/presentation/library_story_session.gd")
const Host=preload("res://scripts/presentation/library_story_host.gd")
var checks: int=0
var errors: int=0
var s: Dictionary
var library: RefCounted
var witness: Node
var fixture: Dictionary
var covered: Array=[]
var covered_lines: int=0
var cues: Array=[]
var under_clicks: int=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: errors+=1; push_error(label)
func fresh() -> Dictionary:
	var state: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/initial_state.json"))
	state.native={"chapter":2,"scene":"campus_bootstrap","page":"phone_home","mode":"light","settings":{}}
	state.actOne.phase="complete"; state.actOne.cc98Login.authenticated=true; state.networkMode="campus_wifi"
	state.ui.libraryFinalsPhase="library_route_unlocked"; state.items.rightArrow=true
	return state
func act(action: String,value: Variant=null) -> Dictionary: return library.dispatch(s,action,value)
func play(id: String) -> void:
	var session: RefCounted=library.story_session(s)
	check(session!=null,"queued "+id)
	if session==null: return
	check(session.sequence_id==id,"event maps to "+id)
	check(session.attach(s,witness),"host attaches "+id)
	var expected: Array=fixture.sequences[id]
	check(session.lines.size()==expected.size(),"authored line count "+id)
	for i in range(expected.size()):
		var row: Dictionary=session.snapshot()
		check(row.speaker==expected[i].speaker and row.text==expected[i].text,"verbatim speaker/text %s:%s" % [id,i])
		check(row.durationMs==expected[i].durationMs,"source grapheme duration %s:%s" % [id,i])
		var pending: Array=session.take_cues()
		check(pending.size()==1 and pending[0].id=="library_story_line" and pending[0].payload.subtitleKey==expected[i].lineKey,"exact voice cue %s:%s" % [id,i])
		session.advance(s,witness); covered_lines+=1
	check(session.status=="complete","all lines complete "+id)
	var result: Dictionary=act("lib_story_complete",session)
	check(result.get("story_finished","")==id and session.status=="consumed","controller consumes once "+id)
	var repeated: Dictionary=act("lib_story_complete",session)
	check(not repeated.has("story_finished"),"repeat completion rejected "+id)
	covered.append(id)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	fixture=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/library_story_source.json"))
	library=Library.new(); witness=Node.new(); root.add_child(witness); s=fresh()
	check(fixture.sequenceCount==12 and fixture.lineCount==53,"fixture covers 12 sequences and 53 authored lines")
	check(fixture.separateOwner.lineCount==20,"final 20-line 022 conversation remains C3-owned")
	act("lib_enter"); check(s.ui.libraryFinalsPhase=="library_entered","first entry preserves source phase")
	act("lib_record"); check(not s.ui.libraryFinalsPuzzle.entranceRecordRead,"entry reveal blocks underlying interaction")
	play("library_entered"); act("lib_record"); act("lib_backpack"); play("library_occupied_seat_found")
	act("lib_note"); act("lib_investigate","occupancyNote"); play("cc98_occupation_post_opened")
	act("lib_catalog_terminal"); act("lib_catalog_search","三分钟离座法"); act("lib_catalog_select","three-minute-leave-method"); play("library_catalog_match_found")
	act("lib_shelf"); act("lib_read_rule")
	check(s.ui.libraryFinalsPuzzle.archivedRuleRead and not s.ui.libraryFinalsPuzzle.archivedRuleBriefingSeen,"reading does not prematurely acknowledge rule briefing")
	act("lib_story_complete",{"sequenceId":"library_archived_rule_recovered","complete":true})
	check(not s.ui.libraryFinalsPuzzle.archivedRuleBriefingSeen,"forged dictionary cannot acknowledge rule")
	play("library_archived_rule_recovered"); check(s.ui.libraryFinalsPuzzle.archivedRuleBriefingSeen,"rule acknowledgement after seven lines")
	act("lib_front_desk"); check(not s.ui.libraryFinalsPuzzle.frontDeskProofRequestSeen,"front desk request remains unacknowledged before five lines")
	play("library_front_desk_proof_request"); check(s.ui.libraryFinalsPuzzle.frontDeskProofRequestSeen,"front desk acknowledgment follows full exchange")
	act("lib_photo"); s.ui.brightness=20; act("lib_dim_photo"); s.native.lib_selected_photo="seat_022_clue"; act("lib_item_report"); act("lib_scan")
	act("lib_scan_result",{"scanMs":720,"identityChecks":[false,false,false],"stamped":true})
	for i in range(8): check(library.story_session(s,100)==null,"stamp story delays at "+str((i+1)*100))
	check(library.story_session(s,99)==null,"stamp story still pending at899ms")
	check(library.story_session(s,1)!=null,"stamp story starts at source900ms")
	play("library_bag_nonperson_proof_issued")
	act("lib_receipt"); s.networkMode="cellular"; act("lib_audit",["7","47","3"]); play("tiyi_presence_proof_issued")
	s.networkMode="campus_wifi"
	for id: String in Library.EVIDENCE: act("lib_upload",id)
	check(s.ui.libraryFinalsPhase=="bd_briefing" and not s.ui.libraryFinalsPuzzle.preBdBriefingSeen,"four evidence uploads queue briefing without unlocking bd")
	act("lib_bd_briefing"); act("lib_bd_select","bd-rule-count")
	check(not s.ui.libraryFinalsPuzzle.preBdBriefingSeen and s.ui.libraryFinalsPuzzle.bdSelectedPostIds.is_empty(),"legacy briefing intent cannot bypass dialogue")
	# A genuine source timer reaches the last line, but cannot confirm bd.
	var bd: RefCounted=library.story_session(s); bd.attach(s,witness)
	for i in range(3):
		while bd.line_index==i: bd.frame(s,100,witness)
	for i in range(100): bd.frame(s,100,witness)
	check(bd.line_index==3 and bd.status=="playing","bd final line stays until explicit confirmation")
	act("lib_story_complete",bd); check(not s.ui.libraryFinalsPuzzle.preBdBriefingSeen,"timer cannot write bd fact")
	bd.cancel(); library.story_session(s)
	play("cc98_evidence_set_completed")
	check(s.ui.libraryFinalsPhase=="top_ten_rising" and s.ui.libraryFinalsPuzzle.preBdBriefingSeen,"explicit final bd confirmation unlocks controller phase")
	for id: String in Library.BD_IDS: act("lib_bd_select",id)
	act("lib_bd_submit"); play("cc98_top_ten_reached"); act("lib_recovery_open")
	for id: String in Library.RECOVERY: act("lib_recovery_upload",id)
	act("lib_generate_pass"); check(s.ui.libraryFinalsPuzzle.evictionPassGenerated and not s.ui.libraryFinalsPuzzle.passBriefingSeen,"PASS generation does not acknowledge its dialogue")
	play("library_seat_release_pass_issued"); check(s.ui.libraryFinalsPuzzle.passBriefingSeen,"PASS briefing only acknowledged after both lines")
	act("lib_apply_pass"); check(s.ui.libraryFinalsPuzzle.backpackEvicted,"controller owns eviction before presentation")
	act("lib_sit"); check(not s.ui.libraryFinalsPuzzle.playerSeated,"eviction exchange cannot be skipped by sitting")
	play("library_backpack_evicted"); act("lib_sit")
	check(library.story_session(s)==null and library.scene_session(s)!=null,"final022 remains exclusively existing C3 opening")
	check(covered.size()==12 and covered_lines==53,"all authored story sequences traversed end-to-end")
	# Save replacement and stale capabilities, plus source recovery priority.
	s=fresh(); s.ui.libraryFinalsPhase="evidence_gathering"; s.ui.libraryFinalsPuzzle.archivedRuleRead=true
	var stale: RefCounted=library.story_session(s); stale.attach(s,witness)
	s=s.duplicate(true); act("lib_story_complete",stale)
	check(not s.ui.libraryFinalsPuzzle.archivedRuleBriefingSeen,"imported state rejects old capability")
	var recovered: RefCounted=library.story_session(s)
	check(recovered!=stale and recovered.sequence_id=="library_archived_rule_recovered","reload reconstructs required briefing")
	recovered.attach(s,witness)
	var impostor:=Node.new(); root.add_child(impostor); recovered.advance(s,impostor)
	check(recovered.line_index==0,"other host cannot advance")
	recovered.frame(s,100,witness,false); recovered.advance(s,witness)
	check(recovered.line_index==0 and recovered.elapsed_ms==0,"blur pauses timer and input")
	recovered.frame(s,999999,witness,true); check(recovered.elapsed_ms==100,"long frame does not skip dialogue")
	# Real viewport input, including a pointer over an underlying button.
	s=fresh(); library=Library.new(); act("lib_enter")
	root.size=Vector2i(960,540)
	var underlying:=Button.new(); underlying.position=Vector2(10,10); underlying.size=Vector2(150,80); underlying.pressed.connect(func():under_clicks+=1); root.add_child(underlying)
	var host: Control=Host.new(); root.add_child(host)
	host.setup(func():return s,func(ms: float):return library.story_session(s,ms),func(id: String,v: Variant):return act(id,v),func(id: String,payload: Dictionary):cues.append({"id":id,"payload":payload}))
	host.set_process(false); host.tick(0); await process_frame
	check(host.blocks_input() and host.view.visible and host.view.body.text==fixture.sequences.library_entered[0].text,"native modal displays first exact line")
	var key:=InputEventKey.new(); key.keycode=KEY_SPACE; key.pressed=true; Input.parse_input_event(key); await process_frame
	check(host.current.line_index==1,"real Space advances exactly one line")
	key=InputEventKey.new(); key.keycode=KEY_TAB; key.pressed=true; Input.parse_input_event(key); await process_frame
	check(host.current.line_index==1 and host.view.has_focus(),"Tab keeps focus in dialogue")
	var mouse:=InputEventMouseButton.new(); mouse.button_index=MOUSE_BUTTON_LEFT; mouse.pressed=true; mouse.position=Vector2(30,30); Input.parse_input_event(mouse); await process_frame
	mouse=InputEventMouseButton.new(); mouse.button_index=MOUSE_BUTTON_LEFT; mouse.pressed=false; mouse.position=Vector2(30,30); Input.parse_input_event(mouse); await process_frame
	check(host.current.line_index==2 and under_clicks==0,"pointer advances dialogue without clicking underlying control")
	var touch:=InputEventScreenTouch.new(); touch.index=0; touch.pressed=true; touch.position=Vector2(700,300); Input.parse_input_event(touch); await process_frame
	check(host.current.line_index==3,"real touch advances dialogue")
	for i in range(9):
		key=InputEventKey.new(); key.keycode=KEY_ENTER; key.pressed=true; Input.parse_input_event(key); await process_frame
	check(not host.blocks_input() and not host.view.visible,"modal closes after twelve lines")
	check(cues.size()==13 and cues[-1].id=="library_story_finished","one exact cue per line plus finished event")
	# Every authored line fits the canonical portrait and landscape viewports.
	# Optional graphical run writes real rendered acceptance images.
	var capture: bool=OS.get_cmdline_user_args().has("--capture") and DisplayServer.get_name()!="headless"
	if capture: DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.screenshots/library-story"))
	for viewport: Vector2i in [Vector2i(390,844),Vector2i(430,860),Vector2i(960,540),Vector2i(1440,900)]:
		root.size=viewport; await process_frame
		for id: String in fixture.sequences:
			var sample: RefCounted=Session.new(s,id,library._data().storyDialogues[id])
			host.view.session=sample
			for i in range(sample.lines.size()):
				sample.line_index=i; host.view.tick(); await process_frame
				check(Rect2(Vector2.ZERO,Vector2(viewport)).encloses(host.view.panel.get_global_rect()),"dialogue panel fits %s %s:%d" % [viewport,id,i])
				check(host.view.body.get_line_count()*host.view.body.get_line_height()<=host.view.body.size.y,"no authored line clipped %s %s:%d" % [viewport,id,i])
				if capture and ((id=="library_entered" and i==7) or (id=="cc98_evidence_set_completed" and i==3)):
					await RenderingServer.frame_post_draw
					root.get_texture().get_image().save_png("res://.screenshots/library-story/%s-%sx%s.png" % [id,viewport.x,viewport.y])
	host.queue_free(); underlying.queue_free(); impostor.queue_free(); witness.queue_free(); await process_frame
	await test_real_shell()
	print("Library story sequences: ",checks," checks, ",errors," errors; 12 sequences /53 authored lines")
	quit(0 if errors==0 else 1)

func test_real_shell() -> void:
	var state: Node=root.get_node("State")
	state.developer_mode=true; state.d=state.initial()
	state.d.native.chapter=2; state.d.native.scene="campus_bootstrap"; state.d.native.page="phone_home"
	state.d.rpgScene="campus_bootstrap"; state.d.runtimeMode="rpg"
	state.d.actOne.phase="complete"; state.d.ui.libraryFinalsPhase="library_route_unlocked"
	root.size=Vector2i(1440,900)
	var shell: Control=load("res://scenes/main.tscn").instantiate(); root.add_child(shell)
	await process_frame; await process_frame
	state.act("lib_enter"); await process_frame; await process_frame
	var live: Control=shell.library_story_host
	live.set_process(false)
	check(live.current!=null and live.current.valid(state.d),"real shell binds authoritative story session")
	check(live.view.body.text==fixture.sequences.library_entered[0].text and shell.world._scene_presentation_blocks(),"real shell shows entry and locks world")
	state.act("lib_record")
	check(not state.d.ui.libraryFinalsPuzzle.entranceRecordRead,"shared State cannot dispatch underlying action during modal")
	for i in range(12):
		var key:=InputEventKey.new(); key.keycode=KEY_ENTER; key.pressed=true; Input.parse_input_event(key); await process_frame
	check(live.current==null and not shell.world._scene_presentation_blocks(),"real shell keyboard closes complete entry and restores world")
	state.act("lib_record")
	check(state.d.ui.libraryFinalsPuzzle.entranceRecordRead,"real shell action resumes after story completion")
	state.d=state.initial(); state.d.native.chapter=2; state.d.native.scene="library_interior"; state.d.native.page="cc98"
	state.d.rpgScene="library_interior"; state.d.runtimeMode="rpg"; state.d.ui.libraryFinalsPhase="bd_briefing"
	state.d.ui.libraryFinalsPuzzle.cc98UploadedEvidenceIds=Library.EVIDENCE.keys(); shell._refresh(); live.tick(0)
	check(live.current!=null and live.current.sequence_id=="cc98_evidence_set_completed","real load recovers pending bd briefing")
	for i in range(3):
		var key:=InputEventKey.new(); key.keycode=KEY_SPACE; key.pressed=true; Input.parse_input_event(key); await process_frame
	for i in range(100): live.tick(100)
	check(live.current!=null and live.current.line_index==3 and not state.d.ui.libraryFinalsPuzzle.preBdBriefingSeen,"real shell bd timer does not approve")
	var key:=InputEventKey.new(); key.keycode=KEY_SPACE; key.pressed=true; Input.parse_input_event(key); await process_frame
	check(live.current==null and state.d.ui.libraryFinalsPuzzle.preBdBriefingSeen and state.d.ui.libraryFinalsPhase=="top_ten_rising","real shell last Space commits bd acknowledgement once")
	state.story_reset.emit()
	check(live.current==null and not live.view.visible,"real story reset removes library modal")
	if is_instance_valid(shell.audio_director): await shell.audio_director.shutdown()
	if is_instance_valid(shell.media_host): await shell.media_host.shutdown()
	shell.queue_free(); await process_frame
