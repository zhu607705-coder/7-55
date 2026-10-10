extends "res://tests/test_phone_loading_notice_layout.gd"
## Lead-only graphical QA in an isolated profile; never earned-campaign proof.
var output: String
var captured := 0

func capture(label: String, verify_dot_mask: bool=false) -> void:
	await frames(); await RenderingServer.frame_post_draw
	var shot := root.get_texture().get_image()
	if verify_dot_mask:
		var art: Control=find_named(shell.page_body,"ZjudingLoadingArt")
		var fitted: Rect2=art.fitted_art_rect()
		var factor: float=fitted.size.x/Art.SOURCE_REGION.size.x
		var top_left: Vector2=art.get_global_transform_with_canvas()*(fitted.position+(Art.BAKED_DOT_REGION.position-Art.SOURCE_REGION.position)*factor)
		var bottom_right: Vector2=art.get_global_transform_with_canvas()*(fitted.position+(Art.BAKED_DOT_REGION.end-Art.SOURCE_REGION.position)*factor)
		var pale_pixels := 0
		for y in range(ceili(top_left.y),floori(bottom_right.y)):
			for x in range(ceili(top_left.x),floori(bottom_right.x)):
				var color := shot.get_pixel(x,y)
				if minf(color.r,minf(color.g,color.b))>.6: pale_pixels+=1
		check(pale_pixels==0,"rendered shader removes all five baked white dots: "+label)
	var path := output+"/"+label+".png"
	check(shot.save_png(path)==OK,"screenshot saved: "+path)
	captured+=1
	print("PHONE_LAYOUT_CAPTURE ",path)

func run() -> void:
	if DisplayServer.get_name()=="headless":
		push_error("This capture harness needs the lead's graphical session; run test_phone_loading_notice_layout.gd headlessly instead")
		quit(1); return
	output=OS.get_environment("PHONE_LAYOUT_CAPTURE_DIR")
	if output.is_empty(): output=ProjectSettings.globalize_path("res://.screenshots/loading-notice")
	DirAccess.make_dir_recursive_absolute(output)
	state=root.get_node("State"); state.developer_mode=true; state.d=state.initial()
	shell=load("res://scenes/main.tscn").instantiate(); root.add_child(shell); await frames(); shell.set_process(false)
	for viewport: Vector2i in [Vector2i(390,844),Vector2i(430,860),Vector2i(1440,900)]:
		DisplayServer.window_set_size(viewport); root.size=viewport; shell.size=Vector2(viewport); await frames()
		var prefix := "%dx%d"%[viewport.x,viewport.y]
		await fixture("cellular")
		await click(find_named(shell.page_body,"HomeApp_zjuding")); await tick(3000)
		check_loading_art()
		await capture(prefix+"-zjuding-blocked",true)
		await fixture()
		await click(find_named(shell.page_body,"HomeApp_zjuding")); await tick(900)
		check_loading_art()
		await capture(prefix+"-zjuding-accepted-loading",true)
		await fixture("campus_wifi",1)
		await click(find_named(shell.page_body,"HomeApp_wechat"))
		check_notice_geometry()
		await capture(prefix+"-wechat-battery-warning")
		shell.battery_prank.deadline=Time.get_ticks_msec()
		await frames()
		check_notice_geometry()
		await capture(prefix+"-wechat-battery-joke")
	await shell.shutdown(); shell.queue_free(); await frames()
	print("Phone loading/notice graphical fixtures: ",captured," captures; ",checks," checks; ",failures," failures. Not manual campaign proof.")
	quit(1 if failures else 0)
