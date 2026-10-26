extends SceneTree
const SCENE = preload("res://scenes/raking_light.tscn")
var view: Control
var failures := 0
var last: Dictionary={}
func _initialize() -> void: call_deferred("run")
func touch(id: int, p: Vector2, pressed: bool) -> void:
	var e := InputEventScreenTouch.new(); e.index=id; e.position=p; e.pressed=pressed; Input.parse_input_event(e); last[id]=p
func drag(id: int, p: Vector2) -> void:
	var e := InputEventScreenDrag.new(); e.index=id; e.position=p; e.relative=p-last[id]; Input.parse_input_event(e); last[id]=p
func check(ok: bool, label: String) -> void:
	if not ok: failures+=1; push_error("TEST FAILED: "+label)
	else: print("PASS ",label)
func run() -> void:
	if OS.get_cmdline_user_args().has("--require-rendering") and (DisplayServer.get_name()=="headless" or RenderingServer.get_video_adapter_name().is_empty()): quit(2); return
	print("RAKING_RENDERER ",DisplayServer.get_name()," ",RenderingServer.get_video_adapter_name())
	root.size=Vector2i(390,844); view=SCENE.instantiate(); root.add_child(view)
	await process_frame; await process_frame
	var paper := Vector2.ZERO; var shade := Vector2.ZERO
	for frame: int in range(510):
		if frame==30:
			paper=view.paper_hit_point(); touch(0,paper,true)
		if frame>30 and frame<=100: drag(0,paper+Vector2(-38,-56)*float(frame-30)/70.0)
		if frame==110:
			shade=view.lamp_hit_point(); touch(1,shade,true)
		if frame==111:
			check(view.model.owners.get(0)=="paper" and view.model.owners.get(1)=="lamp","two physical objects retain separate touch owners")
		if frame>110 and frame<=230: drag(1,shade+Vector2(-140,124)*float(frame-110)/120.0)
		if frame==235: touch(0,last[0],false); touch(1,last[1],false)
		if frame==300:
			print("RAKING_POSE ",view.model.paper_tilt," ",view.model.lamp_azimuth," ",view.model.lamp_elevation," metrics=",view.metrics)
			check(view.model.completed,"actual grazing geometry plus stable observation opens local preview")
		if frame==350: check(view.current_world.door_hinge.rotation.y < -1.0,"visible preview door opens without formal story transition")
		await process_frame
	check(view.model.completion_count==1,"one local completion only")
	print("RAKING_VIDEO frames=510 fps=30 automated_two_touch=true physical_phone=false failures=",failures)
	view.queue_free(); await process_frame; quit(1 if failures else 0)
