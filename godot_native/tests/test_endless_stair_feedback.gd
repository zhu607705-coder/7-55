extends SceneTree
const View=preload("res://scripts/presentation/chapter4_endless_stair_view.gd")
const Foley=preload("res://scripts/audio/endless_stair_guard_foley.gd")
var checks:=0
var failures:=0
func check(ok:bool,note:String)->void:
	checks+=1
	if not ok:failures+=1;push_error("B3 feedback: "+note)
func _initialize()->void:run.call_deferred()
func run()->void:
	DirAccess.make_dir_recursive_absolute("user://endless_stair_b3")
	for kind in ["step","click","inhale","exhale"]:
		var a=Foley.make(kind);var b=Foley.make(kind)
		var peak:=0
		for i in a.data.size()/2:peak=maxi(peak,absi(a.data.decode_s16(i*2)))
		check(a.data==b.data and a.mix_rate==22050,"deterministic PCM "+kind)
		check(peak>1000 and peak<30000,"audible unclipped PCM "+kind)
	var v=View.new();root.add_child(v)
	await process_frame
	v.set_process(false);v.set_physics_process(false);v._start();v.demo_mode=true;v.capture_frames.clear()
	var max_raise_fast:=0.0
	var max_raise_slow:=0.0
	var max_fast_angle:=0.0
	var max_slow_angle:=0.0
	var light_ok:=true
	var lens_attached:=true
	var phase_trace:Array=[]
	while v.model.tick<720 and v.model.status=="running":
		v._physics_process(1.0/60);v._present(1.0/60)
		var m=v.model
		var feedback=v.rhythm_feedback
		if m.pursuit_phase=="windup":
			if m.pursuit_pattern=="fast":
				max_raise_fast=maxf(max_raise_fast,feedback.arm_amount)
				max_fast_angle=maxf(max_fast_angle,feedback.lift_angle)
			else:
				max_raise_slow=maxf(max_raise_slow,feedback.arm_amount)
				max_slow_angle=maxf(max_slow_angle,feedback.lift_angle)
		light_ok=light_ok and v.torch.shadow_enabled and is_equal_approx(v.torch.spot_range,float(m.geometry.lighting.torchRange)) and is_equal_approx(v.torch.spot_angle,float(m.geometry.lighting.torchAngle))
		lens_attached=lens_attached and v.torch.global_position.distance_to(v.guard_hand_world)<.13 and v.torch_lens.position.distance_to(v.torch.position)<.013
	check(max_raise_fast>.99 and max_raise_slow>.99,"both warnings visibly raise the hand before their bursts")
	check(max_fast_angle>max_slow_angle+.10,"two warning gestures have distinct elevation")
	check(light_ok,"gesture preserves real shadowed spotlight range and cone angle")
	check(lens_attached,"light/case/lens follow the raised wrist without detached source")
	var saw_fast:=false;var saw_slow:=false;var saw_recovery:=false
	for cue in v.rhythm_feedback.cues_played:
		if cue.phase=="windup":
			if cue.pattern=="fast":saw_fast=true
			if cue.pattern=="slow":saw_slow=true
		if cue.phase=="recovery":saw_recovery=true
	check(saw_fast and saw_slow and saw_recovery,"both preparation and recovery sounds were triggered by model state")
	check(v.rhythm_feedback.step_events.size()>20,"actual grounded movement emits footsteps")
	var before=v.model.tick
	v._lose_focus();v._physics_process(1.0/60)
	check(v.model.tick==before and v.focus_paused,"focus pause freezes simulation and telegraph clock")
	v._menu_action();v._start()
	check(v.model.tick==0 and v.rhythm_feedback.cues_played.is_empty() and v.rhythm_feedback.step_events.is_empty() and v.rhythm_feedback.scheduled_click_tick==-1,"retry clears queued sound, pose and step counters")
	check(not v.rhythm_feedback.click.playing and not v.rhythm_feedback.breath.playing,"retry stops prior warning/recovery audio")
	var result={"checks":checks,"failures":failures,"fastLiftRadians":max_fast_angle,"slowLiftRadians":max_slow_angle,"input":"simulated fixed-tick inputs; audio samples verified as deterministic nonzero unclipped PCM"}
	FileAccess.open("user://endless_stair_b3/B3_feedback_checks.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	print("B3_FEEDBACK ",JSON.stringify(result))
	v.queue_free();await process_frame;await create_timer(.12).timeout;quit(1 if failures else 0)
