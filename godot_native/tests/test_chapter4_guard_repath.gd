extends "res://tests/test_chapter4_device_main.gd"
const Navigation=preload("res://scripts/games/chapter4_guard_navigation.gd")
const Metrics=preload("res://scripts/player_metrics.gd")
class Counted extends Navigation:
	var calls:=0
	var elapsed_us:=0
	func path(from:Vector2,to:Vector2)->Array:
		calls+=1
		var began:=Time.get_ticks_usec();var result:Array=super.path(from,to)
		elapsed_us+=Time.get_ticks_usec()-began
		return result
func run()->void:
	if not load("res://tests/native_test_isolation.gd").is_isolated_save():quit(2);return
	state_node=root.get_node("State");state_node.developer_mode=true
	await prepare(Vector2i(1440,900),"c4-755-chase")
	shell.world.set_process(false)
	var world:Control=shell.world
	# Explicit source-pixel physical fixture, before input. It is walkable by
	# the shared player body, while the unchanged guard graph rejects its foot.
	world.player=Vector2(622.125,300);world._sync_player();world._process(0)
	check(world.can_stand(world.player),"Regression anchor is genuinely legal for the unchanged player body")
	for i in 40:world._update_guard(.05)
	check(world.guard_visible and world.guard_state.phase=="running","Actual committed world arms the original chase")
	var nav:=Counted.new();nav.setup(world.collisions,world.world_size.x,world.world_size.y)
	check(not nav.foot_open(Metrics.foot_rect(world.player).get_center()),"Fixture hits the confirmed source-wall nav boundary")
	world.guard_navigation=nav;world.guard_navigation_key=world.world_key+":"+str(world.collisions.hash())
	world.guard_navigation_target=Vector2.INF;world.guard_repath_ms=0
	world._update_guard(0)
	check(nav.calls==1 and world.guard_navigation_target==Vector2.INF,"First empty route is searched immediately")
	var before:Dictionary=state_node.d.chapter4.duplicate(true)
	for i in 15:world._update_guard(.016)
	check(nav.calls==1,"Empty route cannot bypass the existing260ms retry deadline on each frame")
	world._update_guard(.021)
	check(nav.calls==2,"Empty route is retried when the original260ms deadline elapses")
	check(state_node.d.chapter4==before,"Search throttling cannot alter chase phase, attempt, inventory or facts")
	# Real root input still reaches the active world while the guard has an
	# empty route. Keep deterministic simulation ticks, not a direct axis write.
	world.grab_focus();await frames()
	var start:Vector2=world.player
	var event:=InputEventKey.new();event.keycode=KEY_A;event.physical_keycode=KEY_A;event.pressed=true
	Input.parse_input_event(event);Input.flush_buffered_events();await frames(1)
	var began:=Time.get_ticks_usec()
	for i in 6:world._process(.05)
	var input_us:=Time.get_ticks_usec()-began
	event=InputEventKey.new();event.keycode=KEY_A;event.physical_keycode=KEY_A;event.pressed=false
	Input.parse_input_event(event);Input.flush_buffered_events();await frames(1)
	check(world.player.x<start.x-10 and absf(world.player.y-start.y)<.01,"Actual root A key moves the unchanged player away from the boundary")
	check(world.guard_navigation_target!=Vector2.INF,"Next eligible search recovers a finite route after real movement")
	check(not world.guard_capture.active and shell.active_game==null,"Input test retains the original world owner without a story bypass")
	print("GUARD_REPATH_PROFILE ",JSON.stringify({"searchCalls":nav.calls,"searchUs":nav.elapsed_us,"sixInputFramesUs":input_us,"from":[start.x,start.y],"to":[world.player.x,world.player.y]}))
	await shell.shutdown();shell.queue_free();await frames(3)
	print("CHAPTER4_GUARD_REPATH ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
