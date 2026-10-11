extends SceneTree
## Isolated actual-Main preview. Start with two conditions; the original third
## condition action triggers the normal renderer. No formal save is read/written.
var shell: Control
var state: Node
var capture_dir := ""
func _initialize() -> void: run.call_deferred()
func frames(count := 4) -> void:
	for i in count: await process_frame
func run() -> void:
	root.size = Vector2i(430,860)
	state = root.get_node("State"); state.developer_mode = true; state.d = state.initial()
	state.d.native.page = "bonsai"; state.d.flags.codeScattered = true
	state.d.flags.plantWatered = true; state.d.flags.plantLit = true
	state.d.items.fertilizer = true; state.d.ui.brightness = 85
	state.d.native.settings.music = false; state.d.native.settings.effects = false
	shell = load("res://scenes/main.tscn").instantiate(); root.add_child(shell); await frames()
	capture_dir = OS.get_environment("BONSAI_CAPTURE_DIR")
	if not capture_dir.is_empty(): DirAccess.make_dir_recursive_absolute(capture_dir)
	await create_timer(0.7).timeout
	shell._on_phone_action("c1_plant", "fertilizer")
	await frames(1)
	if capture_dir.is_empty():
		await create_timer(5.3).timeout
	else:
		var capture_start := Time.get_ticks_msec()
		var manifest: Array = []
		while Time.get_ticks_msec() - capture_start < 5500:
			await RenderingServer.frame_post_draw
			var filename := "flower-%03d.png" % manifest.size()
			manifest.append({"file":filename,"elapsedMs":Time.get_ticks_msec()-capture_start})
			root.get_texture().get_image().save_png(capture_dir.path_join(filename))
			await process_frame
		FileAccess.open(capture_dir.path_join("capture.json"),FileAccess.WRITE).store_string(JSON.stringify(manifest,"\t"))
	print("BONSAI_PREVIEW original action committed; digit remains uncollected: ",state.d.digits.d4)
	if not capture_dir.is_empty():
		await shell.shutdown(); shell.queue_free(); await frames(); quit()
