extends SceneTree
## Real production renderer, isolated DEV fixtures, never campaign completion.
var shell: Control
var state: Node
var report: Array = []
var output: String
func _initialize() -> void: run.call_deferred()
func frames(count: int = 6) -> void:
	for unused in count: await process_frame
func capture(id: String) -> void:
	await frames()
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var path := output.path_join(id + ".png")
	var error := image.save_png(path)
	report.append({"id":id,"width":image.get_width(),"height":image.get_height(),"error":error})
	if error != OK: push_error("Screenshot failed: " + path)
func run() -> void:
	if DisplayServer.get_name() == "headless": quit(2); return
	if not load("res://tests/native_test_isolation.gd").is_isolated_save(): quit(2); return
	Engine.max_fps = 30
	output = OS.get_environment("UI_CAPTURE_DIR")
	if output.is_empty(): quit(2); return
	DirAccess.make_dir_recursive_absolute(output)
	state = root.get_node("State")
	state.developer_mode = true
	state.d = state.initial()
	shell = load("res://scenes/main.tscn").instantiate()
	root.add_child(shell)
	await frames()
	for dimensions: Vector2i in [Vector2i(1440,900),Vector2i(390,844)]:
		DisplayServer.window_set_size(dimensions)
		root.size = dimensions
		shell.size = Vector2(dimensions)
		for sample: Array in [["c2-dorm-exit","phone_home"],["c2-dorm-exit","zjuding"],["c2-dorm-exit","library_app"],["c2-dorm-exit","settings"],["c3-interlude-reboot","c35_recovery"],["c3-interlude-reboot","c35_network"],["c3-interlude-reboot","c35_voice"]]:
			if not state.begin_checkpoint(sample[0]): push_error("Unknown checkpoint"); quit(2); return
			state.d.native.scene = ""
			state.d.native.page = sample[1]
			state.d.native.settings.volume = 0
			shell.mobile_world = false
			shell._refresh()
			shell._layout()
			await capture("%dx%d-%s" % [dimensions.x,dimensions.y,sample[1]])
		state.begin_checkpoint("c2-dorm-exit")
		shell._refresh()
		shell.mobile_world = true
		shell._layout()
		await frames(30)
		shell.world.transition_alpha = 0
		shell.world.queue_redraw()
		await capture("%dx%d-world" % [dimensions.x,dimensions.y])
		var body: VBoxContainer = shell._modal_base("调查记录")
		body.add_child(shell._label("在现场收集证据，再回到这里核对。",17))
		await capture("%dx%d-short-dialog" % [dimensions.x,dimensions.y])
		shell._close_modal()
	var file := FileAccess.open(output.path_join("captures.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t")); file.close()
	await shell.shutdown()
	shell.queue_free()
	await frames()
	print("UI_CAPTURE_COMPLETE ",report.size())
	quit(0)
