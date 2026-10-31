extends "res://campuses/future_learning_center/tests/test_object_input.gd"
func run()->void:
	if not preload("res://tests/native_test_isolation.gd").is_isolated_save():quit(2);return
	root.title="7:55 · 工作室双滑块交互验收"
	RenderingServer.set_default_clear_color(Color("101820"))
	host=SubViewportContainer.new();host.size=Vector2(960,540);host.stretch=false;root.add_child(host)
	viewport=SubViewport.new();viewport.size=Vector2i(960,540);viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;host.add_child(viewport)
	world=load("res://campuses/future_learning_center/scripts/floor_view.gd").new();viewport.add_child(world)
	root.size_changed.connect(fit);fit();root.grab_focus();await process_frame;await process_frame
	touch=OS.get_environment("FLC_TOUCH")=="1"
	world.load_floor(2);check(not world.open_coupling(),"No entry from another floor")
	world.load_floor(3);check(not world.open_coupling(),"No remote entry from spawn")
	var approach:Vector2=world.coupling_approach()
	check(approach.is_finite() and world.set_foot(approach),"Existing room has a legal approach")
	# Start beyond reach and let the ordinary table click route the real actor.
	var distant:Vector2=approach+Vector2(0,150)
	check(world.set_foot(distant),"Clear floor 150 pixels away remains open")
	await process_frame;await capture("coupling_room")
	await click(world.world_to_screen(world.Space.rect(world.coupling_desk().bounds).get_center()))
	check(world.coupling_pending and not world.coupling_tray.visible,"Desk click starts legal approach before closeup")
	var deadline:=Time.get_ticks_msec()+5000
	while not world.coupling_tray.visible and Time.get_ticks_msec()<deadline:await process_frame
	var lab:Control=world.coupling_tray
	check(lab.visible and no_action_strip(lab) and world.invalid_frames==0,"Grounded walk opens one object-driven scene")
	if not lab.visible:write_result();return
	var foot:Vector2=world.player
	await create_timer(.3).timeout;await capture("coupling_initial")
	check(lab.miniature.pool.has("slider0") and lab.miniature.pool.has("terminal_lens"),"Actual apparatus geometry renders through final receiver")
	await stroke(lab.PLATE_HOME,Vector2(380,300))
	check(lab.model.level==0,"Spare tray cannot bypass first physical trial")
	await stroke(lab.block_at(0),lab.block_at(0)+Vector2(450,0))
	check(lab.model.positions[0].x<=300 and lab.model.positions[0].x>280,"Fast actual drag stops linked assembly at wall")
	await capture("coupling_blocked")
	await undo_crank(lab)
	check(lab.model.positions[0]==Vector2(156,274),"Physical undo restores whole assembly")
	await point(lab.block_at(0),"down",7,true);await point(lab.block_at(0)+Vector2(55,0),"move",7,true)
	await point(lab.block_at(0),"up",8,true)
	check(lab.pointer_owner==7,"Second finger cannot release owned slider")
	await point(lab.block_at(0),"up",7,true,true)
	check(lab.model.positions[0]==Vector2(156,274),"Canceled touch rolls assembly back")
	await point(lab.block_at(0),"down");await point(lab.block_at(0)+Vector2(55,0),"move")
	lab._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(lab.gesture.is_empty() and lab.model.positions[0]==Vector2(156,274),"Focus loss releases capture and restores pending move")
	root.grab_focus();await process_frame
	await stroke(lab.clip_at(),lab.CLIP_HOME)
	check(not lab.model.linked,"Lifting actual copper grip detaches bridge")
	await move_points(lab,0,[Vector2(230,274),Vector2(230,302),Vector2(430,302),Vector2(430,230),Vector2(568,230),Vector2(568,274)])
	await move_points(lab,1,[Vector2(156,302),Vector2(430,302),Vector2(430,370),Vector2(568,370),Vector2(568,334)])
	await lever(lab,-42)
	check(lab.model.outcome=="bridge" and not lab.model.completed[0],"Loose blocks on pads still leave real open circuit")
	await capture("coupling_open_circuit")
	await stroke(lab.clip_at(),(lab.model.positions[0]+lab.model.positions[1])/2-Vector2(0,36*lab.miniature.Q))
	check(lab.model.linked,"Dropping copper bridge onto two aligned pins connects")
	check(lab.feedback.contains("已连接") and not lab.feedback.contains("断着"),"Bridge attachment replaces stale open-circuit feedback")
	await lever(lab,-42);await create_timer(.3).timeout;await capture("coupling_testing")
	check(lab.model.running and lab.feedback.contains("正在试通电"),"Valid trial replaces failure with current test feedback")
	lab._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(not lab.model.running and not lab.model.completed[0],"Interrupted powered trial cannot complete")
	root.grab_focus();await process_frame;await lever(lab,-42);await create_timer(1.5).timeout
	check(lab.model.completed[0] and lab.model.powered,"Continuous current lights terminal and records first tray")
	await capture("coupling_first_complete")
	await stroke(lab.PLATE_HOME,Vector2(400,300))
	check(lab.model.level==1 and not lab.model.completed[1],"Physical tray swap introduces second geometry")
	await capture("coupling_second_initial")
	await stroke(lab.clip_at(),lab.CLIP_HOME)
	await move_points(lab,0,[Vector2(230,274),Vector2(230,372),Vector2(584,372),Vector2(584,218),Vector2(474,218)])
	await move_points(lab,1,[Vector2(156,372),Vector2(584,372),Vector2(584,218),Vector2(534,218)])
	await stroke(lab.clip_at(),(lab.model.positions[0]+lab.model.positions[1])/2-Vector2(0,36*lab.miniature.Q))
	await lever(lab,-42);await create_timer(1.5).timeout
	check(lab.model.completed==[true,true] and lab.model.powered,"Second route completes with horizontal bridge using ordinary gestures")
	await capture("coupling_second_complete")
	await click(Vector2(884,110));await capture("coupling_notebook")
	check(lab.book_open and lab.book_page==0,"Notebook records observed results without mandatory hints")
	await click(lab.book_at-Vector2(90,110));await click(Vector2(876,27))
	check(not lab.visible and world.player==foot and world.ui.visible,"Exit restores original grounded room position")
	await capture("coupling_room_complete")
	await click(world.world_to_screen(world.Space.rect(world.coupling_desk().bounds).get_center()))
	check(lab.visible and lab.model.completed==[true,true],"Reenter preserves session record")
	await lever(lab,35)
	check(lab.model.positions[0]==Vector2(156,274) and lab.model.completed==[true,true] and not lab.model.powered,"Physical reset allows replay while retaining session record")
	world.load_floor(2);check(not lab.visible and not world.coupling_pending,"Floor change closes miniature and clears pending entry")
	# Shared renderer integration still dispatches each of the previous five benches.
	for mode:String in ["solar","robotics"]:
		world.set_foot(world.motion_approach(mode));world.open_motion_lab(mode);await process_frame
		check(world.motion_lab.visible and world.motion_lab.miniature.rendered_mode==mode,"Existing renderer retained: "+mode);world.motion_lab.close()
	world.set_foot(world.signal_sync_approach());world.open_signal_sync();await process_frame
	check(world.signal_sync.visible and world.signal_sync.miniature.rendered_mode=="signal","Existing signal renderer retained");world.signal_sync.close()
	var bench_point:Array=world.data.workshopReference.approach
	world.set_foot(Vector2(bench_point[0],bench_point[1]));world.open_workbench();await process_frame
	check(world.workbench.visible and world.workbench.miniature.rendered_mode=="mechanical","Existing mechanical renderer retained");world.workbench.close()
	world.load_floor(3);world.set_foot(world.pantry_approach());world.open_pantry();await process_frame
	check(world.pantry_tray.visible and world.pantry_tray.miniature.rendered_mode=="pantry","Existing pantry renderer retained");world.pantry_tray.close()
	write_result()
func move_points(lab:Control,index:int,points:Array[Vector2])->void:
	for destination:Vector2 in points:
		await stroke(lab.block_at(index),lab.block_at(index)+destination-lab.model.positions[index])
		check(lab.model.positions[index].distance_to(destination)<.1,"Actual drag reaches "+str(destination))
func write_result()->void:
	var failed:Array=results.filter(func(r:Dictionary)->bool:return not r.passed)
	var folder:=OS.get_environment("FLC_CAPTURE_DIR");DirAccess.make_dir_recursive_absolute(folder)
	var file:=FileAccess.open(folder.path_join("coupling_input.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":assertions,"failures":failed.size(),"results":results,"touch":touch,"keyboardEvents":0,"viewport":[root.size.x,root.size.y]},"  "));file.close()
	print("FLC_COUPLING_INPUT: %d checks, %d failures, keyboard events 0"%[assertions,failed.size()]);quit(1 if failed.size() else 0)
