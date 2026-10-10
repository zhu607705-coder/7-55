extends SceneTree
const Metrics=preload("res://scripts/player_metrics.gd")
var checks:=0
var errors:=0
func check(value: bool,label: String) -> void:
	checks+=1
	if not value: errors+=1; push_error("WORLD GUARD: "+label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var state: Node=root.get_node("State")
	state.developer_mode=true
	state.begin_checkpoint("c4-755-chase")
	var world=load("res://scripts/world.gd").new()
	world.size=Vector2(960,540)
	root.add_child(world)
	world.set_process(false)
	world.refresh_world()
	for i in 39: world._update_guard(.05)
	check(not world.guard_visible,"source two-second arming keeps guard hidden")
	world._update_guard(.05)
	check(world.guard_visible,"guard arms only after stable source floor and grace")
	# A real source-pixel obstruction. The renderer runtime, not just the pure
	# navigation helper, must direct the body around it without penetration.
	world.guard_position=Vector2(100,100)
	world.player=Vector2(310,100)-Metrics.FOOT_CENTER_OFFSET
	world.collisions=[{"x":185,"y":40,"width":30,"height":160}]
	world.guard_navigation_key=""
	world.guard_state.phase="running"
	var min_y:=100.0
	for i in 60:
		world._update_guard(.02)
		min_y=minf(min_y,world.guard_position.y)
		check(world._guard_can_stand(world.guard_position,[Rect2(185,40,30,160)]),"actual guard body stays outside obstacle "+str(i))
	check(min_y<34,"actual world guard follows source A-star detour")
	check(world.guard_position.x>185,"detour makes forward progress around obstruction")
	# Source recreates after the separate, validated stairwell game with600px
	# of guard lag on A1; it does not spawn a visible A2 guard immediately.
	state.begin_checkpoint("c4-755-chase")
	state.d.chapter4.floor="A2"
	state.d.chapter4.chaseStairwellStage="complete"
	world.refresh_world()
	world.player=Vector2(1250,450)-Metrics.FOOT_CENTER_OFFSET
	world._update_guard(.05)
	check(world.guard_state.phase=="portal_transfer" and world.guard_state.guardFloor=="A1","A2 handoff retains guard on previous floor")
	check(not world.guard_visible and is_equal_approx(float(world.guard_state.portalRemainingDistance),591.3),"source600px transfer lag begins at174px/s")
	for i in 69: world._update_guard(.05)
	check(world.guard_state.guardFloor=="A2" and world.guard_visible,"guard reaches A2 after actual route lag")
	# Merely standing in the finish volume cannot close the door. Explicit
	# interaction wins over same-frame contact, as source finish priority requires.
	world.player=Vector2(1353,356.5)-Metrics.FOOT_CENTER_OFFSET
	world.guard_position=Vector2(1000,400)
	world.guard_state.phase="running"
	world._update_guard(.01)
	check(state.d.chapter4.phase=="final_chase","standing in202 never auto-completes chase")
	world.guard_position=Metrics.foot_rect(world.player).get_center()
	world.guard_close_requested=true
	world._update_guard(.01)
	check(state.d.chapter4.phase=="final_minute_recovery","explicit door close has source finish-before-contact priority")
	# Source A1 landing triggers only the actual stairwell request, not A2 facts.
	state.begin_checkpoint("c4-755-chase")
	world.refresh_world()
	world.guard_kind=""
	world.player=Vector2(1001,214)-Metrics.FOOT_CENTER_OFFSET
	world._sync_player()
	for i in 40: world._update_guard(.05)
	world._update_guard(.01)
	check(state.last_result.has("game") and state.last_result.game.get("kind")=="chase_stairwell","entering actual landing requests native stairwell game")
	check(state.d.chapter4.floor=="A1" and state.d.chapter4.chaseStairwellStage=="inside","landing cannot directly grant A2 transport")
	world.queue_free()
	await process_frame
	print("World guard integration: ",checks," checks, ",errors," errors")
	quit(1 if errors else 0)
