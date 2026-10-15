extends SceneTree
## Focused integration of the accepted L building and the original-art west-road sector.
## The primary route starts at the actual south-gate spawn and never repositions the actor.
var checks := 0
var failures: Array[String] = []
var report := {"schema":"buct-roads-l-integration-v1","arrivals":[],"trace":[]}
func _init() -> void:call_deferred("run")
func check(value: bool,label: String) -> void:
	checks+=1;print("PASS " if value else "FAIL ",label)
	if not value:failures.append(label)
func frames(count: int) -> void:
	for i in range(count):await physics_frame
func run() -> void:
	var app=load("res://campuses/buct/scenes/playable.tscn").instantiate();root.add_child(app);await frames(3)
	check(app.visitor.position==Vector2(744,979),"Continuous route starts at the original south-gate spawn")
	check(app.visitor.speed==88.0 and app.visitor.get_node("FeetCollision").shape.radius==3.0 and app.visitor.character_visual.target_height==18.0,"Shared student height, foot collider and speed are unchanged")
	check(app.l_building!=null and app.l_building.collision_shapes.size()==3 and app.l_building.foliage_nodes.size()==4,"Accepted L body, three foot contacts and four source-leaf groups coexist")
	check(app.data.route_waypoints.size()==29 and app.data.landmarks.size()==3,"Original three-landmark 29-stop guide retained")
	check(app.data.occluders.size()==10 and app.data.walkable_polygons.size()==57,"Both outdoor branches and two narrow roadside crown groups are installed")
	var targets: Array[Vector2]=[Vector2(422,748),Vector2(416,436),Vector2(422,748),Vector2(613,711),Vector2(612,416)]
	var total_ticks := 0;var violations := 0;var jumps := 0;var max_step := 0.0
	for target in targets:
		var path: PackedVector2Array=app.grid.get_point_path(app.nearest_cell(app.visitor.position),app.nearest_cell(target))
		var clear:=not path.is_empty()
		for i in range(1,path.size()):
			var samples:=ceili(path[i-1].distance_to(path[i])*4)
			for j in range(samples+1):clear=clear and app.is_walkable(path[i-1].lerp(path[i],float(j)/samples))
		check(clear,"Native AStar and every sub-edge avoid blocked surfaces toward "+str(target))
		app.path_to(target)
		var segment_ticks:=0;var stalled:=0
		while app.visitor.position.distance_to(target)>6.0 and segment_ticks<1600:
			var before: Vector2=app.visitor.position
			await physics_frame;segment_ticks+=1;total_ticks+=1
			var after: Vector2=app.visitor.position;var step:=before.distance_to(after);max_step=maxf(max_step,step)
			if step>88.0/Engine.physics_ticks_per_second+0.06:jumps+=1
			if not app.is_walkable(after):violations+=1
			stalled=stalled+1 if step<0.001 else 0
			report.trace.append([total_ticks,after.x,after.y])
			if stalled>120:break
		var arrived: bool=app.visitor.position.distance_to(target)<=6.0
		check(arrived,"Actual continuous student reaches "+str(target))
		report.arrivals.append({"target":[target.x,target.y],"feet":[app.visitor.position.x,app.visitor.position.y],"tick":total_ticks,"arrived":arrived})
		if not arrived:break
	check(violations==0,"Every continuous-route foot position stays on authored paving")
	check(jumps==0,"No repositioning, teleport or overspeed occurs during the continuous route")
	for item in app.data.excluded_probe_points:check(not app.is_walkable(Vector2(item.position[0],item.position[1])),"Blocked surface retained: "+str(item.id))
	# Test the new accepted building's outward-facing neutral interaction in the real map.
	app.current_path.clear();await frames(2)
	var visited_before: Array=app.visited.duplicate();var progress_before: String=app.progress.text;var feet_before: Vector2=app.visitor.position
	check(app.landmark_at(Vector2(520,640))=="west_inner_l_block" and app.landmark_at(Vector2(520,690))=="","L picking follows actual alpha and leaves transparent exterior unselected")
	app.show_landmark("west_inner_l_block")
	check(app.info_id=="west_inner_l_block" and app.info_panel.visible and app.l_building.selected,"Neutral L building card still opens")
	check(not app.ui_controls.library_toggle.visible and not app.ui_controls.library_reset.visible,"L card exposes no unsupported hide/move controls")
	Input.action_press("buct_walk_left");await frames(4);Input.action_release("buct_walk_left")
	check(app.visitor.position==feet_before,"L card pauses movement without moving the student")
	app.close_info()
	check(not app.info_panel.visible and not app.l_building.selected and app.visited==visited_before and app.progress.text==progress_before,"Closing L card preserves the original three-landmark progress")
	# This starts a separate, explicit reset/guide journey after the continuous proof ends.
	app.return_to_gate();check(app.visitor.position==Vector2(744,979) and app.current_path.is_empty(),"Explicit return clears the outdoor route and restores original spawn")
	app.visited.clear();app.start_guide();var guide_ticks:=0;var guide_violations:=0
	while app.guide_active and guide_ticks<2400:
		await physics_frame;guide_ticks+=1
		if not app.is_walkable(app.visitor.position):guide_violations+=1
	check(not app.guide_active and app.visited.size()==3 and app.info_id=="library","Original guided journey still reaches all three landmarks")
	check(guide_violations==0,"Original guide remains on valid ground beside the accepted L footprint")
	app.close_info();app.return_to_gate();app.queue_free();await process_frame
	for action in ["buct_walk_left","buct_walk_right","buct_walk_up","buct_walk_down","buct_walk_fast"]:check(not InputMap.has_action(action),"Scene teardown removes owned input: "+action)
	report["checks"]=checks;report["failures"]=failures;report["continuous_physics_ticks"]=total_ticks;report["continuous_paving_violations"]=violations;report["continuous_teleport_or_overspeed"]=jumps;report["max_step_px"]=max_step;report["guide_ticks"]=guide_ticks;report["guide_violations"]=guide_violations
	report["limits"]="Focused Chaoyang scene merge check. No new art, interiors, semantic tiles, whole-game save claim, water access or campus-wide road claim. Other accepted buildings are unchanged and not broadly re-tested here."
	var output:=OS.get_environment("BUCT_ROADS_L_REPORT")
	if not output.is_empty():
		var file:=FileAccess.open(output,FileAccess.WRITE)
		if file:file.store_string(JSON.stringify(report,"\t")+"\n")
	print("BUCT_ROADS_L_INTEGRATION ","PASS" if failures.is_empty() else "FAIL"," checks=",checks," continuous_ticks=",total_ticks," guide_ticks=",guide_ticks," violations=",violations," jumps=",jumps)
	quit(0 if failures.is_empty() else 1)
