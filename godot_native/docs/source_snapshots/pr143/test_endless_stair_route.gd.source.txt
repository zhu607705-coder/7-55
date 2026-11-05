extends SceneTree
const Model = preload("res://scripts/games/chapter4_endless_stair_model.gd")
const View = preload("res://scripts/presentation/chapter4_endless_stair_view.gd")
var checks := 0
var failures := 0
func _initialize() -> void: run.call_deferred()
func check(ok: bool, note: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("B: " + note)
func run() -> void:
	DirAccess.make_dir_recursive_absolute("user://endless_stair_b3")
	var m = Model.new()
	var d: Dictionary = Model.data()
	check(d.id == "chapter4-endless-stair-chase-B-v3", "B has distinct geometry identity")
	check(d.routes.size() == 25 and d.gates.size() == 12, "twelve flights plus eleven continuous turns")
	check(d.floors.size() == 247 and d.obstacles.size() == 3, "authored repeated floors and three barriers")
	check(Model.TICK_RATE == 60 and Model.PLAYER_SPEED == 3.25 and Model.GUARD_SPEED == 2.71875, "original fixed tick and movement constants unchanged")
	check(Model.MAX_TICKS == 7200, "finite runtime guard remains")
	for i in d.routes.size()-1:
		var a: Dictionary = d.routes[i]
		var b: Dictionary = d.routes[i+1]
		check(absf(a.start+a.length-b.start)<.00001 and a.toXZ==b.fromXZ and absf(a.toY-b.fromY)<.00001, "continuous authored junction %d"%i)
		var before: Vector3 = m.route_position(float(b.start)-.0001,m.route_surface_height(float(b.start)-.0001))
		var after: Vector3 = m.route_position(float(b.start)+.0001,m.route_surface_height(float(b.start)+.0001))
		check(before.distance_to(after)<.001, "no seam teleport %d"%i)
	var last_player := m.route_position(m.player.x,m.player.y)
	var last_guard := m.route_position(m.guard.x,m.guard.y)
	var guard_continuous := true
	var player_continuous := true
	var jumps := 0
	var max_gap := 0.0
	var min_gap := INF
	var crossed: Array = []
	var old_route := "entry"
	var old_grounded: bool = m.player_grounded
	while m.status == "running":
		var mask: int = m.reference_input()
		var old_gx: float = m.guard.x
		m.step(mask)
		var p: Vector3 = m.route_position(m.player.x,m.player.y)
		var g: Vector3 = m.route_position(m.guard.x,m.guard.y)
		guard_continuous = guard_continuous and absf(m.guard.x-old_gx)<=float(d.pursuit.maxSpeed)/60+.00002 and g.distance_to(last_guard)<.20
		player_continuous = player_continuous and p.distance_to(last_player)<.20
		max_gap=maxf(max_gap,m.player.x-m.guard.x)
		min_gap=minf(min_gap,m.player.x-m.guard.x)
		var route_id: String=m.route_section(m.player.x).id
		if route_id!=old_route:
			crossed.append({"tick":m.tick,"route":route_id,"position":[p.x,p.y,p.z],"guardGap":m.player.x-m.guard.x})
			old_route=route_id
		if old_grounded and not m.player_grounded and m.player_velocity.y>0: jumps+=1
		old_grounded=m.player_grounded
		last_player=p; last_guard=g
	check(m.status=="finished", "reference raw inputs reach finite exit: "+m.failure_reason)
	check(m.tick>3000 and m.tick<4000, "playable ascent lasts approximately one minute")
	check(m.gates_passed==12 and m.player_grounded, "all ordered gates and grounded exit required")
	check(guard_continuous and not m.guard_fell, "guard walked all positions without teleport or fall")
	check(player_continuous, "player never jumps coordinates at repeating junction")
	check(jumps>=6, "six damage and obstacle jumps actually executed")
	check(crossed.size()==24, "every route section was traversed in order")
	var proof: Dictionary=m.proof()
	check(Model.validate_proof(proof), "canonical raw-input proof replays full B geometry")
	var final_tick: int=m.tick
	var final_player: Vector2=m.player
	m.step(Model.LEFT)
	check(m.tick==final_tick and m.player==final_player, "finished model stops at exit")
	var output={"checks":checks,"failures":failures,"durationSeconds":float(final_tick)/60,"fixedTicks":final_tick,"jumps":jumps,"minGuardGap":min_gap,"maxGuardGap":max_gap,"junctions":crossed,"proof":proof,"inputSource":"deterministic simulated fixed-tick input; not human play"}

	m.reset()
	for i in 300:
		m.step(0)
		if m.status!="running": break
	check(m.status=="failed" and m.failure_reason=="caught", "idle player is caught")
	m.reset()
	while m.status=="running": m.step(Model.RIGHT)
	check(m.status=="failed" and m.failure_reason in ["caught","player_fell"], "holding run without jumps cannot skip obstacles")
	m.reset()
	check(m.player==Vector2(1,0) and m.guard==Vector2(-3.4,0) and m.tick==0 and m.gates_passed==0 and m.status=="running", "restart clears run state")
	m.player=Vector2(float(d.exit.x)-.01,39.6)
	m.player_grounded=true
	m.step(Model.RIGHT)
	check(m.status!="finished", "teleporting to exit without gates is rejected")
	var v=View.new()
	root.add_child(v)
	await process_frame
	check(v.groups.size()==25 and not v.active and v.menu.visible, "standalone begins in explicit start menu")
	v._start()
	check(v.active and not v.menu.visible and v.model.tick==0, "start resets and enters play")
	v._lose_focus()
	check(not v.active and v.focus_paused and v.menu.visible, "focus loss pauses and clears held input")
	v._menu_action()
	check(v.active and not v.focus_paused, "resume restores running state")
	v.active=false
	var positions: Array=[]
	for route in d.routes:
		v.model.player=Vector2(float(route.start)+.001,float(route.fromY))
		v._present(.0166667)
		positions.append(v.camera.position)
	check(positions.size()==25 and v.actor.position.is_finite(), "all 25 route sections can be presented")
	v.model.player=Vector2(55.6,11.6)
	var before_reveal: Vector2=v.model.player
	v._present(0.0)
	check(v.shadow_groups.size()==25,"all route sections have independent shadow geometry")
	var opaque:=true
	for entry in v.shadow_groups:
		opaque=opaque and entry.node.get_parent()==v.world and entry.node.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY and entry.node.material_override.transparency==BaseMaterial3D.TRANSPARENCY_DISABLED
	check(opaque,"opaque shadow proxies stay independent of visual assembly")
	check(v.model.player==before_reveal,"step assembly never changes player physics position")
	check(v.static_mesh_instances_after<v.static_mesh_instances_before/2,"static visual boxes are batched")
	v.queue_free()
	await process_frame
	output["checks"] = checks
	output["failures"] = failures
	var file:=FileAccess.open("user://endless_stair_b3/B_model_trace.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(output,"  "))
	print("ENDLESS B: %d checks, %d failures. %d fixed ticks = %.2fs; %d jumps; guard gap %.2f..%.2fm"%[checks,failures,final_tick,float(final_tick)/60,jumps,min_gap,max_gap])
	quit(1 if failures else 0)
