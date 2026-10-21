extends SceneTree
var checks:=0
var failures:=0
func _initialize()->void:run.call_deferred()
func check(ok:bool,message:String)->void:
	checks+=1
	if not ok:failures+=1;push_error(message)
func frames()->void:
	for unused in 6:await process_frame
func run()->void:
	var state:=root.get_node("State");state.developer_mode=true
	for dimensions:Vector2i in [Vector2i(390,844),Vector2i(844,390),Vector2i(1440,900)]:
		root.size=dimensions;state.begin_checkpoint("c3-qizhen-location")
		state.d.native.scene="";state.d.native.page="zjuding"
		state.d.qizhenLake.active=true;state.d.qizhenLake.phase="location_search"
		var shell:Control=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames()
		shell.mobile_world=false;shell._refresh();shell._process(2);await frames()
		shell.phone_builder.zjuding_page="campus_map";shell._refresh();await frames();shell._layout();await frames()
		var count:Label=shell.page_body.find_child("QizhenMapCount",true,false)
		check(count!=null,"actual map count renders")
		if count:
			check(not count.get_global_rect().intersects(shell.phone_chrome.inventory_handle.get_global_rect()),"collapsed inventory handle never hides map count")
			check(count.text=="已接入  0 / 3","header retains authored progress")
			check(count.get_theme_font("font").get_string_size(count.text,HORIZONTAL_ALIGNMENT_LEFT,-1,count.get_theme_font_size("font_size")).x<=count.size.x,"count fits its reserved header column")
		await shell.shutdown();shell.queue_free();await frames()
	print("Lake map header clearance: ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)
