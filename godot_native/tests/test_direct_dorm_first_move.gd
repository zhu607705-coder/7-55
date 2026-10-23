extends "res://tests/test_portrait_exploration.gd"
## Original checkpoint prerequisites, then actual root touch input. No virtual
## axis injection and no synthesized manual-control or reservation completion.
func tap(point:Vector2)->void:
	motion(point);touch(point,true);touch(point,false);await frames(3)
func door_point()->Vector2:
	var w:Control=shell.world
	w._update_camera()
	for y:int in range(736,793,4):
		for x:int in range(445,516,4):
			var source:=Vector2(x,y);var local:Vector2=(source-w.camera)*w.zoom+w.size/2
			if w.exploration_safe_rect(true).has_point(local) and w._pick_target(source).get("id","")=="exit_door":return world_screen(local)
	return Vector2.INF
func run()->void:
	check(load("res://tests/native_test_isolation.gd").is_isolated_save(),"isolated root-touch dorm fixture")
	state=root.get_node("State");state.action_completed.connect(func(id,_a,_b,_c):actions.append(id))
	for extent:Vector2i in [Vector2i(390,844),Vector2i(844,390),Vector2i(1280,720)]:
		state.developer_mode=true;check(state.begin_checkpoint("c2-manual-movement"),"original manual-movement checkpoint")
		root.size=extent;shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames(6)
		shell._show_world_mobile();await frames();var w:Control=shell.world;w.set_process(false);w.native_dorm.set_process(false)
		# The authored exercise automatically paces before the gamepad is connected.
		# Use its safe source aisle, then check input ownership before any pacing tick.
		w.player=Vector2(480,720);w._sync_player();w._update_camera();w.queue_redraw();await frames();actions.clear()
		var floor:=floor_touch_point(Vector2.RIGHT,48.0)
		check(floor.is_finite() and not state.d.actOne.controlsInstalled and not state.d.actOne.manualControlTested,"fresh fixture has visible empty floor and no installed controls "+str(extent))
		if floor.is_finite():await tap(floor)
		check(w._floor_route.is_empty() and w._floor_pending_interaction.is_empty() and not state.d.actOne.manualControlTested and actions.count("c2_manual_input")==0,"touch cannot create movement or first-step proof before the original gamepad installation")
		state.act("c2_use_gamepad");await frames();w.set_process(false)
		check(state.d.actOne.controlsInstalled and state.d.actOne.movementEnabled and not state.d.actOne.manualControlTested and not w._manual_sent and not state.d.items.gamepad,"original gamepad action enables movement without fabricating its first-step fact")
		floor=floor_touch_point(Vector2.RIGHT,48.0)
		check(floor.is_finite(),"installed controls retain a visible legal touch destination")
		if floor.is_finite():await tap(floor)
		check(not w._floor_route.is_empty(),"first actual floor tap is accepted while manualControlTested is still false")
		var before:Vector2=w.player;var steps:=0
		while not w._floor_route.is_empty() and steps<200:
			var previous:Vector2=w.player;w._process(.016);steps+=1
			check(w.can_stand(w.player) and previous.distance_to(w.player)<=160*.016+.001,"fresh touch walk retains the original dorm body and speed")
		check(w.player.distance_to(before)>0 and w._input_kind=="touch" and state.d.actOne.manualControlTested and actions.count("c2_manual_input")==1,"actual touch displacement earns the original first-step controller fact exactly once")
		check(state.d.actOne.phase=="reservation_briefing_required" and not state.d.actOne.canLeaveDorm,"first movement still requires the original reservation chain")
		var door:=door_point();check(door.is_finite(),"painted dorm door has a visible direct-touch target")
		if door.is_finite():await tap(door)
		for i:int in range(100):w._process(.016)
		check(state.d.native.scene=="dorm_hub" and not state.d.actOne.canLeaveDorm,"direct door touch cannot bypass the original reservation gate")
		state.act("c2_reservation_briefing");state.act("c2_reserve",{"library":"基础馆","room":"一层书库","seat":"022"});await frames();w.set_process(false)
		check(state.d.actOne.canLeaveDorm and state.d.actOne.phase=="movement_ready","original reservation actions alone authorize the dorm exit")
		door=door_point();check(door.is_finite(),"authorized painted exit remains reachable through the direct-touch picker")
		if door.is_finite():await tap(door)
		for i:int in range(160):
			if state.d.native.scene!="dorm_hub":break
			w._process(.016)
		check(state.d.native.scene=="campus_bootstrap" and state.d.rpgCheckpoint=="campus_spawn" and state.d.actOne.phase=="complete","the original gate now accepts a real direct touch and preserves the campus handoff")
		await shell.shutdown();shell.free();await frames()
	print("DIRECT_DORM_FIRST_MOVE: %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
