extends SceneTree
## Eleven-second native movie: actual independent body and actual route walking.
var campus: Node2D
var records: Array = []
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	campus = load("res://campuses/buct_changping/scenes/playable.tscn").instantiate()
	root.add_child(campus)
	await process_frame;await physics_frame;await process_frame
	campus.set_process(false)
	campus.pin_layer.hide()
	campus.camera.position_smoothing_enabled = false
	campus.camera.position = Vector2(710,791)
	campus.camera.zoom = Vector2.ONE*4.4
	campus.camera.reset_smoothing()
	campus.visitor.position = Vector2(769,842)
	campus.path_to(Vector2(764,765))
	campus.wenli_layer.update_actor_foot(842,true)
	var banner := Label.new()
	banner.text = "文理楼 · 独立外观"
	banner.add_theme_font_override("font",campus.font)
	banner.add_theme_font_size_override("font_size",22)
	banner.add_theme_color_override("font_color",Color(0.99,0.97,0.88))
	banner.add_theme_color_override("font_shadow_color",Color(0.12,0.16,0.12,0.9))
	banner.add_theme_constant_override("shadow_offset_x",1)
	banner.add_theme_constant_override("shadow_offset_y",1)
	banner.position = Vector2(20,84)
	campus.ui.add_child(banner)
	for frame_index in range(220):
		if frame_index == 40:
			campus._pointer_pressed(campus.get_canvas_transform()*Vector2(707,751))
			banner.text = "点击屋顶 · 文理楼"
		if frame_index == 85:
			campus.close_info()
			campus.path_to(Vector2(769,842))
			banner.text = "沿既有东侧步道返回"
		if frame_index == 160:
			campus.wenli_layer.hide()
			banner.text = "隐藏楼体 · 下方是推定补底"
		if frame_index == 195:
			campus.wenli_layer.show()
			banner.text = "文理楼 · 已复位"
		campus.wenli_layer.update_actor_foot(campus.visitor.position.y)
		if frame_index % 10 == 0:
			records.append({"frame":frame_index,"feet_x":campus.visitor.position.x,"feet_y":campus.visitor.position.y,"walkable":campus.is_walkable(campus.visitor.position),"building_visible":campus.wenli_layer.visible,"info_id":campus.info_id})
		await process_frame
	var out := OS.get_environment("BUCT_WENLI_PROOF_DIR")
	var file := FileAccess.open(out.path_join("preview-native-trace.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"status":"automated_native_preview","fixed_fps":20,"planned_frames":220,"samples":records},"\t"));file = null
	campus.queue_free();await process_frame
	quit()
