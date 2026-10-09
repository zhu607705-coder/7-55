extends SceneTree
const Space=preload("res://scripts/games/chapter4_chase_space.gd")
var checks:=0
var failures:=0
var report:Dictionary={}
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func length_of(points:Array,start:Vector2)->float:
	var total:=0.0;var previous:=start
	for point in points:total+=previous.distance_to(point);previous=point
	return total
func reference_trace(space:RefCounted,start_landing:int=0,step_ms:float=80.0)->Dictionary:
	var point:Vector2=space.vec(space.layout.landings[start_landing].spawn)
	var trace:Array=[];var time:=0.0;var total:=0.0;var gate:=start_landing;var prefixes:Dictionary={}
	var start_index:int=space.layout.landings[start_landing].route_index
	for target in space.route.slice(start_index+1):
		while point.distance_to(target)>.001:
			var moved:Vector2=point.move_toward(target,space.PLAYER_SPEED*step_ms/1000.0)
			total+=point.distance_to(moved);point=moved;time+=step_ms
			trace.append({"x":point.x,"y":point.y,"t":time})
			if gate<2 and space.gates[gate].has_point(point):
				gate+=1;prefixes[gate]=trace.duplicate(true)
	return {"path":trace,"elapsed":time,"distance":total,"prefixes":prefixes}
func dense_trace(space:RefCounted,wait_ms:float=0)->Dictionary:
	var point:Vector2=space.route[0];var trace:Array=[];var time:=0.0;var gate:=0;var prefixes:Dictionary={}
	while time<wait_ms:
		time+=minf(250,wait_ms-time);trace.append({"x":point.x,"y":point.y,"t":time})
	for target:Vector2 in space.route.slice(1):
		while point.distance_to(target)>.0001:
			point=point.move_toward(target,.9);time+=.01;trace.append({"x":point.x,"y":point.y,"t":time})
			if gate<2 and space.gates[gate].has_point(point):gate+=1;prefixes[gate]=trace.duplicate(true)
	return {"path":trace,"elapsed":time,"prefixes":prefixes}
func simulate_guard(space:RefCounted,from:Vector2,target:Vector2,seconds:float)->Dictionary:
	var point:=from;var elapsed:=0.0;var next:Variant=null;var repath:=0.0;var open:=true;var contact:=false
	while elapsed<seconds and not contact:
		if repath<=0 or next==null or point.distance_to(next)<.05:
			var path:Array=space.path(point,target);next=path[0] if not path.is_empty() else null;repath=.26
		if next!=null:
			var candidate:=point.move_toward(next,space.GUARD_SPEED*.05)
			open=open and space.segment_open(point,candidate,space.GUARD_BODY)
			point=candidate
		repath-=.05;elapsed+=.05;contact=point.distance_to(target)<=22
	return {"position":point,"elapsed":elapsed,"contact":contact,"all_segments_open":open}
func run()->void:
	var started:=Time.get_ticks_usec();var space:=Space.new()
	report.build_ms=(Time.get_ticks_usec()-started)/1000.0
	check(space.world.size==Vector2(3000,1540),"Independent scene uses authored extended bounds, not the original bitmap")
	check(space.PLAYER_SPEED==208 and space.GUARD_SPEED==174,"Original actor speeds remain unchanged")
	check(space.layout.landings.size()==3 and space.gates.size()==2,"The original logical 0/1/2 platforms remain")
	check(space.obstacles.size()==9 and space.layout.presentation_requirements.minimum_obstacle_gap==100,"Nine readable obstacles leave 100-pixel routes")
	check(space.navigation.size()<100,"Bounded authored navigation graph")
	for point in space.route:check(space.body_open(point) and space.body_open(point,space.GUARD_BODY),"Reference route is legal for both full actor bodies")
	for i in range(1,space.route.size()):check(space.segment_open(space.route[i-1],space.route[i],space.GUARD_BODY),"Reference path segment %d does not cut an obstacle or void"%i)
	for obstacle in space.obstacles:
		check(not space.body_open(obstacle.get_center()),"Obstacle blocks the player")
		check(not space.body_open(obstacle.get_center(),space.GUARD_BODY),"Same obstacle blocks the guard")
		var y:float=obstacle.get_center().y
		check(not space.segment_open(Vector2(obstacle.position.x-40,y),Vector2(obstacle.end.x+40,y)),"Swept path cannot jump through storage or railing")
	for illegal in [Vector2(-1,1300),Vector2(1500,1000),Vector2(1500,520),Vector2(INF,280),Vector2(0,0)]:
		check(not space.body_open(illegal),"Void, nonfinite and outside positions are blocked")
	var full:=reference_trace(space)
	report.route_units=full.distance;report.input_time_ms=full.elapsed
	report.minimum_travel_seconds=full.distance/space.PLAYER_SPEED
	check(full.distance>8500 and full.distance<11000,"Longer play comes from real travel distance, not delay or speed reduction")
	check(space.valid_trace(full.path,0,2,true,full.elapsed),"Whole physical reference trace passes new-space proof")
	var previous:Array=[]
	for gate in [1,2]:
		var prefix:Array=full.prefixes[gate]
		check(space.valid_trace(prefix,0,gate,false,float(prefix.back().t),previous),"Platform %d requires actual continuous traversal"%gate)
		previous=prefix
	check(space.valid_trace(full.path,0,2,true,full.elapsed,previous),"Final route retains both accepted prefixes")
	for fps in [60,120,240]:
		var high_rate:=reference_trace(space,0,1000.0/fps)
		check(space.valid_trace(high_rate.path,0,2,true,high_rate.elapsed),"Real per-frame float movement remains valid at %d FPS"%fps)
	for landing in [1,2]:
		var resumed:=reference_trace(space,landing)
		check(space.valid_trace(resumed.path,landing,2,true,resumed.elapsed),"Resume at logical platform %d still traverses remaining course"%landing)
	for lead in [650,1250,2000,INF,-200]:
		for landing in [0,1,2]:
			var entry:Dictionary=space.guard_entry(landing,lead)
			check(space.body_open(entry.player) and space.body_open(entry.guard,space.GUARD_BODY),"All restored actor spawns fit their bodies")
			check(is_finite(entry.delayMs) and entry.delayMs>=0,"Original bounded lead produces a finite guard delay")
	var bad:Array=full.path.duplicate(true);bad[4].x+=300
	check(not space.valid_trace(bad,0,2,true,full.elapsed),"Teleport is rejected")
	bad=full.path.duplicate(true);bad[4].t=bad[3].t
	check(not space.valid_trace(bad,0,2,true,full.elapsed),"Repeated time is rejected")
	bad=full.path.duplicate(true);bad[4].t=float(bad[3].t)+251
	check(not space.valid_trace(bad,0,2,true,full.elapsed),"Unbounded step time is rejected")
	bad=full.path.duplicate(true);bad[4].x=INF
	check(not space.valid_trace(bad,0,2,true,full.elapsed),"Nonfinite proof is rejected")
	bad=full.path.duplicate(true);bad[0].x+=1
	check(not space.valid_trace(bad,0,2,true,full.elapsed,full.prefixes[1]),"Changed accepted prefix is rejected")
	check(not space.valid_trace([{"x":2820,"y":280,"t":80}],0,2,true,80),"An exit coordinate cannot skip both platforms")
	check(not space.valid_trace(full.prefixes[1],0,2,false,full.elapsed),"First platform proof cannot claim the second")
	check(not space.valid_trace(full.path,0,2,true,full.elapsed-1),"Elapsed clock cannot precede its trace")
	for wait_ms in [0.0,50000.0]:
		var forged:=dense_trace(space,wait_ms)
		check(forged.path.size()<20000,"Dense attack remains below the existing proof-size cap")
		check(not space.valid_trace(forged.path,0,2,true,forged.elapsed),"Per-sample rounding cannot manufacture travel, even after waiting")
		for gate in [1,2]:
			var prefix:Array=forged.prefixes[gate]
			check(not space.valid_trace(prefix,0,gate,false,float(prefix.back().t)),"Dense forged platform proof is rejected before it can become an accepted prefix")
	var rounding:Array=[{"x":180.5,"y":1320,"t":.01}]
	check(space.valid_trace(rounding,0,-1,false,.01),"One subpixel rounding discrepancy remains tolerated")
	rounding.append({"x":181.4,"y":1320,"t":.02})
	check(not space.valid_trace(rounding,0,-1,false,.02),"The same discrepancy cannot be spent again on a later sample")
	var rng:=RandomNumberGenerator.new();rng.seed=755
	var nav_times:Array=[];var examples:=0
	for floor_rect in space.floors:
		for _i in 20:
			var target:=Vector2(rng.randf_range(floor_rect.position.x+14,floor_rect.end.x-14),rng.randf_range(floor_rect.position.y+14,floor_rect.end.y-14))
			if not space.body_open(target,space.GUARD_BODY):continue
			started=Time.get_ticks_usec();var path:Array=space.path(space.route[0],target);nav_times.append((Time.get_ticks_usec()-started)/1000.0)
			check(not path.is_empty(),"Guard can route to arbitrary legal corridor position")
			var last:Vector2=space.route[0]
			for point in path:check(space.segment_open(last,point,space.GUARD_BODY),"Guard path cannot cross an obstacle or wall");last=point
			examples+=1
	report.navigation_queries=examples;nav_times.sort();report.navigation_p95_ms=nav_times[int((nav_times.size()-1)*.95)]
	var chase:=simulate_guard(space,Vector2(760,1260),Vector2(1080,1260),8)
	check(chase.all_segments_open and chase.contact,"Guard actually routes around a blocker and catches a stationary player")
	check(chase.elapsed>320.0/174.0,"Obstacle detour takes physical travel time")
	var edge_target:=Vector2(69.8,1250)
	check(space.body_open(edge_target) and not space.body_open(edge_target,space.GUARD_BODY),"Player and guard foot-width edge case is exercised")
	check(not space.path(Vector2(180,1320),edge_target).is_empty(),"Narrower player body cannot make the guard freeze against an edge")
	report.checks=checks;report.failures=failures
	var path:=OS.get_environment("CHASE_SPACE_REPORT")
	if not path.is_empty():FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("CHAPTER4_CHASE_SPACE ",JSON.stringify(report))
	quit(1 if failures else 0)
