extends SceneTree
## Real production scenes; isolated visual fixtures, not earned campaign progress.
var output: String
var report: Array[Dictionary]=[]
var failures:=0
var validate_only:=OS.get_environment("UI_CAPTURE_VALIDATE")=="1"
var fixture:Dictionary={"runtimeMode":"rpg","rpgScene":"theater_interior","rpgCheckpoint":"campus_theater_interior","native":{"scene":"theater_interior","mode":"light","settings":{"reduced_motion":false}},"theaterHunt":{"active":true,"admitted":true,"phase":"program_search"},"ui":{"controlCenterOpen":false}}
func _initialize()->void:run.call_deferred()
func frames(count:int=6)->void:
	for unused in count:await process_frame
func check(ok:bool,label:String)->void:
	if not ok:failures+=1;push_error("TACTILE_BOUNDARY_CAPTURE: "+label)
func resize_to(dimensions:Vector2i)->void:
	if not validate_only:DisplayServer.window_set_size(dimensions)
	root.size=dimensions
	await frames()
func capture(id:String,details:Dictionary)->void:
	await frames()
	var record:Dictionary={"id":id,"fixture":"Isolated DEV/presentation fixture; not earned campaign progress","dimensions":[root.size.x,root.size.y],"details":details,"validation_only":validate_only}
	if not validate_only:
		await RenderingServer.frame_post_draw
		var pixels:=root.get_texture().get_image()
		check(pixels!=null and not pixels.is_empty(),"Actual rendered frame exists: "+id)
		if pixels!=null:
			record["save_error"]=pixels.save_png(output.path_join(id+".png"))
			check(record.save_error==OK,"PNG saved: "+id)
	report.append(record)
func rect_value(control:Control)->Array:
	var rect:=control.get_global_rect()
	return [rect.position.x,rect.position.y,rect.size.x,rect.size.y]
func run()->void:
	if DisplayServer.get_name()=="headless" and not validate_only:quit(2);return
	if not load("res://tests/native_test_isolation.gd").is_isolated_save():quit(2);return
	output=OS.get_environment("UI_CAPTURE_DIR")
	if output.is_empty():quit(2);return
	DirAccess.make_dir_recursive_absolute(output)
	create_timer(120).timeout.connect(func():push_error("Tactile boundary capture timed out");quit(2))
	Engine.max_fps=30
	for campus:String in ["buct","buct_haidian","buct_changping"]:
		await resize_to(Vector2i(667,375))
		var view=load("res://campuses/"+campus+"/scenes/playable.tscn").instantiate();root.add_child(view);await frames()
		var back:Button=view.ui_controls.back
		check(Rect2(Vector2.ZERO,Vector2(root.size)).encloses(back.get_global_rect()),campus+" return action fits actual window")
		await capture("667x375-"+campus+"-return",{"return":rect_value(back)})
		view.queue_free();await frames()
	var performance=load("res://scripts/presentation/liangzhu_performance.gd").new();root.add_child(performance)
	check(performance.setup({"read_state":func()->Dictionary:return fixture,"allow_placeholder":false}),"Production performance assets load without placeholders")
	performance.set_process(false);performance.tick(15,true);performance.tick(60,true)
	for dimensions:Vector2i in [Vector2i(1440,900),Vector2i(390,844)]:
		await resize_to(dimensions);performance.configure_activity_layout(Vector2(dimensions));await frames()
		check(performance.model.status=="failure","Capture actual failed QTE controls")
		check(not performance.retry_button.get_global_rect().intersects(performance.return_button.get_global_rect()),"Retry and Return hit areas remain separate")
		await capture("%dx%d-qte-retry-return"%[dimensions.x,dimensions.y],{"retry":rect_value(performance.retry_button),"return":rect_value(performance.return_button),"screen_font_px":performance.retry_button.get_theme_font_size("font_size")*performance.stage_frame.scale.x})
	performance.queue_free();await frames()
	var state:=root.get_node("State");state.developer_mode=true
	check(state.begin_checkpoint("c4-755-closure"),"Isolated finale checkpoint loads")
	var issued:Dictionary={}
	for module in state.modules:
		if str(module.get_script().resource_path)=="res://scripts/chapters/chapter4.gd":issued=module.dispatch(state.d,"c4_lamp_start")
	check(issued.has("game"),"Controller issues real lamp view configuration")
	if issued.has("game"):
		var activity=load("res://scripts/games/chapter4_activity.gd").new();root.add_child(activity);activity.setup(issued.game);activity.set_process(false)
		var lamp:Control=activity.lamp_view
		for unused in 12:lamp.advance(100,true)
		for dimensions:Vector2i in [Vector2i(390,844),Vector2i(844,390)]:
			await resize_to(dimensions);activity.configure_activity_layout(Vector2(dimensions),true);await frames()
			var choices:Array=[]
			for button:Button in lamp.buttons:
				check(button.get_theme_font_size("font_size")>=18 and button.size.y>=44,"Actual lamp option keeps readable type and target")
				choices.append({"text":button.text,"rect":rect_value(button),"font_px":button.get_theme_font_size("font_size")})
			await capture("%dx%d-lamp-choices"%[dimensions.x,dimensions.y],{"choices":choices})
		activity.queue_free();await frames()
	var file:=FileAccess.open(output.path_join("tactile-boundaries.json"),FileAccess.WRITE)
	if file!=null:file.store_string(JSON.stringify({"engine":Engine.get_version_info(),"display_server":DisplayServer.get_name(),"failures":failures,"frames":report},"\t"));file.close()
	else:check(false,"Capture manifest can be written")
	print("TACTILE_BOUNDARY_CAPTURE: ",report.size()," frames; ",failures," failures")
	quit(1 if failures else 0)
