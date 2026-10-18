extends SceneTree
var view: Node2D
var output: String=ProjectSettings.globalize_path("res://test-output/")
func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence-dir="):output=arg.trim_prefix("--evidence-dir=").trim_suffix("/")+"/"
	DirAccess.make_dir_recursive_absolute(output)
	call_deferred("run")
func shot(name: String,size: Vector2i) -> void:
	root.size=size
	for i in range(3):await process_frame
	view._update_layout();view._sync(0,true);view.hud.queue_redraw()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output+name+".png")
	print("SCREENSHOT ",name," ",root.get_texture().get_size())
func run() -> void:
	view=load("res://scenes/qizhen_large_world.tscn").instantiate();root.add_child(view);view.set_process(false)
	await shot("01-desktop-title",Vector2i(1280,720))
	view.title_open=false;view.touch_mode=true
	await shot("02-desktop-play",Vector2i(1280,720))
	view.game.progress=1;view.last_progress=1;view.game.position=view.Geo.goals()[1].point+Vector2(-90,70);view.game.heading=-.6
	await shot("03-phone-portrait-target-fixture",Vector2i(390,844))
	view.game.paused=true
	await shot("04-phone-landscape-paused",Vector2i(844,390))
	view.game.paused=false;view.title_open=true
	await shot("05-phone-portrait-title",Vector2i(390,844))
	view.title_open=false;view._set_overview(true)
	await shot("06-phone-portrait-map",Vector2i(390,844))
	view._set_overview(false);view.game.swan_phase="warning";view.game.swan=view.game.position+Vector2(450,10);view.game.swan_lock=view.game.swan;view.game.swan_heading=PI
	await shot("07-phone-landscape-warning-fixture",Vector2i(844,390))
	view._restart();view.touch_mode=true;view.game.progress=2;view.game.speed=285;view.game.heading=PI/2;view.game.swan_phase="warning";view.game.swan=view.game.position+Vector2(450,10);view.game.swan_lock=view.game.swan;view.game.swan_heading=PI
	await shot("08-phone-landscape-highspeed-south-fixture",Vector2i(844,390))
	view.game.heading=-PI/2
	await shot("09-phone-landscape-highspeed-north-fixture",Vector2i(844,390))
	quit(0)
