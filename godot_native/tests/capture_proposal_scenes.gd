extends "res://tests/capture_ui_redesign.gd"
## Isolated runtime scene captures for the illustrated proposal.
func run() -> void:
	if DisplayServer.get_name()=="headless": quit(2);return
	if not load("res://tests/native_test_isolation.gd").is_isolated_save(): quit(2);return
	create_timer(180).timeout.connect(func():push_error("Proposal capture timeout");quit(2))
	output=OS.get_environment("UI_CAPTURE_DIR")
	if output.is_empty(): quit(2);return
	DirAccess.make_dir_recursive_absolute(output)
	state=root.get_node("State");state.developer_mode=true
	Engine.max_fps=30
	var dimensions:=Vector2i(1600,900)
	DisplayServer.window_set_size(dimensions);root.size=dimensions
	for row in [
		["library_interior","c2-occupancy-note","library"],
		["canteen_interior","c3-canteen-entry","canteen"],
		["theater_interior","c3-theater-program","theater"],
		["qizhen_lake","c3-qizhen-location","lake"],
		["duan_yongping_temporal_maze","c4-755-hall-clock","teaching"],
		["campus_bootstrap","c2-library-gate","campus"]
	]:
		if not fixture_checkpoint(row[1]):quit(1);return
		state.d.native.scene=row[0];state.d.rpgScene=row[0];state.d.native.settings.volume=0
		await fresh_shell(dimensions)
		shell.mobile_world=true;shell._refresh();shell._layout()
		await frames(35)
		shell.world.transition_alpha=0;shell.world.subtitle=""
		await frames(3);await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(output.path_join("current_"+row[2]+".png"))
	await shell.shutdown();shell.queue_free();await frames(10)
	for id in ["buct_changping","buct"]:
		var campus: Node2D=load("res://campuses/"+id+"/scenes/playable.tscn").instantiate()
		root.add_child(campus);await frames(30)
		campus.start_guide()
		await create_timer(12.0).timeout
		campus.close_info()
		await frames(5);await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(output.path_join("current_"+id+".png"))
		campus.queue_free();await frames(10)
	quit()
