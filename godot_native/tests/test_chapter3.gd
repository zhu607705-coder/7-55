extends SceneTree
const Chapter = preload("res://scripts/chapters/chapter3.gd")
const MediaHost = preload("res://scripts/media/c3_media_host.gd")
const Spotlight = preload("res://scripts/games/c3_spotlight_model.gd")
var controller: RefCounted=Chapter.new()
var checks: int=0
var errors: int=0
func check(value: bool, label: String) -> void:
	checks+=1
	if not value:
		errors+=1
		push_error(label)
func initial() -> Dictionary:
	var s: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/initial_state.json"))
	s.native={"chapter":3,"page":"c3_canteen","scene":"canteen_interior","mode":"light","player":{},"selected_item":"","log":[],"completed":[]}
	s.canteenHunt.active=true
	s.canteenHunt.phase="tray_search"
	s.canteenHunt.entryPaperEscaped=true # Later mechanics fixture starts after the separately tested entry scene.
	return s
func act(s: Dictionary, action: String, value: Variant=null) -> Dictionary:
	drain_story(s)
	var result: Dictionary=controller.dispatch(s,action,value)
	drain_story(s)
	return result
func drain_story(s: Dictionary) -> void:
	var session: RefCounted=controller.narrative_session(s)
	if session==null: return
	var host:=Node.new()
	root.add_child(host)
	if session.attach(s,host):
		for _frame in range(1000):
			if session.status=="inspecting":
				session.mark_inspector_opened(s,host); session.mark_inspector_closed(s,host); controller.dispatch(s,"c3_reversal_inspect_closed",session)
			if session.status!="playing": break
			session.frame(s,100,host)
			if session.sequence_id=="theater_reversal" and not session.visual_acknowledged and session.elapsed_ms>=float(session.spec.delayMs): controller.dispatch(s,"c3_reversal_visual_complete",session)
			if session.sequence_id=="canteen_promo" and not session.visual_acknowledged and session.elapsed_ms>=float(session.spec.delayMs): controller.dispatch(s,"c3_promo_visual_complete",session)
		controller.dispatch(s,"c3_story_complete",session)
	host.free()
func at(s: Dictionary, scene: String, id: String) -> void:
	s.native.scene=scene
	s.rpgScene=scene
	var entry: Dictionary=controller.get_definition(scene,id,s)
	var p: Dictionary=entry.get("stand",{"x":entry.x,"y":entry.y})
	s.native.player={"x":p.x,"y":p.y}
func interact(s: Dictionary, id: String) -> Dictionary:
	at(s,str(s.native.scene),id)
	return act(s,"c3_target:"+id)
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var s: Dictionary=initial()
	# Rejected remote physical operations cannot mint items.
	s.native.player={"x":10,"y":10}
	act(s,"c3_target:auntie")
	check(not s.canteenHunt.trayTaskStarted,"distant interaction rejected")
	interact(s,"auntie")
	check(s.canteenHunt.trayTaskStarted,"tray task starts at auntie")
	for tray: String in Chapter.TRAYS:
		interact(s,tray)
		interact(s,"auntie")
	check(s.items.cafeteriaWages and s.items.greaseTissue and s.wallet.cashCents==200,"three trays reward exactly two yuan without dark prerequisite")
	interact(s,"auntie")
	check(s.wallet.cashCents==200,"tray reward is idempotent")
	for entry: Dictionary in controller.world("canteen_interior").constants.CANTEEN_DRINK_MACHINES:
		interact(s,entry.id)
		act(s,"c3_drink_take:"+str(entry.id))
	at(s,"canteen_interior","canteen-mixer")
	for ingredient: String in Chapter.RECIPE: act(s,"c3_mix:"+ingredient)
	check(s.items.dailySpecialSparklingWater,"source drink recipe produces promotion drink")
	interact(s,"canteen-promo-board")
	check(s.canteenHunt.phase=="menu_order","promotion opens queue")
	at(s,"canteen_interior","ordering_kiosk")
	act(s,"c3_order","A")
	interact(s,"pickup_window_1")
	check(s.items.canteenRealBun and s.canteenHunt.phase=="menu_order","decoy meal can be collected and reordered")
	at(s,"canteen_interior","ordering_kiosk")
	act(s,"c3_order","D")
	interact(s,"pickup_window_3")
	check(s.canteenHunt.phase=="exit_blocking","ticket and meal match required")
	interact(s,"cart_west")
	check(s.canteenHunt.blockHits==0,"wrong cart does not advance")
	var defense_request: Dictionary=act(s,"c3_defense")
	check(defense_request.has("game"),"active runtime uses real sixty-second pushcart defense")
	var defense: Dictionary=fixture("canteen_defense")
	# Runtime seed is a deterministic scenario input, never a terminal fact.
	controller.defense_pending.seed=str(defense.seed)
	defense.session_id=defense_request.game.session_id
	act(s,"c3_defense_result",defense)
	check(s.canteenHunt.phase=="chase_ready" and not s.canteenHunt.menuDarkClueRead,"sixty-second defense replay completes independently of dark clues")
	at(s,"campus_bootstrap","bike")
	act(s,"c3_bike_clean")
	act(s,"c3_bike_pay")
	check(s.wallet.cashCents==0 and s.canteenHunt.bikePaid and s.items.greaseTissue,"bike pay consumes wage; tissue retained")
	act(s,"c3_chase")
	act(s,"c3_chase_departed")
	act(s,"c3_chase_result",{"mode":"story","distance":755,"lives":3,"collisions":0})
	check(not s.canteenHunt.chaseCompleted,"forged chase terminal rejected without replay")
	var chase: Dictionary=fixture("chase")
	act(s,"c3_chase_result",chase)
	check(s.canteenHunt.chaseCompleted and s.canteenHunt.phase=="theater_reached","755m exact input replay advances to theater")
	s.native.player={"x":3300,"y":1445}
	act(s,"c3_enter_theater")
	act(s,"c3_ticket_accept")
	act(s,"c3_ticket_claim")
	check(s.theaterHunt.cc98TicketCommissionPhase=="first_wave_failed","wifi ticket first wave fails")
	act(s,"c3_network","cellular")
	act(s,"c3_ticket_claim")
	check(s.theaterHunt.cc98TicketClaimedWave==2,"cellular second wave produces receipt")
	interact(s,"theater_poster")
	at(s,"theater_interior","theater_ticket_kiosk")
	act(s,"c3_ticket_code","0832")
	act(s,"c3_ticket_combine")
	interact(s,"theater_ticket_gate")
	for id: String in ["opening","spotlight","finale"]: interact(s,"theater_program_"+id)
	at(s,"theater_interior","theater_light_console")
	act(s,"c3_program_submit",["opening","spotlight","finale"])
	check(s.theaterHunt.phase=="program_search","wrong program order rejected")
	act(s,"c3_program_submit",Chapter.PROGRAM_ORDER)
	check(s.items.spotlightRemote,"source order grants remote")
	interact(s,"theater_prop_scanner")
	interact(s,"theater_backstage_vent")
	check(s.theaterHunt.paperDusted and not s.items.temporaryTheaterTicket and not s.items.fluorescentBrush,"ticket/brush transforms retain causal chain")
	interact(s,"theater_light_console")
	act(s,"c3_spotlight_result",{"round":0,"status":"won"})
	check(s.theaterHunt.spotlightRound==0,"forged spotlight terminal rejected")
	var rules: RefCounted=Spotlight.new()
	var show: Dictionary=rules.create(0,0)
	var trace: Array=[]
	for i: int in range(1600):
		if show.status!="running": break
		var input: Dictionary={"x":0.0,"y":0.0,"dash":false}
		trace.append(input)
		show=rules.step(show,input)
	var terminal: Dictionary=rules.validate({"version":2,"round":0,"attempt":0,"inputs":trace},0,0)
	check(terminal.get("status")=="lost","spotlight exact replay validates timeout")
	act(s,"c3_spotlight_result",{"version":2,"round":0,"attempt":0,"inputs":trace})
	check(s.theaterHunt.spotlightMistakes==1 and s.theaterHunt.spotlightRound==0,"loss persists attempts without granting round")
	for round_id: int in range(3):
		var proof: Dictionary=solve_spotlight(round_id,int(s.theaterHunt.spotlightMistakes))
		act(s,"c3_spotlight_result",proof)
	check(s.theaterHunt.phase=="reversal" and s.theaterHunt.spotlightRound==3,"all three spotlight acts validated from physical movement traces")
	await test_lake(s)
	await test_interlude(s)
	print("Chapter 3 checks: ",checks,"; failures: ",errors)
	quit(0 if errors==0 else 1)
func fixture(name: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/"+name+".json"))
func solve_spotlight(round_id: int,attempt: int) -> Dictionary:
	var rules:RefCounted=Spotlight.new()
	var cases:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/spotlight_balance_samples.json"))
	for route:Dictionary in cases.cases:
		if int(route.proof.round)==round_id and int(route.proof.attempt)==attempt:
			var result:Dictionary=rules.validate(route.proof,round_id,attempt)
			check(result.get("status","")=="won","shared source physical trace completes spotlight act "+str(round_id))
			return route.proof
	check(false,"missing authored QA trace for requested attempt")
	return {}

func lake_at(s: Dictionary,id: String) -> Dictionary:
	for entry: Dictionary in controller.lake.definitions():
		if entry.id!=id: continue
		s.native.scene="qizhen_lake"
		var p: Dictionary=entry.get("stand",{"x":entry.x,"y":entry.y})
		s.native.player={"x":p.x,"y":p.y}
		return act(s,"c3_lake_target:"+id)
	return {}
func finish_kayak(s: Dictionary, request: Dictionary) -> void:
	check(not request.has("game"),"lake traversal uses original world, without bounded substitute")
	if s.qizhenLake.phase not in ["boarding_tutorial","swan_chase"]: return
	var runtime_state: Node=root.get_node("State")
	runtime_state.d=s
	var world_script: Script=load("res://scripts/world.gd")
	var host: Control=world_script.new()
	host.size=Vector2(960,540)
	root.add_child(host); host.set_process(false)
	controller.lake.bind_world(s,host)
	if s.qizhenLake.phase=="boarding_tutorial":
		for side: String in ["left","right","left","right"]: controller.lake.world_stroke(s,host,side)
	else:
		for frame: int in range(900):
			if frame%8==0: controller.lake.world_stroke(s,host,"left" if (frame/8)%2==0 else "right")
			if controller.lake.live_session.status!="recovering":
				var previous: Vector2=host.player
				host.kayak.update(1.0/60)
				if host.can_stand(host.kayak.position): host.player=host.kayak.position
				else: host.kayak.position=previous; host.kayak.speed=0
				host._sync_player()
			controller.lake.world_tick(s,host,1.0/60)
			if s.qizhenLake.phase=="complete": break
	host.free()
func finish_fishing(s: Dictionary, request: Dictionary) -> void:
	check(request.has("game"),"valid cast creates rhythm request")
	if not request.has("game"): return
	var proof: Dictionary=fixture("rhythm_"+str(request.game.spotId))
	proof.session_id=request.game.session_id
	act(s,"c3_fishing_result",proof)
func test_lake(s: Dictionary) -> void:
	act(s,"c3_reversal")
	for id: String in ["bridge","reflection","lake"]:
		act(s,"c3_clue:"+id)
		act(s,"c3_map:"+id)
	act(s,"c3_map_confirm")
	check(s.qizhenLake.phase=="lake_unlocked" and not s.items.wetProgram,"three independent source records gate lake")
	act(s,"c3_lake_enter")
	for id: String in ["qizhen_dock_kayak","qizhen_dock_left_paddle","qizhen_dock_right_paddle"]: lake_at(s,id)
	check(s.qizhenLake.phase=="boarding_tutorial","three outfit branches form boat")
	lake_at(s,"qizhen_dock_safety_officer")
	s.native.settings={"reduced_motion":true}
	await finish_rain(s,lake_at(s,"qizhen_dock_board"))
	check(s.qizhenLake.phase=="rain_recovery" and s.native.scene=="dorm_hub","rain launch physically simulates and forces source rescue")
	s.native.player={"x":700,"y":430}
	act(s,"c3_lake_target:hair_dryer")
	# The original controller requires the actual Weather app, including in
	# split RPG mode; device acquisition alone is not an app-entry authority.
	s.currentScene="weather"; s.native.page="weather"
	act(s,"c3_weather_start")
	act(s,"c3_weather_result",{"moves":3,"cloudOffsets":[34,52,70],"controlledBands":[true,true,true],"stableMs":999,"elapsedMs":3000})
	check(not s.qizhenLake.rainSafetyCleared and s.items.hairDryer,"weather stability floor enforced")
	act(s,"c3_weather_result",{"moves":3,"cloudOffsets":[34,52,70],"controlledBands":[true,true,true],"stableMs":1000,"elapsedMs":3000})
	check(s.qizhenLake.rainSafetyCleared and not s.items.hairDryer,"valid weather summary clears rain safety")
	act(s,"c3_lake_enter")
	finish_kayak(s,lake_at(s,"qizhen_dock_board"))
	check(s.qizhenLake.zone=="open_water" and s.qizhenLake.boardingTutorialCompleted,"four alternating physical strokes unlock lake")
	lake_at(s,"qizhen_fishing_rod")
	act(s,"c3_bait")
	check(s.qizhenLake.decoyBaitAttached and not s.items.decoyPaper,"decoy bait consumed once")
	check(controller.lake.precheck_cast(s,"locker_key"),"unobserved valid light cast allowed")
	s.native.mode="dark"
	check(not controller.lake.precheck_cast(s,"locker_key"),"dark mode cannot catch")
	s.native.mode="light"
	var request: Dictionary=lake_at(s,"qizhen_fishing_item_1")
	var session: int=request.game.session_id
	act(s,"c3_fishing_result",{"spotId":"locker_key","session_id":session,"success":true,"notes_hit":8,"total_notes":8})
	check(not s.items.rustedLockerKey and s.items.fishingRod,"forged rhythm terminal cannot mint key or consume rod")
	check(controller.lake.fishing_session.is_empty(),"failed rhythm session resolves once")
	finish_fishing(s,lake_at(s,"qizhen_fishing_item_1"))
	check(s.items.rustedLockerKey,"exact rhythm trace catches locker key")
	finish_kayak(s,lake_at(s,"qizhen_open_to_dock"))
	lake_at(s,"qizhen_use_item_1")
	check(s.items.nylonCord and not s.items.rustedLockerKey,"key opens dock locker")
	lake_at(s,"qizhen_dock_board")
	finish_kayak(s,lake_at(s,"qizhen_dock_to_open"))
	finish_kayak(s,lake_at(s,"qizhen_open_to_channel"))
	finish_fishing(s,lake_at(s,"qizhen_fishing_item_3"))
	check(s.items.nylonCord and s.items.brokenNetFrame,"locker and raft branches retain independent final materials")
	act(s,"c3_net_combine")
	check(not s.items.improvisedDipNet and s.items.nylonCord and s.items.brokenNetFrame,"obsolete pairwise net assembly cannot consume final materials")
	finish_kayak(s,lake_at(s,"qizhen_channel_to_open"))
	finish_kayak(s,lake_at(s,"qizhen_open_to_swan"))
	lake_at(s,"qizhen_black_swan")
	check(s.items.swanMagnet and s.items.fishingRod and not s.items.magneticFishingRod and not s.qizhenLake.netCombined,"independent swan branch grants only magnet and preserves plain rod")
	check(s.qizhenLake.phase=="tool_chain" and s.qizhenLake.swanFed,"swan branch remains open for final assembly")
	finish_kayak(s,lake_at(s,"qizhen_swan_to_open"))
	lake_at(s,"qizhen_open_workbench")
	check(s.items.magneticFishingRod and s.qizhenLake.magneticRodCombined and not s.items.nylonCord and not s.items.brokenNetFrame and not s.items.swanMagnet and not s.items.fishingRod,"source workbench atomically consumes all four materials")
	finish_kayak(s,lake_at(s,"qizhen_open_to_swan"))
	finish_fishing(s,lake_at(s,"qizhen_final_paper_cast"))
	check(s.qizhenLake.phase=="swan_chase","fourth exact catch releases swan into channel")
	finish_kayak(s,act(s,"c3_swan_chase"))
	check(s.qizhenLake.phase=="complete" and s.qizhenLake.magneticAttachmentBroken and not s.items.magneticFishingRod,"real source-channel x190 crossing completes escape")
func test_interlude(s: Dictionary) -> void:
	s.qizhenLake.phase="complete"
	var c: Dictionary=s.chapterThreeInterlude
	c.phase="reboot"
	act(s,"c35_voice",["lake","stone","lobby","broadcast"])
	check(not c.voiceSequenceSolved,"interlude cannot start before recovery+closeout")
	act(s,"c35_begin")
	act(s,"c35_journal","safe_return")
	act(s,"c35_photos",["paper_left","mirrored_a","paper_right"])
	check(not c.photoSequenceSolved,"mirrored photo rejected")
	act(s,"c35_photos",["paper_left","paper_middle","paper_right"])
	act(s,"c35_voice",["lake","stone","lobby","broadcast"])
	check(not c.voiceSequenceSolved,"correct order alone cannot bypass audition")
	s.native.page="c35_voice"
	var media: Node=MediaHost.new()
	root.add_child(media)
	media.setup(func() -> Dictionary: return s)
	media.event.connect(func(id: String,value: Variant) -> void: act(s,id,value))
	for clip: String in ["lake","stone","lobby","broadcast"]:
		media.apply(act(s,"c35_listen",clip).media)
		# AudioServer uses its own playback clock. A SceneTreeTimer can expire
		# before that clock reaches the source 80% threshold under load.
		var deadline: int=Time.get_ticks_msec()+int(media.current.duration_ms)+5000
		while not controller.interlude.voice_reviewed(s,clip) and Time.get_ticks_msec()<deadline:
			await process_frame
		check(controller.interlude.voice_reviewed(s,clip) and not media.current.fallback,"actual audition completed "+clip+" "+str(media.current.snapshot())+" verified="+str(media.current.verified_ms))
	act(s,"c35_voice",["lake","stone","lobby","broadcast"])
	if not await media.shutdown():
		errors+=1
	media.queue_free()
	await process_frame
	await process_frame
	act(s,"c35_route",["guard_east","west_cleaner"])
	check(not c.routeScreenshotSaved,"route requires actual closure source")
	act(s,"c35_route",["east_closed","west_cleaner"])
	act(s,"c35_official")
	act(s,"c35_network","record_library_south")
	check(c.evidenceIds.size()==4,"four-source collection with provisional network candidate")
	act(s,"c35_destination","duan_yongping_a1")
	check(c.destinationId==null,"destination waits for decoy rejections")
	for id: String in controller.interlude.REASONS: act(s,"c35_reject:"+id,controller.interlude.REASONS[id])
	act(s,"c35_destination","duan_yongping_a1")
	check(c.destinationId==null,"wrong network record conflicts with destination")
	act(s,"c35_network","record_0755")
	act(s,"c35_destination","duan_yongping_a1")
	act(s,"c35_replay")
	check(c.phase=="replay_ready" and c.replayUnlocked and not c.completed,"verified recovery unlocks fourth chapter without completing it")

func finish_rain(s: Dictionary, request: Dictionary) -> void:
	check(request.has("world_effect"),"rain uses a controller-issued source presentation capability")
	if not request.has("world_effect"): return
	var session: RefCounted=request.world_effect.session
	var presenter:=Node.new(); root.add_child(presenter)
	check(session.begin(presenter),"rain presenter registers once")
	var deadline: int=Time.get_ticks_msec()+3500
	while Time.get_ticks_msec()<deadline and session.phase()!="complete":
		session.sample(presenter)
		if session.phase()=="cinematic": session.finish_cinematic(presenter,"fallback","reduced_motion")
		await create_timer(.025).timeout
	act(s,"c3_rain_rescue_result",session)
	presenter.queue_free()
