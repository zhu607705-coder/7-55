extends SceneTree
const SCENE = preload("res://scenes/library_time.tscn")
const Events = preload("res://kit/capture_inputs.gd")
var events := Events.new()
var view: Control
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	if not ok: failures+=1; push_error("TEST FAILED: "+label)
	else: print("PASS ",label)
func run() -> void:
	if OS.get_cmdline_user_args().has("--require-rendering") and (DisplayServer.get_name()=="headless" or RenderingServer.get_video_adapter_name().is_empty()): quit(2); return
	print("LIBRARY_RENDERER ",DisplayServer.get_name()," ",RenderingServer.get_video_adapter_name())
	root.size=Vector2i(390,844); view=SCENE.instantiate(); root.add_child(view)
	await process_frame; await physics_frame; await process_frame
	var a: Vector2=view.history_rects[0].position+Vector2(50,190)
	var b: Vector2=view.history_rects[1].position+Vector2(90,190)
	var book := Vector2.ZERO
	for frame: int in range(600):
		if frame==30: events.touch(0,a,true)
		if frame==45: events.touch(1,b,true)
		if frame==46: check(view.model.input.owners.size()==2,"two hands own separate historical windows")
		if frame>45 and frame<=115:
			events.drag(0,a+Vector2(-6,-8)*float(frame-45)/70)
			events.drag(1,b+Vector2(24,-118)*float(frame-45)/70)
		if frame==116: events.touch(0,events.last[0],false); events.touch(1,events.last[1],false)
		if frame==150:
			print("WINDOW_VISIBILITY ",view.last_visibility," windows=",view.history_rects)
			check(view.last_visibility==[true,true],"both complementary fragments are actually visible at fixed shelf corner")
			check(not view.model.completed,"comparison alone never takes a book")
		if frame==185: book=view.book_point(3); events.touch(2,book,true)
		if frame>185 and frame<=230: events.drag(2,book+Vector2(0,72)*float(frame-185)/45)
		if frame==231: events.touch(2,events.last[2],false)
		if frame==260: check(not view.model.completed and view.model.rejected_count==1,"same upper glyph but wrong lower glyph returns without consuming book")
		if frame==300: book=view.book_point(4); events.touch(3,book,true)
		if frame>300 and frame<=360: events.drag(3,book+Vector2(0,76)*float(frame-300)/60)
		if frame==361: events.touch(3,events.last[3],false)
		if frame==420:
			check(view.model.completed and view.model.completion_count==1,"direct retrieval of combined matching spine completes locally once")
			check(view.current_world.books.size()==6,"books are not destroyed or consumed")
		await process_frame
	print("LIBRARY_VIDEO frames=600 fps=30 automated_two_touch=true physical_phone=false failures=",failures)
	view.queue_free(); await process_frame; quit(1 if failures else 0)
