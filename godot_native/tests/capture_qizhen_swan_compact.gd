extends SceneTree
## Native 390x844 viewport rendering, not a physical-device touch certification.
var checks: int = 0
var failures: int = 0
func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)

func capture(view: Control, viewport: SubViewport, label: String) -> void:
	view.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var boundary := Rect2(Vector2.ZERO, Vector2(390,844))
	for action: String in view.controls:
		check(boundary.encloses(view.controls[action]), label + ": visible " + action)
	check(boundary.has_point(view._screen(view.kayak.position)),label + ": boat on screen")
	var output: String = OS.get_environment("SWAN_CAPTURE_DIR")
	if not output.is_empty():
		var result: int = viewport.get_texture().get_image().save_png(output+"/swan-compact-"+label+".png")
		check(result == OK, label + ": screenshot written")

func run() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(390,844)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var view: Control = load("res://scenes/qizhen_swan_entrance_preview.tscn").instantiate()
	viewport.add_child(view)
	view.set_process(false)
	view.timeline.advance(3.5)
	view._process(0)
	await capture(view,viewport,"intro")
	view.skip_intro()
	await capture(view,viewport,"play")
	view.paused = true
	await capture(view,viewport,"paused")
	viewport.queue_free()
	await process_frame
	print("QIZHEN_SWAN_COMPACT: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
