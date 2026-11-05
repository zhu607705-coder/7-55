extends SceneTree
## Real Main + prologue scene. Explicit presentation pose, not earned gameplay.
var shell: Control
var game: Control
var output:=OS.get_environment("RECEIPT_CAPTURE_DIR")
var captures: Array=[]
func _initialize()->void: run.call_deferred()
func frames(count:int=4)->void:
	for unused in count: await process_frame
func pointer(point:Vector2,down:bool)->void:
	var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.position=point;event.pressed=down;root.push_input(event)
func motion(point:Vector2)->void:
	var event:=InputEventMouseMotion.new();event.position=point;root.push_input(event)
func capture(id:String)->void:
	await frames()
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		if root.get_texture().get_image().save_png(output.path_join(id+".png"))!=OK:quit(2);return
	captures.append({"id":id,"phase":game.phase,"paused":game.paused,"button_rect":str(game.success_continue.get_global_rect()),"viewport":[root.size.x,root.size.y]})
func reset_receipt()->void:
	game.paused=false;game.done=false;game._switch("success");game.elapsed=2.6;game._layout_controls();game.success_view.pose(2.6,true,false)
	game.success_continue.disabled=false;root.gui_release_focus();motion(Vector2(1,1));await frames()
func run()->void:
	if not preload("res://tests/native_test_isolation.gd").is_isolated_save():quit(2);return
	if output.is_empty():push_error("RECEIPT_CAPTURE_DIR is required");quit(2);return
	DirAccess.make_dir_recursive_absolute(output)
	create_timer(90).timeout.connect(func():push_error("Receipt capture timeout");quit(2))
	var state:Node=root.get_node("State");state.developer_mode=true;state.d=state.initial()
	state.d.native.settings.music=false;state.d.native.settings.effects=false;state.d.native.settings.reduced_motion=true
	shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames(8)
	shell.set_process(false);shell.world.set_process(false);shell.battery_prank.set_process(false)
	if is_instance_valid(shell.audio_director):shell.audio_director.reset();shell.audio_director.set_process(false)
	await shell._open_game_now({"script":"res://scripts/games/prologue_interception.gd","type":"interception","viewport":[430,820]})
	game=shell.active_game;game.set_process(false)
	for extent:Vector2i in [Vector2i(390,844),Vector2i(1440,900)]:
		root.size=extent;shell.size=Vector2(extent)
		if DisplayServer.get_name()!="headless":DisplayServer.window_set_size(extent)
		await frames();shell._layout();game._layout_controls()
		var prefix:="%dx%d-"%[extent.x,extent.y]
		await reset_receipt();await capture(prefix+"01-receipt-normal")
		motion(game.success_continue.get_global_rect().get_center());await capture(prefix+"02-receipt-hover")
		pointer(game.success_continue.get_global_rect().get_center(),true);await capture(prefix+"03-receipt-pressed")
		motion(Vector2(1,1));pointer(Vector2(1,1),false);await reset_receipt()
		game.success_continue.grab_focus();await capture(prefix+"04-receipt-focus")
		root.gui_release_focus();game.success_continue.disabled=true;await capture(prefix+"05-receipt-disabled")
		await reset_receipt();game._pause();game._layout_controls();game.success_view.pose(game.elapsed,true,true);await capture(prefix+"06-receipt-paused")
		game._resume();game._switch("lock");game._layout_controls();await capture(prefix+"07-keyboard-help")
	await shell.shutdown();shell.queue_free();await frames()
	var file:=FileAccess.open(output.path_join("receipt-captures.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"engine":Engine.get_version_info(),"scope":"Real production scenes with frozen presentation fixtures; not earned completion. Before and after use identical fixture.","captures":captures},"\t"));file.close()
	print("CHECKIN_RECEIPT_CAPTURES: ",captures.size()," surfaces");quit(0)
