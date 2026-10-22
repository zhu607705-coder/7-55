extends SceneTree
var failures:=0
var checks:=0
func check(value: bool,message: String) -> void:
	checks+=1
	if not value: failures+=1; push_error("TEST FAILED: "+message)
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	var state=root.get_node("State")
	state.developer_mode=true
	var shell=load("res://scenes/main.tscn").instantiate(); root.add_child(shell)
	await process_frame
	state.d.native.scene="qizhen_lake"; state.d.runtimeMode="rpg"; state.d.rpgScene="qizhen_lake"
	state.d.qizhenLake.active=true; state.d.qizhenLake.vehicle="kayak"; state.d.qizhenLake.zone="open_water"
	state.d.native.positions={}; shell.world.refresh_world()
	var world=shell.world
	world.kayak.heading=0
	check(not world.can_stand(Vector2(595,200)),"heading-zero hull cannot overlap northwest island horizontally")
	check(not world.can_stand(Vector2(300,415)),"hull cannot overlap island vertically")
	check(world.kayak_collision_rect(Vector2.ZERO,0).size.is_equal_approx(Vector2(83,67)),"source 83x67 eastward hull")
	check(world.kayak_collision_rect(Vector2.ZERO,PI/2).size.is_equal_approx(Vector2(67,83)),"source heading rotates collision AABB")
	check(world.kayak_collision_rect(Vector2.ZERO,PI/4).size.is_equal_approx(Vector2.ONE*150/sqrt(2.0)),"diagonal source extent")
	state.d.qizhenLake.zone="dock"; state.d.native.positions={}; world.refresh_world()
	check(not world.can_stand(Vector2(480,300)),"boat center must remain within authored dock water area")
	world.kayak.heading=-PI/2
	check(not world.can_stand(Vector2(714,410)),"boat bow/stern cannot cross dock walkway")
	check(world.can_stand(Vector2(714,380)),"boat can reverse away from dock boundary")
	var heading: float=world.kayak.heading
	var roll: float=world.kayak.roll
	world.player=Vector2(714,380); world.kayak.position=world.player; world.kayak.speed=-100
	world.kayak.update(.02)
	if not world.can_stand(world.kayak.position): world.kayak.position=world.player; world.kayak.speed=0
	check(world.kayak.status=="running" and world.kayak.heading==heading and world.kayak.roll==roll,"geometry rejection cannot capsize or rotate boat")
	await shell.shutdown()
	shell.queue_free(); await process_frame
	print("Lake world geometry: ",checks," checks, ",failures," failures")
	quit(0 if failures==0 else 1)
