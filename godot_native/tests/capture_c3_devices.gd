extends "res://tests/test_c3_devices_controls.gd"
## Lead-only source-seeded graphical fixtures, not manual chapter acceptance.
func capture(label: String) -> void:
	await frames(8); await RenderingServer.frame_post_draw
	var output: String=OS.get_environment("C3_CAPTURE_DIR")
	if output.is_empty(): output=ProjectSettings.globalize_path("res://.screenshots/c3-devices")
	DirAccess.make_dir_recursive_absolute(output)
	var path: String=output+"/"+label+".png"
	root.get_texture().get_image().save_png(path); print("C3_CAPTURE ",path)
func run() -> void:
	if DisplayServer.get_name()=="headless": quit(2); return
	state=root.get_node("State")
	for dim in [Vector2i(1280,720),Vector2i(960,540),Vector2i(390,844),Vector2i(430,860),Vector2i(844,390)]:
		DisplayServer.window_set_size(dim)
		await setup("canteen_interior","canteen-mixer",dim)
		await capture(str(dim.x)+"-mixer-landmark")
		for id in controller.RECIPE: state.d.items[id]=true
		await open_world("canteen-mixer")
		await capture(str(dim.x)+"-mixer-open")
		await teardown()
		await setup("theater_interior","theater_ticket_kiosk",dim)
		state.d.theaterHunt.cc98TicketCommissionPhase="delivered"
		await open_world("theater_ticket_kiosk")
		await capture(str(dim.x)+"-theater-keypad")
		for code in [KEY_0,KEY_1,KEY_2,KEY_3]: await key(code)
		await key(KEY_ENTER)
		await capture(str(dim.x)+"-theater-wrong-feedback")
		await teardown()
		await setup("theater_interior","theater_light_console",dim)
		state.d.theaterHunt.phase="program_search"; state.d.theaterHunt.admitted=true; state.d.theaterHunt.collectedProgramIds=["opening","spotlight","finale"]
		for id in controller.PROGRAM.values(): state.d.items[id]=true
		shell.world.refresh_world();await frames();await open_world("theater_light_console")
		await click(shell.c3_device_panel.controls.spotlight)
		await capture(str(dim.x)+"-theater-draft")
		await teardown()
	# Source-shaped soft occlusion at the actual CUA failure location.
	DisplayServer.window_set_size(Vector2i(1280,720));await setup("canteen_interior","drink-bottle-shelf",Vector2i(1280,720))
	shell.world.player=Vector2(1410,360);shell.world._sync_player();shell.world._update_camera()
	await capture("1280-shelf-soft-occlusion")
	await teardown();print("C3 fixture captures complete. Not earned-play proof.");quit(1 if errors else 0)
