extends ColorRect
## Shared hall/phone workspace. Only Chapter4 owns durable operations.
signal intent_requested(event:Dictionary)
signal submit_requested(value:Dictionary)
signal cancel_requested(session:Dictionary)
signal close_requested
const VisualCard=preload("res://scripts/ui/clock_visual_card.gd")
const DelayBoard=preload("res://scripts/ui/clock_delay_board.gd")
const Model=preload("res://scripts/games/chapter4_clock_chain.gd")
const Mechanism=preload("res://scripts/objects/chapter4_clock_mechanism_view.gd")
const Ui=preload("res://scripts/ui/native_ui_theme.gd")
const Typography=preload("res://scripts/ui/native_typography.gd")
const PhoneChrome=preload("res://scripts/ui/phone_chrome.gd")
var frame:Control
var face:Control
var session:Dictionary={}
var checkpoint:Dictionary={}
var authority_owner:Dictionary={}
var spec:Dictionary={}
var required_time:=""
var current_time:=""
var phase:=""
var live:=true
var pending:=false
var font:Font
var controls:Dictionary={}
var feedback_label:Label
var physical_feedback:Label
var progress_label:Label
var physical:PanelContainer
var physical_body:VBoxContainer
var phone:PanelContainer
var phone_body:VBoxContainer
var tabs:HBoxContainer
var close_button:Button
var surface:="phone"
var mobile:=false
var notes_open:=false
var step_before:=-1
var reduced:=false
var draft_hour:=0
var draft_minute:=0
var channel_focus:=0

func configure(state:Dictionary,request:Dictionary,pixel_font:Font)->bool:
	if not request.has("session") or not Model.valid_run(request.get("checkpoint"),str(request.get("target",""))):return false
	authority_owner=state;session=request.session.duplicate(true);required_time=request.target;checkpoint=request.checkpoint.duplicate(true)
	spec=Model.data().runs[required_time];current_time=state.chapter4.timeState;phase=state.chapter4.phase;font=pixel_font
	reduced=bool(state.native.get("settings",{}).get("reduced_motion",false))
	color=Color(.025,.035,.04,.92);mouse_filter=Control.MOUSE_FILTER_STOP;focus_mode=Control.FOCUS_ALL;z_index=100
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);theme=Ui.font_theme(font)
	frame=Control.new();add_child(frame)
	tabs=HBoxContainer.new();tabs.add_theme_constant_override("separation",8);frame.add_child(tabs)
	tabs.add_child(button("旧钟",func():surface="hall";layout_panel(size),false))
	tabs.add_child(button("校时终端",func():surface="phone";layout_panel(size),false))
	var spacer=Control.new();spacer.size_flags_horizontal=Control.SIZE_EXPAND_FILL;tabs.add_child(spacer)
	close_button=button("返回现场",func():close_requested.emit(),false);tabs.add_child(close_button)
	physical=PanelContainer.new();physical.add_theme_stylebox_override("panel",Ui.box(Color("202725"),Color("665b44"),1,8,Vector2(20,16)));frame.add_child(physical)
	var mechanical_scroll=ScrollContainer.new();mechanical_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;physical.add_child(mechanical_scroll)
	physical_body=VBoxContainer.new();physical_body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;physical_body.size_flags_vertical=Control.SIZE_EXPAND_FILL;physical_body.add_theme_constant_override("separation",10);mechanical_scroll.add_child(physical_body)
	physical_body.add_child(label("大厅旧钟",25,Color("e1d3b8")))
	physical_body.add_child(label("钟壳刻印  /  "+spec.label,17,Color("aeac99")))
	face=Mechanism.new();face.font=font;face.symbol=spec.symbol;face.repair=spec.repair;face.reduced=reduced;face.custom_minimum_size=Vector2(180,220);face.size_flags_vertical=Control.SIZE_EXPAND_FILL;physical_body.add_child(face)
	physical_feedback=label("",16,Color("e5d8be"));physical_feedback.custom_minimum_size.y=24;physical_body.add_child(physical_feedback)
	phone=PanelContainer.new();phone.add_theme_stylebox_override("panel",Ui.box(Color("fafafa"),Color("d3d6d5"),1,18,Vector2.ZERO));phone.custom_minimum_size=Vector2(430,860);phone.size=Vector2(430,860);frame.add_child(phone)
	var phone_canvas=Control.new();phone.add_child(phone_canvas)
	var seconds:int=int(state.chapter4.phoneStatusTimeSeconds)
	var status=label("%02d:%02d"%[seconds/3600,(seconds%3600)/60],17,Color("252a29"));status.position=Vector2(24,12);status.size=Vector2(220,28);phone_canvas.add_child(status)
	var icons=PhoneChrome.StatusIcons.new();icons.network=state.networkMode;icons.percent=float(state.phoneBattery.percent);icons.network_x=0;icons.battery_x=32;icons.position=Vector2(348,10);icons.size=Vector2(62,30);phone_canvas.add_child(icons)
	var header=label("校时终端",25,Color("202823"));header.position=Vector2(24,54);header.size=Vector2(300,38);phone_canvas.add_child(header)
	progress_label=label("",17,Color("47715a"));progress_label.position=Vector2(24,99);progress_label.size=Vector2(382,32);phone_canvas.add_child(progress_label)
	var scroll=ScrollContainer.new();scroll.position=Vector2(24,147);scroll.size=Vector2(382,570);scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;phone_canvas.add_child(scroll)
	phone_body=VBoxContainer.new();phone_body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;phone_body.add_theme_constant_override("separation",12);scroll.add_child(phone_body)
	feedback_label=label("",17,Color("42604d"));feedback_label.position=Vector2(24,736);feedback_label.size=Vector2(382,77);phone_canvas.add_child(feedback_label)
	var home=ColorRect.new();home.color=Color("252a29");home.position=Vector2(157,837);home.size=Vector2(116,4);home.mouse_filter=Control.MOUSE_FILTER_IGNORE;phone_canvas.add_child(home)
	refresh();return true
func label(text:String,points:int,ink:Color)->Label:
	var node=Label.new();Typography.apply_body(node);node.text=text;node.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;node.add_theme_font_size_override("font_size",points);node.add_theme_color_override("font_color",ink);node.mouse_filter=Control.MOUSE_FILTER_IGNORE;return node
func button(text:String,callback:Callable,light:bool=true)->Button:
	var node=Button.new();Typography.apply_body(node);node.text=text;node.custom_minimum_size.y=48;node.add_theme_font_size_override("font_size",18)
	var bg:=Color("eef2ef") if light else Color("333c36")
	var fg:=Color("243f31") if light else Color("ece1c8")
	var styles:Dictionary=Ui.button_styles(bg,fg,Color("b9c8be") if light else Color("827659"),5,1,Vector2(12,8))
	for key in styles:node.add_theme_stylebox_override(key,styles[key])
	for key in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:node.add_theme_color_override(key,fg)
	node.pressed.connect(callback);return node
func action_button(parent:Control,id:String,text:String,event:Dictionary,light:bool=true)->Button:
	var node=button(text,send.bind(event),light);node.size_flags_horizontal=Control.SIZE_EXPAND_FILL;parent.add_child(node);controls[id]=node;return node
func clear_children(node:Node)->void:
	for child in node.get_children():node.remove_child(child);child.queue_free()
func visual(parent:Control,key:String,kind:String,id:String,height:float,event:Dictionary={},details:Dictionary={})->Button:
	var tile=VisualCard.new();tile.kind=kind;tile.id=id;tile.spec=details.get("spec",spec).duplicate(true);tile.font=Typography.body_font();tile.chosen=details.get("chosen",false);tile.caption=details.get("caption","");tile.drift=float(details.get("drift",0));tile.settled=details.get("settled",false);tile.samples=int(checkpoint.samples);tile.reduced=reduced
	tile.custom_minimum_size.y=height;tile.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	for style in Ui.button_styles(Color("eef1eb"),Color("34463c"),Color("c3cbbf"),5,1,Vector2(4,4)):tile.add_theme_stylebox_override(style,Ui.button_styles(Color("eef1eb"),Color("34463c"),Color("c3cbbf"),5,1,Vector2(4,4))[style])
	parent.add_child(tile)
	if not event.is_empty():tile.pressed.connect(send.bind(event));controls[key]=tile
	else:tile.mouse_filter=Control.MOUSE_FILTER_IGNORE;tile.focus_mode=Control.FOCUS_NONE
	return tile
func refresh()->void:
	var focused=get_viewport().gui_get_focus_owner() if is_inside_tree() else null
	var focus_id:=""
	for id in controls:
		if controls[id]==focused:focus_id=id
	controls.clear();clear_children(phone_body)
	var step:=int(checkpoint.step)
	progress_label.text="%d / 7   %s"%[mini(step+1,7),Model.data().stages[mini(step,6)]]
	var top=HBoxContainer.new();phone_body.add_child(top)
	var seal=label(spec.label,20,Color("34463c"));seal.size_flags_horizontal=Control.SIZE_EXPAND_FILL;top.add_child(seal)
	var note_toggle=button("收起记录" if notes_open else "记录",func():notes_open=not notes_open;refresh());top.add_child(note_toggle);controls.notes=note_toggle
	if notes_open:
		phone_body.add_child(label(spec.inspection,17,Color("5b635e")))
		for record in spec.records:
			if record.id in checkpoint.evidence:phone_body.add_child(label(record.title+"\n"+record.body,17,Color("5b635e")))
		if step==0:
			for source in Model.data().sources:
				var details:String=source.title+"\n"+source.body
				if source.id=="phone" and required_time!="1225_bakery":details="手机上一轮记录\n没有本次安装零件后的现场脉冲。"
				phone_body.add_child(label(details,17,Color("5b635e")))
		if step==3:phone_body.add_child(label(spec.repairHint,17,Color("5b635e")))
	match step:
		0:
			for source in Model.data().sources:
				var time_label:String="07:55:23" if required_time=="1225_bakery" else "12:25" if required_time=="1850_evening" else "18:50"
				visual(phone_body,"source_"+source.id,"source",source.id,90,{"kind":"source","id":source.id},{"caption":time_label}).tooltip_text=source.body
		1:
			var cards=GridContainer.new();cards.columns=2;cards.add_theme_constant_override("h_separation",10);cards.add_theme_constant_override("v_separation",10);phone_body.add_child(cards)
			for index in [3,0,4,2,1]:
				var record:Dictionary=spec.records[index]
				visual(cards,"evidence_"+record.id,"evidence",record.id,124,{"kind":"evidence","id":record.id},{"chosen":record.id in checkpoint.evidence}).tooltip_text=record.title+"\n"+record.body
			action_button(phone_body,"link","拼合  %d / 3"%checkpoint.evidence.size(),{"kind":"link"})
		2:
			visual(phone_body,"","timeline","",116)
			visual(phone_body,"","target","draft",120,{}, {"spec":{"hour":draft_hour,"minute":draft_minute}})
			for axis:String in ["hour","minute"]:
				var row=HBoxContainer.new();row.add_theme_constant_override("separation",8);phone_body.add_child(row)
				var title=label("时针记录" if axis=="hour" else "分针记录",18,Color("34463c"));title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(title)
				for direction:int in [-1,1]:
					var control=button("−" if direction<0 else "+",func():
						if axis=="hour":draft_hour=posmod(draft_hour+direction,24)
						else:draft_minute=posmod(draft_minute+direction*5,60)
						refresh())
					control.custom_minimum_size.x=64;row.add_child(control);controls["draft_"+axis+("_minus" if direction<0 else "_plus")]=control
			action_button(phone_body,"target_commit","将推算盖入记录",{"kind":"target","hour":draft_hour,"minute":draft_minute})
		3,4:
			visual(phone_body,"","target","",145)
			var switch=button("查看旧钟",func():surface="hall";layout_panel(size));phone_body.add_child(switch);controls.hall=switch
		5:
			var board=DelayBoard.new();board.run_id=required_time;board.trims=checkpoint.trims.duplicate(true);board.selected=channel_focus
			board.custom_minimum_size=Vector2(0,322);board.size_flags_horizontal=Control.SIZE_EXPAND_FILL
			board.tooltip_text="左右拖动延迟轮；点轮的左半边或右半边微调。键盘上下选轮、左右调节。"
			board.edited.connect(func(channel:String,value:int):channel_focus=board.selected;send({"kind":"trim","channel":channel,"correction":value}))
			phone_body.add_child(board);controls.circuit=board
			action_button(phone_body,"balance","接通三路试脉冲",{"kind":"balance"})
		6:
			phone_body.add_child(label("每格 %d 秒"%int(spec.pulseInterval),17,Color("687269")))
			var sample=action_button(phone_body,"sample","采样  %d / 3"%int(checkpoint.samples),{"kind":"sample"});sample.disabled=checkpoint.samples>=3
			var signals:Array=["frozen","drift","live"]
			if required_time=="1850_evening":signals=["live","frozen","drift"]
			elif required_time=="2245_maintenance":signals=["drift","live","frozen"]
			for i in 3:
				var control=visual(phone_body,"verify_"+signals[i],"verify",signals[i],89,{"kind":"verify","id":signals[i]},{"caption":["A","B","C"][i]});control.disabled=checkpoint.samples<3
		7:
			visual(phone_body,"","ready","",176)
	controls.merge(face.configure_interaction(step,send,checkpoint.locks))
	if step_before!=step:surface="hall" if step in [3,4,7] else "phone";step_before=step
	face.show_checkpoint(checkpoint)
	if is_inside_tree():
		layout_panel(size)
		if controls.has(focus_id):controls[focus_id].grab_focus.call_deferred()
func _ready()->void:
	resized.connect(func():layout_panel(size));layout_panel(size);close_button.grab_focus.call_deferred()
func layout_panel(available:Vector2)->void:
	if frame==null:return
	mobile=available.x<760
	frame.size=Vector2(minf(1080,available.x-16),available.y-16);frame.position=(available-frame.size)/2
	tabs.position=Vector2.ZERO;tabs.size=Vector2(frame.size.x,48)
	var height:float=frame.size.y-58
	var phone_scale:float=minf(height/860.0,(frame.size.x if mobile else frame.size.x*.44)/430.0)
	phone.scale=Vector2.ONE*phone_scale;phone.position=Vector2((frame.size.x-430*phone_scale)/2 if mobile else frame.size.x-430*phone_scale,58+(height-860*phone_scale)/2)
	physical.position=Vector2(0,58);physical.size=Vector2(frame.size.x if mobile else frame.size.x-430*phone_scale-20,height)
	physical.visible=not mobile or surface=="hall";phone.visible=not mobile or surface=="phone"
	face.custom_minimum_size.y=430
func send(event:Dictionary)->void:
	if event.get("kind","")=="commit":submit();return
	if not live or pending:return
	pending=true;intent_requested.emit(event)
func submit()->void:
	if not live or pending or checkpoint.step!=7:return
	pending=true;submit_requested.emit({"time":required_time,"session":session})
func resolve(state:Dictionary,result:Dictionary)->void:
	if not live:return
	pending=false
	if not sync_authority(state):close_requested.emit();return
	var movement:=""
	if result.has("clock"):checkpoint=result.clock.checkpoint.duplicate(true);movement=result.clock.get("motion","")
	var old_hour:float=face.hour_angle;var old_minute:float=face.minute_angle
	refresh();face.hour_angle=old_hour;face.minute_angle=old_minute;face.show_checkpoint(checkpoint,movement)
	var message:String=""
	if not result.get("accepted",false) and not str(result.get("message","")).is_empty():
		message=["信号未更新","刻印不吻合","时间片未对齐","仍在打滑","指针尚未对齐","脉冲仍有偏差","信号未同步","请重新接入"][int(checkpoint.step)]
	feedback_label.text=message;physical_feedback.text=message
func sync_authority(state:Dictionary)->bool:
	var c:Dictionary=state.get("chapter4",{})
	return live and is_same(state,authority_owner) and state.get("runtimeMode","")=="rpg" and state.get("rpgScene","")=="duan_yongping_temporal_maze" and c.get("floor","")=="A1" and c.get("mode","")=="light" and c.get("phase","")==phase and c.get("timeState","")==current_time and state.get("native",{}).get("c4_context","")=="clock"
func dispose_session()->void:
	if not live:return
	live=false;face.dispose();cancel_requested.emit(session)
func owns_feedback()->bool:return live and pending
func handle_key(event:InputEventKey)->bool:
	if not live or not event.pressed or event.echo:return false
	if event.keycode==KEY_ESCAPE:close_requested.emit();return true
	return false
