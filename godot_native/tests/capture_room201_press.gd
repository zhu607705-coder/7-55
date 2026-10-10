extends "res://tests/test_room201_press_main.gd"
## Source-seeded visual fixtures through the real Main/root-input path.
## These are presentation evidence, not a claim of an earned chapter walkthrough.
## Set ROOM201_CAPTURE_DIR, and use an isolated writable XDG_DATA_HOME.
func capture(label:String)->void:
	await frames(4);await RenderingServer.frame_post_draw
	var output:String=OS.get_environment("ROOM201_CAPTURE_DIR")
	if output.is_empty():output=ProjectSettings.globalize_path("res://.screenshots/room201-press")
	DirAccess.make_dir_recursive_absolute(output)
	var path:String=output+"/"+label+".png"
	root.get_texture().get_image().save_png(path);print("ROOM201_CAPTURE ",path)
func frozen_pose(panel:Control,time:float,label:String)->void:
	panel.view.set_process(false);panel.view.motion_time=time;panel.view.queue_redraw()
	await capture(label)
	panel.view.set_process(true)
func run()->void:
	if DisplayServer.get_name()=="headless":
		print("ROOM201_CAPTURE: parser loaded; rendered capture requires a graphical display")
		quit(0);return
	state_node=root.get_node("State")
	var requested:String=OS.get_environment("ROOM201_CAPTURE_SIZE")
	var dimensions:Array=[Vector2i(390,844)] if requested=="390x844" else [Vector2i(1280,720)]
	for dim:Vector2i in dimensions:
		await setup_press(dim)
		state_node.d.native.settings.reduced_motion=false
		var panel:Control=await open_press()
		var prefix:String="room201-%dx%d-"%[dim.x,dim.y]
		await capture(prefix+"insert")
		# All progression is controller accepted; only pose time is frozen.
		await point_click(scene_point(panel,panel.view.loose_center));await settle(panel)
		await capture(prefix+"idle")
		await point_click(scene_point(panel,panel.view.lever_handle()))
		await frozen_pose(panel,.40,prefix+"lever-down")
		await frozen_pose(panel,.68,prefix+"rebound")
		await settle(panel)
		await key_step(panel,KEY_LEFT);await key_step(panel,KEY_LEFT);await key_step(panel,KEY_DOWN)
		for i in 3:await point_click(scene_point(panel,panel.view.wheel+Vector2(28,0)));await settle(panel)
		check(Model.ready_to_press(state_node.d.native.c4_plate_press),"Capture rail and spring preparation uses actual accepted input")
		await point_click(scene_point(panel,panel.view.lever_handle()))
		await frozen_pose(panel,.68,prefix+"embossed-rebound")
		await settle(panel);await capture(prefix+"calibrated")
		check(panel.session.completed and state_node.d.items.clockPositioningPlate,"Captured success preserves the actual existing plate")
		await mouse_click(panel.close_button);await frames()
		if await finish_cross_floor_route():await capture(prefix+"a1-clock-2245")
		else:await capture(prefix+"route-incomplete")
	await shell.shutdown();shell.queue_free();await frames(3)
	print("ROOM201_CAPTURE: ",checks," checks; ",failures," failures; source-seeded visual fixtures")
	quit(1 if failures else 0)
