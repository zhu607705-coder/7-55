extends SceneTree
## Independent regression audit. Only unit-test fixtures assign model state.
## The full-route audit below never assigns gameplay state after construction.
const Model=preload("res://scripts/games/large_world_model.gd")
const Geo=preload("res://scripts/games/lake_geometry.gd")
const Driver=preload("res://tests/route_driver.gd")
var failures: Array[String]=[]
var passed: Array[String]=[]
var notes: Array[String]=[]
var route: Dictionary={}
func check(value: bool,label: String) -> void:
	if value:passed.append(label);print("PASS: ",label)
	else:failures.append(label);push_error(label)
func _initialize() -> void:call_deferred("run")
func snapshot(g: RefCounted) -> Dictionary:
	return {"result":g.result().duplicate(true),"heading":g.heading,"speed":g.speed,"swan":g.swan,"phase":g.swan_phase,"timer":g.swan_timer,"events":g.events.duplicate(true),"hold":g.action_hold,"remainder":g.remainder,"clock":g.paddle_clock,"next_side":g.next_side}
func run() -> void:
	audit_route()
	audit_pause_and_restart()
	audit_objectives()
	audit_collision()
	audit_scene_inputs()
	var report: Dictionary={"route":route,"passes":passed,"failures":failures,"notes":notes,"scope":"Independent model/driver audit; fixtures are separate from the input-only route"}
	var file:=FileAccess.open("user://audit-results.json",FileAccess.WRITE)
	if file==null:
		push_error("Cannot write user://audit-results.json");quit(1);return
	file.store_string(JSON.stringify(report,"  "))
	print("AUDIT_RESULT ",JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
func audit_route() -> void:
	var g: RefCounted=Model.new()
	var driver:=Driver.new()
	var moved_time: float=0
	var travel_time: float=0
	var throttle_time: float=0
	var interact_time: float=0
	var braking_time: float=0
	var swan_phase_time: Dictionary={}
	var max_step: float=0
	var mutated: bool=false
	var teleported: bool=false
	var left_water: bool=false
	var order_bad: bool=false
	var dt: float=1.0/60
	for n in range(60*240):
		var before:=snapshot(g)
		driver.control(g)
		if snapshot(g)!=before:mutated=true
		var old: Vector2=g.position
		var old_heading: float=g.heading
		var old_progress: int=g.progress
		var old_time: float=g.elapsed
		g.step(dt)
		var step_time: float=g.elapsed-old_time
		var moved: float=old.distance_to(g.position)
		max_step=maxf(max_step,moved)
		if moved>.0001:moved_time+=step_time
		if moved>30*step_time:travel_time+=step_time
		if driver.throttle:throttle_time+=step_time
		if driver.use:interact_time+=step_time
		if driver.brake:braking_time+=step_time
		swan_phase_time[g.swan_phase]=float(swan_phase_time.get(g.swan_phase,0))+step_time
		if moved>Model.MAX_SPEED*step_time+.01 or absf(angle_difference(old_heading,g.heading))>1.5*step_time+.0001:teleported=true
		if not Geo.water(g.position,31):left_water=true
		if g.progress<old_progress or g.progress>old_progress+1:order_bad=true
		if g.status!="running":break
	check(not mutated,"Driver modifies only permitted input fields")
	check(not teleported,"All route displacements and turns respect physical speed bounds")
	check(not left_water,"Every route sample remains on collision-clear water")
	check(not order_bad,"Route objective progression is strictly sequential")
	check(g.status=="won","Independent full input-only route wins")
	check(g.elapsed>=90 and travel_time>=90,"At least 90 seconds are actual travel above 30 px/s")
	check(g.travel>=19000 and g.strokes>150,"Completion requires a long physical journey with repeated strokes")
	var goal_events: Array=[]
	var sides_ok: bool=true
	var last_side: String="right"
	for event in g.events:
		if event.kind=="goal":goal_events.append(event.index)
		if event.kind=="stroke":
			if event.side==last_side:sides_ok=false
			last_side=event.side
	check(goal_events==[0,1,2,3,4,5,6,7,8],"All nine objective events are earned exactly once in order")
	check(sides_ok,"Paddle strokes alternate left and right throughout route")
	var finished:=snapshot(g)
	g.input(true,1,false,true);g.step(.5)
	check(snapshot(g)==finished,"Win state freezes physics and further objective events")
	route=g.result().duplicate(true)
	route.merge({"moving_time":moved_time,"travel_above_30_time":travel_time,"throttle_time":throttle_time,"interaction_input_time":interact_time,"braking_input_time":braking_time,"max_displacement_per_60hz_frame":max_step,"swan_phase_seconds":swan_phase_time})
func audit_pause_and_restart() -> void:
	var g: RefCounted=Model.new()
	g.input(true,.4,false,false)
	for n in range(120):g.step(1.0/60)
	g.paused=true
	var frozen:=snapshot(g)
	g.input(true,-1,true,true)
	for n in range(300):g.step(1.0/60)
	check(snapshot(g)==frozen,"Pause freezes movement, hazards, hold progress, timers, and event logs")
	g.paused=false;g.input(false,0,true,false);g.step(1.0/60)
	check(g.elapsed>float(frozen.result.elapsed),"Unpause resumes simulation")
	g.feedback="stale success feedback";g.checkpoint_pos=Vector2(100,100);g.last_stroke="right";g.input(true,1,false,true)
	g.reset()
	var fresh: RefCounted=Model.new()
	check(g.result()==fresh.result() and g.heading==fresh.heading,"Restart resets gameplay position, progress, metrics, and outcome")
	check(g.feedback==fresh.feedback,"Restart clears stale feedback")
	check(g.throttle==fresh.throttle and g.steering==fresh.steering and g.brake==fresh.brake and g.interact==fresh.interact,"Model restart clears held input state")
	check(g.checkpoint_pos==fresh.checkpoint_pos and g.last_stroke==fresh.last_stroke,"Restart clears checkpoint and previous-stroke transients")
func fixture(stage: int) -> RefCounted:
	var g: RefCounted=Model.new()
	g.progress=stage;g.position=Geo.goals()[stage].point;g.speed=0;g.input(false,0,false,false)
	return g
func audit_objectives() -> void:
	var g: RefCounted=fixture(1)
	for n in range(120):g.step(1.0/60)
	check(g.progress==1 and g.action_hold==0,"Inspection cannot complete without interaction")
	g.input(false,0,false,true);g.speed=150;g.step(Model.STEP)
	check(g.action_hold==0,"Inspection rejects excessive speed")
	g.speed=0;g.action_hold=0
	for n in range(149):g.step(Model.STEP)
	check(g.progress==1,"Inspection requires the full hold duration")
	for n in range(3):g.step(Model.STEP)
	check(g.progress==2 and g.inspected,"Inspection completes after eligible hold")
	g=fixture(3);g.input(false,0,false,true)
	for n in range(152):g.step(Model.STEP)
	check(g.progress==4 and g.recovered,"Collection requires eligible interaction and marks the bag recovered")
	g=fixture(8);g.heading=-PI/2;g.input(false,0,false,true)
	for n in range(200):g.step(Model.STEP)
	check(g.status=="running" and g.action_hold==0,"Dock refuses completion without the recovered bag")
	g.recovered=true;g.heading=0
	for n in range(200):g.step(Model.STEP)
	check(g.status=="running" and g.action_hold==0,"Dock refuses wrong orientation")
	g.heading=-PI/2;g.speed=100;g.step(Model.STEP)
	check(g.action_hold==0,"Dock refuses excessive speed")
	g.speed=0
	for n in range(152):g.step(Model.STEP)
	check(g.status=="won" and g.elapsed<90,"Dock succeeds by conditions without any minimum-duration time lock")
	g=Model.new();g.position=Geo.goals()[3].point;g.input(false,0,false,true)
	for n in range(200):g.step(Model.STEP)
	check(g.progress==0 and not g.recovered,"Visiting a later objective cannot skip the current objective")
	g=fixture(1);g.input(false,0,false,true)
	for n in range(90):g.step(Model.STEP)
	g.position=Geo.dock();g.step(Model.STEP)
	check(g.action_hold==0,"Leaving objective range resets interaction progress")
func audit_collision() -> void:
	var g: RefCounted=Model.new()
	g.heading=0;g.input(true,0,false,false)
	var valid: bool=true
	for n in range(60*30):
		g.step(1.0/60)
		if not Geo.water(g.position,31):valid=false
	check(valid and g.collisions>0,"Repeated shoreline impacts cannot leave navigable water")
	check(g.travel<1000,"Shoreline collision prevents tunneling across the bank")
	g=fixture(6);g.swan=g.position;g.swan_origin=g.position;g.hit_cooldown=0;g.step(Model.STEP)
	check(g.damage==1,"Swan contact records damage")
	var first: int=g.damage
	g.step(Model.STEP)
	check(g.damage==first,"Collision cooldown prevents repeated same-contact damage")
	g.damage=2;g.hit_cooldown=0;g.swan=g.position;g.swan_origin=g.position;g.step(Model.STEP)
	check(g.status=="lost" and g.damage==3,"Three swan impacts produce the loss state")
	var lost:=snapshot(g)
	g.input(true,1,false,true);g.step(.5)
	check(snapshot(g)==lost,"Loss state freezes simulation")
func key(scene: Node,code: int,pressed: bool=true) -> void:
	var event:=InputEventKey.new();event.keycode=code;event.pressed=pressed
	scene._unhandled_key_input(event)
func audit_scene_inputs() -> void:
	var scene: Node=load("res://scenes/qizhen_large_world.tscn").instantiate()
	root.add_child(scene);scene.set_process(false)
	for n in range(20):scene._process(1.0/60)
	check(scene.title_open and scene.game.elapsed==0,"Title screen does not consume route time")
	key(scene,KEY_ENTER);key(scene,KEY_W)
	for n in range(60):scene._process(1.0/60)
	check(not scene.title_open and scene.game.strokes>0 and scene.game.travel>0,"Scene keyboard W produces normal paddling movement")
	key(scene,KEY_P)
	var frozen:=snapshot(scene.game)
	for n in range(60):scene._process(1.0/60)
	check(scene.game.paused and scene.keys.is_empty() and snapshot(scene.game)==frozen,"Scene pause clears held keys and freezes gameplay")
	key(scene,KEY_P);key(scene,KEY_M)
	var before: float=scene.game.elapsed
	for n in range(60):scene._process(1.0/60)
	check(scene.overview and scene.game.elapsed==before,"Map view does not pad route duration")
	key(scene,KEY_M);scene._process(1.0/60)
	check(not scene.overview and scene.game.elapsed>before,"Returning from map resumes physics")
	scene._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(scene.game.paused and scene.keys.is_empty(),"Focus loss pauses gameplay and clears keys")
	key(scene,KEY_R)
	check(not scene.game.paused and not scene.overview and not scene.title_open and scene.game.progress==0 and scene.game.elapsed==0 and scene.keys.is_empty(),"Scene R performs a complete playable restart")
	scene._process(1.0/60)
	check(scene.game.strokes==0 and scene.game.travel==0,"Restart cannot reuse old held thrust")
	scene.free()
