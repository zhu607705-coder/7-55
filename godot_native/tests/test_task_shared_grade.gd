extends "res://tests/test_task_shared_ui.gd"
## Real new game and brightness controller, shared same rendered phone layer.
func run() -> void:
	if not load("res://tests/native_test_isolation.gd").is_isolated_save():quit(2);return
	if not output.is_empty():DirAccess.make_dir_recursive_absolute(output)
	create_timer(60).timeout.connect(func():push_error("Shared grade deadline");quit(2))
	state=root.get_node("State");actual_progress(0)
	if capture_enabled:DisplayServer.window_set_size(Vector2i(390,844))
	root.size=Vector2i(390,844)
	shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames(10);shell.set_process(false)
	var reports: Array=[]
	for brightness: int in [0,65,100]:
		controller("c1_brightness",brightness);await frames(6);shell._clear_notice_presentations()
		check(int(state.d.ui.brightness)==brightness,"authored brightness controller accepts actual value")
		shell._on_phone_page("control_center");await frames(8)
		var source: Control=shell.control_center.find_child("ControlCenterPanel",true,false)
		var source_close: Button=source.find_child("PhoneNav_close",true,false)
		var source_title: Label=source.find_child("PhoneOverlayTitle",true,false)
		var source_z: int=shell.control_center.z_index
		var source_parent: Node=shell.control_center.get_parent()
		var source_scale: Vector2=source.get_global_transform().get_scale()
		var source_rect: Rect2=source_close.get_global_rect()
		var control_pixels: Image
		motion(Vector2(1,1));await frames(4)
		if capture_enabled:
			await RenderingServer.frame_post_draw
			control_pixels=root.get_texture().get_image()
		await take("390x844-brightness-%d-control"%brightness)
		shell._on_phone_action("native_control_center_close",null);await frames(4)
		shell._show_journal();await frames(8)
		var shared: Dictionary=shell.modal.get_meta("journal_shared_shell")
		check(shared.panel.get_global_transform().get_scale()==source_scale,"task and control use identical physical scale")
		check(shared.close.get_global_rect()==source_rect,"task and control use identical physical close geometry")
		check(shell.modal.z_index==source_z,"task and control share actual phone z index")
		check(shell.modal.get_parent()==source_parent,"task and control share phone composition parent")
		check(not shared.close.has_focus(),"no initial blue outline")
		await take("390x844-brightness-%d-task"%brightness)
		var entry: Dictionary={"brightness":brightness,"sameParent":true,"sameScale":str(source_scale),"sameCloseRect":str(source_rect),"actualController":"State.new_game + State.act(c1_brightness)","pixelCompared":false}
		if capture_enabled:
			await RenderingServer.frame_post_draw
			var task_pixels: Image=root.get_texture().get_image()
			var region:=Rect2i(source_rect.position.floor(),source_rect.size.ceil())
			var same: bool=control_pixels.get_region(region).get_data()==task_pixels.get_region(region).get_data()
			check(same,"actual RGBA shared close matches at brightness %d"%brightness)
			entry.pixelCompared=true;entry.closeRGBAIdentical=same
		reports.append(entry)
		shell._close_modal();await frames(4)
	if not output.is_empty():
		var file:=FileAccess.open(output.path_join("shared-grade-report.json"),FileAccess.WRITE)
		file.store_string(JSON.stringify({"checks":checks,"failures":failures,"realGraphics":capture_enabled,"brightness":reports,"shots":shots},"\t"));file.close()
	await shell.shutdown();shell.queue_free();await frames(4)
	print("TASK_SHARED_GRADE: %d checks; %d failures; real_graphics=%s"%[checks,failures,str(capture_enabled)]);quit(1 if failures else 0)
