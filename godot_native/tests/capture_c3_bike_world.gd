extends "res://tests/test_c3_bike_world_drop.gd"
## Source phase/stand fixtures only; not earned campaign gameplay.
func capture(label: String) -> void:
	await frames(8);await RenderingServer.frame_post_draw
	var path: String=OS.get_environment("C3_BIKE_CAPTURE_DIR")+"/"+label+".png"
	root.get_texture().get_image().save_png(path);print("BIKE_CAPTURE ",path)
func run() -> void:
	if DisplayServer.get_name()=="headless":quit(2);return
	state=root.get_node("State");Input.emulate_mouse_from_touch=false
	for dim in [Vector2i(1440,900),Vector2i(390,844),Vector2i(430,860),Vector2i(844,390)]:
		DisplayServer.window_set_size(dim);await bike_fixture(dim)
		await capture(str(dim.x)+"-bike-before")
		state.select_item("greaseTissue");state.act("c3_target:bike");await frames();await capture(str(dim.x)+"-bike-clean")
		state.select_item("cafeteriaWages");state.act("c3_target:bike");await frames();await capture(str(dim.x)+"-bike-paid")
		await bike_fixture(dim,true);await capture(str(dim.x)+"-bike-dark")
	if is_instance_valid(shell):await shell.shutdown();shell.queue_free();await frames()
	print("Bicycle fixture captures finished; failures=",failures);quit(1 if failures else 0)
