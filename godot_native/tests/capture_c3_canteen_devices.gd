extends "res://tests/test_c3_canteen_devices_controls.gd"
## Source-stand fixture captures, not uninterrupted chapter-play acceptance.
func capture(label: String) -> void:
	await frames(8);await RenderingServer.frame_post_draw
	var output: String=OS.get_environment("C3_CAPTURE_DIR")
	DirAccess.make_dir_recursive_absolute(output)
	var path: String=output+"/"+label+".png"
	root.get_texture().get_image().save_png(path);print("C3_CAPTURE ",path)
func run() -> void:
	if DisplayServer.get_name()=="headless":quit(2);return
	state=root.get_node("State")
	var machines: Array=controller.world("canteen_interior").constants.CANTEEN_DRINK_MACHINES
	for dim in [Vector2i(1280,720),Vector2i(390,844),Vector2i(430,860),Vector2i(844,390)]:
		DisplayServer.window_set_size(dim)
		for machine in machines:
			await setup_device(machine.id,dim);await open_world(machine.id)
			await capture(str(dim.x)+"-"+str(machine.value));await key(KEY_ESCAPE);await teardown()
		await setup_device("ordering_kiosk",dim,"menu_order",true);await open_world("ordering_kiosk")
		await touch(shell.c3_device_panel.controls.D);await capture(str(dim.x)+"-menu-dark-refusal")
		await click(shell.c3_device_panel.controls.mode);await capture(str(dim.x)+"-menu-light")
		await teardown()
		await setup_device("bike",dim,"chase_ready")
		state.d.items.greaseTissue=true;state.d.items.cafeteriaWages=true;state.d.wallet.cashCents=200
		await open_world("bike");await capture(str(dim.x)+"-bike-glare")
		await touch(shell.c3_device_panel.controls.mode);await touch(shell.c3_device_panel.controls.inspect);await touch(shell.c3_device_panel.controls.pay)
		await capture(str(dim.x)+"-bike-dark-refusal")
		await touch(shell.c3_device_panel.controls.mode);await touch(shell.c3_device_panel.controls.clean);await touch(shell.c3_device_panel.controls.pay)
		await capture(str(dim.x)+"-bike-paid");await teardown()
	print("C3 canteen device captures finished. Seeded local fixtures only.");quit(1 if errors else 0)
