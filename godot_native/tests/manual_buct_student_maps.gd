extends SceneTree
## Manual QA fixture only: selects a valid start point. It never injects input or walks the actor.
func _init() -> void:call_deferred("run")
func run() -> void:
	var campus:=OS.get_environment("BUCT_STUDENT_MANUAL_CAMPUS")
	if campus not in ["buct","buct_haidian"]:campus="buct_haidian"
	var app=load("res://campuses/"+campus+"/scenes/playable.tscn").instantiate();root.add_child(app)
	await physics_frame;await physics_frame
	var preferred:=Vector2(750,405) if campus=="buct_haidian" else Vector2(750,700)
	var safe:=Vector2.ZERO;var best:=INF
	for cell in app.walk_cells:
		var candidate: Vector2=Vector2(cell)*app.CELL+Vector2.ONE*app.CELL*.5;var valid:=true
		for delta in [Vector2(-12,0),Vector2(12,0),Vector2(0,-12),Vector2(0,12)]:valid=valid and app.is_walkable(candidate+delta)
		var distance: float=candidate.distance_squared_to(preferred)
		if valid and distance<best:safe=candidate;best=distance
	if safe==Vector2.ZERO:push_error("No valid manual fixture");quit(1);return
	app.visitor.position=safe;app.current_path.clear();app.close_info()
	app.camera.position=app._walking_camera_position();app.camera.reset_smoothing();app.camera.force_update_scroll()
	print("MANUAL_QA_READY campus=",campus," feet=",safe," no automated input; use actual physical WASD, release, and opposite keys")
	root.window_input.connect(func(event: InputEvent):
		if event is InputEventKey and not event.echo:print("MANUAL_WINDOW_KEY pressed=",event.pressed," physical=",event.physical_keycode," key=",event.keycode," feet=",app.visitor.position," facing=",app.visitor.character_visual.facing," walking=",app.visitor.character_visual.walking))
