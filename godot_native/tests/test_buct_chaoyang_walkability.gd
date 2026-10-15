extends SceneTree
## Actual Godot scene/AStar/CharacterBody2D test for the two outdoor road branches.
var failures: Array[String] = []
var checks := 0
var walking_samples := 0
var report := {"schema":"buct-chaoyang-west-sector-native-v1","endpoints":[],"blocked":[],"depth":[]}
func verify(value: bool, message: String) -> void:
	checks += 1
	print("PASS " if value else "FAIL ", message)
	if not value: failures.append(message)
func _init() -> void:
	call_deferred("run_tests")
func frames(count: int) -> void:
	for i in range(count): await physics_frame
func as_point(value: Array) -> Vector2:
	return Vector2(value[0],value[1])
func run_tests() -> void:
	var app: Node2D = load("res://campuses/buct/scenes/playable.tscn").instantiate()
	root.add_child(app)
	await frames(3)
	verify(app.data.route_waypoints.size()==29 and app.data.landmarks.size()==3,"Original 29-stop guide and three landmarks retained")
	verify(app.data.walkable_polygons.size()==57,"35 road-segment polygons extend the 22 original paving polygons")
	verify(app.visitor.get_node("FeetCollision").shape.radius==3.0 and app.visitor.speed==88.0,"Original foot collider and movement speed retained")
	verify(app.visitor.get_node("StudentVisual").ready_to_show,"Genuine shared student is configured")
	verify(app.grid.diagonal_mode==AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES,"AStar prevents blocked-corner diagonal steps")
	for item in app.data.exploration_endpoints:
		app.return_to_gate()
		var target := as_point(item.position)
		var path: PackedVector2Array = app.grid.get_point_path(app.nearest_cell(app.visitor.position),app.nearest_cell(target))
		verify(app.is_walkable(target) and not path.is_empty(),"Original spawn connects to "+str(item.id))
		var clear := true
		for i in range(1,path.size()):
			var steps := ceili(path[i-1].distance_to(path[i])*4)
			for j in range(steps+1):
				clear=clear and app.is_walkable(path[i-1].lerp(path[i],float(j)/steps))
		verify(clear,"Every AStar edge stays on allowed paving: "+str(item.id))
		var endpoint_report := {"id":item.id,"path_points":path.size(),"edge_samples_clear":clear}
		# Walk to the two far ends at the original 88 px/s using the real process loop.
		if item.id in ["sports_side_junction","library_west_north_junction"]:
			app.path_to(target)
			# Grid centre may be sqrt(8) px from the authored endpoint; the
			# unchanged controller stops within 2.5 px of its final path point.
			var ticks := 0
			var violations := 0
			var stalled_ticks := 0
			var previous: Vector2 = app.visitor.position
			while ticks<1800 and app.visitor.position.distance_to(target)>6.0:
				await physics_frame
				ticks+=1;walking_samples+=1
				if not app.is_walkable(app.visitor.position):violations+=1
				if app.visitor.position.distance_to(previous)<0.001:stalled_ticks+=1
				else:stalled_ticks=0
				previous=app.visitor.position
				if stalled_ticks>120:break
			verify(app.visitor.position.distance_to(target)<=6.0,"Actual student walks from original spawn to "+str(item.id))
			verify(violations==0,"All real physics positions stay on paving: "+str(item.id))
			endpoint_report["physics_ticks"]=ticks
			endpoint_report["paving_violations"]=violations
			endpoint_report["arrived"]=app.visitor.position.distance_to(target)<=6.0
			endpoint_report["final_feet"]=[app.visitor.position.x,app.visitor.position.y]
		report.endpoints.append(endpoint_report)
	for item in app.data.excluded_probe_points:
		var blocked: bool = not app.is_walkable(as_point(item.position))
		verify(blocked,"Excluded surface remains blocked: "+str(item.id))
		report.blocked.append({"id":item.id,"blocked":blocked})
	# Actual held input hits the sports lane's west curb without entering a blue court.
	app.return_to_gate();app.visitor.position=Vector2(420,522)
	Input.action_press("buct_walk_left");await frames(25);Input.action_release("buct_walk_left")
	verify(app.is_walkable(app.visitor.position) and app.visitor.position.x>410,"Held keyboard movement cannot cross the sports curb into the court")
	# These tiny ground feet block physics; source-pixel canopy polygons are visual only.
	for probe in [{"id":"west_lane_yellow_curb_canopy","behind":Vector2(417,618),"front":Vector2(419,624)}, {"id":"library_west_avenue_west_canopy","behind":Vector2(606,505),"front":Vector2(608,524)}]:
		var tree: Node2D=app.objects.get_node(probe.id)
		var canopy: Polygon2D=tree.get_node("OriginalCanopyOccluder")
		var uv_ok := true
		for i in range(canopy.polygon.size()):uv_ok=uv_ok and canopy.polygon[i]+tree.position==canopy.uv[i]
		verify(uv_ok,"Added crown uses exact original image UVs: "+str(probe.id))
		verify(tree.get_node("TrunkFeetCollision").get_child(0).shape.radius==1.5,"Added crown has only a tiny inferred trunk collider: "+str(probe.id))
		app.visitor.position=probe.behind;await frames(2);app._process(0)
		verify(app.is_walkable(probe.behind) and app.visitor_head_occluded(),"Student can stand beneath the roadside crown: "+str(probe.id))
		app.visitor.position=probe.front;await frames(2);app._process(0)
		verify(app.is_walkable(probe.front) and not app.visitor_head_occluded(),"Student emerges in front of the same crown: "+str(probe.id))
		app.visitor.position=tree.position+Vector2(8,0);await frames(2)
		verify(app.visitor.test_move(app.visitor.global_transform,Vector2(-8,0)),"Native inferred trunk stops feet: "+str(probe.id))
		report.depth.append({"id":probe.id,"source_uv_exact":uv_ok,"ground_depth":tree.position.y,"behind":[probe.behind.x,probe.behind.y],"front":[probe.front.x,probe.front.y]})
	app.return_to_gate()
	verify(app.visitor.position==as_point(app.data.spawn) and app.current_path.is_empty(),"Reset returns to the original spawn and cancels branch movement")
	app.queue_free();await process_frame
	for action in ["buct_walk_left","buct_walk_right","buct_walk_up","buct_walk_down","buct_walk_fast"]:verify(not InputMap.has_action(action),"Owned input removed on exit: "+action)
	report["checks"]=checks;report["walking_samples"]=walking_samples;report["failures"]=failures
	report["limit"]="Authored outdoor branches only; no campus-wide or surveyed-navigation claim. Rendered depth pixels are reviewed separately."
	var report_path := OS.get_environment("BUCT_WALKABILITY_NATIVE_REPORT")
	if not report_path.is_empty():
		var file:=FileAccess.open(report_path,FileAccess.WRITE)
		if file:file.store_string(JSON.stringify(report,"\t")+"\n")
	print("BUCT_CHAOYANG_WALKABILITY ","PASS" if failures.is_empty() else "FAIL"," checks=",checks," walking_samples=",walking_samples," failures=",failures.size())
	quit(0 if failures.is_empty() else 1)
