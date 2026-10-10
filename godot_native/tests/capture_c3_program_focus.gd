extends "res://tests/capture_c3_devices.gd"
func run() -> void:
	if DisplayServer.get_name()=="headless": quit(2); return
	state=root.get_node("State")
	for dim in [Vector2i(1280,720),Vector2i(960,540),Vector2i(390,844),Vector2i(430,860),Vector2i(844,390)]:
		DisplayServer.window_set_size(dim)
		await setup("theater_interior","theater_light_console",dim)
		state.d.theaterHunt.phase="program_search";state.d.theaterHunt.admitted=true;state.d.theaterHunt.collectedProgramIds=["opening","spotlight","finale"]
		for id in controller.PROGRAM.values(): state.d.items[id]=true
		shell.world.refresh_world();await frames();await open_world("theater_light_console")
		await click(shell.c3_device_panel.controls.spotlight)
		await capture(str(dim.x)+"-theater-draft")
		await teardown()
	print("C3 program focus recapture complete");quit(1 if errors else 0)
