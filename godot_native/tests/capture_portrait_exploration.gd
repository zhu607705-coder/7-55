extends "res://tests/test_portrait_exploration.gd"
## Source-seeded visual fixtures; run only after the lead hands off the GUI.
func capture(label: String) -> void:
	shell.world.transition_alpha=0;shell.world.subtitle="";shell.world.subtitle_left=0;shell.world.queue_redraw()
	shell.toast.text="";shell.toast_time=0;shell.toast.hide()
	await frames(8);await RenderingServer.frame_post_draw
	var output:=OS.get_environment("PORTRAIT_CAPTURE_DIR")
	if output.is_empty():output=ProjectSettings.globalize_path("res://.screenshots/portrait-exploration")
	DirAccess.make_dir_recursive_absolute(output)
	var path:=output+"/"+label+".png"
	root.get_texture().get_image().save_png(path);print("PORTRAIT_CAPTURE ",path)
func run() -> void:
	if DisplayServer.get_name()=="headless":push_error("Capture needs the lead's GUI handoff");quit(2);return
	state=root.get_node("State");state.developer_mode=true;state.d=state.initial()
	shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames()
	DisplayServer.window_set_title("7:55 · Portrait exploration prototype · source fixture")
	if OS.get_environment("PORTRAIT_CAPTURE_HOLD")=="1":
		var parts:=OS.get_environment("PORTRAIT_CAPTURE_SIZE").split("x")
		var dim:=Vector2i(int(parts[0]),int(parts[1])) if parts.size()==2 else Vector2i(390,844)
		DisplayServer.window_set_size(dim);await fixture(dim);await capture("manual-start")
		shell.world.set_process(true)
		print("PORTRAIT_MANUAL_READY: source-seeded dorm, purchased gamepad, bag open; no earned profile")
		return
	for dim in [Vector2i(390,844),Vector2i(430,860),Vector2i(844,390),Vector2i(1440,900)]:
		DisplayServer.window_set_size(dim);await fixture(dim)
		await capture(str(dim.x)+"x"+str(dim.y)+"-dorm-bag-open")
		if dim.x<1100:
			await click(shell.inventory_handle);await capture(str(dim.x)+"x"+str(dim.y)+"-dorm-bag-closed")
			await click(shell.inventory_handle)
		# Synthetic Input.parse_input_event drags do not move the OS pointer in
		# graphical runs. Physical drag acceptance belongs to manual CUA review.
	for dim in [Vector2i(390,844),Vector2i(844,390)]:
		DisplayServer.window_set_size(dim);root.size=dim;shell.size=Vector2(dim)
		for checkpoint in ["c2-library-gate","c2-occupancy-note","c3-canteen-drinks","c3-theater-program","c4-755-hall-clock","c4-755-a2-field-records"]:
			state.begin_checkpoint(checkpoint);shell.mobile_world=true;shell.compact_inventory_open=true;shell._refresh();await frames()
			shell.world.set_process(false);shell.world.transition_alpha=0;shell.world.subtitle="";shell.world.subtitle_left=0;shell.world.queue_redraw()
			await capture(str(dim.x)+"x"+str(dim.y)+"-"+checkpoint)
	DisplayServer.window_set_size(Vector2i(390,844));root.size=Vector2i(390,844);shell.size=Vector2(390,844)
	state.begin_checkpoint("c3-canteen-entry");shell.mobile_world=true;shell._refresh();await frames()
	shell.world.set_process(false);shell.c3_scene_host.set_process(false)
	shell.world.player=Vector2(1053,660);shell.world._sync_player();shell.c3_scene_host.tick(0,true);shell._layout()
	for i in 12:shell.c3_scene_host.tick(100,true)
	shell.world.transition_alpha=0;shell.world.subtitle="";shell.world.subtitle_left=0;shell.world.queue_redraw();await capture("390-canteen-authored-cinematic")
	for i in 60:shell.c3_scene_host.tick(100,true)
	await frames();await capture("390-canteen-return-to-exploration")
	await shell.shutdown();shell.queue_free();await frames()
	print("PORTRAIT_CAPTURE_COMPLETE: source fixtures, not earned play; failures=",failures);quit(1 if failures else 0)
