extends ColorRect
## Native presentation of the original post-solved floor choices.
## Main dispatches controller-owned selection/cancel; this Control owns no progress.
signal selected_destination(value: Dictionary)
signal close_requested
signal cancelled(session: String)
const Ui=preload("res://scripts/ui/native_ui_theme.gd")
const FLOORS={"A1":["门厅 · 教室层","104 / 105 / 旧钟门厅"],"A2":["204 · 创客层","201 / 203 / 204 / 开放自习区"],"A3":["荣誉墙 · 档案层","301 / 302 / 303 / 304 / 荣誉墙"]}
var frame: PanelContainer
var choices: Array=[]
var buttons: Dictionary={}
var selected: String=""
var config: Dictionary={}
var read_state: Callable
var live:=true
var submitted:=false
var font: Font
var detail: Label
var records: Label
var primary: Button
var layout_pending:=false
var instructions: Label
func configure(value: Dictionary,state_reader: Callable,pixel_font: Font) -> bool:
	if value.get("session","").is_empty() or value.get("fromFloor","") not in FLOORS or value.get("phase","")!="room204_restore" or not state_reader.is_valid():return false
	config=value.duplicate(true);choices=config.get("destinations",[]).duplicate();read_state=state_reader;font=pixel_font
	if choices.is_empty() or choices.any(func(f):return f not in FLOORS or f==config.fromFloor):return false
	selected=choices[0]
	color=Color(.03,.06,.08,.88);mouse_filter=Control.MOUSE_FILTER_STOP;focus_mode=Control.FOCUS_ALL;z_index=100
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);theme=Ui.font_theme(font)
	frame=PanelContainer.new();frame.minimum_size_changed.connect(_schedule_layout);frame.add_theme_stylebox_override("panel",Ui.box(Color("08131f"),Color("d7b654"),2,0,Vector2(16,16)));add_child(frame)
	var body=VBoxContainer.new();body.add_theme_constant_override("separation",12);frame.add_child(body)
	var header=HBoxContainer.new();body.add_child(header)
	var title=label("主电梯 · 选择楼层",22,Color("f7f1dc"));title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;header.add_child(title)
	var close=button("× 离开",func():close_requested.emit());close.custom_minimum_size.x=92;header.add_child(close)
	body.add_child(label("当前："+config.fromFloor.substr(1)+"F · "+FLOORS[config.fromFloor][0],17,Color("79d4db")))
	var scroll=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;body.add_child(scroll)
	var content=VBoxContainer.new();content.size_flags_horizontal=Control.SIZE_EXPAND_FILL;content.add_theme_constant_override("separation",10);scroll.add_child(content)
	for floor_id: String in ["A1","A2","A3"]:
		var pick=button(floor_id.substr(1)+"F · "+FLOORS[floor_id][0],choose.bind(floor_id));pick.custom_minimum_size.y=54;pick.disabled=floor_id not in choices;buttons[floor_id]=pick;content.add_child(pick)
	detail=label("",17,Color("d8e7ec"));content.add_child(detail)
	var review=button("复核已归档记录 · Space",toggle_records);content.add_child(review)
	records=label(str(config.get("records","")),16,Color("d8e7ec"));records.visible=false;content.add_child(records)
	primary=button("",submit);primary.custom_minimum_size.y=50;body.add_child(primary)
	instructions=label("",14,Color("b8c7d2"));body.add_child(instructions)
	refresh();return true
func label(text: String,points: int,ink: Color) -> Label:
	var node=Label.new();node.text=text;node.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;node.add_theme_font_size_override("font_size",points);node.add_theme_color_override("font_color",ink);return node
func button(text: String,callback: Callable) -> Button:
	var node=Button.new();node.text=text;node.custom_minimum_size.y=44;node.add_theme_font_size_override("font_size",18)
	var styles:=Ui.button_styles(Color("17263a"),Color("f7f1dc"),Color("60768c"),0,2,Vector2(10,8))
	for key in styles:node.add_theme_stylebox_override(key,styles[key])
	for key in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:node.add_theme_color_override(key,Color("f7f1dc"))
	node.pressed.connect(callback);return node
func _ready() -> void:
	resized.connect(func():layout_panel(size));layout_panel(size);buttons[selected].grab_focus.call_deferred()
func _schedule_layout() -> void:
	if layout_pending:return
	layout_pending=true;_relayout.call_deferred()
func _relayout() -> void:
	layout_pending=false
	if is_inside_tree():layout_panel(size)
func layout_panel(available: Vector2) -> void:
	if frame==null:return
	if instructions!=null:instructions.text="↑↓ 选层 · Enter 执行\nSpace 复核 · Esc 离开" if available.x<660 else "↑↓ 选层 · Enter 执行 · Space 复核 · Esc 离开"
	frame.size=Vector2(minf(640,maxf(1,available.x-24)),minf(650,maxf(1,available.y-24)));frame.position=(available-frame.size)/2
func valid_context() -> bool:
	if not read_state.is_valid():return false
	var s: Dictionary=read_state.call();var c: Dictionary=s.get("chapter4",{})
	return s.get("native",{}).get("scene","")=="duan_yongping_temporal_maze" and c.get("floor","")==config.fromFloor and c.get("phase","")==config.phase and "misaligned_stair_solved" in c.get("factIds",[])
func _process(_delta: float) -> void:
	if live and not submitted and not valid_context():close_requested.emit()
func choose(value: String) -> void:
	if not live or submitted or value not in choices:return
	selected=value;refresh()
func refresh() -> void:
	if detail==null:return
	for floor_id in buttons:
		buttons[floor_id].add_theme_stylebox_override("normal",Ui.box(Color("274d63" if floor_id==selected else "17263a"),Color("d7b654" if floor_id==selected else "60768c"),2,0,Vector2(10,8)))
	detail.text=FLOORS[selected][1];primary.text="前往 "+selected.substr(1)+"F"
func toggle_records() -> void:
	if live and not submitted:records.visible=not records.visible
func submit() -> void:
	if not live or submitted or selected not in choices or not valid_context():return
	submitted=true;selected_destination.emit({"session":config.session,"destination":selected})
func dispose_session() -> void:
	if not live:return
	live=false
	if not submitted:cancelled.emit(str(config.get("session","")))
func _exit_tree() -> void:dispose_session()
func handle_key(event: InputEventKey) -> bool:
	if not live or submitted or not event.pressed or event.echo:return false
	if event.keycode in [KEY_UP,KEY_DOWN]:choose(choices[posmod(choices.find(selected)+(-1 if event.keycode==KEY_UP else 1),choices.size())]);return true
	if event.keycode in [KEY_ENTER,KEY_KP_ENTER]:submit();return true
	if event.keycode==KEY_SPACE:toggle_records();return true
	if event.keycode==KEY_ESCAPE:close_requested.emit();return true
	return false
