extends SceneTree
const Timeline=preload("res://scripts/presentation/qizhen_swan_hop_timeline.gd")
var checks: int=0
var failures: int=0
func _initialize() -> void:run.call_deferred()
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func run() -> void:
	var timeline: RefCounted=Timeline.new()
	var seen: Dictionary={}
	var old: Vector2=timeline.pose().point
	var old_height: float=0
	var max_height: float=0
	for i: int in range(420):
		var pose: Dictionary=timeline.pose()
		seen[pose.frame]=true
		check(pose.frame>=0 and pose.frame<16,"all key poses within the real atlas")
		check(pose.point.distance_to(old)<2,"horizontal movement stays continuous")
		check(absf(pose.height-old_height)<2.6,"vertical short hop stays continuous")
		check(pose.height>=0 and pose.height<=32.001,"bounded short hop, not sustained flight")
		if timeline.elapsed<Timeline.TAKEOFF or timeline.elapsed>Timeline.LANDING:check(pose.height==0,"rest and wing preparation remain on water")
		max_height=maxf(max_height,pose.height);old=pose.point;old_height=pose.height
		timeline.advance(1.0/60)
	check(seen.size()==16,"all sixteen articulated complete-body poses used")
	check(max_height>31.8,"short hop clearly leaves water")
	check(timeline.launch_count==1 and timeline.landing_count==1,"splash impulses fire once at takeoff and landing")
	timeline.advance(100);check(timeline.launch_count==1 and timeline.landing_count==1,"terminal hold cannot duplicate splashes")
	timeline.reset();timeline.advance(2.7);timeline.paused=true
	var frozen: Dictionary=timeline.pose();timeline.advance(1)
	check(timeline.pose()==frozen,"pause freezes key pose and splash age")
	timeline.reset();check(timeline.elapsed==0 and timeline.launch_count==0 and timeline.landing_count==0,"replay clears timing and event counters")
	print("QIZHEN_SWAN_HOP: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
