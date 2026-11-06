extends SceneTree
## Actual Main journal routing across chapters, phone sizes and retained world.
var checks := 0
var failures := 0
func _initialize() -> void: run.call_deferred()
func frames() -> void:
	for unused in 5: await process_frame
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func isolated() -> bool:
	if OS.get_name() != "Windows": return load("res://tests/native_test_isolation.gd").is_isolated_save()
	var actual := OS.get_user_data_dir().replace("\\","/").simplify_path()
	var declared := OS.get_environment("GODOT_TEST_USER_DATA_DIR").replace("\\","/").simplify_path()
	return actual == declared and actual.get_file().begins_with("755-focus-journal-")
func press_key(code: Key) -> void:
	for down: bool in [true,false]:
		var event := InputEventKey.new(); event.keycode=code; event.pressed=down
		root.push_input(event,true)
	await frames()
func run() -> void:
	if not isolated(): push_error("JOURNAL_TEST_ISOLATION_REQUIRED"); quit(2); return
	var state := root.get_node_or_null("State")
	if state==null: push_error("State autoload failed"); quit(2); return
	state.developer_mode=true; state.d=state.initial()
	var shell: Control=load("res://scenes/main.tscn").instantiate(); root.add_child(shell); await frames()
	for dimensions: Vector2i in [Vector2i(1280,720),Vector2i(1440,900),Vector2i(390,844),Vector2i(844,390)]:
		root.size=dimensions; shell.size=Vector2(dimensions)
		for checkpoint: String in ["c1-code-hunt","c2-dorm-exit","c3-theater-entry","c4-755-opening"]:
			check(state.begin_checkpoint(checkpoint),"chapter checkpoint loads: "+checkpoint)
			state.d.runtimeMode="phone"; state.d.native.page="phone_home"; state.d.currentScene="phone_home"
			state.d.items.headphone=true; state.d.items.waterDrop=true
			for i in 35: state.d.native.log.append({"text":"已取得的记录 %s：核对当前任务和材料，保留原有章节内容。" % i})
			shell.mobile_world=false; shell._refresh(); shell._layout(); await frames()
			var before: String=JSON.stringify(state.d)
			shell._show_journal(); await frames()
			check(shell.modal.has_meta("journal_shared_shell"),"every phone chapter uses shared shell: "+checkpoint)
			check(shell.modal.get_parent()==shell.phone,"journal stays inside phone glass")
			var shared: Dictionary=shell.modal.get_meta("journal_shared_shell")
			check(shared.panel.position.is_equal_approx(Vector2.ZERO) and is_equal_approx(shared.panel.size.x,378),"same top anchor and authoring width")
			var journal: Control=shell.modal.find_child("NativeJournal",true,false)
			var toggle: Button=journal.find_child("JournalHistoryToggle",true,false)
			toggle.button_pressed=true; toggle.pressed.emit(); await frames()
			check(journal.find_child("JournalObjective",true,false).text==state.objective(),"current objective remains controller-owned")
			check(not shared.scroll.is_ancestor_of(shared.close),"close stays outside scroll body")
			check(shared.scroll.follow_focus,"keyboard focus scrolls into view")
			check(shell.phone.get_global_rect().grow(.5).encloses(shell.modal_panel.get_global_rect()),"phone panel stays in bounds")
			var rail: VScrollBar=shared.scroll.get_v_scroll_bar()
			check(rail.max_value>rail.page,"long earned history has a scrollable range")
			shared.scroll.scroll_vertical=10000; await frames()
			check(shared.scroll.scroll_vertical>0,"history actually scrolls")
			if OS.get_cmdline_user_args().has("--capture") and DisplayServer.get_name()!="headless":
				await RenderingServer.frame_post_draw
				DirAccess.make_dir_recursive_absolute("res://.screenshots/journal-chapters")
				root.get_texture().get_image().save_png("res://.screenshots/journal-chapters/%s-%sx%s.png" % [checkpoint,dimensions.x,dimensions.y])
			check(JSON.stringify(state.d)==before,"opening/scrolling preserves story state")
			await press_key(KEY_TAB)
			check(is_instance_valid(root.gui_get_focus_owner()),"Tab enters a real modal control")
			if int(state.d.native.chapter) in [1,2]:
				shell._show_observation_comparison(true); await frames()
				check(shell.modal.has_meta("journal_shared_shell"),"available clue comparison uses same phone shell")
				var back: Button=shell.modal.find_child("ObservationJournalReturn",true,false)
				check(back!=null,"comparison retains return to journal")
				if back!=null: back.pressed.emit(); await frames()
				check(shell.modal.find_child("NativeJournal",true,false)!=null,"comparison returns to journal")
			await press_key(KEY_ESCAPE)
			check(not is_instance_valid(shell.modal) and not shell.phone_chrome.input_blocked,"Escape restores phone input")
			check(JSON.stringify(state.d)==before,"journal exit preserves chapter content")
		# World retains the existing reading layer and explicit return destination.
		check(state.begin_checkpoint("c2-dorm-exit"),"world checkpoint loads")
		shell._refresh(); shell.mobile_world=true; shell._layout(); await frames()
		shell._show_journal(); await frames()
		check(not shell.modal.has_meta("journal_shared_shell"),"world keeps landscape journal")
		var resume: Button=shell.modal.find_child("JournalResume",true,false)
		check(resume!=null and resume.text=="返回现场","world return label preserved")
		if resume!=null: resume.pressed.emit(); await frames()
		check(not is_instance_valid(shell.modal) and shell.world_frame.is_visible_in_tree(),"world return restores retained map")
	await shell.shutdown(); shell.queue_free(); await frames()
	print("Phone journal chapters: ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)
