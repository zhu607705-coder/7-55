extends SceneTree
var frame: int=0
var shell: Control
var view: Control
func _initialize() -> void:run.call_deferred()
func run() -> void:
	root.size=Vector2i(1280,720)
	shell=load("res://scenes/rain_rescue_preview.tscn").instantiate()
	root.add_child(shell)
	view=shell.get_node("Presentation")
	view.capture_mode=true
func _process(_dt: float) -> bool:
	if view==null:return false
	frame+=1
	if frame in [30,69,91,122,164,225,266,287,319,358,402,450]:capture_frame.call_deferred(frame)
	if frame>=480:
		print("RESCUE_NATIVE_CAPTURE ",JSON.stringify({"frames":frame,"phase":view.timeline.pose().phase,"time":view.timeline.elapsed,"callback_count":view.callback_count,"story_state_access":false,"layers":"native","footprints":view.footprints.size()}))
		quit()
	return false
func capture_frame(n: int) -> void:
	await RenderingServer.frame_post_draw
	var output: String=OS.get_environment("RESCUE_CAPTURE_DIR")
	if not output.is_empty():root.get_texture().get_image().save_png(output+"/rescue-%03d.png" % n)
