extends SceneTree
const Opening=preload("res://scripts/ui/native_opening_presentation.gd")
const Notice=preload("res://scripts/ui/native_phone_notice.gd")
var shell: Control
var state: Node
var checks:=0
var failures:=0
func _initialize() -> void: run.call_deferred()
func frames(count: int=3) -> void:
	for i in range(count): await process_frame
func check(ok: bool,text: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error("OPENING SOURCE UI: "+text)
func find_named(node: Node,value: String) -> Node:
	if node.name==value: return node
	for child: Node in node.get_children():
		var found:=find_named(child,value)
		if found!=null: return found
	return null
func rect(node: Control) -> Rect2:
	var transform:=node.get_global_transform_with_canvas()
	return Rect2(transform.origin,node.size*transform.get_scale())
func click(button: Control) -> void:
	var point:=rect(button).get_center()
	var move:=InputEventMouseMotion.new(); move.position=point; root.push_input(move)
	for down: bool in [true,false]:
		var event:=InputEventMouseButton.new(); event.button_index=MOUSE_BUTTON_LEFT; event.pressed=down; event.position=point; root.push_input(event)
	await frames()
func press_without_action(button: Button) -> void:
	var rest:=button.position
	var point:=rect(button).get_center()
	var move:=InputEventMouseMotion.new(); move.position=point; root.push_input(move)
	var event:=InputEventMouseButton.new(); event.button_index=MOUSE_BUTTON_LEFT; event.pressed=true; event.position=point; root.push_input(event)
	check(button.position.is_equal_approx(rest+Vector2(0,3)/(424.0/378.0)),"source active translates whole button exactly3 logical px")
	check(is_equal_approx(button.get_theme_stylebox("pressed").shadow_offset.y,1.0/(424.0/378.0)),"pressed translation retains1px shadow")
	move=InputEventMouseMotion.new(); move.position=Vector2.ZERO; root.push_input(move)
	event=InputEventMouseButton.new(); event.button_index=MOUSE_BUTTON_LEFT; event.position=Vector2.ZERO; event.pressed=false; root.push_input(event)
	check(button.position.is_equal_approx(rest),"canceled release restores source button position")
	await frames(1)
func check_alarm_art(dimensions: Vector2i) -> void:
	var clock: Control=find_named(shell.page_body,"AlarmClock")
	var bell: Control=find_named(shell.page_body,"AlarmBellArtwork")
	check(clock!=null and bell!=null,"source clock and clipped bell are present")
	check(is_equal_approx(clock.logical_font_size,Opening.clock_size(dimensions.x)),"clock uses actual viewport vw clamp")
	check(is_equal_approx(clock.logical_letter_spacing,4),"clock retains4 logical px letter spacing")
	check(clock.text_width()<=clock.size.x*(424.0/378.0),"responsive spaced clock remains contained")
	check(bell.size.is_equal_approx(Vector2(90,74)/(424.0/378.0)),"source bell90x74 wrapper")
	var points: PackedVector2Array=bell.body_polygon()
	check(points.size()==11 and points[0]==Vector2(45,8) and points[5]==Vector2(75,66),"source11point clipped60x58 bell geometry")
	check(bell.wave_alpha==0 and bell.rotation==0,"ready bell has no wave or independent rotation")
	for width: int in [280,320,390,430,1440]:
		root.size=Vector2i(width,dimensions.y); shell.size=Vector2(width,dimensions.y); await frames(2)
		check(is_equal_approx(clock.logical_font_size,clampf(width*.2,57.2,83.2)),"existing clock responds to viewport resize "+str(width))
	root.size=dimensions; shell.size=Vector2(dimensions); await frames(2)
func check_button(name: String,fill: Color,ink: Color) -> Button:
	var button: Button=find_named(shell.page_body,"OpeningAction_"+name)
	check(button!=null,"authored opening action exists "+name)
	if button==null: return null
	var scale: float=button.get_global_transform_with_canvas().get_scale().x
	check(button.get_theme_font_size("font_size")==16,"18logical role rounds to16 authored "+name)
	check(absf(16*424.0/378.0-18)<0.06,"18px role retains source scale "+name)
	check(button.get_theme_stylebox("normal").bg_color==fill and button.get_theme_color("font_color")==ink,"source normal palette "+name)
	check(button.get_theme_stylebox("pressed").bg_color==fill,"source pressed palette "+name)
	for mode: String in ["normal","hover","pressed","hover_pressed","disabled","focus"]:
		check(button.has_theme_stylebox_override(mode),"complete local state "+name+" "+mode)
		check(button.get_theme_stylebox(mode).corner_radius_top_left==0,"sharp source edge "+mode)
	check(rect(button).size.x>=44 and rect(button).size.y>=44,"big button keeps readable pointer target "+name)
	check(16*scale>=14,"big button readable at tested physical scale "+name)
	return button
func run() -> void:
	check(is_equal_approx(Opening.SHAKE_SECONDS,.12) and is_equal_approx(Opening.WAVE_SECONDS,.5),"original visual motion durations")
	check(Opening.shake_at(.002)==Vector2.ZERO and Opening.shake_at(.020)==Vector2(2,-1.5),"frame-shake uses steps2 in first keyframe segment")
	check(Opening.shake_at(.035)==Vector2(4,-3) and Opening.shake_at(.065)==Vector2(-4,3) and Opening.shake_at(.095)==Vector2(3,4),"whole-scene shake uses authored keyframe coordinates")
	check(is_equal_approx(Opening.wave_alpha_at(.01),.2) and is_equal_approx(Opening.wave_alpha_at(.10),.2+.8/3) and is_equal_approx(Opening.wave_alpha_at(.26),1),"bell waves use source steps3 opacity")
	state=root.get_node("State"); state.developer_mode=true; state.d=state.initial()
	shell=load("res://scenes/main.tscn").instantiate(); root.add_child(shell); await frames(5)
	for dimensions: Vector2i in [Vector2i(390,844),Vector2i(430,860),Vector2i(1280,720),Vector2i(1440,900)]:
		root.size=dimensions; shell.size=Vector2(dimensions)
		state.d=state.initial(); state.developer_mode=true; shell._refresh(); shell._layout(); await frames(4)
		check(shell.phone.size==Vector2(430,860),"opening preserves canonical frame")
		var start:=check_button("c1_start_alarm",Color("4d7ed9"),Color("fff6df"))
		var subtitle: Label=find_named(shell.page_body,"AlarmSubtitle")
		var chip: Label=find_named(shell.page_body,"AlarmLabel")
		check(subtitle.get_theme_font_size("font_size")==12 and chip.get_theme_font_size("font_size")==12,"alarm subtitle/chip use source13 logical body")
		check(find_named(shell.page_body,"OpeningPaperGradient")!=null,"source opening paper gradient")
		await check_alarm_art(dimensions)
		await press_without_action(start)
		check(not state.d.native.get("alarm_ringing",false),"canceled pointer press does not start alarm")
		await click(start)
		check(state.d.native.alarm_ringing,"real start enters ringing without skipping")
		var close:=check_button("c1_dismiss_alarm",Color("c85454"),Color("fff6df"))
		var motion: Node=find_named(shell.page_body,"AlarmSceneMotion")
		var ringing_bell: Control=find_named(shell.page_body,"AlarmBellArtwork")
		check(motion!=null and motion.scene==close.get_parent() and motion.scene==ringing_bell.get_parent(),"ringing motion owns whole alarm scene including action")
		check(motion.scene.position.is_equal_approx(Opening.shake_at(motion.elapsed)/(424.0/378.0)),"whole-scene translation follows source stepped curve")
		check(ringing_bell.rotation==0 and ringing_bell.wave_alpha>=.2 and ringing_bell.wave_alpha<=1,"ringing shows bounded arc waves without body rotation")
		await press_without_action(close)
		check(state.d.native.page=="alarm","canceled close press retains ringing scene")
		await click(close)
		check(state.d.native.page=="desktop" and not state.d.native.get("wake_warned",false),"real close enters wake choice")
		var sleep:=check_button("c1_wake",Color("fff6df"),Color("222322"))
		var narration: Label=find_named(shell.page_body,"WakeNarration")
		check(narration!=null and narration.text=="你没有5分钟了，但你很有勇气","one scene-owned authored narration")
		check(narration.get_node("NoticeSpeaker").text=="旁白" and narration.get_node("NoticeAvatar/Icon").texture!=null,"source narrator composition and pixel icon")
		check(narration.get_theme_font_size("font_size")==16,"phone caption retains16 logical pixels")
		var expected: Vector2=shell.phone.position+Vector2(19,55)*shell.phone.scale
		check(rect(narration).position.is_equal_approx(expected),"narration follows final CSS phone top52,left16")
		check(rect(find_named(shell.page_body,"WakeTime")).end.y<=rect(narration).position.y+0.1,"narration does not overlap wake status")
		check(not rect(narration).intersects(rect(sleep)),"narration does not overlap wake action")
		check(rect(shell.phone).encloses(rect(narration)),"narration contained by430x860 frame")
		shell._feedback("你没有5分钟了，但你很有勇气。")
		check(shell.toast.text.is_empty() and not shell.toast.visible,"scene narration is not duplicated as global feedback")
		await press_without_action(sleep)
		check(not state.d.native.get("wake_warned",false),"canceled sleep does not warn")
		await click(sleep)
		check(state.d.native.wake_warned,"real sleep action retains controller warning")
		check(shell.toast.text.is_empty() and not shell.toast.visible,"wake warning has only its authored scene display")
		check(find_named(shell.page_body,"WakeNarration")==null,"narration clears when authored warning appears")
		var home:=check_button("c1_enter_home",Color("4d7ed9"),Color("fff6df"))
		await press_without_action(home)
		check(state.d.native.page=="desktop","canceled home press does not navigate")
		await click(home)
		check(state.d.native.page=="phone_home","real enter-home preserves progression")
		shell._feedback("进度已保存。")
		check(shell.toast.visible and shell.toast.text=="进度已保存。","ordinary feedback remains visible")
		check(rect(shell.toast).position.is_equal_approx(expected),"global phone toast uses same phone-relative safe zone")
		check(shell.toast.get_theme_color("font_color")==Color("222322") and shell.toast.get_theme_stylebox("normal").bg_color==Color("fff8e2",.85),"readable source notification colors")
		check(shell.toast.mouse_filter==Control.MOUSE_FILTER_IGNORE,"toast never blocks taps")
		check(rect(shell.phone).encloses(rect(shell.toast)),"toast contained by phone")
		shell._feedback("这是一条完整的提示。".repeat(9),"task"); await frames(2)
		check(shell.toast.get_node("NoticeSpeaker").text=="任务","authored tone retains source speaker")
		check(shell.toast.get_line_count()>1 and shell.toast.size.y>69,"long feedback grows a wrapping card")
		check(shell.toast.get_line_count()*Notice.FONT.get_height(16)+45<=shell.toast.size.y+0.1,"long feedback is not vertically clipped")
		check(rect(shell.phone).encloses(rect(shell.toast)),"long feedback stays inside phone bounds")
		shell.audio_director.subtitle_timed.emit("带音频时长的提示","toast",4200.0,"xiaoying")
		check(is_equal_approx(shell.toast_time,4.2) and shell.toast.get_node("NoticeSpeaker").text=="小影","audio duration and tone remain source-owned")
		shell._process(4.3)
		check(shell.toast.text.is_empty() and not shell.toast.visible,"expired toast clears card and text")
		print("OPENING physical ",dimensions,": button=",16*424.0/378.0*shell.phone.scale.x,"px; notice=",16*shell.phone.scale.x,"px")
	await shell.shutdown(); shell.queue_free(); await frames(3)
	print("Opening source UI: ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)
