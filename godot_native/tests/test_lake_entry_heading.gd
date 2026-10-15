extends SceneTree
## Zone-entry fixtures exercise the real world placement and live proof owner.
## They do not represent earned manual play or grant a fishing result.
var state: Node
var host: Control
var checks:=0
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(value: bool,label: String) -> void:
	checks+=1
	if not value: failures+=1; push_error(label)
func setup(zone: String) -> void:
	if is_instance_valid(host): host.free()
	state.d=state.initial()
	var s: Dictionary=state.d
	s.native.chapter=3; s.native.scene="qizhen_lake"; s.native.page="c3_lake"; s.native.mode="light"; s.runtimeMode="rpg"; s.rpgScene="qizhen_lake"
	s.qizhenLake.merge({"active":true,"phase":"tool_chain","zone":zone,"vehicle":"kayak","boardingTutorialCompleted":true,"rainSafetyCleared":true,"kayakEquipped":true,"leftPaddleEquipped":true,"rightPaddleEquipped":true},true)
	host=load("res://scripts/world.gd").new(); host.size=Vector2(960,540); root.add_child(host); host.set_process(false)
func frames(count: int) -> void:
	for i: int in range(count): host._process(1.0/60)
func run() -> void:
	if not OS.get_user_data_dir().begins_with("/tmp/"): quit(2); return
	state=root.get_node("State"); state.developer_mode=false
	var map: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/worlds.json")).worlds.qizhen_lake
	for destination: String in ["open_water","channel","swan_cove"]:
		for origin: String in map.zones[destination].kayakEntrySpawns:
			setup(origin)
			var owner: RefCounted=state.lake_module()
			var source_spawn: Dictionary=map.zones[destination].kayakEntrySpawns[origin]
			owner.enter_zone(state.d,destination); host.refresh_world()
			var label:=origin+" -> "+destination
			check(is_equal_approx(host.kayak.heading,float(source_spawn.heading)),label+" retains authored entry heading")
			check(host.can_stand(host.player),label+" begins with legal full hull")
			check(host.player.distance_to(Vector2(source_spawn.x,source_spawn.y))<=40,label+" remains local to authored portal")
			check(host.kayak.position==host.player and host.safe_player==host.player,label+" model/player/safe center agree")
			var entry_session: RefCounted=host.lake_session
			frames(4)
			check(entry_session.status=="running",label+" proof survives actual frame advance")
			if origin=="open_water" and destination=="channel":
				print("CHANNEL_ENTRY ",host.player," hull=",host.kayak_collision_rect(host.player,host.kayak.heading)," status=",entry_session.status)
				var start: Vector2=host.player
				for side: String in ["left","right","left","right"]:
					owner.world_stroke(state.d,host,side,false); frames(45)
				check(host.player.y<start.y-20,"north-facing channel entry paddles away from shore")
				check(entry_session.status=="running" and state.d.qizhenLake.capsizeCount==0,"entry strokes retain live proof without charging a failure")
				owner.world_stroke(state.d,host,"left",true); frames(45)
				owner.world_stroke(state.d,host,"right",true); frames(45)
				check(entry_session.status=="running" and host.can_stand(host.player),"reverse and yaw remain legal after entry")
				# A normal surface rebuild must not invalidate the renewed owner.
				host.world_key=""; host.refresh_world(); frames(4)
				check(host.lake_session!=entry_session and host.lake_session.status=="running","world rebuild renews a legal proof")
				check(not entry_session.valid(state.d,host),"old entry owner cannot authorize new world")
	# The exact saved failed pose remains a fixture; no campaign save is modified.
	setup("channel")
	host.player=Vector2(828,734.215393066406); host._sync_player()
	host.world_key=""; host.refresh_world(); frames(4)
	check(host.can_stand(host.player) and host.lake_session.status=="running","saved failed center recovers through ordinary full-hull placement")
	check(host.kayak.heading==PI,"ordinary channel reload preserves original safe-heading contract")
	check(state.d.qizhenLake.capsizeCount==0 and not state.d.items.brokenNetFrame,"placement grants neither failure nor reward")
	host.free()
	print("Lake entry heading: ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)
