extends SceneTree
## Ordinary two-touch input recording. Run with Godot Movie Maker in a supported
## graphical environment. This is automated input, not physical-phone evidence.
const SCENE = preload("res://scenes/paper_rewind.tscn")
const Model = preload("res://scripts/paper_rewind_model.gd")
var view: Control
var overlay: Control
var markers: Dictionary = {}
var current_frame := 0
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
	else:
		print("CAPTURE_PASS ", message)

func touch(id: int, point: Vector2, down: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = id
	event.position = point
	event.pressed = down
	Input.parse_input_event(event)
	markers[id] = {"point":point,"until":99999 if down else current_frame + 10}

func drag(id: int, from: Vector2, point: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = id
	event.position = point
	event.relative = point - from
	Input.parse_input_event(event)
	markers[id] = {"point":point,"until":99999}

func paper_point(at_time: float) -> Vector2:
	return view.stage.global_position + view.stage.world_to_local(Model.free_position(at_time))

func _run() -> void:
	if OS.get_cmdline_user_args().has("--require-rendering"):
		if DisplayServer.get_name() == "headless" or RenderingServer.get_video_adapter_name().is_empty():
			push_error("Actual graphical renderer required for movie capture")
			quit(2)
			return
		print("PAPER_REWIND_RENDERER display=", DisplayServer.get_name(), " adapter=", RenderingServer.get_video_adapter_name())
	root.size = Vector2i(390,844)
	view = SCENE.instantiate()
	root.add_child(view)
	await process_frame
	await process_frame
	overlay = Control.new()
	overlay.name = "AutomatedTouchDemonstrationOverlay"
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.z_index = 1000
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.draw.connect(_draw_overlay)
	root.add_child(overlay)
	var history_start: Vector2 = view.stage.history_window.get_global_rect().get_center()
	var history_end := history_start + Vector2(-135,30)
	var last_history := history_start
	var last_paper := Vector2.ZERO
	var folder := Vector2.ZERO
	for frame: int in range(720):
		current_frame = frame
		if frame == 45: touch(1,history_start,true)
		if frame > 45 and frame <= 90:
			var p := history_start.lerp(history_end,float(frame - 45)/45.0)
			drag(1,last_history,p); last_history = p
		if frame == 100: touch(1,history_end,false)
		if frame == 150: touch(1,history_end,true)
		if frame > 150 and frame <= 195:
			var p := history_end.lerp(history_start,float(frame - 150)/45.0)
			drag(1,last_history,p); last_history = p
		if frame == 205: touch(1,history_start,false)
		if frame == 235:
			last_paper = view.stage.paper_grip.get_global_rect().get_center()
			touch(0,last_paper,true)
		if frame > 235 and frame <= 280:
			var at_time := lerpf(Model.ENTRY_TIME,2.5,float(frame - 235)/45.0)
			var p := paper_point(at_time)
			drag(0,last_paper,p); last_paper = p
		if frame == 295:
			folder = view.stage.folder_button.get_global_rect().get_center()
			touch(1,folder,true)
		if frame == 315:
			touch(1,folder,false)
		if frame == 316:
			check(view.model.folder_open and view.stage.paper_grip.held,"Right folder opens while left paper stays captured")
		if frame > 330 and frame <= 375:
			var at_time := lerpf(2.5,0.8,float(frame - 330)/45.0)
			var p := paper_point(at_time)
			drag(0,last_paper,p); last_paper = p
		if frame == 390:
			touch(0,last_paper,false)
		if frame == 391:
			check(view.model.mode == "forward" and view.model.folder_open,"Releasing owner resumes with environment retained")
		if frame == 565:
			check(view.model.mode == "landed" and view.model.completion_count == 0,"Real catch lands before explicit collection")
		if frame == 585:
			last_paper = view.stage.paper_grip.get_global_rect().get_center()
			touch(0,last_paper,true)
		if frame == 595:
			touch(0,last_paper,false)
		if frame == 596:
			check(view.model.mode == "solved" and view.model.paper_collected,"Explicit paper tap collects once")
		overlay.queue_redraw()
		await process_frame
	check(view.model.completion_count == 1,"Recording completed exactly one local collection")
	print("PAPER_REWIND_VIDEO frames=720 fps=30 portrait=390x844 automated_input=true physical_mobile=false failures=",failures)
	view.queue_free(); overlay.queue_free()
	await process_frame
	quit(1 if failures else 0)

func _draw_overlay() -> void:
	var font: Font = view.theme.default_font
	for id: int in markers:
		var marker: Dictionary = markers[id]
		if current_frame > marker.until:
			continue
		var color := Color("9bd8d2") if id == 0 else Color("efc784")
		overlay.draw_circle(marker.point,18,Color(color,0.18))
		overlay.draw_arc(marker.point,18,0,TAU,40,color,2.0,true)
		overlay.draw_string(font,marker.point + Vector2(-4,6),str(id + 1),HORIZONTAL_ALIGNMENT_LEFT,-1,18,color)
	var bottom := float(root.size.y)
	overlay.draw_string(font,Vector2(12,bottom - 12),"自动双触点 · 非物理手机",HORIZONTAL_ALIGNMENT_LEFT,root.size.x - 24,12,Color("d3ded4"))
