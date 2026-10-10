extends SceneTree
const ArchivePanel=preload("res://scripts/objects/room301_archive_panel.gd")
const Chapter=preload("res://scripts/chapters/chapter4.gd")
const Motion=preload("res://scripts/objects/room301_archive_motion.gd")
var checks:=0
var failures:=0
var submissions:Array=[]
var choices:Array=[]
var handoffs:Array=[]
var panel:Control
var state:Dictionary
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error("ROOM301_INDEX: "+label)
func frames(n:=2)->void:
	for i in range(n):await process_frame
func initial(mode:="light")->Dictionary:
	var value:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/initial_state.json"))
	value.native={"chapter":4,"scene":"duan_yongping_temporal_maze","mode":mode,"c4_context":"archive_index","settings":{}}
	value.chapter4.prologueSeen=true;value.chapter4.phase="room204_restore";value.chapter4.timeState="1850_evening";value.chapter4.floor="A3";value.chapter4.mode=mode;value.chapter4.factIds=[]
	return value
func point(row:int)->Vector2:return panel.view.index_targets[row].rect.get_center()
func value(row:int)->String:return str(panel.session.draft[panel.view.DRAFT_KEYS[row]])
func gesture(row:int,delta:=Vector2.ZERO,kind:="mouse",index:=0,device:=0)->void:
	var at:=point(row)
	panel.view._owned_pointer(kind,index,true,at,false,device)
	panel.view._owned_pointer(kind,index,false,at+delta,false,device)
func choose(row:int,desired:String)->void:
	for attempt in range(4):
		if value(row)==desired:return
		gesture(row)
	check(value(row)==desired,"Original selector reaches "+desired)
func finish_motion()->void:
	for i in range(25):panel.view._process(.05)
	panel._refresh()
func run()->void:
	state=initial();panel=ArchivePanel.new();check(panel.configure("archive_index",state),"Source archive context opens")
	root.add_child(panel);root.size=Vector2i(1280,720);panel.layout_fullscreen(Rect2(0,0,1280,720));await frames()
	panel.submit_requested.connect(func(action:String,v:Dictionary,serial:int):submissions.append({"action":action,"value":v,"serial":serial}))
	panel.view.choice_requested.connect(func(key:String,v:String):choices.append([key,v]))
	panel.world_handoff_requested.connect(func(fresh:bool):handoffs.append(fresh))
	check(panel.view.index_targets.size()==3,"Exactly three attached index strips replace the nine-option grid")
	check(panel.find_children("*","OptionButton",true,false).is_empty(),"No hidden dropdown input path")
	var before:=JSON.stringify(state)
	panel._submit();check(submissions.is_empty() and panel.feedback.text.contains("三条"),"Unset index gives local guidance, no submit")
	check(panel.view.interactive,"Incomplete feedback adds no forced wait")
	gesture(0);check(value(0)=="1977_1984" and choices.size()==1,"One tap advances one original year")
	gesture(0,Vector2(-36,0));check(value(0)=="1985_1990" and choices.size()==2,"Left swipe advances once")
	gesture(0,Vector2(36,0));check(value(0)=="1977_1984" and choices.size()==3,"Right swipe reverses once")
	var count:=choices.size();var at:=point(0)
	panel.view._owned_pointer("mouse",0,true,at)
	for i in range(60):panel.view._process(.05)
	check(choices.size()==count,"Long hold never auto-repeats or submits")
	panel.view._owned_pointer("mouse",0,false,at);panel.view._owned_pointer("mouse",0,false,at)
	check(choices.size()==count+1 and value(0)=="1985_1990","Long-hold release commits once; duplicate release is inert")
	count=choices.size();gesture(0,Vector2(0,100));check(choices.size()==count and submissions.is_empty(),"Vertical index drag cannot pull the drawer")
	gesture(0,Vector2(8,2));check(choices.size()==count+1,"Pointer jitter remains one tap")
	at=point(1);var old:=value(1);count=choices.size()
	panel.view._owned_pointer("touch",4,true,at,false,1)
	panel.view._owned_pointer("touch",5,true,at,false,1);panel.view._owned_pointer("touch",5,false,at,false,1)
	panel.view._owned_pointer("mouse",0,false,at,false,1);panel.view._owned_pointer("touch",4,false,at,false,2)
	check(panel.view.dragging and panel.view.pointer_index==4 and choices.size()==count,"Only initial touch/device owns a strip")
	panel.view._owned_pointer("touch",4,false,at,true,1)
	check(not panel.view.dragging and value(1)==old,"Canceled touch makes no selection")
	gesture(1,Vector2.ZERO,"touch",4,1);count=choices.size()
	for down in [true,false]:
		var emulated:=InputEventMouseButton.new();emulated.button_index=MOUSE_BUTTON_LEFT;emulated.pressed=down;emulated.position=point(1);emulated.device=InputEvent.DEVICE_ID_EMULATION;panel.view._gui_input(emulated)
	check(choices.size()==count,"Touch-emulated mouse cannot duplicate the choice")
	for boundary:String in ["resize","focus","hide","mode","cancel"]:
		at=point(2);old=value(2);panel.view._owned_pointer("touch",7,true,at)
		match boundary:
			"resize":panel.layout_fullscreen(Rect2(0,0,1180,812))
			"focus":panel._notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
			"hide":panel.hide();panel.show()
			"mode":panel.set_input_mode("touch")
			"cancel":panel.cancel_input()
		panel.view._owned_pointer("touch",7,false,at-Vector2(40,0));check(not panel.view.dragging and value(2)==old,boundary+" cancels selector without input")
	panel.set_input_mode("keyboard");panel.grab_focus();await frames()
	panel.session.choose("yearBand","");panel._refresh();panel.view.focused_row=0
	var key:=InputEventKey.new();key.pressed=true;key.keycode=KEY_LEFT
	panel.handle_key(key);check(value(0)=="1991_1998","Left from unset selects bounded last original year")
	key.keycode=KEY_DOWN;panel.handle_key(key);check(panel.view.focused_row==1,"Down focuses the next strip")
	at=point(1);panel.view._owned_pointer("mouse",0,true,at);key.keycode=KEY_RIGHT;panel.handle_key(key)
	check(not panel.view.dragging,"Keyboard retires an in-flight mouse gesture")
	count=choices.size();panel.view._owned_pointer("mouse",0,false,at);check(choices.size()==count,"Old mouse release cannot override keyboard index")
	choose(0,"1977_1984");choose(1,"A1");choose(2,"attendance")
	check(JSON.stringify(state)==before,"Index edits never write state/save")
	var wrong:Dictionary=panel.session.draft.duplicate(true)
	var handle:Vector2=panel.view.handle.get_center();count=choices.size()
	panel.view._owned_pointer("mouse",0,true,handle);panel.view._owned_pointer("mouse",0,false,handle+Vector2(60,0))
	check(choices.size()==count and submissions.is_empty(),"Horizontal handle motion cannot change an index or submit")
	panel.view._owned_pointer("mouse",0,true,handle);panel.view._owned_pointer("mouse",0,false,handle+Vector2(0,35))
	check(submissions.size()==1 and panel.session.pending,"Downward handle requests one original solve")
	panel._submit();check(submissions.size()==1 and not panel.can_close(),"Pending submit blocks duplicate pull/close")
	var request:Dictionary=submissions.back();var controller:=Chapter.new()
	panel.resolve_submission(request.serial+1,state,{"message":"stale"});check(panel.session.pending,"Wrong serial cannot resolve live request")
	panel.resolve_submission(request.serial,state,controller.dispatch(state,request.action,request.value))
	check(not panel.session.completed and panel.session.draft==wrong and not panel.feedback.text.is_empty(),"Original wrong answer preserves index positions and feedback")
	check(panel.view.interactive and not panel.view.motion.is_empty(),"Error recoil is visual only, with no wait gate")
	choose(0,"1991_1998");choose(1,"A3");choose(2,"wayfinding")
	panel._submit();request=submissions.back();panel.resolve_submission(request.serial,state,controller.dispatch(state,request.action,request.value))
	check(panel.session.completed and Motion.FACT in state.chapter4.factIds and panel.fresh_success,"Only original controller earns film")
	var facts:Array=state.chapter4.factIds.duplicate();count=submissions.size();gesture(0);panel._submit()
	check(state.chapter4.factIds==facts and submissions.size()==count,"Completed strips and handle are read-only")
	for dim:Vector2i in [Vector2i(1280,720),Vector2i(390,844),Vector2i(430,860),Vector2i(844,390)]:
		panel.layout_fullscreen(Rect2(Vector2.ZERO,Vector2(dim)));await frames()
		check(Rect2(Vector2.ZERO,Vector2(dim)).encloses(panel.close_button.get_global_rect()),"Return contained at "+str(dim))
		for i in range(3):
			var rect:Rect2=panel.view.index_targets[i].rect
			check(panel.view.play_area.encloses(rect) and rect.size.y>=44 and rect.size.x>=44,"Attached strip is contained/touchable at "+str(dim))
			check(not rect.intersects(panel.view.handle),"Index and handle hit areas remain distinct at "+str(dim))
			if i<2:check(not rect.intersects(panel.view.index_targets[i+1].rect),"Adjacent strips do not overlap at "+str(dim))
	panel.dispose_session();panel.dispose_session();check(handoffs==[true],"One final handoff despite repeated disposal")
	panel.queue_free();await frames();panel=ArchivePanel.new();panel.configure("archive_index",JSON.parse_string(JSON.stringify(state)));root.add_child(panel);await frames()
	check(panel.session.completed and not panel.fresh_success and panel.session.draft==panel.session.source.defaults,"Completed reopen invents no draft/checkpoint or replay")
	panel.dispose_session();panel.queue_free();await frames();state=initial("dark");panel=ArchivePanel.new();panel.configure("archive_index",state);root.add_child(panel);await frames()
	before=JSON.stringify(state);gesture(0,Vector2(-40,0));panel._submit()
	check(not panel.view.interactive and JSON.stringify(state)==before,"Dark evidence remains read-only on the same attached strips")
	check(panel.view.index_label(0)=="九十年代末","Dark label reads original source clue without invented answer")
	panel.dispose_session();panel.queue_free();await frames();test_motion()
	print("ROOM301_INDEX_TABS: %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)

func test_motion()->void:
	var value:=initial();var before:=JSON.stringify(value);var motion:=Motion.new()
	motion.open(value);check(motion.sample().pull==0,"Design K1 starts aligned")
	for i in range(4):motion.tick(.055,value)
	check(is_equal_approx(motion.sample().pull,5),"Design K2 reveals five source pixels at 220ms")
	motion.close(false,value)
	for i in range(3):motion.tick(.06,value)
	check(motion.stage=="idle" and motion.sample().pull==0,"Cancel retracts within 180ms")
	check(JSON.stringify(value)==before,"Presentation cannot write a story or save field")
	motion.close(true,value);check(motion.stage!="handoff","Unaccepted close cannot lift film")
	value.chapter4.factIds.append(Motion.FACT);motion.open(value);check(motion.stage=="idle","Existing completed state does not reopen acquisition")
	motion.close(true,value)
	for i in range(8):motion.tick(.06,value)
	check(motion.sample().film_offset==Vector2(0,-10) and is_equal_approx(motion.sample().film_alpha,1),"Design K3 reaches local lift at 480ms")
	motion.tick(.06,value);motion.tick(.06,value);motion.tick(.06,value);motion.tick(.06,value);motion.tick(.04,value)
	check(is_zero_approx(motion.sample().film_alpha),"Design K4 fades rightward film by 760ms")
	for i in range(4):motion.tick(.06,value)
	check(motion.stage=="idle" and motion.sample().pull==0,"Drawer settles by 1000ms")
	motion.open(value);motion.close(true,value);motion.tick(.04,value.duplicate(true))
	check(motion.stage=="idle","Same-scene ordinary reload retires active world acquisition")
	value.native.settings.reduced_motion=true;motion.open(value);motion.close(true,value)
	check(motion.stage=="idle" and motion.sample().film_alpha==0,"Reduced motion keeps terminal state without extra displacement")
