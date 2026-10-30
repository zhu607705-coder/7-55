extends SceneTree
const View=preload("res://campuses/future_learning_center/scripts/workbench_view.gd")
const Model=preload("res://campuses/future_learning_center/scripts/workbench_model.gd")
var checks:=0
var failures:=0
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;printerr("FLC_WORKBENCH_FAIL: "+label)
func run()->void:
	var m=Model.new()
	check(not m.edit("gear",99) and m.gear==-1,"invalid part leaves model unchanged")
	check(not m.edit("chapter",1),"no story/progression intent")
	for g:int in [-1,0,1,2]:
		for b:int in 3:
			for t:int in 3:
				m.reset()
				if g>=0:m.edit("gear",g)
				m.edit("belt",b);m.edit("tension",t);m.start()
				for i:int in 240:m.step(1.0/60)
				check((m.outcome=="passed")== (g==1 and b==2 and t==1),"only a meshing, tensioned, correctly directed drive passes")
				check(not m.running,"all trials terminate")
	for fps:int in [30,60,144]:
		m.reset();m.edit("gear",1);m.edit("belt",2);m.edit("tension",1)
		check(m.start() and not m.start(),"start is idempotent while running")
		for i:int in fps*3:m.step(1.0/fps)
		check(m.outcome=="passed" and is_equal_approx(m.travel,.92),"same result at different frame rates")
		var phase:float=m.motor_phase;m.step(5)
		check(m.motor_phase==phase,"finished state does not advance")
	m.reset();m.start();m.step(.2);m.cancel();var time:float=m.elapsed;m.step(10)
	check(m.elapsed==time and m.outcome.is_empty(),"closing or losing focus cancels without completion")
	m.start();m.edit("gear",1)
	check(not m.running and m.travel==.12,"changing a part cancels the previous trial")
	m.edit("belt",1);m.edit("tension",1);m.start();m.step(.3)
	check(m.travel<.12 and m.gear_phase<0 and m.output_phase<0,"open belt visibly drives the wrong way")
	m.reset();m.edit("gear",1);m.edit("belt",2);m.start();m.step(.3)
	check(m.gear_phase<0 and m.output_phase==0,"slack belt slips while the meshing gears turn")
	m.reset();m.step(INF);m.step(-1)
	check(m.travel==.12 and m.outcome.is_empty(),"invalid time cannot create progress")
	for g:int in [-1,0,1,2]:
		for b:int in 3:
			for t:int in 3:
				m.reset();m.set_reverse(true)
				if g>=0:m.edit("gear",g)
				m.edit("belt",b);m.edit("tension",t);m.start()
				for i:int in 240:m.step(1.0/60)
				check((m.outcome=="passed")== (g==1 and b==1 and t==1),"reverse target requires opposite belt with same meshing and tension")
	m.reset();m.edit("gear",1);m.edit("belt",1);m.edit("tension",1);m.set_reverse(true);m.start();m.step(3)
	check(m.transfer_completed and is_equal_approx(m.travel,.12),"reverse trial reaches left physical mark")
	m.edit("tension",2);m.undo();check(m.tension==1 and m.reverse_target and not m.running,"local undo restores only last edit without changing target")
	m.start();m.set_reverse(false);check(not m.running and m.outcome.is_empty(),"target change invalidates active trial")
	if "--with-view" in OS.get_cmdline_user_args():
		var v=View.new();root.add_child(v);v.open()
		var t=InputEventScreenTouch.new();t.pressed=true;t.index=3;t.position=Vector2(238,387);v._input(t)
		var other=InputEventScreenTouch.new();other.pressed=false;other.index=5;other.position=v.AXLE;v._input(other)
		check(v.drag==1 and v.model.gear==-1,"second touch cannot drop selected gear")
		var e=InputEventMouseButton.new();e.device=InputEvent.DEVICE_ID_EMULATION;e.pressed=false;e.button_index=MOUSE_BUTTON_LEFT;e.position=v.AXLE;v._input(e)
		check(v.drag==1 and v.model.gear==-1,"emulated mouse cannot duplicate touch drop")
		t.canceled=true;v._input(t);check(v.drag==-1 and v.model.gear==-1,"canceled gear drag cannot equip")
		v._press(Vector2(238,387));v._release(v.AXLE);v._press(v.BELT.get_center());v._press(v.TENSION)
		v._press(Vector2(700,310));v._press(v.POWER)
		for i:int in 240:v.model.step(1.0/60)
		check(v.model.transfer_completed,"direct gear, belt, tension, target and power inputs complete reverse exercise")
		v._press(Vector2(850,475));check(not v.model.reverse_target,"physical undo restores previous target")
		v.model.start();v.close();v.open();check(not v.model.running and v.drag==-1,"closing and reopening never resumes stale run")
		v.queue_free()
	print("FLC_WORKBENCH_TESTS: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
