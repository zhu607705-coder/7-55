extends SceneTree
## Actual continuous playback, started by a normal touchscreen Replay tap.
var endings: Array[String] = []

func _initialize() -> void: call_deferred("record")

func record() -> void:
	if DisplayServer.get_name() == "headless" or RenderingServer.get_video_adapter_name().is_empty():
		push_error("Movie evidence requires a real graphical renderer."); quit(2); return
	print("PHONE_CAMPUS_MOVIE_RENDERER display=", DisplayServer.get_name(), " adapter=", RenderingServer.get_video_adapter_name(), " method=", RenderingServer.get_current_rendering_method())
	var scene = load("res://transition.tscn").instantiate()
	scene.autoplay = false; root.add_child(scene)
	scene.ended.connect(func(reason: String): endings.append(reason))
	for i in 12: await process_frame
	var replay: Button = scene.find_children("*", "Button", true, false)[0]
	var point := replay.get_global_rect().get_center()
	for down in [true, false]:
		var event := InputEventScreenTouch.new()
		event.index = 0; event.position = point; event.pressed = down
		Input.parse_input_event(event)
		await process_frame
	if not scene.running: push_error("Ordinary Replay tap did not start playback."); quit(1); return
	for i in 336: await process_frame
	if endings != ["completed"] or scene.running or not is_equal_approx(scene.playhead, 10.2):
		push_error("Continuous timeline did not complete exactly once."); quit(1); return
	print("PHONE_CAMPUS_MOVIE failures=0 ordinary_touch_start=true continuous_playback=true physical_device=false frames=350")
	quit(0)
