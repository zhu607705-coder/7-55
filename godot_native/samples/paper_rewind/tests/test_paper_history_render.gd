extends SceneTree
## Real-renderer-only regression: a recorded pixel must never leave its window.
const SCENE = preload("res://scenes/paper_rewind.tscn")
var view: Control
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok: failures += 1; push_error(message)
	else: print("HISTORY_RENDER_PASS ", message)
func settled_image() -> Image:
	for i: int in range(4):
		await process_frame
		await RenderingServer.frame_post_draw
	return root.get_texture().get_image()
func changes(a: Image, b: Image, bounds: Rect2) -> Vector2i:
	var result := Vector2i.ZERO
	for y: int in range(a.get_height()):
		for x: int in range(a.get_width()):
			if a.get_pixel(x,y) != b.get_pixel(x,y):
				if bounds.has_point(Vector2(x,y)): result.x += 1
				else: result.y += 1
	return result
func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("History pixel test requires a supported actual renderer"); quit(2); return
	root.size = Vector2i(390,844)
	view = SCENE.instantiate(); root.add_child(view)
	await process_frame
	view.set_process(false)
	view.model.seek(1.2); view.model.open_folder()
	view.stage.folder_open_amount = 1
	view.stage.history_time = 3.8; view._refresh()
	var before: Dictionary = view.model.snapshot()
	var a: Image = await settled_image()
	view.stage.history_time = 4.8; view._refresh()
	var b: Image = await settled_image()
	var bounds: Rect2 = view.stage.history_window.get_global_rect().grow(2)
	var delta := changes(a,b,bounds)
	check(delta.y == 0,"Changing only recorded time changes zero pixels outside the past window")
	check(delta.x > 100,"Past window visibly contains moving recorded paper, not an empty rectangle")
	check(view.model.snapshot() == before,"Recorded pixels cannot mutate the current paper or folder")
	check(view.stage.paper_grip.get_global_rect().get_center().distance_to(view.stage.global_position+view.stage.world_to_local(view.model.paper_position())) < 0.01,"Visible current paper and its ordinary-input target share one position")
	# Demonstrate that the pixel boundary assertion catches the old clipping bug.
	view.stage.history_window.clip_contents = false
	view.stage.history_time = 3.8; view._refresh()
	var unbounded: Image = await settled_image()
	check(changes(b,unbounded,bounds).y > 100,"Negative control detects unbounded recorded child drawing")
	view.stage.history_window.clip_contents = true
	view.queue_free(); await process_frame
	print("PAPER_HISTORY_RENDER failures=",failures," renderer=",DisplayServer.get_name())
	quit(1 if failures else 0)
