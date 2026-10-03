extends "res://tests/test_canteen_defense_mobile.gd"
var music_starts:=0
var source_starts:=0
var result_received: Dictionary={}
func run() -> void:
	state=root.get_node("State");state.developer_mode=true;state.d=state.initial()
	state.d.native.chapter=3;state.d.native.page="phone_home";state.d.native.scene="canteen_interior"
	state.d.canteenHunt.active=true;state.d.canteenHunt.phase="exit_blocking"
	root.size=Vector2i(430,860)
	shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames()
	shell.set_process(false);shell.world.set_process(false)
	shell.audio_director.playback_started.connect(func(channel,asset):
		if channel=="music" and asset=="music_canteen_chase":music_starts+=1
	)
	shell.audio_director.cue_published.connect(func(id,_payload):
		if id=="canteen_defense_started":source_starts+=1
	)
	var game: Control=await open_activity(Vector2i(430,860))
	await tap(game.start_button);game._process(1.0/60);await tap(game.pause_button)
	var music: AudioStreamPlayer=shell.audio_director.music
	check(music.stream_paused,"real pause freezes defense music owner")
	var plays:=music_starts;var cues_before:=source_starts
	await tap(game.retry_button)
	check(not music.stream_paused and shell.audio_director.music==music,"paused active Retry resumes same music player")
	check(game.model.tick==0 and not game.paused,"paused active Retry resets only simulation attempt")
	await tap(game.start_button)
	check(source_starts==cues_before and music_starts==plays,"restart Start never duplicates music start or playback")
	while game.model.status=="running":game.model.step({"x":0,"y":0,"dash":false})
	game.refresh();await tap(game.pause_button)
	check(music.stream_paused,"failed attempt pause owns music")
	await tap(game.retry_button)
	check(not music.stream_paused and game.running and not game.paused,"paused failed Retry resumes owner and next source attempt")
	check(source_starts==cues_before and music_starts==plays,"failed Retry retains source playback without duplicate start")
	await tap(game.pause_button);await tap(game.start_button)
	check(not music.stream_paused and not game.paused,"central Resume resumes the AudioDirector owner")
	await tap(game.exit_button)
	# Source subtitle windows remain visible through pause and layout, exactly780ms.
	game=await open_activity(Vector2i(430,860),true)
	game._pickup_elapsed=0;game._pickup_beat=0;game._pickup_tick(0)
	for sample: Array in [[9580.0,"玩家：那是鸡吗？"],[10480.0,"系统：现在不是了。"]]:
		while game._pickup_elapsed<float(sample[0]):game._process(.01)
		check(game.hint.text==sample[1] and game.hint.is_visible_in_tree(),"source subtitle visible in activity "+str(sample[0]))
		check(shell.toast.text!=sample[1] and not shell.world_frame.visible,"subtitle has one visible owner")
		await tap(game.pause_button)
		root.size=Vector2i(860,430);shell.size=Vector2(860,430);shell._layout();game._process(.1)
		check(game.hint.text==sample[1] and game._pickup_elapsed==float(sample[0]),"pause and rotation preserve active source line")
		await tap(game.start_button)
		for i in range(77):game._process(.01)
		check(game.hint.text==sample[1],"subtitle remains for first770ms")
		game._process(.01)
		check(game.hint.text!=sample[1],"subtitle ends at source780ms")
	await tap(game.exit_button)
	# Recorded winning input runs through root touch events at actual mobile sizes.
	var proof: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/canteen_defense.json"))
	for view: Vector2i in [Vector2i(390,844),Vector2i(430,860)]:
		game=await open_activity(view);result_received={}
		game.finished.connect(func(result: Dictionary):result_received=result)
		await tap(game.start_button);finger_event(game.stick_center,0,true)
		for input: Dictionary in proof.inputs:
			finger_drag(game.stick_center+Vector2(input.x,input.y)*55,0)
			if input.dash:
				var point: Vector2=game.dash_button.get_global_rect().get_center()
				finger_event(point,1,true);finger_event(point,1,false)
			game._process(1.0/60)
		check(game.model.status=="won" and game.model.tick==3600,"actual root touch trace reaches60seconds "+str(view))
		game._process(1)
		check(Model.validate_result(result_received,"1"),"actual mobile touch proof independently replays "+str(view))
		await frames()
	await shell.shutdown();shell.queue_free();await frames()
	print("CANTEEN_DEFENSE_OWNERS: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
