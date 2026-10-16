extends SceneTree
const Geometry=preload("res://scripts/games/chapter4_chase_space.gd")
var checks:=0
var failures:=0
func _initialize()->void:run.call_deferred()
func _guard_isolated_profile()->bool:
	if OS.get_user_data_dir().begins_with("/tmp/"):return true
	push_error("Refusing chase integration tests outside an isolated /tmp profile; ordinary saves must remain untouched.")
	quit(2);return false
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func frames(n:int=2)->void:
	for i in n:await process_frame
func issue(state:Node)->Dictionary:
	state.begin_checkpoint("c4-755-chase")
	return state.act("c4_chase",{"expectedAttempt":state.d.chapter4.chaseAttempt,"leadDistance":650})
func make_game(state:Node,config:Dictionary)->Control:
	var game:Control=load(config.script).new();root.add_child(game);game.setup(config);game.set_process(false)
	game.progress_requested.connect(func(proof):game.resolve_progress(state.act("c4_chase_landing",proof)))
	game.completed.connect(func(proof):state.act("c4_chase_done",proof))
	return game
func drive(game:Control,targets:Array)->void:
	for target:Vector2 in targets:
		var safety:=0;game.pointer_moving=true;game.pointer_target=target
		while game.player.distance_to(target)>=8 and not game.done and game.stage=="chase" and safety<1500:
			game.elapsed+=50;game._chase(.05);safety+=1
		game.pointer_moving=false
		check(safety<1500,"Reference pointer route cannot stall at an invisible barrier")
		if game.done or game.stage!="chase":break
func drive_touch(game:Control,targets:Array)->void:
	var held:=false
	for target:Vector2 in targets:
		var safety:=0
		while game.player.distance_to(target)>=8 and not game.done and game.stage=="chase" and safety<1500:
			# Use the real screen-to-world input path. A nearby point stays on the
			# visible field while the following camera changes the projection.
			var aim:Vector2=game.player.move_toward(target,120)
			var screen:Vector2=game.chase_view.global_position+game.chase_view.world_root.position+aim*game.chase_view.factor
			if not held:
				var down:=InputEventScreenTouch.new();down.index=7;down.position=screen;down.pressed=true
				game._chase_input(down);held=true
			else:
				var drag:=InputEventScreenDrag.new();drag.index=7;drag.position=screen;game._chase_input(drag)
			game.elapsed+=50;game.chase_animation_ms+=50;game._chase(.05);game._present_chase();safety+=1
		check(safety<1500,"Native touch-event route cannot stall at a camera or collision boundary")
		if game.done or game.stage!="chase":break
	var up:=InputEventScreenTouch.new();up.index=7;up.pressed=false;game._chase_input(up)
	check(not game.pointer_moving,"Terminal touch release leaves no held movement")
func check_trace_coalescing(game:Control)->void:
	var corner:=[Vector2(870,1347),Vector2(870,1347.5),Vector2(870.6,1347.5)]
	check(not game.geometry.segment_open(corner[0],corner[2]),"Corner fixture has an illegal coarse chord")
	for point:Vector2 in corner:
		game.player=point;game.elapsed+=10;game._record_chase_sample()
		if point==corner[0]:game._chase_proof_payload() # Synthetic sampler fixture: retain the corner's starting anchor.
	check(game.trail.size()==3,"Sampler preserves the actual turn around a solid corner")
	var issued:Dictionary=game._chase_proof_payload()
	game.player+=Vector2(1,0);game.elapsed+=10;game._record_chase_sample()
	game.player+=Vector2(1,0);game.elapsed+=10;game._record_chase_sample()
	check(game.trail.slice(0,issued.path.size())==issued.path,"Later coalescing never changes any issued proof prefix")
	game._reset_chase()
func drive_high_refresh(game:Control,targets:Array)->void:
	var total_frames:=0
	for target:Vector2 in targets:
		game.pointer_moving=true;game.pointer_target=target
		while game.player.distance_to(target)>=8 and not game.done and game.stage=="chase" and total_frames<40000:
			game.elapsed+=1000.0/480;game._chase(1.0/480);total_frames+=1
		if game.done or game.stage!="chase" or total_frames>=40000:break
	game.pointer_moving=false
	check(total_frames>20000 and total_frames<40000,"High-refresh regression actually executes more than 20,000 movement frames")
	check(game.trail.size()<1000,"High-refresh proof size depends on travel time and corners rather than rendered frames")
	print("HIGH_REFRESH_CHASE ",total_frames," frames; ",game.trail.size()," proof points")
func run()->void:
	if not _guard_isolated_profile():return
	var state:=root.get_node("State");var geometry:=Geometry.new()
	var issued:=issue(state)
	check(issued.game.script=="res://scripts/games/chapter4_chase_space_activity.gd","Original c4_chase enters the independent scene")
	check(issued.game.geometryVersion==geometry.layout.format,"Controller binds the issued geometry revision")
	var game:=make_game(state,issued.game)
	check_trace_coalescing(game)
	var view:Control=game.chase_view
	check(view.camera_focus(Vector2(1100,1260))==view.camera_focus(Vector2(1100,1380)),"Vertical obstacle dodges do not redirect the lower-corridor camera")
	check(view.camera_focus(Vector2(1800,740))==view.camera_focus(Vector2(1800,860)),"Middle-corridor camera stays on the route while the player dodges")
	check(view.camera_focus(Vector2(1100,1260))==Vector2(1200,1320),"Lookahead remains a small 100-unit presentation offset")
	check(view.camera_focus(Vector2(2780,1320))==Vector2(2820,1260),"Camera previews the actual stair turn before the player reaches it")
	check(view.camera_focus(Vector2(2780,1320)).distance_to(view.camera_focus(Vector2(2781,1320)))<=1.01,"Turn anticipation changes continuously, not with a direction-key snap")
	check(view.camera_focus(Vector2(180,520))==Vector2(180,420),"The connecting stair points toward the next real platform")
	check(view.camera_focus(Vector2(2810,280))==Vector2(2820,280),"Final lookahead is bounded at the authored exit")
	check(view.camera_focus(Vector2(1100,1260),0)==Vector2(1100,1320),"Reduced motion removes anticipatory camera offset")
	for dimensions in [Vector2(1440,900),Vector2(1280,720),Vector2(1180,812),Vector2(430,860),Vector2(390,844),Vector2(844,390)]:
		game.configure_activity_layout(dimensions,true);await frames()
		check(Rect2(Vector2.ZERO,dimensions).encloses(Rect2(game.chase_view.position,game.chase_view.size)),"The full adaptive chase field is contained")
		check(game.chase_view.field.size.is_equal_approx(game.chase_view.size),"The chase fills its usable field in both phone orientations without letterbox islands")
		check(is_equal_approx(game.chase_view.world_root.scale.x,game.chase_view.world_root.scale.y),"Adaptive camera extents preserve equal world and sprite scale")
		check(game.chase_view.logical.y>=360,"Landscape retains the corridor and actor height")
		check(game.chase_view.field.grow(-20).has_point(game.chase_view.world_root.position+game.player*game.chase_view.factor),"Resize immediately keeps the player inside the visible field")
		check(game.chase_view.size.y>=dimensions.y*.66,"Instructions and Return leave at least two thirds of the activity for the chase")
		check(game.controls.get_child_count()==1 and game.controls.get_child(0).text=="返回","No bottom virtual buttons or joystick are added")
		check(game.controls.get_child(0).size.y>=44 and game.chase_pad.size==Vector2.ZERO,"Existing Return remains reachable without hidden joystick controls")
	var point:Vector2=game.global_position+game.chase_view.position+game.chase_view.field.get_center()
	var touch:=InputEventScreenTouch.new();touch.index=7;touch.position=point;touch.pressed=true
	check(game._chase_input(touch) and game.chase_finger==7 and game.pointer_moving,"Real field touch owns pointer direction")
	var other:=InputEventScreenTouch.new();other.index=8;other.position=point;other.pressed=true;game._chase_input(other)
	check(game.chase_finger==7,"Second touch cannot steal movement ownership")
	touch.pressed=false;game._chase_input(touch);check(not game.pointer_moving,"Touch release stops movement")
	touch.pressed=true;game._chase_input(touch);game.configure_activity_layout(Vector2(430,860),true)
	check(not game.pointer_moving,"Resize clears held input")
	var versionless:Dictionary=game._chase_proof_payload();versionless.erase("geometryVersion");versionless.landing=1
	check(not state.act("c4_chase_landing",versionless).get("accepted",false),"Legacy or missing geometry proof cannot bypass the new route")
	drive(game,geometry.route.slice(1,9))
	check(game.stage=="chase" and game.landing==1 and state.d.chapter4.chaseStairwellLanding==1,"Actual simulated input reaches and commits platform one")
	var first_elapsed:float=game.elapsed
	check(first_elapsed>14000,"First section length comes from actual travel")
	var old_config:Dictionary=game.config.duplicate(true)
	var old_proof:Dictionary=game._chase_proof_payload();old_proof.landing=2
	game._leave_chase();check(not game.pointer_moving and game.done,"Return clears inputs and retires the old scene")
	state.developer_mode=false
	check(state.save_game(),"Ordinary save writes the real accepted platform")
	state.d=state.initial();check(state.load_game() and state.d.chapter4.chaseStairwellLanding==1,"Ordinary reload restores logical platform one")
	state.developer_mode=true
	var resumed:Dictionary=state.act("c4_chase_resume")
	check(resumed.game.startLanding==1 and resumed.game.session!=old_config.session,"Reentry issues a fresh session for the saved platform")
	check(not state.act("c4_chase_landing",old_proof).get("accepted",false),"Retired scene cannot submit to the new session")
	game.queue_free();await frames();game=make_game(state,resumed.game)
	check(game.player==Vector2(2820,800),"New space maps the saved platform to its corresponding safe spawn")
	drive(game,geometry.route.slice(9))
	check(game.done and state.d.chapter4.floor=="A2" and state.d.chapter4.chaseStairwellStage=="complete","Actual remaining route reaches original A2 handoff")
	check(state.d.chapter4.phase=="final_chase" and not state.d.chapter4.factIds.has("room202_route_reached"),"Escape grants neither room202 arrival nor a final-minute reward")
	game.queue_free();await frames()
	for dimensions in [Vector2(390,844),Vector2(844,390)]:
		issued=issue(state);game=make_game(state,issued.game);game.configure_activity_layout(dimensions,true);await frames()
		drive_touch(game,geometry.route.slice(1))
		check(game.done and state.d.chapter4.floor=="A2" and state.d.chapter4.chaseStairwellStage=="complete","Full native screen-touch route completes at %s (stage=%s position=%s target=%s owner=%s elapsed=%s)"%[dimensions,game.stage,game.player,game.pointer_target,game.chase_pointer_owner,game.elapsed])
		game.queue_free();await frames()
	issued=issue(state);game=make_game(state,issued.game)
	drive_high_refresh(game,geometry.route.slice(1))
	check(game.done and state.d.chapter4.floor=="A2" and state.d.chapter4.chaseStairwellStage=="complete","More than 20,000 legitimate movement frames still complete the original A2 handoff")
	game.queue_free();await frames()
	issued=issue(state);game=make_game(state,issued.game)
	var attempt:int=state.d.chapter4.chaseAttempt
	for i in 300:
		if game.stage=="capture":break
		game.elapsed+=50;game._chase(.05)
	check(game.stage=="capture" and not game.running and game.body.text.contains("你在这里干什么"),"Stationary player is caught by actual guard motion and receives original dialogue")
	var failure:Dictionary=game._chase_proof_payload();failure.captured=true;failure.guard={"x":game.guard.x,"y":game.guard.y};failure.captureMs=5199
	check(not state.act("c4_chase_failed",failure).get("accepted",false),"Original caught-dialogue duration cannot be shortened")
	failure.captureMs=5200
	check(state.act("c4_chase_failed",failure).get("accepted",false) and state.d.chapter4.chaseAttempt==attempt+1 and state.d.chapter4.floor=="A1" and state.d.chapter4.chaseStairwellLanding==0,"Original failure increments once and resets to A1, not a free platform respawn")
	check(not state.act("c4_chase_failed",failure).get("accepted",false) and state.d.chapter4.chaseAttempt==attempt+1,"Duplicate failure is rejected")
	game.queue_free();await frames()
	state.begin_checkpoint("c4-755-chase")
	var shell:Control=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames(5)
	state.act("c4_chase");await frames()
	check(is_instance_valid(shell.active_game) and shell.active_game.get_script().resource_path.ends_with("chapter4_chase_space_activity.gd"),"Actual Main routes the original trigger into the new activity")
	shell.active_game.set_process(false);shell.active_game._leave_chase();await frames()
	check(not is_instance_valid(shell.active_game),"Actual Main releases the independent scene on Return")
	shell._show_world_mobile();await frames()
	check(is_instance_valid(shell.active_game) and shell.active_game.player==Vector2(180,1320),"Explicit world Return resumes the independent space safely")
	shell.queue_free();await frames(4)
	print("CHAPTER4_CHASE_SPACE_INTEGRATION ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
