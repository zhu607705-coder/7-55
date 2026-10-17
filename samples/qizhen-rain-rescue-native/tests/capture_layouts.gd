extends SceneTree
func _initialize() -> void:run.call_deferred()
func run() -> void:
	var shell: Control=load("res://scenes/rain_rescue_preview.tscn").instantiate()
	root.add_child(shell)
	var view: Control=shell.get_node("Presentation")
	view.capture_mode=true;view.timeline.paused=true
	var output: String=OS.get_environment("RESCUE_CAPTURE_DIR")
	for entry: Dictionary in [
		{"size":Vector2i(1280,720),"time":9.35,"name":"rescue-contact-final"},
		{"size":Vector2i(1280,720),"time":14.2,"name":"rescue-wet-steps-final"},
		{"size":Vector2i(390,844),"time":9.35,"name":"rescue-portrait-contact"},
		{"size":Vector2i(390,844),"time":15.0,"name":"rescue-portrait-safe"},
		{"size":Vector2i(960,600),"time":15.0,"name":"rescue-non169"}]:
		root.size=entry.size
		await process_frame;await process_frame
		view.timeline.elapsed=entry.time;view.wet_time=entry.time
		view.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(output+"/"+entry.name+".png")
	print("RESCUE_LAYOUT_CAPTURE: five native viewport captures")
	quit()
