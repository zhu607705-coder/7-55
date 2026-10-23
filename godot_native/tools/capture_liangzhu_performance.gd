extends SceneTree
## Manual GPU capture of the production renderer in a no-autoload project.
const View=preload("res://scripts/presentation/liangzhu_performance.gd")
const Model=preload("res://scripts/presentation/liangzhu_performance_model.gd")
const FPS=30
var view:Control
var closed_count:=0
var fixture:Dictionary={"runtimeMode":"rpg","rpgScene":"theater_interior","rpgCheckpoint":"campus_theater_interior","native":{"scene":"theater_interior","mode":"light","settings":{"reduced_motion":false}},"theaterHunt":{"active":true,"admitted":true,"phase":"program_search"},"ui":{"controlCenterOpen":false}}

func _initialize()->void:run.call_deferred()

func option(name:String)->String:
	for argument:String in OS.get_cmdline_user_args():
		if argument.begins_with("--"+name+"="):return argument.substr(name.length()+3)
	return ""

func reject(reason:String)->void:
	push_error("LIANGZHU_CAPTURE: "+reason);quit(2)

func freeze(value:Variant)->void:
	if value is Dictionary:
		for child:Variant in value.values():freeze(child)
		value.make_read_only()
	elif value is Array:
		for child:Variant in value:freeze(child)
		value.make_read_only()

func run()->void:
	if DisplayServer.get_name()=="headless":reject("GPU_RENDERER_REQUIRED");return
	for property:Dictionary in ProjectSettings.get_property_list():
		if str(property.name).begins_with("autoload/"):reject("MINIMAL_NO_AUTOLOAD_PROJECT_REQUIRED");return
	var output:String=option("output")
	if not output.is_absolute_path():reject("Absolute --output directory required");return
	var sample_only:bool=OS.get_cmdline_user_args().has("--samples")
	var presentation_frame:bool=OS.get_cmdline_user_args().has("--presentation-frame")
	var output_size:=Vector2i(1280,720) if presentation_frame else Vector2i(1200,675)
	if DirAccess.dir_exists_absolute(output):
		for filename:String in DirAccess.get_files_at(output):
			if filename.ends_with(".png") or filename=="capture.json":reject("Output must not contain stale capture frames");return
	if DirAccess.make_dir_recursive_absolute(output)!=OK:reject("Cannot create capture directory");return
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS,true)
	root.size=Vector2i(1280,720)
	# Root-authorized immutable presentation context, never a playable save or
	# claim of earned admission. No State/Main/autoload exists in this project.
	freeze(fixture)
	var original_context:String=JSON.stringify(fixture)
	view=View.new();root.add_child(view);view.set_process(false)
	if not view.setup({"read_state":func()->Dictionary:return fixture,"allow_placeholder":false,"playback_mode":"passive"}):reject("Generated production assets/context rejected: "+str(view.asset_issues));return
	view.set_process(false);view.configure_activity_layout(Vector2(1280,720),false)
	view.closed.connect(func(_reason:String):closed_count+=1)
	if not view.assets_ready or view.diagnostic:reject("No diagnostic/placeholder capture is permitted");return
	if view.model.playback_mode!="passive":reject("Offline viewing must be explicit passive mode, never a QTE completion");return
	var times:Array[float]=[]
	if sample_only:times=[0.0,6000.0,15000.0,29000.0,42000.0,48000.0,52000.0]
	else:
		for frame:int in int(ceil(Model.DURATION_MS*FPS/1000.0)):times.append(float(frame)*1000.0/FPS)
	if not option("sample-times").is_empty():
		if not sample_only:reject("Custom cue times are allowed only in samples mode");return
		times=[]
		for value:String in option("sample-times").split(","):
			if not value.is_valid_float():reject("Invalid sample timestamp");return
			var time_ms:float=value.to_float()
			if not is_finite(time_ms) or time_ms<0 or time_ms>Model.DURATION_MS:reject("Sample timestamp outside performance");return
			times.append(time_ms)
		if times.is_empty() or times.size()>8:reject("Custom preview needs1..8 timestamps");return
	for timestamp:float in times:
		if timestamp>Model.DURATION_MS:reject("Default preview cues exceed the frozen model duration; choose explicit --sample-times");return
	var records:Array[Dictionary]=[]
	for index:int in times.size():
		var timestamp:float=times[index]
		# NO_FOCUS keeps this isolated preview from interrupting the desktop.
		# Resume only its passive presenter before seeking; the clock stays stopped.
		view.resume()
		view.render_at(timestamp)
		await RenderingServer.frame_post_draw
		if view.model.manually_paused or view.model.focus_paused or view.pause_button.text!="暂停":reject("Offline playing view must display the active pause action");return
		var texture:Texture2D=view.stage_texture()
		if texture==null or texture.get_size()!=Vector2(1200,675):reject("Renderer must return native1200×675 stage texture");return
		var stage_image:Image=texture.get_image()
		if stage_image==null or stage_image.get_size()!=Vector2i(1200,675):reject("GPU image dimensions differ from native stage");return
		var image:Image=root.get_texture().get_image() if presentation_frame else stage_image
		if image==null or image.get_size()!=output_size:reject("Actual GPU output differs from declared full-view/native dimensions");return
		var name:String=("sample_%06d.png" if sample_only else "frame_%06d.png")%index
		var file:String=output.path_join(name)
		if image.save_png(file)!=OK:reject("Cannot write native frame: "+file);return
		var digest:=HashingContext.new();digest.start(HashingContext.HASH_SHA256);digest.update(image.get_data())
		var stage_digest:=HashingContext.new();stage_digest.start(HashingContext.HASH_SHA256);stage_digest.update(stage_image.get_data())
		var geometry:Dictionary=view.geometry_snapshot()
		var oracle:Dictionary={}
		if presentation_frame and sample_only:
			var oracle_name:String="stage_oracle_%06d.png"%index
			if stage_image.save_png(output.path_join(oracle_name))!=OK:reject("Cannot save native stage pixel oracle");return
			oracle={"file":oracle_name,"sha256":FileAccess.get_sha256(output.path_join(oracle_name)),"dimensions":[1200,675]}
		records.append({"file":name,"sha256":FileAccess.get_sha256(file),"nativePixelSha256":digest.finish().hex_encode(),"pixelFormat":image.get_format(),"nativeStagePixelSha256":stage_digest.finish().hex_encode(),"nativeStageDimensions":[1200,675],"nativeStageOracle":oracle,"timestampMs":timestamp,"beat":int(view.capture_pose.beat),"dimensions":[output_size.x,output_size.y],"sceneId":view.capture_pose.get("sceneId",""),"cueId":view.capture_pose.get("cueId",""),"speaker":view.capture_pose.get("speaker",""),"delivery":view.capture_pose.get("delivery",""),"actualTitleText":view.title.text,"actualCaptionText":view.caption.text,"actualPauseActionText":view.pause_button.text,"actorRigs":geometry.get("actorRigs",{}),"fans":geometry.get("fans",[])})
		if index%60==0:print("LIANGZHU_CAPTURE_PROGRESS ",index+1,"/",times.size())
	if JSON.stringify(fixture)!=original_context or closed_count!=0 or view.model.elapsed_ms!=0 or view.model.status!="playing":reject("Pure capture changed the runtime clock, readonly context or closed lifecycle");return
	if not view.model.qte_completed.is_empty() or not view.model.qte_results.is_empty() or not view.model.active_qte.is_empty():reject("Offline passive viewing must not create QTE results");return
	var report:Dictionary={
		"schema":"755-liangzhu-native-frame-capture-v1","sampleOnly":sample_only,"engine":Engine.get_version_info(),"displayServer":DisplayServer.get_name(),
		"context":"Immutable minimal theater-admitted presentation fixture; not a save and not an earned player session. No State or Main instantiated.","autoloads":[],
		"rasterDimensions":[output_size.x,output_size.y],"nativeStageDimensions":[1200,675],"presentationFrame":presentation_frame,"playbackMode":"passive","compositionUnits":[240,135],"finePixelsPerUnit":5,"coarseIntermediate":false,
		"fps":FPS,"frames":records,"frameCount":records.size(),"canonicalDurationSeconds":Model.DURATION_MS/1000.0 if not sample_only else null,
		"stageSha256":FileAccess.get_sha256("res://assets/native/liangzhu_performance_20261021/stage.png"),
		"actorsSha256":FileAccess.get_sha256("res://assets/native/liangzhu_performance_20261021/actors.png"),
		"modelSha256":FileAccess.get_sha256("res://scripts/presentation/liangzhu_performance_model.gd"),
		"contentSha256":FileAccess.get_sha256(Model.CONTENT_PATH),
		"presenterSha256":FileAccess.get_sha256("res://scripts/presentation/liangzhu_performance.gd"),
		"rigSha256":FileAccess.get_sha256("res://scripts/presentation/liangzhu_actor_rig.gd"),
		"stagePlateSha256":FileAccess.get_sha256("res://scripts/presentation/liangzhu_stage_plate.gd"),
		"furnitureMetadataSha256":FileAccess.get_sha256("res://assets/native/liangzhu_performance_20261021/furniture.json"),
		"harnessSha256":FileAccess.get_sha256("res://tools/capture_liangzhu_performance.gd"),
		"sameProductionDrawPath":true,"actualGPUReadback":true,"runtimeClockUnchanged":true,"readonlyContextUnchanged":true,"gameSaveAccess":false,"qteResults":[],"qteCompletions":[],"closedSignals":closed_count,
		"offlineFocusHandling":"Isolated passive presenter.resume() before each pure render_at; no OS window focus, real State or runtime clock advancement. Every captured pause action must read 暂停.",
		"limitations":["Native GPU frames do not prove browser/physical-device input or media playback.","Palette membership of individual assets does not guarantee exact composite RGB during alpha fades.","Native1200×675 stage PNGs are the art pixel oracle. Full-view1280×720 includes actual presenter text/UI and uniformly displayed stage; compressed movies have separate codec/display acceptance."]
	}
	var result:=FileAccess.open(output.path_join("capture.json"),FileAccess.WRITE)
	if result==null:reject("Cannot write capture receipt");return
	result.store_string(JSON.stringify(report,"\t"));result.close()
	view.dispose_presentation();view.queue_free();await process_frame
	print("LIANGZHU_CAPTURE_COMPLETE ",JSON.stringify({"frames":records.size(),"sampleOnly":sample_only,"dimensions":[output_size.x,output_size.y],"presentationFrame":presentation_frame,"output":output,"gameSaveAccess":false}));quit()
