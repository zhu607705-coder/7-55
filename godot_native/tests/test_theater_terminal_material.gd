extends SceneTree
const Terminal=preload("res://scripts/ui/c3_theater_device_panel.gd")
const Typography=preload("res://scripts/ui/native_typography.gd")
const Ui=preload("res://scripts/ui/native_ui_theme.gd")
var checks:=0
var failures:=0
func _initialize()->void:run.call_deferred()
func check(ok:bool,message:String)->void:
	checks+=1
	if not ok:failures+=1;push_error(message)
func run()->void:
	for kind:String in ["code","program"]:
		var state:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/initial_state.json"))
		state.native={"scene":"theater_interior","mode":"light"}
		state.theaterHunt.phase="entry_ticket" if kind=="code" else "program_search"
		state.theaterHunt.collectedProgramIds=["opening","spotlight","finale"]
		var panel:=Terminal.new()
		check(panel.setup(kind,func():return state,func(_action,_value):return {}),"actual terminal opens")
		root.add_child(panel)
		for unused in 3:await process_frame
		var original:Dictionary={}
		for id:String in panel.controls:original[id]=panel.controls[id].get_rect()
		for extent:Vector2 in [Vector2(390,844),Vector2(667,375),Vector2(568,320),Vector2(844,390),Vector2(1440,900)]:
			var compact:bool=extent.x<1000
			panel.configure_layout(extent,compact)
			panel.set_feedback("取票机：查无此票。请核对回执，本机不接受到场证明。")
			await process_frame
			check(panel.owns_feedback_surface()==compact,"only visible compact terminal owns feedback surface")
			if compact:
				for first:Control in [panel.title_label,panel.display,panel.feedback_label]:
					check(panel.compact_board.encloses(first.get_rect()),"text surface inside terminal")
					check(first.get_line_count()*first.get_line_height()<=first.size.y+1,"all authored text lines fit their actual font height")
					for second:Control in [panel.title_label,panel.display,panel.feedback_label]:
						if first!=second:check(not first.get_rect().intersects(second.get_rect()),"heading/readout/feedback rows do not overlap")
			check(panel.title_label.get_theme_font("font")==Typography.body_font(),"instructions use body font")
			for id:String in panel.controls:
				var button:Button=panel.controls[id]
				check(button.get_theme_font("font")==Typography.display_font(),"keys use bundled Medium face")
				if compact:
					check(not button.get_rect().intersects(panel.feedback_label.get_rect()),"feedback never overlaps any key")
					check(not button.get_rect().intersects(panel.display.get_rect()),"screen never overlaps any key %s %s %s screen=%s key=%s"%[kind,extent,id,panel.display.get_rect(),button.get_rect()])
					check(not button.get_rect().intersects(panel.title_label.get_rect()),"heading never overlaps any key")
					check(button.size.y>=44,"short landscape retains touch target height")
					for other_id:String in panel.controls:
						if other_id!=id:check(not button.get_rect().intersects(panel.controls[other_id].get_rect()),"key targets never overlap")
				check((panel.compact_board if compact else Rect2(Vector2.ZERO,Vector2(960,540))).encloses(button.get_rect()),"existing key targets stay inside device")
				if not compact:check(button.get_rect().is_equal_approx(original[id]),"desktop hit coordinates preserved: %s old=%s actual=%s"%[id,original[id],button.get_rect()])
				var normal:StyleBox=button.get_theme_stylebox("normal")
				check(Ui._contrast(button.get_theme_color("font_color"),normal.bg_color)>=4.5,"key contrast")
				check(button.get_theme_stylebox("focus").bg_color.a==0,"focus ring does not replace key face")
			check(panel.controls.submit.get_theme_stylebox("normal").bg_color!=panel.controls.close.get_theme_stylebox("normal").bg_color,"submit has distinct primary hierarchy")
		panel.hide();check(not panel.owns_feedback_surface(),"hidden terminal cannot own feedback")
		panel.show();panel.set_feedback("");check(not panel.owns_feedback_surface(),"empty feedback has no surface")
		panel.dismiss();check(not panel.owns_feedback_surface(),"dismissal releases surface")
		panel.free()
	print("Theater terminal material: ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)
