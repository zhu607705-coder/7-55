extends SceneTree
const Closure=preload("res://scripts/presentation/chapter4_lamp_closure.gd")
var checks:=0
var failures:=0
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func inspect_summaries(view:Control,data:Dictionary)->void:
	var ts:=TextServerManager.get_primary_interface()
	var rid:RID=view.SummaryFont.get_rids()[0]
	for first:Dictionary in data.questions[0].options:
		for second:Dictionary in data.questions[1].options:
			view.answers={str(data.questions[0].id):first.id,str(data.questions[1].id):second.id};view.stage="final";view._rebuild()
			var one:Label=view.column.get_node("LampAnswerSummary1")
			var two:Label=view.column.get_node("LampAnswerSummary2")
			check(one.get_theme_font("font")==two.get_theme_font("font") and one.get_theme_font("font")==view.SummaryFont,"Both complete summary lines share the bundled font")
			check(one.get_theme_font_size("font_size")==16 and two.get_theme_font_size("font_size")==16,"Original summary sizes stay 16px")
			check(one.text=="求学所向  ·  "+str(first.label) and two.text=="成人所守  ·  "+str(second.label),"Existing summary content and separator remain unchanged")
			for summary:Label in [one,two]:
				var text:=TextLine.new();text.add_string(summary.text,summary.get_theme_font("font"),16)
				for glyph:Dictionary in ts.shaped_text_get_glyphs(text.get_rid()):
					check(glyph.font_rid==rid and int(glyph.index)>0,"Every CJK glyph, Latin punctuation and space is shaped by the same face")
			check(view.buttons.size()==1 and view.buttons[0].text=="继续" and not view.buttons[0].has_theme_font_override("font"),"The existing button remains untouched")
			var hint:Label=view.column.get_child(view.column.get_child_count()-1)
			check(hint.text=="按 Space 或 Enter 继续" and hint.get_theme_font_size("font_size")==14 and not hint.has_theme_font_override("font"),"Unrelated bottom hint content and typography remain untouched")
func run()->void:
	var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/native/chapter4-native-source.json"))
	var view:=Closure.new();view.configure({"questions":data.questions,"settings":{},"lampPresentation":"layered"});root.add_child(view);view.size=Vector2(1180,812)
	inspect_summaries(view,data)
	view.queue_free();await process_frame;await process_frame
	var state:=root.get_node("State");state.begin_checkpoint("c4-755-closure")
	var shell:Control=load("res://scenes/main.tscn").instantiate();root.add_child(shell)
	await process_frame;await process_frame
	var controller:RefCounted
	for module in state.modules:
		if str(module.get_script().resource_path)=="res://scripts/chapters/chapter4.gd":controller=module
	var issued:Dictionary=controller.dispatch(state.d,"c4_lamp_start")
	# Isolate typography after the independently tested exterior-door prelude.
	# This fixture inspects presentation only and never submits completion.
	issued.game.native_exterior_presented=true
	shell._open_game_now(issued.game);shell.active_game.set_process(false)
	var main_view:Control=shell.active_game.lamp_view
	check(main_view.get_theme_font("font")==shell.font,"Real Main entry retains the original project theme")
	inspect_summaries(main_view,data)
	shell.queue_free();await process_frame;await process_frame
	print("CHAPTER4_LAMP_FONT ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
