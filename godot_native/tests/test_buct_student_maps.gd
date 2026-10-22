extends SceneTree
## Checks the real formal campus actors, not an isolated artwork canvas.
var failures: Array[String]=[]
var checks:=0
func _init() -> void:call_deferred("run")
func frames(count:=2) -> void:
	for i in range(count):await physics_frame
func expect(value: bool,label: String) -> void:
	checks+=1;print("PASS " if value else "FAIL ",label)
	if not value:failures.append(label)
func run() -> void:
	for campus in ["buct_haidian","buct","buct_changping"]:
		var app=load("res://campuses/"+campus+"/scenes/playable.tscn").instantiate();root.add_child(app);await frames(3)
		var actor=app.visitor;var visual=actor.get_node_or_null("StudentVisual")
		expect(visual!=null and visual.ready_to_show and visual.sprite.visible and visual.sprite.texture!=null,campus+" actual CampusVisitor owns visible registered approved artwork")
		if visual==null:app.queue_free();await frames();continue
		expect(actor.get_parent()==app.objects and actor.get_node("FeetCollision").shape.radius==3 and actor.speed==88,campus+" actual original sorted world and movement contract retained")
		expect(visual.target_height==18.0 and visual.current_foot_global().distance_to(actor.global_position)<0.001,campus+" uniform scale and exact controller foot anchor")
		expect(is_equal_approx(float(visual.profile.cycle_stride_body_heights),2.6),campus+" map-specific distance stride is calibrated without changing source profile")
		var safe:=Vector2.ZERO
		var best_safe_distance:=INF
		var preferred:=Vector2(750,405) if campus=="buct_haidian" else (Vector2(515,1230) if campus=="buct_changping" else Vector2(750,700))
		for cell in app.walk_cells:
			var candidate: Vector2=Vector2(cell)*app.CELL+Vector2.ONE*app.CELL*.5;var valid:=true
			for delta in [Vector2(-12,0),Vector2(12,0),Vector2(0,-12),Vector2(0,12)]:valid=valid and app.is_walkable(candidate+delta)
			if valid and candidate.distance_squared_to(preferred)<best_safe_distance:
				safe=candidate;best_safe_distance=candidate.distance_squared_to(preferred)
		if campus=="buct_changping":safe=Vector2(app.data.spawn[0],app.data.spawn[1])
		else:expect(safe!=Vector2.ZERO,campus+" authored paving has four-way testing space")
		var prefix: String="buct_haidian_walk_" if campus=="buct_haidian" else ("buct_changping_walk_" if campus=="buct_changping" else "buct_walk_")
		for direction in ["right","left","down","up"]:
			if campus=="buct_changping":
				# Narrow Changping paths support directions at different positions, not one invented plaza.
				var vector: Vector2={"right":Vector2.RIGHT,"left":Vector2.LEFT,"down":Vector2.DOWN,"up":Vector2.UP}[direction]
				safe=Vector2.ZERO
				for cell in app.walk_cells:
					var candidate: Vector2=app.grid.get_point_position(cell);var valid:=true
					for step in range(14):valid=valid and app.is_walkable(candidate+vector*step)
					if valid:safe=candidate;break
				expect(safe!=Vector2.ZERO,campus+" original bounded route supports physical "+direction+" input")
			actor.position=safe;app.current_path.clear();app.guide_active=false;app.guide_pause=0;app.close_info()
			Input.action_press(prefix+direction)
			var observed: Dictionary={};var phase_before: float=visual.distance_phase
			for i in range(7):await physics_frame;observed[visual.frame_index]=true
			Input.action_release(prefix+direction);await frames(2)
			expect(actor.position.distance_to(safe)>1 and visual.facing==direction,campus+" real controller moves and faces "+direction)
			expect(observed.size()>1 and not visual.walking and visual.frame_index==0,campus+" walking frames advance then stop in directional idle "+direction)
			expect(visual.current_foot_global().distance_to(actor.global_position)<0.001,campus+" feet remain registered "+direction)
			expect(visual.profile.directions[direction].walk.size()==(6 if direction=="up" else 8),campus+" approved frame count "+direction)
		# Hold real movement into an authored paving boundary. Blocked input must stop the artwork.
		var wall_start:=Vector2.ZERO
		for cell in app.walk_cells:
			var candidate: Vector2=Vector2(cell)*app.CELL+Vector2.ONE*app.CELL*.5
			if app.is_walkable(candidate) and not app.is_walkable(candidate+Vector2(16,0)):
				wall_start=candidate;break
		expect(wall_start!=Vector2.ZERO,campus+" original map offers a real blocked boundary")
		actor.position=wall_start;app.current_path.clear();Input.action_press(prefix+"right");await frames(30)
		var stopped_position: Vector2=actor.position;var stopped_phase: float=visual.distance_phase
		await frames(5)
		expect(actor.position.distance_to(stopped_position)<0.001 and actor.last_motion==Vector2.ZERO and not visual.walking,campus+" held input at blocked boundary never walks in place")
		expect(visual.distance_phase==stopped_phase,campus+" blocked frames preserve the animation phase")
		Input.action_release(prefix+"right");await frames()
		# An impossible next point must not create in-place walk motion.
		actor.position=safe;app.overview=true;Input.action_press(prefix+"right");await frames(3);Input.action_release(prefix+"right")
		expect(not visual.walking and actor.last_motion==Vector2.ZERO,campus+" paused controller renders idle")
		app.overview=false
		var start: Vector2=Vector2(app.data.spawn[0],app.data.spawn[1]);app.return_to_gate();await frames()
		expect(actor.position==start,campus+" first gate return preserves original feet")
		actor.position=safe;app.return_to_gate();await frames()
		expect(actor.position==start,campus+" repeated gate return preserves original feet")
		if campus=="buct_changping":
			app.visited.clear();app.start_guide()
			var route_ticks:=0;var violations:=0;var animation_ticks:=0
			while app.guide_active and route_ticks<2000:
				await physics_frame;route_ticks+=1
				if not app.is_walkable(actor.position):violations+=1
				if visual.walking:animation_ticks+=1
			expect(not app.guide_active and app.visited.size()==3,campus+" original three-POI route physically completes")
			expect(violations==0 and animation_ticks>100,campus+" complete guide remains collision constrained with actual student movement")
			print("CHANGPING_INTEGRATED_ROUTE ticks=",route_ticks," animation_ticks=",animation_ticks," violations=",violations)
		app.queue_free();await frames(3)
	print("BUCT_STUDENT_REAL_MAPS ","PASS" if failures.is_empty() else "FAIL"," checks=",checks," errors=",failures)
	quit(0 if failures.is_empty() else 1)
