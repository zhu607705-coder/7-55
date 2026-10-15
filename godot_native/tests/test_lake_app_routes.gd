extends "res://tests/test_compact_device_navigation.gd"
const Lake=preload("res://scripts/chapters/c3_lake.gd")
func named(id: String) -> Control:
	return main.page_body.find_child(id,true,false)
func press(id: String) -> void: await click(named(id),id)
func milestone(_name: String) -> void: pass
func readable_saved(id: String) -> void:
	var button: Button=named(id)
	check(button!=null and button.disabled,"saved source control remains explicitly disabled")
	if button!=null: check(contrast(button.get_theme_color("font_disabled_color"),button.get_theme_stylebox("disabled").bg_color)>=4.5,"saved source label has readable disabled contrast")
func home() -> void:
	for i in range(7):
		if state.d.native.page=="phone_home": return
		var button: Button
		for id in ["Cc98CloseThread","FriendChatBack","PhoneNav_exit","ZjudingLoadingExit","ZjudingMenu_2","PhoneNav_back","ZjudingProfileMenu"]:
			var candidate: Control=named(id)
			if candidate is Button and candidate.is_visible_in_tree(): button=candidate; break
		if button==null and main.header_row.is_visible_in_tree(): button=find_button(main.header_row,"‹")
		await click(button,"app back/home")
	check(state.d.native.page=="phone_home","actual app controls returned Home")
func open_zjuding() -> void:
	await press("HomeApp_zjuding")
	var entry: RefCounted=state.get_phone_entry_session()
	if not entry.entry_allowed:
		check(entry.phase=="loading","original checkpoint network must satisfy real app-entry gate")
		await click(main.find_child("ControlCenterTrigger",true,false),"open real Control Center")
		await click(main.control_center.find_child("ControlNetwork_wifi",true,false),"choose campus WiFi")
		await click(main.control_center.find_child("PhoneNav_close",true,false),"close Control Center")
		check(not entry.entry_allowed,"network change preserves rejected mount snapshot")
		await press("ZjudingLoadingExit")
		await press("HomeApp_zjuding")
		entry=state.get_phone_entry_session()
	var deadline:=Time.get_ticks_msec()+8000
	while entry.phase=="loading" and Time.get_ticks_msec()<deadline: await process_frame
	check(entry.phase=="ready","normal source1500ms loader completed before app interaction")
	await process_frame; await process_frame
func fixture(id: String,width: int) -> void:
	check(state.begin_checkpoint(id),"unmodified original source scenario")
	root.size=Vector2i(width,844 if width<1100 else 720)
	await process_frame; await process_frame
	main.world.set_process(false); main.c3_narrative_host.set_process(false); main.c3_scene_host.set_process(false)
	main.mobile_world=false; main._layout(); await process_frame
func run() -> void:
	state=root.get_node("State"); state.developer_mode=true; state.begin_checkpoint("c3-qizhen-location")
	root.size=Vector2i(390,844); main=load("res://scenes/main.tscn").instantiate(); root.add_child(main); await process_frame; await process_frame
	controller_contracts()
	for width: int in [390,430,1280]:
		await fixture("c3-qizhen-location",width)
		await home(); await press("HomeApp_cc98")
		check(named("OpenPost_seat-022-backpack")!=null,"ordinary CC98 content retained")
		check(named("OpenPost_qizhen-wet-paper-witness")==null,"witness hidden before explicit physical-feature search")
		await milestone("cc98-context-search")
		await press("Cc98WetProgramSearch")
		check(state.d.items.wetProgram and not state.d.qizhenLake.bridgeClueFound,"search grants no evidence")
		await press("OpenPost_qizhen-wet-paper-witness")
		check(named("Cc98BridgeKeyword")!=null,"source thread exposes explicit save after replies")
		await press("Cc98BridgeKeyword")
		check(state.d.qizhenLake.bridgeClueFound and state.d.items.bridgeKeyword and state.d.items.wetProgram,"bridge save grants first distinct clue only")
		check(named("Cc98BridgeKeyword").disabled,"saved witness is one-time")
		readable_saved("Cc98BridgeKeyword")
		await milestone("cc98-source-replies-saved")
		await home(); await open_zjuding(); await press("ZjudingApp_library"); await press("LibraryApp_catalog")
		var query: LineEdit=named("LibraryCatalogQuery")
		check(query!=null,"catalog available after genuine accepted entry")
		if query==null: quit(1); return
		query.text="签到记录夹页"; query.text_changed.emit(query.text)
		await press("LibraryCatalogSearch")
		check(not state.d.qizhenLake.reflectionClueFound,"catalog search does not auto-collect")
		await press("LibraryReflectionKeyword")
		check(state.d.qizhenLake.reflectionClueFound and state.d.items.reflectionKeyword and state.d.items.wetProgram,"native Library entrance and second source save work")
		readable_saved("LibraryReflectionKeyword")
		await milestone("library-reflection-record")
		query=named("LibraryCatalogQuery"); query.text="图书"; query.text_changed.emit(query.text); await press("LibraryCatalogSearch")
		check(named("LibraryReflectionKeyword")!=null and named("LibraryReflectionKeyword").disabled,"unrelated search keeps original saved anomaly")
		await home(); await press("HomeApp_wechat")
		check(named("WechatRow_0")!=null and named("WechatRow_2")!=null and named("WechatRow_3")!=null,"ordinary WeChat rows retained")
		await press("WechatRow_1")
		check(not named("WechatLakeKeyword").visible and not state.d.qizhenLake.lakeClueFound,"no immediate or automatic final clue")
		await create_timer(.29).timeout
		check(named("QizhenChatLine_0").visible and not named("QizhenChatLine_2").visible,"source first chat line precedes final line")
		await create_timer(.52).timeout
		check(named("QizhenChatLine_1").visible,"source second line arrives in order")
		await create_timer(.53).timeout
		check(named("WechatLakeKeyword").visible and not state.d.qizhenLake.lakeClueFound,"full source chat reveals explicit save only")
		await press("WechatLakeKeyword")
		check(state.d.qizhenLake.lakeClueFound and state.d.items.lakeKeyword and not state.d.items.wetProgram,"only third distinct source consumes wet program")
		readable_saved("WechatLakeKeyword")
		await milestone("wechat-source-chat-saved")
		await home(); await open_zjuding(); await press("ZjudingApp_library"); await press("LibraryApp_catalog")
		check(named("LibraryReflectionKeyword")!=null and named("LibraryReflectionKeyword").disabled,"persisted reflection remains reviewable without wet program after re-entry")
		await home(); await open_zjuding(); await press("ZjudingApp_campus_map")
		check(state.d.native.page=="zjuding" and named("QizhenMapDrop")!=null,"map remains native Zjuding subpage")
		check(named("QizhenMapConfirm")==null,"empty map has no premature confirmation")
		await milestone("map-three-owned-sources")
		for clue: String in ["bridge","reflection","lake"]:
			await press("QizhenMapImport_"+clue)
			check(not state.d.items[clue+"Keyword"],"source map import consumes corresponding keyword")
		check(state.d.qizhenLake.phase=="location_search" and state.d.qizhenLake.mapClueIds.size()==3,"third import does not auto-confirm")
		await milestone("map-ready-for-confirm")
		await press("QizhenMapConfirm")
		check(state.d.qizhenLake.phase=="lake_unlocked" and state.d.native.page=="zjuding" and main.phone.is_visible_in_tree(),"explicit confirmation stays on solved phone map")
		await milestone("map-confirmed-result")
		await press("QizhenMapEnter")
		check(state.d.native.scene=="campus_qizhen_loop" and state.d.rpgCheckpoint=="campus_qizhen_gate" and state.d.qizhenLake.phase=="lake_unlocked","source map enters campus gate without premature lake entry")
		check(main.world_frame.is_visible_in_tree(),"map world entry becomes visibly actionable")
		await milestone("map-entered-physical-campus-gate")
		await interact("c3_lake_enter")
		check(state.d.native.scene=="qizhen_lake" and state.d.qizhenLake.phase=="dock_outfitting","actual physical gate alone initializes lake")
		await weather_flow(width)
	await main.shutdown(); main.queue_free(); await process_frame
	print("Lake ordinary app routes: %d checks, %d failures"%[checks,failures]); quit(0 if failures==0 else 1)

func controller_contracts() -> void:
	var owner=Lake.new()
	for order: Array in [["bridge","reflection","lake"],["bridge","lake","reflection"],["reflection","bridge","lake"],["reflection","lake","bridge"],["lake","bridge","reflection"],["lake","reflection","bridge"]]:
		var s: Dictionary=state.initial(); s.qizhenLake.active=true; s.qizhenLake.phase="location_search"; s.items.wetProgram=true
		for i in range(order.size()):
			var id: String=order[i]
			owner.dispatch(s,"c3_clue:"+id); check(s.qizhenLake[id+"ClueFound"] and s.items[id+"Keyword"],"all six collection orders grant exact keyword")
			owner.dispatch(s,"c3_map:"+id); owner.dispatch(s,"c3_clue:"+id)
			check(not s.items[id+"Keyword"],"reread after import never regrants keyword")
			check(s.items.wetProgram==(i<2),"wet program consumed exactly after third distinct source")
		check(s.qizhenLake.phase=="location_search","three controller imports still require confirm")
		owner.dispatch(s,"c3_map_confirm"); check(s.qizhenLake.phase=="lake_unlocked","named source set confirms")
	var weather: Dictionary=state.initial(); weather.qizhenLake.active=true; weather.qizhenLake.phase="rain_recovery"; weather.qizhenLake.rainRescueCompleted=true; weather.qizhenLake.weatherAdjustmentRequested=true; weather.items.hairDryer=true; weather.currentScene="weather"
	check(owner.weather_ready(weather),"source Weather app authority accepts RPG-mounted phone")
	for field: String in ["rainRescueCompleted","weatherAdjustmentRequested"]:
		var bad: Dictionary=weather.duplicate(true); bad.qizhenLake[field]=false; check(not owner.dispatch(bad,"c3_weather_start").has("game"),"weather rejects missing "+field)
	for pair: Array in [["zone","open_water"],["vehicle","kayak"]]:
		var bad: Dictionary=weather.duplicate(true); bad.qizhenLake[pair[0]]=pair[1]; check(not owner.dispatch(bad,"c3_weather_start").has("game"),"weather rejects wrong "+pair[0])
	var wrong_app: Dictionary=weather.duplicate(true); wrong_app.currentScene="phone_home"; check(not owner.dispatch(wrong_app,"c3_weather_start").has("game"),"weather cannot authorize its own app entry")
	var proof: Dictionary={"moves":3,"cloudOffsets":[34,52,70],"controlledBands":[true,true,true],"stableMs":1000,"elapsedMs":3000}
	check(owner.valid_weather(proof),"source-shaped summary accepted")
	for key: String in ["moves","stableMs","elapsedMs"]:
		var invalid: Dictionary=proof.duplicate(true); invalid[key]=NAN; check(not owner.valid_weather(invalid),"weather rejects nonfinite "+key)
	proof.moves=3.5; check(not owner.valid_weather(proof),"weather move count must be integer")

func weather_flow(width: int) -> void:
	await fixture("c3-qizhen-hair-dryer",width)
	await home(); await press("HomeWeatherOpen")
	check(named("WeatherWaterCard")==null and named("QizhenWeatherDevice")!=null,"lake context replaces only source Weather bottom card")
	await press("QizhenWeatherDevice")
	check(state.d.ui.inventoryOpen and not is_instance_valid(main.active_game),"unselected Weather interface opens inventory without starting")
	await milestone("weather-dryer-interface")
	named("QizhenWeatherDevice")._drop_data(Vector2.ZERO,{"kind":"inventory_item","item":"campusCard"})
	await process_frame; await process_frame
	check(not is_instance_valid(main.active_game) and state.d.items.hairDryer,"wrong Weather drop never starts or consumes dryer")
	var dryer: Button=main.phone_chrome.find_child("Item_hairDryer",true,false)
	await click(dryer,"real inventory dryer selection")
	check(state.d.ui.selectedItem=="hairDryer","actual inventory click selects owned dryer")
	await press("QizhenWeatherDevice")
	check(is_instance_valid(main.active_game) and state.d.items.hairDryer,"correct selected dryer starts genuine calibration without consuming it")
	check(not state.d.ui.inventoryOpen and state.d.ui.selectedItem==null,"accepted start closes inventory and selection")
	await milestone("weather-actual-calibration")
	if not is_instance_valid(main.active_game): return
	await click(find_button(main.active_game,"返回天气"),"cancel weather control")
	check(not is_instance_valid(main.active_game) and state.d.items.hairDryer and not state.d.qizhenLake.rainSafetyCleared,"cancel returns to Weather without rewards/consumption")
	await press("QizhenWeatherDevice"); await create_timer(.4).timeout
	dryer=main.phone_chrome.find_child("Item_hairDryer",true,false); await click(dryer,"select dryer for retry"); await press("QizhenWeatherDevice")
	check(is_instance_valid(main.active_game),"deliberate dryer retry opens actual calibration")
	if not is_instance_valid(main.active_game): return
	var game: Control=main.active_game; game.set_process(false)
	await click(find_button(game,"开始调整"),"actual calibration start")
	check(game.started and not game.paused,"real start input enables calibration clock")
	var held: Array=[0,0,0]
	var keys: Array=[[KEY_Z,KEY_C],[KEY_A,KEY_D],[KEY_Q,KEY_E]]
	for frame in range(400):
		if not is_instance_valid(main.active_game): break
		for band in range(3):
			var error: float=[34.0,52.0,70.0][band]-float(game.positions[band])
			var direction: int=1 if error>1 else -1 if error< -3 else 0
			if direction!=held[band]:
				if held[band]!=0: key(keys[band][1 if held[band]>0 else 0],false)
				if direction!=0: key(keys[band][1 if direction>0 else 0],true)
				held[band]=direction
		Input.flush_buffered_events()
		game._process(.05)
	for band in range(3):
		if held[band]!=0: key(keys[band][1 if held[band]>0 else 0],false)
	await process_frame; await process_frame
	if not state.d.qizhenLake.rainSafetyCleared and is_instance_valid(game): print("WEATHER_INPUT_DIAGNOSTIC ",{"started":game.started,"paused":game.paused,"positions":game.positions,"moves":game.moves,"stable":game.stable,"elapsed":game.elapsed,"controlled":game.controlled,"scene":state.d.currentScene,"result":state.last_result})
	check(state.d.qizhenLake.rainSafetyCleared and not state.d.items.hairDryer,"actual keyboard-controlled minigame emits validated success and consumes dryer")
	check(state.d.native.page=="weather" and main.phone.is_visible_in_tree() and named("QizhenWeatherDevice").disabled,"success returns to ordinary Weather complete state")
	await milestone("weather-source-success")
func key(code: int,pressed: bool) -> void:
	var event:=InputEventKey.new(); event.keycode=code; event.physical_keycode=code; event.pressed=pressed; Input.parse_input_event(event)
