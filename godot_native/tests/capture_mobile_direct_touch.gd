extends "res://tests/test_mobile_direct_touch.gd"
## Actual production renderer with isolated DEV source targets. No compositing,
## manual-play claim, physical-device claim or generated replacement UI.
var capture_output := ""
var capture_records: Array = []
var validate_only := OS.get_environment("UI_CAPTURE_VALIDATE") == "1"
func shot(id: String, note: String) -> void:
	shell.world.queue_redraw(); await frames(8)
	var record: Dictionary = {"id":id,"fixture":note,"dimensions":str(root.size),"world_rect":str(shell.world_view.get_global_rect()),"stick_rect":str(shell.world.mobile_control_metrics().stick_rect),"confirmed_plaque":shell.world.selected_overlay.plaque.visible,"lamp_on":lamp(),"axis":str(shell.world.touch_axis),"validation_only":validate_only}
	if shell.world.selected_overlay.plaque.is_visible_in_tree():
		assert_mobile_plaque_at_bottom(id)
		var plaque:Rect2=shell.world.selected_overlay.plaque.get_global_rect()
		record["plaque_rect"]=str(plaque)
		record["plaque_bottom_gap"]=shell.world_view.get_global_rect().end.y-plaque.end.y
	if not validate_only:
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		var result := image.save_png(capture_output.path_join(id+".png"))
		check(result==OK,"actual renderer screenshot saved: "+id)
		record["width"]=image.get_width(); record["height"]=image.get_height(); record["save_error"]=result
	capture_records.append(record)
func run() -> void:
	if DisplayServer.get_name()=="headless" and not validate_only: quit(2); return
	if not load("res://tests/native_test_isolation.gd").is_isolated_save(): quit(2); return
	create_timer(180).timeout.connect(func(): push_error("MOBILE TOUCH capture deadline"); quit(2))
	Engine.max_fps=30
	capture_output=OS.get_environment("UI_CAPTURE_DIR")
	if capture_output.is_empty(): quit(2); return
	DirAccess.make_dir_recursive_absolute(capture_output)
	state=root.get_node("State"); state.developer_mode=true; state.d=state.initial()
	state.action_completed.connect(func(id,_before,_after,_result): actions.append(id))
	for row: Array in [[Vector2i(390,844),Vector4.ZERO,"portrait"],[Vector2i(430,860),Vector4(0,44,0,34),"portrait-safearea"],[Vector2i(844,390),Vector4(44,0,44,21),"landscape-safearea"],[Vector2i(568,320),Vector4.ZERO,"short-landscape"]]:
		DisplayServer.window_set_size(row[0]); root.size=row[0]
		await fixture(row[0],row[1]); assert_layout(row[1])
		var prefix: String=row[2]
		await shot(prefix+"-01-near-unconfirmed","DEV c2-dorm-exit; legal near lamp; no object confirmation; simulated insets="+str(row[1]))
		var point:=visible_pick(); var count:=action_count()
		touch(point,true); touch(point,false); await frames()
		check(lamp() and action_count()==count+1,"capture uses successful actual controller lamp tap")
		await shot(prefix+"-02-direct-tap","Same fixture; root finger tap toggled source lamp once, no joystick confirm")
		touch(stick_point(),true,3); await frames()
		check(shell.world.touch_axis.x>.5,"capture shows a held real movement intent")
		await shot(prefix+"-03-joystick-held","Root touch owns lower-left joystick; movement tick frozen only for deterministic screenshot")
		touch(stick_point(),false,3); await frames()
		if prefix in ["portrait","landscape-safearea"]:
			shell._toggle_world_inventory(); await frames()
			check(not shell.world.selected_overlay.plaque.visible,"inventory layout change clears the previous confirmation")
			point=visible_pick();count=action_count()
			touch(point,true);touch(point,false);await frames()
			check(action_count()==count+1,"expanded inventory capture reconfirms the actual nearby object through root touch")
			await shot(prefix+"-04-existing-inventory","Existing inventory expanded; fresh root object tap confirms bottom plaque above unchanged inventory")
			shell._show_journal(); await frames()
			await shot(prefix+"-05-existing-journal","Existing locked JOURNAL-3 owns input; world pointer ownership canceled")
			shell._close_modal(); await frames()
			check(not shell.world.selected_overlay.plaque.visible,"journal dismissal does not restore stale target label")
			await shot(prefix+"-06-journal-closed","Journal closed; no stale confirmed label or held joystick resumes")
	var file:=FileAccess.open(capture_output.path_join("mobile-touch-captures.json"),FileAccess.WRITE)
	if file==null: quit(2); return
	file.store_string(JSON.stringify({"captures":capture_records,"checks":checks,"failures":failures,"engine":Engine.get_version_info(),"physical_device":false,"safe_area":"simulated OS inset seam"},"\t")); file.close()
	if is_instance_valid(shell): await shell.shutdown(); shell.queue_free(); await frames()
	print("MOBILE_TOUCH_FIXTURES " if validate_only else "MOBILE_TOUCH_CAPTURES ",capture_records.size(),"; ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
