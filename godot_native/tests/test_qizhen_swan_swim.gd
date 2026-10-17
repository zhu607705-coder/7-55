extends SceneTree
const Swim=preload("res://scripts/presentation/qizhen_swan_swim_visual.gd")
var checks: int=0
var failures: int=0
func _initialize() -> void:run.call_deferred()
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func run() -> void:
	var swim: RefCounted=Swim.new()
	swim.reset(Vector2(800,400))
	for i: int in range(180):swim.update(1.0/60,Vector2(800,400),PI,"swim")
	check(swim.emitted==0 and swim.wakes.is_empty(),"still body emits no travelling wake")
	for i: int in range(120):swim.update(1.0/60,Vector2(800-float(i+1)*.5,400),PI,"swim")
	check(swim.emitted==6,"60 source pixels create six distance-spaced wakes")
	check(absf(swim.speed-30)<.01,"wake speed derives from real displacement")
	check(absf(swim.body_bob())<=.35,"small heave cannot pump whole neck")
	check(not swim.accelerated_pose,"normal swimming cannot select acceleration head dip")
	var count: int=swim.emitted
	for i: int in range(200):swim.update(1.0/60,Vector2(740,400),PI,"swim")
	check(swim.emitted==count and swim.wakes.is_empty(),"stopped wake fades without new particles")
	var sample: Control=load("res://scenes/qizhen_swan_swim_study.tscn").instantiate()
	root.add_child(sample);sample.set_process(false)
	var old: Vector2=sample.point
	var old_heading: float=sample.heading
	for i: int in range(690):
		sample._process(1.0/60)
		check(sample.point.distance_to(old)<1.5,"continuous sample body movement")
		check(absf(angle_difference(old_heading,sample.heading))<.01,"bounded inertial heading")
		check(sample.visual.row>=0 and sample.visual.row<4,"valid genuinely drawn direction")
		check(absf(sample.visual.body_bob())<=.35,"waterline heave bounded")
		old=sample.point;old_heading=sample.heading
	sample.free()
	print("QIZHEN_SWAN_SWIM: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
