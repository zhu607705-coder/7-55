extends SceneTree
## The guard must account for the kayak's fixed-step carry, not loosen its speed limit.
var state: Node
var host: Control
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)
func setup() -> void:
	if is_instance_valid(host): host.free()
	state.d=state.initial()
	state.d.native.merge({"chapter":3,"scene":"qizhen_lake","page":"c3_lake","mode":"light","positions":{}},true)
	state.d.runtimeMode="rpg";state.d.rpgScene="qizhen_lake"
	state.d.qizhenLake.merge({"active":true,"phase":"tool_chain","zone":"open_water","vehicle":"kayak","boardingTutorialCompleted":true,"rainSafetyCleared":true,"kayakEquipped":true,"leftPaddleEquipped":true,"rightPaddleEquipped":true},true)
	host=load("res://scripts/world.gd").new();host.size=Vector2(430,860);root.add_child(host);host.set_process(false);host.refresh_world()
	state.lake_module().bind_world(state.d,host)
func stroke(side: String,reverse: bool=false) -> void:
	state.lake_module().world_stroke(state.d,host,side,reverse)
func accelerate(reverse: bool=false) -> void:
	for i in range(8): stroke("left" if i%2==0 else "right",reverse)
func session() -> RefCounted: return state.lake_module().live_session
func move_frame(dt: float) -> void: host._process(dt)
func run() -> void:
	state=root.get_node("State");state.developer_mode=true
	setup();accelerate()
	check(is_equal_approx(host.kayak.speed,340.0),"real alternating strokes reach the unchanged 340 speed cap")
	move_frame(.0075)
	var before: Vector2=host.player
	move_frame(.001)
	print("Fixed-step crossing: travel=",host.player.distance_to(before)," frame-only-limit=",340*.001+2," remainder=",host.kayak.remainder)
	check(host.player.distance_to(before)>2.34,"regression actually crosses the old frame-only displacement bound")
	check(host.can_stand(host.player) and host.player.is_equal_approx(host.kayak.position),"the reproduced motion retains legal full hull and exact model position")
	check(session().status=="running","fractional accumulated physics time cannot cancel ordinary paddling")
	for reverse: bool in [false,true]:
		setup();accelerate(reverse)
		for dt: float in [.0075,.001,.032,.0005,.004,.012,.001,.049,.0004,.018,.003]:
			move_frame(dt)
			check(session().status=="running","variable frame sequence retains live paddle ownership")
			check(host.can_stand(host.player) and host.player.is_equal_approx(host.kayak.position),"variable frames preserve hull and model agreement")
	# A stopped world does not bank wall time; its next frame consumes only pending carry.
	setup();accelerate();move_frame(.0075)
	var elapsed: float=host.kayak.elapsed
	await process_frame;await process_frame
	check(host.kayak.elapsed==elapsed,"paused world does not advance or bank simulation time")
	move_frame(.001)
	check(session().status=="running","pause/reentry retains the existing fractional clock")
	# Frames without a physics step cannot borrow the unprocessed fraction for movement.
	setup();move_frame(.004)
	host.player+=Vector2(2.1,0);host.kayak.position=host.player
	move_frame(.001)
	check(session().status=="cancelled","no completed step cannot authorize an invented 2.1 px displacement")
	# The original finite pose, model agreement, hull and speed guards remain mandatory.
	setup();host.player+=Vector2(40,0);host.kayak.position=host.player
	check(state.lake_module().world_tick(state.d,host,.001).message.contains("位置已失效"),"unearned jump cannot become a valid receipt")
	setup();host.player+=Vector2(.5,0)
	state.lake_module().world_tick(state.d,host,.02)
	check(session().status=="cancelled","model/player disagreement is rejected")
	setup();var obstacle: Rect2=host._rect(host.collisions[0]);host.player=obstacle.get_center();host.kayak.position=host.player
	state.lake_module().world_tick(state.d,host,5)
	check(session().status=="cancelled","large time allowance cannot authorize a hull inside an original solid")
	for carry: float in [-.1,1.0,NAN]:
		setup();host.kayak.remainder=carry
		state.lake_module().world_tick(state.d,host,.001)
		check(session().status=="cancelled","invalid or invented fractional carry is rejected")
	# Original same-side capsize and 1040 ms safe recovery keep their authored rules.
	setup()
	for i in range(4): stroke("left")
	move_frame(.05)
	check(session().status=="recovering","same-side capsize remains unchanged")
	for i in range(21): move_frame(.05)
	check(session().status=="running","ordinary safe recovery renews the movement sample")
	stroke("right");move_frame(.001)
	check(session().status=="running" and host.can_stand(host.player),"recovered model carry cannot invalidate the first new stroke")
	setup();accelerate();move_frame(.0075);move_frame(.001)
	check(session().status=="running","new normal binding has its own movement clock")
	host.free()
	print("Kayak fixed-step guard: ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)
