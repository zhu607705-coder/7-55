extends SceneTree
const Model=preload("res://campuses/future_learning_center/scripts/puzzles/collab_model.gd")
const View=preload("res://campuses/future_learning_center/scripts/puzzles/collab_view.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;printerr("COLLAB: "+label)
func finish(m)->void:
	for i:int in 35:m.step(.1)
func photos(m)->void:
	m.set_condition(0);m.start("photo");finish(m);m.set_condition(1);m.start("photo");finish(m)
func _initialize()->void:run.call_deferred()
func run()->void:
	var m=Model.new()
	check(not m.current_passed(),"empty apparatus cannot pass")
	check(not m.place(-1,0) and not m.place(0,4),"invalid edits rejected")
	check(m.place(0,0) and not m.place(1,0),"one baffle per slot")
	m.start("photo");finish(m);check(m.receipts.photo_a.passed,"west baffle shades west source")
	m.set_condition(1);check(m.receipts.has("photo_a"),"condition switch preserves current evidence")
	m.start("photo");finish(m);check(not m.receipts.photo_b.passed,"one side is not sufficient")
	m.place(0,2);check(m.receipts.is_empty() and m.history.size()==2,"edits invalidate but keep history")
	m.start("photo");finish(m);check(m.receipts.photo_b.passed and not m.current_passed(),"old opposite photo cannot be combined")
	m.place(1,0);photos(m);m.start("feed");m.step(.1);check(not m.current_passed(),"feed must finish physically")
	m.pause();var elapsed:float=m.elapsed;m.step(.1);check(m.elapsed==elapsed,"focus pause freezes trial")
	m.resume();finish(m);check(m.current_passed() and m.completed,"same configuration complete")
	m.rotate_fixture();check(m.completed and not m.current_passed() and m.receipts.is_empty(),"rotation preserves completed fact but invalidates pending proof")
	check(not m.camera_clear() and not m.feed_clear(),"rotation changes actual paths")
	m.start("feed");finish(m);check(m.travel<=m.feed_stop_fraction() and not m.receipts.feed.passed,"carriage stops at obstruction")
	m.place(0,1);m.place(1,3);photos(m);m.start("feed");finish(m);check(m.current_passed(),"rotated fixture can be solved")
	var before:=m.version();check(m.place(1,3) and before==m.version(),"unchanged placement does not erase evidence")
	m.start("feed");m.step(.1);m.cancel();check(not m.running and m.current_passed(),"cancel does not erase valid prior results")
	for rotation:int in 4:
		var solutions:=0
		for a:int in range(-1,4):
			for b:int in range(-1,4):
				var trial=Model.new()
				for turn:int in rotation:trial.rotate_fixture()
				if not trial.place(0,a) or not trial.place(1,b):continue
				photos(trial);trial.start("feed");finish(trial)
				if trial.current_passed():solutions+=1
		check(solutions==2,"both interchangeable baffle solutions at rotation %d"%rotation)
	var view=View.new();check(view.model!=null,"view parses with its controller")
	view._press(view.TRAY[0]);view._release(view.TRAY[0]);check(view.selected==0 and view.model.slots[0]==-1,"tap selects physical baffle without auto-solving")
	view._press(view.projected(Model.SLOT_POINTS[0]));view._release(view.projected(Model.SLOT_POINTS[0]));check(view.model.slots[0]==0,"tap-place alternative uses empty physical slot")
	view._press(view.TRAY[1]);view._release(Vector2(10,200));check(view.model.slots[1]==-1,"missed drag returns part to its tray")
	view._press(view.TRAY[1]);view._release(view.projected(Model.SLOT_POINTS[2]));check(view.model.slots[1]==2,"drag places second baffle")
	view._press(view.camera_at());view._release(view.camera_at()+Vector2(35,0));check(not view.model.running,"pointer cancellation does not trigger a shutter")
	view._press(view.camera_at());view._release(view.camera_at());check(view.model.running,"physical camera starts a timed exposure")
	view._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT);check(view.model.paused and view.drag==-1,"view focus loss pauses and releases drag")
	view._press(Vector2(480,280));view._release(Vector2(480,280));check(not view.model.paused,"explicit touch resumes experiment")
	view.close();check(not view.model.running and view.model.slots==[0,2],"close preserves assembly and cancels only current trial")
	owner_cancel(view,"_input")
	for child:String in ["assembly","recording","sync"]:
		var inherited=load("res://campuses/future_learning_center/scripts/puzzles/"+child+"_view.gd").new()
		owner_cancel(inherited,"_input");inherited.free()
	view.free()
	print("FLC_COLLAB: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)

func owner_cancel(view:Control,method:String)->void:
	if not view.is_inside_tree():root.add_child(view)
	view.show()
	var contact:=InputEventScreenTouch.new();contact.index=8;contact.position=Vector2(700,75);contact.pressed=true
	view.call(method,contact);contact.canceled=true;view.call(method,contact)
	check(view.touch_id==-1,"pressed cancellation releases owner")
	view.call(method,contact);check(view.touch_id==-1,"orphan canceled press cannot reacquire")
	contact.canceled=false;contact.index=9;view.call(method,contact)
	check(view.touch_id==9,"next finger can acquire after cancellation")
	var foreign:=InputEventScreenTouch.new();foreign.index=10;foreign.pressed=true;foreign.canceled=true;view.call(method,foreign)
	check(view.touch_id==9,"non-owner cancellation cannot steal capture")
	contact.pressed=false;contact.canceled=true;view.call(method,contact)
