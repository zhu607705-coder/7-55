extends Control
## Source-authored elevator timing diagram. Presentation and intents only.
signal shifted(seconds: int)
signal replay_requested
signal board_requested
signal close_requested
var timeline: Dictionary={}
var selection:=0
var stage:="select"
var elapsed_ms:=0.0
var boarded:=false
var feedback:=""
var heading:Label
var instruction:Label
var door_label:Label
var passenger_label:Label
var readout:Label
var hint:Label
var controls:BoxContainer
var chart:=Rect2()
var earlier:Button
var later:Button
var replay:Button
var board:Button
var back:Button
func configure(value:Dictionary) -> void:
	timeline=value.duplicate(true)
	selection=int(timeline.selectableStartMinSeconds)
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_STOP
	heading=_label(22,"#f7f1dc");heading.text="18:50 / 一号电梯运行档案"
	instruction=_label(18,"#a9bac7");instruction.text="调整蓝色门体区间，让它完整覆盖黄色人物进入区间。"
	door_label=_label(16,"#79c5cf");door_label.text="门体开放"
	passenger_label=_label(16,"#ffd36f");passenger_label.text="人物进入"
	readout=_label(16,"#f7f1dc")
	hint=_label(14,"#a9bac7")
	controls=BoxContainer.new();controls.add_theme_constant_override("separation",8);add_child(controls)
	earlier=_button("提前 1 秒",func():shifted.emit(-1))
	replay=_button("重放并校验",func():replay_requested.emit())
	later=_button("延后 1 秒",func():shifted.emit(1))
	board=_button("走入电梯",func():board_requested.emit())
	back=_button("返回",func():close_requested.emit())
	var normal:=StyleBoxFlat.new();normal.bg_color=Color("#d7b654");normal.border_color=Color("#ffefad");normal.set_border_width_all(2);normal.content_margin_left=8;normal.content_margin_right=8
	replay.add_theme_stylebox_override("normal",normal)
	var pressed:=normal.duplicate();pressed.bg_color=Color("#b29549");replay.add_theme_stylebox_override("pressed",pressed)
	replay.add_theme_color_override("font_color",Color("#111b24"))
	resized.connect(_layout)
	refresh(selection,stage,elapsed_ms,boarded,feedback)
func _label(font_size:int,color:String) -> Label:
	var label:=Label.new();label.add_theme_font_size_override("font_size",font_size);label.add_theme_color_override("font_color",Color(color));label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;label.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(label);return label
func _button(caption:String,callback:Callable) -> Button:
	var button:=Button.new();button.text=caption;button.custom_minimum_size=Vector2(0,44);button.size_flags_horizontal=Control.SIZE_EXPAND_FILL;button.add_theme_font_size_override("font_size",17);button.pressed.connect(callback);controls.add_child(button);return button
func clock(value:int) -> String:
	return "%02d:%02d:%02d"%[value/3600,(value%3600)/60,value%60]
func refresh(start:int,current_stage:String,elapsed:float,entered:bool,message:String="") -> void:
	selection=start;stage=current_stage;elapsed_ms=elapsed;boarded=entered;feedback=message
	if not is_instance_valid(heading):return
	earlier.visible=stage=="select";later.visible=stage=="select";replay.visible=stage=="select";board.visible=stage=="replay";board.disabled=boarded
	earlier.disabled=selection<=int(timeline.selectableStartMinSeconds);later.disabled=selection>=int(timeline.selectableStartMaxSeconds)
	var door_end:=selection+int(timeline.firstFloorDoorOpenDurationSeconds)
	readout.text="当前门体记录  %s—%s  /  8 秒\n人物进入记录  %s—%s  /  6 秒\n%s"%[clock(selection),clock(door_end),clock(int(timeline.playerWindowStartSeconds)),clock(int(timeline.playerWindowEndSeconds)),feedback if not feedback.is_empty() else "白线：轿厢于 %s 开始上行。"%clock(selection+int(timeline.riseOffsetSeconds))]
	readout.add_theme_color_override("font_color",Color("#ff987d") if not feedback.is_empty() else Color("#f7f1dc"))
	hint.text="← / → 调整重放起点   Enter 校验   Esc 返回" if stage=="select" else ("乘客轨迹正在回放。   Esc 返回" if boarded else "空格 / Enter 走入电梯   Esc 返回")
	_layout();queue_redraw()
func _layout() -> void:
	if not is_instance_valid(heading):return
	var compact:=size.x<600
	var width:=minf(960,size.x-32)
	var left:=(size.x-width)/2
	var top:=maxf(12,(size.y-(650 if compact else 350))/2)
	heading.position=Vector2(left,top);heading.size=Vector2(width,32);heading.add_theme_font_size_override("font_size",20 if compact else 22)
	instruction.position=Vector2(left,top+40);instruction.size=Vector2(width,60 if compact else 44);instruction.add_theme_font_size_override("font_size",16 if compact else 18)
	if not compact and size.y<390:
		heading.position=Vector2(left,8);heading.size=Vector2(width,28);heading.add_theme_font_size_override("font_size",20)
		instruction.position=Vector2(left,40);instruction.size=Vector2(width,38);instruction.add_theme_font_size_override("font_size",16)
		chart=Rect2(left,84,width*0.55-12,100)
		door_label.position=chart.position+Vector2(8,5);door_label.size=Vector2(90,23)
		passenger_label.position=chart.position+Vector2(8,51);passenger_label.size=Vector2(90,23)
		readout.position=Vector2(left+width*0.55,82);readout.size=Vector2(width*0.45,120)
		controls.vertical=false;controls.position=Vector2(left,size.y-78);controls.size=Vector2(width,44)
		hint.position=Vector2(left,size.y-28);hint.size=Vector2(width,24)
		return
	var chart_top:=top+(110 if compact else 94)
	chart=Rect2(left,chart_top,width,100)
	door_label.position=Vector2(left+8,chart_top+5);door_label.size=Vector2(90,23)
	passenger_label.position=Vector2(left+8,chart_top+51);passenger_label.size=Vector2(90,23)
	readout.position=Vector2(left,chart.end.y+14);readout.size=Vector2(width,118 if compact else 72)
	controls.vertical=compact;controls.position=Vector2(left,readout.position.y+(126 if compact else 80));controls.size=Vector2(width,(200 if stage=="select" else 96) if compact else 44)
	hint.position=Vector2(left,controls.position.y+controls.size.y+8);hint.size=Vector2(width,42 if compact else 24)
func geometry() -> Dictionary:
	var duration:=float(timeline.timelineEndSeconds)-float(timeline.timelineStartSeconds)
	var track:=Rect2(chart.position+Vector2(8,27),Vector2(chart.size.x-16,18))
	var origin:=float(timeline.timelineStartSeconds)
	var door:=Rect2(track.position+Vector2((selection-origin)/duration*track.size.x,0),Vector2(float(timeline.firstFloorDoorOpenDurationSeconds)/duration*track.size.x,18))
	var passenger:=Rect2(track.position+Vector2((float(timeline.playerWindowStartSeconds)-origin)/duration*track.size.x,46),Vector2(float(timeline.playerWindowEndSeconds-timeline.playerWindowStartSeconds)/duration*track.size.x,16))
	return {"door":door,"passenger":passenger,"rise_x":track.position.x+(selection+float(timeline.riseOffsetSeconds)-origin)/duration*track.size.x,"track":track,"duration":duration}
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("#101722"))
	if timeline.is_empty() or not is_instance_valid(heading):return
	draw_rect(chart,Color("#102033"));draw_rect(chart,Color("#60768c"),false,2)
	var g:=geometry();draw_rect(g.door,Color("#4ca7c7"));draw_rect(g.passenger,Color("#ffcf58"))
	draw_line(Vector2(g.rise_x,chart.position.y+4),Vector2(g.rise_x,chart.end.y-4),Color("#f7f1dc"),2)
	if stage=="replay":
		var x:float=g.track.position.x+(selection+elapsed_ms/1000-float(timeline.timelineStartSeconds))/g.duration*g.track.size.x
		draw_line(Vector2(x,chart.position.y),Vector2(x,chart.end.y),Color("#ffd36f"),2)
