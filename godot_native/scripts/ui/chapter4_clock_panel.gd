extends ColorRect
## Original hall-clock face, clue status and selection. Main retains submission authority.
signal submit_requested(value: Dictionary)
signal close_requested
const Ui=preload("res://scripts/ui/native_ui_theme.gd")
var frame:PanelContainer
var grid:GridContainer
var face:Control
var options:Array=[]
var buttons:Array[Button]=[]
var selected:=0
var current_time:=""
var required_time:=""
var phase:=""
var live:=true
var pending:=false
var feedback_label:Label
var submit_button:Button
var close_button:Button
var font:Font
var layout_pending:=false
class ClockFace extends Control:
	var font:Font
	var clock_text:="12:25"
	func _draw():
		var c=size/2;var radius=minf(size.x,size.y)/2-8
		draw_circle(c,radius,Color("e8dfc1"));draw_arc(c,radius,0,TAU,96,Color("a57d34"),3,true)
		for n in 60:
			var direction=Vector2.from_angle(n*TAU/60-PI/2)
			draw_line(c+direction*(radius-(14 if n%5==0 else 6)),c+direction*(radius-2),Color("263746"),2 if n%5==0 else 1,true)
		for mark in [["12",Vector2(0,-.64)],["3",Vector2(.66,0)],["6",Vector2(0,.67)],["9",Vector2(-.66,0)]]:
			var point=c+mark[1]*radius;var width=font.get_string_size(mark[0],HORIZONTAL_ALIGNMENT_LEFT,-1,18).x
			draw_string(font,point+Vector2(-width/2,7),mark[0],HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("263746"))
		var parts=clock_text.split(":");var hour=float(parts[0]);var minute=float(parts[1])
		draw_line(c,c+Vector2.from_angle((hour+minute/60)*TAU/12-PI/2)*radius*.48,Color("263746"),5,true)
		draw_line(c,c+Vector2.from_angle(minute*TAU/60-PI/2)*radius*.73,Color("b47c2d"),3,true)
		draw_circle(c,5,Color("263746"))
func configure(state:Dictionary,choices:Array,required:String,pixel_font:Font)->bool:
	if required.is_empty() or choices.is_empty() or state.native.get("c4_context","")!="clock":return false
	options=choices.duplicate(true);required_time=required;current_time=state.chapter4.timeState;phase=state.chapter4.phase;font=pixel_font
	color=Color(0.03,0.06,0.08,.88);mouse_filter=Control.MOUSE_FILTER_STOP;focus_mode=Control.FOCUS_ALL;z_index=100
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);theme=Ui.font_theme(font)
	frame=PanelContainer.new();frame.minimum_size_changed.connect(_schedule_layout);frame.add_theme_stylebox_override("panel",Ui.box(Color("08131f"),Color("d7b654"),2,0,Vector2(16,16)));add_child(frame)
	var body=VBoxContainer.new();body.add_theme_constant_override("separation",10);frame.add_child(body)
	var header=HBoxContainer.new();body.add_child(header)
	var title=label("大厅旧钟",24,Color("ead8a9"));title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;header.add_child(title)
	close_button=button("× 返回",func():close_requested.emit());close_button.custom_minimum_size=Vector2(90,44);header.add_child(close_button)
	body.add_child(label("转动外圈，比较能够停住的刻度",18,Color("b0bcae")))
	var scroll=ScrollContainer.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;body.add_child(scroll)
	grid=GridContainer.new();grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL;grid.add_theme_constant_override("h_separation",18);grid.add_theme_constant_override("v_separation",12);scroll.add_child(grid)
	face=ClockFace.new();face.font=font;face.custom_minimum_size=Vector2(220,220);face.size_flags_horizontal=Control.SIZE_EXPAND_FILL;grid.add_child(face)
	var choices_box=VBoxContainer.new();choices_box.size_flags_horizontal=Control.SIZE_EXPAND_FILL;choices_box.add_theme_constant_override("separation",10);grid.add_child(choices_box)
	for i in options.size():
		if str(options[i].value)==current_time:selected=i
		var choice=button("",choose.bind(i));choice.custom_minimum_size.y=54;buttons.append(choice);choices_box.add_child(choice)
	feedback_label=label("",16,Color("b9d88b"));feedback_label.custom_minimum_size.y=38;body.add_child(feedback_label)
	var commands=HBoxContainer.new();commands.add_theme_constant_override("separation",10);body.add_child(commands)
	submit_button=button("固定这一刻度",submit);submit_button.size_flags_horizontal=Control.SIZE_EXPAND_FILL;commands.add_child(submit_button)
	var back=button("暂不调节",func():close_requested.emit());back.size_flags_horizontal=Control.SIZE_EXPAND_FILL;commands.add_child(back)
	body.add_child(label("← / → 选择刻度 · Enter 确认 · Esc 返回",14,Color("b0bcae")))
	refresh();return true
func label(text:String,points:int,ink:Color)->Label:
	var node=Label.new();node.text=text;node.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;node.add_theme_font_size_override("font_size",points);node.add_theme_color_override("font_color",ink);return node
func button(text:String,callback:Callable)->Button:
	var node=Button.new();node.text=text;node.custom_minimum_size.y=44;node.add_theme_font_size_override("font_size",18);node.add_theme_color_override("font_color",Color("ead8a9"));node.add_theme_stylebox_override("normal",Ui.box(Color("142331"),Color("49626e"),1,0,Vector2(10,6)));
	for key in Ui.button_styles(Color("142331"),Color("ead8a9"),Color("49626e"),0,1,Vector2(10,6)):
		node.add_theme_stylebox_override(key,Ui.button_styles(Color("142331"),Color("ead8a9"),Color("49626e"),0,1,Vector2(10,6))[key])
	for key in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:node.add_theme_color_override(key,Color("ead8a9"))
	node.pressed.connect(callback);return node
func _ready():
	resized.connect(func():layout_panel(size));layout_panel(size);buttons[selected].grab_focus.call_deferred()
func _schedule_layout():
	if layout_pending:return
	layout_pending=true;_relayout.call_deferred()
func _relayout():
	layout_pending=false
	if is_inside_tree():layout_panel(size)
func layout_panel(available:Vector2):
	if frame==null:return
	grid.columns=1 if available.x<660 else 2
	face.custom_minimum_size=Vector2(180,180) if grid.columns==1 else Vector2(220,220)
	frame.size=Vector2(minf(720,available.x-24),minf(750 if grid.columns==1 else 480,available.y-24));frame.position=(available-frame.size)/2
func choose(index:int):
	if not live or pending:return
	selected=posmod(index,options.size());feedback_label.text="";refresh()
func refresh():
	if buttons.is_empty():return
	face.clock_text=str(options[selected].label);face.queue_redraw()
	for i in buttons.size():
		var value=str(options[i].value);var status="当前" if value==current_time else "刻痕清晰" if value==required_time else ""
		buttons[i].text=str(options[i].label)+( "  ·  "+status if not status.is_empty() else "")
		buttons[i].disabled=pending
		buttons[i].add_theme_stylebox_override("normal",Ui.box(Color("263f50" if i==selected else "1b303d" if value==current_time else "142331"),Color("8ca46a" if value==required_time else "d7b654" if i==selected else "49626e"),2 if i==selected else 1,0,Vector2(10,6)))
		buttons[i].add_theme_color_override("font_color",Color("79d4db" if value==current_time else "b9d88b" if value==required_time else "ead8a9"))
	submit_button.disabled=pending
func submit():
	if not live or pending:return
	var value=str(options[selected].value)
	if value==current_time:feedback_label.text="旧钟已经停在这一格；另一圈刻痕刚刚变得清晰。";return
	if value!=required_time:feedback_label.text="这处刻度仍会回弹。";return
	pending=true;feedback_label.text="齿轮正在咬合……";refresh();submit_requested.emit({"time":value})
func resolve(state:Dictionary,result:Dictionary):
	if not live:return
	pending=false
	if not sync_authority(state):close_requested.emit();return
	feedback_label.text=str(result.get("message",""));refresh()
func sync_authority(state:Dictionary)->bool:
	var c:Dictionary=state.get("chapter4",{})
	return live and c.get("floor","")=="A1" and c.get("mode","")=="light" and c.get("phase","")==phase and c.get("timeState","")==current_time and state.get("native",{}).get("c4_context","")=="clock"
func dispose_session():live=false
func owns_feedback()->bool:
	return live and pending
func handle_key(event:InputEventKey)->bool:
	if not live or not event.pressed or event.echo:return false
	if event.keycode in [KEY_LEFT,KEY_UP]:choose(selected-1);return true
	if event.keycode in [KEY_RIGHT,KEY_DOWN]:choose(selected+1);return true
	if event.keycode in [KEY_ENTER,KEY_KP_ENTER]:submit();return true
	if event.keycode==KEY_ESCAPE:close_requested.emit();return true
	return false
