extends SceneTree
const Session=preload("res://scripts/presentation/c3_scene_session.gd")
const Library=preload("res://scripts/chapters/library022.gd")
const Chapter=preload("res://scripts/chapters/chapter3.gd")
const Host=preload("res://scripts/presentation/c3_scene_host.gd")
var checks: int=0
var errors: int=0
var s: Dictionary
var library: RefCounted
var chapter: RefCounted
var cues: Array=[]
class MockWorld extends Control:
	var scene_id: String="library_interior"
	var player:=Vector2(1053,660)
	var camera:=Vector2(1000,640)
	var zoom: float=1
	var world_size:=Vector2(1672,941)
	var move_target:=Vector2.INF
	var touch_axis:=Vector2.ZERO
	var walk_clock: float=0
	func _update_camera() -> void: camera=player
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: errors+=1; push_error(label)
func fresh(kind: String) -> Dictionary:
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/initial_state.json"))
	data.native={"chapter":2 if kind=="opening" else 3,"scene":"library_interior" if kind=="opening" else "canteen_interior","page":"library_022_dialogue" if kind=="opening" else "c3_canteen","mode":"light","settings":{},"player":{"x":1053.0,"y":660.0},"host":{"focused":true,"world_visible":true}}
	data.runtimeMode="rpg"; data.rpgScene=data.native.scene
	if kind=="opening":
		data.ui.libraryFinalsPhase="seat_recovered"; data.ui.libraryFinalsPuzzle.playerSeated=true
	else:
		data.canteenHunt.active=true; data.canteenHunt.phase="tray_search"; data.canteenHunt.entryPaperEscaped=false
	return data
func run_ms(session: RefCounted,host: Node,ms: float) -> void:
	var remaining: float=ms
	while remaining>0:
		var delta: float=minf(10,remaining); session.frame(s,delta,host); remaining-=delta
func _initialize() -> void: call_deferred("run")
func run() -> void:
	library=Library.new(); chapter=Chapter.new()
	var native_host:=Node.new(); root.add_child(native_host)
	s=fresh("opening")
	for i in range(40): library.dispatch(s,"lib_dialogue_next")
	check(s.native.chapter==2 and not s.canteenHunt.active,"legacy dialogue count does not grant chapter")
	library.dispatch(s,"lib_opening_complete",{"complete":true,"elapsedMs":100000})
	check(s.native.chapter==2,"forged opening dictionary rejected")
	var opening: RefCounted=library.scene_session(s)
	check(opening==library.scene_session(s),"pending opening reuses issued capability")
	check(opening.beats.size()==27 and opening.lines.size()==20,"source has 20 authored lines and seven transition beats")
	var fixture: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/chapter3_scene_source.json"))
	check(JSON.parse_string(JSON.stringify(opening.beats))==fixture.normal,"all normal opening beats equal original TypeScript helper output")
	check(JSON.parse_string(JSON.stringify(Session.new(s,"opening",true).beats))==fixture.reduced,"all reduced opening beats equal original TypeScript helper output")
	for beat: Dictionary in opening.beats:
		if beat.lineIndex!=null:
			var line: String=opening.lines[int(beat.lineIndex)].text
			check(beat.durationMs==clampi(760+line.to_utf16_buffer().size()/2*48,1200,1900),"source UTF16 duration "+str(beat.lineIndex))
	check(opening.attach(s,native_host),"opening attaches to one host")
	check(not opening.attach(s,native_host),"duplicate opening attachment refused")
	var impostor:=Node.new(); root.add_child(impostor)
	opening.advance_current(s,impostor)
	check(opening.beat_index==0,"foreign host cannot fast-forward")
	opening.frame(s,100,native_host,false); opening.advance_current(s,native_host)
	check(opening.elapsed_ms==0,"focus loss pauses time and controls")
	opening.frame(s,100000,native_host,true)
	check(opening.elapsed_ms==100,"long frames capped at source RAF catch-up")
	library.dispatch(s,"lib_opening_complete",opening)
	check(not s.canteenHunt.active,"issued authentic capability still cannot complete early")
	opening.skip_to_arrival(s,native_host)
	check(opening.snapshot().phase=="arrival" and opening.status=="playing" and not s.canteenHunt.active,"skip goes to arrival without immediately unlocking")
	check(opening.take_cues()[-1].id=="chapter_three_opening_arrival","skip emits source arrival cue")
	run_ms(opening,native_host,1299)
	check(opening.status=="playing","arrival holds full authored duration")
	run_ms(opening,native_host,1); library.dispatch(s,"lib_opening_complete",opening)
	check(s.native.chapter==3 and s.canteenHunt.active and s.canteenHunt.phase=="tracking","opening completion applies source canteen handoff")
	check(s.native.scene=="campus_bootstrap" and s.rpgCheckpoint=="campus_library_gate" and not s.canteenHunt.entryPaperEscaped,"opening returns to campus without skipping canteen scene")
	check(s.ui.libraryFinalsPuzzle.clueIds.has("borrowed_attendance_record") and s.ui.libraryFinalsPuzzle.nextQuestId=="chapter_three_canteen_hunt","source clue and next quest preserved")
	check(not opening.consume(s),"consumed capability cannot replay")
	# Replacing state on import must cancel a capability, even for equal content.
	s=fresh("opening"); var stale: RefCounted=library.scene_session(s); stale.attach(s,native_host)
	s=s.duplicate(true); stale.frame(s,50,native_host)
	check(stale.status=="cancelled","save import invalidates old state-bound opening")
	check(library.scene_session(s)!=stale,"pending save reconstructs fresh opening session")
	# Canteen entry route cannot be replaced by a target operation or callback.
	s=fresh("canteen")
	var entry: RefCounted=chapter.scene_session(s)
	check(chapter.targets("canteen_interior",s).is_empty(),"all canteen targets stay hidden until entry paper escapes")
	s.native.player={"x":638.0,"y":582.0}; chapter.dispatch(s,"c3_target:auntie")
	check(not s.canteenHunt.trayTaskStarted,"entry paper gate protects controller physical operations")
	chapter.dispatch(s,"c3_entry_paper_complete",{"elapsedMs":999999,"escaped":true})
	check(not s.canteenHunt.entryPaperEscaped,"forged entry receipt rejected")
	check(entry.attach(s,native_host),"canteen issues waiting session")
	check(not entry.post_collision(s,Vector2(1053,302),native_host),"position spoof cannot trigger proximity")
	s.native.player={"x":1053.0,"y":663.0}
	check(not entry.post_collision(s,Vector2(1053,663),native_host),"outside 360 source radius stays idle")
	s.native.player={"x":1053.0,"y":660.0}
	check(not entry.post_collision(s,Vector2(1053,660),native_host,false),"hidden canteen does not trigger")
	check(entry.post_collision(s,Vector2(1053,660),native_host),"post-collision actual position triggers within radius")
	check(not entry.post_collision(s,Vector2(1053,660),native_host),"entry discovery fires once")
	run_ms(entry,native_host,819); check(entry.take_cues().is_empty(),"no surprise cue before 820ms")
	run_ms(entry,native_host,1); check(entry.take_cues()[0].id=="canteen_entry_paper_spotted","surprise cue at exact source time")
	run_ms(entry,native_host,360); check(entry.prompt_at().text=="玩家：找到了。","player bubble preserves exact line and delay")
	run_ms(entry,native_host,2020); check(entry.take_cues()[0].id=="canteen_entry_paper_escape_started","run begins at 3200ms")
	check(entry.paper_pose().frame==0 and is_equal_approx(entry.paper_pose().scale,0.82),"run uses source frame and scale")
	run_ms(entry,native_host,190); check(entry.paper_pose().point.distance_to(Vector2(944,300))<0.01,"first route point exact")
	run_ms(entry,native_host,1120+260); check(entry.paper_pose().point.distance_to(Vector2(92,252))<0.01,"paper turns at source corner")
	run_ms(entry,native_host,199); check(entry.paper_pose().point==Vector2(92,252),"source corner pause is 200ms")
	run_ms(entry,native_host,1+230+430+220); check(not entry.paper_pose().visible and entry.status=="playing","exit hides paper but camera return still gates completion")
	chapter.dispatch(s,"c3_entry_paper_complete",entry); check(not s.canteenHunt.entryPaperEscaped,"camera-return completion cannot be skipped")
	run_ms(entry,native_host,1259); check(entry.status=="playing","full 500+720+40 camera return is required")
	run_ms(entry,native_host,1); chapter.dispatch(s,"c3_entry_paper_complete",entry)
	check(s.canteenHunt.entryPaperEscaped and not chapter.targets("canteen_interior",s).is_empty(),"source 7110ms completion exposes physical targets")
	# Reduced motion shortens motion, not text or required route stages.
	s=fresh("canteen"); s.native.settings.reduced_motion=true
	entry=chapter.scene_session(s); entry.attach(s,native_host); entry.post_collision(s,Vector2(1053,660),native_host)
	run_ms(entry,native_host,900)
	check(entry.speech_bubbles().size()==2,"reduced-motion speech bubbles overlap as authored")
	check(entry.route_start_ms==1280 and entry.route[0].durationMs==120 and entry.route[1].durationMs==694.4,"reduced route durations preserve min120 and x0.62")
	# Full native host controls and post-completion prompt ownership.
	s=fresh("opening")
	var world:=MockWorld.new(); world.size=Vector2(960,540); root.add_child(world)
	var host:=Host.new(); root.add_child(host); host.size=Vector2(960,540)
	host.setup(world,func()->Dictionary:return s,func()->RefCounted:return library.scene_session(s) if s.native.scene=="library_interior" else chapter.scene_session(s),func(action: String,value: Variant)->Dictionary:return library.dispatch(s,action,value) if action.begins_with("lib_") else chapter.dispatch(s,action,value),func(id: String,_payload: Dictionary):cues.append(id),func()->Dictionary:return s.duplicate(true))
	host.set_process(false); host.tick(0)
	check(host.blocks_world_input() and host.opening.visible,"host mounts opening modal and locks world")
	host._skip(); check(s.native.chapter==2 and host.opening.advance_button.text=="回到校园","native skip retains actionable arrival")
	host._advance(); check(s.native.chapter==3 and not host.blocks_world_input() and not host.opening.visible,"native arrival control commits once and removes modal")
	s=fresh("canteen"); world.scene_id="canteen_interior"; host.tick(0)
	check(host.blocks_world_input(),"host triggers entry from committed source position after world collision")
	for i in range(712): host.tick(10)
	check(s.canteenHunt.entryPaperEscaped and not host.blocks_world_input(),"native host submits authentic route completion and releases movement")
	check(host.paper.tail_lines==["旁白：纸条钻进了食堂。","系统：先别跟丢。"],"both original system prompts follow camera return")
	check(cues.count("canteen_entry_paper_escape_completed")==1,"native entry completion cue emits once")
	for i in range(320): host.tick(10)
	check(host.paper.tail_lines.is_empty(),"post-entry prompts retire after two 1600ms steps")

	# Losing the scene mid-route cannot publish a completion or retain a lock.
	s=fresh("canteen"); host.tick(0); host.tick(100)
	var abandoned: RefCounted=host.current
	s.native.scene="campus_bootstrap"; world.scene_id="campus_bootstrap"; host.tick(0)
	check(abandoned.status=="cancelled" and not host.blocks_world_input() and not s.canteenHunt.entryPaperEscaped,"scene leave cancels entry route without granting escape")
	# Returning starts at a new source queue pose, not at a trusted saved timer.
	s.native.scene="canteen_interior"; world.scene_id="canteen_interior"; s.native.player={"x":100.0,"y":600.0}; world.player=Vector2(100,600); host.tick(0)
	check(host.current!=abandoned and host.current.status=="waiting" and host.paper.session!=null,"returning to unfinished scene restores waiting paper")
	host.tick(100,false)
	check(host.current.idle_ms==0,"focus pause also freezes idle paper")
	host.reset(); check(not host.blocks_world_input() and not host.opening.visible,"reset clears presentation locks")
	host.queue_free(); world.queue_free(); native_host.queue_free(); impostor.queue_free()
	await process_frame
	await test_real_shell()
	print("Chapter 3 scene timeline checks: ",checks,"; failures: ",errors)
	quit(0 if errors==0 else 1)

func test_real_shell() -> void:
	var state: Node=root.get_node("State")
	state.developer_mode=true
	state.d=state.initial()
	state.d.native.chapter=2; state.d.native.scene="library_interior"; state.d.native.page="library_022_dialogue"
	state.d.runtimeMode="rpg"; state.d.rpgScene="library_interior"
	state.d.ui.libraryFinalsPhase="seat_recovered"; state.d.ui.libraryFinalsPuzzle.playerSeated=true
	state.d.rpgCheckpoint="library_seat_022"
	root.size=Vector2i(1440,900)
	var shell: Control=load("res://scenes/main.tscn").instantiate(); root.add_child(shell)
	await process_frame; await process_frame
	check(shell.c3_scene_host.current!=null and shell.c3_scene_host.current.valid(state.d),"real shell authoritative reader preserves controller session identity")
	shell.c3_scene_host.set_process(false)
	shell.c3_scene_host._skip(); shell.c3_scene_host._advance()
	await process_frame
	check(state.d.native.chapter==3 and state.d.native.scene=="campus_bootstrap" and shell.world.scene_id=="campus_bootstrap","real shell arrival completion refreshes the campus world")
	state.d=state.initial()
	state.d.native.chapter=3; state.d.native.scene="canteen_interior"; state.d.native.page="c3_canteen"
	state.d.runtimeMode="rpg"; state.d.rpgScene="canteen_interior"
	state.d.canteenHunt.active=true; state.d.canteenHunt.phase="tray_search"; state.d.rpgCheckpoint="canteen_entrance"
	shell._refresh(); shell.world.player=Vector2(1053,660); shell.world._sync_player(); shell.c3_scene_host.tick(0)
	check(shell.c3_scene_host.blocks_world_input() and shell.world._scene_presentation_blocks(),"real world movement and interaction guard use active canteen host")
	for i in range(712): shell.c3_scene_host.tick(10)
	await process_frame
	check(state.d.canteenHunt.entryPaperEscaped and not shell.world.targets.is_empty(),"real shell completion refreshes canteen target affordances")
	state.story_reset.emit()
	check(shell.c3_scene_host.current==null and not shell.c3_scene_host.blocks_world_input(),"real story reset clears scene host state")
	# Retire all audio owners through the production shutdown contract, not only movies.
	await shell.shutdown()
	shell.queue_free(); await process_frame
