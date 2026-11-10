extends SceneTree
## Complete Main + State/controller + on-disk save/load regression.
## Retained source checkpoints initialize only prerequisites. No completion facts
## or result payloads are synthesized. Pointer events drive real activity views.
var checks:=0
var failures:=0
var state: Node
var shell
var actions: Array[String]=[]
var proofs: Array[Dictionary]=[]
var trace: Array=[]
var page
var phone_clock_owned:=false
func check(ok: bool,label: String) -> bool:
	checks+=1
	if not ok: failures+=1;push_error("MAIN_HANDOFF: "+label)
	return ok
func _initialize() -> void: run.call_deferred()
func frames(count:=3) -> void:
	for i in count: await process_frame
func mouse(p: Vector2,down: bool) -> void:
	var motion:=InputEventMouseMotion.new();motion.position=p;motion.global_position=p;root.push_input(motion,true)
	var e:=InputEventMouseButton.new();e.position=p;e.global_position=p;e.button_index=MOUSE_BUTTON_LEFT;e.button_mask=MOUSE_BUTTON_MASK_LEFT if down else 0;e.pressed=down
	root.push_input(e,true)
func click(button: Button) -> void:
	check(is_instance_valid(button) and button.is_visible_in_tree() and not button.disabled,"ordinary button visible and enabled "+str(button.name))
	var p:=button.get_global_rect().get_center();mouse(p,true);mouse(p,false)
func tick(game,count: int,delta:=.05) -> void:
	for i in count: game._process(delta)
func mount() -> void:
	shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames(6)
	shell.world.set_process(false)
func unmount() -> void:
	if is_instance_valid(shell): await shell.shutdown();shell.free();await frames()
	shell=null
func initialize_checkpoint(id: String) -> void:
	await unmount();state.developer_mode=true
	check(state.begin_checkpoint(id),"legal retained source checkpoint "+id)
	state.developer_mode=false;state.formal_snapshot={};state.persistence_ready=true
	check(state.validate_snapshot(state.d),"checkpoint has valid formal save shape")
	check(state.save_game(),"isolated formal checkpoint persisted")
	check(state.load_game(),"checkpoint reloaded through production validator")
	actions.clear();proofs.clear();await mount()
func cloud_event(game,local: Vector2,pressed: bool) -> void:
	var e:=InputEventMouseButton.new();e.position=game.get_global_transform_with_canvas()*local;e.global_position=e.position
	e.button_index=MOUSE_BUTTON_LEFT;e.button_mask=MOUSE_BUTTON_MASK_LEFT if pressed else 0;e.pressed=pressed
	root.push_input(e,true)
func cloud_drag(game,band: int,destination: float) -> void:
	var center: Vector2=game.cloud_center(band)
	cloud_event(game,center,true)
	var event:=InputEventMouseMotion.new()
	event.position=game.get_global_transform_with_canvas()*Vector2(game.TRACK_LEFT+destination*game.TRACK_UNIT,center.y)
	event.global_position=event.position;event.button_mask=MOUSE_BUTTON_MASK_LEFT
	root.push_input(event,true)
func solve_weather(game) -> void:
	var owned: int=-1
	for i in range(1200):
		if game.settled:break
		if owned>=0 and absf(game.positions[owned]-(game.TARGET[owned]+4.0))<1.0:
			cloud_event(game,Vector2(5,5),false);owned=-1
		if owned<0:
			var band: int=-1;var distance: float=0
			for index in 3:
				var error: float=absf(game.positions[index]-game.TARGET[index])
				if (error>6 or not game.controlled[index]) and error>distance:band=index;distance=error
			if band>=0:cloud_drag(game,band,game.TARGET[band]+4);owned=band
		game._process(.05)
func weather() -> void:
	for extent: Vector2i in [Vector2i(1280,720),Vector2i(390,844)]:
		root.size=extent;await initialize_checkpoint("c3-qizhen-weather-control")
		var ui=load("res://tests/campaign_compact_ui.gd").new();ui.runner=self;ui.main=shell
		if not await ui.home():return
		if not await ui.click("HomeWeatherOpen"):return
		check(state.d.currentScene=="weather" and state.d.native.page=="weather" and state.lake_module().weather_ready(state.d),"ordinary Home Weather satisfies all rain recovery/dock/dryer controller gates")
		if not await ui.drag_item("hairDryer","QizhenWeatherDevice"):return
		if not check(is_instance_valid(shell.active_game),"real inventory dryer drop opens Main weather activity"):return
		var game=shell.active_game;game.set_process(false);game.finished.connect(func(value):proofs.append(value.duplicate(true)))
		click(game.start_button);cloud_drag(game,0,50);tick(game,4);cloud_event(game,Vector2(5,5),false)
		check(game.controlled[0] and game.elapsed>0,"real visible cloud manipulated before cancellation")
		click(game.exit_button);tick(game,50)
		check(not is_instance_valid(shell.active_game) and proofs.is_empty() and actions.count("c3_weather_result")==0,"cancel closes Main without late weather result")
		check(state.d.items.hairDryer and not state.d.qizhenLake.rainSafetyCleared and state.d.qizhenLake.phase=="rain_recovery","cancel keeps dryer and story phase")
		check(state.save_game(),"cancelled weather state saves")
		await frames();await unmount();check(state.load_game(),"cancelled weather state reloads")
		check(state.d.items.hairDryer and not state.d.qizhenLake.rainSafetyCleared and state.d.qizhenLake.phase=="rain_recovery","cancel facts survive disk reload")
		await mount();ui.main=shell
		if not await ui.home():return
		if not await ui.click("HomeWeatherOpen"):return
		if not await ui.drag_item("hairDryer","QizhenWeatherDevice"):return
		if not check(is_instance_valid(shell.active_game),"ordinary dryer drop reenters after cancellation and reload"):return
		game=shell.active_game;game.set_process(false);game.finished.connect(func(value):proofs.append(value.duplicate(true)))
		click(game.start_button);solve_weather(game)
		check(proofs.size()==1 and actions.count("c3_weather_result")==1,"three actual cloud drags issue one Main result")
		if proofs.is_empty():return
		check(state.lake_module().valid_weather(proofs[0]),"controller validator accepts genuine gameplay proof")
		check(not is_instance_valid(shell.active_game) and not state.d.items.hairDryer and state.d.qizhenLake.rainSafetyCleared and state.d.qizhenLake.phase=="boarding_tutorial","controller consumes dryer once and advances tutorial")
		var attempts: int=state.d.qizhenLake.weatherControlAttempts
		var best: int=state.d.qizhenLake.weatherControlBestMoves
		var saved: Dictionary=state._read_native_save(state.SAVE_PATH).get("state",{})
		check(not saved.get("items",{}).get("hairDryer",true) and saved.get("qizhenLake",{}).get("rainSafetyCleared",false),"Main callback automatic save contains weather success")
		tick(game,50);check(proofs.size()==1,"settled weather cannot issue second result")
		await frames();await unmount();check(state.load_game(),"accepted weather save reloads")
		check(not state.d.items.hairDryer and state.d.qizhenLake.rainSafetyCleared and state.d.qizhenLake.phase=="boarding_tutorial","success facts survive disk reload")
		state.act("c3_weather_result",proofs[0])
		check(state.d.qizhenLake.weatherControlAttempts==attempts and state.d.qizhenLake.weatherControlBestMoves==best,"replaying actual proof cannot duplicate weather mutation")
		check(not state.act("c3_weather_start").has("game"),"successful weather gate cannot consume again")
		print("WEATHER_MAIN_HANDOFF viewport=",extent," realResult=",proofs[0])
func run() -> void:
	if not check(load("res://tests/native_test_isolation.gd").is_isolated_save(),"isolated save root"):quit(1);return
	state=root.get_node("State")
	state.action_completed.connect(func(id,_before,_after,_result):actions.append(id))
	await weather()
	await unmount()
	print("WEATHER_MAIN_HANDOFF: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
