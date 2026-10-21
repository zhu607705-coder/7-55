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
		var preview:Control=journal.find_child("JournalScenePreview",true,false)
		var resume:Button=journal.find_child("JournalResume",true,false)
		check(preview!=null,"world journal has its actual scene thumbnail")
		check(preview.get_child(0).texture==shell.world.background,"thumbnail uses the actual scene artwork, without recapturing HUD or fabricated location art")
		check(resume.size.x<journal.size.x,"resume is a compact primary action, not another full-width strip")
		check(resume.size.y>=44,"compact action retains touch height")
		check(journal.find_child("JournalObjective",true,false).text==state.objective(),"objective remains controller-owned")
		check(shell.modal.find_child("NotebookPageIndex",true,false)!=null,"index identifies the actual mounted journal page")
		var title_index:Control=shell.modal.find_child("NotebookPageIndex",true,false)
		check(title_index.size.x>=96 and title_index.size.y<=48,"actual title has horizontal readable width, not one-character vertical wrapping")
		check(title_index.get_parent().size.y<=48,"page index does not stretch close into a tall column")
		check(JSON.stringify(state.d)==before,"composition changes no earned state or save")
		check(shell.modal_panel.get_global_rect().encloses(preview.get_global_rect()),"scene thumbnail stays in the viewport-bounded folder")
		shell._close_modal();await frames()
	await shell.shutdown();shell.queue_free();await frames()
	print("Journal composition: ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)
