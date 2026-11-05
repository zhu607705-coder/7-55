extends SceneTree
var checks:=0
var failures:=0
func _initialize()->void: run.call_deferred()
func check(ok:bool,message:String)->void:
	checks+=1
	if not ok: failures+=1;push_error(message)
func frames()->void:
	for unused in 5: await process_frame
func run()->void:
	# Cross-chapter composition must not write to a real player's save.
	if not load("res://tests/native_test_isolation.gd").is_isolated_save():quit(2);return
	var state:=root.get_node("State");state.developer_mode=true;state.d=state.initial()
	var shell:Control=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames()
	for dimensions:Vector2i in [Vector2i(390,844),Vector2i(844,390),Vector2i(1440,900)]:
		root.size=dimensions;shell.size=Vector2(dimensions)
		check(state.begin_checkpoint("c2-dorm-exit"),"source world fixture loads");shell._refresh();shell.mobile_world=true;shell._layout();await frames()
		var before:String=JSON.stringify(state.d)
		shell._show_journal();await frames()
		var journal:Control=shell.modal.find_child("NativeJournal",true,false)
		var resume:Button=shell.modal.find_child("JournalResume",true,false)
		check(shell.modal.find_child("NativeModalClose",true,false)==null,"task has one contextual return instead of a duplicate close")
		check(not shell.modal.find_child("JournalScroll",true,false).is_ancestor_of(resume),"return stays outside the scrolling task body")
		check(resume.text=="返回现场","world task keeps its distinct scene-return label")
		check(journal.find_child("JournalScenePreview",true,false)==null,"selected single page does not duplicate the retained world into a thumbnail")
		check(is_equal_approx(shell.modal.color.a,0.42),"flat task scrim separates readable task from retained world")
		var panel_style: StyleBox=shell.modal_panel.get_theme_stylebox("panel")
		check(panel_style is StyleBoxFlat and panel_style.shadow_size==0,"task panel is a flat ink-edged surface without paper material or elevation")
		check(resume.size.x<journal.size.x,"resume is a compact primary action, not another full-width strip")
		check(resume.size.y>=44,"compact action retains touch height")
		for child: Node in journal.get_children():
			if child is Button:
				var face: StyleBox=child.get_theme_stylebox("normal")
				var caption: float=child.get_theme_font("font").get_string_size(child.text,HORIZONTAL_ALIGNMENT_LEFT,-1,child.get_theme_font_size("font_size")).x
				check(caption+face.get_margin(SIDE_LEFT)+face.get_margin(SIDE_RIGHT)<=child.size.x+.01,"journal action fits single line: "+child.name)
				check(journal.get_global_rect().encloses(child.get_global_rect()),"journal action stays inside reading column: "+child.name)
		check(journal.find_child("JournalObjective",true,false).text==state.objective(),"objective remains controller-owned")
		check(shell.modal.find_child("NotebookPageIndex",true,false)==null,"single page has no unselected folder tab")
		var objective:Label=journal.find_child("JournalObjective",true,false)
		check(objective.get_theme_font_size("font_size")==18,"locked heading size remains 18")
		check(resume.get_theme_font_size("font_size")==14,"locked button size remains 14")
		check(resume.get_meta("phone_button_role","")=="action" and resume.get_node("TactileMaterialState").phone_flat,"task actions use the flat phone material")
		check(objective.get_theme_color("font_shadow_color").a==0.0,"task objective has clear unshadowed ink")
		check(shell.modal.find_child("JournalScroll",true,false).follow_focus,"task history follows keyboard focus")
		check(JSON.stringify(state.d)==before,"composition changes no earned state or save")
		check(Rect2(Vector2.ZERO,Vector2(dimensions)).encloses(shell.modal_panel.get_global_rect()),"single-page layout remains inside viewport")
		# Keep the original explicit world-return behavior, not only its caption.
		# A retained world can be mounted while the persisted mode still says phone.
		state.d.runtimeMode="phone"
		var expected: Dictionary=state.d.duplicate(true);expected.runtimeMode="rpg"
		var position_before: Vector2=shell.world.player
		for down: bool in [true,false]:
			var click:=InputEventMouseButton.new();click.position=resume.get_global_rect().get_center();click.global_position=click.position
			click.button_index=MOUSE_BUTTON_LEFT;click.pressed=down
			Input.parse_input_event(click);Input.flush_buffered_events()
		await frames()
		check(not is_instance_valid(shell.modal),"world return dismisses task with actual pointer input")
		check(state.d==expected,"world return preserves the original persisted mode change without advancing plot")
		check(shell.world.player==position_before,"world return does not move the retained actor")
		check(shell.world_frame.is_visible_in_tree(),"world return restores the retained scene")
		shell._show_journal();await frames()
		for down: bool in [true,false]:
			var escape:=InputEventKey.new();escape.keycode=KEY_ESCAPE;escape.physical_keycode=KEY_ESCAPE;escape.pressed=down
			Input.parse_input_event(escape);Input.flush_buffered_events()
		await frames()
		check(not is_instance_valid(shell.modal),"world Escape retains original dismissal semantics")
		check(state.d==expected,"world Escape does not advance plot or change destination")
	await shell.shutdown();shell.queue_free();await frames()
	print("Journal composition: ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)
