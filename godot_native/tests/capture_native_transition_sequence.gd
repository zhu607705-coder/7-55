extends SceneTree
## Full original frame-domain render coverage, one stage per owned process.
## This is an isolated stepped presentation fixture, not an earned playthrough.
const Presenter=preload("res://scripts/presentation/chase_transition_3d_presenter.gd")
func _initialize() -> void:run.call_deferred()
func inspect_pixels(image: Image) -> Dictionary:
	var sum:=Vector3.ZERO;var square:=Vector3.ZERO;var count: int=0;var finite: bool=true
	for y: int in range(0,image.get_height(),8):
		for x: int in range(0,image.get_width(),8):
			var color: Color=image.get_pixel(x,y);var value:=Vector3(color.r,color.g,color.b)
			finite=finite and is_finite(color.r) and is_finite(color.g) and is_finite(color.b)
			sum+=value;square+=value*value;count+=1
	var mean: Vector3=sum/maxi(1,count);var variance: Vector3=square/maxi(1,count)-mean*mean
	return {"samples":count,"finite":finite,"variance":variance.x+variance.y+variance.z,"sha256":hash_pixels(image)}
func hash_pixels(image: Image) -> String:
	var digest:=HashingContext.new();digest.start(HashingContext.HASH_SHA256);digest.update(image.get_data());return digest.finish().hex_encode()
func run() -> void:
	if DisplayServer.get_name()=="headless":push_error("A native GPU viewport is required");quit(2);return
	root.get_node("State").developer_mode=true
	var stage: String="start"
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--stage="):stage=arg.get_slice("=",1)
	if stage not in ["start","finish"]:quit(2);return
	var output: String=OS.get_environment("CHASE_TRANSITION_CAPTURE_DIR")
	if output.is_empty():push_error("Explicit isolated output directory required");quit(2);return
	DirAccess.make_dir_recursive_absolute(output)
	DisplayServer.window_set_size(Vector2i(960,676));root.size=Vector2i(960,676)
	var view=Presenter.new();root.add_child(view);view.size=Vector2(960,676);view.manual_clock=true
	view.configure_activity_layout(Vector2(960,676),false)
	view.play(stage)
	view.caption.text+="  [独立原作帧序列验证]"
	var records: Array=[];var errors: Array=[]
	for frame: int in range(view.last_frame()+1):
		view.frame=frame;view.elapsed=float(frame)/24;view._redraw()
		await process_frame;await RenderingServer.frame_post_draw
		var film: Image=view.view3d.get_texture().get_image()
		var record: Dictionary=inspect_pixels(film)
		record["frame"]=frame;record["camera"]=view.source_manifest.stages[stage][frame].camera
		if film.get_size()!=Vector2i(960,540) or not record.finite or record.variance<.00005:errors.append(frame)
		var error: Error=root.get_texture().get_image().save_png(output+"/"+stage+"-%03d.png"%frame)
		if error!=OK:errors.append(frame)
		record["save_error"]=error;records.append(record)
		if frame%24==0:print("SOURCE3D_SEQUENCE ",stage," frame=",frame," variance=",record.variance)
	var report: Dictionary={"fixture":"isolated stepped source-frame presentation; not controller progression or performance evidence","stage":stage,"source_fps":24,"logical_resolution":[960,540],"frame_count":records.size(),"frames":records,"errors":errors}
	var file:=FileAccess.open(output+"/"+stage+"-render-coverage.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"  "));file.close()
	view.dispose();view.queue_free();await process_frame
	print("SOURCE3D_SEQUENCE_DONE ",stage," frames=",records.size()," errors=",errors.size());quit(0 if errors.is_empty() else 1)
