extends SceneTree
var view: Control
var frames: int=0
func _initialize() -> void:run.call_deferred()
func run() -> void:
	root.size=Vector2i(1280,720)
	view=load("res://scenes/qizhen_swan_hop_study.tscn").instantiate();view.capture_mode=true;root.add_child(view)
func _process(_dt: float) -> bool:
	if view==null:return false
	frames+=1
	if frames in [42,54,68,78,89,97,104,119,140]:capture_frame.call_deferred(frames)
	if frames>=210:
		print("SWAN_HOP_CAPTURE ",JSON.stringify({"frames":frames,"seconds":7,"launch_count":view.timeline.launch_count,"landing_count":view.timeline.landing_count,"poses":16}))
		quit()
	return false
func capture_frame(number: int) -> void:
	await RenderingServer.frame_post_draw
	var output: String=OS.get_environment("SWAN_CAPTURE_DIR")
	if not output.is_empty():root.get_texture().get_image().save_png(output+"/hop-%03d.png"%number)
