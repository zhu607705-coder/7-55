extends "res://tests/test_c3_swan_entrance_shell.gd"
## Explicit visual-QA fixture: no manual save/progress is touched.
func run() -> void:
	if not OS.get_user_data_dir().begins_with("/tmp/"): quit(2); return
	state=root.get_node("State"); state.developer_mode=true; state.d=state.initial()
	var compact: bool=OS.get_cmdline_user_args().has("--compact")
	root.size=Vector2i(390,844) if compact else Vector2i(1280,720)
	shell=load("res://scenes/main.tscn").instantiate(); root.add_child(shell); await frames()
	shell.set_process(false); shell.world.set_process(false)
	solved=Solver.new().solve_fishing("paper")
	await fixture(); capture()
	var effect: Control=shell.world_effect
	for time: float in [0.0,2.0,4.8,6.6]:
		while effect.timeline.elapsed<time:
			effect._process(.01); shell.world._process(.01)
		await frames(3); await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OS.get_environment("SWAN_CAPTURE_DIR")+"/"+("compact" if compact else "desktop")+"-"+str(time)+".png")
	effect.skip_intro(); await frames(3); await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OS.get_environment("SWAN_CAPTURE_DIR")+"/"+("compact" if compact else "desktop")+"-channel.png")
	await shell.shutdown(); shell.queue_free(); await frames()
	print("C3_SWAN_VISUAL_CAPTURE: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
