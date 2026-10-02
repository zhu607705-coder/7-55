extends RefCounted
## Semantic campaign continuation. Stand-point placement is explicitly reported;
## actual minigame physics and source issued capabilities produce all outcomes.
const Chase=preload("res://scripts/games/chase_stunt_model.gd")
const Spotlight=preload("res://scripts/games/c3_spotlight_model.gd")
const DefenseSolver=preload("res://tests/campaign_defense_solver.gd")
const FishSolver=preload("res://tests/campaign_fishing_solver.gd")
const CompactUI=preload("res://tests/campaign_compact_ui.gd")
var r: SceneTree
var c: RefCounted
var lake_world: Control

func run(runner: SceneTree) -> void:
	r=runner; c=r.chapter3
	var gate: Dictionary=c.world("campus_bootstrap").manifest.canteen.gate
	place("campus_bootstrap",Vector2(gate.x,gate.y))
	await r.step("c3_enter_canteen")
	var opening: RefCounted=r.state.get_scene_session()
	if not r.check(opening!=null and opening.kind=="canteen" and opening.attach(r.state.d,r.witness),"source canteen paper entry issued"): return
	place("canteen_interior",Vector2(1053,540))
	r.check(opening.post_collision(r.state.d,Vector2(1053,540),r.witness),"source paper proximity trigger")
	for frame in range(300):
		if opening.status=="complete": break
		opening.frame(r.state.d,100,r.witness)
	await r.step("c3_entry_paper_complete",opening)
	if not r.check(r.state.d.canteenHunt.entryPaperEscaped,"full paper escape finished"): return
	await interact("auntie")
	for id in c.TRAYS:
		await interact(id)
		await interact("auntie")
	if not r.check(r.state.d.wallet.cashCents==200 and r.state.d.items.greaseTissue,"fresh three trays earned wages"): return
	for entry in c.world("canteen_interior").constants.CANTEEN_DRINK_MACHINES: await interact(entry.id)
	at("canteen-mixer")
	for id in c.RECIPE: await r.step("c3_mix:"+id)
	await interact("canteen-promo-board")
	at("ordering_kiosk")
	await r.step("c3_order","D")
	await interact("pickup_window_3")
	var request: Dictionary=await r.step("c3_defense")
	if not r.check(request.has("game"),"fresh defense request issued"): return
	var defense: RefCounted=DefenseSolver.new().solve(str(request.game.seed),null,false)
	if not r.check(defense.status=="won","real 60-second model inputs win defense"): return
	var proof: Dictionary=defense.result(); proof.session_id=request.game.session_id
	await r.step("c3_defense_result",proof)
	r.check(r.state.d.native.scene=="campus_bootstrap","source escape dialogue and door return to campus")
	at("bike")
	await r.step("c3_bike_clean")
	await r.step("c3_bike_pay")
	request=await r.step("c3_chase")
	if not r.check(request.has("game"),"paid bike launches actual chase"): return
	var chase: RefCounted=Chase.new()
	chase.press("left")
	while chase.lane>0.5 and chase.status=="running": chase.step()
	chase.neutral()
	while chase.status=="running": chase.step()
	r.check(chase.status=="won" and Chase.validate_result(chase.result()),"model-produced 755m proof")
	await r.step("c3_chase_result",chase.result())
	await r.boundary("canteen chase")
	gate=c.world("campus_bootstrap").manifest.theater.gate
	place("campus_bootstrap",Vector2(gate.x,gate.y))
	await r.step("c3_enter_theater")
	await r.step("c3_ticket_accept")
	await r.step("c3_ticket_claim")
	await r.step("c3_network","cellular")
	await r.step("c3_ticket_claim")
	await interact("theater_poster")
	at("theater_ticket_kiosk")
	await r.step("c3_ticket_code","0832")
	await r.step("c3_ticket_combine")
	await interact("theater_ticket_gate")
	for id in ["opening","spotlight","finale"]: await interact("theater_program_"+id)
	at("theater_light_console")
	await r.step("c3_program_submit",c.PROGRAM_ORDER)
	await interact("theater_prop_scanner")
	await interact("theater_backstage_vent")
	await interact("theater_light_console")
	for round_id in range(3):
		await r.step("c3_spotlight_result",solve_spotlight(round_id,int(r.state.d.theaterHunt.spotlightMistakes)))
		await r.step("c3_spotlight_continue",{"continue":true})
	if not r.check(r.state.d.theaterHunt.phase=="complete","three physical spotlight acts and real continuation"): return
	await r.boundary("theater")
	await lake()
	if r.failures==0: await interlude()
	if is_instance_valid(lake_world): lake_world.queue_free()

func place(scene: String,point: Vector2) -> void:
	if not r.check(r.state.d.native.scene==scene,"spatial setup stays in unlocked scene "+scene): return
	r.trace.append({"spatialSetup":{"scene":scene,"point":[point.x,point.y]},"notPhysicalNavigation":true})
	r.state.d.native.player={"x":point.x,"y":point.y,"scene":scene}

func at(id: String) -> void:
	var scene: String=r.state.d.native.scene
	var definition: Dictionary=c.get_definition(scene,id,r.state.d)
	if not r.check(not definition.is_empty(),"authored interaction target "+id): return
	var point: Dictionary=definition.get("stand",{"x":definition.x,"y":definition.y})
	place(scene,Vector2(point.x,point.y))

func interact(id: String) -> Dictionary:
	at(id)
	return await r.step("c3_target:"+id)

func solve_spotlight(round_id: int,attempt: int) -> Dictionary:
	var rules: RefCounted=Spotlight.new()
	var model: Dictionary=rules.create(round_id,attempt)
	var inputs: Array=[]
	for frame in range(10000):
		if model.status!="running": break
		var aim: Vector2=rules.mouth(model)
		var nearest: float=INF
		for index in range(int(Spotlight.ACTS[round_id].count)):
			if not model.collected.has(index) and model.head.distance_to(Spotlight.FOOD[index])<nearest:
				nearest=model.head.distance_to(Spotlight.FOOD[index]); aim=Spotlight.FOOD[index]
		var direction: Vector2=(aim-model.head).normalized()
		var dash:=false
		for hazard in rules.hazards(model):
			if model.head.distance_to(hazard.position)<100 and model.invulnerable==0:
				if model.dashCooldown<=1: dash=true
				elif model.dashTicks==0 and model.head.distance_to(hazard.position)<65: direction=(direction+(model.head-hazard.position).normalized()*1.6).normalized()
		var input: Dictionary={"x":direction.x,"y":direction.y,"dash":dash}
		inputs.append(input); model=rules.step(model,input)
	r.check(model.status=="won","physical spotlight solver act"+str(round_id+1))
	return {"version":2,"round":round_id,"attempt":attempt,"inputs":inputs}

func lake() -> void:
	await interact("theater_exit")
	if not r.check(r.state.d.native.scene=="campus_qizhen_loop" and r.state.d.qizhenLake.locationBriefingSeen,"theater exit plays actual lake approach narrative"): return
	if not await lake_location_apps(): return
	if not r.check(r.state.d.qizhenLake.phase=="dock_outfitting","three independent source clues unlock lake"): return
	if r.state.d.qizhenLake.mode!="light": r.state.toggle_mode()
	lake_world=load("res://scripts/world.gd").new()
	lake_world.size=Vector2(960,540)
	r.root.add_child(lake_world)
	lake_world.set_process(false)
	for id in ["qizhen_dock_kayak","qizhen_dock_left_paddle","qizhen_dock_right_paddle","qizhen_dock_safety_officer"]: await lake_interact(id)
	var request: Dictionary=await lake_interact("qizhen_dock_board")
	if not r.check(request.has("world_effect"),"rainy boarding issues source rescue presenter"): return
	await rescue(request.world_effect)
	if not r.check(r.state.d.qizhenLake.rainRescueCompleted and r.state.d.native.scene=="dorm_hub","actual rescue clock and dock hold return to dorm"): return
	place("dorm_hub",Vector2(700,430))
	await r.step("c3_lake_target:hair_dryer")
	if not await lake_weather_app(): return
	lake_world.refresh_world()
	await lake_interact("qizhen_dock_board")
	if not r.check(lake_world.kayak!=null and lake_world.lake_session!=null,"actual lake world owns issued kayak session"): return
	for key in [KEY_A,KEY_D,KEY_A,KEY_D]:
		lake_key(key)
		lake_world.refresh_world()
	if not r.check(r.state.d.qizhenLake.boardingTutorialCompleted and r.state.d.qizhenLake.zone=="open_water","real A/D inputs satisfy four alternating tutorial strokes"): return
	await lake_interact("qizhen_fishing_rod")
	await r.step("c3_bait")
	await fish("qizhen_fishing_item_1","locker_key")
	await lake_interact("qizhen_open_to_dock")
	await lake_interact("qizhen_use_item_1")
	await lake_interact("qizhen_dock_board")
	await lake_interact("qizhen_dock_to_open")
	await lake_interact("qizhen_open_to_channel")
	await fish("qizhen_fishing_item_3","net_frame")
	await lake_interact("qizhen_channel_to_open")
	await lake_interact("qizhen_open_to_swan")
	# The current active source uses this independent swan branch. The legacy
	# fish-feed/net chain is intentionally not manufactured into the fresh route.
	await lake_interact("qizhen_black_swan")
	if not r.check(r.state.d.items.swanMagnet and r.state.d.qizhenLake.swanFed,"source independent swan branch grants magnet"): return
	await lake_interact("qizhen_swan_to_open")
	await lake_interact("qizhen_open_workbench")
	if not r.check(r.state.d.items.magneticFishingRod and r.state.d.qizhenLake.magneticRodCombined,"four source components assemble magnetic rod"): return
	await lake_interact("qizhen_open_to_swan")
	await fish("qizhen_final_paper_cast","paper")
	lake_world.refresh_world()
	if not r.check(r.state.d.qizhenLake.phase=="swan_chase" and lake_world.player.distance_to(Vector2(1280,680))<.01,"actual fishing completion enters authored chase spawn"): return
	var start: Vector2=lake_world.player
	for frame in range(1200):
		if r.state.d.qizhenLake.phase=="complete": break
		if frame%8==0: lake_key(KEY_A if (frame/8)%2==0 else KEY_D)
		lake_world._process(1.0/60)
	r.trace.append({"nativeLakeEscape":{"start":[start.x,start.y],"actualEnd":[lake_world.player.x,lake_world.player.y],"phase":r.state.d.qizhenLake.phase,"distance":r.state.d.qizhenLake.chaseDistance,"attempts":r.state.d.qizhenLake.chaseAttempts},"input":"world.gd A/D and collision-backed process ticks","notManualNavigation":true})
	if not r.check(r.state.d.qizhenLake.phase=="complete" and r.state.d.chapterThreeInterlude.phase=="reboot" and not r.state.d.items.magneticFishingRod,"live world escape consumes issued session and opens interlude"): return
	lake_world.free(); lake_world=null
	await r.boundary("lake escape")

func interlude() -> void:
	await r.step("c35_begin")
	await r.step("c35_journal","safe_return")
	for id in ["paper_left","paper_middle","paper_right"]:
		await r.step("c35_frame",id)
		await r.step("c35_select_photo",id)
	await r.step("c35_photos",r.state.d.native.c35_photo_selection.duplicate())
	var host: Node=load("res://scripts/media/c3_media_host.gd").new()
	r.root.add_child(host)
	host.setup(func(): return r.state.d)
	host.event.connect(func(id,value): r.state.act(id,value))
	r.state.open_page("c35_voice")
	for id in ["lake","stone","lobby","broadcast"]:
		var request: Dictionary=await r.step("c35_listen",id)
		if not r.check(request.has("media"),"source voice session issued " + id): break
		host.apply(request.media)
		var deadline: int=Time.get_ticks_msec()+int(request.media.session.duration_ms)+2500
		while not c.interlude.voice_reviewed(r.state.d,id) and Time.get_ticks_msec()<deadline:
			await r.create_timer(.025).timeout
		r.trace.append({"nativeVoice":id,"session":request.media.session.snapshot(),"verifiedMs":request.media.session.verified_ms})
		if not r.check(r.state.d.native.get("c35_listened",[]).has(id) and not request.media.session.fallback,"actual voice playback crosses authored80-percent threshold " + id): break
		await r.step("c35_select_voice",id)
	r.check(await host.shutdown(),"C35 actual audio playbacks retire")
	host.free()
	if r.failures>0: return
	await r.step("c35_voice_stage","ordering")
	await r.step("c35_voice",r.state.d.native.c35_voice_selection.duplicate())
	await r.step("c35_official")
	for id in ["east_closed","west_cleaner"]: await r.step("c35_select_route",id)
	await r.step("c35_route",r.state.d.native.c35_route_selection.duplicate())
	for pair in [["time","missing_475"],["session","unknown_short"],["area","north_a"]]: await r.step("c35_filter",{"key":pair[0],"value":pair[1]})
	await r.step("c35_network","record_0755")
	if not r.check(r.state.d.chapterThreeInterlude.evidenceIds.size()==4,"four independent interlude evidence categories recovered"): return
	for id in c.interlude.REASONS: await r.step("c35_reject:"+id,c.interlude.REASONS[id])
	await r.step("c35_destination","duan_yongping_a1")
	await r.step("c35_replay")
	if r.check(r.state.d.chapterThreeInterlude.phase=="replay_ready" and r.state.d.chapterThreeInterlude.replayUnlocked,"actual evidence and exclusion chain unlocks recovered replay"):
		r.completed_chapters.append(3)
		await r.boundary("chapter3 interlude")

func lake_interact(id: String) -> Dictionary:
	lake_world.refresh_world()
	var definition: Dictionary={}
	for entry in c.lake.definitions():
		if entry.id==id: definition=entry; break
	if not r.check(not definition.is_empty() and definition.zone==r.state.d.qizhenLake.zone,"authored lake target in current zone " + id): return {}
	var stand: Dictionary=definition.get("stand",{"x":definition.x,"y":definition.y})
	var point: Vector2=Vector2(stand.x,stand.y)
	if not lake_world.can_stand(point):
		var found:=false
		for distance in range(20,241,20):
			for direction in range(16):
				var candidate: Vector2=point+Vector2.from_angle(direction*TAU/16)*distance
				if lake_world.can_stand(candidate): point=candidate; found=true; break
			if found: break
	if not r.check(lake_world.can_stand(point),"spatial setup uses clear source-map geometry " + id): return {}
	r.trace.append({"spatialSetup":{"scene":"qizhen_lake","zone":r.state.d.qizhenLake.zone,"target":id,"point":[point.x,point.y]},"notPhysicalNavigation":true})
	lake_world.player=point
	if lake_world.kayak!=null: lake_world.kayak.position=point
	lake_world._sync_player()
	# The relocation is explicit setup, so bind a fresh actual world model before
	# any live runtime tick. It cannot mint a chase or progression receipt.
	lake_world.world_key=""
	lake_world.refresh_world()
	var result: Dictionary=await r.step("c3_lake_target:"+id)
	lake_world.refresh_world()
	return result

func lake_key(code: Key) -> void:
	var event:=InputEventKey.new()
	event.keycode=code; event.physical_keycode=code; event.pressed=true
	lake_world._gui_input(event)
	r.trace.append({"nativeLakeKey":OS.get_keycode_string(code),"zone":r.state.d.qizhenLake.zone})

func rescue(config: Dictionary) -> void:
	var presenter: Control=load(config.script).new()
	lake_world.add_child(presenter)
	var setup: Dictionary=config.duplicate()
	setup.read_state=func(): return r.state.d
	setup.world=lake_world
	presenter.event.connect(func(id,value): r.state.act(id,value))
	presenter.setup(setup)
	var session: RefCounted=config.session
	var deadline: int=Time.get_ticks_msec()+14000
	var skipped:=false
	while not r.state.d.qizhenLake.rainRescueCompleted and Time.get_ticks_msec()<deadline:
		if is_instance_valid(presenter) and is_instance_valid(presenter.skip) and not skipped:
			if presenter.video.stream_position>0:
				r.trace.append({"nativeRescueVideoPosition":presenter.video.stream_position,"elapsedMs":session.snapshot().elapsedMs})
				presenter.skip.pressed.emit(); skipped=true
		await r.create_timer(.025).timeout
	r.trace.append({"nativeRainRescue":session.snapshot(),"skipButtonPressed":skipped})
	r.check(r.state.d.qizhenLake.rainRescueCompleted and (skipped or session.reduced_motion()),"source rescue route, actual skip/fallback, and monotonic dock hold")
	if is_instance_valid(presenter): presenter.cancel()
	await r.process_frame

func weather(already_started: bool=false) -> void:
	var buttons: Array=[{},{},{}]
	var controls: Array=[]
	for child in r.game.find_children("*","Button",true,false):
		if child is Button and child.text in ["向左","向右"]: controls.append(child)
	controls.sort_custom(func(a,b):
		var first: Vector2=a.get_global_rect().position; var second: Vector2=b.get_global_rect().position
		return first.y<second.y if not is_equal_approx(first.y,second.y) else first.x<second.x)
	if not r.check(controls.size()==6,"actual Weather exposes three left/right control pairs"): return
	for row in range(3):
		for index in range(2):
			var control: Button=controls[row*2+index]
			buttons[2-row][-1 if control.text=="向左" else 1]=control
	var held: Array=[0,0,0]
	if not already_started: r.game.start_button.pressed.emit()
	for frame in range(1500):
		if not r.game_results.is_empty(): break
		for band in range(3):
			var error: float=float(r.game.TARGET[band])-float(r.game.positions[band])
			var direction: int=1 if error>1 else -1 if error< -1 else 0
			if direction!=held[band]:
				if held[band]!=0: buttons[band][held[band]].button_up.emit()
				if direction!=0: buttons[band][direction].button_down.emit()
				held[band]=direction
		r.game._process(.02)
	for band in range(3):
		if held[band]!=0: buttons[band][held[band]].button_up.emit()

func fish(target: String,spot: String) -> void:
	var request: Dictionary=await lake_interact(target)
	if not r.check(request.has("game") and request.game.spotId==spot,"source fishing session issued " + spot): return
	var model: RefCounted=FishSolver.new().solve_fishing(spot)
	if not r.check(model.phase=="completed","actual rhythm input model catches " + spot): return
	var proof: Dictionary=model.final_result.duplicate(true)
	proof.session_id=request.game.session_id
	r.trace.append({"nativeFishing":spot,"result":proof.duplicate(true)})
	await r.step("c3_fishing_result",proof)

func lake_location_apps() -> bool:
	var ui: RefCounted=CompactUI.new()
	var started: bool=await ui.begin(r)
	var passed: bool=await lake_location_controls(ui) if started else false
	await ui.close()
	return passed

func lake_location_controls(ui) -> bool:
	# Source app entrances, physical pointer clicks and native inventory drags.
	# The campaign's Chapter1/2 login, identity and access flags are untouched.
	if not await ui.open_app("cc98"): return false
	if not await ui.drag_item("wetProgram","Cc98WetProgramDrop"): return false
	if not await ui.inventory(false): return false
	if not await ui.click("Cc98WetProgramSearch"): return false
	if not await ui.click("OpenPost_qizhen-wet-paper-witness"): return false
	if not await ui.click("Cc98BridgeKeyword"): return false
	if not r.check(r.state.d.qizhenLake.bridgeClueFound and r.state.d.items.bridgeKeyword,"fresh CC98 source thread grants bridge clue through actual app"): return false
	if not await ui.open_app("wechat"): return false
	if not await ui.click("WechatRow_1"): return false
	var deadline: int=Time.get_ticks_msec()+4000
	while Time.get_ticks_msec()<deadline:
		var keyword: Control=ui.named("WechatLakeKeyword")
		if keyword!=null and keyword.visible: break
		await r.create_timer(.025).timeout
	if not await ui.click("WechatLakeKeyword"): return false
	if not r.check(r.state.d.qizhenLake.lakeClueFound and r.state.d.items.lakeKeyword,"fresh friend chat publishes source-timed lake clue"): return false
	if not await ui.open_app("zjuding"): return false
	if not await ui.click("ZjudingApp_library"): return false
	if not await ui.click("LibraryApp_catalog"): return false
	if not await ui.drag_item("wetProgram","LibraryCatalogQuery"): return false
	if not await ui.inventory(false): return false
	if not await ui.click("LibraryCatalogSearch"): return false
	if not await ui.click("LibraryReflectionKeyword"): return false
	if not r.check(r.state.d.qizhenLake.reflectionClueFound and r.state.d.items.reflectionKeyword and not r.state.d.items.wetProgram,"fresh Library catalog clue completes unordered source evidence set"): return false
	if not await ui.open_app("zjuding"): return false
	if not await ui.click("ZjudingApp_campus_map"): return false
	for clue in ["bridge","reflection","lake"]:
		if not await ui.click("QizhenMapImport_"+clue): return false
	if not r.check(r.state.d.qizhenLake.mapClueIds.size()==3 and r.state.d.qizhenLake.phase=="location_search","actual map imports preserve final confirmation gate"): return false
	if not await ui.click("QizhenMapConfirm"): return false
	if not await ui.click("QizhenMapEnter"): return false
	if not r.check(r.state.d.native.scene=="campus_qizhen_loop" and r.state.d.rpgCheckpoint=="campus_qizhen_gate" and r.state.d.qizhenLake.phase=="lake_unlocked","actual map entrance opens campus gate without skipping physical entry"): return false
	return await compact_lake_gate(ui)

func compact_lake_gate(ui) -> bool:
	if not r.check(ui.main.world_frame.is_visible_in_tree(),"compact map action exposes actual world viewport"): return false
	var selected: Dictionary={}
	for target in r.state.get_targets(r.state.d.native.scene):
		if target.action=="c3_lake_enter": selected=target; break
	if not r.check(not selected.is_empty(),"naturally unlocked physical lake gate exists"): return false
	var world: Control=ui.main.world
	var point: Vector2=Vector2(selected.position[0],selected.position[1])
	world.player=world._find_safe(point)
	world._sync_player(); world._process(0)
	r.trace.append({"spatialSetup":{"scene":world.scene_id,"target":"physical lake entrance","point":[world.player.x,world.player.y]},"notPhysicalNavigation":true})
	if not r.check(world._distance(selected)<=float(selected.get("radius",100)),"source gate has collision-safe reachable interaction stand"): return false
	world.grab_focus()
	for pressed in [true,false]:
		var event:=InputEventKey.new(); event.keycode=KEY_SPACE; event.physical_keycode=KEY_SPACE; event.pressed=pressed
		ui.main.world_viewport.push_input(event,true)
		await r.process_frame
	await ui.flush()
	return r.check(r.state.d.native.scene=="qizhen_lake" and r.state.d.qizhenLake.phase in ["dock_outfitting","boarding_tutorial"],"actual compact viewport Space enters lake from its physical gate")

func lake_weather_app() -> bool:
	var ui: RefCounted=CompactUI.new()
	var started: bool=await ui.begin(r)
	var passed: bool=await lake_weather_controls(ui) if started else false
	r.game=null
	await ui.close()
	return passed

func lake_weather_controls(ui) -> bool:
	if not await ui.home(): return false
	if not await ui.click("HomeWeatherOpen"): return false
	if not r.check(r.state.d.currentScene=="weather" and r.state.d.native.page=="weather","actual Home Weather entrance satisfies source app guard"): return false
	if not await ui.drag_item("hairDryer","QizhenWeatherDevice"): return false
	if not r.check(is_instance_valid(ui.main.active_game),"actual Weather inventory drop starts Main-owned cloud game"): return false
	r.game=ui.main.active_game
	r.game.set_process(false)
	r.game_results=[]
	r.game.finished.connect(func(proof): r.game_results.append(proof.duplicate(true)))
	if not await ui.click_control(r.game.start_button,"weather start adjustment"): return false
	await weather(true)
	if not r.check(r.game_results.size()==1 and r.state.d.qizhenLake.rainSafetyCleared and not r.state.d.items.hairDryer,"Main-owned actual three-band weather proof consumes dryer"): return false
	r.trace.append({"nativeActivity":"c3_weather","entry":"compact Home→Weather→actual inventory drag","result":r.game_results[0].duplicate(true)})
	r.game=null
	await ui.flush()
	if not r.check(r.state.d.native.page=="weather" and r.state.d.native.scene=="dorm_hub","source Weather success does not silently teleport to lake"): return false
	if not await ui.open_app("zjuding"): return false
	if not await ui.click("ZjudingApp_campus_map"): return false
	if not await ui.click("QizhenMapEnter"): return false
	return await compact_lake_gate(ui)
