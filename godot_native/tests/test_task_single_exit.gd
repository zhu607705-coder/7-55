extends "res://tests/test_task_flat_surface.gd"
## Real Main and root-viewport input. Isolated authored checkpoints test the
## task's single exit without claiming earned gameplay or manual UI acceptance.
func assert_single_exit() -> Button:
	var exits: Array[Button]=[]
	for node: Node in shell.modal.find_children("*","Button",true,false):
		if node.is_visible_in_tree() and node.text in ["×","关闭","返回游戏","返回现场"]:exits.append(node)
	check(exits.size()==1,"task has exactly one visible exit")
	check(find("NativeModalClose")==null,"generic duplicate close is absent")
	var resume:=find("JournalResume") as Button
	check(resume!=null,"original contextual return is wired to shared ×")
	if resume==null:return null
	var scroll:=find("JournalScroll") as ScrollContainer
	check(not scroll.is_ancestor_of(resume),"single exit stays outside scrolling content")
	check(resume.get_global_rect().end.y<=scroll.get_global_rect().position.y+.1,"return stays above task content")
	check(shell.modal_panel.get_global_rect().encloses(resume.get_global_rect()),"return stays inside task panel")
	check(resume.size==Vector2(27,27),"return is the exact source Control Center size")
	var paper: StyleBoxFlat=shell.modal_panel.get_theme_stylebox("panel")
	check(paper.bg_color==Color("e9e5da") and paper.border_color==Color("222322"),"task uses actual shared phone colors")
	check(shell.modal.has_meta("journal_shared_shell") and shell.modal.get_parent()==shell.phone,"task uses phone's real authored canvas and grade composition")
	check(shell.phone_chrome.get_global_rect().encloses(shell.modal_panel.get_global_rect()),"task remains on same phone canvas at every size")
	var face: StyleBoxFlat=resume.get_theme_stylebox("normal")
	check(face.border_width_top==0 and resume.get_theme_stylebox("focus").border_width_top==2,"unoutlined normal close keeps true keyboard focus")
	return resume

func keyboard(code: int, shift:=false) -> void:
	for down: bool in [true,false]:
		var key:=InputEventKey.new();key.keycode=code;key.physical_keycode=code;key.pressed=down;key.shift_pressed=shift
		event(key);await process_frame
	await frames(4)

func prepare_phone(dimensions: Vector2i, page: String="phone_home") -> void:
	shell._close_modal()
	if capture_enabled:DisplayServer.window_set_size(dimensions)
	root.size=dimensions;shell.size=Vector2(dimensions)
	check(seed_c1_fixture("c1-home"),"authored first-chapter fixture loads")
	state.d.native.page=page;state.d.native.scene="";state.d.native.settings.volume=0
	state.d.native.settings.music=false;state.d.native.settings.effects=false;state.d.native.settings.reduced_motion=true
	state.d.ui.inventoryOpen=false;state.d.ui.controlCenterOpen=false
	shell.mobile_world=false;shell._refresh();shell._process(2);await frames(8);shell._layout();await frames(4)
	shell._clear_notice_presentations()

func open_task() -> void:
	var trigger: Button=shell.phone_chrome.task_button
	check(not trigger.disabled,"phone task trigger is enabled before opening")
	await click(trigger);await frames(5)
	check(is_instance_valid(shell.modal),"actual task trigger opens task panel")
	check(shell.phone_chrome.task_button.disabled,"modal blocks underlying task trigger")

func run() -> void:
	check(load("res://tests/native_test_isolation.gd").is_isolated_save(),"single-exit run uses isolated save")
	if failures:quit(2);return
	create_timer(180).timeout.connect(func():push_error("Single task exit deadline exceeded");quit(2))
	if not output.is_empty():DirAccess.make_dir_recursive_absolute(output)
	state=root.get_node("State");state.developer_mode=true;state.d=state.initial()
	shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames(8);shell.set_process(false)
	for dimensions: Vector2i in [Vector2i(320,568),Vector2i(390,844),Vector2i(844,390),Vector2i(1440,900)]:
		for page: String in ["phone_home","settings","bonsai"]:
			await prepare_phone(dimensions,page)
			var original: String=JSON.stringify(state.d)
			# Same trigger repeatedly opens; pointer, Enter, Space and Escape each
			# dismiss only this task and keep the originating phone page unchanged.
			for exit_method: String in ["pointer","enter","space","escape"]:
				await open_task()
				if not is_instance_valid(shell.modal):quit(2);return
				var resume:=assert_single_exit()
				check(resume.text=="×" and resume.tooltip_text=="返回游戏","shared × retains explicit return tooltip")
				check(root.gui_get_focus_owner()==shell.modal,"pointer entry keeps close unoutlined")
				check(find("JournalScroll").scroll_vertical==0,"initial focus keeps current objective at top")
				check(not find("JournalHistory").visible,"repeat opens reset only the presentation history fold")
				if exit_method=="pointer":await click(resume)
				elif exit_method=="enter":await keyboard(KEY_TAB);await keyboard(KEY_ENTER)
				elif exit_method=="space":await keyboard(KEY_TAB);await keyboard(KEY_SPACE)
				else:await keyboard(KEY_ESCAPE)
				await frames(5)
				check(not is_instance_valid(shell.modal),"single task dismisses with "+exit_method)
				check(not shell.phone_chrome.task_button.disabled,"phone input resumes after "+exit_method)
				check(state.d.native.page==page,"return keeps originating phone page: "+page)
				check(JSON.stringify(state.d)==original,"task open/return grants no progress or preference change")
				check(shell.find_children("NativeModalOverlay","",true,false).is_empty(),"no stale overlay survives repeat dismissal")
		# Real earned-card model is seeded only in this isolated presentation
		# fixture. Subpage Back remains distinct from the sole top-level exit.
		await prepare_phone(dimensions)
		state.d.items.headphone=true;state.d.items.waterDrop=true
		state.d.native.log=[]
		for index in 90:state.d.native.log.append({"text":"测试历史 %d：仅展示已知记录。"%index,"time":"fixture"})
		var original: String=JSON.stringify(state.d)
		await open_task();assert_single_exit()
		check(find("JournalObservationCompare")!=null,"available earned cards keep optional clue comparison")
		var controls: Array[Control]=[]
		shell._modal_focus_controls(shell.modal,controls)
		for index in controls.size()+2:
			await keyboard(KEY_TAB)
			var focused: Control=root.gui_get_focus_owner()
			check(focused!=null and (focused==shell.modal or shell.modal.is_ancestor_of(focused)),"Tab remains in task modal")
		await keyboard(KEY_TAB,true)
		check(shell.modal.is_ancestor_of(root.gui_get_focus_owner()) or root.gui_get_focus_owner()==shell.modal,"Shift-Tab remains in task modal")
		await click(await reveal_control("JournalHistoryToggle"));await frames(5)
		var scroll:=find("JournalScroll") as ScrollContainer
		scroll.scroll_vertical=int(scroll.get_v_scroll_bar().max_value);await frames(6)
		check(scroll.scroll_vertical>0,"long history is genuinely scrolled")
		assert_single_exit()
		await take("%dx%d-single-task-exit-long-history"%[dimensions.x,dimensions.y])
		await click(find("JournalResume"));await frames(5)
		check(not is_instance_valid(shell.modal),"fixed return remains clickable at end of long history")
		await open_task()
		await click(await reveal_control("JournalObservationCompare"));await frames(8)
		check(find("ObservationComparison")!=null,"task opens actual clue comparison subpage")
		check(find("ObservationJournalReturn")!=null,"subpage retains distinct Back to journal")
		check(find("PhoneNav_close")!=null,"comparison keeps shared close independently of Back")
		await take("%dx%d-clue-back-preserved"%[dimensions.x,dimensions.y])
		await click(await reveal_control("ObservationChoice_item_headphone"));await frames(5)
		await click(await reveal_control("ObservationChoice_item_waterDrop"));await frames(5)
		await click(await reveal_control("ObservationCompare"));await frames(5)
		check(shell.observation_comparison_session.stage=="comparison","actual clue comparison still works")
		check(find("ObservationReturn")!=null,"clue result retains its separate try-idea return")
		var chosen: Array=shell.observation_comparison_session.selected.duplicate()
		await click(await reveal_control("ObservationJournalReturn"));await frames(8)
		assert_single_exit()
		check(find("NativeJournal")!=null,"clue Back returns to task rather than exiting game overlay")
		await take("%dx%d-single-task-exit-after-clue-back"%[dimensions.x,dimensions.y])
		await click(await reveal_control("JournalObservationCompare"));await frames(8)
		check(shell.observation_comparison_session.selected==chosen,"subpage round trip preserves selected clues")
		await keyboard(KEY_ESCAPE)
		check(not is_instance_valid(shell.modal),"clue Escape keeps original dismiss semantics")
		check(JSON.stringify(state.d)==original,"history and clue navigation remain read-only")
	# Keep the same open journal and clue sessions across portrait/landscape
	# relayout. No re-mount, scroll ownership change or duplicate return is needed.
	await prepare_phone(Vector2i(390,844))
	state.d.items.headphone=true;state.d.items.waterDrop=true
	await open_task()
	var mounted: Control=find("NativeJournal")
	for dimensions: Vector2i in [Vector2i(844,390),Vector2i(320,568),Vector2i(1440,900),Vector2i(390,844)]:
		if capture_enabled:DisplayServer.window_set_size(dimensions)
		root.size=dimensions;shell.size=Vector2(dimensions);shell._layout();await frames(8)
		assert_single_exit()
		check(find("NativeJournal")==mounted,"resize retains the current task instance")
	await click(await reveal_control("JournalObservationCompare"));await frames(8)
	var comparison: Control=find("ObservationComparison")
	for dimensions: Vector2i in [Vector2i(844,390),Vector2i(320,568),Vector2i(390,844)]:
		if capture_enabled:DisplayServer.window_set_size(dimensions)
		root.size=dimensions;shell.size=Vector2(dimensions);shell._layout();await frames(8)
		check(find("ObservationComparison")==comparison,"resize retains the independent clue instance")
		check(Rect2(Vector2.ZERO,Vector2(dimensions)).encloses(shell.modal_panel.get_global_rect()),"clue sheet stays in resized viewport")
	await click(await reveal_control("ObservationJournalReturn"));await frames(8)
	assert_single_exit()
	await keyboard(KEY_ESCAPE)
	check(not is_instance_valid(shell.modal),"resized task still exits exactly once")
	await shell.shutdown();shell.queue_free();await frames()
	if not output.is_empty():
		var file:=FileAccess.open(output.path_join("task-single-exit-report.json"),FileAccess.WRITE)
		if file:file.store_string(JSON.stringify({"checks":checks,"failures":failures,"real_graphics":capture_enabled,"shots":shots,"scope":"Actual Main input with isolated C1 fixtures; not earned campaign or manual acceptance."},"\t"));file.close()
	print("TASK_SINGLE_EXIT: %d checks; %d failures; real_graphics=%s"%[checks,failures,str(capture_enabled)])
	quit(1 if failures else 0)
