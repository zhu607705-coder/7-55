extends "res://tests/test_portrait_exploration.gd"
## Isolated checkpoint and log-size fixtures on actual Main controls. Optional
## graphical capture uses the real native renderer; not earned campaign proof.
var output:=OS.get_environment("UI_CAPTURE_DIR")
var capture_enabled:=not output.is_empty() and DisplayServer.get_name()!="headless"
var shots: Array=[]
func find(id: String) -> Control: return shell.modal.find_child(id,true,false)
func reveal_control(id: String) -> Control:
	var target:=find(id)
	var scroll:=find("JournalScroll") as ScrollContainer
	if scroll.is_ancestor_of(target):scroll.ensure_control_visible(target)
	await frames(8)
	return target
func press_key(code: int) -> void:
	for down: bool in [true,false]:
		var e:=InputEventKey.new();e.keycode=code;e.physical_keycode=code;e.pressed=down;event(e);await process_frame
	await frames(8)
func take(id: String) -> void:
	await frames(10)
	if not capture_enabled:return
	await RenderingServer.frame_post_draw
	var image:=root.get_texture().get_image()
	var path:=output.path_join(id+".png")
	var error:=image.save_png(path)
	check(error==OK,"actual native render saved: "+id)
	shots.append({"path":path,"width":image.get_width(),"height":image.get_height(),"fixture":"Isolated C1 checkpoint; authored objective; fixture log length. Not earned progress."})
func seed_c1_fixture(id: String="c1-code-hunt") -> bool:
	var packed:=FileAccess.get_file_as_bytes("res://data/native/developer_checkpoints.json.gz")
	var data: Dictionary=JSON.parse_string(packed.decompress_dynamic(4*1024*1024,FileAccess.COMPRESSION_GZIP).get_string_from_utf8())
	for checkpoint: Dictionary in data.get("checkpoints",[]):
		if checkpoint.id==id:
			state.story_reset.emit()
			state.d=state.merge_defaults(state.initial(),checkpoint.state)
			state.d.native.chapter=1
			return true
	return false
func check_digit_projection() -> void:
	var view: VBoxContainer=load("res://scripts/ui/native_journal_view.gd").new()
	var snapshot: Dictionary={"native":{"chapter":1},"actOne":{"phase":"prologue"},"flags":{"codeScattered":true},"digits":{"d1":"0","d2":null,"d3":"9","d4":null}}
	var before:=JSON.stringify(snapshot)
	view.configure_digits(snapshot)
	check(view.digit_slots==["0","?","9","?"],"partial earned digits stay ordered; no unknown value is disclosed")
	check(JSON.stringify(snapshot)==before,"partial digit projection is read-only")
	snapshot.native.chapter=2;view.configure_digits(snapshot)
	check(view.digit_slots.is_empty(),"later chapter does not inherit prologue digit status")
	snapshot.native.chapter=1;snapshot.actOne.phase="friend_message_required";view.configure_digits(snapshot)
	check(view.digit_slots.is_empty(),"finished prologue does not inherit digit status")
	view.free()
func run() -> void:
	check(load("res://tests/native_test_isolation.gd").is_isolated_save(),"task surface run uses isolated save")
	if failures:quit(2);return
	check_digit_projection()
	create_timer(120).timeout.connect(func():push_error("Task surface deadline exceeded");quit(2))
	if capture_enabled:DirAccess.make_dir_recursive_absolute(output)
	state=root.get_node("State");state.developer_mode=true;state.d=state.initial()
	shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames(8);shell.set_process(false)
	for dimensions: Vector2i in [Vector2i(430,860),Vector2i(390,844),Vector2i(320,568),Vector2i(1440,900),Vector2i(844,390)]:
		if capture_enabled:DisplayServer.window_set_size(dimensions)
		root.size=dimensions;shell.size=Vector2(dimensions)
		check(seed_c1_fixture(),"source first-chapter checkpoint data loads without runtime DEV access")
		state.d.native.page="phone_home";state.d.native.scene="";state.d.native.settings.volume=0
		shell.mobile_world=false;shell._refresh();shell._process(2);await frames(10);shell._layout();await frames(8)
		var original: String=JSON.stringify(state.d)
		shell._show_journal();await create_timer(.20).timeout;await frames(8)
		var journal:=find("NativeJournal")
		var resume:=find("JournalResume") as Button
		check(find("JournalObjective").text==state.objective(),"only actual current objective is displayed")
		check(not find("JournalHistory").visible,"history is collapsed on task entry")
		check(resume.text=="×" and resume.tooltip_text=="返回游戏","phone task uses shared close with authored return destination")
		check(find("NativeModalClose")==null,"task has no duplicate generic close")
		check(not find("JournalScroll").is_ancestor_of(resume),"single return stays in the fixed header")
		check(root.gui_get_focus_owner()==shell.modal,"pointer entry does not invent a default blue close outline")
		check(find("JournalScroll").scroll_vertical==0,"current objective is not auto-scrolled away on entry")
		check(Rect2(Vector2.ZERO,Vector2(dimensions)).encloses(shell.modal_panel.get_global_rect()),"flat task panel stays inside viewport "+str(dimensions))
		check(resume.size==Vector2(27,27),"return uses exact source control center target")
		var normal:=resume.get_theme_stylebox("normal") as StyleBoxFlat
		var hover:=resume.get_theme_stylebox("hover") as StyleBoxFlat
		check(normal!=null and normal.shadow_size==0,"return is a flat native surface")
		check(hover!=null and hover.bg_color!=normal.bg_color,"return hover has visible color feedback")
		check(resume.get_theme_stylebox("focus") is StyleBoxFlat,"return has visible keyboard focus outline")
		motion(Vector2(1,1));await take("%dx%d-task-current"%[dimensions.x,dimensions.y])
		await reveal_control("JournalResume");motion(resume.get_global_rect().get_center());await take("%dx%d-task-return-hover"%[dimensions.x,dimensions.y])
		await click(await reveal_control("JournalHistoryToggle"));await frames(8)
		check(find("JournalHistory").visible,"pointer opens actual history toggle")
		check(find("JournalHistory").get_child_count()==state.d.native.log.size() if not state.d.native.log.is_empty() else 1,"all earned records remain available")
		await take("%dx%d-task-history"%[dimensions.x,dimensions.y])
		await press_key(KEY_SPACE)
		check(not find("JournalHistory").visible,"Space closes the same history toggle")
		check(root.gui_get_focus_owner()==find("JournalHistoryToggle"),"collapse retains focus")
		check(JSON.stringify(state.d)==original,"pointer/keyboard/hover/history are read-only")
		await press_key(KEY_ESCAPE)
		check(not is_instance_valid(shell.modal),"Escape closes task without reopening it")
		# Empty and long logs are isolated presentation fixtures, never formal saves.
		for count: int in [0,1,129]:
			state.d.native.log=[]
			for i in count:state.d.native.log.append({"text":"测试记录 %d：保留已获得的记录，不显示未来任务。"%i,"time":"fixture"})
			original=JSON.stringify(state.d)
			shell._show_journal();await create_timer(.20).timeout;await frames(8)
			await click(await reveal_control("JournalHistoryToggle"));await frames(8)
			check(find("JournalHistory").get_child_count()==maxi(count,1),"record size retained: %d"%count)
			if count==0:check(find("JournalHistoryEmpty").text=="还没有历史记录。","empty state retains original wording")
			else:check(find("JournalHistoryRow0").text==state.d.native.log[0].text,"oldest record text retained")
			var scroll:=find("JournalScroll") as ScrollContainer
			if count==129:
				check(scroll.get_v_scroll_bar().max_value>scroll.size.y,"long records have genuine scroll extent")
				scroll.scroll_vertical=int(scroll.get_v_scroll_bar().max_value);await frames(8)
				check(scroll.scroll_vertical>0,"long record history scrolls to oldest entry")
				check(find("JournalResume").get_global_rect().end.y<=find("JournalScroll").get_global_rect().position.y,"single return remains above scrolling history")
				await take("%dx%d-task-long-history-bottom"%[dimensions.x,dimensions.y])
				journal=find("NativeJournal");journal.focus_control("JournalHistoryToggle");await frames(8)
				check(scroll.get_global_rect().grow(0.01).encloses(find("JournalHistoryToggle").get_global_rect()),"history toggle is visible within 0.01px transform tolerance")
			check(JSON.stringify(state.d)==original,"empty/partial/long records do not mutate quest state")
			await click(find("JournalResume"));await frames(8)
			check(not is_instance_valid(shell.modal),"single header return remains reachable for every record length")
		for checkpoint_id: String in ["c1-home","c1-dorm-card","c1-checkin"]:
			check(seed_c1_fixture(checkpoint_id),"authored digit-progress fixture loads: "+checkpoint_id)
			state.d.native.page="phone_home";state.d.native.scene="";state.d.native.settings.volume=0
			shell._refresh();await frames(8)
			original=JSON.stringify(state.d)
			shell._show_journal();await create_timer(.20).timeout;await frames(8)
			var digits_visible: bool=bool(state.d.flags.codeScattered)
			for key: String in ["d1","d2","d3","d4"]:
				digits_visible=digits_visible or (state.d.digits.get(key)!=null and not str(state.d.digits.get(key)).is_empty())
			check((find("JournalDigitProgress")!=null)==digits_visible,"digit progress follows actual discovery eligibility")
			if digits_visible:
				for index in 4:
					var value: Variant=state.d.digits.get("d%d"%(index+1))
					var expected: String=str(value) if value!=null and not str(value).is_empty() else "?"
					check(find("JournalDigitSlot%d"%index).text==expected,"digit order and masks preserve earned facts")
			await take("%dx%d-task-%s"%[dimensions.x,dimensions.y,checkpoint_id])
			check(JSON.stringify(state.d)==original,"digit status never changes a discovery")
			shell._close_modal();await frames(6)
	await shell.shutdown();shell.queue_free();await frames()
	if not output.is_empty():
		var file:=FileAccess.open(output.path_join("task-surface-report.json"),FileAccess.WRITE)
		if file:file.store_string(JSON.stringify({"checks":checks,"failures":failures,"real_graphics":capture_enabled,"shots":shots},"\t"));file.close()
	print("TASK_FLAT_SURFACE: %d checks; %d failures; real_graphics=%s"%[checks,failures,str(capture_enabled)])
	quit(1 if failures else 0)
