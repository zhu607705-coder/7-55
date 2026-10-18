extends SceneTree
## Layout-only automated captures; not gameplay evidence or performance measurement.
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var view=load("res://scenes/qizhen_playable_chase.tscn").instantiate()
	root.add_child(view)
	for dimensions: Vector2i in [Vector2i(1180,812),Vector2i(640,360),Vector2i(390,844)]:
		root.size=dimensions
		view.restart(true)
		await create_timer(.3).timeout
		await RenderingServer.frame_post_draw
		var out: String=OS.get_environment("CHASE_LAYOUT_DIR")
		if not out.is_empty():root.get_texture().get_image().save_png(out+"/playable-%sx%s.png"%[root.size.x,root.size.y])
	quit()
