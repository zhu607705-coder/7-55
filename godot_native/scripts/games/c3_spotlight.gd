extends Control
## Source TheaterImpossibleShow.ts native presentation and 50ms validated model.
signal finished(result: Dictionary)
signal attempt_submitted(result: Dictionary)
signal cancelled
const Model=preload("res://scripts/games/c3_spotlight_model.gd")
const COLORS:=[Color("ffcf68"),Color("94f3d0"),Color("ff94bc")]
const INK=Color("11152d")
const CREAM=Color("fff0cb")
var rules: RefCounted=Model.new()
var config: Dictionary={}
var state: Dictionary={}
var trace: Array=[]
var accumulator:=0.0
var visual_time:=0.0
var running:=false
var paused:=false
var dragging:=false
var pointer:=Vector2.ZERO
var queued_dash:=false
var screen:="intro"
var approved:=false
var final_act:=false
var font: Font
var label: Label
var badge: Label
var start_button: Button
var dash_button: Button
var pause_button: Button
var resume_button: Button
var overlay_title: Label
var overlay_body: Label
func setup(parameters: Dictionary) -> void:
	config=parameters; state=rules.create(int(config.get("round",0)),int(config.get("attempt",0)))
	if is_node_ready(): refresh()
func _label(text: String,rect: Rect2,font_size: int,color: Color=CREAM,center: bool=false) -> Label:
	var node:=Label.new(); node.text=text; node.position=rect.position; node.size=rect.size
	node.add_theme_font_override("font",font); node.add_theme_font_size_override("font_size",font_size); node.add_theme_color_override("font_color",color)
	node.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; node.mouse_filter=Control.MOUSE_FILTER_IGNORE
	if center: node.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; node.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	add_child(node); return node
func _button(text: String,rect: Rect2,callback: Callable) -> Button:
	var button:=Button.new(); button.text=text; button.position=rect.position; button.size=rect.size
	button.add_theme_font_override("font",font); button.add_theme_font_size_override("font_size",18)
	var box:=StyleBoxFlat.new(); box.bg_color=COLORS[state.round]; box.set_border_width_all(0)
	for mode: String in ["normal","hover","pressed","hover_pressed","disabled"]: button.add_theme_stylebox_override(mode,box)
	for role: String in ["font_color","font_hover_color","font_pressed_color","font_hover_pressed_color","font_focus_color","font_disabled_color"]: button.add_theme_color_override(role,INK)
	button.pressed.connect(callback); add_child(button); return button
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT); size=Vector2(960,540); mouse_filter=Control.MOUSE_FILTER_STOP
	font=load("res://assets/rpg/fonts/fusion_pixel_12px_proportional_zh_hans.ttf")
	if state.is_empty(): setup(config)
	_label("追光灯辞职以后",Rect2(67,55,780,34),23)
	badge=_label("第 %d 幕 / 3 · %s" % [state.round+1,Model.ACTS[state.round].title],Rect2(67,90,780,26),15,Color("ff94bc"))
	label=_label("",Rect2(68,427,550,25),16)
	start_button=_button("让灯自己演",Rect2(330,351,300,49),_primary)
	dash_button=_button("谢幕 · Space",Rect2(718,460,178,44),func(): queued_dash=true)
	pause_button=_button("Ⅱ",Rect2(638,460,64,44),_pause)
	for role: String in ["font_color","font_hover_color","font_pressed_color","font_hover_pressed_color","font_focus_color","font_disabled_color"]: pause_button.add_theme_color_override(role,CREAM)
	var pause_style:=StyleBoxFlat.new(); pause_style.bg_color=INK; pause_style.border_color=Color("595a77"); pause_style.set_border_width_all(1)
	for mode: String in ["normal","hover","pressed","hover_pressed","disabled"]: pause_button.add_theme_stylebox_override(mode,pause_style)
	var pause_focus:=StyleBoxFlat.new(); pause_focus.bg_color=Color.TRANSPARENT; pause_focus.border_color=CREAM; pause_focus.set_border_width_all(2)
	pause_button.add_theme_stylebox_override("focus",pause_focus)
	overlay_title=_label("",Rect2(210,177,540,58),25,CREAM,true)
	overlay_body=_label("",Rect2(210,239,540,90),17,Color("cdd2e8"),true)
	start_button.move_to_front(); refresh()
func _primary() -> void:
	if screen in ["intro","paused"]:
		screen="running"; running=true; paused=false; accumulator=0; dragging=false; queued_dash=false
	elif screen=="result": finished.emit({"continue":true}); return
	refresh()
func _pause() -> void:
	if screen!="running": return
	screen="paused"; paused=true; accumulator=0; dragging=false; queued_dash=false; refresh()
func resolve(accepted: bool,last_act: bool=false) -> void:
	approved=accepted; final_act=last_act; screen="result"; running=false; dragging=false; refresh()
func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	if event.keycode==KEY_ESCAPE: _pause(); get_viewport().set_input_as_handled()
	elif event.keycode==KEY_SPACE and screen=="running": queued_dash=true; get_viewport().set_input_as_handled()
	elif event.keycode in [KEY_ENTER,KEY_KP_ENTER] and screen!="running": _primary(); get_viewport().set_input_as_handled()
func _notification(what: int) -> void:
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT and running: _pause()
func _gui_input(event: InputEvent) -> void:
	if screen!="running": return
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		dragging=event.pressed and Rect2(56,126,848,289).has_point(event.position); pointer=event.position
	elif event is InputEventMouseMotion and dragging: pointer=event.position
	elif event is InputEventScreenTouch: dragging=event.pressed and Rect2(56,126,848,289).has_point(event.position); pointer=event.position
	elif event is InputEventScreenDrag and dragging: pointer=event.position
func _process(delta: float) -> void:
	if screen!="paused": visual_time+=minf(delta,.1)
	if screen=="running":
		accumulator+=minf(delta,.15)
		while accumulator>=.05 and state.status=="running":
			accumulator-=.05
			var axis:=Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))-float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
			if axis.length()<.01 and dragging and pointer.distance_to(state.head)>9: axis=(pointer-state.head).normalized()
			var input: Dictionary={"x":axis.x,"y":axis.y,"dash":queued_dash}; queued_dash=false
			trace.append(input); state=rules.step(state,input)
			if state.status!="running":
				screen="awaiting"; running=false; dragging=false
				attempt_submitted.emit({"version":2,"round":state.round,"attempt":state.attempt,"inputs":trace.duplicate(true)})
	refresh()
func refresh() -> void:
	if not is_instance_valid(label): return
	var act: Dictionary=Model.ACTS[state.round]
	badge.text="第 %d 幕 / 3 · %s" % [state.round+1,act.title]
	for button: Button in [start_button,dash_button]:
		var box: StyleBoxFlat=button.get_theme_stylebox("normal").duplicate(); box.bg_color=COLORS[state.round]
		for mode: String in ["normal","hover","pressed","hover_pressed","disabled"]: button.add_theme_stylebox_override(mode,box)
	label.text="标点 %d/%d     灯芯 %s%s     %ds" % [state.collected.size(),act.count,"●".repeat(state.lives),"○".repeat(3-state.lives),ceili((1600-state.tick)/20.0)]
	dash_button.text="谢幕冷却 %ds" % ceili(state.dashCooldown/20.0) if state.dashCooldown>0 else "谢幕 · Space"
	dash_button.visible=screen=="running"; pause_button.visible=screen=="running"
	start_button.visible=screen!="running"; start_button.disabled=screen=="awaiting"; overlay_title.visible=screen!="running"; overlay_body.visible=screen!="running"
	match screen:
		"intro": overlay_title.text=act.title; overlay_body.text=act.subtitle+"\n按住舞台拖动，或用 WASD / 方向键移动。\nSpace「谢幕」可以短暂穿过影子。"; start_button.text="让灯自己演"
		"paused": overlay_title.text="演出暂停，影子也停下了"; overlay_body.text="按继续后再演。计时和动作都从暂停处恢复。"; start_button.text="继续演出"
		"awaiting": overlay_title.text="正在收下这场演出"; overlay_body.text=""; start_button.text="稍等一下"
		"result":
			overlay_title.text=("全体观众，都被演出了" if final_act else "这一幕已经无法撤回") if approved else "影子把这场演出吃掉了"
			overlay_body.text=("灯光谢幕。台上只剩下一张湿节目单。" if final_act else "收下这一幕。下一幕的规则会变。") if approved else "已经完成的幕次保留。\n再演一次，这一幕从头开始。"
			start_button.text=("拉开最后的幕布" if final_act else "下一幕") if approved else "重演这一幕"
	queue_redraw()
func ellipse(center: Vector2,extent: Vector2,color: Color) -> void:
	var points:=PackedVector2Array()
	for i in range(32): points.append(center+Vector2(cos(i*TAU/32),sin(i*TAU/32))*extent/2)
	draw_colored_polygon(points,color)
func chair(x: float,y: float,phase: float,factor: float=1) -> void:
	ellipse(Vector2(x,y+24*factor),Vector2(53,12)*factor,Color(.04,.06,.13,.5))
	draw_rect(Rect2(x-17*factor,y-27*factor,34*factor,26*factor),Color("ffb18e")); draw_rect(Rect2(x-12*factor,y-22*factor,24*factor,15*factor),Color("773b66")); draw_rect(Rect2(x-21*factor,y,42*factor,9*factor),Color("ffb18e"))
	var kick:=sin(phase)*8*factor
	draw_line(Vector2(x-14*factor,y+7*factor),Vector2(x-18*factor+kick,y+24*factor),COLORS[0],5*factor); draw_line(Vector2(x+14*factor,y+7*factor),Vector2(x+18*factor-kick,y+24*factor),COLORS[0],5*factor)
	for offset in [-7,3]: draw_rect(Rect2(x+offset*factor,y-19*factor,5*factor,6*factor),CREAM); draw_rect(Rect2(x+(offset+2)*factor,y-17*factor,2*factor,3*factor),INK)
func eye(point: Vector2,width: float,awake: bool=true) -> void:
	ellipse(point,Vector2(width*2,width),CREAM if awake else Color(.337,.376,.502,.6))
	var offset: Vector2=((state.head-point)/110).clamp(Vector2(-width*.24,-width*.13),Vector2(width*.24,width*.13))
	draw_circle(point+offset,width*.27,Color("171936")); draw_rect(Rect2(point+offset-Vector2(2,2),Vector2(4,4)),Color("e85881"))
func _draw() -> void:
	draw_rect(Rect2(0,0,960,540),INK); draw_rect(Rect2(46,122,868,296),Color("24233e"))
	if state.is_empty(): return
	var t:=visual_time; var color: Color=COLORS[state.round]; var act: Dictionary=Model.ACTS[state.round]
	for i in 6:
		var curtain:=Color("78334f") if i%2 else Color("a43d60")
		draw_rect(Rect2(i*8,115,8,309-i*13),curtain); draw_rect(Rect2(912+i*8,115,8,244+i*13),curtain)
	draw_rect(Rect2(46,116,868,14),Color("77354f"))
	for x in range(50,915,48): draw_colored_polygon(PackedVector2Array([Vector2(x,128),Vector2(x+47,128),Vector2(x+24,144)]),Color("ab496d"))
	var moon:=Vector2(170+sin(t*.35)*12,201)
	draw_circle(moon,51,Color(.4,.376,.47,.18)); draw_circle(moon,41,Color(.973,.839,.561,.11)); chair(moon.x,moon.y+8,t*2,.7); draw_rect(Rect2(105,150,132,115),Color(.141,.137,.243,.6))
	for i in 13:
		var point:=Vector2(82+i*65,157+sin(t+i)*8 if state.round==2 else 389+sin(i*2)*4)
		ellipse(point+Vector2(0,12),Vector2(43,42),Color("37354f")); eye(point+Vector2(0,3),12,state.round==2)
	draw_rect(Rect2(49,410,862,14),Color("202947")); draw_line(Vector2(49,416),Vector2(911,416),Color(.384,.396,.522,.4),1)
	for i in 15: draw_line(Vector2(55+i*60,410),Vector2(37+i*63,424),Color(.384,.396,.522,.4),1)
	if state.round==2:
		for i in 10:
			var point:=Vector2(80+i*87,185+fmod(state.tick*2+i*43,190)); draw_line(point,point+Vector2(5,sin(state.tick*.028)*30),Color(.588,.902,.835,.12),2)
	var mouth: Vector2=rules.mouth(state); var open: bool=state.collected.size()==act.count
	ellipse(mouth,Vector2(108,95 if open else 47),Color("713852")); ellipse(mouth,Vector2(91,78 if open else 29),Color("f582a7")); ellipse(mouth,Vector2(70,61 if open else 9),Color("0c1024"))
	for i in 5:
		draw_rect(Rect2(mouth.x-30+i*13,mouth.y-(29 if open else 4),9,11 if open else 5),CREAM)
		if open: draw_rect(Rect2(mouth.x-30+i*13,mouth.y+19,9,10),CREAM)
	if screen=="running":
		draw_string(font,mouth+Vector2(-75,70 if open else 48),"请从嘴里退场" if open else "还差 %d 个标点" % (act.count-state.collected.size()),HORIZONTAL_ALIGNMENT_CENTER,150,13,Color("ffb1c4"))
		for id in int(act.count):
			if state.collected.has(id): continue
			draw_circle(Model.FOOD[id],28+sin(t*3+id)*3,Color(color,.08)); draw_arc(Model.FOOD[id],24,0,TAU,32,Color(color,.25),1)
			draw_string(font,Model.FOOD[id]+Vector2(-18,10+sin(t*3+id)*2),act.glyph,HORIZONTAL_ALIGNMENT_CENTER,36,36,CREAM)
	for hazard: Dictionary in rules.hazards(state):
		var point: Vector2=hazard.position
		if hazard.kind=="chair": chair(point.x,point.y,t*6+point.x)
		elif hazard.kind=="shadow": ellipse(point,Vector2(49,39),Color(.024,.031,.059,.75)); draw_colored_polygon(PackedVector2Array([point+Vector2(-24,0),point+Vector2(24,0),point+Vector2(0,31)]),Color(.024,.031,.059,.75)); eye(point-Vector2(0,3),13)
		else: draw_arc(point,25,0,TAU,32,Color(1,.58,.74,.6),3); eye(point,25)
	if state.trail.size()>1:
		var points:=PackedVector2Array(state.trail)
		draw_polyline(points,Color(color,.09),34 if state.dashTicks>0 else 25,true); draw_polyline(points,Color(color,.75),12,true); draw_polyline(points,Color(CREAM,.92),4,true)
	draw_circle(state.head,13,Color.WHITE if state.invulnerable>0 and state.tick%4<2 else color)
	draw_rect(Rect2(state.head-Vector2(15,19),Vector2(30,5)),INK); draw_rect(Rect2(state.head-Vector2(8,32),Vector2(16,15)),INK); draw_rect(Rect2(state.head-Vector2(8,30),Vector2(16,3)),CREAM)
	for x in [-6,3]: draw_rect(Rect2(state.head+Vector2(x,-3),Vector2(3,5)),INK)
	draw_line(state.head+Vector2(-3,6),state.head+Vector2(4,6),INK,2); draw_rect(Rect2(59,52,842,62),Color("595a77"),false,1)
	draw_string(font,Vector2(68,494),"影子咬掉了一截光。谢幕可以冲过去。" if state.lastEvent=="hurt" else "按住舞台拖动 / WASD 移动 · 集齐标点后从嘴里退场",HORIZONTAL_ALIGNMENT_LEFT,540,14,Color("b7bdd6"))
	if screen!="running":
		draw_rect(Rect2(48,128,864,296),Color(.039,.059,.137,.84)); draw_rect(Rect2(186,165,588,244),Color("24233e")); draw_rect(Rect2(186,165,588,244),Color(color,.75),false,2)
