extends SceneTree
## Short manual QA starting at a verified existing east-road point.
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	var campus = load("res://campuses/buct_changping/scenes/playable.tscn").instantiate()
	root.add_child(campus)
	current_scene = campus
	await process_frame;await physics_frame;await process_frame
	campus.visitor.position = Vector2(769,842)
	campus.zoom_level = 3.5
	campus._layout_ui()
	campus.camera.reset_smoothing()
	campus.status.text = "原生验收：沿东路移动，点击文理楼；Esc 关闭信息"
