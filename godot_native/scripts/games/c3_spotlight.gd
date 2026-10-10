extends Control
## Source TheaterImpossibleShow.ts native presentation and 50ms validated model.
signal finished(result: Dictionary)
signal attempt_submitted(result: Dictionary)
signal cancelled
const Lens=preload("res://scripts/presentation/theater_lens.gd")
const StageView=preload("res://scripts/presentation/theater_stage_view.gd")
const Model=preload("res://scripts/games/c3_spotlight_model.gd")
const COLORS:=[Color("ffcf68"),Color("94f3d0"),Color("ff94bc")]
const INK=Color("11152d")
const CREAM=Color("fff0cb")
var stage_view:Control
var ui_ink:Node2D
var pointer_device:=""
var pointer_touch:=-1
var pointer_source_device:=-999
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
	trace.clear();accumulator=0;visual_time=0;running=false;paused=false;screen="intro";approved=false;final_act=false;_release_pointer();queued_dash=false
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
	stage_view=StageView.new();stage_view.name="ModeledTheater";add_child(stage_view)
	ui_ink=Node2D.new();ui_ink.draw.connect(func():draw_ui(ui_ink));add_child(ui_ink)
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
		screen="running"; running=true; paused=false; accumulator=0; _release_pointer(); queued_dash=false
	elif screen=="result": finished.emit({"continue":true}); return
	refresh()
func _pause() -> void:
	if screen!="running": return
	screen="paused"; paused=true; accumulator=0; _release_pointer(); queued_dash=false; refresh()
func resolve(accepted: bool,last_act: bool=false) -> void:
	approved=accepted; final_act=last_act; screen="result"; running=false; queued_dash=false; _release_pointer(); refresh()
func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	if event.keycode==KEY_ESCAPE: _pause(); get_viewport().set_input_as_handled()
	elif event.keycode==KEY_SPACE and screen=="running": queued_dash=true; get_viewport().set_input_as_handled()
	elif event.keycode in [KEY_ENTER,KEY_KP_ENTER] and screen!="running": _primary(); get_viewport().set_input_as_handled()
func _notification(what: int) -> void:
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT and running: _pause()
func pointer_to_model(point:Vector2)->Vector2:return Lens.sample_point(point)
func model_to_pointer(point:Vector2)->Vector2:return Lens.display_point(point)
func _release_pointer()->void:
	dragging=false;pointer_device="";pointer_touch=-1;pointer_source_device=-999
func _accept_pointer(point:Vector2)->bool:
	return Rect2(56,126,848,289).has_point(pointer_to_model(point))
func _gui_input(event: InputEvent) -> void:
	if screen!="running": return
	if event is InputEventScreenTouch:
		if event.pressed and not event.canceled and pointer_device.is_empty() and _accept_pointer(event.position):
			pointer_device="touch";pointer_source_device=event.device;pointer_touch=event.index;dragging=true;pointer=pointer_to_model(event.position)
		elif event.index==pointer_touch and event.device==pointer_source_device and (not event.pressed or event.canceled):_release_pointer()
	elif event is InputEventScreenDrag and pointer_device=="touch" and event.index==pointer_touch and event.device==pointer_source_device:
		pointer=pointer_to_model(event.position)
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		if event.device==InputEvent.DEVICE_ID_EMULATION or pointer_device=="touch":return
		if event.pressed and pointer_device.is_empty() and _accept_pointer(event.position):
			pointer_device="mouse";pointer_source_device=event.device;dragging=true;pointer=pointer_to_model(event.position)
		elif not event.pressed and pointer_device=="mouse" and event.device==pointer_source_device:_release_pointer()
	elif event is InputEventMouseMotion and pointer_device=="mouse" and event.device==pointer_source_device and event.device!=InputEvent.DEVICE_ID_EMULATION:
		pointer=pointer_to_model(event.position)
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
				screen="awaiting"; running=false; _release_pointer()
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
	if is_instance_valid(stage_view):stage_view.sync(self)
	if is_instance_valid(ui_ink):ui_ink.queue_redraw()
func draw_ui(canvas:CanvasItem)->void:
	# UI and text deliberately sit outside the optical surface.
	canvas.draw_rect(Rect2(58,43,844,70),Color(.045,.045,.076,.95))
	canvas.draw_line(Vector2(67,114),Vector2(893,114),Color("8a6350"),1)
	canvas.draw_rect(Rect2(47,424,867,89),Color(.045,.045,.076,.98))
	if is_instance_valid(font):
		canvas.draw_string(font,Vector2(68,491),"影子咬掉了一截光。谢幕可以冲过去。" if state.get("lastEvent","")=="hurt" else "按住舞台拖动 / WASD 移动 · 集齐标点后从嘴里退场",HORIZONTAL_ALIGNMENT_LEFT,540,14,Color("b7bdd6"))
	if screen!="running":
		canvas.draw_rect(Rect2(186,165,588,244),Color(.06,.055,.095,.94))
		canvas.draw_rect(Rect2(186,165,588,244),Color(COLORS[state.round],.65),false,1)
