extends "res://tests/test_portrait_exploration.gd"
## A declared retained checkpoint; all approach, record and passage actions
## below use real root touch events and the existing Main/controller chain.
const Metrics=preload("res://scripts/player_metrics.gd")
const Gate=preload("res://scripts/presentation/library_turnstiles.gd")
const RECORD_HINT="刚刷过卡。打开浙大钉里的图书馆，到座位预约的「我的」里查入馆记录。"
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
	await tap(source_screen(shell.world.library_gate.reader_rect(1).get_center()))
	check(not shell.world._floor_pending_interaction.is_empty() and not shell.world._floor_route.is_empty(),"far entity tap owns actual source navigation")
	check(state.d.native.page!="library_record","approach does not submit the record action before reaching its source radius")
func tap_control(node_name: String) -> void:
	for frame in 120:
		var control := shell.find_child(node_name,true,false) as Button
		if is_instance_valid(control) and control.is_visible_in_tree() and not control.disabled:
			await tap(control.get_global_rect().get_center())
			return
		await create_timer(.025).timeout
	check(false,"visible touch control "+node_name)
func run()->void:
	check(load("res://tests/native_test_isolation.gd").is_isolated_save(),"isolated root event test")
	state=root.get_node("State");state.action_completed.connect(func(id,_a,_b,_c):actions.append(id))
	var feedback: Array[String]=[]
	state.feedback.connect(func(message: String): feedback.append(message))
	for extent:Vector2i in [Vector2i(390,844),Vector2i(844,390),Vector2i(1280,720)]:
		source_fixture();root.size=extent;shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames(6)
		shell._show_world_mobile();await frames();shell.world.set_process(false);actions.clear();feedback.clear()
		var w:Control=shell.world
		check(w.player==Vector2(715,842) and w.can_stand(w.player) and not state.d.ui.libraryFinalsPuzzle.entranceRecordRead,"authored physical entrance spawn and locked original record "+str(extent))
		await tap(source_screen(w.library_gate.reader_rect(0).get_center()))
		var step:=0
		while not w._floor_route.is_empty() and step<250:
			var before:Vector2=w.player;w._process(.016);step+=1
			check(w.can_stand(w.player) and before.distance_to(w.player)<=165*.016+.001,"source collision body walks at its original speed")
		for i:int in range(16):w._process(.05)
		var axis_y: float = w.library_gate.axis_y
		check(w.library_gate.lanes[0].progress==1 and w.library_gate.lanes[1].progress==0 and w.can_stand(Metrics.anchor_from_foot_center(Vector2(715,axis_y))),"first swipe opens only the touched lane")
		check(not is_instance_valid(shell.modal) and state.get_view("library_record").body=="暂无入馆记录" and state.get_actions("library_record").is_empty(),"opening the wing does not issue a record before passage")
		check(not feedback.has(RECORD_HINT),"swipe alone does not prompt for the entry record")
		await tap(source_screen(Vector2(715,755)))
		check(not w._floor_route.is_empty() and w._floor_pending_interaction.is_empty(),"direct interior floor tap walks without a queued entity action")
		step=0
		while not w._floor_route.is_empty() and step<250:
			w._process(.016);step+=1;check(w.can_stand(w.player),"opened door traversal retains exact player body")
		var feet:=Metrics.foot_rect(w.player,w.scene_id)
		check(feet.size==Vector2(36,10) and feet.end.y<axis_y and actions.count("lib_register_arrival")==1 and state.d.native.get("lib_admission_recorded",false),"the body-width feet pass the gate and record one arrival")
		check(feedback.count(RECORD_HINT)==1 and shell.notice_surface=="world" and w.subtitle==RECORD_HINT,"first physical entry shows its phone route in the map dialogue lane")
		check(not state.d.ui.libraryFinalsPuzzle.entranceRecordRead and not state.d.ui.libraryFinalsPuzzle.backpackInspected,"crossing the gate does not acknowledge the record")
		var saved: Dictionary = state._read_native_save(state.SAVE_PATH).get("state",{})
		check(saved.get("native",{}).get("lib_admission_recorded",false) and not saved.get("ui",{}).get("libraryFinalsPuzzle",{}).get("entranceRecordRead",true),"ordinary save stores the arrival with an unread record")
		for i in 20: w._process(.05)
		check(w.library_gate.lanes[0].progress==0,"inbound lane closes after the body clears it")
		var arrival: Vector2 = w.player
		for name in ["WorldPhoneButton","HomeApp_zjuding","ZjudingApp_library","LibraryApp_reserve","LibraryReservationMyTab","LibraryEntranceRecord"]:
			await tap_control(name)
		check(state.d.native.page=="library_record" and shell.phone.visible and not shell.world_frame.visible,"seat reservation opens the record on the phone")
		check(not shell.toast.visible or shell.toast.text!=RECORD_HINT,"map arrival hint never overlays the phone")
		var evidence := shell.page_body.find_child("LibraryRecordEvidence",true,false) as Label
		check(is_instance_valid(evidence) and "07:55 从紫云五舍出发" in evidence.text and "08:02 刷卡进基础图书馆" in evidence.text and not state.d.ui.libraryFinalsPuzzle.entranceRecordRead,"the original record identifies both travel endpoints without acknowledging itself")
		await tap_control("PhoneNav_back")
		check(state.d.native.page=="library_app" and not state.d.ui.libraryFinalsPuzzle.entranceRecordRead,"record back returns to My without confirming")
		await tap_control("LibraryEntranceRecord")
		await tap_control("LibraryRecordAction")
		check(actions.count("lib_record")==1 and state.d.ui.libraryFinalsPuzzle.entranceRecordRead and state.d.ui.libraryFinalsPuzzle.clueIds.count("arrival_7_minutes")==1 and not state.d.ui.libraryFinalsPuzzle.backpackInspected,"real touch confirmation earns the existing clue exactly once")
		await key(KEY_ENTER)
		await key(KEY_ENTER)
		check(not shell.library_story_host.blocks_input(),"record dialogue releases navigation after both lines")
		await tap_control("PhoneNav_back")
		await tap_control("LibraryEntranceRecord")
		check(state.d.native.page=="library_record" and not is_instance_valid(shell.page_body.find_child("LibraryRecordAction",true,false)),"confirmed record remains available for review")
		await tap_control("PhoneWorldReturn")
		check(shell.world_frame.visible and w.player==arrival and w.library_gate.lanes[0].progress==0,"phone return preserves the closed gate and the same player position")
		shell.world.set_process(false)
		await tap(source_screen(Vector2(715,axis_y-30)))
		for i in 24: w._process(.05)
		check(w.library_gate.lanes[0].direction==1 and w.library_gate.lanes[0].progress==1,"walking toward the inside sensor opens outward")
		await tap(source_screen(Vector2(726,880)))
		check(not w._floor_route.is_empty(),"real root return tap on fully visible empty floor owns a physical route")
		step=0
		while not w._floor_route.is_empty() and step<250:
			w._process(.016);step+=1;check(w.scene_id=="library_interior" and w.can_stand(w.player),"return route retains library scene and exact source collision body")
		check(w.scene_id=="library_interior" and w.library_gate.outside(w.player) and actions.count("lib_register_arrival")==1 and actions.count("lib_record")==1 and actions.count("lib_exit")==0,"real root touch returns through the wing without registering another arrival " + str([extent, w.player, w._floor_status, actions]))
		check(feedback.count(RECORD_HINT)==1,"entry cue is issued once across arrival, phone and exit")
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
	check(shell.world.library_gate.lanes[1].phase==Gate.Phase.CLOSED and not state.d.native.get("lib_admission_recorded",false),"closing a cancelled approach panel never submits a stale swipe")
	await shell.shutdown();shell.free();await frames()
	print("DIRECT_LIBRARY_ENTRY_MAIN: %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
