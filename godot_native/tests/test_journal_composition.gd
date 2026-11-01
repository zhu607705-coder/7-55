extends SceneTree
const PaperInk=preload("res://scripts/ui/paper_ink_material.gd")
const TactileMaterial=preload("res://scripts/ui/tactile_button_material.gd")
const Ui=preload("res://scripts/ui/native_ui_theme.gd")
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
		# The reviewed paper/ink skin changes the reading face, not JOURNAL-3's
		# single-column composition. A plain paper panel is not a notebook shell.
		var paper:StyleBox=shell.modal_panel.get_theme_stylebox("panel")
		check(paper is StyleBoxFlat and paper.bg_color==PaperInk.PAPER,"single-page text has the exact opaque warm paper face")
		check(shell.modal_panel.get_script()==null,"single-page panel has no fabricated notebook shell renderer")
		for side:int in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]:
			check(paper.get_margin(side)==8,"paper retains the original eight-pixel reading inset")
		check(resume.size.x<journal.size.x,"resume is a compact primary action, not another full-width strip")
		check(resume.size.y>=44,"compact action retains touch height")
		for child: Node in journal.get_children():
			if child is Button:
				var face: StyleBox=child.get_theme_stylebox("normal")
				var caption: float=child.get_theme_font("font").get_string_size(child.text,HORIZONTAL_ALIGNMENT_LEFT,-1,child.get_theme_font_size("font_size")).x
				check(caption+face.get_margin(SIDE_LEFT)+face.get_margin(SIDE_RIGHT)<=child.size.x+.01,"journal action fits single line: "+child.name)
				check(journal.get_global_rect().encloses(child.get_global_rect()),"journal action stays inside reading column: "+child.name)
				check(face is TactileMaterial and face.paper_ink and face.variant=="ghost" and face.bg_color.a==0,"journal action is a transparent paper-ink key: "+child.name)
				for color_role:String in ["font_color","font_hover_color","font_pressed_color","font_hover_pressed_color","font_focus_color","font_disabled_color"]:
					var ink:Color=child.get_theme_color(color_role)
					check(ink.a==1 and Ui._contrast(ink,PaperInk.PAPER)>=4.5,"journal action ink remains readable in "+color_role+": "+child.name)
				var focus:StyleBox=child.get_theme_stylebox("focus")
				check(focus is StyleBoxFlat and focus.bg_color.a==0 and focus.border_color==PaperInk.FOCUS and focus.get_border_width_min()>=1 and Ui._contrast(focus.border_color,PaperInk.PAPER)>=3,"journal keyboard focus is visible without covering its label: "+child.name)
		check(journal.find_child("JournalObjective",true,false).text==state.objective(),"objective remains controller-owned")
		check(shell.modal.find_child("NotebookPageIndex",true,false)==null,"single page has no unselected folder tab")
		var objective:Label=journal.find_child("JournalObjective",true,false)
		check(objective.get_theme_font_size("font_size")==18,"locked heading size remains 18")
		check(resume.get_theme_font_size("font_size")==14,"locked button size remains 14")
		check(resume.get_meta("tactile_paper_ink",false) and resume.get_meta("tactile_variant","")=="ghost","journal actions use the reviewed plain paper-ink variant")
		check(root.gui_get_focus_owner()==resume and resume.focus_mode==Control.FOCUS_ALL,"journal retains initial keyboard focus and focus ownership")
		check(JSON.stringify(state.d)==before,"composition changes no earned state or save")
		check(Rect2(Vector2.ZERO,Vector2(dimensions)).encloses(shell.modal_panel.get_global_rect()),"single-page layout remains inside viewport")
		shell._close_modal();await frames()
	await shell.shutdown();shell.queue_free();await frames()
	print("Journal composition: ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)
