extends SceneTree
const SCENE=preload("res://scenes/raking_light.tscn")
var view: Control
var checks:=0
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if ok: print("PASS ",label)
	else: failures+=1; push_error("TEST FAILED: "+label)
func frames(n: int=2) -> void:
	for i: int in range(n): await process_frame
func touch(id: int,p: Vector2,down: bool) -> void:
	var e:=InputEventScreenTouch.new(); e.index=id; e.position=p; e.pressed=down
	Input.parse_input_event(e); await frames()
func drag(id: int,a: Vector2,b: Vector2) -> void:
	var e:=InputEventScreenDrag.new(); e.index=id; e.position=b; e.relative=b-a
	Input.parse_input_event(e); await frames(); view._process(0)
func snapshot(label: String) -> void:
	var folder:=OS.get_environment("RAKING_RENDER_ARTIFACT_DIR")
	if folder.is_empty() or DisplayServer.get_name()=="headless": return
	await frames(3); await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(folder)
	check(root.get_texture().get_image().save_png(folder+"/"+label+".png")==OK,"Save real GL "+label)
func reset() -> void:
	view.model.reset(); view.pointer_positions.clear(); view._close_menu(); view.history_offset=Vector2.ZERO; view._layout(); view._process(0); await frames()
func run() -> void:
	print("RAKING_REACHABILITY_RENDERER ",DisplayServer.get_name()," ",RenderingServer.get_video_adapter_name())
	root.size=Vector2i(844,390); view=SCENE.instantiate(); root.add_child(view); await frames(5); view.set_process(false); view._process(0)
	await snapshot("landscape-entry")
	var paper: Vector2=view.paper_hit_point(); var lamp: Vector2=view.lamp_hit_point()
	await touch(0,paper,true); await touch(1,lamp,true)
	check(view.model.owners.get(0)=="paper" and view.model.owners.get(1)=="lamp","Landscape starts with independent real touch owners")
	var scale: float=view.current_rect.size.x/390.0
	var paper_end: Vector2=paper+Vector2(112.5,-112.5)*scale
	var lamp_end: Vector2=lamp+Vector2(-315,80)*scale
	await drag(0,paper,paper_end); await drag(1,lamp,lamp_end)
	await touch(0,paper_end,false); await touch(1,lamp_end,false); view._process(0)
	check(view.model.paper_tilt.distance_to(Vector2(18,18))<0.001 and absf(view.model.lamp_azimuth+98)<0.001 and absf(view.model.lamp_elevation-40)<0.001,"Ordinary two-hand drag reaches the previously lost landscape grip pose")
	lamp=view.lamp_hit_point()
	print("RAKING_REGRAB grip=",lamp," camera_size=",view.current_world.camera.size)
	check(view.current_rect.grow(-34.9).has_point(lamp) and view._target(lamp)=="lamp","Released extreme lamp stays inside the pane with a full grab margin")
	await snapshot("landscape-extreme-released")
	await touch(2,lamp,true)
	check(view.model.owners.get(2)=="lamp","A new ordinary touch reacquires the released extreme lamp")
	await snapshot("landscape-extreme-regrab")
	await drag(2,lamp,lamp+Vector2(10,8)); await touch(2,lamp+Vector2(10,8),false)
	check(view.model.lamp_azimuth>-98 and view.model.lamp_elevation<40,"Reacquired lamp remains adjustable without resetting paper")
	# Resize while holding the actual grip: stale geometry must be cancelled.
	lamp=view.lamp_hit_point(); await touch(3,lamp,true)
	var arrangement: Array=[view.model.paper_tilt,view.model.lamp_azimuth,view.model.lamp_elevation]
	root.size=Vector2i(390,844); await frames(5)
	check(view.model.suspended and view.model.owners.is_empty() and view.pointer_positions.is_empty(),"Extreme-pose resize releases the old touch and pauses observation")
	await touch(3,lamp,false)
	var resume_point: Vector2=view.resume.get_global_rect().get_center()
	await touch(4,resume_point,true); await touch(4,resume_point,false); view._process(0)
	check(not view.model.suspended and arrangement==[view.model.paper_tilt,view.model.lamp_azimuth,view.model.lamp_elevation],"Ordinary resume preserves the extreme physical arrangement")
	lamp=view.lamp_hit_point(); await touch(5,lamp,true)
	check(view.model.owners.get(5)=="lamp","New portrait coordinates reacquire the same lamp after resize")
	await touch(5,lamp,false); await snapshot("portrait-extreme-after-resize")
	# Camera fit uses analytic extrema. This grid independently checks every
	# angle boundary, interior orbit extrema and all supported aspect classes.
	var azimuths: Array=[]
	for az: int in range(-145,146,10): azimuths.append(float(az))
	azimuths.append_array([-98.0,-8.0,82.0,145.0])
	var elevations: Array=[]
	for el: int in range(8,83,6): elevations.append(float(el))
	elevations.append_array([40.0,82.0])
	for dimensions: Vector2i in [Vector2i(320,568),Vector2i(390,844),Vector2i(844,390),Vector2i(1100,760)]:
		root.size=dimensions; await frames(5); await reset()
		var transform: Transform3D=view.current_world.camera.transform
		var camera_size: float=view.current_world.camera.size
		var safe: Rect2=view.current_rect.grow(-34.9)
		var outside:=0; var samples:=0
		for x: float in [-18.0,0.0,18.0]:
			for z: float in [-18.0,0.0,18.0]:
				for az: float in azimuths:
					for el: float in elevations:
						view.current_world.update_scene(Vector2(x,z),az,el,0,false)
						samples+=1
						if not safe.has_point(view.lamp_hit_point()): outside+=1
		check(outside==0,"All "+str(samples)+" lamp poses retain a 35px viewport margin at "+str(dimensions))
		check(view.current_world.camera.transform==transform and view.current_world.camera.size==camera_size,"Camera remains static throughout the movement envelope at "+str(dimensions))
		var back: Vector3=view.current_world.camera.global_basis.z
		check(absf(rad_to_deg(asin(back.y))-50)<0.001 and absf(rad_to_deg(atan2(back.x,back.z))-8)<0.001,"Envelope fitting preserves the 50 degree / 8 degree projection at "+str(dimensions))
	print("RAKING_REACHABILITY checks=",checks," failures=",failures," real_touch_events=true physical_phone=false")
	view.queue_free(); await frames(); quit(1 if failures else 0)
