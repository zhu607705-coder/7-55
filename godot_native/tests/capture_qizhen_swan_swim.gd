extends SceneTree
var view: Control
var frames: int=0
func _initialize() -> void:run.call_deferred()
func run() -> void:
	root.size=Vector2i(1280,720)
	view=load("res://scenes/qizhen_swan_swim_study.tscn").instantiate()
	view.capture_mode=true
	root.add_child(view)
func _process(_dt: float) -> bool:
	if view==null:return false
	frames+=1
	if frames in [75,168,262]:capture_frame.call_deferred(frames)
	if frames>=360:
		print("SWAN_SWIM_CAPTURE ",JSON.stringify({"frames":frames,"wake_count":view.visual.emitted,"final_position":[view.point.x,view.point.y],"no_story_writes":true}))
		quit()
	return false
func capture_frame(number: int) -> void:
	await RenderingServer.frame_post_draw
	var output: String=OS.get_environment("SWAN_CAPTURE_DIR")
	if not output.is_empty():root.get_texture().get_image().save_png(output+"/swim-%03d.png"%number)
