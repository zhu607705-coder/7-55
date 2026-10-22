extends SceneTree
const Model=preload("res://scripts/objects/room201_press_model.gd")
const PressPanel=preload("res://scripts/objects/room201_press_panel.gd")
var checks:=0
var failures:=0
var events:Array=[]
var submissions:Array=[]
var panel:Control
var state:Dictionary
func _initialize()->void:run.call_deferred()
func check(value:bool,label:String)->void:
	checks+=1
	if not value:failures+=1;push_error(label)
func frames(n:=2)->void:
	for i in range(n):await process_frame
func touch(index:int,pressed:bool,point:Vector2,canceled:=false,device:=0)->void:
	var event:=InputEventScreenTouch.new();event.index=index;event.pressed=pressed;event.position=point;event.canceled=canceled;event.device=device;panel.view._gui_input(event)
func mouse(pressed:bool,point:Vector2,device:=0)->void:
	var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed;event.position=point;event.device=device;panel.view._gui_input(event)
func answer()->void:
	if not events.is_empty():
		var result:Dictionary=Model.transition(state.native.get("c4_plate_press",Model.initial()),events.back())
		if result.accepted:state.native.c4_plate_press=result.checkpoint
		panel.resolve_press_event(state,{"message":result.message,"press_motion":result.motion})
		panel.view.motion="";panel._refresh_view()
	events.clear()
func point(at:Vector2)->Vector2:return panel.view.origin+at*panel.view.fit
func run()->void:
	root.size=Vector2i(1180,812)
	var owner:Node=root.get_node("State")
	owner.d=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/room201_projection_entry.json")).state
	owner.act("c4_plate");owner.act("c4_device_positioning_calibration");state=owner.d.duplicate(true)
	panel=PressPanel.new();check(panel.configure("positioning_calibration",state),"Press accepts original positioning context")
	root.add_child(panel);await frames(3)
	panel.press_event_requested.connect(func(event:Dictionary):events.append(event))
	panel.submit_requested.connect(func(action:String,value:Dictionary,serial:int):submissions.append({"action":action,"value":value,"serial":serial}))
	check(panel.frame==null and panel.uses_exclusive_game_viewport(),"Press uses exclusive viewport without nested form")
	var at:Vector2=point(panel.view.loose_center)
	touch(4,true,at);check(panel.view.gesture=="plate","Actual loose plate owns insertion gesture")
	touch(4,false,at+Vector2(0,100),true);check(events.is_empty() and not panel.view.dragging,"Canceled plate drag never inserts")
	touch(4,true,at);touch(4,false,point(panel.view.center))
	check(events==[{"kind":"insert"}],"Dragging plate into slot requests insert once")
	check(not panel.checkpoint.inserted,"Insertion waits for authority")
	answer();check(panel.checkpoint.inserted,"Accepted checkpoint installs plate")
	at=point(panel.view.carriage_center())
	touch(4,true,at);check(panel.view.dragging and panel.view.pointer_index==4,"First touch owns carriage")
	touch(5,true,at+Vector2(15,0));touch(5,false,at+Vector2(90,0));touch(5,false,at,true)
	check(events.is_empty() and panel.view.dragging and panel.view.pointer_index==4,"Other finger cannot replace, release or cancel owner")
	mouse(false,at+Vector2(90,0));touch(4,false,at+Vector2(90,0),false,2)
	check(events.is_empty() and panel.view.dragging,"Mouse or other device cannot release owner")
	touch(4,false,at+Vector2(90,0));touch(4,false,at+Vector2(90,0))
	check(events==[{"kind":"step","axis":"horizontal","delta":1}] and not panel.view.dragging,"Owner release commits exactly one bounded detent")
	answer();mouse(true,at,-1);mouse(false,at+Vector2(90,0),-1);check(events.is_empty(),"Touch-emulated mouse cannot duplicate movement")
	mouse(true,at);mouse(false,at+Vector2(0,-90));check(events==[{"kind":"step","axis":"vertical","delta":-1}],"Real mouse drags vertical rail");answer()
	for boundary:String in ["resize","focus","mode","hide","explicit_cancel"]:
		at=point(panel.view.carriage_center());touch(7,true,at)
		match boundary:
			"resize":panel.layout_fullscreen(Rect2(Vector2.ZERO,Vector2(1024,768)))
			"focus":panel._notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
			"mode":panel.set_input_mode("touch")
			"hide":panel.hide();panel.show()
			"explicit_cancel":panel.cancel_input()
		touch(7,false,at+Vector2(90,0));check(events.is_empty() and not panel.view.dragging,"Lifecycle "+boundary+" cancels gesture")
	panel.set_input_mode("keyboard");panel.close_button.grab_focus();await frames()
	var key:=InputEventKey.new();key.pressed=true
	for code:int in [KEY_ENTER,KEY_KP_ENTER,KEY_SPACE]:key.keycode=code;check(not panel.handle_key(key),"Return button retains keyboard activation")
	panel.grab_focus();key.keycode=KEY_E;check(panel.handle_key(key) and events==[{"kind":"step","axis":"pressure","delta":1}],"E winds one spring detent");answer()
	key.keycode=KEY_Q;panel.handle_key(key);check(events==[{"kind":"step","axis":"pressure","delta":-1}],"Q unwinds spring");answer()
	at=point(panel.view.wheel+Vector2(30,0));mouse(true,at);mouse(false,at);check(events==[{"kind":"step","axis":"pressure","delta":1}],"Wheel right rim winds spring");answer()
	at=point(panel.view.wheel-Vector2(30,0));mouse(true,at);mouse(false,at);check(events==[{"kind":"step","axis":"pressure","delta":-1}],"Wheel left rim unwinds spring");answer()
	at=point(panel.view.lever_handle());mouse(true,at);mouse(false,at+Vector2(0,50))
	check(submissions.size()==1 and submissions[0].action=="c4_solve_positioning_calibration" and submissions[0].value==panel.checkpoint.calibration,"Lever submits exact accepted calibration to existing solver")
	check(panel.session.pending and panel.view.motion=="press" and not panel.can_close(),"Outstanding press locks input")
	var before:Dictionary=panel.checkpoint.duplicate(true)
	panel.resolve_submission(submissions[0].serial,state,{"message":"三处触点没有同时套入旧痕。"})
	check(panel.view.press_outcome=="bounce" and panel.view.dent and panel.checkpoint==before,"Wrong press dents and preserves adjustments")
	panel.view.motion="";panel._refresh_view()
	for dim:Vector2i in [Vector2i(1280,720),Vector2i(390,844),Vector2i(430,860),Vector2i(844,390)]:
		panel.layout_fullscreen(Rect2(Vector2.ZERO,Vector2(dim)))
		check(panel.view.play_area.grow(.01).encloses(Rect2(panel.view.origin,panel.view.design_size*panel.view.fit)),"Machine fits play area at "+str(dim))
		for handle:Dictionary in panel.view.rail_handles():check(panel.view.play_area.has_point(point(handle.point)),"Rail grip visible at "+str(dim))
		check(panel.view.play_area.has_point(point(panel.view.lever_handle())) and panel.view.play_area.has_point(point(panel.view.wheel)),"Lever and wheel visible at "+str(dim))
	var invalid:Dictionary=state.duplicate(true);invalid.chapter4.timeState="2245_opening";check(not panel.sync_authority(invalid),"Time change rejects stale authority")
	panel.sync_authority(state);invalid=state.duplicate(true);invalid.items.clockPositioningPlate=false;panel.sync_authority(invalid)
	check(not panel.view.interactive and not panel._editable(),"Losing prerequisite locks input")
	panel.sync_authority(state);state.chapter4.factIds.append("a2_positioning_plate_calibrated");state.native.erase("c4_plate_press")
	check(panel.sync_authority(state) and panel.session.completed and panel.checkpoint.imprinted and not panel.view.interactive,"Legacy completed fact displays success without checkpoint")
	check(not state.native.has("c4_plate_press"),"Completed display never backfills save")
	panel.dispose_session();check(not panel.session.opened and not panel.view.dragging,"Disposal clears pointer and session")
	panel.queue_free();await frames()
	print("ROOM201_PRESS_INPUT: %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
