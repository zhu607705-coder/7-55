extends "res://tests/test_library_recovery_feedback.gd"
## Selected is a persistent value, despite using disabled input to prevent duplicates.
## Measure the resolved real Main control's sRGB colors, rather than theme constants.
func linear_component(value: float) -> float:
	return value/12.92 if value<=0.04045 else pow((value+0.055)/1.055,2.4)

func luminance(color: Color) -> float:
	return 0.2126*linear_component(color.r)+0.7152*linear_component(color.g)+0.0722*linear_component(color.b)

func contrast(ink: Color,fill: Color) -> float:
	var effective=fill.lerp(Color(ink,1),ink.a)
	var text_luma=luminance(effective); var fill_luma=luminance(fill)
	return (maxf(text_luma,fill_luma)+0.05)/(minf(text_luma,fill_luma)+0.05)

func run() -> void:
	state=root.get_node("State"); state.developer_mode=true; earn_followup(); state.d=bd_earned.duplicate(true)
	shell=load("res://scenes/main.tscn").instantiate(); root.add_child(shell); await frames(); shell.set_process(false)
	var results: Array=[]
	for size in [Vector2i(390,844),Vector2i(430,860),Vector2i(1440,900)]:
		root.size=size; shell.size=Vector2(size); await frames(); await restore_followup(bd_earned)
		var unselected: Button=node("Cc98BdSelect_24")
		var old_font=unselected.get_theme_color("font_color")
		var old_disabled=unselected.get_theme_color("font_disabled_color")
		var old_fill: StyleBoxFlat=unselected.get_theme_stylebox("normal")
		var old_fill_color=old_fill.bg_color
		await tap("Cc98BdSelect_24")
		var selected: Button=node("Cc98BdSelect_24")
		var ink=selected.get_theme_color("font_disabled_color")
		var fill: StyleBoxFlat=selected.get_theme_stylebox("disabled")
		var ratio=contrast(ink,fill.bg_color)
		check(selected.disabled and selected.text=="已选第1项","actual Main retains selected ordinal and duplicate prevention")
		check(is_equal_approx(ink.a,1) and is_equal_approx(fill.bg_color.a,1),"selected control's measured text and fill are opaque")
		check(selected.modulate==Color.WHITE and selected.self_modulate==Color.WHITE,"selected control has no extra color modulation")
		check(ratio>=4.5,"selected ordinal text contrast is at least4.5:1: "+str(ratio))
		var other: Button=node("Cc98BdSelect_25")
		check(other.get_theme_color("font_color")==old_font and other.get_theme_color("font_disabled_color")==old_disabled and other.get_theme_stylebox("normal").bg_color==old_fill_color,"unselected reply retains original palette")
		results.append({"viewport":str(size),"fontDisabledColor":ink.to_html(),"disabledFill":fill.bg_color.to_html(),"contrastRatio":ratio})
		await tap("Cc98BdUndo_24")
		check(not node("Cc98BdSelect_24").disabled and node("Cc98BdSelect_24").get_theme_color("font_disabled_color")==old_disabled,"Undo restores ordinary unselected palette")
	await shell.shutdown(); shell.queue_free(); await frames()
	var report={"checks":checks,"failures":failures,"measurements":results,"gui_used":false}
	var path=OS.get_environment("UI_QA_REPORT")
	if not path.is_empty():
		var file=FileAccess.open(path,FileAccess.WRITE); file.store_string(JSON.stringify(report,"\t")); file.close()
	print("CC98_BD_SELECTED_CONTRAST: ",checks," checks / ",failures," failures; ",JSON.stringify(results))
	quit(1 if failures else 0)
