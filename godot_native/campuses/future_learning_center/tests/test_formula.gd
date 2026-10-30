extends SceneTree
const Model=preload("res://campuses/future_learning_center/scripts/puzzles/formula_model.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;printerr("FORMULA_FAIL: "+label)
func race(m)->void:m.place_on_track(true);m.start();m.step(30)
func _initialize()->void:_run.call_deferred()
func _run()->void:
	var counts:=[0,0]
	for scene:int in 2:
		for p:int in 2:
			for t:int in 3:
				for g:int in 3:
					var m=Model.new();m.set_scenario(scene);m.edit("panel",p);m.edit("tilt",t);m.edit("gear",g);race(m)
					check(m.records.size()==1 and m.ticks==600,"all configs finish actual fixed ticks")
					if m.completed:counts[scene]+=1
					for c:Dictionary in m.cars:
						check(c.peak_power_fraction<=1.000001 and c.mechanical_energy<=.65*c.electrical_energy+1e-5,"mechanical power never exceeds panel input")
						check(c.energy_error<.00001,"discrete energy balance")
	check(counts==[11,7],"enumerated winners match independent numerical study")
	var m=Model.new();m.edit("panel",1);m.edit("tilt",1);m.edit("gear",1);race(m)
	check(absf(m.cars[0].distance-62.51707176)<.001 and absf(m.cars[1].distance-52.35006524)<.001,"sunny numerical reference")
	check(m.segments.size()==4 and m.records[-1].won,"measured stage records, no static config win")
	m=Model.new();race(m);check(not m.completed,"baseline tie does not win")
	m=Model.new();check(not m.start(),"car must actually be placed on track")
	m.place_on_track(true);m.start();m.step(5);m.cancel();m.step(30);check(m.records.is_empty() and not m.completed,"abort never publishes finish")
	m.start();m.step(2);m.edit("gear",1);m.step(30);check(m.records.is_empty() and not m.running,"edit invalidates in-flight run")
	m.edit("panel",-1);m.place_on_track(true);check(not m.start(),"missing panel cannot run")
	m=Model.new();m.set_scenario(1);m.edit("panel",1);m.edit("tilt",2);m.edit("gear",1);race(m)
	check(absf(m.cars[0].distance-48.37489527)<.001 and m.extension_completed,"side-light reference")
	check(m.irradiance(10)==.15 and m.irradiance(18)==.8,"cloud interval matches visual clock")
	m=Model.new();m.place_on_track(true);m.start();m.step(NAN);m.step(-1);check(m.ticks==0,"invalid time ignored")
	var n=Model.new();race(n)
	m.step(.013)
	for i:int in 3000:m.step(.01)
	check(absf(m.cars[0].distance-n.cars[0].distance)<.00001,"frame chunking preserves same fixed light replay")
	if "--with-view" in OS.get_cmdline_user_args():
		var v=load("res://campuses/future_learning_center/scripts/puzzles/formula_view.gd").new()
		root.add_child(v);v.open()
		v.press(v.PANEL_TRAYS[1]);v.release(v.BENCH_CAR)
		check(v.model.panel==1,"physical panel drag installs wide board")
		v.press(v.GEAR_TRAYS[1]);v.release(v.BENCH_CAR)
		check(v.model.gear==1,"physical gear drag changes actual drivetrain")
		v.press(v.TILT_KNOB);v.motion(v.TILT_KNOB);v.release(v.TILT_KNOB)
		check(v.model.tilt==1,"rotary bracket changes panel angle")
		v.press(v.BENCH_CAR);v.release(Vector2(480,120))
		check(v.model.on_track,"car is physically placed on race lane")
		v.press(v.GATE);v.release(v.GATE);v.model.step(30)
		check(v.model.completed and v.model.records.size()==1,"pointer assembled car wins actual complete run")
		v.press(v.GATE);v.release(v.GATE);v.model.step(1);v._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT);v.model.step(40)
		check(v.model.records.size()==1 and not v.model.running,"focus abort adds no forged race")
		v.press(v.GATE);v.release(v.GATE);v.close();v.model.step(40);v.open()
		check(v.model.records.size()==1 and v.model.personal_best[0]>60,"close abort retains completed personal record only")
		v.model.place_on_track(false)
		var touch:=InputEventScreenTouch.new();touch.index=2;touch.pressed=true;touch.position=v.BENCH_CAR;v._input(touch)
		var other:=InputEventScreenTouch.new();other.index=3;other.pressed=true;other.position=v.GATE;v._input(other)
		check(v.touch_id==2 and v.action=="car" and not v.model.running,"second finger cannot steal car or start race")
		touch.pressed=false;touch.canceled=true;touch.position=Vector2(480,120);v._input(touch)
		check(not v.model.on_track and v.action.is_empty(),"cancel does not place dragged car")
		var mouse:=InputEventMouseButton.new();mouse.device=InputEvent.DEVICE_ID_EMULATION;mouse.button_index=MOUSE_BUTTON_LEFT;mouse.pressed=true;mouse.position=v.LAMP;v._input(mouse)
		check(v.action.is_empty() and v.model.scenario==0,"emulated mouse cannot change lighting")
		v.queue_free()
	print("FLC_FORMULA: %d checks, %d failures"%[checks,failures]);quit(failures)
