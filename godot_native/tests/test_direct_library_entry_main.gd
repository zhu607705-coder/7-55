extends "res://tests/test_portrait_exploration.gd"
## A declared retained checkpoint; all approach, record and passage actions
## below use real root touch events and the existing Main/controller chain.
const Metrics=preload("res://scripts/player_metrics.gd")
func source_screen(point:Vector2)->Vector2:return world_screen((point-shell.world.camera)*shell.world.zoom+shell.world.size/2)
func tap(point:Vector2)->void:
	motion(point);touch(point,true);touch(point,false);await frames(3)
func key(code:int)->void:
	var e:=InputEventKey.new();e.keycode=code;e.physical_keycode=code;e.pressed=true;event(e);e=e.duplicate();e.pressed=false;event(e);await frames(3)
func source_fixture()->void:
	state.developer_mode=true;check(state.begin_checkpoint("c2-entrance-record"),"retained source entrance checkpoint")
	state.d.native.player={"scene":"library_interior","x":715.0,"y":842.0};state.d.native.positions={"library_interior:":{"x":715.0,"y":842.0}}
	state.d.ui.controlCenterOpen=false;state.developer_mode=false
func approach()->void:
	await tap(source_screen(Vector2(750,727)))
	check(not shell.world._floor_pending_interaction.is_empty() and not shell.world._floor_route.is_empty(),"far entity tap owns actual source navigation")
	check(state.d.native.page!="library_record","approach does not submit the record action before reaching its source radius")
func record_action()->Button:
	# The original Zjuding app entry owns its loading interval. Let that real
	# session finish before expecting a newly opened record page's controls.
	for i:int in range(40):
		var button:Button=shell.find_child("LibraryRecordAction",true,false)
		if is_instance_valid(button) and button.is_visible_in_tree():return button
		await create_timer(.05).timeout
	return null
func run()->void:
	check(load("res://tests/native_test_isolation.gd").is_isolated_save(),"isolated root event test")
	state=root.get_node("State");state.action_completed.connect(func(id,_a,_b,_c):actions.append(id))
	for extent:Vector2i in [Vector2i(390,844),Vector2i(844,390),Vector2i(1280,720)]:
		source_fixture();root.size=extent;shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames(6)
		shell._show_world_mobile();await frames();shell.world.set_process(false);actions.clear()
		var w:Control=shell.world
		check(w.player==Vector2(715,842) and w.can_stand(w.player) and not state.d.ui.libraryFinalsPuzzle.entranceRecordRead,"authored physical entrance spawn and locked original record "+str(extent))
		await approach()
		var step:=0
		while not w._floor_route.is_empty() and step<250:
			var before:Vector2=w.player;w._process(.016);step+=1
			check(w.can_stand(w.player) and before.distance_to(w.player)<=165*.016+.001,"source collision body walks at its original speed")
		await frames(4)
		check(step<250 and actions.count("lib_open_record")==1 and state.d.native.page=="library_record" and not state.d.ui.libraryFinalsPuzzle.entranceRecordRead,"arrival submits exactly one original record-page intent")
		var record:Button=await record_action()
		if not is_instance_valid(record) or not record.is_visible_in_tree():print("DIRECT_RECORD_UI_DIAGNOSTIC ",JSON.stringify({"view":extent,"page":state.d.native.page,"phase":state.d.ui.libraryFinalsPhase,"phoneVisible":shell.phone.visible,"worldVisible":shell.world_frame.visible,"mobileWorld":shell.mobile_world,"recordExists":is_instance_valid(record),"recordVisible":record.is_visible_in_tree() if is_instance_valid(record) else false,"actions":state.get_actions("library_record"),"last":state.last_result,"pending":w._floor_pending_interaction}))
		check(is_instance_valid(record) and record.is_visible_in_tree(),"original record confirmation is visible")
		if is_instance_valid(record):await tap(record.get_global_rect().get_center())
		check(state.d.ui.libraryFinalsPuzzle.entranceRecordRead and state.d.ui.libraryFinalsPuzzle.clueIds.count("arrival_7_minutes")==1,"real touch confirmation earns original evidence exactly once")
		await tap(shell.phone_world_return.get_global_rect().get_center());shell.world.set_process(false)
		for i:int in range(12):w._process(.05)
		check(w.library_door.progress==1 and w.can_stand(Vector2(715,710)),"original record fact opens the actual glass passage")
		await tap(source_screen(Vector2(715,673.1875)))
		check(not w._floor_route.is_empty() and w._floor_pending_interaction.is_empty(),"direct interior floor tap walks without a queued entity action")
		step=0
		while not w._floor_route.is_empty() and step<250:
			w._process(.016);step+=1;check(w.can_stand(w.player),"opened door traversal retains exact player body")
		check(w.player.y<700 and actions.count("lib_open_record")==1 and not state.d.ui.libraryFinalsPuzzle.backpackInspected and state.d.ui.libraryFinalsPhase=="library_entered","pure touch crosses the original entrance while preserving later story gates")
		# The free source floor between record and exit is narrow on coarse input.
		# Choose an unpainted point outside both expanded target affordances; the
		# complete foot box fits above the short landscape feedback surface.
		await tap(source_screen(Vector2(715,790)))
		check(not w._floor_route.is_empty(),"real root return tap on fully visible empty floor owns a physical route")
		step=0
		while not w._floor_route.is_empty() and step<250:
			w._process(.016);step+=1;check(w.scene_id=="library_interior" and w.can_stand(w.player),"return route retains library scene and exact source collision body")
		check(w.scene_id=="library_interior" and Metrics.foot_rect(w.player).position.y>748 and w.player.y>755 and actions.count("lib_open_record")==1 and actions.count("lib_exit")==0,"real root return fully crosses open source leaf without selecting the nearby exit")
		await shell.shutdown();shell.free();await frames()
	# F10 is an actual interruption of a pending approach, not a pause/resume
	# promise. Closing the panel must never replay that old target intent.
	source_fixture();root.size=Vector2i(844,390);shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames(6);shell._show_world_mobile();await frames();shell.world.set_process(false);actions.clear()
	await approach();await key(KEY_F10)
	check(is_instance_valid(shell.modal) and shell.world._floor_pending_interaction.is_empty() and shell.world._floor_route.is_empty(),"real F10 retires pending navigation and its action owner")
	var close:Button
	for button in shell.modal.find_children("*","Button",true,false):
		if button.text=="关闭":close=button;break
	check(is_instance_valid(close),"settings has its ordinary visible close action")
	if is_instance_valid(close):await tap(close.get_global_rect().get_center())
	for i:int in range(120):shell.world._process(.016)
	check(actions.count("lib_open_record")==0 and not state.d.ui.libraryFinalsPuzzle.entranceRecordRead,"closing a cancelled approach panel never submits a stale record request")
	await shell.shutdown();shell.free();await frames()
	print("DIRECT_LIBRARY_ENTRY_MAIN: %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
