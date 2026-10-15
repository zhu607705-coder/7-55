extends SceneTree
const Model = preload("res://scripts/games/rhythm_fishing_model.gd")
const Motion = preload("res://scripts/ui/lake_fishing_motion.gd")
var checks:=0
var failures:=0
func _initialize() -> void: run.call_deferred()
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error("FISHING MOTION: "+label)
func snapshot(m: RefCounted) -> String:
	var values: Dictionary={}
	for p: Dictionary in m.get_property_list():
		if int(p.usage)&PROPERTY_USAGE_SCRIPT_VARIABLE:values[p.name]=m.get(p.name)
	return JSON.stringify(values)
func at(m: RefCounted,beat: int,u: float,held: bool=true) -> Dictionary:
	m.elapsed=m.cast_at+4*m.beat_sec+m.phrase_time(beat+u)
	m.physics_tick=roundi(m.elapsed*120)
	m.controls={"hook":true} if held else {}
	return Motion.sample(m)
func run() -> void:
	var m:=Model.new();m.configure("locker_key",Model.load_chart("locker_key"))
	m.phase="running";m.stage="fighting";m.cast_at=.6;m.tension=65
	var anticipate:=at(m,0,.90)
	var thrust:=at(m,1,.30)
	var pull:=at(m,2,.50)
	var recover:=at(m,3,.85,false)
	check(anticipate.pose=="anticipation" and anticipate.body_bend<-.4,"pre-thrust C-bend anticipates next beat")
	check(thrust.pose=="fish_thrust" and thrust.fish_force>.8,"rush beat produces an authored fish thrust")
	check(pull.pose=="player_pull" and pull.human_lean<-12,"held收线 beat pulls upper body backward")
	check(recover.pose=="recovery" and absf(recover.body_bend)<.001 and recover.human_lean>0,"release relaxes the fish and opens the body while actual tension persists")
	var pre_thrust:=at(m,0,.9999)
	var begin_thrust:=at(m,1,0)
	check(absf(pre_thrust.body_bend-begin_thrust.body_bend)<.001,"anticipation flows continuously into body thrust")
	check(absf(pre_thrust.tail_thrust-begin_thrust.tail_thrust)<.001,"tail winding does not snap at beat boundary")
	var tail0:=Motion.fish_point(Vector2(0,.5),62,at(m,1,.30))
	var tail1:=Motion.fish_point(Vector2(0,.5),62,at(m,1,.60))
	check(absf(tail0.y-tail1.y)>8,"tail reverses by visibly different silhouette positions")
	for pose: Dictionary in [anticipate,thrust,pull,recover]:
		var center:=Motion.fish_point(Vector2(646.0/1014.0,269.0/465.0),62,pose)
		check(center.length()<.0001,"logical fish target remains fixed")
		var head:=Motion.fish_point(Vector2(.98,.5),62,pose)
		check(head.is_equal_approx(Motion.fish_point(Vector2(.98,.5),62,recover)),"head anchor is independent of tail deformation")
		for y: float in [.60,.61,.65,.75,1.0]:
			for x: float in [0,.25,.5,.75,1]:
				var uv:=Vector2(x,y)
				check(Motion.angler_point(uv,Vector2(224,147),pose).is_equal_approx(Vector2((x-.5)*224,-147+y*147)),"boat/lower-body texel stays stationary")
	var hand:=Vector2(150,400)
	var load_high:=thrust.duplicate();load_high.load=.95
	var load_low:=recover.duplicate();load_low.load=.05
	var high:=Motion.rod_points(hand,1,0,load_high)
	var low:=Motion.rod_points(hand,1,0,load_low)
	check(high.size()==33 and high[0]==hand,"continuous rod starts at exact hand")
	check(high[-1].y>low[-1].y+50,"loaded rod bends down toward fish")
	check(high[16].distance_to(high[0].lerp(high[-1],.5))>20,"rod has genuine curvature, not one rotated straight segment")
	var float_point:=Vector2(650,260)
	var taut:=Motion.line_points(high[-1],float_point,load_high)
	var slack:=Motion.line_points(high[-1],float_point,load_low)
	check(taut[0]==high[-1] and taut[-1].distance_to(float_point)<.001,"line follows exact rod tip and model float")
	check(slack[16].y-taut[16].y>30,"release restores visible line sag")
	var before:=snapshot(m)
	for i in range(600):
		var pose:=Motion.sample(m)
		Motion.fish_point(Vector2(.1,.5),62,pose)
		Motion.angler_point(Vector2(.5,.2),Vector2(224,147),pose)
		Motion.rod_points(hand,1,0,pose)
	check(snapshot(m)==before,"600 render samples cannot change any model property, input, time, score or reward")
	var quiet:=Motion.sample(m,true)
	check(quiet.body_bend==0 and quiet.tail_thrust==0 and quiet.human_lean==0,"reduced motion removes all secondary body and tail movement")
	# Same phase, actual model tension only: progressively stronger visible load.
	var previous_tip_y: float=-INF
	var previous_sag: float=INF
	var previous_effort: float=-1
	var previous_body_excursion: float=INF
	for value: float in [20,55,90]:
		m.tension=value
		var pose:=at(m,2,.5,true)
		var rod:=Motion.rod_points(Vector2.ZERO,1,0,pose)
		var line:=Motion.line_points(Vector2.ZERO,Vector2(200,0),pose)
		check(rod[-1].y>previous_tip_y,"same-phase rod bends monotonically with actual tension")
		check(line[16].y<previous_sag,"same-phase line sag decreases monotonically with actual tension")
		check(pose.effort>previous_effort and pose.human_lean<0,"held player effort increases monotonically with actual tension")
		check(absf(pose.body_bend)<previous_body_excursion,"fish excursion is restricted, never arbitrarily sped up by tension")
		previous_tip_y=rod[-1].y;previous_sag=line[16].y;previous_effort=pose.effort;previous_body_excursion=absf(pose.body_bend)
	var high_hold:=at(m,2,.5,true)
	var high_release:=at(m,2,.5,false)
	check(high_hold.load==high_release.load,"same high tension retains physical load on immediate release")
	check(high_hold.human_lean<0 and high_release.human_lean>0,"same-tension holding braces back; release reaches forward to feed line")
	check(Motion.line_points(Vector2.ZERO,Vector2(200,0),high_hold)[16].y<1,"90 percent actual tension is visually taut")
	check(Motion.line_points(Vector2.ZERO,Vector2(200,0),high_hold)==Motion.line_points(Vector2.ZERO,Vector2(200,0),high_release),"release cannot fake lower tension before model tension decays")
	check(Motion.angler_pose(high_hold)=="pull","high-tension hold uses the painted bent-elbow keyframe")
	check(Motion.angler_pose(high_release)=="release","release uses the painted extended-arm keyframe")
	m.tension=20
	check(Motion.angler_pose(at(m,2,.5,true))=="rest","low-tension hold retains a relaxed original keyframe")
	# Host-level pause/reset verification uses the actual view owner.
	root.get_node("State").developer_mode=true
	var host: Control=load("res://scripts/ui/minigame_host.gd").new();root.add_child(host)
	await process_frame
	host.setup({"type":"rhythm","chartId":"locker_key","spotId":"locker_key","title":"锈蚀钥匙","session_id":"motion-test"})
	host.set_process(false);host.begin();host.set_process(false)
	check(host.fishing_view.angler_poses.size()==2,"two independent painted elbow poses load")
	for texture: Texture2D in host.fishing_view.angler_poses.values():check(texture.get_size()==Vector2(1548,1016),"painted pose retains exact source registration canvas")
	for grip: Array in host.fishing_view.ANGLER_GRIPS.values():
		check(grip[0].y<610 and grip[1].y<610,"both hand anchors belong to the movable upper body")
	host.fishing_view.current_motion=pull.duplicate(true)
	host.toggle_pause()
	var fixed: String=JSON.stringify(host.fishing_view.current_motion)
	for i in range(8):host.fishing_view.advance_view(.1)
	check(JSON.stringify(host.fishing_view.current_motion)==fixed,"pause retains the displayed tug pose despite neutral input cleanup")
	host.fishing_view.reset_view()
	check(host.fishing_view.current_motion.is_empty(),"retry clears any cached previous tug pose")
	host.queue_free();await process_frame
	print("LAKE_FISHING_MOTION: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
