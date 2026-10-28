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
	var state:=root.get_node("State");state.developer_mode=true;state.d=state.initial()
	var shell:Control=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames()
	for dimensions:Vector2i in [Vector2i(390,844),Vector2i(844,390),Vector2i(1440,900)]:
		root.size=dimensions;shell.size=Vector2(dimensions)
		state.begin_checkpoint("c2-dorm-exit");shell._refresh();shell.mobile_world=true;shell._layout();await frames()
		var before:String=JSON.stringify(state.d)
		shell._show_journal();await frames()
		var journal:Control=shell.modal.find_child("NativeJournal",true,false)
		var resume:Button=journal.find_child("JournalResume",true,false)
		check(journal.find_child("JournalScenePreview",true,false)==null,"selected single page does not duplicate the retained world into a thumbnail")
		check(shell.modal.color.a==0.0,"none backdrop preserves world visibility")
		check(shell.modal_panel.get_theme_stylebox("panel") is StyleBoxEmpty,"single-page text has no fabricated notebook shell")
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
		check(resume.get_meta("tactile_variant","")=="secondary","journal actions use neutral readable keys")
		check(JSON.stringify(state.d)==before,"composition changes no earned state or save")
		check(Rect2(Vector2.ZERO,Vector2(dimensions)).encloses(shell.modal_panel.get_global_rect()),"single-page layout remains inside viewport")
		shell._close_modal();await frames()
	await shell.shutdown();shell.queue_free();await frames()
	print("Journal composition: ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)
