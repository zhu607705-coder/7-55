extends SceneTree
## Optional native graphics evidence fixture. Start once at an existing west-lane junction,
## then traverse both branches continuously using the unchanged real visitor at 88 px/s.
## No per-shot pose jumps, fake camera movement, changed physics, or building transforms.
var app: Node2D
var targets: Array[Vector2]=[Vector2(416,436),Vector2(422,748),Vector2(613,711),Vector2(612,416)]
var index := 0
var ticks := 0
var violations := 0
var frame_count := 0
var output := ""
var report := {"schema":"buct-chaoyang-continuous-walk-v1","arrivals":[],"frame_samples":[],"speed":88.0,"frame_format":"JPEG","frame_quality":0.90}
func _init() -> void: call_deferred("run")
func run() -> void:
	output=OS.get_environment("BUCT_WALK_CAPTURE_DIR")
	if DisplayServer.get_name()=="headless" or not output.is_absolute_path():push_error("A real renderer and absolute BUCT_WALK_CAPTURE_DIR are required");quit(2);return
	DirAccess.make_dir_recursive_absolute(output)
	app=load("res://campuses/buct/scenes/playable.tscn").instantiate();root.add_child(app)
	for i in range(5):await process_frame
	app.return_to_gate();app.visitor.position=Vector2(422,748)
	app.status.text="西侧运动区边路 → 原连接步道 → 图书馆西路"
	app.camera.position=app._walking_camera_position();app.camera.reset_smoothing()
	app.path_to(targets[0])
	var start_usec := Time.get_ticks_usec()
	var start_physics_frame := Engine.get_physics_frames()
	while index<targets.size() and ticks<1500:
		await physics_frame;ticks+=1
		if not app.is_walkable(app.visitor.position):violations+=1
		if app.visitor.position.distance_to(targets[index])<=6.0:
			report.arrivals.append({"target":[targets[index].x,targets[index].y],"physics_tick":ticks,"actual_feet":[app.visitor.position.x,app.visitor.position.y]})
			index+=1
			if index<targets.size():app.path_to(targets[index])
		if ticks%3==0:
			await RenderingServer.frame_post_draw
			var save_error := root.get_texture().get_image().save_jpg(output.path_join("walk-%04d.jpg"%frame_count),0.90)
			if save_error!=OK:report["save_error"]=save_error;break
			report.frame_samples.append({"frame":frame_count,"elapsed_usec":Time.get_ticks_usec()-start_usec,"physics_frame":Engine.get_physics_frames()-start_physics_frame,"feet":[app.visitor.position.x,app.visitor.position.y],"walking":app.visitor.walking,"direction":app.visitor.character_visual.facing})
			frame_count+=1
	report["elapsed_usec"]=Time.get_ticks_usec()-start_usec;report["actual_physics_frames"]=Engine.get_physics_frames()-start_physics_frame;report["physics_ticks"]=ticks;report["frames"]=frame_count;report["paving_violations"]=violations;report["completed"]=index==targets.size()
	report["limit"]="One initial placement at the already-open west-lane junction; thereafter continuous native movement. Only the authored two-branch road sector is shown."
	var file:=FileAccess.open(output.path_join("continuous-walk.json"),FileAccess.WRITE)
	if file:file.store_string(JSON.stringify(report,"\t")+"\n")
	print("BUCT_CHAOYANG_CAPTURE complete=",index==targets.size()," ticks=",ticks," violations=",violations," frames=",frame_count)
	app.queue_free();await process_frame
	quit(0 if index==targets.size() and violations==0 else 1)
