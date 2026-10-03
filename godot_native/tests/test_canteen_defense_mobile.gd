extends "res://tests/test_portrait_exploration.gd"
## Main-mounted, root-event coverage. Fixtures do not count as an earned run.
const Model=preload("res://scripts/games/canteen_defense_model.gd")
var dimensions: Vector2i
var cues: Array=[]
func open_activity(view: Vector2i,prelude: bool=false) -> Control:
	root.size=view; shell.size=Vector2(view); dimensions=view
	shell.mobile_world=true
	shell._open_game({"script":"res://scripts/games/canteen_defense.gd","seed":"1","session_id":"mobile-input","source_pickup_prelude":prelude})
	await frames(3)
	var game: Control=shell.active_game; game.set_process(false)
	game.presentation_requested.connect(func(id: String,payload: Dictionary): cues.append({"id":id,"at":game._pickup_elapsed,"payload":payload}))
	return game
func finger_event(point: Vector2,index: int,down: bool,canceled: bool=false) -> void:
	var e:=InputEventScreenTouch.new(); e.position=point; e.index=index; e.pressed=down; e.canceled=canceled; event(e)
func finger_drag(point: Vector2,index: int) -> void:
	var e:=InputEventScreenDrag.new(); e.position=point; e.index=index; event(e)
func tap(button: Button,index: int=1) -> void:
	var point:=button.get_global_rect().get_center()
	finger_event(point,index,true); finger_event(point,index,false); await frames(2)
func press(code: int,down: bool) -> void:
	var e:=InputEventKey.new(); e.keycode=code; e.physical_keycode=code; e.pressed=down; event(e)
func verify_layout(game: Control) -> void:
	var screen:=Rect2(Vector2.ZERO,Vector2(dimensions))
	check(game.scale==Vector2.ONE and game.size==Vector2(dimensions),"compact activity uses actual screen pixels "+str(dimensions))
	for button: Button in [game.pause_button,game.retry_button,game.exit_button,game.start_button,game.dash_button]:
		check(button.size.x>=44 and button.size.y>=44,"44px targets "+button.text)
		check(screen.encloses(button.get_global_rect()),"control stays in viewport "+button.text)
		check(button.get_theme_font_size("font_size")>=14,"button text stays >=14px "+button.text)
	for label: Label in [game.title,game.timer,game.hint,game.overview_label,game.board_label]:
		if label.visible:
			check(screen.encloses(label.get_global_rect()),"label stays in viewport "+label.text)
			check(label.get_theme_font_size("font_size")>=14,"label text stays >=14px "+label.text)
	check(not shell.phone.visible and not shell.world_frame.visible and not shell.mobile_back.visible and not shell.world_tasks.visible and not shell.inventory_handle.visible and not shell.inventory_dock.visible,"activity hides all old exploration controls and phone")
	check(screen.encloses(game.board_view.get_global_rect()),"action view inside screen")
	if game.portrait_layout:
		check(not game.overview.get_rect().intersects(game.board_view.get_rect()),"overview distinct from action view")
		check(not game.timer.get_rect().intersects(game.overview_label.get_rect()),"status and overview header never overlap")
		check(not game.dash_button.get_rect().intersects(game.hint.get_rect()),"dash and instructions never overlap")
		var metrics: Dictionary=game.board_metrics(game.overview,true)
		for point: Vector2 in Model.EXITS.values()+[game.model.player,game.model.paper]:
			check(Rect2(Vector2.ZERO,game.overview.size).has_point(point*metrics.zoom+metrics.offset),"overview includes all exits, player and paper")
		check(game.board_metrics(game.board_view,false).zoom*94.2>=60,"portrait action actor >=60px")
func run() -> void:
	state=root.get_node("State"); state.developer_mode=true; state.d=state.initial()
	state.d.native.chapter=3; state.d.native.page="c3_canteen"; state.d.native.scene="canteen_interior"
	state.d.canteenHunt.active=true; state.d.canteenHunt.phase="exit_blocking"
	shell=load("res://scenes/main.tscn").instantiate(); root.add_child(shell); await frames()
	shell.set_process(false); shell.world.set_process(false)
	for view: Vector2i in [Vector2i(390,844),Vector2i(430,860),Vector2i(844,390),Vector2i(860,430)]:
		var game: Control=await open_activity(view)
		verify_layout(game)
		var world_before: Vector2=shell.world.player
		var story_before:=JSON.stringify(state.d)
		await tap(game.start_button)
		check(game.running and not game.start_button.visible,"real touch starts activity "+str(view))
		var stick: Vector2=game.stick_center
		finger_event(stick,0,true); finger_drag(stick+Vector2(45,0),0)
		var start: Vector2=game.model.player
		game._process(1.0/60); game._process(1.0/60)
		check(game.model.player.x>start.x and game.model.inputs[-1].x>0,"real root joystick moves through source physics")
		finger_event(game.dash_button.get_global_rect().get_center(),1,true)
		game._process(1.0/60)
		check(game.model.dash_remaining>0 and game.model.inputs[-1].dash,"second finger fires dash while first steers")
		finger_event(game.dash_button.get_global_rect().get_center(),1,false)
		finger_event(stick,0,false,true)
		check(game.touch_id==-1 and game.touch_direction==Vector2.ZERO,"canceled joystick releases axis")
		await tap(game.pause_button)
		var ticks: int=game.model.tick
		finger_event(stick+Vector2(45,0),0,true); game._process(1)
		check(game.paused and game.model.tick==ticks and game.touch_direction==Vector2.ZERO,"pause freezes timer and rejects new steering")
		finger_event(stick,0,false)
		await tap(game.start_button)
		check(not game.paused and game.touch_direction==Vector2.ZERO,"center resume has no stale gesture")
		press(KEY_D,true); game._process(1.0/60)
		game._notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
		game._process(1)
		check(game.paused and game.held.is_empty() and game.touch_direction==Vector2.ZERO,"window focus loss freezes and releases all inputs")
		press(KEY_D,false); await tap(game.pause_button)
		# Resize while a finger is held; old-screen drag/release cannot resume it.
		finger_event(stick,0,true); finger_drag(stick+Vector2(45,0),0)
		root.size=Vector2i(view.y,view.x); shell.size=Vector2(view.y,view.x); shell._layout(); await frames(2)
		check(game.touch_id==-1 and game.touch_direction==Vector2.ZERO and not game.pointer_down,"orientation change cancels old gesture")
		finger_drag(stick+Vector2(55,0),0); finger_event(stick,0,false)
		check(game.touch_direction==Vector2.ZERO,"stale drag after resize cannot move player")
		root.size=view; shell.size=Vector2(view); shell._layout(); await frames(2)
		# Context overview and header never start mouse movement.
		if game.portrait_layout:
			var point: Vector2=game.overview.get_global_rect().get_center(); motion(point); mouse(point,true)
			check(not game.pointer_down,"overview is context only")
			mouse(point,false)
		var point: Vector2=game.board_view.get_global_rect().get_center()+Vector2(20,0)
		motion(point); mouse(point,true)
		check(game.pointer_down and game.pointer_target.is_finite(),"mouse action view maps back to source coordinates")
		mouse(Vector2(-20,-20),false)
		check(not game.pointer_down,"release outside activity clears mouse movement")
		check(shell.world.player==world_before and JSON.stringify(state.d)==story_before,"activity gestures cannot alter exploration or story")
		# Let source simulation lose; native retry retains original failed trace/RNG.
		game.clear_input()
		while game.model.status=="running": game.model.step({"x":0,"y":0,"dash":false})
		game.refresh(); await frames(2)
		check(Rect2(Vector2.ZERO,Vector2(view)).encloses(game.hint.get_rect()),"failed-exit feedback stays inside screen")
		var attempt: Array=game.model.inputs.duplicate(true)
		await tap(game.retry_button)
		check(game.model.status=="running" and game.model.tick==0 and game.model.prior_attempts[-1]==attempt,"real retry preserves failed input trace and starts next source attempt")
		await tap(game.exit_button)
		check(not is_instance_valid(shell.active_game) and shell.world_frame.visible and shell.mobile_back.visible,"exit restores exploration controls")
	# Desktop restores unchanged authored dimensions after responsive use.
	var desktop: Control=await open_activity(Vector2i(1440,900))
	check(not desktop.compact_layout and desktop.size==Vector2(960,540),"desktop retains authored960x540 canvas")
	check(desktop.pause_button.get_rect()==Rect2(702,14,76,43) and desktop.dash_button.get_rect()==Rect2(793,445,141,68),"desktop authored button geometry preserved")
	check(not shell.phone.visible and not shell.world_frame.visible,"desktop phone/world hidden while defense owns scene")
	await tap(desktop.exit_button)
	check(shell.phone.visible and shell.world_frame.visible,"desktop phone/world restore after exit")
	# Prelude source cues survive real pause/resume and rotation at exact times.
	var game: Control=await open_activity(Vector2i(430,860),true)
	cues.clear(); game._pickup_elapsed=0; game._pickup_beat=0; game._pickup_tick(0)
	for i in range(85): game._process(.01)
	await tap(game.pause_button)
	var elapsed: float=game._pickup_elapsed
	root.size=Vector2i(860,430); shell.size=Vector2(860,430); shell._layout()
	for i in range(100): game._process(.01)
	check(game._pickup_elapsed==elapsed and game.paused,"source pickup clock frozen during pause and rotation")
	await tap(game.start_button)
	check(not game.paused and game._pickup_active,"central resume continues source prelude")
	while game._pickup_active: game._process(.01)
	for cue: Array in game.PICKUP_CUES:
		var found:=false
		for record: Dictionary in cues:
			if record.id==cue[1]: found=is_equal_approx(record.at,float(cue[0]))
		check(found,"exact prelude cue "+str(cue))
	check(is_equal_approx(game._pickup_elapsed,11380) and game.running and game.model.tick==0,"source11380ms pickup hands off without advancing simulation")
	check(cues.any(func(record): return record.id=="native_activity_resumed"),"resume emits matching audio-owner cue")
	await tap(game.exit_button)
	await shell.shutdown(); shell.queue_free(); await frames()
	print("CANTEEN_DEFENSE_MOBILE: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
