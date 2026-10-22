extends SceneTree
const Timeline=preload("res://scripts/presentation/kayak_stroke_timeline.gd")
const Geo=preload("res://scripts/games/lake_geometry.gd")
var passed: Array[String]=[]
var failed: Array[String]=[]
var metrics: Dictionary={}
var output: String=ProjectSettings.globalize_path("res://test-output/")
var scene: Node2D
func check(ok: bool,label: String) -> void:
	if ok:passed.append(label);print("PASS: ",label)
	else:failed.append(label);push_error(label)
func key(code: int,pressed: bool=true) -> void:
	var ev:=InputEventKey.new();ev.keycode=code;ev.pressed=pressed;scene._unhandled_key_input(ev)
func touch(id: int,at: Vector2,pressed: bool=true,cancel: bool=false) -> void:
	var ev:=InputEventScreenTouch.new();ev.index=id;ev.position=at;ev.pressed=pressed;ev.canceled=cancel;scene._input(ev)
func drag(id: int,at: Vector2) -> void:
	var ev:=InputEventScreenDrag.new();ev.index=id;ev.position=at;scene._input(ev)
func frames(n: int) -> void:
	for i in range(n):scene._process(1.0/60)
func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence-dir="):output=arg.trim_prefix("--evidence-dir=").trim_suffix("/")+"/"
	DirAccess.make_dir_recursive_absolute(output)
	call_deferred("run")
func run() -> void:
	root.size=Vector2i(1280,720)
	var motion=Timeline.new();motion.request_stroke("left");motion.advance(.2);motion.request_stroke("right")
	check(not motion.pending.is_empty(),"Regression fixture contains a pending stroke")
	motion.set_paused(false)
	check(not motion.pending.is_empty(),"Repeated unpause preserves pending stroke")
	motion.set_paused(true);check(motion.pending.is_empty(),"Actual pause removes stale queued intent")
	var age: float=motion.age;motion.advance(1)
	check(motion.age==age,"Pause freezes active stroke age")
	motion.set_paused(false);motion.advance(.05)
	check(motion.age>age,"Resume continues the active stroke without restart")
	scene=load("res://scenes/qizhen_large_world.tscn").instantiate();root.add_child(scene);scene.set_process(false);key(KEY_ENTER)
	key(KEY_W);frames(120)
	check(scene.game.strokes>=4,"Keyboard hold emits repeated physical strokes")
	check(scene.rig.motion.started_strokes>=scene.game.strokes-1,"Continuous presentation no longer loses alternate stroke requests")
	check(scene.rig.contact_history_ready,"Rig retains valid world-space contact history while running")
	var vel: Vector2=scene.rig.blade_world_velocity[0];var emission: float=scene.rig.emission_clock
	scene.rig.set_paused(false)
	check(scene.rig.contact_history_ready and scene.rig.blade_world_velocity[0]==vel and scene.rig.emission_clock==emission,"Idempotent unpause preserves derivatives and emission clock")
	key(KEY_W,false);frames(1)
	check(not scene.game.throttle and scene.rig.motion.pending.is_empty(),"Keyboard release clears thrust and queued presentation")
	frames(60);check(not scene.rig.motion.active,"Release returns paddle to rest within one second")
	scene._restart();touch(1,Vector2(1040,450));frames(60)
	check(scene.game.strokes>=2 and scene.game.throttle,"Right touch hold uses the normal repeated thrust input")
	touch(1,Vector2(1040,450),false,true);frames(1)
	check(scene.touch_right==-1 and not scene.game.throttle,"Canceled right touch cannot stick thrust")
	touch(2,Vector2(220,450));drag(2,Vector2(280,450));frames(25)
	var first_heading: float=scene.game.heading
	drag(2,Vector2(160,450));frames(25)
	check(absf(angle_difference(first_heading,scene.game.heading))>.1,"Continuous left drag changes steering without new touches")
	touch(2,Vector2(160,450),false);frames(1)
	check(scene.game.steering==0,"Releasing direction returns steering to neutral")
	touch(3,Vector2(1040,450));touch(4,Vector2(220,450));key(KEY_P)
	var before: Dictionary=scene.game.result();var phase_age: float=scene.rig.motion.age
	frames(90)
	check(scene.game.result()==before and scene.rig.motion.age==phase_age,"Pause freezes model and presentation together")
	check(scene.touch_left==-1 and scene.touch_right==-1 and scene.keys.is_empty(),"Pause clears all input sources")
	key(KEY_P);frames(5)
	check(not scene.game.throttle and scene.game.steering==0,"Resume needs fresh input and does not revive old fingers")
	touch(5,Vector2(1040,450));frames(10);scene._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT);frames(10)
	check(scene.game.paused and scene.touch_right==-1 and scene.rig.motion.paused,"Focus loss pauses rig and releases fingers")
	key(KEY_P);frames(1);check(not scene.game.throttle,"Focus resume does not rearm thrust")
	key(KEY_W);frames(20);key(KEY_M);before=scene.game.result();phase_age=scene.rig.motion.age;frames(90)
	check(scene.overview and scene.game.result()==before and scene.rig.motion.age==phase_age,"Map freezes physics, route time, and paddle pose")
	key(KEY_M);frames(15)
	metrics["map_return_seconds"]=.25
	metrics["map_return_target_error"]=scene.cam.position.distance_to(scene._follow_target())
	check(not scene.overview and scene.map_return_time==0 and scene.cam.position.distance_to(scene.game.position)<200,"Map returns to boat in 0.25s without long camera chase")
	check(not scene.game.throttle and scene.cam.rotation==0,"Map return clears thrust and preserves north-up orientation")
	for i in range(8):key(KEY_M);frames(2)
	check(not scene.overview and scene.touch_right==-1,"Rapid repeated map toggles leave a playable neutral state")
	# Direct model assignment below is only an objective fixture, never route proof.
	scene._restart();scene.game.progress=1;scene.last_progress=1;scene.game.position=Geo.goals()[1].point;scene.game.speed=20;scene._sync(0,true)
	var target: Vector2=scene.world_to_screen(Geo.goals()[1].point)
	touch(6,Vector2(1040,450));touch(7,target)
	check(scene.touch_use and scene.touch_left==-1 and scene.touch_right==-1,"Direct target touch wins over thumb zones and cancels propulsion")
	touch(7,target,false);frames(100)
	check(scene.game.inspected and scene.game.progress==2,"A target tap completes the original low-speed 1.25s interaction")
	scene._restart();scene.game.progress=1;scene.last_progress=1;scene.game.position=Geo.goals()[1].point;scene._sync(0,true)
	touch(8,scene.world_to_screen(Geo.goals()[1].point));frames(20);touch(9,Vector2(1040,450));frames(1)
	check(not scene.touch_use and not scene.game.interact,"New paddle input cancels tap-to-interact")
	touch(9,Vector2(1040,450),false);touch(10,Vector2(220,450));scene._on_viewport_changed()
	check(scene.touch_left==-1 and scene.touch_right==-1 and not scene.touch_use,"Viewport rotation cancels stale pointer coordinates")
	for size in [Vector2i(1280,720),Vector2i(720,1280),Vector2i(1920,1080),Vector2i(960,640),Vector2i(390,844),Vector2i(844,390)]:
		root.size=size;scene._update_layout();scene._sync(0,true)
		check(scene.hud_size.x>=390 and scene.map_button.end.x<=scene.hud_size.x and scene.pause_button.end.x<=scene.hud_size.x,"HUD controls fit aspect "+str(size))
		check(scene.play_rect.has_point(scene.world_to_screen(scene.game.position)/scene.hud_scale),"Boat remains inside clear play area "+str(size))
		check(scene.pause_button.size.y*scene.hud_scale>=44,"Touch hit targets retain physical size "+str(size))
		var old_scale: Vector2=scene.hud.scale;scene.cam.zoom*=.5
		check(scene.hud.scale==old_scale,"HUD text scale is independent of world zoom "+str(size))
	root.size=Vector2i(844,390);scene._update_layout();scene._restart();scene.game.progress=2;scene.game.speed=285;scene.game.swan_phase="warning"
	for i in range(8):
		scene.game.heading=i*PI/4;scene._sync(0,true)
		var boat_at: Vector2=scene.world_to_screen(scene.game.position)/scene.hud_scale
		check(boat_at.y>=146 and boat_at.y<=scene.hud_size.y-124,"Fast landscape boat clears top and bottom HUD heading "+str(i))
		check(not scene._warning_rect().grow(30).has_point(boat_at),"Warning avoids full boat bounds at fast heading "+str(i))
	scene.game.progress=1;scene.game.position=Geo.goals()[1].point+Vector2(-15,-45);scene._sync(0,true)
	var target_at: Vector2=scene.world_to_screen(Geo.goals()[1].point)/scene.hud_scale
	var label_at: Vector2=scene._target_label_position(target_at)
	check(not Rect2(label_at-Vector2(0,18),Vector2(72,24)).grow(30).has_point(scene.world_to_screen(scene.game.position)/scene.hud_scale),"Target label avoids the boat during close approach")
	scene.touch_mode=true;scene.game.feedback="按 M 查看全湖路线。按 S 收桨"
	check(not scene._feedback_text().contains("按 M") and not scene._feedback_text().contains("按 S"),"Touch feedback uses touch instructions instead of keyboard shortcuts")
	var report={"passes":passed,"failures":failed,"metrics":metrics,"scope":"Godot scene/input tests; touch events are synthetic, not physical-device testing. Direct state assignment is limited to labeled objective fixtures."}
	var file:=FileAccess.open(output+"input-camera-tests.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"  "))
	print("INPUT_CAMERA_RESULT ",JSON.stringify(report));scene.free();quit(0 if failed.is_empty() else 1)
