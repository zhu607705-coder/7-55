extends SceneTree
const Rig = preload("res://scripts/presentation/kayak_rig.gd")
const Motion = preload("res://scripts/presentation/kayak_stroke_timeline.gd")
var checks: int=0
var failures: Array[String]=[]
func check(ok: bool,label: String)->void:
	checks+=1
	if not ok and not failures.has(label):failures.append(label)
func _initialize()->void:call_deferred("run")
func run()->void:
	var rig=Rig.new();root.add_child(rig)
	var max_recovery_water:float=0
	for side:String in ["left","right"]:
		for reverse:bool in [false,true]:
			rig.reset();rig.sync_pose(Vector2(100,100),-PI/2,0,0,1,0,true,Vector2(820,520));rig.request_stroke(side,reverse)
			var saw_wet:bool=false;var emitted_exit:bool=false
			for frame:int in range(1000):
				rig.advance(.001)
				var p:Dictionary=rig.motion.pose()
				var min_depth:float=9.0+float(p.lift)-86*absf(sin(float(p.pitch)))
				if rig.motion.phase()=="recovery":
					max_recovery_water=maxf(max_recovery_water,rig.water_strength)
					check(min_depth>=0,"Recovery blade endpoints must be above water")
				if rig.water_strength>.02:
					saw_wet=true
					check(rig.submerged_index==(0 if side=="left" else 1),"Isolated stroke only wets requested blade")
				for drop:Dictionary in rig.spray:
					if drop.large:emitted_exit=true
			check(saw_wet,"Every isolated stroke touches water")
			check(emitted_exit,"Every isolated stroke emits exit droplets")
	print("ISOLATED ",JSON.stringify({"max_recovery_water":max_recovery_water}))
	for cadence:float in [.9,.36,.18]:
		rig.reset();var event_index:int=0;var last_starts:int=0;var starts:Array=[];var wrong_wet:int=0;var first_right:float=-1
		for frame:int in range(6000):
			var time:float=frame*.001
			if event_index<20 and time+0.00001>=event_index*cadence:
				var before:Dictionary=rig.motion.pose()
				rig.request_stroke("left" if event_index%2==0 else "right")
				var after:Dictionary=rig.motion.pose()
				for key:String in ["sweep","pitch","lean","twist","lift"]:check(absf(before[key]-after[key])<.00001,"No pose jump at a new cadence/input")
				event_index+=1
			rig.advance(.001)
			if rig.motion.started_strokes!=last_starts:
				last_starts=rig.motion.started_strokes;starts.append({"time":time,"side":rig.motion.side})
				if first_right<0 and rig.motion.side=="right":first_right=time
			if rig.water_strength>.02 and rig.submerged_index!=(0 if rig.motion.side=="left" else 1):wrong_wet+=1
		check(rig.motion.started_strokes==rig.motion.accepted_intents,"Cadence preserves each accepted stroke")
		for i:int in range(1,starts.size()):check(starts[i].side!=starts[i-1].side,"Cadence preserves strict left-right alternation")
		print("CADENCE ",JSON.stringify({"cadence":cadence,"intents":rig.motion.accepted_intents,"started":rig.motion.started_strokes,"first_right":first_right,"old_wet_samples_during_blend":wrong_wet,"starts":starts}))
	rig.reset();rig.sync_pose(Vector2(100,100),-PI/2,0,0,1,0,true,Vector2(820,520));rig.request_stroke("left")
	for i:int in range(240):rig.advance(.001)
	check(not rig.spray.is_empty(),"World particle test has droplets")
	var drop:Dictionary=rig.spray[0].duplicate(true)
	var orig_local:Vector2=(Vector2(drop.point)-rig.boat_world_position).rotated(-rig.rotation)/.52
	rig.sync_pose(Vector2(100,100),.8,0,0,3.5,0,true,Vector2(840,515))
	check(drop==rig.spray[0],"Existing particle point/velocity stay unchanged during boat transform")
	var new_local:Vector2=(Vector2(drop.point)-rig.boat_world_position).rotated(-rig.rotation)/.52
	check(orig_local.distance_to(new_local)>1,"Particle local coordinates compensate boat movement")
	check(rig._local_to_world(new_local).distance_to(Vector2(drop.point))<.0001,"Particle world round trip matches stored anchor")
	rig.reset();rig.sync_pose(Vector2.ZERO,-PI/2,0,0,1,0,true,Vector2.ZERO)
	rig.motion.reverse=false;rig._emit_splash(Vector2.ZERO,1,false);var forward:Vector2=rig.spray[-1].velocity
	rig.motion.reverse=true;rig._emit_splash(Vector2.ZERO,1,false);var back:Vector2=rig.spray[-1].velocity
	check(is_equal_approx(forward.x,back.x) and is_equal_approx(forward.y,-back.y),"Reverse spray mirrors longitudinal velocity")
	var preview=load("res://scenes/qizhen_swan_entrance_preview.tscn").instantiate();root.add_child(preview);preview.set_process(false);preview.skip_intro()
	for i:int in range(4):preview.stroke("left")
	var before_inputs:int=preview.kayak.inputs.size();var before_visual:int=preview.paddler.motion.accepted_intents
	preview.stroke("right")
	print("POST_LOSS ",JSON.stringify({"status":preview.kayak.status,"model_before":before_inputs,"model_after":preview.kayak.inputs.size(),"visual_before":before_visual,"visual_after":preview.paddler.motion.accepted_intents}))
	check(preview.kayak.inputs.size()==before_inputs and preview.paddler.motion.accepted_intents==before_visual,"No post-loss visual-only stroke")
	print("AUDIT ",JSON.stringify({"checks":checks,"failures":failures}))
	preview.queue_free();rig.queue_free();quit(0 if failures.is_empty() else 1)
