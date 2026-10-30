extends "res://campuses/future_learning_center/tests/test_object_input.gd"
func run()->void:
	if not preload("res://tests/native_test_isolation.gd").is_isolated_save():quit(2);return
	root.title="7:55 · 茶水区慢流交互验收"
	RenderingServer.set_default_clear_color(Color("101820"))
	host=SubViewportContainer.new();host.size=Vector2(960,540);host.stretch=false;root.add_child(host)
	viewport=SubViewport.new();viewport.size=Vector2i(960,540);viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;host.add_child(viewport)
	world=load("res://campuses/future_learning_center/scripts/floor_view.gd").new();viewport.add_child(world)
	root.size_changed.connect(fit);fit();root.grab_focus();await process_frame;await process_frame
	touch=OS.get_environment("FLC_TOUCH")=="1"
	world.load_floor(2);check(not world.open_pantry(),"Pantry cannot open from another floor")
	world.load_floor(3);check(not world.open_pantry(),"Pantry cannot open remotely from spawn")
	check(world.set_foot(world.pantry_approach()),"Existing legal pantry approach")
	await create_timer(.15).timeout;await capture("pantry_room")
	var foot:Vector2=world.player
	await click(world.world_to_screen(world.Space.rect(world.pantry_desk().bounds).get_center()));await create_timer(.3).timeout
	var lab:Control=world.pantry_tray
	check(lab.visible and no_action_strip(lab),"Actual table entry, exit is sole button")
	check(lab.model.water==[0.0,0.0,0.0,0.0],"Four empty glasses, not prefilled props")
	await capture("pantry_initial")
	await stroke(lab.valve_at(),lab.valve_at()-Vector2(0,30))
	check(not lab.model.tap_open,"Valve refuses empty cup station")
	await stroke(lab.handle_at(),lab.handle_at()-Vector2(0,42));await create_timer(.8).timeout
	await stroke(lab.handle_at(),lab.handle_at()-Vector2(0,110))
	check(lab.model.phase=="held" and not lab.model.earned,"Empty level tray cannot complete")
	await stroke(lab.handle_at(),lab.handle_at()+Vector2(0,50));await create_timer(.3).timeout
	await stroke(lab.cup_at(0),lab.DOCK);await create_timer(.3).timeout
	check(lab.model.dock_slot==0 and not lab.model.lift(),"Cup dock physically removes it from tray")
	var before:float=0
	# Capture only an uninterrupted physical pour. macOS focus changes close the
	# real valve; retry with pointer input rather than changing the water/model.
	for retry:int in 3:
		root.grab_focus();await create_timer(.1).timeout
		await stroke(lab.valve_at(),lab.valve_at()-Vector2(0,30))
		var focus_before:int=lab.focus_interruptions
		before=lab.model.water[0]
		await create_timer(5).timeout
		await capture("pantry_slow_flow")
		if lab.focus_interruptions==focus_before: break
		print("WATER_TEST: focus changed during slow-flow capture, retry ",retry+1)
	check(lab.model.water[0]-before>18 and lab.model.water[0]-before<22,"Actual five-second slow pour adds approximately 20 ml")
	check(lab.miniature.pool.water_stream.visible,"Visible stream corresponds to actual flowing state")
	lab._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT);var kept:float=lab.model.water[0]
	await create_timer(.25).timeout
	check(not lab.model.tap_open and lab.model.water[0]==kept,"Focus loss stops water without discarding quantity")
	for retry:int in 3:
		root.grab_focus();await create_timer(.2).timeout
		var focus_before:int=lab.focus_interruptions
		kept=lab.model.water[0]
		await point(lab.cup_at(0),"down");await point(lab.DRAIN,"move");await create_timer(.16).timeout
		await capture("pantry_drain")
		if lab.focus_interruptions==focus_before: break
		print("WATER_TEST: focus changed during pourback capture, retry ",retry+1)
	check(lab.model.draining and lab.model.water[0]<kept,"Holding glass above real drain removes water")
	await point(lab.DRAIN,"up");kept=lab.model.water[0];await create_timer(.3).timeout
	check(not lab.model.draining and lab.model.water[0]==kept,"Releasing tilted cup stops drain and restores dock")
	# Accepted hand positions must still pour inside the visible basin.
	await stroke(lab.valve_at(),lab.valve_at()-Vector2(0,30));await create_timer(5).timeout
	await stroke(lab.valve_at(),lab.valve_at()+Vector2(0,30))
	for offset:Vector2 in [Vector2(-39,0),Vector2(39,0),Vector2(0,-39),Vector2(0,39)]:
		await point(lab.cup_at(0),"down");await point(lab.DRAIN+offset,"move");await process_frame
		var stream:MeshInstance3D=lab.miniature.pool.drain_stream
		var ends:Array[Vector3]=[stream.position-stream.basis.y*.5,stream.position+stream.basis.y*.5]
		var landing:Vector2=lab.miniature.screen(ends[0] if ends[0].y<ends[1].y else ends[1])
		check(stream.visible and Rect2(lab.DRAIN-Vector2(57.5,23),Vector2(115,46)).has_point(landing),"Pourback lands inside basin at hand edge "+str(offset))
		await point(lab.DRAIN+offset,"up")
	# Cancellation and extra touches do not alter cup ownership or silently fill.
	await point(lab.cup_at(0),"down",7,true);await point(lab.slot_at(0),"up",8,true)
	check(lab.pointer_owner==7 and lab.model.dock_slot==0,"Second finger cannot commit cup return")
	await point(lab.slot_at(0),"up",7,true,true)
	check(lab.model.dock_slot==0 and not lab.model.tap_open,"Canceled cup drag preserves water and station")
	await fill_to(lab,0,65)
	for i:int in [1,2,3]:
		await stroke(lab.cup_at(i),lab.DOCK);await create_timer(.25).timeout
		await fill_to(lab,i,[65.0,85.0,115.0,155.0][i])
	check(lab.model.portions_ready() and lab.model.dock_slot==-1,"Four real slow-filled portions returned to tray")
	await capture("pantry_filled")
	await stroke(lab.handle_at(),lab.handle_at()-Vector2(0,42));await create_timer(.9).timeout
	check(lab.model.phase=="tilted" and not lab.model.earned,"Correct water portions still require load placement")
	await capture("pantry_tilted")
	await record_page(lab,"pantry_record_tilted")
	var cups:Array=lab.model.cups.duplicate();var water:Array=lab.model.water.duplicate()
	await stroke(lab.handle_at(),lab.handle_at()+Vector2(0,50));await create_timer(.25).timeout
	check(lab.model.phase=="table" and lab.model.cups==cups and lab.model.water==water,"Downward handle lowers tilted tray without changing prepared cups")
	await capture("pantry_lowered")
	await stroke(lab.cup_at(1),Vector2(950,510));await create_timer(.25).timeout
	check(lab.model.cups==cups and lab.model.water==water,"Invalid drop retains cups and measured water")
	await stroke(lab.cup_at(1),lab.cup_at(3));await create_timer(.3).timeout
	print("WATER_LAYOUT: ",lab.model.water," cups=",lab.model.cups," moment=",lab.model.moment())
	check(lab.model.ready(),"Visible cup swap plus fine-filled water yields valid whole arrangement")
	await stroke(lab.handle_at(),lab.handle_at()-Vector2(0,42));await create_timer(.85).timeout
	check(lab.model.phase=="held" and absf(lab.tray_angle)<.015,"Prepared tray holds visibly level")
	await capture("pantry_balanced")
	await stroke(lab.handle_at(),lab.handle_at()-Vector2(0,110));await create_timer(.5).timeout
	await capture("pantry_carrying")
	lab._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT);await create_timer(.2).timeout
	check(lab.model.phase=="table" and not lab.model.earned and lab.model.water==water,"Canceled delivery preserves measured water but earns nothing")
	root.grab_focus();await create_timer(.2).timeout;lab.set_reduced_motion(true)
	await stroke(lab.handle_at(),lab.handle_at()-Vector2(0,42));await create_timer(.8).timeout
	await stroke(lab.handle_at(),lab.handle_at()-Vector2(0,110));await create_timer(1.6).timeout
	check(lab.model.earned and lab.model.deliveries==1,"Full ordinary delivery works with reduced motion")
	await capture("pantry_served");await record_page(lab,"pantry_record_served")
	await stroke(lab.handle_at(),lab.handle_at()+Vector2(0,90));await create_timer(.25).timeout
	await stroke(lab.support_at(),lab.support_at()-Vector2(27,0));await create_timer(.2).timeout
	await capture("pantry_support_left")
	await stroke(lab.support_at(),lab.support_at()+Vector2(27,0));await create_timer(.2).timeout
	await capture("pantry_support_center")
	await stroke(lab.support_at(),lab.support_at()+Vector2(27,0));await create_timer(.2).timeout
	check(lab.model.support==.25 and not lab.model.stable(),"Earned alternate support makes a new physical condition")
	await capture("pantry_advanced")
	await click(Vector2(884,105));for i:int in 3:await click(lab.book_at+Vector2(164,-25))
	check(lab.book_page==3 and lab.model.deliveries==1,"Three optional clue pages do not grant result")
	await capture("pantry_hint");await click(lab.book_at-Vector2(140,150))
	await click(Vector2(877,25));await create_timer(.15).timeout
	check(not lab.visible and world.ui.visible and world.player==foot and world.space.can_stand(world.player),"Exit restores unchanged legal room feet")
	await capture("pantry_room_served")
	check(world.invalid_frames==0,"No invalid floor frames")
	for mode:String in ["solar","robotics"]:
		await enter(mode);check(world.motion_lab.visible and world.motion_lab.kind==mode,"Incumbent "+mode+" entry");await click(Vector2(877,25))
	world.load_floor(2);world.set_foot(world.signal_sync_approach());await process_frame
	await click(world.world_to_screen(world.Space.rect(world.signal_sync_desk().bounds).get_center()))
	check(world.signal_sync.visible,"Incumbent signal entry");await click(Vector2(877,25))
	var a:Array=world.data.workshopReference.approach;world.set_foot(Vector2(a[0],a[1]));await process_frame
	await click(world.world_to_screen(world.Space.rect(world.workshop_bench().bounds).get_center()))
	check(world.workbench.visible,"Incumbent mechanical entry");await click(Vector2(877,25))
	var failed:Array=results.filter(func(r:Dictionary)->bool:return not r.passed)
	var file:=FileAccess.open(OS.get_environment("FLC_CAPTURE_DIR").path_join("pantry_input.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":assertions,"failures":failed.size(),"results":results,"touch":touch,"keyboardEvents":0,"viewport":[root.size.x,root.size.y],"waterTiming":"Actual elapsed time, no model writes or fast-forward"},"  "));file.close()
	print("FLC_PANTRY_INPUT: %d checks, %d failures"%[assertions,failed.size()]);quit(1 if failed.size() else 0)

func fill_to(lab:Control,slot:int,amount:float)->void:
	await stroke(lab.valve_at(),lab.valve_at()-Vector2(0,30))
	var deadline:=Time.get_ticks_msec()+60000
	var focus_before:int=lab.focus_interruptions
	while lab.model.water[lab.model.cups[slot]]<amount-.6 and Time.get_ticks_msec()<deadline:
		if not lab.model.tap_open and lab.focus_interruptions>focus_before:
			# macOS may focus a different validation process. The runtime correctly
			# closes its valve; the harness resumes with ordinary input, not a write.
			print("WATER_TEST: restore OS focus and reopen physical valve")
			focus_before=lab.focus_interruptions;root.grab_focus();await process_frame
			await stroke(lab.valve_at(),lab.valve_at()-Vector2(0,30))
		await process_frame
	await stroke(lab.valve_at(),lab.valve_at()+Vector2(0,30))
	print("WATER_STOP: cup=",slot," ml=",lab.model.water[lab.model.cups[slot]]," target=",amount)
	check(absf(lab.model.water[lab.model.cups[slot]]-amount)<1.3,"Manual valve stops cup %d near chosen level"%slot)
	await stroke(lab.cup_at(slot),lab.slot_at(slot));await create_timer(.25).timeout

func record_page(lab:Control,name:String)->void:
	await click(Vector2(884,105));await capture(name)
	await click(lab.book_at-Vector2(140,150))
