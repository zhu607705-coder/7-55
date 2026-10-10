extends SceneTree
const View=preload("res://scripts/presentation/c3_reversal_view.gd")
var checks: int=0
var errors: int=0
var state: Node
var main: Control
var host: Control
var world: Control
var cues: Array=[]
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: errors+=1; push_error(label)
func _initialize() -> void: call_deferred("run")
func advance_to(ms: float) -> void:
	var frames: int=0
	while host.current!=null and host.current.elapsed_ms<ms and frames<1000:
		if host.current.status=="inspecting": break
		var delta: float=minf(100,ms-host.current.elapsed_ms)
		world._process(delta/1000); host.tick(delta,true); frames+=1
func reload_file() -> void:
	check(state.save_game(),"actual save_game writes pending reversal")
	state.d=state.initial()
	check(state.load_game(),"actual load_game accepts pending reversal file")
	state.story_reset.emit(); state.changed.emit(); await process_frame; await process_frame
	host.set_process(false); world.set_process(false); host.tick(0,true)
func run() -> void:
	check(ProjectSettings.globalize_path("user://").begins_with("/tmp/"),"reversal tests use isolated actual save files")
	if errors: quit(1); return
	state=root.get_node("State"); state.developer_mode=false; state.d=state.initial()
	state.d.native.chapter=3; state.d.native.scene="theater_interior"; state.d.native.page="c3_theater"; state.d.rpgScene="theater_interior"; state.d.runtimeMode="rpg"
	state.d.theaterHunt.active=true; state.d.theaterHunt.phase="reversal"; state.d.theaterHunt.spotlightRound=3
	state.d.theaterHunt.admitted=true; state.d.items.decoyPaper=false; state.d.items.wetProgram=false
	root.size=Vector2i(1280,720)
	main=load("res://scenes/main.tscn").instantiate(); root.add_child(main)
	await process_frame; await process_frame
	host=main.c3_narrative_host; world=main.world; host.set_process(false); world.set_process(false)
	main.audio_director.cue_published.connect(func(id:String,payload:Dictionary)->void:cues.append({"id":id,"payload":payload}))
	state.act("c3_reversal"); host.tick(0,true)
	var session: RefCounted=host.current
	check(session!=null and session.sequence_id=="theater_reversal" and session.spec.delayMs==1320,"actual source1320ms physical reveal is issued")
	check(state.d.native.c3_reversal_pending and not state.d.items.decoyPaper and state.d.theaterHunt.phase=="reversal","request does not grant source facts before visual receipt")
	check(host.blocks_movement() and host.blocks_input(),"source physical reveal locks player and interactions")
	check(View.phase_at(0)=="locked" and View.phase_at(219)=="locked" and View.phase_at(220)=="cracked" and View.phase_at(370)=="fragments" and View.phase_at(770)=="escape" and View.phase_at(1320)=="dialogue","exact source reveal texture/timing boundaries")
	state.act("c3_reversal_visual_complete",{"elapsedMs":1320}); state.act("c3_reversal_visual_complete",session)
	check(not state.d.items.decoyPaper,"forged and real-but-early visual callbacks rejected")
	advance_to(700)
	var stale: RefCounted=session
	await reload_file(); session=host.current
	check(stale.status=="cancelled" and session!=stale and session.elapsed_ms==0 and not state.d.items.decoyPaper,"actual pre-boundary load restarts reveal without granting items")
	advance_to(1319)
	check(state.d.theaterHunt.phase=="reversal" and not state.d.qizhenLake.active,"source flags stay pending at1319ms")
	advance_to(1320)
	check(session.visual_acknowledged and state.d.theaterHunt.phase=="complete" and state.d.items.decoyPaper and state.d.items.wetProgram and state.d.qizhenLake.active,"only genuine1320ms receipt grants original source facts")
	check(host.blocks_input() and not host.blocks_movement(),"first source dialogue retains interaction lock but allows ordinary walking")
	check(session.emitted_lines==1,"first dialogue alone appears after reveal")
	state.act("c3_target:theater_exit")
	check(state.d.native.scene=="theater_interior","source-complete phase cannot exit during required dialogue")
	var inventory: Dictionary=state.d.items.duplicate(true)
	await reload_file(); session=host.current
	check(session.visual_acknowledged and session.spec.delayMs==0 and state.d.items==inventory,"actual post-boundary load replays narrative without re-granting rewards")
	advance_to(session.inspector_at_ms)
	check(session.status=="inspecting" and session.emitted_lines==2,"source freezes after exactly first two lines")
	check(is_instance_valid(main.modal) and main.inspected_item_id=="decoyPaper" and session.inspector_opened,"actual Main opens original item inspector")
	var at: float=session.elapsed_ms
	for _i in range(100): host.tick(100,true)
	check(session.elapsed_ms==at and session.emitted_lines==2,"inspector cannot be acknowledged by timer or leak final three lines")
	state.act("c3_reversal_inspect_closed",session)
	check(session.status=="inspecting","direct completion with genuine session still lacks host close receipt")
	await reload_file(); session=host.current
	check(session!=null and not is_instance_valid(main.modal) and not session.inspector_acknowledged,"actual inspector-pause save reload requires genuine reopened inspector")
	advance_to(session.inspector_at_ms)
	check(main.inspected_item_id=="decoyPaper" and is_instance_valid(main.modal),"inspector reopens on reconstructed source boundary")
	var legacy: Array=main.audio_director.scheduled.filter(func(e:Dictionary)->bool:return str(e.id).begins_with("native_theater_dialogue_reversal"))
	check(legacy.is_empty(),"old audio queues cannot duplicate or reveal future reversal lines")
	main._close_modal()
	check(session.inspector_acknowledged and session.status=="playing" and session.emitted_lines==3 and not is_instance_valid(main.modal),"actual inspector close starts exactly third source line")
	check(host.blocks_input(),"last three lines preserve exit lock")
	var close_time: float=session.elapsed_ms
	main._close_modal(); state.act("c3_reversal_inspect_closed",session)
	check(session.elapsed_ms==close_time and session.emitted_lines==3,"repeated close cannot skip lines")
	advance_to(session.duration_ms)
	check(session.status=="consumed" and host.current==null and state.d.native.c3_reversal_pending==false,"terminal line acknowledgement clears presentation lock")
	check(state.d.items==inventory and not world._interaction_presentation_blocks(),"no reward duplication or stale world lock")
	await reload_file()
	check(host.current==null and state.get_c3_narrative_session()==null,"completed file does not replay reversal")
	var invalid: Dictionary=state.d.duplicate(true); invalid.native.c3_reversal_pending="yes"
	check(not state.validate_snapshot(invalid),"native pending marker is explicitly boolean-validated")
	check(state.d.items==inventory,"save/reload preserves source items exactly")
	# Actual split/narrow-world containment and hidden-world pause, on new ordinary queue.
	state.d.native.scene="canteen_interior"; state.d.rpgScene="canteen_interior"; state.d.native.page="c3_canteen"
	state.d.canteenHunt.active=true; state.d.canteenHunt.phase="tray_search"; state.d.canteenHunt.entryPaperEscaped=true
	state.d.native.positions={}; state.story_reset.emit(); state.changed.emit(); await process_frame
	world.player=world._find_safe(Vector2(1466,608)); world._sync_player()
	state.act("c3_target:auntie"); host.tick(0,true); session=host.current
	check(host.view.get_parent()==world and host.view.panel.get_rect().position.x>=0 and host.view.panel.get_rect().end.x<=960 and host.view.panel.get_rect().end.y<=540,"actual split shell subtitles remain inside960x540 RPG viewport")
	# Headless OS focus is unavailable; retain actual visibility/layout and provide
	# only an explicit focused-window test input to the host's runtime reader.
	host.runtime_reader=func()->Dictionary:
		var context: Dictionary=main._read_runtime_state(); context.native.host.focused=true; return context
	root.size=Vector2i(390,844); main.mobile_world=false; main._layout(); await process_frame; await process_frame
	at=session.elapsed_ms; var cue_count: int=cues.size()
	for _i in range(10): host._process(.1)
	check(not world.is_visible_in_tree() or not main.world_frame.is_visible_in_tree(),"actual narrow phone-only layout hides world")
	check(session.elapsed_ms==at and not main.world_frame.is_visible_in_tree() and host.view.get_parent()==world,"phone-only layout pauses invisible dialogue and contains its surface in hidden world")
	main.mobile_world=true; main._layout(); await process_frame; await process_frame
	host._process(.1)
	check(session.elapsed_ms>at and host.view.is_visible_in_tree(),"actual narrow world layout resumes the same dialogue")
	check(Rect2(Vector2.ZERO,world.size).encloses(host.view.panel.get_rect()),"mobile dialogue stays inside the current exploration world")
	var active_key: String=session.audio_keys.get(session.lines[0].text,"")
	var same_cues: Array=cues.slice(cue_count).filter(func(e:Dictionary)->bool:return e.id=="chapter3_story_line" and e.payload.get("subtitleKey")==active_key)
	check(same_cues.is_empty(),"hide/show resumes current line without duplicating its voice cue")
	await main.shutdown(); main.queue_free(); await process_frame
	print("Chapter 3 reversal/save/layout: %d checks, %d failures" % [checks,errors]); quit(0 if errors==0 else 1)
