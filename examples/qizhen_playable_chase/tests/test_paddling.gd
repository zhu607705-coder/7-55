extends SceneTree
const Motion = preload("res://scripts/presentation/kayak_stroke_timeline.gd")
const Kayak = preload("res://scripts/games/kayak_model.gd")
var assertions: int=0
var failures: Array[String]=[]
func check(value: bool, label: String) -> void:
	assertions+=1
	if not value: failures.append(label);push_error(label)
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var motion=Motion.new()
	check(motion.phase()=="rest","Starts resting")
	motion.request_stroke("left")
	var seen: Array[String]=[]
	var samples: Dictionary={}
	var angles: Array[float]=[]
	for i: int in range(55):
		var p: Dictionary=motion.pose()
		if not seen.has(motion.phase()):seen.append(motion.phase())
		samples[str(snappedf(p.sweep,.00001))+":"+str(snappedf(p.pitch,.00001))]=true
		angles.append(p.sweep)
		motion.advance(1.0/60)
	check(seen==["catch","power","exit","recovery","rest"],"All four stroke phases in order")
	check(samples.size()>=40,"More than 40 distinct native motion samples, no two-frame flip")
	check(not motion.active,"No phantom strokes after release")
	check(motion.started_strokes==1,"One slow intent starts one stroke")
	motion.reset();motion.request_stroke("right");motion.advance(.24)
	var before: Dictionary=motion.pose()
	motion.set_paused(true);motion.advance(30);motion.request_stroke("left")
	check(motion.pose()==before,"Pause freezes every pose field and rejects input")
	check(motion.accepted_intents==1,"Paused input does not queue")
	motion.set_paused(false);motion.advance(.6)
	check(motion.phase()=="rest","Resume finishes only the pending stroke")
	motion.reset();motion.request_stroke("left");motion.advance(.20)
	var left: Dictionary=motion.pose()
	motion.reset();motion.request_stroke("right");motion.advance(.20)
	var right: Dictionary=motion.pose()
	check(is_equal_approx(left.sweep,-right.sweep),"Left/right sweep symmetry")
	check(is_equal_approx(left.pitch,-right.pitch),"Left/right immersion depth symmetry")
	motion.reset();motion.request_stroke("left",true);motion.advance(.20)
	var back: Dictionary=motion.pose()
	check(is_equal_approx(left.sweep,-back.sweep),"Reverse pulls in the reverse direction")
	check(is_equal_approx(left.pitch,back.pitch),"Reverse keeps active blade on correct side")
	motion.reset()
	for i: int in range(60):
		motion.request_stroke("left" if i%2==0 else "right")
		motion.advance(.01)
		check(motion.pending.size()<=3,"Bounded latest-intent buffer")
	motion.advance(3)
	motion.advance(3)
	check(not motion.active and motion.pending.is_empty(),"Rapid input never leaves a long animation backlog")
	motion.reset()
	check(motion.accepted_intents==0 and motion.started_strokes==0 and motion.pose().immersion==0 and motion.pending.is_empty(),"Retry clears timeline, counters, wet blade, buffer")
	for interval: float in [.36,.5,.6]:
		motion.reset();motion.request_stroke("left");motion.advance(interval)
		var old_duration: float=motion.duration
		motion.request_stroke("right")
		check(motion.duration<=old_duration,"Cadence compression never lengthens an in-flight stroke")
	# Model parity: the visual system sees the same accepted intents but is
	# never permitted to add force or mutate the gameplay controller.
	var plain=Kayak.new();plain.configure({"phase":"world","bounded":false})
	var rendered=Kayak.new();rendered.configure({"phase":"world","bounded":false})
	for frame: int in range(1200):
		if frame%42==0:
			var side: String="left" if (frame/42)%2==0 else "right"
			var reverse: bool=frame>900
			plain.stroke(side,reverse);rendered.stroke(side,reverse);motion.request_stroke(side,reverse)
		plain.update(1.0/60);rendered.update(1.0/60);motion.advance(1.0/60)
	check(plain.position==rendered.position and plain.heading==rendered.heading and plain.speed==rendered.speed,"Visual motion does not change dynamics")
	check(plain.result()==rendered.result(),"Full result protocol parity")
	var view=load("res://scenes/qizhen_paddling_study.tscn").instantiate()
	root.add_child(view);view.set_process(false)
	view.stroke("left")
	check(view.kayak.inputs.size()==1 and view.rig.motion.accepted_intents==1,"One accepted intent reaches model and visual exactly once")
	view._pointer(Vector2.ZERO,true,7)
	view.touch_starts[7]={"side":"right","start":Vector2(20,20)}
	view.set_paused(true)
	view._pointer(Vector2(20,70),false,7)
	check(view.kayak.inputs.size()==1 and view.touch_starts.is_empty(),"Pause cancels an in-progress touch")
	view.set_paused(false)
	view.touch_starts[8]={"side":"right","start":Vector2(20,20)}
	view._pointer(Vector2(20,70),false,8)
	check(view.kayak.inputs.size()==2 and view.kayak.inputs[-1].direction=="reverse","Touch downward drag retains reverse contract")
	var simulated_mouse:=InputEventMouseButton.new();simulated_mouse.device=-1;simulated_mouse.button_index=MOUSE_BUTTON_LEFT;simulated_mouse.pressed=true
	view._gui_input(simulated_mouse)
	check(view.touch_starts.is_empty(),"Synthesized mouse from touch never doubles input")
	view.restart()
	check(view.kayak.inputs.is_empty() and view.rig.motion.accepted_intents==0 and view.rig.spray.is_empty() and view.touch_starts.is_empty(),"Scene retry clears all presentation and touch state")
	view.stroke("left");view.rig.advance(.2);view._notification(Control.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(view.paused and view.rig.motion.paused,"Focus loss freezes model and motion together")
	view.queue_free()
	var report: Dictionary={"assertions":assertions,"failures":failures,"passed":failures.is_empty(),"unique_native_stroke_samples":samples.size(),"observed_phases":seen}
	print("PADDLE_TEST ",JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
