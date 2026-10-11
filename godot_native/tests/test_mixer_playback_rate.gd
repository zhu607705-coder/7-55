extends "res://tests/test_mixer_completion_continuity.gd"
## Deterministic local-clock boundary tests. No rendering-FPS or GUI claim.
const RateMotion = preload("res://scripts/presentation/c3_mixer_motion.gd")
func run() -> void:
	var original_time_scale: float=Engine.time_scale
	check(RateMotion.PLAYBACK_RATE==0.75,"requested local playback rate is exactly 0.75")
	for reduced in [false,true]:
		var view: Control=fresh(reduced)
		press(view,"blackCoffee")
		var committed: Dictionary=s.duplicate(true)
		var duration: float=MixerTiming.REDUCED_ORDINARY_MS if reduced else MixerTiming.ORDINARY_MS
		var real_seconds: float=duration/1000.0/RateMotion.PLAYBACK_RATE
		view.surface.motion._process(real_seconds-0.001)
		check(view.surface.motion.playing,"ordinary pour remains live just before local slowed boundary")
		view.surface.motion._process(0.002)
		check(not view.surface.motion.playing,"ordinary pour completes just after local slowed boundary")
		check(s==committed and dispatched.size()==1,"slow presentation never delays, replays or changes accepted input")
		view.free()
		view=fresh(reduced);complete(view);committed=s.duplicate(true)
		for index in range(2):MixerTiming.finish_current(view.surface.motion)
		check(view.surface.motion.item_id=="lemonTea" and view.surface.motion.playing,"rapid queue reaches original third input")
		duration=MixerTiming.REDUCED_TERMINAL_MS if reduced else MixerTiming.TERMINAL_MS;real_seconds=duration/1000.0/RateMotion.PLAYBACK_RATE
		view.surface.motion._process(real_seconds-0.001)
		check(view.surface.is_pouring() and view.finishing,"terminal pour remains live to slowed boundary")
		view.surface.motion._process(0.002)
		check(not view.surface.is_pouring(),"terminal pour completes after slowed boundary")
		var return_ms: float=260 if reduced else 660
		view._process(return_ms/1000.0/RateMotion.PLAYBACK_RATE-0.001)
		check(view.visible and closes.is_empty(),"result/return tail uses same local 0.75 clock")
		view._process(0.002)
		check(not view.visible and closes==["attempt_complete"] and s==committed,"slowed completion releases input once and keeps transaction intact")
		view.free()
	# The logical pose is based on seconds, not the number of process calls.
	for hz in [30,60,120]:
		var view: Control=fresh();press(view,"blackCoffee")
		for step in range(hz/5):view.surface.motion._process(1.0/hz)
		check(is_equal_approx(view.surface.motion.elapsed_ms,150.0),"same 150ms pose after 200ms at "+str(hz)+" simulated process Hz")
		view.surface.motion._process(-1)
		check(is_equal_approx(view.surface.motion.elapsed_ms,150.0),"negative delta cannot rewind presentation")
		view.dismiss();check(not view.blocks_world_input(),"Escape/dismiss remains immediate at "+str(hz)+"Hz")
		view.free()
	check(Engine.time_scale==original_time_scale,"global engine time scale remains untouched")
	print("Mixer local playback rate: ",checks," checks, ",errors," failures")
	quit(1 if errors else 0)
