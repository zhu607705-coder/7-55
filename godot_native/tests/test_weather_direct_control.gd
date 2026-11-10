extends SceneTree
## Input is dispatched through the real Viewport. Only time is stepped manually.
const Game=preload("res://scripts/games/c3_weather.gd")
var checks:=0
var failures:=0
var game
var results: Array[Dictionary]=[]
var cancellations:=0
var original_touch_emulation: bool
func check(value: bool,message: String) -> void:
	checks+=1
	if not value: failures+=1; push_error("WEATHER INPUT: "+message)
func _initialize() -> void: run.call_deferred()
func make_game(extent:=Vector2(1280,720)) -> void:
	if is_instance_valid(game):
		game.queue_free(); await process_frame
	root.size=Vector2i(extent)
	game=Game.new(); root.add_child(game); game.set_process(false)
	game.scale=Vector2.ONE*minf((extent.x-20)/960,(extent.y-20)/540)
	game.position=Vector2(10,10)
	game._apply_presentation_layout(true)
	results.clear(); cancellations=0
	game.finished.connect(func(result: Dictionary): results.append(result))
	game.cancelled.connect(func(): cancellations+=1)
	await process_frame
func point(local: Vector2) -> Vector2: return game.get_global_transform_with_canvas()*local
func mouse(local: Vector2,pressed: bool,emulated:=false,canceled:=false) -> void:
	var event:=InputEventMouseButton.new()
	event.position=point(local); event.global_position=event.position
	event.button_index=MOUSE_BUTTON_LEFT; event.button_mask=MOUSE_BUTTON_MASK_LEFT if pressed else 0
	event.pressed=pressed; event.canceled=canceled
	if emulated: event.device=InputEvent.DEVICE_ID_EMULATION
	root.push_input(event,true)
func mouse_drag(local: Vector2,button_mask:=MOUSE_BUTTON_MASK_LEFT) -> void:
	var event:=InputEventMouseMotion.new()
	event.position=point(local); event.global_position=event.position; event.button_mask=button_mask
	root.push_input(event,true)
func touch(local: Vector2,index: int,pressed: bool,canceled:=false) -> void:
	var event:=InputEventScreenTouch.new()
	event.position=point(local); event.index=index; event.pressed=pressed; event.canceled=canceled
	root.push_input(event,true)
func touch_drag(local: Vector2,index: int) -> void:
	var event:=InputEventScreenDrag.new()
	event.position=point(local); event.index=index
	root.push_input(event,true)
func key(code: int,pressed: bool,echo:=false) -> void:
	var event:=InputEventKey.new()
	event.keycode=code; event.physical_keycode=code; event.pressed=pressed; event.echo=echo
	root.push_input(event,true)
func click(button: Button) -> void:
	var p: Vector2=button.position+button.size/2
	mouse(p,true); mouse(p,false)
func touch_navigation(button: Button) -> void:
	# Exercise Godot's actual touch -> mouse compatibility path for BaseButton,
	# rather than constructing mouse events and calling them touch coverage.
	var event:=InputEventScreenTouch.new()
	event.position=button.get_global_rect().get_center(); event.index=0; event.pressed=true
	Input.parse_input_event(event)
	var up=event.duplicate(); up.pressed=false; Input.parse_input_event(up)
	Input.flush_buffered_events()
func cancel_touch_navigation(button: Button) -> void:
	var event:=InputEventScreenTouch.new()
	event.position=button.get_global_rect().get_center(); event.index=0; event.pressed=true
	Input.parse_input_event(event)
	var drag:=InputEventScreenDrag.new(); drag.index=0; drag.position=Vector2(1,1)
	Input.parse_input_event(drag)
	var up=event.duplicate(); up.position=drag.position; up.pressed=false
	Input.parse_input_event(up); Input.flush_buffered_events()
func begin(is_touch:=false) -> void:
	if is_touch: touch_navigation(game.start_button)
	else: click(game.start_button)
	check(game.started and not game.paused,"real start button starts weather")
func step(count:=1,delta:=0.05) -> void:
	for i in count: game._process(delta)
func drag_to(band: int,destination: float,is_touch: bool) -> void:
	var center: Vector2=game.cloud_center(band)
	if is_touch: touch(center,7,true)
	else: mouse(center,true)
	var aim:=Vector2(game.TRACK_LEFT+destination*game.TRACK_UNIT,center.y)
	if is_touch: touch_drag(aim,7)
	else: mouse_drag(aim)
func release(is_touch: bool) -> void:
	# A captured release need not still be over the moving cloud.
	if is_touch: touch(Vector2(5,5),7,false)
	else: mouse(Vector2(5,5),false)
func solve(is_touch: bool) -> void:
	var acquired: int=-1
	for tick: int in range(1200):
		if game.settled: break
		if acquired>=0 and absf(game.positions[acquired]-(game.TARGET[acquired]+4.0))<1.0:
			release(is_touch); acquired=-1
		if acquired<0:
			var next_band: int=-1
			var distance: float=0
			for band: int in range(3):
				var error: float=absf(game.positions[band]-game.TARGET[band])
				if (error>6.0 or not game.controlled[band]) and error>distance:
					next_band=band; distance=error
			if next_band>=0:
				drag_to(next_band,game.TARGET[next_band]+4.0,is_touch)
				acquired=next_band
		step()
	check(results.size()==1,"ordinary %s input completes all three bands" % ("single-finger" if is_touch else "mouse"))
	if results.is_empty():
		print("UNSOLVED ",game.positions," control=",game.controlled," paused=",game.paused," owner=",game.pointer_owner)
		return
	var result: Dictionary=results[0]
	check(result.keys().size()==5 and result.has_all(["moves","cloudOffsets","controlledBands","stableMs","elapsedMs"]),"source result format retained")
	check(result.moves>=3 and result.controlledBands==[true,true,true],"every band receives a deliberate correction")
	check(result.stableMs==1000 and result.elapsedMs>=result.stableMs,"completion requires one continuous second")
	for band: int in range(3): check(absf(result.cloudOffsets[band]-game.TARGET[band])<=8,"submitted offsets remain in original tolerance")
	var elapsed_before: float=game.elapsed
	release(is_touch)
	if is_touch: touch_navigation(game.exit_button)
	else: click(game.exit_button)
	game._resume_shared_pause(); step(50)
	check(results.size()==1 and cancellations==0 and game.elapsed==elapsed_before,"success is terminal before host callback; no late cancel or second result")
	check(game.pointer_owner==game.NO_POINTER and game.directions==[0,0,0],"finish retires all input")
	print("WEATHER_COMPLETE mode=",("touch" if is_touch else "mouse")," viewport=",root.size," result=",result)
func run() -> void:
	original_touch_emulation=Input.emulate_mouse_from_touch
	Input.emulate_mouse_from_touch=true
	await make_game(Vector2(390,844))
	cancel_touch_navigation(game.start_button)
	check(not game.started and game.elapsed==0,"touch moving off Start before release does not activate")
	begin(true)
	touch_navigation(game.start_button)
	check(game.paused and game.shared_pause_overlay.is_open(),"native emulated touch opens Pause")
	touch_navigation(game.shared_pause_overlay.action_buttons[1])
	check(game.show_controls and game.shared_pause_overlay.body.visible,"native emulated touch opens requested Help")
	touch_navigation(game.shared_pause_overlay.resume_button)
	step(1,60.0)
	check(not game.paused and game.elapsed==0,"native emulated touch Continue clears the resume frame")
	touch_navigation(game.exit_button); step(40)
	check(cancellations==1 and results.is_empty(),"native emulated touch Return cancels without late success")
	await make_game()
	mouse(game.cloud_center(0),true); mouse_drag(game.cloud_center(0)-Vector2(80,0)); mouse(Vector2(5,5),false); step(3)
	check(not game.started and game.moves==0 and game.positions==[78.0,22.0,38.0],"clouds do not activate before explicit start")
	begin()
	var before: Array=game.positions.duplicate()
	drag_to(0,20,false)
	check(game.pointer_owner==game.MOUSE_POINTER and game.pointer_band==0,"visible cloud acquires mouse")
	check(game.positions==before,"pointer motion does not teleport the cloud")
	step()
	check(is_equal_approx(game.positions[0],before[0]+(-5.5-30.0)*.05),"drag uses exact source control speed plus wind")
	check(is_equal_approx(game.positions[1],before[1]-6.5*.05),"unowned band keeps original drift")
	check(game.controlled==[true,false,false] and game.moves==1,"drag records only the operated band")
	release(false); before=game.positions.duplicate(); step()
	check(game.pointer_owner==game.NO_POINTER and is_equal_approx(game.positions[0],before[0]-5.5*.05),"outside release stops force but retains normal wind")
	mouse(Vector2(game.TRACK_LEFT+game.TARGET[1]*game.TRACK_UNIT,game.row_centers[1]),true)
	check(game.pointer_owner==game.NO_POINTER,"clicking an empty target lane cannot acquire or auto-align a cloud")
	mouse(Vector2(5,5),false)
	# All six old keys remain equivalent, with no global polling after a pause.
	for band: int in range(3):
		for dir: int in [-1,1]:
			before=game.positions.duplicate()
			var code: int=game.KEYS[band][0 if dir<0 else 1]
			key(code,true); step(); key(code,false)
			check(is_equal_approx(game.positions[band],clampf(before[band]+(-game.WIND[band]+dir*30.0)*.05,2,98)),"old keyboard key preserves band, direction and speed")
	key(KEY_A,true); key(KEY_D,true); before=game.positions.duplicate(); step(); key(KEY_A,false); key(KEY_D,false)
	check(is_equal_approx(game.positions[1],before[1]-6.5*.05),"opposed keyboard sources cancel")
	await make_game(Vector2(390,844)); begin()
	drag_to(2,80,true)
	var aim: float=game.pointer_target
	touch(game.cloud_center(0),12,true); touch_drag(Vector2(850,game.row_centers[2]),12); touch(Vector2(5,5),12,false)
	mouse(game.cloud_center(1),true,true); mouse(game.cloud_center(1),false,true)
	check(game.pointer_owner==7 and game.pointer_band==2 and game.pointer_target==aim,"second finger and emulated mouse cannot steal the gesture")
	key(KEY_Q,true); step(); key(KEY_Q,false)
	check(game.directions[2]==1,"captured pointer owns its band over conflicting keyboard")
	touch(Vector2(5,5),7,false,true)
	var frozen: Array=game.positions.duplicate(); var time: float=game.elapsed
	step(30)
	check(game.paused and game.pointer_owner==game.NO_POINTER and game.directions==[0,0,0],"touch cancel clears ownership and pauses")
	check(game.positions==frozen and game.elapsed==time and results.is_empty(),"canceled gesture cannot accumulate a delayed success")
	# Continue through the real shared overlay, then discard the resume delta.
	var resume:=InputEventMouseButton.new(); resume.position=game.shared_pause_overlay.resume_button.get_global_rect().get_center(); resume.global_position=resume.position; resume.button_index=MOUSE_BUTTON_LEFT; resume.pressed=true
	root.push_input(resume,true); var up=resume.duplicate(); up.pressed=false; root.push_input(up,true)
	check(not game.paused,"shared Continue is reachable after touch cancellation")
	step(1,60.0)
	check(game.elapsed==time and game.positions==frozen,"first resume frame never catches up background time")
	touch(game.cloud_center(1),9,true); touch_drag(game.cloud_center(1)+Vector2(70,0),9)
	check(game.pointer_owner==9,"fresh gesture works after cancel and resume")
	game.stable=350
	game._notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT)
	time=game.elapsed; step(5)
	check(game.paused and game.held_keys.is_empty() and game.pointer_owner==game.NO_POINTER and game.elapsed==time,"focus loss releases and freezes")
	check(game.stable==350,"ordinary pause freezes accumulated stable time")
	game._resume_shared_pause(); step()
	drag_to(0,40,false); game.hide(); step(3)
	check(game.paused and game.pointer_owner==game.NO_POINTER,"hiding activity releases owned drag")
	game.show(); game._resume_shared_pause(); step()
	key(KEY_C,true); paused=true; await process_frame
	check(game.paused and game.held_keys.is_empty() and game.directions==[0,0,0],"SceneTree pause cancels held keyboard")
	paused=false; game._resume_shared_pause(); step()
	drag_to(0,40,false); mouse_drag(game.cloud_center(0)-Vector2(30,0),0)
	check(game.paused and game.pointer_owner==game.NO_POINTER,"lost mouse button capture cancels cleanly")
	game._resume_shared_pause(); step(); drag_to(0,40,false)
	mouse_drag(Vector2(-20,-20))
	check(game.paused and game.pointer_owner==game.NO_POINTER,"drag beyond the activity pauses without sticking")
	game._resume_shared_pause(); step(); drag_to(0,40,true)
	root.size=Vector2i(844,390); game.scale=Vector2.ONE*minf(824.0/960,370.0/540); game._process(.05)
	check(game.paused and game.pointer_owner==game.NO_POINTER,"rotation invalidates old input coordinates")
	game._resume_shared_pause(); step(); drag_to(1,70,true)
	check(game.pointer_band==1,"new touch hits visible cloud after rotation")
	touch(Vector2(5,5),7,false)
	click(game.start_button)
	check(game.paused and game.shared_pause_overlay.is_open(),"visible Pause button retains explicit pause path")
	var help: Button=game.shared_pause_overlay.action_buttons[1]
	var help_down:=InputEventMouseButton.new(); help_down.position=help.get_global_rect().get_center(); help_down.global_position=help_down.position; help_down.button_index=MOUSE_BUTTON_LEFT; help_down.pressed=true
	root.push_input(help_down,true); var help_up=help_down.duplicate(); help_up.pressed=false; root.push_input(help_up,true)
	check(game.show_controls and game.shared_pause_overlay.body.visible and "Q/E" in game.shared_pause_overlay.body.text and "A/D" in game.shared_pause_overlay.body.text and "Z/C" in game.shared_pause_overlay.body.text,"requested help exposes retained keyboard bindings in existing pause surface")
	game._cancel_game(); step(50); game._cancel_game(); game._resume_shared_pause(); step(30)
	check(cancellations==1 and results.is_empty() and game.settled,"return during pause is terminal and emitted once")
	await make_game(); click(game.exit_button); game._resume_shared_pause(); step(100)
	check(cancellations==1 and results.is_empty() and not game.started,"return before start cannot later complete")
	await make_game(); begin(); drag_to(0,40,true); click(game.exit_button); step(100)
	check(cancellations==1 and results.is_empty() and game.pointer_owner==game.NO_POINTER,"return during drag clears input before cancellation")
	await make_game(); begin(); step(1200)
	check(results.is_empty() and game.controlled==[false,false,false],"waiting alone cannot win")
	# Deliberate taps without a drag do not satisfy the three-operated-band gate.
	for band: int in range(3): touch(game.cloud_center(band),7,true); touch(Vector2(5,5),7,false)
	step()
	check(game.moves==0 and game.controlled==[false,false,false],"tap-only inspection is not a correction")
	# Out-of-zone motion clears an almost-stable attempt, retaining a retry path.
	game.positions=[34.0,52.0,70.0]; game.stable=950
	key(KEY_E,true); step(20); key(KEY_E,false)
	check(game.stable==0 and results.is_empty() and not game.settled,"leaving a target resets stability without ending the attempt")
	for extent: Vector2 in [Vector2(1280,720),Vector2(1024,768),Vector2(390,844),Vector2(844,390)]:
		for is_touch: bool in [false,true]:
			await make_game(extent); begin(is_touch); solve(is_touch)
	# Same object may be reset for a new host session; no old keys or ownership.
	game.setup({}); step(5)
	check(not game.settled and not game.started and game.moves==0 and game.elapsed==0 and game.positions==[78.0,22.0,38.0] and game.controlled==[false,false,false],"explicit re-entry resets only local session state")
	game.queue_free(); await process_frame
	Input.emulate_mouse_from_touch=original_touch_emulation
	print("Weather direct control: ",checks," checks / ",failures," failures")
	quit(1 if failures else 0)
