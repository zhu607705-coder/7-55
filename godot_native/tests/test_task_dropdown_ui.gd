extends "res://tests/test_task_flat_surface.gd"
## Production regression: main screenshots are real new-game/controller progress.
## The separately named stress case injects history length, never quest facts.
var scenario=""
var states: Array=[]
func take(id: String) -> void:
	await frames(10)
	if not capture_enabled:return
	await RenderingServer.frame_post_draw
	var picture:=root.get_texture().get_image()
	var path:=output.path_join(id+".png")
	check(picture.save_png(path)==OK,"actual native render saved: "+id)
	shots.append({"path":path,"width":picture.get_width(),"height":picture.get_height(),"fixture":"Injected history stress, not ordinary content" if "STRESS" in id else "Real new-game/controller progress; not checkpoint injection. Automated actual renderer, not a manual campaign claim."})
func controller(id: String,value: Variant=null) -> Dictionary:return state.act(id,value)
func actual_progress(stage: int) -> void:
	state.new_game()
	controller("c1_start_alarm");controller("c1_dismiss_alarm");controller("c1_wake");controller("c1_enter_home")
	if stage>=1:
		state.open_page("wechat");controller("c1_friend")
		controller("c1_scatter_complete",{"phase":4,"elapsedMs":19322,"skipped":false})
	if stage>=2:
		state.open_page("checkin");controller("c1_absence")
	if stage>=3:
		controller("c1_network","移动数据");state.open_page("tiyi");controller("c1_tiyi_digit")
	state.open_page("phone_home")
	check(state.validate_snapshot(state.d),"actual controller progress validates")
	state.d.native.settings.music=false;state.d.native.settings.effects=false;state.d.native.settings.volume=0

func settle() -> void:
	await create_timer(.22).timeout
	await frames(4)

func verify_dropdown() -> void:
	check(shell.modal.has_meta("journal_shared_shell"),"task uses shared real phone overlay shell")
	var shared: Dictionary=shell.modal.get_meta("journal_shared_shell")
	check(shell.modal.get_parent()==shell.phone and shell.modal.z_index==65,"task uses the same phone parent and compositing layer as control center")
	check(shared.root.size.x==378 and is_equal_approx(shared.root.scale.x,424.0/378.0),"same authoring canvas and phone overlay scale")
	check(shared.title.get_theme_font_size("font_size")==16,"same 16 logical header type")
	check(shared.title.get_theme_font("font")==load("res://scripts/ui/native_typography.gd").body_font(),"same Regular header family, no task-only bold title")
	check(shared.close.text=="×" and shared.close.size==Vector2(27,27),"same native close glyph and 27px control")
	check(shared.close.position==Vector2(337,12),"same close placement")
	check(not shell.modal_panel.has_meta("journal_slide"),"task has no added slide tween")
	check(shell.modal_panel.get_global_rect().position.distance_to(shell.phone_chrome.get_global_rect().position)<.5,"shared overlay starts on the actual phone origin")
	check(Rect2(Vector2.ZERO,Vector2(root.size)).encloses(shell.modal_panel.get_global_rect()),"all scaled task content stays within viewport")
	if find("NativeJournal")!=null:
		check(find("JournalCurrentCard")!=null and find("JournalHistoryCard")!=null,"real task and history have existing phone-panel grouping")
		check(find("JournalResume")==shared.close,"single exit is the actual shared close control")

func capture_state(label: String, dimensions: Vector2i, stress:=false) -> void:
	var saved: Dictionary=state.d.duplicate(true)
	await take("%dx%d-%s"%[dimensions.x,dimensions.y,label])
	check(state.d==saved,"capture and viewing are read-only")
	states.append({"id":label,"viewport":str(dimensions),"panel":str(shell.modal_panel.get_global_rect()) if is_instance_valid(shell.modal_panel) else "control-center reference","objective":state.objective(),"historyCount":state.d.native.log.size(),"digits":state.d.digits.duplicate(),"origin":"separately labeled injected history stress only" if stress else "real State.new_game and authored State.act chain; no checkpoint or injected quest/log content"})

func run() -> void:
	if not load("res://tests/native_test_isolation.gd").is_isolated_save():quit(2);return
	create_timer(180).timeout.connect(func():push_error("Task shared-overlay deadline");quit(2))
	if not output.is_empty():DirAccess.make_dir_recursive_absolute(output)
	state=root.get_node("State")
	for dimensions: Vector2i in [Vector2i(390,844),Vector2i(1440,900),Vector2i(320,568),Vector2i(844,390)]:
		if capture_enabled:DisplayServer.window_set_size(dimensions)
		root.size=dimensions
		for stage: int in [0,1,2,3]:
			actual_progress(stage)
			shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell)
			await frames(12);shell.set_process(false);shell._layout();shell._clear_notice_presentations();await frames(4)
			if stage==0:
				shell._on_phone_page("control_center");await frames(8)
				await capture_state("00-existing-control-center",dimensions)
				shell._on_phone_action("native_control_center_close",null);await frames(6)
			var before: Dictionary=state.d.duplicate(true)
			await click(shell.phone_chrome.task_button);await settle()
			check(is_instance_valid(shell.modal),"actual task trigger opens candidate")
			if not is_instance_valid(shell.modal):quit(2);return
			verify_dropdown()
			var label: String=["01-real-new-game","02-real-code-scattered","03-real-first-clue","04-real-two-clues"][stage]
			if stage==0:check(shell.modal_panel.size.y<300,"daily first task stays compact without filler")
			await capture_state(label,dimensions)
			if stage==3:
				await click(await reveal_control("JournalHistoryToggle"));await settle();verify_dropdown()
				await capture_state("05-real-history-expanded",dimensions)
				await click(await reveal_control("JournalHistoryToggle"));await settle()
				check(find("JournalCluesCard")==null and find("JournalObservationCompare")==null,"no extra task section or focus target after earning clues")
			check(state.d==before,"task and history preserve earned progress")
			await press_key(KEY_ESCAPE);await frames(4)
			check(not is_instance_valid(shell.modal),"Escape dismisses candidate exactly once")
			if stage==0:
				# Same phone-only backdrop behavior as existing Control Center.
				await click(shell.phone_chrome.task_button);await settle()
				var shade: Button=find("JournalDropdownBackdrop")
				var bottom:=shade.get_global_rect().end-Vector2(20,20)
				motion(bottom);mouse(bottom,true);mouse(bottom,false);await frames(5)
				check(not is_instance_valid(shell.modal),"tapping exposed backdrop retracts short task")
			await shell.shutdown();shell.queue_free();await frames(5)
		# This pressure case is deliberately not used as the daily-state design.
		actual_progress(3)
		state.d.native.log=[]
		for index in 90:state.d.native.log.append({"text":"压力测试历史 %d：仅用于验证滚动，不代表日常任务内容。"%index,"time":"stress"})
		shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell)
		await frames(10);shell.set_process(false);shell._layout();shell._clear_notice_presentations()
		await click(shell.phone_chrome.task_button);await settle()
		await click(await reveal_control("JournalHistoryToggle"));await settle()
		var scroll:=find("JournalScroll") as ScrollContainer
		scroll.scroll_vertical=int(scroll.get_v_scroll_bar().max_value);await settle();verify_dropdown()
		check(scroll.scroll_vertical>0,"separately labeled long-history stress really scrolls")
		await capture_state("08-STRESS-only-long-history",dimensions,true)
		await click(find("JournalResume"));await settle()
		check(not is_instance_valid(shell.modal),"fixed return works at the end of long history")
		await shell.shutdown();shell.queue_free();await frames(5)
	if not output.is_empty():
		var file:=FileAccess.open(output.path_join("task-dropdown-report.json"),FileAccess.WRITE)
		file.store_string(JSON.stringify({"checks":checks,"failures":failures,"realGraphics":capture_enabled,"states":states,"shots":shots,"scope":"Real new-game/controller states; stress history separately labeled. Source shared-overlay regression."},"\t"));file.close()
	print("TASK_SHARED_UI: %d checks; %d failures; real_graphics=%s"%[checks,failures,str(capture_enabled)])
	quit(1 if failures else 0)
