extends SceneTree
const Director=preload("res://scripts/media/audio_director.gd")
const Chapter=preload("res://scripts/chapters/chapter3.gd")
const Host=preload("res://scripts/ui/minigame_host.gd")
const Defense=preload("res://scripts/games/canteen_defense.gd")
var checks: int=0
var errors: int=0
var state: Dictionary={}
var audio: Node
var controller: RefCounted=Chapter.new()
var events: Array=[]
var plays: Array=[]
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok: errors+=1; push_error(message)
func _initialize() -> void: call_deferred("run")
func drain() -> void: await process_frame; await process_frame
func at(scene: String, id: String) -> void:
	state.native.scene=scene; state.rpgScene=scene; state.runtimeMode="rpg"
	var target: Dictionary=controller.get_definition(scene,id,state)
	var stand: Dictionary=target.get("stand",{"x":target.x,"y":target.y})
	state.native.player={"x":stand.x,"y":stand.y}
func act(id: String,value: Variant=null) -> Dictionary:
	drain_story()
	var previous: Dictionary=state.duplicate(true)
	var result: Dictionary=controller.dispatch(state,id,value)
	audio.update_state(id,previous,state.duplicate(true),result)
	drain_story()
	return result
func drain_story() -> void:
	var story: RefCounted=controller.narrative_session(state)
	if story==null: return
	var witness:=Node.new(); root.add_child(witness)
	if story.attach(state,witness):
		for _i in range(1000):
			for event: Dictionary in story.take_cues(): audio.cue(event.id,event.payload)
			if story.status=="inspecting":
				story.mark_inspector_opened(state,witness); story.mark_inspector_closed(state,witness); controller.dispatch(state,"c3_reversal_inspect_closed",story)
			if story.status!="playing": break
			story.frame(state,100,witness)
			if story.sequence_id=="theater_reversal" and not story.visual_acknowledged and story.elapsed_ms>=float(story.spec.delayMs): controller.dispatch(state,"c3_reversal_visual_complete",story)
			if story.sequence_id=="canteen_promo" and not story.visual_acknowledged and story.elapsed_ms>=float(story.spec.delayMs): controller.dispatch(state,"c3_promo_visual_complete",story)
		var before: Dictionary=state.duplicate(true)
		var result: Dictionary=controller.dispatch(state,"c3_story_complete",story)
		audio.update_state("c3_story_complete",before,state.duplicate(true),result)
	witness.free()
func seen(id: String) -> bool: return events.any(func(e: Dictionary) -> bool: return e.id==id)
func latest(id: String) -> Dictionary:
	for i in range(events.size()-1,-1,-1):
		if events[i].id==id: return events[i].payload
	return {}
func run() -> void:
	state=JSON.parse_string(FileAccess.get_file_as_string("res://data/initial_state.json"))
	state.native={"chapter":3,"page":"c3_canteen","scene":"canteen_interior","mode":"light","player":{},"settings":{"music":true,"effects":true,"volume":1},"log":[],"completed":[]}
	state.runtimeMode="rpg"; state.rpgScene="canteen_interior"; state.canteenHunt.active=true; state.canteenHunt.phase="tray_search"; state.canteenHunt.entryPaperEscaped=true
	audio=Director.new(); root.add_child(audio)
	audio.cue_published.connect(func(id: String,payload: Dictionary) -> void: events.append({"id":id,"payload":payload.duplicate(true)}))
	audio.playback_started.connect(func(channel: String,asset: String) -> void: plays.append([channel,asset]))
	audio.setup(func() -> Dictionary: return state)
	await drain()
	check(seen("canteen_interior_opened") and audio.music.playing,"actual canteen scene entry starts source score")
	state.native.mode="dark"; state.canteenHunt.mode="dark"; await drain()
	check(seen("canteen_dark_mode_enabled"),"mode change outside action_completed is observed")
	state.native.mode="light"; state.canteenHunt.mode="light"; await drain()
	check(seen("canteen_light_mode_enabled"),"light-mode cue is reachable")
	at("canteen_interior","auntie"); act("c3_target:auntie")
	at("canteen_interior","tray_blue_01"); act("c3_target:tray_blue_01")
	check(latest("canteen_tray_slide_started")=={"trayId":"tray_blue_01"},"actual tray pickup emits exact payload")
	await create_timer(.4).timeout
	check(seen("canteen_tray_slide_completed"),"source360ms tray completion sound is reached")
	state.canteenHunt.phase="menu_order"; at("canteen_interior","ordering_kiosk"); act("c3_order","A")
	check(latest("canteen_order_wrong")=={"optionId":"A"},"wrong-order cue comes from accepted controller attempt")
	at("canteen_interior","pickup_window_1"); act("c3_target:pickup_window_1")
	check(latest("canteen_wrong_meal_collected")=={"optionId":"A","itemId":"canteenRealBun","windowId":"1"},"wrong meal exact source payload")
	at("canteen_interior","ordering_kiosk"); act("c3_order","D")
	check(latest("canteen_order_solved")=={"optionId":"D"},"correct order exact payload")
	at("canteen_interior","pickup_window_3"); var defense_request: Dictionary=act("c3_target:pickup_window_3")
	check(defense_request.game.source_pickup_prelude,"actual pickup requests source audio prelude")
	var defense: Control=Defense.new(); root.add_child(defense); defense.set_process(false)
	var beats: Array=[]
	defense.presentation_requested.connect(func(id: String,payload: Dictionary) -> void: beats.append([id,defense._pickup_elapsed]); audio.cue(id,payload))
	defense.setup(defense_request.game)
	defense.begin(); check(not defense.running,"prelude cannot be skipped by start button")
	for i in range(1138): defense._process(.01)
	if not defense.running: defense._process(.01)
	check(defense.running and defense.model.tick==0,"source11380ms prelude precedes physics without granting progress")
	for row in [["canteen_pickup_ticket_handoff",0],["canteen_pickup_cutscene_quiet",850],["canteen_paper_package_wait",4030],["canteen_paper_package_shake",4930],["canteen_paper_burst_started",5980],["canteen_paper_camera_impact",6500]]:
		var matches: Array=beats.filter(func(beat: Array) -> bool: return beat[0]==row[0])
		check(matches.size()==1 and absf(float(matches[0][1])-row[1])<=11,"source cutscene event time "+row[0])
	check(seen("canteen_defense_started"),"actual defense begin reaches source cue")
	defense.queue_free(); await drain()
	state.canteenHunt.phase="chase_ready"; at("campus_bootstrap","bike"); act("c3_bike_inspect")
	check(seen("canteen_bike_glare_failed"),"accepted glare branch emits explicit cue")
	state.items.greaseTissue=true; act("c3_bike_clean"); act("c3_bike_inspect")
	check(seen("canteen_bike_lock_cleaned") and seen("canteen_bike_payment_ready"),"exact bike controller events reached")
	state.theaterHunt.active=true; state.theaterHunt.phase="entry_ticket"; state.theaterHunt.cc98TicketCommissionPhase="accepted"
	state.networkMode="campus_wifi"; act("c3_ticket_claim")
	check(latest("theater_ticket_first_wave_slow")=={"releaseWave":1,"surface":"phone"},"ticket first failure preserves source payload")
	state.networkMode="cellular"; act("c3_ticket_claim")
	check(latest("theater_ticket_second_wave_success")=={"releaseWave":2,"surface":"phone"},"ticket second wave preserves payload")
	at("theater_interior","theater_ticket_kiosk"); act("c3_ticket_code","0832")
	check(latest("theater_ticket_printed")=={"code":"0832"},"actual ticket printing reaches audio")
	state.items.theaterTicketHalfA=true; act("c3_ticket_combine")
	at("theater_interior","theater_ticket_gate"); act("c3_target:theater_ticket_gate")
	for id in ["opening","spotlight","finale"]:
		at("theater_interior","theater_program_"+id); act("c3_target:theater_program_"+id)
	check(seen("theater_ticket_combined") and seen("theater_ticket_admitted") and latest("theater_program_collected")=={"programId":"finale"},"ticket/admission/program native actions all emit")
	at("theater_interior","theater_light_console"); act("c3_program_submit",["opening","spotlight","finale"])
	check(seen("theater_program_order_wrong") and events.any(func(e: Dictionary) -> bool:return e.id=="chapter3_story_line" and e.payload.get("subtitleKey")=="c3_theater_logic_system") and not audio.scheduled.any(func(p:Dictionary)->bool:return str(p.id)=="native_theater_dialogue_wrong_order"),"wrong-order narrative owns exact voiced second line without duplicate auto queue")
	act("c3_program_submit",["spotlight","opening","finale"])
	check(seen("theater_program_order_solved"),"correct program reaches source sound")
	audio.cancel_scheduled("native_theater_dialogue_")
	audio.feedback("  系统：台上的顺序改过，印刷版未必跟得上。  ")
	await drain()
	check(audio.voice_asset=="vo_c3_theater_logic_system","original exact subtitle normalization reaches source voice")
	var count: int=events.size(); audio.feedback("系统：台上的顺序改过，印刷版未必跟得上。猜测")
	check(events.size()==count,"approximate text never becomes source dialogue")
	state.qizhenLake.active=true; state.qizhenLake.phase="location_search"; state.items.wetProgram=true
	act("c3_clue:bridge"); act("c3_clue:reflection")
	check(latest("qizhen_bridge_clue_found")=={"clueId":"bridge"} and latest("qizhen_reflection_clue_found")=={"clueId":"reflection"},"lake source clues route exact audio")
	state.qizhenLake.mapClueIds=["bridge","reflection","lake"]; act("c3_map_confirm")
	check(latest("qizhen_location_solved").clueIds==state.qizhenLake.mapClueIds,"lake solution payload uses actual ordered clues")
	state.qizhenLake.phase="complete"; act("c35_begin")
	check(seen("chapter35_recovery_opened"),"interlude recovery action starts reflection score")
	# Every C4 controller cue is wired to a particular successful native transition.
	var prior: Dictionary=state.duplicate(true); var next: Dictionary=prior.duplicate(true)
	prior.chapter4.phase="maintenance_repair"; prior.chapter4.factIds=["cart_wheel_cover_opened"]
	next=prior.duplicate(true); next.chapter4.factIds.append_array(["cart_wheel_repaired","clock_gear_repaired"])
	audio.update_state("c4_cart_oil",prior,next,{})
	check(latest("maintenance_cart_wheel_repaired").targetId=="a1_cleaning_cart_wheel" and latest("clock_gear_repaired").linkedAction,"C4 repair maps exact source target and linked flag")
	check(latest("maintenance_cart_roll_started")=={"phase":"maintenance_repair","durationMs":900},"C4 cart animation has source duration")
	prior.chapter4.lightGrid={"mask":6,"locked":false}; next=prior.duplicate(true); next.chapter4.lightGrid.mask=9
	audio.update_state("c4_toggle_hall",prior,next,{})
	check(latest("power_zone_toggled")=={"zoneId":"hall","previousMask":6,"mask":9},"C4 light zone uses actual mask transition")
	# Real procedural AudioStreamPlayer output and source-recorded tone envelopes.
	var host: Control=Host.new(); root.add_child(host); host.set_process(false)
	host.presentation_requested.connect(audio.cue)
	host.setup({"type":"chase"}); host.begin(); host.press_action("bell","test")
	await drain()
	check(plays.any(func(p: Array) -> bool:return p[1]=="native_chase_tone:bell"),"real chase bell interaction produces native procedural sound")
	var model_snapshot: Dictionary=host.model.result().duplicate(true)
	host._audio_update()
	check(host.model.result()==model_snapshot,"audio observer never changes physics replay")
	host.model.collisions+=1; host.model.lives-=1; host._audio_update()
	check(latest("canteen_chase_collision").collisions==1,"chase actual collision counter maps source domain event")
	host.queue_free(); await drain()
	host=Host.new(); root.add_child(host); host.set_process(false); host.presentation_requested.connect(audio.cue)
	host.setup({"type":"rhythm","spotId":"locker_key","chartId":"locker_key","session_id":77}); host.begin()
	check(latest("qizhen_fishing_started").sessionId=="77" and latest("qizhen_fishing_started").totalNotes==host.model.notes.size(),"fishing start identifies real native session and chart")
	host.model.phase="running"; host.model.stage="count_in"; host.model.cast_at=0; host.model.elapsed=0; host._audio_update()
	await drain()
	check(plays.any(func(p: Array) -> bool:return str(p[1]).begins_with("native_fishing_beat:")),"actual rhythm metronome emits native audio")
	host.model.notes[0].judgment="perfect"; host.model.tension=85; host._audio_update()
	check(latest("qizhen_fishing_warning").kind=="tension_high","source warning follows real note judgment")
	host.cancel_game(); await create_timer(.1).timeout
	check(seen("qizhen_fishing_cancelled") and audio.music_asset=="music_qizhen_lakeside","fishing cancel restores source lakeside score")
	host.queue_free(); await drain()
	host=Host.new(); root.add_child(host); host.set_process(false); host.presentation_requested.connect(audio.cue)
	host.setup({"type":"kayak","phase":"chase","session_id":78,"audio_chase_attempt":1}); host.begin()
	host.model.pressure="charge_warning"; host._audio_update(); host.model.pressure="charge"; host._audio_update(); host.model.segment="final_bank"; host._audio_update()
	check(seen("rpg_qizhen_chase_started") and seen("qizhen_swan_chase_telegraph") and seen("qizhen_swan_chase_telegraph_voice") and seen("qizhen_swan_chase_surge") and seen("qizhen_swan_chase_final_bank"),"swan pressure model transitions drive active source cues")
	host.queue_free(); await drain()
	check(await audio.shutdown(),"playback references retired before process exit")
	audio.queue_free(); await drain()
	print("GAMEPLAY_AUDIO_WIRING checks=",checks," errors=",errors)
	quit(1 if errors else 0)
