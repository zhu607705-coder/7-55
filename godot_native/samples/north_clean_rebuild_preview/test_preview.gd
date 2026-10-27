extends SceneTree

var failures := 0
var checks := 0

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func _initialize() -> void:
	await process_frame
	var view: Control = load("res://preview.tscn").instantiate()
	root.add_child(view)
	await process_frame
	check(view.selected_floor == "a3" and view.mode == "empty", "Open with the A3 empty plate")
	check(view.textures["a3_empty"].get_size() == Vector2(1672, 941), "A3 keeps the source canvas size")
	var seen := {}
	var counts := {}
	for row: Dictionary in view.placements.a3:
		check(not seen.has(row.id), "Each A3 placement has its own identity: " + row.id)
		seen[row.id] = true
		check(view.textures.get(row.texture) != null, "Every A3 placement resolves its texture: " + row.id)
		counts[row.texture] = int(counts.get(row.texture, 0)) + 1
	check(counts.get("a3_report_seat") == 44, "Report hall retains its 44 seats")
	check(counts.get("a3_class_desk") == 24 and counts.get("a3_class_chair") == 24, "Classroom retains 24 desks and 24 separate chairs")
	check(counts.get("portrait_zhu_kezhen") == 1 and counts.get("a3_frame") >= 6, "Existing Zhu portrait and frames are separate assets")
	# These regions are the visible beige wall faces in the empty plate, above the wall foot.
	# A picture must remain inside them after texture fitting, not only in its layout box.
	var honor_wall := Rect2(735, 568, 205, 57)
	var hall_wall := Rect2(590, 73, 97, 60)
	for id: String in ["su_buqing", "zhu_kezhen", "lu_yongxiang", "chen_jiangong", "tan_jiazhen", "cheng_kaijia"]:
		var frame_row: Dictionary = view.placements.a3.filter(func(row): return row.id == "frame_" + id)[0]
		var portrait_row: Dictionary = view.placements.a3.filter(func(row): return row.id == "portrait_" + id)[0]
		var fitted_frame: Rect2 = view._fitted_rect(frame_row)
		var wall: Rect2 = honor_wall if id in ["su_buqing", "zhu_kezhen", "lu_yongxiang"] else hall_wall
		check(wall.encloses(fitted_frame), "Portrait frame stays above the wall foot: " + id)
		check(fitted_frame.encloses(view._fitted_rect(portrait_row)), "Portrait remains inside its mounted frame: " + id)
	var desk_row: Dictionary = view.placements.a3.filter(func(row): return row.id == "a3_media_control_desk")[0]
	var desk: Rect2 = view._fitted_rect(desk_row)
	check(desk.size.y >= 70.0, "The control desk keeps its visible depth")
	for index: int in range(3):
		var monitor_row: Dictionary = view.placements.a3.filter(func(row): return row.id == "studio_monitor_%d" % index)[0]
		var monitor: Rect2 = view._fitted_rect(monitor_row)
		check(monitor.size.x >= (60.0 if index == 1 else 45.0), "Editing monitor keeps a readable desk-scale footprint")
		check(desk.has_point(Vector2(monitor.get_center().x, monitor.end.y - 1.0)), "Editing monitor stand rests on the desk")
	check(counts.get("a3_studio_right_camera") == 1 and counts.get("a3_av_rack_wide") == 3, "Restore the right camera and three separate AV cabinets")
	var frame: Image = view.textures.a3_frame.get_image()
	check(frame.get_pixel(frame.get_width() / 2, frame.get_height() / 2).a < 0.05, "Portrait frame centre is transparent")
	var trim: Dictionary = view.placements.a3.filter(func(row): return row.id == "honor_floor_trim")[0]
	check(not view._object_contains_point(trim, view._fitted_rect(trim).get_center()), "Transparent floor trim interior does not capture clicks")
	view._select_mode("objects")
	view.board_rect = Rect2(0, 0, 1672, 941)
	view.board_scale = 1.0
	var chosen: Dictionary = view.placements.a3.filter(func(row): return row.id == "a3_report_seat_0_0_0")[0]
	var at: Vector2 = view._fitted_rect(chosen).get_center()
	var press := InputEventScreenTouch.new()
	press.pressed = true
	press.position = at
	view.board_input(view.board, press)
	var release := InputEventScreenTouch.new()
	release.pressed = false
	release.position = at
	view.board_input(view.board, release)
	check(view.hidden_objects.has(chosen.id), "Touch hides the selected seat only")
	view.board_input(view.board, press)
	view.board_input(view.board, release)
	check(view.hidden_objects.has(chosen.id), "A hidden object does not block a second click")
	view._reset_objects()
	check(view.hidden_objects.is_empty(), "Reset restores individual objects")
	view._change_zoom(1.5)
	check(is_equal_approx(view.zoom_factor, 1.5), "Zoom increases uniformly")
	view._reset_view()
	check(is_equal_approx(view.zoom_factor, 1.0), "Full view resets zoom")
	view.queue_free()
	await process_frame
	print("A3 art review: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
