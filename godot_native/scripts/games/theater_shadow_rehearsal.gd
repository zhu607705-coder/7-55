extends Control
## Physical prop manipulation over one bounded stage, with replay-only completion.
signal completed(result: Dictionary)
signal cancelled
const Model=preload("res://scripts/games/theater_shadow_rehearsal_model.gd")
const Ui=preload("res://scripts/ui/native_ui_theme.gd")
const TheaterUi=preload("res://scripts/ui/theater_typography.gd")
const PerformanceView=preload("res://scripts/presentation/liangzhu_performance.gd")
const StagePlate=preload("res://scripts/presentation/liangzhu_stage_plate.gd")
const FanView=preload("res://scripts/presentation/theater_rehearsal_fan.gd")
const LOGICAL=Vector2(960,540)
const ASSET_ROOT="res://assets/native/theater_rebuild_20261020/"
const PAPER=Color("F4EAD5")
const INK=Color("202B35")
var performance:Control
var performance_restore:Dictionary={}
var config: Dictionary={}
var model: RefCounted
var state: Dictionary={}
var controls: Dictionary={}
var textures: Dictionary={}
var title_label: Label
var status_label: Label
var feedback_label: Label
var stage_hud:Control
var cue_sheet:=Rect2(20,436,380,92)
var feedback_sheet:=Rect2(548,432,392,96)
var help_panel: PanelContainer
var help_title: Label
var help_body: RichTextLabel
var help_next: Button
var help_close: Button
var field=Rect2()
var selected := "left_fan"
var paused := false
var help_open := false
var done := false
var disposed := false
var pointer_id := -99
var drag_id := ""
var drag_offset := Vector2.ZERO
var held: Dictionary={}
var key_clock := 0.0
var last_touch_ms := -1000
var built := false
var undo_groups: Array[int]=[]
var drag_steps := 0
var last_round := -1
var coarse := false
var touch_seen := false
var menu_panel: PanelContainer
var menu_controls: Dictionary={}
var menu_open := false
var rotation_label: Label
var fingers: Dictionary={}
var gesture_age := 0.0
var gesture_moved := false
var gesture_consumed := false
var two_fingers := false
var lamp_armed := false
var drag_kind := "move"
var fold_keys := false
var presentation_clock := 0.0
var trial_age := 10.0
var curtain_age := 2.0
const HOLD_SECONDS := 0.6
const TOUCH_SLOP := 10.0

func setup(value: Dictionary) -> void:
	config=value.duplicate(true);model=Model.new();state=model.snapshot()
	selected="left_fan";paused=false;help_open=false;menu_open=false;done=false;disposed=false
	_clear_input();undo_groups.clear();last_round=-1
	if is_inside_tree():_build();_refresh();_intro()

func uses_activity_layout() -> bool:return true
func configure_activity_layout(available: Vector2,_compact: bool) -> void:
	if size!=available:_clear_input()
	custom_minimum_size=Vector2.ZERO;scale=Vector2.ONE;position=Vector2.ZERO;size=available.max(Vector2(240,240));_layout()

func _ready() -> void:
	name="TheaterShadowRehearsal";mouse_filter=Control.MOUSE_FILTER_STOP;focus_mode=Control.FOCUS_ALL
	coarse=DisplayServer.is_touchscreen_available()
	_build();resized.connect(_layout);visibility_changed.connect(_visibility_changed);get_window().focus_exited.connect(_focus_out)
	if model!=null:_refresh()
	if model!=null:_intro()
	grab_focus.call_deferred()

func _label(id: String,pixels: int) -> Label:
	var label=Label.new();label.name=id;TheaterUi.text(label);label.add_theme_font_size_override("font_size",pixels);label.add_theme_color_override("font_color",PAPER);label.mouse_filter=Control.MOUSE_FILTER_IGNORE;label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;add_child(label);return label
func _button(id: String,text: String,action: Callable) -> Button:
	var button=Button.new();button.name=id;button.text=text;button.focus_mode=Control.FOCUS_NONE
	TheaterUi.button(button,id in ["RehearsalTry","RehearsalNext"]);button.pressed.connect(action);controls[id]=button;add_child(button);return button
func _build() -> void:
	if built:return
	built=true;TheaterUi.apply(self)
	for id: String in ["fan_closed","fan_open","lantern","side_screen"]:
		var path: String=ASSET_ROOT+id+".png"
		if ResourceLoader.exists(path):textures[id]=load(path)
	if ResourceLoader.exists(StagePlate.TEXTURE_PATH):textures.stage=load(StagePlate.TEXTURE_PATH)
	for id:String in StagePlate.FURNITURE_IDS:
		var path:String=str(StagePlate.furniture().get("props",{}).get(id,{}).get("texture",""))
		if not path.is_empty() and ResourceLoader.exists(path):textures[id]=load(path)
	title_label=_label("RehearsalTitle",24);status_label=_label("RehearsalProgress",15);feedback_label=_label("RehearsalFeedback",17)
	TheaterUi.heading(title_label)
	stage_hud=Control.new();stage_hud.name="RehearsalStageFrame";stage_hud.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(stage_hud)
	for label:Label in [title_label,status_label,feedback_label]:label.reparent(stage_hud);label.add_theme_color_override("font_color",INK)
	rotation_label=_label("RehearsalRotate",24);rotation_label.text="把屏幕横过来\n让舞台铺开。";rotation_label.autowrap_mode=TextServer.AUTOWRAP_OFF;rotation_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;rotation_label.add_theme_color_override("font_color",INK)
	_button("RehearsalExit","返回现场",_cancel);_button("RehearsalHelp","观察",_help);_button("RehearsalPause","暂停",_pause)
	_button("RehearsalWatch","合演一段",_watch_performance)
	_button("RehearsalUndo","撤回",_undo);_button("RehearsalRestart","重排本幕",func():_clear_input();_apply({"kind":"restart"}))
	_button("RehearsalTry","演一遍",_try_stage);_button("RehearsalNext","下一幕",_continue_stage)
	_button("RehearsalSelect","换一件",_cycle_selection)
	for spec: Array in [["RehearsalLeft","←",Vector2(-0.12,0)],["RehearsalRight","→",Vector2(0.12,0)],["RehearsalForward","向幕",Vector2(0,0.12)],["RehearsalBack","向灯",Vector2(0,-0.12)]]:
		var delta: Vector2=spec[2];_button(spec[0],spec[1],func():_nudge(delta))
	help_panel=PanelContainer.new();help_panel.name="RehearsalReading";help_panel.add_theme_stylebox_override("panel",Ui.box(PAPER,Color("A39B87"),1,2,Vector2(18,16)));add_child(help_panel)
	var column=VBoxContainer.new();column.add_theme_constant_override("separation",14);help_panel.add_child(column)
	help_title=Label.new();help_title.add_theme_font_size_override("font_size",24);help_title.add_theme_color_override("font_color",INK);TheaterUi.heading(help_title);column.add_child(help_title)
	help_body=RichTextLabel.new();TheaterUi.text(help_body);help_body.fit_content=false;help_body.scroll_active=true;help_body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;help_body.add_theme_font_size_override("normal_font_size",18);help_body.add_theme_color_override("default_color",INK);help_body.size_flags_vertical=Control.SIZE_EXPAND_FILL;column.add_child(help_body)
	help_next=Button.new();help_next.name="RehearsalNextHint";help_next.text="再观察一层";help_next.custom_minimum_size.y=44;TheaterUi.button(help_next);help_next.pressed.connect(_next_hint);column.add_child(help_next)
	help_close=Button.new();help_close.name="RehearsalCloseReading";help_close.text="回到舞台";help_close.custom_minimum_size.y=44;TheaterUi.button(help_close,true);help_close.pressed.connect(_close_help);column.add_child(help_close)
	help_panel.hide()
	menu_panel=PanelContainer.new();menu_panel.name="RehearsalPaperMenu";menu_panel.add_theme_stylebox_override("panel",Ui.box(PAPER,Color("8d6b45"),2,4,Vector2(16,12)));add_child(menu_panel)
	var menu_column=VBoxContainer.new();menu_column.add_theme_constant_override("separation",6);menu_panel.add_child(menu_column)
	var menu_title=Label.new();menu_title.text="排练单";menu_title.add_theme_font_size_override("font_size",22);menu_title.add_theme_color_override("font_color",INK);TheaterUi.heading(menu_title);menu_column.add_child(menu_title)
	for spec: Array in [["RehearsalMenuClose","回到舞台",_close_menu],["RehearsalMenuUndo","撤回",_menu_undo],["RehearsalMenuRestart","重排本幕",_menu_restart],["RehearsalMenuPause","暂停",_menu_pause],["RehearsalMenuExit","返回现场",_cancel]]:
		var button=Button.new();button.name=spec[0];button.text=spec[1];button.custom_minimum_size.y=44;button.focus_mode=Control.FOCUS_NONE;TheaterUi.button(button,spec[0]=="RehearsalMenuClose");button.pressed.connect(spec[2]);menu_controls[spec[0]]=button
		if spec[0]=="RehearsalMenuClose":
			var row:=HBoxContainer.new();row.add_theme_constant_override("separation",8);menu_column.add_child(row)
			button.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(button)
			var watch:=Button.new();watch.name="RehearsalMenuWatch";watch.text="合演一段";watch.focus_mode=Control.FOCUS_NONE;watch.custom_minimum_size.y=44;watch.size_flags_horizontal=Control.SIZE_EXPAND_FILL
			TheaterUi.button(watch);watch.pressed.connect(_watch_performance);row.add_child(watch);menu_controls.RehearsalMenuWatch=watch
		else:menu_column.add_child(button)
	menu_panel.hide();_layout()

func touch_layout() -> bool:return coarse or touch_seen
func touch_landscape() -> bool:return touch_layout() and size.x>=size.y

func _place(id: String,rect: Rect2) -> void:
	controls[id].position=rect.position;controls[id].size=rect.size
func _layout() -> void:
	if not built:return
	if is_instance_valid(performance):performance.configure_activity_layout(size,false)
	var portrait: bool=size.x<size.y
	if touch_layout():
		feedback_label.add_theme_color_override("font_color",INK)
		feedback_label.visible=not portrait
		var available=Vector2(size.x-16,size.y-(16 if portrait else 0))
		var stage_width: float=minf(available.x,available.y*16.0/9.0)
		field=Rect2(Vector2((size.x-stage_width)/2,8 if portrait else 0),Vector2(stage_width,stage_width*9/16))
		for button: Button in controls.values():button.hide()
		if portrait:
			controls.RehearsalExit.show();controls.RehearsalHelp.show();controls.RehearsalWatch.show()
			var row_width:float=(size.x-48)/3.0;var row_y:float=field.end.y+164
			_place("RehearsalHelp",Rect2(16,row_y,row_width,44));_place("RehearsalWatch",Rect2(24+row_width,row_y,row_width,44));_place("RehearsalExit",Rect2(32+row_width*2,row_y,row_width,44))
		rotation_label.visible=portrait;rotation_label.position=Vector2(24,field.end.y+40);rotation_label.size=Vector2(size.x-48,100)
		_layout_reading()
		menu_panel.position=Vector2((size.x-minf(360,size.x-32))/2,(size.y-326)/2);menu_panel.size=Vector2(minf(360,size.x-32),326)
		_layout_stage_hud();_hide_under_performance();queue_redraw();return
	rotation_label.hide();feedback_label.add_theme_color_override("font_color",INK);feedback_label.show()
	for id: String in ["RehearsalExit","RehearsalHelp","RehearsalPause","RehearsalUndo","RehearsalRestart","RehearsalWatch"]:controls[id].show()
	controls.RehearsalNext.visible=state.get("screen","")=="round_complete";controls.RehearsalTry.visible=not controls.RehearsalNext.visible
	var top: float=116 if portrait else 78
	var bottom: float=244 if portrait else 12
	var width: float=minf(size.x-24,(size.y-top-bottom)*16.0/9.0)
	width=maxf(180,width);field=Rect2(Vector2((size.x-width)/2,top),Vector2(width,width*9/16))
	var menu_y: float=76 if portrait else 12
	_place("RehearsalWatch",Rect2(size.x-476,menu_y,140,44))
	_place("RehearsalExit",Rect2(size.x-132,menu_y,116,44));_place("RehearsalHelp",Rect2(size.x-228,menu_y,84,44));_place("RehearsalPause",Rect2(size.x-324,menu_y,84,44))
	var actions_y: float=field.end.y+12
	var each: float=minf(196,(size.x-48)/3)
	var action_left: float=(size.x-each*3-24)/2
	_place("RehearsalUndo",Rect2(action_left,actions_y,each,44));_place("RehearsalRestart",Rect2(action_left+12+each,actions_y,each,44));_place("RehearsalTry",Rect2(action_left+24+each*2,actions_y,each,44));_place("RehearsalNext",Rect2(action_left+24+each*2,actions_y,each,44))
	var touch_y: float=actions_y+112 if portrait else actions_y+84
	if portrait:_place("RehearsalWatch",Rect2(12,touch_y,size.x-24,44))
	var touch: bool=coarse or touch_seen
	for id: String in ["RehearsalSelect","RehearsalLeft","RehearsalRight","RehearsalForward","RehearsalBack"]:controls[id].visible=touch
	var unit: float=(size.x-48)/5
	for i in 5:_place(["RehearsalSelect","RehearsalLeft","RehearsalRight","RehearsalForward","RehearsalBack"][i],Rect2(8+(unit+8)*i,touch_y,unit,44))
	for id:String in ["RehearsalUndo","RehearsalRestart","RehearsalTry","RehearsalNext","RehearsalSelect","RehearsalLeft","RehearsalRight","RehearsalForward","RehearsalBack"]:controls[id].hide()
	_layout_reading()
	menu_panel.position=Vector2((size.x-minf(360,size.x-32))/2,(size.y-326)/2);menu_panel.size=Vector2(minf(360,size.x-32),326)
	_layout_stage_hud();_hide_under_performance();queue_redraw()

func _layout_reading() -> void:
	var width: float=minf(680,size.x-32)
	var font: Font=help_body.get_theme_font("normal_font")
	var measured: float=font.get_multiline_string_size(help_body.text,HORIZONTAL_ALIGNMENT_LEFT,width-52,18).y
	var lines: int=maxi(1,ceili(measured/font.get_height(18)))
	var actions: int=2 if help_next.visible else 1
	var content_height: float=measured+maxi(0,lines-1)*6+38+actions*44+(actions+1)*14+44
	var top: float=32 if touch_layout() else (124 if size.x<size.y else 76)
	var height: float=minf(maxf(240,content_height),size.y-top-24)
	help_panel.position=Vector2((size.x-width)/2,maxf(top,(size.y-height)/2))
	help_panel.size=Vector2(width,height)

func _layout_stage_hud()->void:
	var fit:float=field.size.x/LOGICAL.x
	stage_hud.position=field.position;stage_hud.size=LOGICAL;stage_hud.scale=Vector2.ONE*fit
	stage_hud.visible=not is_instance_valid(performance)
	var title_px:int=maxi(18,ceili(18.0/fit));var body_px:int=maxi(14,ceili(14.0/fit))
	var title_height:float=ceilf(title_label.get_theme_font("font").get_height(title_px))
	var body_height:float=ceilf(status_label.get_theme_font("font").get_height(body_px))
	title_label.add_theme_font_size_override("font_size",title_px);status_label.add_theme_font_size_override("font_size",body_px)
	var compact:bool=size.x<size.y
	var sheet_height:float=maxf(58,body_height+20 if compact else title_height+body_height+18)
	cue_sheet=Rect2(20,528-sheet_height,440 if compact else 270,sheet_height)
	title_label.visible=not compact
	title_label.position=cue_sheet.position+Vector2(20,8);title_label.size=Vector2(cue_sheet.size.x-32,title_height)
	status_label.position=cue_sheet.position+Vector2(20,(sheet_height-body_height)/2 if compact else title_height+10);status_label.size=Vector2(cue_sheet.size.x-32,body_height)
	var feedback_height:float=feedback_label.get_theme_font("font").get_multiline_string_size(feedback_label.text,HORIZONTAL_ALIGNMENT_LEFT,368,body_px).y
	feedback_sheet=Rect2(548,528-maxf(96,feedback_height+16),392,maxf(96,feedback_height+16))
	feedback_label.position=feedback_sheet.position+Vector2(12,8);feedback_label.size=feedback_sheet.size-Vector2(24,16)
	feedback_label.add_theme_font_size_override("font_size",body_px)

func _hud_nodes()->Array[Control]:
	var nodes:Array[Control]=[stage_hud,rotation_label,help_panel,menu_panel]
	for button:Button in controls.values():nodes.append(button)
	return nodes

func _hide_under_performance()->void:
	if is_instance_valid(performance):
		for node:Control in _hud_nodes():node.hide()

func _refresh() -> void:
	if model==null:return
	state=model.snapshot();title_label.text="借扇成蝶";status_label.text="%d/3 ·%s"%[int(state.round)+1,state.title]
	if int(state.round)!=last_round:undo_groups.clear();drag_steps=0;last_round=int(state.round)
	controls.RehearsalNext.hide();controls.RehearsalTry.hide()
	controls.RehearsalTry.text="收幕" if state.screen=="complete" else "演一遍"
	controls.RehearsalUndo.disabled=not state.undoAvailable or state.screen!="playing";controls.RehearsalRestart.disabled=state.screen!="playing"
	# Failure is shown at the physical shadow. Detailed copy stays in Observation.
	feedback_label.text=""
	if built and field.size.x>0:_layout_stage_hud()
	queue_redraw()
func _apply(action: Dictionary) -> bool:
	if disposed or done or paused or help_open or menu_open or model==null or is_instance_valid(performance):return false
	var accepted: bool=model.apply(action)
	if accepted:
		if action.kind in ["move","spread","lamp"]:
			if not drag_id.is_empty():drag_steps+=1
			else:undo_groups.append(1)
		elif action.kind=="restart":undo_groups.append(1)
		_refresh()
	return accepted
func _undo() -> void:
	_clear_input()
	var count: int=undo_groups.pop_back() if not undo_groups.is_empty() else 1
	for i in count:
		if not _apply({"kind":"undo"}):break
func _try_stage() -> void:
	if state.get("screen")=="complete":_finish();return
	_clear_input()
	if _apply({"kind":"try"}):trial_age=0.0
func _continue_stage() -> void:
	_clear_input()
	if _apply({"kind":"continue"}):selected="left_fan";curtain_age=0.0;trial_age=10.0
func _finish() -> void:
	if done or disposed or state.get("screen")!="complete" or is_instance_valid(performance):return
	done=true;_clear_input();completed.emit(model.proof(config.get("session",{})))
func _cancel() -> void:
	if disposed or done:return
	_stop_performance()
	disposed=true;_clear_input();cancelled.emit()
func _selected_object() -> Dictionary:
	for object: Dictionary in state.get("objects",[]):
		if object.id==selected:return object
	return {}
func _cycle_selection() -> void:
	if paused or help_open or menu_open or state.get("screen")!="playing":return
	var objects: Array=state.objects.duplicate()
	if state.get("lampMovable",false):objects.append({"id":"lamp"})
	for i in objects.size():
		if objects[i].id==selected:selected=objects[(i+1)%objects.size()].id;queue_redraw();return
func _nudge(delta: Vector2) -> void:
	if selected=="lamp":_move_lamp(float(state.lampX)+delta.x);return
	var object: Dictionary=_selected_object()
	if object.is_empty():return
	if fold_keys and object.kind=="fan":_spread_prop(selected,float(object.spread)+delta.x*.5);return
	var next: Vector2=Vector2(float(object.x),float(object.depth))+Vector2(delta.x,delta.y if object.depthMovable else 0.0)
	_move_prop(selected,next)
func _move_prop(id: String,next: Vector2) -> void:
	if paused or help_open or menu_open or done or disposed or state.get("screen")!="playing":return
	var object: Dictionary={}
	for candidate: Dictionary in state.objects:
		if candidate.id==id:object=candidate;break
	if object.is_empty():return
	next.x=clampf(next.x,-4.5,4.5);next.y=clampf(next.y,3.0,7.0) if object.depthMovable else float(object.depth)
	var start=Vector2(float(object.x),float(object.depth));var distance: float=start.distance_to(next)
	if distance<0.0001:return
	var steps: int=ceili(distance/0.5)
	for i in range(1,steps+1):
		var point: Vector2=start.lerp(next,float(i)/steps)
		if not _apply({"kind":"move","id":id,"x":point.x,"depth":point.y}):break

func _spread_prop(id:String,value:float)->void:
	var object:Dictionary={}
	for candidate:Dictionary in state.objects:
		if candidate.id==id:object=candidate;break
	if object.is_empty() or object.kind!="fan":return
	value=clampf(value,.25,1.0)
	var start:float=object.spread
	if is_equal_approx(start,value):return
	var steps:int=ceili(absf(value-start)/.18)
	for i:int in range(1,steps+1):
		if not _apply({"kind":"spread","id":id,"value":lerpf(start,value,float(i)/steps)}):break

func _move_lamp(value:float)->void:
	if not state.get("lampMovable",false):return
	value=clampf(value,-Model.LAMP_LIMIT,Model.LAMP_LIMIT)
	var start:float=state.lampX
	if is_equal_approx(start,value):return
	var steps:int=ceili(absf(value-start)/.5)
	for i:int in range(1,steps+1):
		if not _apply({"kind":"lamp","x":lerpf(start,value,float(i)/steps)}):break

func lamp_rect()->Rect2:
	return Rect2(StagePlate.REHEARSAL_LAMP.position+Vector2(float(state.get("lampX",0.0))*56,0),StagePlate.REHEARSAL_LAMP.size)

func _begin_lamp(id:int,local:Vector2)->void:
	pointer_id=id;lamp_armed=true;drag_id="lamp";drag_kind="lamp"
	drag_offset=Vector2(float(state.lampX)*56,0)-_logical(local)
	held.clear();grab_focus();queue_redraw()

func _intro() -> void:
	_clear_input();help_open=true;help_title.text="借扇成蝶"
	help_body.text="扇影要合上幕上的旧痕。\n\n拖动底座移动道具，拉动扇骨铜扣开合，点灯试演。\n\n手机横过来即可操作；按住物件观察，双指轻触撤回。键盘可用 Tab 选物、方向键移动，Shift＋左右键开合，空格试演。"
	help_next.hide();help_close.text="开始排练";help_panel.show();_layout_reading();help_panel.move_to_front()
func _help() -> void:
	if disposed or done:return
	_clear_input();help_open=true
	if int(state.hintTier)==0:model.apply({"kind":"hint"});state=model.snapshot()
	help_title.text="排练手记"
	help_close.text="回到舞台"
	help_body.text=Model.failure_text(str(state.failure))+"\n\n"+Model.hint(int(state.round),int(state.hintTier))+"\n\n拖底座移动；拉扇骨铜扣开合；点灯试演。键盘：Tab 选物，方向键移动，Shift＋左右键开合，空格试演，Z 撤回，R 重排。"
	help_next.visible=state.screen=="playing" and int(state.hintTier)<3;help_panel.show();_layout_reading();help_panel.move_to_front()
func _next_hint() -> void:
	if model==null or not help_open:return
	model.apply({"kind":"hint"});state=model.snapshot();_help()
func _close_help() -> void:
	help_open=false;help_panel.hide();_clear_input();_layout();grab_focus()
func _open_menu() -> void:
	if disposed or done or help_open:return
	_clear_input();menu_open=true;menu_panel.show();menu_panel.move_to_front()
	menu_controls.RehearsalMenuPause.text="继续" if paused else "暂停"
	menu_controls.RehearsalMenuUndo.disabled=not state.undoAvailable or state.screen!="playing"
	menu_controls.RehearsalMenuRestart.disabled=state.screen!="playing";queue_redraw()
func _close_menu() -> void:
	menu_open=false;paused=false;menu_panel.hide();controls.RehearsalPause.text="暂停";_clear_input();grab_focus();queue_redraw()
func _menu_undo() -> void:
	_close_menu();_undo()
func _menu_restart() -> void:
	_close_menu();_apply({"kind":"restart"})
func _menu_pause() -> void:
	_pause();menu_controls.RehearsalMenuPause.text="继续" if paused else "暂停"
func _lamp_action() -> void:
	if paused or help_open or menu_open:return
	if state.screen=="round_complete":_continue_stage()
	else:_try_stage()
func _pause() -> void:
	if done or disposed:return
	_clear_input();paused=not paused;controls.RehearsalPause.text="继续" if paused else "暂停";queue_redraw()
func _focus_out() -> void:
	_clear_input()
	if is_instance_valid(performance):return
	if not done and not disposed:paused=true;controls.RehearsalPause.text="继续";queue_redraw()
	if touch_layout() and not help_open:_open_menu()
func _visibility_changed() -> void:
	if not visible:_focus_out()
func _clear_input() -> void:
	if drag_steps>0:undo_groups.append(drag_steps);drag_steps=0
	held.clear();pointer_id=-99;drag_id="";drag_kind="move";fold_keys=false;key_clock=0.0;fingers.clear();gesture_age=0;gesture_moved=false;gesture_consumed=false;two_fingers=false;lamp_armed=false
func _process(delta: float) -> void:
	if is_instance_valid(performance):return
	if not fingers.is_empty() and not gesture_moved and not gesture_consumed:
		gesture_age+=delta
		if gesture_age>=HOLD_SECONDS:
			if two_fingers:_open_menu()
			elif not drag_id.is_empty() and not paused and not help_open and not menu_open:_help()
	if model==null or paused or help_open or menu_open or done or disposed:return
	presentation_clock+=minf(delta,.1);trial_age+=minf(delta,.1);curtain_age+=minf(delta,.1);queue_redraw()
	key_clock-=delta
	if key_clock<=0 and not held.is_empty():
		key_clock=0.075
		var delta_pos: Vector2=_held_direction()
		if delta_pos.length_squared()>0:_nudge(delta_pos.normalized()*0.12)
func _held_direction() -> Vector2:
	return Vector2(float(held.has(KEY_RIGHT) or held.has(KEY_D))-float(held.has(KEY_LEFT) or held.has(KEY_A)),float(held.has(KEY_UP) or held.has(KEY_W))-float(held.has(KEY_DOWN) or held.has(KEY_S)))

func _local(global: Vector2) -> Vector2:return get_global_transform_with_canvas().affine_inverse()*global
func _logical(local: Vector2) -> Vector2:return (local-field.position)/field.size*LOGICAL
static func prop_foot(object: Dictionary) -> Vector2:return Vector2(480+float(object.x)*56,450-float(object.depth)*22)
static func prop_rect(object: Dictionary) -> Rect2:
	var foot: Vector2=prop_foot(object)
	if object.kind=="screen":return Rect2(foot+Vector2(-50,-132),Vector2(100,144))
	var factor: float=float(object.get("radius",Model.FAN_RADIUS))/Model.FAN_RADIUS
	var extent=Vector2(maxf(84,80*factor),maxf(88,86*factor))
	return Rect2(foot-Vector2(extent.x/2,extent.y-12),extent)
func _sorted_props() -> Array:
	var result: Array=state.objects.duplicate()
	result.sort_custom(func(a: Dictionary,b: Dictionary):return float(a.depth)>float(b.depth))
	return result
func _pick(point: Vector2) -> String:
	var objects: Array=_sorted_props()
	for i in range(objects.size()-1,-1,-1):
		if prop_rect(objects[i]).has_point(point):return str(objects[i].id)
	return ""
func _start_pointer(id: int,local: Vector2) -> bool:
	if paused or help_open or menu_open or done or disposed or state.get("screen")!="playing" or not field.has_point(local):return false
	var point: Vector2=_logical(local);var object_id: String="";var fold:bool=false
	var props:Array=_sorted_props()
	for i:int in range(props.size()-1,-1,-1):
		var object:Dictionary=props[i]
		if object.kind=="fan" and point.distance_to(FanView.grip(prop_foot(object),object))<=maxf(17,22*LOGICAL.x/field.size.x):
			object_id=str(object.id);fold=true;break
	if object_id.is_empty():object_id=_pick(point)
	if object_id.is_empty():return false
	pointer_id=id;drag_id=object_id;drag_kind="spread" if fold else "move";selected=object_id;drag_offset=prop_foot(_selected_object())-point;held.clear();grab_focus();queue_redraw();return true
func _drag_pointer(local: Vector2) -> void:
	if drag_id.is_empty():return
	if drag_kind=="spread":
		var object:Dictionary=_selected_object();var offset:Vector2=_logical(local)-FanView.pivot(prop_foot(object),object)
		_spread_prop(drag_id,(rad_to_deg(atan2(offset.x,-offset.y))-15.0)/60.0);return
	if drag_kind=="lamp":selected="lamp";_move_lamp((_logical(local).x+drag_offset.x)/56);return
	var point: Vector2=_logical(local)+drag_offset
	_move_prop(drag_id,Vector2((point.x-480)/56,(450-point.y)/22))
func _touch_begin(index: int,local: Vector2) -> bool:
	if help_open or menu_open or not touch_landscape():return false
	if paused:_open_menu();return true
	fingers[index]={"start":local,"current":local}
	if gesture_consumed:return true
	if fingers.size()==1:
		gesture_age=0;gesture_moved=false;gesture_consumed=false;two_fingers=false
		if field.has_point(local) and lamp_rect().has_point(_logical(local)):
			_begin_lamp(index,local);return true
		return _start_pointer(index,local)
	# A second finger owns a new gesture. End the previous drag as one undo
	# group; neither remaining finger may resume it after the other lifts.
	if drag_steps>0:undo_groups.append(drag_steps);drag_steps=0
	held.clear();pointer_id=-99;drag_id="";lamp_armed=false
	two_fingers=true;gesture_age=0;gesture_moved=false;gesture_consumed=fingers.size()>2
	return true
func _touch_drag(index: int,local: Vector2) -> bool:
	if not fingers.has(index):return false
	fingers[index].current=local
	if Vector2(fingers[index].start).distance_to(local)>TOUCH_SLOP:gesture_moved=true
	if not two_fingers and not gesture_consumed and gesture_moved and index==pointer_id:_drag_pointer(local)
	return true
func _touch_end(index: int,local: Vector2,cancelled_touch: bool=false) -> bool:
	if not fingers.has(index):return false
	if cancelled_touch:_clear_input();return true
	if Vector2(fingers[index].start).distance_to(local)>TOUCH_SLOP:gesture_moved=true
	if two_fingers:
		var undo: bool=not gesture_moved and not gesture_consumed and gesture_age<HOLD_SECONDS
		fingers.erase(index);gesture_consumed=true
		if undo:_undo()
		elif fingers.is_empty():_clear_input()
		return true
	var activate_lamp: bool=lamp_armed and not gesture_moved and field.has_point(local) and lamp_rect().has_point(_logical(local))
	_clear_input()
	if activate_lamp:_lamp_action()
	return true
func _input(event: InputEvent) -> void:
	if is_instance_valid(performance):return
	if disposed or done or not visible or model==null:return
	if event is InputEventKey:
		if event.echo:return
		if event.keycode in [KEY_LEFT,KEY_RIGHT,KEY_UP,KEY_DOWN,KEY_A,KEY_D,KEY_W,KEY_S]:
			if event.pressed and not paused and not help_open and not menu_open:
				fold_keys=event.shift_pressed
				held[event.keycode]=true;key_clock=0.075
				var direction: Vector2=_held_direction()
				if direction.length_squared()>0:_nudge(direction.normalized()*0.12)
			else:held.erase(event.keycode)
			get_viewport().set_input_as_handled();return
		if not event.pressed:return
		if event.keycode==KEY_V:
			_watch_performance();get_viewport().set_input_as_handled();return
		if event.keycode==KEY_ESCAPE:
			if help_open:_close_help()
			elif menu_open:_close_menu()
			elif touch_layout():_open_menu()
			else:_pause()
		elif paused or help_open or menu_open:return
		elif event.keycode==KEY_TAB:_cycle_selection()
		elif event.keycode==KEY_Z:_undo()
		elif event.keycode==KEY_R:_apply({"kind":"restart"})
		elif event.keycode in [KEY_ENTER,KEY_KP_ENTER,KEY_SPACE]:
			if state.screen=="round_complete":_continue_stage()
			else:_try_stage()
		else:return
		get_viewport().set_input_as_handled();return
	if event is InputEventScreenTouch:
		last_touch_ms=Time.get_ticks_msec()
		if not touch_seen:
			touch_seen=true
			# Do not move the very first Start button underneath a down finger.
			# The stage adopts touch layout when that paper sheet is closed.
			if not help_open and not menu_open:_layout()
		if event.pressed:
			if _touch_begin(event.index,_local(event.position)):get_viewport().set_input_as_handled()
		elif _touch_end(event.index,_local(event.position),event.canceled):get_viewport().set_input_as_handled()
		return
	if event is InputEventScreenDrag:
		if _touch_drag(event.index,_local(event.position)):get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		if event.device==InputEvent.DEVICE_ID_EMULATION and not help_open and not menu_open and field.has_point(_local(event.position)):
			get_viewport().set_input_as_handled();return
		if Time.get_ticks_msec()-last_touch_ms<600:return
		if event.pressed:
			var local:Vector2=_local(event.position)
			if pointer_id==-99 and not paused and not help_open and not menu_open and field.has_point(local) and lamp_rect().has_point(_logical(local)):
				_begin_lamp(-1,local);fingers[-1]={"start":local,"current":local};get_viewport().set_input_as_handled()
			elif pointer_id==-99 and _start_pointer(-1,local):get_viewport().set_input_as_handled()
		elif pointer_id==-1:
			var local:Vector2=_local(event.position)
			var activate_lamp:bool=lamp_armed and not gesture_moved and fingers.has(-1) and Vector2(fingers[-1].start).distance_to(local)<=TOUCH_SLOP and field.has_point(local) and lamp_rect().has_point(_logical(local))
			_clear_input()
			if activate_lamp:_lamp_action()
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and pointer_id==-1:
		var local:Vector2=_local(event.position)
		if lamp_armed and fingers.has(-1) and Vector2(fingers[-1].start).distance_to(local)>TOUCH_SLOP:gesture_moved=true
		if not lamp_armed or gesture_moved:_drag_pointer(local)
		get_viewport().set_input_as_handled()

func _draw_texture_fit(id: String,rect: Rect2,flip: bool=false,alpha: float=1.0) -> bool:
	if not textures.has(id):return false
	var texture: Texture2D=textures[id];var source: Vector2=texture.get_size();var factor: float=minf(rect.size.x/source.x,rect.size.y/source.y);var size2: Vector2=source*factor;var target=Rect2(rect.position+(rect.size-size2)/2,size2)
	if flip:target.position.x+=target.size.x;target.size.x=-target.size.x
	draw_texture_rect(texture,target,false,Color(1,1,1,alpha));return true
func _wing(center: Vector2,radius: float,side: int,color: Color,outline: bool=false,on_gauze: bool=false,spread:float=1.0) -> void:
	# The cut-paper fan has a broad upper lobe and a smaller lower lobe.
	# Both the pale receiver mark and the live shadow use this same profile;
	# model-owned center, radius and side still determine every projection.
	var profile=PackedVector2Array([Vector2(0,-.10),Vector2(.12,-.72),Vector2(.44,-1.10),Vector2(.85,-.98),Vector2(1,-.64),Vector2(.90,-.29),Vector2(.55,-.01),Vector2(.48,.09),Vector2(.83,.28),Vector2(.80,.60),Vector2(.55,.92),Vector2(.25,1.04),Vector2(.10,.81),Vector2(0,.14)])
	var points=PackedVector2Array()
	for point: Vector2 in profile:points.append(center+Vector2(point.x*side*spread,point.y)*radius)
	var pieces:Array[PackedVector2Array]=[points]
	if on_gauze:
		var gauze:Rect2=StagePlate.REHEARSAL_RECEIVER
		pieces=Geometry2D.intersect_polygons(points,PackedVector2Array([gauze.position,Vector2(gauze.end.x,gauze.position.y),gauze.end,Vector2(gauze.position.x,gauze.end.y)]))
	for piece: PackedVector2Array in pieces:
		if piece.size()<3:continue
		if outline:
			piece.append(piece[0]);draw_polyline(piece,color,2.0,true)
		else:draw_colored_polygon(piece,color)
func _draw_stage() -> void:
	if not StagePlate.draw(self,textures.get("stage"),true):
		draw_rect(Rect2(Vector2.ZERO,LOGICAL),Color("352d3a"));draw_rect(Rect2(50,250,860,260),Color("826449"))
	# The gauze is a physical receiver; all silhouettes share its single plane.
	draw_style_box(Ui.box(Color("d5ceab"),Color("7b6e52"),5,2,Vector2.ZERO),StagePlate.REHEARSAL_RECEIVER)
	var reduced:bool=bool(config.get("settings",{}).get("reducedMotion",false))
	for target: Dictionary in state.targets:_wing(Vector2(480+float(target.center)*64,148),float(target.radius)*64,int(target.side),Color("aa9b70"),true,true,float(target.spread))
	for shadow: Dictionary in state.projections:
		if shadow.kind=="fan":_wing(Vector2(480+float(shadow.center)*64,148),float(shadow.radius)*64,int(shadow.side),Color("34312bed"),false,true,float(shadow.spread))
		else:
			var shadow_rect:=Rect2(480+(float(shadow.center)-float(shadow.radius))*64,61,float(shadow.radius)*128,176).intersection(StagePlate.REHEARSAL_RECEIVER)
			if shadow_rect.has_area():draw_rect(shadow_rect,Color("34312bd9"))
	if state.lampMovable:
		var target_x:float=480+float(state.witnessTarget)*64
		var cast_x:float=480+float(state.witness.center)*64
		draw_polyline(PackedVector2Array([Vector2(target_x-7,86),Vector2(target_x-7,69),Vector2(target_x+7,69),Vector2(target_x+7,86)]),Color("9A514A"),2)
		draw_line(Vector2(cast_x,77),Vector2(cast_x,108),Color("34312b"),5)
		draw_circle(Vector2(cast_x,78),4,Color("34312b"))
		var pin:Vector2=prop_foot(Model.WITNESS)
		draw_line(pin,pin-Vector2(0,42),Color("665C42"),5)
		draw_circle(pin-Vector2(0,42),5,Color("C2A46F"))
		draw_line(pin-Vector2(13,0),pin+Vector2(13,0),Color("665C42"),4)
	if trial_age<1.25:
		var alpha:float=1.0-trial_age/1.25
		var edge_color:Color=Color("E5D7B4") if str(state.failure).is_empty() else Color("9A514A")
		edge_color.a=alpha
		if state.failure=="light_axis":draw_arc(Vector2(480+float(state.witnessTarget)*64,80),13,0,TAU,32,edge_color,2)
		else:
			for target:Dictionary in state.targets:_wing(Vector2(480+float(target.center)*64,148),float(target.radius)*64,int(target.side),edge_color,true,true,float(target.spread))
	for prop:Dictionary in StagePlate.furniture_entries("rehearsal"):StagePlate.draw_prop(self,textures,prop,true)
	if state.screen=="complete":
		# A small body joins the two earned wings; it has no puzzle hit area.
		draw_line(Vector2(480,121),Vector2(480,177),Color("292820"),4,true)
		draw_polyline(PackedVector2Array([Vector2(480,127),Vector2(474,115),Vector2(470,113)]),Color("292820"),1.5,true)
		draw_polyline(PackedVector2Array([Vector2(480,127),Vector2(486,115),Vector2(490,113)]),Color("292820"),1.5,true)
	# Cables converge at the lamp. They are thin stage hardware, never answer rails.
	for object: Dictionary in _sorted_props():
		var foot: Vector2=prop_foot(object)
		draw_line(Vector2(lamp_rect().get_center().x,475),foot,Color("b7a37155"),1.5,true)
		if object.kind=="screen":
			if not _draw_texture_fit("side_screen",prop_rect(object)):draw_style_box(Ui.box(Color("483b49"),Color("a8875d"),3,2,Vector2.ZERO),Rect2(foot+Vector2(-46,-126),Vector2(92,128)))
		else:
			FanView.draw(self,foot,object,object.id==selected,presentation_clock,reduced)
		if object.id==selected:
			# A subtle brass mark names current manipulation, not a target/range box.
			draw_line(foot+Vector2(-13,13),foot+Vector2(13,13),Color("e3c18b"),3,true)
	if state.lampMovable:
		draw_line(Vector2(480-Model.LAMP_LIMIT*56,517),Vector2(480+Model.LAMP_LIMIT*56,517),Color("665C42"),4)
		for x:int in [-1,0,1]:draw_line(Vector2(480+x*56,513),Vector2(480+x*56,521),Color("9D875E"),2)
	var lamp:Rect2=lamp_rect()
	if state.screen in ["round_complete","complete"]:
		var pulse:float=1.0 if reduced else .7+.3*sin(presentation_clock*3)
		draw_circle(lamp.get_center()-Vector2(0,8),34,Color(.89,.76,.55,.18*pulse))
	if not _draw_texture_fit("lantern",lamp):
		draw_circle(lamp.get_center(),19,Color("e4c483"));draw_rect(Rect2(lamp.position+Vector2(24,44),Vector2(36,25)),Color("40363b"))
	if textures.has("fan_closed"):_draw_texture_fit("fan_closed",Rect2(864,300,39,103),false,.8)
	_draw_cue_sheet(cue_sheet)
	if feedback_label.visible and not feedback_label.text.is_empty():_draw_cue_sheet(feedback_sheet)
	if curtain_age<.65 and not reduced:
		var width:float=460*(1.0-smoothstep(0,.65,curtain_age))
		for side:int in 2:
			var x:float=0 if side==0 else 960-width
			draw_rect(Rect2(x,0,width,426),Color("594147"))
			for fold:int in range(0,int(width),18):draw_rect(Rect2(x+fold,0,3,426),Color("453B43"))
	if paused:draw_rect(Rect2(Vector2.ZERO,LOGICAL),Color(0.06,0.07,0.10,.63))

func _draw_cue_sheet(rect:Rect2)->void:
	draw_rect(Rect2(rect.position+Vector2(0,2),rect.size),Color("202B3524"))
	draw_rect(rect,PAPER);draw_rect(rect,Color("C5C1A9"),false,1)
	draw_rect(Rect2(rect.position+Vector2(9,12),Vector2(2,rect.size.y-24)),Color("9A514A"))
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("252a31"))
	if is_instance_valid(performance):return
	if model==null or state.is_empty() or field.size.x<=0:return
	draw_set_transform(field.position,0,field.size/LOGICAL);_draw_stage();draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
	if touch_layout() and size.x<size.y:draw_style_box(Ui.box(PAPER,Color("8d6b45"),1,3),Rect2(rotation_label.position-Vector2(0,12),rotation_label.size+Vector2(0,24)))
func geometry_snapshot() -> Dictionary:
	var props: Array=[]
	for object: Dictionary in state.get("objects",[]):
		var rect: Rect2=prop_rect(object);var actual=Rect2(field.position+rect.position/LOGICAL*field.size,rect.size/LOGICAL*field.size)
		var grip:Vector2=field.position+FanView.grip(prop_foot(object),object)/LOGICAL*field.size if object.kind=="fan" else Vector2.ZERO
		props.append({"id":object.id,"rect":[actual.position.x,actual.position.y,actual.size.x,actual.size.y],"grip":[grip.x,grip.y],"foot":[(field.position+prop_foot(object)/LOGICAL*field.size).x,(field.position+prop_foot(object)/LOGICAL*field.size).y]})
	var lamp=Rect2(field.position+lamp_rect().position/LOGICAL*field.size,lamp_rect().size/LOGICAL*field.size)
	return {"field":[field.position.x,field.position.y,field.size.x,field.size.y],"props":props,"lamp":[lamp.position.x,lamp.position.y,lamp.size.x,lamp.size.y],"selected":selected,"paused":paused,"helpOpen":help_open,"menuOpen":menu_open,"touchLayout":touch_layout(),"rotationRequired":touch_layout() and size.x<size.y,"state":state.duplicate(true),"stagePlate":StagePlate.TEXTURE_PATH if StagePlate.valid_texture(textures.get("stage")) else "diagnostic","cueSheet":[cue_sheet.position.x,cue_sheet.position.y,cue_sheet.size.x,cue_sheet.size.y],"hudOwner":str(stage_hud.get_path()),"hudVisible":stage_hud.visible,"performance":performance.geometry_snapshot() if is_instance_valid(performance) else null}
func _watch_performance() -> bool:
	if disposed or done or is_instance_valid(performance):return false
	var state_node:Node=get_node_or_null("/root/State")
	if state_node==null:return false
	var show:=PerformanceView.new()
	var setup_config:Dictionary={"read_state":func()->Dictionary:return state_node.d,"is_blocked":_performance_host_blocked,"assets":config.get("performance_assets",{})}
	if not show.setup(setup_config):
		show.free();feedback_label.text="这段演出还没准备好，先把手里的排练接下去。";return false
	_clear_input()
	var visibility:Array=[]
	for node:Control in _hud_nodes():visibility.append({"node":weakref(node),"visible":node.visible})
	performance_restore={"paused":paused,"helpOpen":help_open,"menuOpen":menu_open,"visibility":visibility,"viewSize":size,"touchLayout":touch_layout()}
	performance=show;show.z_index=20;add_child(show);show.configure_activity_layout(size,false)
	_hide_under_performance();queue_redraw()
	show.closed.connect(func(reason:String):
		if not is_instance_valid(show) or performance!=show:return
		performance=null;show.queue_free()
		if disposed:return
		if reason=="context_changed":_cancel();return
		paused=bool(performance_restore.get("paused",false));help_open=bool(performance_restore.get("helpOpen",false));menu_open=bool(performance_restore.get("menuOpen",false))
		_clear_input();controls.RehearsalPause.text="继续" if paused else "暂停";_layout()
		help_panel.visible=help_open;menu_panel.visible=menu_open
		if performance_restore.get("viewSize")==size and performance_restore.get("touchLayout")==touch_layout():
			for item:Dictionary in performance_restore.get("visibility",[]):
				var node:Control=item.node.get_ref()
				if is_instance_valid(node):node.visible=bool(item.visible)
		performance_restore={};grab_focus();queue_redraw()
	)
	return true

func _performance_host_blocked()->bool:
	if disposed or not is_visible_in_tree():return true
	var host:Node=get_parent()
	if not is_instance_valid(host) or not host.has_method("_activity_owns_scene"):return false
	for key:String in ["modal","phone_document","file_dialog"]:
		var overlay:Variant=host.get(key)
		if is_instance_valid(overlay) and overlay is CanvasItem and overlay.is_visible_in_tree():return true
		if is_instance_valid(overlay) and overlay is Window and overlay.visible:return true
	var state_node:Node=get_node_or_null("/root/State")
	if state_node!=null and state_node.story_input_locked():return true
	return false

func _stop_performance()->void:
	if is_instance_valid(performance):
		performance.dispose_presentation();performance.queue_free()
	performance=null;performance_restore={}

func dispose_presentation() -> void:
	_stop_performance()
	disposed=true;_clear_input();set_process_input(false);set_process(false)
func _exit_tree() -> void:
	dispose_presentation()
	if is_instance_valid(get_window()) and get_window().focus_exited.is_connected(_focus_out):get_window().focus_exited.disconnect(_focus_out)
