extends SceneTree
## Runs the real production World script and source geometry/controller in an
## explicitly seeded fixture. Synthetic events/ticks are not manual OS focus QA.
const Metrics = preload("res://scripts/player_metrics.gd")
var state: Node
var world: Control
var checks: Array=[]
var samples: Array=[]
var actions: Array=[]
var failures:=0
var world_script_path: String

func _initialize() -> void: run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks.append({"label":label,"passed":ok})
	if not ok:
		failures+=1
		print("ASSERTION FAILED: ",label)
func frame() -> void: await process_frame
func fixture(controls: bool) -> void:
	if is_instance_valid(world):
		world.free()
		await frame()
	check(state.begin_checkpoint("c2-manual-movement"),"source checkpoint loads")
	state.developer_mode=true
	if controls: state.act("c2_use_gamepad")
	world=load(world_script_path).new()
	world.size=Vector2(960,540)
	root.add_child(world)
	world.set_process(false)
	world.native_dorm.set_process(false)
	world.mobile_exploration=false
	world.player=Vector2(480,670)
	world._sync_player()
	world._update_camera()
	world.cancel_exploration_gestures()
	world.walk_clock=0
	world._manual_sent=false
	actions.clear()
	await frame()
	check(world.scene_id=="dorm_hub" and world.is_visible_in_tree(),"actual dorm world is visible")
	check(world.can_stand(world.player),"fixture feet are legal in unchanged source geometry")

func click_ground(goal: Vector2) -> void:
	var event:=InputEventMouseButton.new()
	event.button_index=MOUSE_BUTTON_LEFT
	event.pressed=true
	event.position=(goal-world.camera)*world.zoom+world.size/2
	# Deliberately call the production GUI handler. OS/root dispatch is not claimed.
	world._gui_input(event)

func test_focus() -> void:
	await fixture(true)
	check(root.size==Vector2i(1440,900) and not world.mobile_exploration,"desktop root and non-compact input path")
	var goal:=Vector2(560,670)
	check(world.can_stand(goal),"real source destination is walkable")
	click_ground(goal)
	check(world._floor_goal.distance_to(goal)<.001 and not world._floor_route.is_empty(),"desktop production click handler sets exact floor marker and collision route")
	var start:Vector2=world.player
	world._process(.05)
	check(world.player.x>start.x,"click target moves before focus loss")
	var stopped:Vector2=world.player
	world.notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
	check(world.move_target==Vector2.INF and world._floor_route.is_empty() and world._floor_goal==Vector2.INF,"desktop focus notification retires click target and floor route")
	for i in 20: world._process(.05)
	check(world.player==stopped,"20 background ticks do not consume the retired desktop target")
	world.notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_IN)
	world._process(.05)
	check(world.player==stopped and world.move_target==Vector2.INF and world._floor_route.is_empty() and world._floor_goal==Vector2.INF,"focus regain cannot replay the old click target or floor route")
	var fresh_goal:=Vector2(520,610)
	check(world.can_stand(fresh_goal) and world._pick_target(fresh_goal).is_empty(),"fresh click fixture is ground rather than the actor inspection target")
	click_ground(fresh_goal)
	check(world._floor_goal.distance_to(fresh_goal)<.001 and not world._floor_route.is_empty(),"fresh ground click sets a new exact floor marker and collision route after regain")
	world._process(.05)
	check(world.player!=stopped,"a fresh click can move after focus regain")
	for compact in [false,true]:
		world.mobile_exploration=compact
		world.move_target=goal
		world.touch_axis=Vector2.RIGHT
		var contact:=InputEventScreenTouch.new();contact.index=3;contact.position=world.exploration_safe_rect(true).get_center();contact.pressed=true
		world._gui_input(contact)
		check(world.direct_gestures.has_active(),"real contact claims direct world gesture compact="+str(compact))
		world._floor_route.append(goal)
		world._floor_goal=goal
		world.kayak_mouse_gesture={"side":"left"}
		world.notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
		check(world.move_target==Vector2.INF and world.touch_axis==Vector2.ZERO and not world.direct_gestures.has_active(),"focus clears all transient controls compact="+str(compact))
		check(world._floor_route.is_empty() and world._floor_goal==Vector2.INF and world.kayak_mouse_gesture.is_empty(),"focus clears floor and paddle ownership compact="+str(compact))
		world.notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
		check(world.move_target==Vector2.INF,"repeated focus loss is idempotent compact="+str(compact))

func test_auto_pacing() -> void:
	await fixture(false)
	check(state.d.actOne.exerciseStarted and not state.d.actOne.controlsInstalled and not state.d.actOne.manualControlTested,"exercise fixture has no manual authorization")
	var legal:=true
	for x in [440.0,465.0,505.0,540.0,570.0]: legal=legal and world.can_stand(Vector2(x,670))
	check(legal,"entire original automatic pace range clears real source collision")
	var moved:=0
	var clocked:=0
	var facing_ok:=true
	var frames_seen: Dictionary={}
	var flips_seen: Dictionary={}
	var initial_items:Dictionary=state.d.items.duplicate(true)
	# Original auto pacing uses Time.get_ticks_msec(), so let actual wall time
	# advance as well as injecting a known delta. 3.4s spans a turn for any phase.
	for i in 68:
		await create_timer(.05).timeout
		var before:Vector2=world.player
		var previous_clock:float=world.walk_clock
		world._process(.05)
		var displacement:Vector2=world.player-before
		if displacement.length_squared()>0:
			moved+=1
			if is_equal_approx(world.walk_clock,previous_clock+.05): clocked+=1
			facing_ok=facing_ok and world.facing=="side" and world.player_flip==(displacement.x<0)
			flips_seen[str(displacement.x<0)]=true
		if world.walk_clock>0:frames_seen[Metrics.frame_at(world.walk_clock*1000)]=true
		samples.append({"step":i,"position":[world.player.x,world.player.y],"dx":displacement.x,"clock":world.walk_clock,"frame":Metrics.frame_at(world.walk_clock*1000),"side_idle":world.facing=="side" and world.walk_clock<=0,"flip":world.player_flip})
	check(moved>=60,"actual wall-clock automatic pace changes position across sampled ticks")
	check(clocked==moved,"each moving auto tick increments gait clock exactly once")
	check(frames_seen.size()>=4,"real frame selector visits multiple gait frames during auto pacing")
	check(flips_seen.size()==2,"sample crosses an actual automatic turn")
	check(facing_ok,"automatic facing follows real displacement on both directions")
	check(not state.d.actOne.manualControlTested and not actions.has("c2_manual_input") and not world._manual_sent,"automatic pacing never grants manual progression")
	check(state.d.items==initial_items,"automatic presentation leaves inventory unchanged")
	state.d.actOne.exerciseStarted=false
	var idle:Vector2=world.player
	world._process(.05)
	check(world.player==idle and world.walk_clock==0,"exercise stops into an idle frame")

func test_manual_and_collision() -> void:
	await fixture(true)
	var start:Vector2=world.player
	world.touch_axis=Vector2.RIGHT
	world._process(.05)
	check(is_equal_approx(world.player.x-start.x,8.0) and is_equal_approx(world.player.y,start.y),"authorized manual speed remains 160 source units per second")
	check(is_equal_approx(world.walk_clock,.05) and world.facing=="side" and not world.player_flip,"manual right walk advances clock once")
	check(state.d.actOne.manualControlTested and actions.count("c2_manual_input")==1,"real controller still accepts first manual displacement once")
	world.touch_axis=Vector2.LEFT
	world._process(.05)
	check(is_equal_approx(world.walk_clock,.1) and world.player_flip,"manual left walk turns without duplicate clock ticks")
	check(actions.count("c2_manual_input")==1,"later manual displacement does not resend proof")
	world.touch_axis=Vector2.ZERO;world._process(.05)
	check(world.walk_clock==0,"manual idle resets gait clock")
	# Exact north-wall contact at feet y=201.5 (no changed source collision).
	world.player=Vector2(480,177.125)
	check(world.can_stand(world.player) and not world.can_stand(world.player+Vector2(0,-8)),"real wall contact fixture has legal start and blocked next step")
	world.walk_clock=.3;world.touch_axis=Vector2.UP
	start=world.player;world._process(.05)
	check(world.player==start and world.walk_clock==0,"blocked manual step returns to idle instead of retaining a gait frame")
	world.touch_axis=Vector2.ZERO

func isolated_save_fixture() -> bool:
	# A direct --script launch must never overwrite a player's native saves.
	# XDG alone is insufficient: verify the directory Godot actually resolved.
	var declared:=OS.get_environment("GODOT_TEST_USER_DATA_DIR").replace("\\", "/")
	if declared.is_empty() or not declared.is_absolute_path():return false
	declared=declared.simplify_path().trim_suffix("/")
	var sandbox:=declared.get_base_dir().get_base_dir()
	if not sandbox.get_file().begins_with("755-native-check-"):return false
	if declared!=sandbox.path_join("data/SevenFiftyFiveNative"):return false
	if OS.get_user_data_dir().replace("\\", "/").simplify_path().trim_suffix("/")!=declared:return false
	if ProjectSettings.globalize_path("user://").replace("\\", "/").simplify_path().trim_suffix("/")!=declared:return false
	for file in ["save.json","save.previous.json","save.json.tmp"]:
		if FileAccess.file_exists(declared.path_join(file)) or DirAccess.dir_exists_absolute(declared.path_join(file)):return false
	return true

func run() -> void:
	world_script_path=OS.get_environment("WORLD_SCRIPT_PATH")
	if world_script_path.is_empty():world_script_path="res://scripts/world.gd"
	if not isolated_save_fixture():
		print("CHARACTER_TEST_ISOLATION_REQUIRED: refusing an undeclared or populated save fixture");quit(2);return
	state=root.get_node("State");state.developer_mode=true
	state.action_completed.connect(func(id,_a,_b,_c):actions.append(id))
	root.size=Vector2i(1440,900)
	await test_focus()
	await test_auto_pacing()
	await test_manual_and_collision()
	world.free();await frame()
	var result:Dictionary={"checks":checks.size(),"failures":failures,"production_world_script":world_script_path,"engine_version":Engine.get_version_info(),"headless":DisplayServer.get_name()=="headless","synthetic_focus_notification":true,"manual_os_focus_tested":false,"pixel_render_tested":false,"assertions":checks,"auto_samples":samples}
	var report_path:=OS.get_environment("CHARACTER_REPORT")
	if not report_path.is_empty():
		var file:=FileAccess.open(report_path,FileAccess.WRITE);file.store_string(JSON.stringify(result,"\t"));file.close()
	print("WORLD INPUT ANIMATION: ",checks.size()," checks / ",failures," failures")
	quit(1 if failures else 0)
