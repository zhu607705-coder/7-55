extends SceneTree
const Model=preload("res://scripts/objects/room302_studio_model.gd")
var checks:=0
var failures:=0
var events:Array=[]
var panel:Control
func _initialize()->void:run.call_deferred()
func check(value:bool,label:String)->void:
	checks+=1
	if not value:failures+=1;push_error(label)
func frames(n:=2)->void:
	for i in range(n):await process_frame
func touch(index:int,pressed:bool,point:Vector2,canceled:=false,device:=0)->void:
	var input:=InputEventScreenTouch.new();input.index=index;input.pressed=pressed;input.position=point;input.canceled=canceled;input.device=device
	panel.view._gui_input(input)
func mouse(pressed:bool,point:Vector2,device:=0)->void:
	var input:=InputEventMouseButton.new();input.button_index=MOUSE_BUTTON_LEFT;input.pressed=pressed;input.position=point;input.device=device
	panel.view._gui_input(input)
func reset_reply(state:Dictionary)->void:
	panel.resolve_studio_event(state,{"message":""})
func run()->void:
	root.size=Vector2i(1180,812)
	var state:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/room302_earned_film_entry.json")).state
	state.native.c4_context="media_alignment"
	var cp:Dictionary=Model.initial()
	cp=Model.transition(cp,{"kind":"swap","a":0,"b":2}).checkpoint
	cp=Model.transition(cp,{"kind":"swap","a":1,"b":2}).checkpoint
	state.native.c4_media_studio=cp
	panel=load("res://scripts/objects/room302_studio_panel.gd").new()
	check(panel.configure("media_alignment",state),"Curtain pointer fixture uses valid original film authority")
	root.add_child(panel);await frames(3)
	panel.studio_event_requested.connect(func(event:Dictionary):events.append(event))
	var point:Vector2=panel.view.origin+panel.view.curtain_rect().get_center()*panel.view.fit
	touch(4,true,point)
	check(panel.view.dragging and panel.view.pointer_index==4,"First touch owns cloth drag")
	touch(5,true,point+Vector2(15,0));touch(5,false,point+Vector2(90,0))
	check(events.is_empty() and panel.view.dragging and panel.view.pointer_index==4,"Second finger cannot replace or release first drag")
	touch(5,false,point,true)
	check(panel.view.dragging,"Non-owner touch cancellation preserves owner")
	mouse(false,point+Vector2(90,0))
	check(events.is_empty() and panel.view.dragging,"Mouse release cannot finish touch gesture")
	touch(4,false,point+Vector2(90,0),false,2)
	check(events.is_empty() and panel.view.dragging,"Other touch device cannot finish same index")
	touch(4,false,point+Vector2(90,0))
	check(events.size()==1 and events.back()=={"kind":"step","axis":"xOffset","delta":1} and not panel.view.dragging,"Owner release commits exactly one bounded step")
	reset_reply(state);events.clear()
	touch(4,false,point+Vector2(90,0))
	check(events.is_empty(),"Duplicate release never repeats operation")
	touch(2,true,point);touch(2,false,point+Vector2(90,0),true)
	check(events.is_empty() and not panel.view.dragging and panel.view.pointer_kind.is_empty(),"Owner canceled touch clears without dispatch")
	mouse(true,point,-1);mouse(false,point+Vector2(90,0),-1)
	check(events.is_empty() and not panel.view.dragging,"Emulated mouse following touch cannot duplicate gesture")
	mouse(true,point);touch(3,false,point+Vector2(90,0));mouse(false,point+Vector2(90,0))
	check(events.size()==1 and panel.view.pointer_kind.is_empty(),"Real mouse owns its release independently of unrelated touch")
	reset_reply(state);events.clear()
	for boundary:String in ["resize","focus","mode","hide","explicit_cancel"]:
		point=panel.view.origin+panel.view.curtain_rect().get_center()*panel.view.fit
		touch(7,true,point)
		match boundary:
			"resize":panel.layout_fullscreen(Rect2(Vector2.ZERO,Vector2(1024,768)))
			"focus":panel._notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
			"mode":panel.set_input_mode("touch")
			"hide":panel.hide();panel.show()
			"explicit_cancel":panel.cancel_input()
		touch(7,false,point+Vector2(90,0))
		check(events.is_empty() and not panel.view.dragging,"Lifecycle "+boundary+" cancels pointer without changing checkpoint")
	check(panel.checkpoint==cp,"Canceled input preserves accepted checkpoint")
	panel.set_input_mode("keyboard");panel.close_button.grab_focus();await frames()
	var key:=InputEventKey.new();key.pressed=true;key.keycode=KEY_ENTER
	check(not panel.handle_key(key) and events.is_empty(),"Focused Return retains native Enter dispatch")
	key.keycode=KEY_KP_ENTER;check(not panel.handle_key(key),"Focused Return retains keypad Enter dispatch")
	key.keycode=KEY_SPACE;check(not panel.handle_key(key),"Focused Return retains Space dispatch")
	panel.grab_focus();key.keycode=KEY_RIGHT
	check(panel.handle_key(key) and events.size()==1,"Gameplay keyboard emits one controller request")
	reset_reply(state);events.clear()
	var stale:Dictionary=state.duplicate(true);stale.native.scene="library_interior"
	check(not panel.sync_authority(stale),"Scene change rejects stale studio authority")
	panel.sync_authority(state)
	point=panel.view.origin+panel.view.curtain_rect().get_center()*panel.view.fit
	touch(9,true,point);panel.dispose_session();touch(9,false,point+Vector2(90,0))
	check(events.is_empty() and not panel.view.dragging and not panel.session.opened,"Actual disposal clears pointer and closes session without dispatch")
	panel.queue_free();await frames()
	print("ROOM302_STUDIO_INPUT: %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
