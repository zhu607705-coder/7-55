extends SceneTree
const Fibers=preload("res://scripts/presentation/c3_mode_fibers.gd")
const View=preload("res://scripts/presentation/c3_mode_fiber_view.gd")
var checks:=0
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error(label)
func initial(mode: String="dark",reduced: bool=false) -> Dictionary:
	return {"native":{"scene":"canteen_interior","mode":mode,"settings":{"reduced_motion":reduced}},"canteenHunt":{"phase":"tray_search","mode":mode,"active":true},"items":{"campusCard":true}}
func run() -> void:
	var oracle: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/canteen_mode_fibers_source.json"))
	var state:=initial(); var model:=Fibers.new(); model.sync(state,true)
	var before:=JSON.stringify(state)
	for step in range(oracle.deltas.size()):
		model.tick(float(oracle.deltas[step])/1000,state)
		var samples: Array=model.entries()
		check(samples.size()==4,"four source circles at step "+str(step))
		for i in range(4):
			var source: Dictionary=oracle.fibers[i]
			var mix_value: float=oracle.loops[i].samples[step]
			var expected:=Vector2(source.point[0],source.point[1]).lerp(Vector2(source.to[0],source.to[1]),mix_value)
			check(samples[i].point.is_equal_approx(expected) and is_equal_approx(samples[i].alpha,lerpf(source.alpha.from,source.alpha.to,mix_value)),"actual Phaser TweenData position/alpha "+str(step)+":"+str(i))
			if step==0:
				check(samples[i].radius==source.radius and samples[i].depth==source.depth and samples[i].color==Color("8be6ff",source.fillAlpha),"source radius, fill and exact depth "+str(i))
	check(JSON.stringify(state)==before,"source facts and items unchanged after all loop samples")
	var time_before: float=model.clock_ms; var stationary: Array=model.entries()
	for i in range(10): model.sync(state); model.entries()
	model.tick(-1,state)
	check(model.clock_ms==time_before and model.entries()==stationary,"paused reads, redraws and negative delta never advance the presentation")
	state=initial("light"); model.sync(state,true)
	check(model.entries().is_empty(),"light entry shows no fibers")
	state.native.mode="dark"; model.sync(state)
	check(model.entries().size()==4 and model.entries()[0].alpha==0,"dark switch begins at zero alpha")
	model.tick(.11,state)
	for i in range(4):
		var transition: Dictionary=oracle.modes.normalDark[i]
		check(is_equal_approx(model.entries()[i].alpha,(110-transition.delay)/transition.duration*transition.alpha),"source 220ms linear fade and 9ms stagger "+str(i))
	model.tick(.11,state)
	check(is_equal_approx(model.entries()[0].alpha,.9),"first source fade reaches .9 exactly at 220ms")
	model.tick(.027,state)
	check(model.entries().size()==4 and is_equal_approx(model.entries()[3].alpha,.9),"fourth source fade reaches .9 at 247ms")
	state.native.mode="light"; model.sync(state); model.tick(.219,state)
	check(model.entries().size()==4,"light fade retains all circles until first 220ms boundary")
	model.tick(.001,state)
	check(model.entries().size()==3,"first circle hides at exactly220ms")
	model.tick(.027,state)
	check(model.entries().is_empty(),"last circle hides after source27ms stagger")
	state=initial("light",true); model.sync(state,true); state.native.mode="dark"; model.sync(state); model.tick(.06,state)
	for i in range(4):
		check(model.entries()[i].point==Fibers.POINTS[i] and is_equal_approx(model.entries()[i].alpha,.45),"reduced source120ms fade has no delay or displacement "+str(i))
	model.tick(.06,state); stationary=model.entries(); model.tick(2,state)
	check(model.entries()==stationary and is_equal_approx(stationary[0].alpha,.9),"reduced mode suppresses indefinite motion and flicker")
	state=initial("light"); model.sync(state,true); state.native.mode="dark"; model.sync(state); model.tick(.08,state)
	state.native.mode="light"; model.sync(state); model.tick(.04,state); state.native.mode="dark"; model.sync(state); model.tick(.247,state)
	check(model.entries().size()==4 and model.mode=="dark","rapid reversal cannot execute stale hide callbacks")
	state.canteenHunt.phase="exit_blocking"; model.sync(state)
	check(model.entries().is_empty(),"defense suppresses circles immediately")
	model.tick(.1,state); state.canteenHunt.phase="chase_ready"; model.sync(state)
	check(model.entries().is_empty(),"defense completion does not resurrect hidden fibers")
	state.native.mode="light"; model.sync(state); state.native.mode="dark"; model.sync(state)
	check(model.entries().size()==4,"new authorized mode change resumes passive display")
	state.native.scene="campus_bootstrap"; model.sync(state); model.tick(1,state)
	check(model.entries().is_empty() and model.clock_ms==0,"scene exit clears all fiber motion and clock")
	state.native.scene="canteen_interior"; model.sync(state)
	check(model.entries().size()==4 and model.entries()[0].point==Fibers.POINTS[0],"reentry starts only one clean source layer")
	seed(755); var expected_rng:=randi(); seed(755)
	for i in range(20): model.tick(.017,state); model.entries()
	check(randi()==expected_rng,"fiber animation never consumes gameplay RNG")
	var view:=View.new(); root.add_child(view); view.set_samples(model.entries()); await process_frame
	check(view.is_visible_in_tree() and view.samples.size()==4 and view.get_meta("source_depth")==1602.0,"actual native Node2D consumes four circle samples at source depth1602")
	check(not view.is_processing() and view.get_child_count()==0,"view has no independent clock, input object or physics body")
	view.set_samples([]); await process_frame
	check(not view.visible and view.samples.is_empty(),"empty snapshot clears the actual native view")
	view.queue_free(); await process_frame
	print("CANTEEN_MODE_FIBERS ",checks," checks; ",failures," failures"); quit(1 if failures else 0)
