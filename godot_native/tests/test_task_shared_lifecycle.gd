extends "res://tests/test_task_shared_ui.gd"
## Actual root-viewport mouse, keys and synthetic touch. No task-only tween.
func run() -> void:
	if not load("res://tests/native_test_isolation.gd").is_isolated_save():quit(2);return
	create_timer(180).timeout.connect(func():push_error("Shared lifecycle deadline");quit(2))
	state=root.get_node("State");actual_progress(0)
	shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell)
	await frames(10);shell.set_process(false);shell._clear_notice_presentations()
	for dimensions: Vector2i in [Vector2i(390,844),Vector2i(1440,900),Vector2i(320,568),Vector2i(844,390)]:
		root.size=dimensions;shell._layout();await frames(4)
		for page: String in ["phone_home","settings","bonsai"]:
			state.open_page(page);await frames(6);shell._clear_notice_presentations()
			for reduced: bool in [false,true]:
				state.d.native.settings.reduced_motion=reduced
				var baseline: Dictionary=state.d.duplicate(true)
				for method: String in ["pointer","enter","space","escape","backdrop"]:
					await click(shell.phone_chrome.task_button);await frames(5)
					check(is_instance_valid(shell.modal),"actual task trigger opens "+page)
					var shared: Dictionary=shell.modal.get_meta("journal_shared_shell")
					check(root.gui_get_focus_owner()==shell.modal,"pointer open has no forced visible close focus")
					check(not shared.close.has_focus(),"close starts with the same unoutlined appearance as Control Center")
					check(not shell.modal_panel.has_meta("journal_slide"),"neither motion setting adds task animation")
					check(shell.modal_panel.position==Vector2.ZERO,"real source shell appears at final position immediately")
					if method=="pointer":await click(shared.close)
					elif method=="backdrop":
						var point: Vector2=shared.backdrop.get_global_rect().end-Vector2(2,2)
						motion(point);mouse(point,true);mouse(point,false)
					elif method=="escape":await press_key(KEY_ESCAPE)
					else:
						await press_key(KEY_TAB)
						check(root.gui_get_focus_owner()==shared.close,"Tab reaches true close first")
						var focus: StyleBoxFlat=shared.close.get_theme_stylebox("focus")
						check(focus.border_color==Color("1975dc") and focus.border_width_top==2,"keyboard keeps visible authentic blue focus")
						await press_key(KEY_ENTER if method=="enter" else KEY_SPACE)
					await frames(4)
					check(not is_instance_valid(shell.modal),"close via "+method+" releases overlay")
					check(not shell.phone_chrome.input_blocked,"close restores phone input")
					check(shell.find_children("NativeModalOverlay","",true,false).is_empty(),"repeat close leaves no stale phone modal")
					check(state.d==baseline,"open and "+method+" do not click through or change original "+page)
		for cycle in 6:
			shell._show_journal();shell._close_modal();await process_frame
		await frames(6)
		check(not is_instance_valid(shell.modal),"same-frame opens cannot revive old content or tween")
	actual_progress(3);await frames(8);shell._clear_notice_presentations()
	root.size=Vector2i(390,844);shell._layout();shell._show_journal();await frames(6)
	var before: Dictionary=state.d.duplicate(true)
	await click(await reveal_control("JournalHistoryToggle"));await frames(5)
	var mounted: Control=find("NativeJournal")
	for dimensions: Vector2i in [Vector2i(844,390),Vector2i(320,568),Vector2i(1440,900),Vector2i(390,844)]:
		root.size=dimensions;shell._layout();await frames(6);verify_dropdown()
		check(find("NativeJournal")==mounted and find("JournalHistory").visible,"resize preserves current task and expanded history")
	await click(await reveal_control("JournalHistoryToggle"));await frames(5)
	check(find("JournalCluesCard")==null and find("JournalObservationCompare")==null,"earned task has no comparison card or entry")
	check(state.d==before,"history browsing preserves earned progress")
	shell._close_modal();await frames(4)
	Input.call("set_emulate_mouse_from_touch",true)
	for cycle in 4:
		var trigger: Vector2=shell.phone_chrome.task_button.get_global_rect().get_center()
		touch(trigger,true);touch(trigger,false);await frames(5)
		check(is_instance_valid(shell.modal),"synthetic touch opens actual task button")
		if not is_instance_valid(shell.modal):break
		var exit_point: Vector2=find("JournalResume").get_global_rect().get_center()
		touch(exit_point,true);touch(exit_point,false);await frames(5)
		check(not is_instance_valid(shell.modal),"synthetic touch closes via shared ×")
	Input.call("set_emulate_mouse_from_touch",false)
	check(state.d==before,"touch closure does not click through")
	check_digit_projection()
	await shell.shutdown();shell.queue_free();await frames(4)
	print("TASK_SHARED_LIFECYCLE: %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
