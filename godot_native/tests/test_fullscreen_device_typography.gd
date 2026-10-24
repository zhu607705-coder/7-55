extends SceneTree
const Layout=preload("res://scripts/ui/device_layout.gd")
var failures:=0
var checks:=0
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func _initialize()->void:call_deferred("run")
func run()->void:
	var state:Node=root.get_node("State");state.developer_mode=true
	state.begin_checkpoint("c4-755-classrooms-1850")
	for spec:Array in [["archive_index","room301_archive_panel.gd","A3"],["media_alignment","room302_studio_panel.gd","A3"],["positioning_calibration","room201_press_panel.gd","A2"]]:
		state.d.chapter4.floor=spec[2];state.d.native.c4_context=spec[0]
		if spec[0]=="positioning_calibration":state.d.chapter4.factIds.append("misaligned_stair_solved")
		var panel:Control=load("res://scripts/objects/"+spec[1]).new()
		var configured:bool=panel.configure(spec[0],state.d)
		check(configured,"Real device configures "+spec[0])
		if not configured:panel.free();continue
		root.add_child(panel)
		for dims:Vector2i in [Vector2i(390,844),Vector2i(430,860),Vector2i(844,390),Vector2i(1280,720),Vector2i(1920,1080),Vector2i(2560,1440)]:
			root.size=dims;panel.layout_fullscreen(Rect2(Vector2.ZERO,Vector2(dims)))
			for i:int in 4:await process_frame
			var bounds:=Rect2(Vector2.ZERO,Vector2(dims))
			for control:Control in [panel.header,panel.hint,panel.feedback,panel.close_button]:
				check(bounds.encloses(control.get_global_rect()),"Text/return remains inside "+spec[0]+str(dims))
			check(panel.hint.get_theme_font_size("font_size")==Layout.font_size(dims,18),"Body grows with logical viewport, not DPR")
			check(panel.close_button.size.y>=52*Layout.scale_for(dims),"Return grows together with body")
			check(panel.hint.get_line_count()*panel.hint.get_line_height()<=panel.hint.size.y+1,"Hint is not vertically cropped "+spec[0]+str(dims))
			var before:String=JSON.stringify(state.d)
			panel.evidence.cover.pressed.emit()
			for i:int in 2:await process_frame
			check(panel.evidence.opened and panel.evidence.paper_scroll.visible,"Physical sheet opens the actual visual evidence")
			check(bounds.encloses(panel.evidence.paper_scroll.get_global_rect()),"Evidence scroll remains in viewport")
			check(panel.evidence.paper.size.x>=328,"Short screens scroll the sheet instead of shrinking its type")
			panel.evidence.close_sheet()
			check(JSON.stringify(state.d)==before,"Evidence inspection cannot grant a fact or adjust a mechanism")
		panel.dispose_session();panel.queue_free();await process_frame
	print("FULLSCREEN_DEVICE_TYPE ",checks," checks; ",failures," failures");quit(1 if failures else 0)
