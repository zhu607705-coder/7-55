extends SceneTree
const Lake=preload("res://scripts/chapters/c3_lake.gd")
const Pressure=preload("res://scripts/games/qizhen_swan_pressure.gd")
var World: Script
var checks: int=0
var failures: int=0
var state: Node
var lake: RefCounted
var host: Control
var fixture: Dictionary
func _initialize() -> void: call_deferred("run")
func check(value: bool,label: String) -> void:
	checks+=1
	if not value:
		failures+=1
		if failures<25: push_error(label)
func close_value(a: Variant,b: Variant) -> bool:
	if (a is float or a is int) and (b is float or b is int): return absf(float(a)-float(b))<0.00001
	if a is Dictionary and b is Dictionary:
		if a.size()!=b.size(): return false
		for key: String in a:
			if not b.has(key) or not close_value(a[key],b[key]): return false
		return true
	return a==b
func setup(phase: String="swan_chase",zone: String="channel") -> void:
	if is_instance_valid(host): host.free()
	state.d=state.initial()
	var s: Dictionary=state.d
	s.native.chapter=3; s.native.scene="qizhen_lake"; s.native.page="c3_lake"; s.native.mode="light"; s.runtimeMode="rpg"; s.rpgScene="qizhen_lake"
	s.qizhenLake.merge({"active":true,"phase":phase,"zone":zone,"vehicle":"kayak","boardingTutorialCompleted":phase!="boarding_tutorial","rainSafetyCleared":true,"kayakEquipped":true,"leftPaddleEquipped":true,"rightPaddleEquipped":true,"paperCaptured":phase=="swan_chase","chaseAttempts":1 if phase=="swan_chase" else 0},true)
	s.items.magneticFishingRod=phase=="swan_chase"
	lake=Lake.new()
	host=World.new(); host.size=Vector2(960,540); root.add_child(host); host.set_process(false)
	host.refresh_world()
	lake.bind_world(s,host)
func project() -> Dictionary:
	var q: Dictionary={}
	for key: String in fixture.qKeys: q[key]=state.d.qizhenLake[key]
	return {"qizhenLake":q,"rpgCheckpoint":state.d.rpgCheckpoint}
func motion(dt: float) -> void:
	if lake.live_session.status=="recovering": return
	var previous: Vector2=host.player
	host.kayak.update(dt)
	if host.can_stand(host.kayak.position): host.player=host.kayak.position
	else: host.kayak.position=previous; host.kayak.speed=0
	host._sync_player()
func run() -> void:
	state=root.get_node("State")
	World=load("res://scripts/world.gd")
	fixture=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/lake_live_source.json"))
	for row: Dictionary in fixture.trace:
		check(close_value(Pressure.step(row.source,row.input),row.expected),"exact original pressure result")
	for tutorial: Dictionary in fixture.tutorials:
		setup("boarding_tutorial","dock")
		for key: String in fixture.qKeys: state.d.qizhenLake[key]=tutorial.initial.qizhenLake[key]
		state.d.rpgCheckpoint=tutorial.initial.rpgCheckpoint
		for row: Dictionary in tutorial.steps:
			var result: Dictionary=lake.world_stroke(state.d,host,row.side,row.reverse)
			check(not result.has("game"),"tutorial remains in real dock world")
			check(close_value(project(),row.expected),"original tutorial "+str(tutorial.sequence)+" "+str(row.side))
	for pursuit: Dictionary in fixture.pursuits:
		setup()
		var session: RefCounted=lake.live_session
		for frame: Dictionary in pursuit.frames:
			host.player=Vector2(frame.x,frame.y); host.kayak.position=host.player
			check(host.can_stand(host.player),"source trace remains on source-map water")
			var event: Dictionary=session.tick(state.d,host,1.0/60)
			if event.has("progress"): state.d.qizhenLake.chaseDistance=clampi(event.progress,0,1000)
			check(close_value(session.pressure_state,frame.pressure),"source scene pressure state")
			if not frame.caught:
				check(absf(session.swan_x-frame.swan[0])<0.00001 and absf(session.swan_y-frame.swan[1])<0.00001,"exact source pursuit position")
				check(absf(session.actual_gap-frame.gap)<0.00001 and absf(session.swan_speed-frame.speed)<0.00001,"exact source pursuit speed/gap")
			check(bool(event.get("finished",false))==bool(frame.finished),"source finish boundary parity")
			check((event.get("failure")=="swan_caught")==bool(frame.caught),"source caught boundary parity")
	# Live movement, original obstacles, actual accepted player pose, no result dictionary.
	setup()
	var start: Vector2=host.player
	var completed: bool=false
	for frame: int in range(900):
		if frame%8==0: lake.world_stroke(state.d,host,"left" if (frame/8)%2==0 else "right")
		motion(1.0/60)
		lake.world_tick(state.d,host,1.0/60)
		if state.d.qizhenLake.phase=="complete": completed=true; break
	check(completed,"real source-channel westbound paddle route completes")
	check(start==Vector2(1280,680) and host.player.x<=190,"source channel start and x190 far-bank finish")
	check(state.d.currentScene=="phone_home" and state.d.chapterThreeInterlude.phase=="reboot" and not state.d.items.magneticFishingRod,"source escape transition/consumption")
	# Idle catch restarts continuously, without charging a capsize.
	setup()
	for frame: int in range(270): motion(1.0/60); lake.world_tick(state.d,host,1.0/60)
	check(lake.live_session.status=="recovering" and state.d.qizhenLake.chaseAttempts==2 and state.d.qizhenLake.capsizeCount==0,"swan catch has original distinct failure accounting")
	for frame: int in range(70): lake.world_tick(state.d,host,1.0/60)
	check(lake.live_session.status=="running" and host.player==Vector2(1280,680) and host.kayak.heading==PI,"1040ms source capsize returns actual channel checkpoint")
	# Repeated paddle capsize resets only controller-owned tutorial state.
	setup("boarding_tutorial","dock")
	for index: int in range(4): lake.world_stroke(state.d,host,"left")
	lake.world_tick(state.d,host,1.0/60)
	check(state.d.qizhenLake.capsizeCount==1 and state.d.qizhenLake.boardingStrokeCount==0 and state.d.qizhenLake.boardingLastSide==null,"same-side tutorial capsize resets count and side")
	# Neither old dictionaries nor another host's live object can claim escape.
	setup()
	var before: Dictionary=state.d.duplicate(true)
	lake.dispatch(state.d,"c3_kayak_result",{"success":true,"distance":1000,"target_zone":"dock"})
	lake.complete_live_escape(state.d,host,{"success":true})
	check(state.d==before,"forged generic and live result dictionaries are zero-write")
	host.player=Vector2(180,680); host.kayak.position=host.player
	lake.world_tick(state.d,host,1.0/60)
	check(state.d.qizhenLake.phase=="swan_chase" and lake.live_session.status=="cancelled","teleport cannot produce live far-bank receipt")
	for i: int in range(3): lake.world_tick(state.d,host,1.0/60)
	check(state.d.qizhenLake.phase=="swan_chase","cancelled proof cannot remint at forged finish pose")
	# Visible portals change source zone immediately; no fabricated travel distance.
	setup("tool_chain","open_water")
	host.player=Vector2(620,110); host.kayak.position=host.player; host._sync_player()
	var portal: Dictionary=lake.dispatch(state.d,"c3_lake_target:qizhen_open_to_channel")
	check(state.d.qizhenLake.zone=="channel" and not portal.has("game"),"physical source portal is immediate")
	var entry: Dictionary=lake.take_entry_spawn(state.d)
	check(close_value(entry,{"x":840,"y":755,"heading":-PI/2}),"source portal preserves from-zone entry spawn")
	check(lake.take_entry_spawn(state.d).is_empty(),"entry spawn is one-use")
	host.free()
	print("Live lake source differential and real world: ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)
