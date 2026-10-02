extends SceneTree
const Chapter=preload("res://scripts/chapters/chapter3.gd")
const Session=preload("res://scripts/presentation/c3_narrative_session.gd")
const Host=preload("res://scripts/presentation/c3_narrative_host.gd")
const Guard=preload("res://scripts/save_domain_guard.gd")
var checks: int=0
var errors: int=0
var s: Dictionary
var chapter: RefCounted
var cues: Array=[]
class MockWorld extends Control:
	var scene_id: String="canteen_interior"
	var player:=Vector2(1300,540)
	var camera:=Vector2(1000,640)
	var zoom: float=1.1
	var world_size:=Vector2(13668,1084)
	var move_target:=Vector2.INF
	var touch_axis:=Vector2.ZERO
	var walk_clock: float=0
	var facing: String="side"
	var player_flip: bool=false
	func _update_camera() -> void: camera=player
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: errors+=1; push_error(label)
func initial(scene: String="canteen_interior") -> Dictionary:
	var value: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/initial_state.json"))
	value.native={"chapter":3,"scene":scene,"page":"c3_canteen","mode":"light","settings":{},"player":{"x":1466,"y":608}}
	value.canteenHunt.active=true; value.canteenHunt.phase="tray_search"; value.canteenHunt.entryPaperEscaped=true
	value.runtimeMode="rpg"; value.rpgScene=scene
	return value
func run_ms(session: RefCounted,host: Node,ms: float,focused: bool=true) -> void:
	while ms>0:
		var delta: float=minf(10,ms); session.frame(s,delta,host,focused); ms-=delta
func finish(session: RefCounted,host: Node) -> void:
	if session.status=="issued": check(session.attach(s,host),"issued narrative attaches")
	run_ms(session,host,session.duration_ms+100)
	chapter.dispatch(s,"c3_story_complete",session)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var fixture: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/chapter3_narrative_source.json"))
	var owner:=Node.new(); root.add_child(owner)
	# Original TS methods, executed with their own timer and duration helper,
	# independently provide all 19 authored queues (not native assumptions).
	for id: String in fixture.groups:
		var oracle: Dictionary=fixture.groups[id]
		s=initial("theater_interior" if id.begins_with("theater_") else "canteen_interior")
		var authored: Array=[]
		for line: Dictionary in oracle.lines: authored.append(line.text)
		var config: Dictionary={"id":id,"lines":authored,"scene":s.native.scene}
		if id=="canteen_escape": s.canteenHunt.phase="chase_ready"; config.stepMs=1200; config.delayMs=0
		if id=="qizhen_approach":
			s=initial("campus_qizhen_loop"); s.qizhenLake.active=true; s.qizhenLake.phase="location_search"
			config.scene=s.native.scene; config.merge(fixture.approach); config.durations=[]
			for line: Dictionary in oracle.lines: config.durations.append(line.durationMs)
		var session:=Session.new(s,config)
		check(JSON.parse_string(JSON.stringify(session.lines))==oracle.lines,id+" every source string, order, onset, duration")
		if oracle.completeAtMs!=null: check(session.duration_ms==float(oracle.completeAtMs),id+" original completion time")
		if id=="qizhen_approach": check(session.runtime==fixture.route,"approach original authored route")
		check(session.attach(s,owner),id+" attaches")
		var expected_voice: int=0
		for line: Dictionary in session.lines:
			if session.audio_keys.has(Session._normalize(line.text)): expected_voice+=1
		run_ms(session,owner,session.duration_ms)
		check(session.take_cues().size()==expected_voice,id+" exactly one source-key voice per authored voiced line")
	# Actual controller: do not grant the auntie's task until every original line.
	s=initial(); chapter=Chapter.new()
	var result: Dictionary=chapter.dispatch(s,"c3_target:auntie")
	check(result.get("narrative_owned",false) and str(result.get("message","" )).is_empty(),"dialogue has sole owner, no joined future toast")
	var story: RefCounted=chapter.narrative_session(s)
	check(story.sequence_id=="canteen_tray_intro" and not s.canteenHunt.trayTaskStarted,"task remains locked before first line")
	chapter.dispatch(s,"c3_story_complete",{"complete":true})
	check(not s.canteenHunt.trayTaskStarted,"forged dictionary cannot acknowledge narrative")
	story.attach(s,owner)
	check(not story.blocks_movement(),"ordinary source dialogue permits walking")
	var intruder:=Node.new(); root.add_child(intruder)
	story.frame(s,100,intruder)
	check(story.elapsed_ms==0,"unowned frame cannot accelerate narrative")
	run_ms(story,owner,7500,false)
	check(story.elapsed_ms==0,"blur pauses story timing")
	run_ms(story,owner,2490)
	check(story.emitted_lines==1 and story.snapshot().rawText!=fixture.groups.canteen_tray_intro.lines[1].text,"second line is not revealed early (source120ms gap)")
	chapter.dispatch(s,"c3_target:tray_blue_01")
	check(s.canteenHunt.carriedTrayIds.is_empty() and not s.canteenHunt.trayTaskStarted,"interactions cannot advance beneath queue")
	run_ms(story,owner,10)
	check(story.snapshot().rawText==fixture.groups.canteen_tray_intro.lines[1].text,"second line appears at original 2500ms")
	chapter.dispatch(s,"c3_story_complete",story)
	check(not s.canteenHunt.trayTaskStarted,"genuine early capability rejected")
	story.cancel()
	var reopened: RefCounted=chapter.narrative_session(s)
	check(reopened!=story and reopened.elapsed_ms==0,"cancel/reopen restarts unacknowledged queue")
	chapter.dispatch(s,"c3_story_complete",story)
	check(not s.canteenHunt.trayTaskStarted,"cancelled receipt cannot acknowledge replacement")
	finish(reopened,owner)
	check(s.canteenHunt.trayTaskStarted and chapter.narrative_session(s)==null,"terminal acknowledgement starts task exactly once")
	chapter.dispatch(s,"c3_story_complete",reopened)
	check(chapter.narrative_session(s)==null,"consumed acknowledgement cannot replay queue")
	# Third returned tray includes source's preceding correctReturn + all four lines.
	s.canteenHunt.returnedTrayIds=["tray_blue_01","tray_blue_02"]; s.canteenHunt.carriedTrayIds=["tray_blue_03"]
	chapter.dispatch(s,"c3_target:auntie"); story=chapter.narrative_session(s)
	check(story.lines.size()==5 and story.lines[0].text==fixture.groups.canteen_tray_complete.lines[0].text,"third return preserves formerly missing first reply")
	check(s.wallet.cashCents==200,"source grants wages on delivery, before dialogue")
	finish(story,owner)
	chapter.dispatch(s,"c3_target:auntie"); finish(chapter.narrative_session(s),owner)
	check(s.wallet.cashCents==200,"repeated conversation never duplicates wages")
	# Initial canteen phone page must not reveal the post-escape prompts early.
	s.canteenHunt.entryPaperEscaped=false; s.canteenHunt.trayTaskStarted=false
	check(chapter.view("c3_canteen",s).body.is_empty(),"canteen entry page does not reveal future prompts")
	# Actual replay-validated defense → visual victory → original three lines → exit.
	s=initial(); chapter=Chapter.new(); s.canteenHunt.phase="exit_blocking"
	var request: Dictionary=chapter.dispatch(s,"c3_defense")
	var defense: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/canteen_defense.json"))
	chapter.defense_pending.seed=str(defense.seed); defense.session_id=request.game.session_id
	chapter.dispatch(s,"c3_defense_result",defense); story=chapter.narrative_session(s)
	check(story!=null and s.native.scene=="canteen_interior","defense result does not teleport before conversation")
	if story!=null:
		var reduced_state: Dictionary=s.duplicate(true); reduced_state.native.settings.reduced_motion=true
		var reduced_spec: Dictionary=story.spec.duplicate(true); reduced_spec.delayMs=220; reduced_spec.tailMs=166
		var reduced_story:=Session.new(reduced_state,reduced_spec)
		check(reduced_story.duration_ms==3986 and reduced_story.lines[0].atMs==220,"reduced motion keeps all three full dialogue durations")
		check(story.duration_ms==5095 and story.lines.size()==3,"source victory1020 + dialogue3600 + door475")
		story.attach(s,owner); check(story.blocks_movement(),"source paper victory blocks walking")
		run_ms(story,owner,1020); check(not story.blocks_movement(),"escape dialogue allows ordinary walking")
		run_ms(story,owner,4074); chapter.dispatch(s,"c3_story_complete",story)
		check(s.native.scene=="canteen_interior","exit waits for actual terminal motion")
		run_ms(story,owner,1); chapter.dispatch(s,"c3_story_complete",story)
		check(s.native.scene=="campus_bootstrap" and s.rpgCheckpoint=="campus_canteen_gate","terminal victory exits to source campus checkpoint")
		var bike: Dictionary=chapter.get_definition("campus_bootstrap","bike",s)
		check(bike.x==3220 and bike.y==650 and bike.proximity==170,"bike uses original campus coordinates and radius")
		s.items.greaseTissue=true; s.items.cafeteriaWages=true; s.wallet.cashCents=200; s.native.player={"x":3220,"y":650}
		chapter.dispatch(s,"c3_bike_clean"); chapter.dispatch(s,"c3_bike_pay")
		check(s.canteenHunt.bikePaid and s.wallet.cashCents==0,"post-exit bike remains causally playable")
	# Approach callback is unavailable until the genuine full in-world timeline.
	s=initial("campus_qizhen_loop"); chapter=Chapter.new(); s.qizhenLake.active=true; s.qizhenLake.phase="location_search"
	story=chapter.narrative_session(s)
	check(story.lines.size()==7 and story.duration_ms==20960,"approach includes startup160 + authored20800ms")
	for i in range(story.lines.size()):
		check(story.lines[i].text==fixture.groups.qizhen_approach.lines[i].text and story.lines[i].atMs==fixture.groups.qizhen_approach.lines[i].atMs+160,"approach exact interleaving "+str(i))
	check(chapter.view("c3_location",s).body.is_empty(),"location page does not dump future dialogue")
	var world:=MockWorld.new(); world.scene_id="campus_qizhen_loop"; root.add_child(world)
	var host:=Host.new(); root.add_child(host)
	host.setup(world,func()->Dictionary:return s,func(_delta:float=0)->RefCounted:return chapter.narrative_session(s),func(action:String,value:Variant=null)->void:chapter.dispatch(s,action,value),func(id:String,payload:Dictionary)->void:cues.append({"id":id,"payload":payload}))
	host.set_process(false); host.tick(0)
	check(host.blocks_input() and host.blocks_movement(),"approach host blocks interactions and movement")
	check(world.player==Vector2(7730,840),"actual host places source theater-side start")
	host.tick(100,false)
	check(story.elapsed_ms==0 and cues[-1].id=="native_activity_paused","voice and timeline pause together")
	host.tick(100,true)
	check(cues.any(func(c:Dictionary)->bool:return c.id=="native_activity_resumed"),"voice resumes with owner")
	for _i in range(59): host.tick(100,true)
	check(world.player==Vector2(9040,930) and not s.qizhenLake.locationBriefingSeen,"source walk finishes before all narrative; no early flag")
	var stale: RefCounted=story
	host.reset(); host.tick(0)
	check(host.current!=stale and not s.qizhenLake.locationBriefingSeen,"host cancel/reopen does not skip acknowledgement")
	for _i in range(210): host.tick(100,true)
	check(s.qizhenLake.locationBriefingSeen and s.rpgCheckpoint=="campus_qizhen_transition_stop","host terminal ack records source safe checkpoint")
	check(chapter.narrative_session(s)==null and not host.blocks_input(),"acknowledged approach never replays")
	check(is_equal_approx(world.zoom,1.1),"approach restores camera zoom")
	check(cues.any(func(c:Dictionary)->bool:return c.id=="native_activity_closed"),"completion/cancel stops only owned story voice")
	check(Guard.new().validate(s),"controller-produced acknowledged snapshot remains source-valid")
	host.queue_free(); world.queue_free()
	# Reload before ack invalidates old capabilities and restarts the source start.
	s=initial("campus_qizhen_loop"); chapter=Chapter.new(); s.qizhenLake.active=true; s.qizhenLake.phase="location_search"
	story=chapter.narrative_session(s); story.attach(s,owner); run_ms(story,owner,6000)
	s=s.duplicate(true); reopened=chapter.narrative_session(s)
	check(not story.valid(s) and reopened!=story and reopened.elapsed_ms==0,"reload preserves unseen flag and restarts source approach")
	# Source replays theater greeting only on fresh unmodified lobby entry.
	s=initial("theater_interior"); chapter=Chapter.new(); s.theaterHunt.active=true; s.theaterHunt.phase="entry_ticket"
	story=chapter.narrative_session(s); check(story.sequence_id=="theater_entry" and story.lines[0].atMs==1100,"theater entry is staged after original delay")
	finish(story,owner); check(chapter.narrative_session(s)==null,"entry is once per scene mount")
	s=s.duplicate(true); check(chapter.narrative_session(s)!=null,"fresh unmodified lobby reload replays source greeting")
	chapter=Chapter.new(); s.theaterHunt.posterCleaned=true
	check(chapter.narrative_session(s)==null,"progressed theater lobby never shows introductory future conversation")
	intruder.free(); owner.free()
	await process_frame
	print("Chapter 3 narrative: %d checks, %d failures" % [checks,errors]); quit(0 if errors==0 else 1)
