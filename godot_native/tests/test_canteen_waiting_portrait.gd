extends "res://tests/test_portrait_exploration.gd"
## Explicit source checkpoint fixture. Actual Main, projected root touch events,
## world collision/movement, and the controller's original timeline capability.
var receipts:=0
var handoffs:=0
func waiting_fixture(dimensions: Vector2i) -> void:
	root.size=dimensions;shell.size=Vector2(dimensions)
	check(state.begin_checkpoint("c3-canteen-entry"),"source canteen entry checkpoint loads")
	shell.mobile_world=true;shell.compact_inventory_open=false;shell._refresh();await frames()
	shell.world.set_process(false);shell.c3_scene_host.set_process(false)
	shell.c3_scene_host.tick(0,true);await frames()
	check(shell.c3_scene_host.current!=null and shell.c3_scene_host.current.status=="waiting","approach owns original waiting session")
	check(shell.world.player==Vector2(1194,834),"approach starts at original entrance")
	check(not shell._authored_world_contract() and not shell.c3_scene_host.blocks_world_input(),"waiting does not own cinematic camera or movement")
	check(shell.world.mobile_exploration and shell.world_frame.scale==Vector2.ONE,"waiting uses physical-scale exploration")
	check(shell.world.size.y>=600 if dimensions.y>dimensions.x else shell.world.size.y>=300,"waiting fills useful viewport height")
	check(Vector2(shell.world_viewport.size)==shell.world.size,"waiting viewport projection matches controls")
	var controls:Dictionary=shell.world.mobile_control_metrics()
	check(controls.interact.size.x>=44 and controls.interact.size.y>=44 and controls.stick_rect.size==Vector2(100,100),"waiting exposes practical touch controls")
	check(not state.d.canteenHunt.entryPaperEscaped and shell.world.targets.is_empty(),"waiting grants neither receipt nor device targets")
	print("WAITING_MEASURE ",dimensions," world=",shell.world.size," scale=",shell.world_frame.scale," player=",shell.world.player)
func hold_direction(direction: Vector2,steps: int,probe:=true) -> void:
	var point:=world_screen(shell.world.mobile_control_metrics().stick+direction*32)
	touch(point,true);await frames(2)
	check(shell.world.touch_axis.dot(direction)>.99,"projected touch reaches actual exploration stick")
	for i in steps:
		shell.world._process(.05)
		if probe:shell.c3_scene_host.tick(0,true)
		if shell.c3_scene_host.blocks_world_input():break
	touch(point,false,true);await frames(2)
func tick_to(target: float) -> void:
	while shell.c3_scene_host.current!=null and shell.c3_scene_host.current.elapsed_ms<target:
		shell.c3_scene_host.tick(minf(100,target-shell.c3_scene_host.current.elapsed_ms),true)
func run() -> void:
	check(ProjectSettings.globalize_path("user://").begins_with("/tmp/"),"isolated test profile")
	if failures:quit(1);return
	state=root.get_node("State");state.developer_mode=true;state.d=state.initial()
	shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames()
	shell.c3_scene_host.set_process(false);shell.world.set_process(false)
	state.action_completed.connect(func(action,_a,_b,_c):
		if action=="c3_entry_paper_complete":receipts+=1
	)
	shell.c3_scene_host.cinematic_started.connect(func():
		handoffs+=1
		check(shell.world.size==Vector2(960,540) and not shell.world.mobile_exploration,"canonical surface restored synchronously before camera sample")
	)
	for dimensions in [Vector2i(390,844),Vector2i(430,860),Vector2i(844,390)]:
		await waiting_fixture(dimensions)
		var session:RefCounted=shell.c3_scene_host.current
		var before:Vector2=shell.world.player
		var receipt_before:=receipts
		var handoff_before:=handoffs
		var save_before:String=JSON.stringify(state.d)
		# Real modal consumes projected touches, while the same session remains pending.
		shell._show_settings();await frames()
		var point:=world_screen(shell.world.mobile_control_metrics().stick+Vector2.UP*32)
		touch(point,true);shell.world._process(.05);shell.c3_scene_host.tick(100,true);touch(point,false,true)
		check(shell.world.player==before and shell.c3_scene_host.current==session and session.status=="waiting","modal interruption cannot move or trigger waiting paper")
		check(JSON.stringify(state.d)==save_before,"opening and closing settings cannot create proof")
		shell._close_modal();await frames()
		point=world_screen(shell.world.mobile_control_metrics().stick+Vector2.RIGHT*32)
		touch(point,true);await frames(2)
		check(shell.world.touch_axis.length()>0,"waiting accepts new touch after modal dismissal")
		shell.world._notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
		var idle:float=session.idle_ms;shell.c3_scene_host.tick(100,false)
		check(shell.world.touch_axis==Vector2.ZERO and session.idle_ms==idle and shell.c3_scene_host.current==session,"focus loss cancels held controls and freezes original waiting session")
		touch(point,false,true)
		# Resize uses the same session and source position. No arrival or timeline receipt.
		var rotated:=Vector2i(844,390) if dimensions.y>dimensions.x else Vector2i(390,844)
		root.size=rotated;shell.size=Vector2(rotated);shell._layout();await frames()
		check(shell.c3_scene_host.current==session and session.status=="waiting" and shell.world.mobile_exploration,"rotation keeps waiting in exploration")
		check(shell.world.player==before and JSON.stringify(state.d)==save_before,"waiting rotation preserves source state and position")
		root.size=dimensions;shell.size=Vector2(dimensions);shell._layout();await frames()
		# Traverse the source aisle using projected physical touch controls. No
		# teleport, direct status mutation, proximity change, or completion injection.
		await hold_direction(Vector2.RIGHT,5)
		check(shell.world.player.x>before.x and session.status=="waiting","real touch moves around the original entrance wall")
		await hold_direction(Vector2.UP,22)
		check(shell.world.player.y<before.y and session.status=="waiting","real touch approach stays pending outside source radius")
		check(shell.world.player.distance_to(session.idle_pose().point)>session.TRIGGER_RADIUS,"pre-trigger source distance stays outside360")
		check(receipts==receipt_before and not state.d.canteenHunt.entryPaperEscaped,"movement cannot issue premature receipt")
		await hold_direction(Vector2.UP,12)
		check(session.status=="playing" and shell.c3_scene_host.current==session and handoffs==handoff_before+1,"real post-collision proximity starts original session exactly once")
		check(session.trigger_player==shell.world.player and session.trigger_player.distance_to(session.trigger_paper)<=session.TRIGGER_RADIUS,"trigger proof contains actual collision-validated source position")
		# The real trigger tick changed Main's displayed size. Validate before a
		# second host tick can conceal stale portrait metrics from the first shot.
		var paper:Control=shell.c3_scene_host.paper
		var display_scale:float=shell.world_frame.scale.x
		check(is_equal_approx(paper.display_scale,display_scale),"first cinematic tick reads the new Main display scale")
		check(paper.narrow_text()==(shell.world.size.x*display_scale<620),"first cinematic tick uses the real displayed width")
		var first_text:Dictionary=paper.text_layout("玩家：找到了。",Vector2(480,270),108,1)
		check(first_text.fontSize*display_scale>=14,"first cinematic text retains14physical pixels after handoff")
		var half:=Vector2(480,270)/1.18
		var source_camera:=Vector2(clampf(shell.world.player.x,half.x,maxf(half.x,shell.world.world_size.x-half.x)),clampf(shell.world.player.y,half.y,maxf(half.y,shell.world.world_size.y-half.y)))
		check(shell.c3_scene_host.entry_camera.distance_to(source_camera)<.001,"discovery camera starts from canonical source clamp")
		check(shell.world.size==Vector2(960,540) and not shell.world.mobile_exploration and shell.c3_scene_host.blocks_world_input(),"playing owns canonical camera and locks controls")
		check(shell.world.touch_axis==Vector2.ZERO and shell.world.mobile_touch_roles.is_empty(),"cinematic takeover retires held portrait touch")
		var progress_before:String=JSON.stringify(state.d)
		root.size=rotated;shell.size=Vector2(rotated);shell._layout();await frames()
		check(shell.world.size==Vector2(960,540) and shell.c3_scene_host.current==session and JSON.stringify(state.d)==progress_before,"playing rotation retains canonical camera, session, and proof")
		var elapsed:float=session.elapsed_ms;shell.c3_scene_host.tick(100,false)
		check(session.elapsed_ms==elapsed and shell._authored_world_contract(),"focus pause retains authored ownership and time")
		shell._show_settings();await frames();shell.c3_scene_host.tick(0,true)
		check(shell.c3_scene_host.current==session and shell.world.size==Vector2(960,540) and not state.d.canteenHunt.entryPaperEscaped,"playing modal cannot discard session or grant receipt")
		shell._close_modal();await frames()
		tick_to(session.escape_end_ms)
		check(session.status=="playing" and not session.paper_pose().visible and not state.d.canteenHunt.entryPaperEscaped,"paper exit still waits for original camera return")
		tick_to(session.completion_ms-1)
		check(shell._authored_world_contract() and receipts==receipt_before and not state.d.canteenHunt.entryPaperEscaped,"return shot retains cinematic contract through last millisecond")
		shell.c3_scene_host.tick(1,true);await frames()
		check(session.status=="consumed" and shell.c3_scene_host.current==null and receipts==receipt_before+1 and state.d.canteenHunt.entryPaperEscaped,"authentic completed route consumes exactly one receipt")
		check(shell.world.mobile_exploration and not shell._authored_world_contract() and not shell.world.targets.is_empty(),"receipt releases exploration controls and original device targets")
		root.size=dimensions;shell.size=Vector2(dimensions);shell._layout();await frames()
		check(shell.world.size.y>=600 if dimensions.y>dimensions.x else shell.world.size.y>=300,"post-cinematic viewport returns useful height")
		before=shell.world.player
		await hold_direction(Vector2.DOWN,2,false)
		check(shell.world.player.y>before.y and receipts==receipt_before+1,"restored projected touch moves without duplicate receipt")
	await shell.shutdown();shell.queue_free();await frames()
	print("CANTEEN_WAITING_PORTRAIT: %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
