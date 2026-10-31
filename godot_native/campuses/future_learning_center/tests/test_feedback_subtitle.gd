extends "res://campuses/future_learning_center/tests/test_object_input.gd"
const Subtitle = preload("res://campuses/future_learning_center/scripts/feedback_subtitle.gd")

func run() -> void:
	if not preload("res://tests/native_test_isolation.gd").is_isolated_save(): quit(2); return
	root.title = "7:55 · 统一提示字幕验收"
	RenderingServer.set_default_clear_color(Color("101820"))
	host = SubViewportContainer.new(); host.size = Vector2(960, 540); host.stretch = false; root.add_child(host)
	viewport = SubViewport.new(); viewport.size = Vector2i(960, 540); viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS; host.add_child(viewport)
	world = load("res://campuses/future_learning_center/scripts/floor_view.gd").new(); viewport.add_child(world)
	root.size_changed.connect(fit); fit(); root.grab_focus(); await process_frame; await process_frame
	var short_text := "纸片贴合了。留意窗口和锁轮上的图形。"
	var long_text := "窗口上的图形要与锁轮上的标记对应，再把对应的数字组合起来。".repeat(3)
	var baseline_images := {}
	for item: Array in [["locker", world.locker_cipher], ["coupling", world.coupling_tray], ["pantry", world.pantry_tray]]:
		var id: String = item[0]
		var view: Control = item[1]
		view.open()
		for sample: Array in [["short", short_text], ["long", long_text]]:
			var kind: String = sample[0]
			var content: String = sample[1]
			view.notice(content); await process_frame; await RenderingServer.frame_post_draw
			var metrics: Dictionary = Subtitle.layout(view.font, content)
			var panel: Rect2 = metrics.panel
			check(panel.position.y >= 0 and panel.end.y == Subtitle.BOTTOM and metrics.text_size.x <= Subtitle.TEXT_WIDTH + 1, id + " " + kind + " caption fits the playfield")
			if kind == "long": check(panel.size.y > 46 and view.feedback_seconds > 5.0, id + " long copy wraps and has more reading time")
			var caption: Image = viewport.get_texture().get_image().get_region(Rect2i(int(panel.position.x), int(panel.position.y), int(panel.size.x), int(panel.size.y)))
			if baseline_images.has(kind): check(caption.get_data() == baseline_images[kind], id + " " + kind + " renders identical caption pixels")
			else: baseline_images[kind] = caption.get_data()
			await capture(id + "_" + kind)
		if id != "locker":
			view.book_open = true; view.book_at = Vector2(710, 480); view.notice(long_text)
			await process_frame; await RenderingServer.frame_post_draw
			var metrics: Dictionary = Subtitle.layout(view.font, long_text)
			var panel: Rect2 = metrics.panel
			var caption: Image = viewport.get_texture().get_image().get_region(Rect2i(int(panel.position.x), int(panel.position.y), int(panel.size.x), int(panel.size.y)))
			check(caption.get_data() == baseline_images.long, id + " notebook cannot cover a visible subtitle")
			view.book_open = false
		view.feedback_seconds = .04; await create_timer(.12).timeout
		check(view.feedback_seconds <= 0, id + " caption expires without input")
		view.close()
	var failed: Array = results.filter(func(row: Dictionary) -> bool: return not row.passed)
	var folder := OS.get_environment("FLC_CAPTURE_DIR"); DirAccess.make_dir_recursive_absolute(folder)
	var file := FileAccess.open(folder.path_join("feedback_subtitle.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks": assertions, "failures": failed.size(), "results": results, "viewport": [root.size.x, root.size.y]}, "  ")); file.close()
	print("FLC_FEEDBACK_SUBTITLE: %d checks, %d failures" % [assertions, failed.size()])
	quit(1 if failed.size() else 0)
