extends SceneTree
var view: Control
var frames: int=0
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	root.size=Vector2i(1280,720)
	view=load("res://scenes/qizhen_swan_entrance_preview.tscn").instantiate()
	view.capture_demo=true
	root.add_child(view)
func _process(_dt: float) -> bool:
	if view==null:return false
	frames+=1
	if frames in [45,105,150,182,216,270,330]:
		capture_frame.call_deferred(frames)
	if frames>=360:
		print("SWAN_NATIVE_CAPTURE ",JSON.stringify({"frames":frames,"timeline":view.timeline.elapsed,"handed_back":view.handed_back,"stage":view.stage,"paddle_inputs":view.capture_input_count,"player":[view.kayak.position.x,view.kayak.position.y],"swan_valid":view.swan.spawn_valid}))
		quit()
	return false

func capture_frame(number: int) -> void:
	await RenderingServer.frame_post_draw
	var output: String=OS.get_environment("SWAN_CAPTURE_DIR")
	if not output.is_empty(): root.get_texture().get_image().save_png(output+"/swan-%03d.png" % number)
