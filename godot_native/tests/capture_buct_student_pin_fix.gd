extends SceneTree
## Two real-scene stills at the reported label-overlap positions. No altered artwork or UI hiding.
const LAYOUT=preload("res://campuses/buct_shared/student/scripts/landmark_pin_layout.gd")
func _init() -> void:call_deferred("run")
func run() -> void:
	var output:=OS.get_environment("BUCT_STUDENT_PIN_PROOF_DIR")
	if DisplayServer.get_name()=="headless" or not output.is_absolute_path():quit(2);return
	DirAccess.make_dir_recursive_absolute(output);root.size=Vector2i(1280,800)
	var failures:=0
	for campus: String in ["buct","buct_haidian"]:
		var app=load("res://campuses/"+campus+"/scenes/playable.tscn").instantiate();root.add_child(app);await physics_frame
		app.visitor.set_physics_process(false);app.visitor.position=Vector2(752,815) if campus=="buct" else Vector2(762,402)
		app.camera.position=app._walking_camera_position();app.camera.reset_smoothing();app.camera.force_update_scroll()
		for i in range(5):await process_frame;await RenderingServer.frame_post_draw
		var body: Rect2=LAYOUT.student_screen_bounds(app.visitor)
		for pin in app.pins:
			if pin.visible and Rect2(pin.position,pin.size).intersects(body):failures+=1
		root.get_texture().get_image().save_png(output.path_join(campus+"-student-visible-landmark.png"))
		print("PIN_FIX_CAPTURE ",campus," actual_foot=",app.visitor.position," failures=",failures)
		app.queue_free();await process_frame;await process_frame
	quit(0 if failures==0 else 1)
