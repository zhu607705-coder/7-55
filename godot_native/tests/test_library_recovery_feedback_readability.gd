extends "res://tests/test_library_recovery_feedback.gd"
## Full actual Main rendering/layout metrics; no fixed card/action resize to fit text.
const FEEDBACK_COPY=["材料已收取，可查看原件","原件已识别，可提交","待取得本栏原件","材料不符，请核对本栏名称","材料已收取，请点查看阅读","尚未取得本栏证明原件","请先开启本次恢复申请"]

func run() -> void:
	state=root.get_node("State"); state.developer_mode=true; earn_followup(); state.d=recovery_earned.duplicate(true)
	shell=load("res://scenes/main.tscn").instantiate(); root.add_child(shell); await frames(); shell.set_process(false)
	var results: Array=[]
	for size in [Vector2i(390,844),Vector2i(430,860),Vector2i(1440,900)]:
		root.size=size; shell.size=Vector2(size); await frames(); await restore_followup(recovery_earned)
		for evidence in Recovery.RECOVERY:
			var id=str(evidence[0])
			var card: Button=node("LibraryRecoverySlot_"+id)
			var target: Label=node("LibraryRecoveryFeedback_"+id)
			var action: Label=node("LibraryRecoveryAction_"+id)
			var card_geometry=Rect2(card.position,card.size)
			var action_geometry=Rect2(action.position,action.size)
			for copy: String in FEEDBACK_COPY:
				# Supply only the presentation string to the same built label. This
				# tests every possible copy independently of ownership/story gating.
				target.text=copy; await frames()
				await reveal("LibraryRecoveryFeedback_"+id)
				var font_size=target.get_theme_font_size("font_size")
				var physical_size=font_size*target.get_global_transform_with_canvas().get_scale().y
				check(font_size==13,"feedback authored font size is13")
				check(physical_size>=12,"feedback effective font size is at least12 pixels: "+str(physical_size))
				check(target.get_line_count()==target.get_visible_line_count(),"all wrapped feedback lines fit: "+copy)
				check(Rect2(Vector2.ZERO,card.size).encloses(Rect2(target.position,target.size)),"feedback remains inside original card: "+copy)
				check(not Rect2(target.position,target.size).intersects(action_geometry),"feedback avoids action: "+copy)
				check(Rect2(card.position,card.size)==card_geometry and Rect2(action.position,action.size)==action_geometry,"feedback does not resize card/action")
				check(card.size==Vector2(315,116) and action_geometry==Rect2(241,70,62,40),"original card/action dimensions are retained")
				var font: Font=target.get_theme_font("font")
				var measured=font.get_multiline_string_size(copy,HORIZONTAL_ALIGNMENT_LEFT,target.size.x,font_size,-1,TextServer.BREAK_MANDATORY|TextServer.BREAK_WORD_BOUND|TextServer.BREAK_ADAPTIVE)
				check(measured.y<=target.size.y,"font's wrapped ink height fits feedback bounds")
				results.append({"viewport":str(size),"card":id,"text":copy,"authoredFontSize":font_size,"physicalFontSize":physical_size,"lines":target.get_line_count(),"visibleLines":target.get_visible_line_count(),"labelSize":str(target.size),"wrappedTextSize":str(measured)})
	await shell.shutdown(); shell.queue_free(); await frames()
	var report={"checks":checks,"failures":failures,"measurements":results,"gui_used":false}
	var path=OS.get_environment("UI_QA_REPORT")
	if not path.is_empty():
		var file=FileAccess.open(path,FileAccess.WRITE); file.store_string(JSON.stringify(report,"\t")); file.close()
	print("LIBRARY_RECOVERY_FEEDBACK_READABILITY: ",checks," checks / ",failures," failures; ",results.size()," actual Main text/card/viewport cases")
	quit(1 if failures else 0)
