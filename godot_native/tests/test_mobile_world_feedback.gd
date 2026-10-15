extends "res://tests/test_portrait_exploration.gd"
## Full source feedback corpus and the original long-paragraph regression.
func run() -> void:
	state=root.get_node("State");state.developer_mode=true;state.d=state.initial()
	shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames()
	var c4:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/source/chapter4-755.content.json"))
	var c3:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/source/chapter3-qizhen-lake.content.json"))
	var cases:Dictionary={"source_kayak_instructions":c3.boarding.instruction,"generated_regression":"这是一段完整的现场反馈，保留全部文字并根据窗口换行。".repeat(5)}
	# Chapter4._dialogue emits these arrays joined by newline; measure the
	# complete emitted message rather than selecting its longest single line.
	for id in c4.dialogues:
		var lines:PackedStringArray=[]
		for line in c4.dialogues[id]:lines.append(line.text)
		cases[id]="\n".join(lines)
	for dimensions:Vector2i in [Vector2i(390,844),Vector2i(430,860),Vector2i(844,390)]:
		root.size=dimensions;shell.size=Vector2(dimensions)
		state.begin_checkpoint("c3-canteen-drinks");shell.mobile_world=true;shell.compact_inventory_open=true;shell._refresh();await frames(5)
		shell.world.set_process(false)
		var world:Control=shell.world
		var largest:=0.0
		for id in cases:
			var line:String=cases[id]
			var before:String=JSON.stringify(state.d)
			var player:Vector2=world.player
			world.subtitle=line;world.subtitle_left=60;world.queue_redraw();await frames(2)
			var hud:Dictionary=world.hud_metrics(line)
			var needed:float=world.font.get_multiline_string_size(line,HORIZONTAL_ALIGNMENT_CENTER,hud.body_width,hud.body_font).y+hud.body_inset*2
			var controls:Dictionary=world.mobile_control_metrics()
			var bar:=Rect2(hud.body_gap,world.size.y-hud.body_gap-hud.body_height,world.size.x-hud.body_gap*2,hud.body_height)
			check(world.subtitle==line and (hud.body_height>=needed or hud.body_overflow),"complete feedback is retained in measured or scrollable bar: "+str(id))
			if hud.body_overflow:
				check(world.overflow_feedback.visible and world.overflow_feedback.label.text==line,"overflow owns complete source text")
				check(world.overflow_feedback.label.size.y>=needed-hud.body_inset*2,"overflow scroll content retains full glyph height")
			check(hud.body_font*world.hud_display_scale()>=14,"physical feedback font floor")
			check(Rect2(Vector2.ZERO,world.size).encloses(bar),"full feedback bar is inside viewport")
			check(Rect2(0,hud.header_height,world.size.x,world.size.y-hud.header_height).encloses(controls.stick_rect),"movement hit area stays beneath header after growth")
			check(not controls.stick_rect.intersects(bar) and not controls.interact.intersects(bar),"grown feedback never covers world controls")
			check(controls.interact.size.x>=44 and controls.interact.size.y>=44 and controls.stick_rect.size.x>=100,"touch target floors survive feedback growth")
			if id in ["generated_regression","opening.external_time_rejected"]:
				var thumb:Vector2=world_screen(controls.stick+Vector2(-32,0))
				touch(thumb,true);await frames(2)
				check(world.touch_axis.length()>0,"root touch reaches moved control after paragraph growth")
				touch(thumb,false);await frames(2)
				check(world.touch_axis==Vector2.ZERO,"same touch releases after paragraph growth")
			check(world.player==player and JSON.stringify(state.d)==before,"feedback metrics/input cannot change world or save state")
			largest=maxf(largest,hud.body_height)
		print("FEEDBACK ",dimensions," source_cases=",cases.size()," largest_bar=",largest," control_size=100x100; font=",world.hud_metrics("").body_font,"px")
	await shell.shutdown();shell.queue_free();await frames()
	print("MOBILE_WORLD_FEEDBACK: %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
