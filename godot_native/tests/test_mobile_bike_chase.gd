extends "res://tests/test_canteen_defense_mobile.gd"
const Chase=preload("res://scripts/games/chase_stunt_model.gd")
func open_chase(view: Vector2i) -> Control:
	state.d.native.scene="campus_bootstrap";state.d.runtimeMode="rpg";state.d.rpgScene="campus_bootstrap"
	state.d.canteenHunt.active=true;state.d.canteenHunt.phase="chase_ready";state.d.canteenHunt.bikePaid=true;state.d.canteenHunt.chaseCompleted=false
	root.size=view;shell.size=Vector2(view);shell._refresh();await frames(3)
	var result: Dictionary=state.act("c3_chase")
	check(result.get("game",{}).get("type")=="chase","controller admits paid source chase")
	await frames(6)
	if result.game.get("departure",false):
		check(state.d.canteenHunt.phase=="chase_ready","departure does not commit an attempt early")
		await tap(shell.active_game.skip_button);await frames(6)
	var game: Control=shell.active_game;game.set_process(false)
	return game
func press_control(game: Control,key: String,id: int,down: bool,cancel: bool=false) -> void:
	finger_event(game.control_buttons[key].get_global_rect().get_center(),id,down,cancel)
func bounds(game: Control) -> void:
	var view: Control=game.native_chase_view
	check(is_instance_valid(view) and view.ready3d,"original source 3D world is loaded")
	check(view.size==game.chase_view.size and view.position==game.chase_view.position,"native film and interaction overlay have identical bounds")
	check(view.surface.stretch_mode==TextureRect.STRETCH_KEEP_ASPECT_CENTERED,"source16:9 film is contained without portrait stretching")
	check(view.camera.keep_aspect==Camera3D.KEEP_HEIGHT and is_equal_approx(view.camera.near,.1),"source vertical camera FOV/near plane is retained")
	check(game.background==null and game.rider==null,"legacy2D fallback cannot replace original3D")
	var scale: float=minf(view.size.x/960,view.size.y/540)
	var extent:=Vector2(960,540)*scale
	check(Rect2(Vector2.ZERO,view.size).encloses(Rect2((view.size-extent)/2,extent)),"entire authored film fits the native field")
func run() -> void:
	state=root.get_node("State");state.developer_mode=true;state.d=state.initial()
	state.d.native.chapter=3;state.d.native.page="phone_home";state.d.native.scene="campus_bootstrap"
	shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames()
	shell.set_process(false);shell.world.set_process(false)
	for view: Vector2i in [Vector2i(390,844),Vector2i(430,860),Vector2i(844,390),Vector2i(860,430)]:
		var game: Control=await open_chase(view);var screen:=Rect2(Vector2.ZERO,Vector2(view))
		check(game.activity_compact and game.size==Vector2(view) and game.scale==Vector2.ONE,"compact chase uses physical screen pixels")
		check(not shell.world_frame.visible and not shell.phone.visible and not shell.mobile_back.visible and not shell.world_tasks.visible and not shell.inventory_dock.visible,"one activity owner hides all old shell surfaces")
		bounds(game)
		for control: Control in [game.headline,game.status,game.hint,game.pause_button,game.retry_button,game.exit_button,game.start_button]:
			check(screen.encloses(control.get_global_rect()),"physical HUD/control stays in viewport: "+control.text)
			check(control.get_theme_font_size("font_size")>=14,"HUD/control label >=14px")
		await tap(game.start_button)
		for control: Button in game.control_buttons.values():
			check(control.size.x>=44 and control.size.y>=44 and screen.encloses(control.get_global_rect()),"usable thumb target "+control.text)
			check(not control.get_rect().intersects(game.chase_view.get_rect()),"thumb target never hides a hazard")
		var story_before:=JSON.stringify(state.d)
		press_control(game,"left",0,true);game._process(.1)
		press_control(game,"jump",1,true);game._process(.1)
		check(game.model.lane<1 and game.model.charge>0 and game.model.air_height==0,"two-finger steering and hold-charge share original simulation")
		press_control(game,"jump",1,false,true)
		check(game.model.air_velocity==0 and game.model.held.is_empty() and game.model.charge==0,"cancel touch neutralizes controls without launching a jump")
		press_control(game,"left",0,false)
		press_control(game,"jump",1,true);game._process(.1);press_control(game,"jump",1,false)
		check(game.model.air_velocity>0,"ordinary charge release still jumps")
		press_control(game,"right",0,true);press_control(game,"jump",1,true)
		var count: int=game.model.inputs.size();var tick: int=game.model.tick
		root.size=Vector2i(view.y,view.x);shell.size=Vector2(view.y,view.x);shell._layout();await frames()
		check(game.model.tick==tick and game.model.held.is_empty() and game.touch_sources.is_empty(),"orientation freezes tick and clears held ownership through neutral input")
		finger_event(Vector2.ZERO,1,false)
		check(game.model.inputs.size()==count+1,"stale release after rotation cannot create another action")
		root.size=view;shell.size=Vector2(view);shell._layout();await frames()
		var music_owner: AudioStreamPlayer=shell.audio_director.music
		var music_stream: AudioStream=music_owner.stream
		await tap(game.pause_button);tick=game.model.tick;game._process(.3)
		check(game.paused and game.model.tick==tick,"real pause freezes source clock")
		await tap(game.retry_button)
		check(not game.running and not game.paused and game.model.tick==0 and game.model.lives==3,"paused Retry returns to ready with clean model")
		check(not shell.audio_director._paused_prefixes.has("canteen_chase_"),"paused Retry releases existing source audio pause owner")
		await tap(game.start_button)
		check(shell.audio_director.music==music_owner and music_owner.stream==music_stream and not music_owner.stream_paused,"paused Retry/Start retain same resumed music owner and stream")
		var point: Vector2=game.control_buttons.jump.get_global_rect().get_center()
		motion(point);mouse(point,true);game._process(.1);mouse(Vector2(-20,-20),false)
		check(not game.model.held.has("jump") and game.model.air_velocity>0,"captured mouse release outside control completes intended jump")
		press_control(game,"left",0,true);game._notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
		check(game.paused and game.model.held.is_empty() and game.touch_sources.is_empty(),"native focus loss freezes and clears held controls")
		await tap(game.start_button)
		check(JSON.stringify(state.d)==story_before,"presentation/input does not alter story wallet or inventory")
		await tap(game.exit_button)
		check(not is_instance_valid(shell.active_game) and shell.world_frame.visible and not shell.phone.visible,"Exit restores world owner")
		for i in range(3):shell._refresh();shell._process(.1);await frames(1)
		check(not is_instance_valid(shell.active_game),"Exit cannot immediately auto-loop")
	# Actual source collision creates both owners before paused Retry.
	var audio_game: Control=await open_chase(Vector2i(430,860));await tap(audio_game.start_button)
	while audio_game.model.collisions==0:audio_game._process(.1)
	await frames(2)
	await tap(audio_game.pause_button)
	var collision_owner: AudioStreamPlayer
	for effect: Dictionary in shell.audio_director.effects:
		if effect.id=="canteen_chase_collision":collision_owner=effect.player
	check(is_instance_valid(collision_owner) and collision_owner.stream_paused,"actual collision effect remains owned and paused before Retry")
	var music_owner: AudioStreamPlayer=shell.audio_director.music
	var music_stream: AudioStream=music_owner.stream
	await tap(audio_game.retry_button)
	check(not shell.audio_director.effects.any(func(effect):return str(effect.id).begins_with("canteen_chase_collision") or str(effect.id).begins_with("native_chase_")),"Retry retires both old collision-effect owners")
	check(not is_instance_valid(collision_owner) or not collision_owner.playing,"retired collision cannot revive on Resume")
	await tap(audio_game.start_button)
	check(shell.audio_director.music==music_owner and music_owner.stream==music_stream and not music_owner.stream_paused,"Retry/Start resume same music while leaving old effect retired")
	await tap(audio_game.exit_button)
	# Full legitimate existing chase trace through actual root actions.
	var game: Control=await open_chase(Vector2i(430,860));await tap(game.start_button)
	var proof: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/chase.json"))
	var index:=0
	while game.model.status=="running" and game.model.tick<=int(proof.ticks):
		while index<proof.inputs.size() and int(proof.inputs[index].tick)==game.model.tick:
			var action: Dictionary=proof.inputs[index]
			if action.type=="press":press_control(game,action.action,0,true)
			elif action.type=="release":press_control(game,action.action,0,false)
			else:press_control(game,"left",0,false,true)
			index+=1
		game._process(1.0/120)
	check(game.model.status=="won" and Chase.validate_result(game.model.result()),"755m real root action trace independently replays")
	var terminal_ticks: int=game.model.tick;await tap(game.retry_button)
	check(game.sent and game.model.tick==terminal_ticks,"queued Retry cannot discard an already won proof")
	game._process(1);await frames(8)
	check(state.d.canteenHunt.chaseCompleted and state.d.canteenHunt.phase=="theater_reached","ordinary callback accepts unchanged controller proof")
	check(is_instance_valid(shell.active_game) and shell.active_game.stage=="finish","accepted result presents original theater arrival before world return")
	await tap(shell.active_game.skip_button);await frames()
	check(shell.world_frame.is_visible_in_tree() and not shell.phone.visible,"ending Skip restores visible campus owner")
	await shell.shutdown();shell.queue_free();await frames()
	print("MOBILE_BIKE_CHASE: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
