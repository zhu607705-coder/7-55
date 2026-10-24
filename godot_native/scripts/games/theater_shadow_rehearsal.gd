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
const Notebook=preload("res://scripts/presentation/theater_rehearsal_notebook.gd")
const Folio=preload("res://scripts/presentation/theater_rehearsal_folio.gd")
const StageObjects=preload("res://scripts/presentation/theater_rehearsal_stage_objects.gd")
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
var help_previous: Button
var help_page_label: Label
var help_navigation: HBoxContainer
var help_content: BoxContainer
var notebook: Control
var notebook_open:=false
var notebook_page:=0
var notebook_pages:Dictionary={}
var trial_records:Dictionary={}
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
var stage_pressed := ""
var stage_hover := ""
var stage_press_origin := Vector2.ZERO
var stage_pull := 0.0
var stage_action := ""
var stage_action_age := 0.0
const STAGE_ACTION_SECONDS := 0.28
var presentation_clock := 0.0
var trial_age := 10.0
var curtain_age := 2.0
const HOLD_SECONDS := 0.6
const TOUCH_SLOP := 10.0

func setup(value: Dictionary) -> void:
	config=value.duplicate(true);model=Model.new();state=model.snapshot()
	selected="left_fan";paused=false;help_open=false;menu_open=false;done=false;disposed=false
	notebook_open=false;notebook_page=0;notebook_pages.clear();trial_records.clear()
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
	_button("RehearsalExit","返回现场",_cancel)
	_button("RehearsalUndo","撤回",_undo);_button("RehearsalRestart","重排本幕",func():_clear_input();_apply({"kind":"restart"}))
	_button("RehearsalTry","演一遍",_try_stage);_button("RehearsalNext","下一幕",_continue_stage)
	_button("RehearsalSelect","换一件",_cycle_selection)
	for spec: Array in [["RehearsalLeft","←",Vector2(-0.12,0)],["RehearsalRight","→",Vector2(0.12,0)],["RehearsalForward","向幕",Vector2(0,0.12)],["RehearsalBack","向灯",Vector2(0,-0.12)]]:
		var delta: Vector2=spec[2];_button(spec[0],spec[1],func():_nudge(delta))
	help_panel=Folio.new();help_panel.name="RehearsalReading"
	help_panel.add_theme_stylebox_override("panel",Ui.box(Color.TRANSPARENT,Color.TRANSPARENT,0,0,Vector2(36,26)));add_child(help_panel)
	var column=VBoxContainer.new();column.add_theme_constant_override("separation",10);help_panel.add_child(column)
	var heading=HBoxContainer.new();heading.add_theme_constant_override("separation",12);column.add_child(heading)
	help_title=Label.new();help_title.add_theme_font_size_override("font_size",24);help_title.add_theme_color_override("font_color",INK);TheaterUi.heading(help_title);help_title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;heading.add_child(help_title)
	help_close=Button.new();help_close.name="RehearsalCloseReading";help_close.text="回到舞台";help_close.custom_minimum_size=Vector2(92,44);TheaterUi.button(help_close);help_close.pressed.connect(_close_help);heading.add_child(help_close)
	help_content=BoxContainer.new();help_content.add_theme_constant_override("separation",28);help_content.size_flags_vertical=Control.SIZE_EXPAND_FILL;column.add_child(help_content)
	notebook=Notebook.new();notebook.name="RehearsalInkDiagrams";notebook.size_flags_horizontal=Control.SIZE_EXPAND_FILL;notebook.size_flags_vertical=Control.SIZE_EXPAND_FILL;help_content.add_child(notebook)
	help_body=RichTextLabel.new();TheaterUi.text(help_body);help_body.bbcode_enabled=true;help_body.fit_content=false;help_body.scroll_active=true;help_body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;help_body.add_theme_font_size_override("normal_font_size",18);help_body.add_theme_color_override("default_color",INK);help_body.size_flags_vertical=Control.SIZE_EXPAND_FILL;help_body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;help_content.add_child(help_body)
	help_navigation=HBoxContainer.new();help_navigation.add_theme_constant_override("separation",12);column.add_child(help_navigation)
	help_previous=Button.new();help_previous.name="RehearsalPreviousPage";help_previous.text="前页";help_previous.custom_minimum_size=Vector2(92,44);TheaterUi.button(help_previous);help_previous.pressed.connect(_previous_hint);help_navigation.add_child(help_previous)
	help_page_label=Label.new();help_page_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;help_page_label.add_theme_color_override("font_color",Color("9A514A"));help_page_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;help_navigation.add_child(help_page_label)
	help_next=Button.new();help_next.name="RehearsalNextHint";help_next.text="后页";help_next.custom_minimum_size=Vector2(92,44);TheaterUi.button(help_next);help_next.pressed.connect(_next_hint);help_navigation.add_child(help_next)
	help_panel.hide()
	menu_panel=PanelContainer.new();menu_panel.name="RehearsalPaperMenu";menu_panel.add_theme_stylebox_override("panel",Ui.box(PAPER,Color("8d6b45"),2,4,Vector2(16,12)));add_child(menu_panel)
	var menu_column=VBoxContainer.new();menu_column.add_theme_constant_override("separation",6);menu_panel.add_child(menu_column)
	var menu_title=Label.new();menu_title.text="排练单";menu_title.add_theme_font_size_override("font_size",22);menu_title.add_theme_color_override("font_color",INK);TheaterUi.heading(menu_title);menu_column.add_child(menu_title)
	for spec: Array in [["RehearsalMenuClose","回到舞台",_close_menu],["RehearsalMenuUndo","撤回",_menu_undo],["RehearsalMenuRestart","重排本幕",_menu_restart],["RehearsalMenuPause","暂停",_menu_pause],["RehearsalMenuExit","返回现场",_cancel]]:
		var button=Button.new();button.name=spec[0];button.text=spec[1];button.custom_minimum_size.y=44;button.focus_mode=Control.FOCUS_NONE;TheaterUi.button(button,spec[0]=="RehearsalMenuClose");button.pressed.connect(spec[2]);menu_controls[spec[0]]=button
		menu_column.add_child(button)
	menu_panel.hide();_layout()

func touch_layout() -> bool:return coarse or touch_seen
func touch_landscape() -> bool:return touch_layout() and size.x>=size.y

func _place(id: String,rect: Rect2) -> void:
	controls[id].position=rect.position;controls[id].size=rect.size
func _layout() -> void:
	if not built or size.x<=0 or size.y<=0:return
	if is_instance_valid(performance):performance.configure_activity_layout(size,false)
	var portrait:bool=size.x<size.y
	var available:Vector2=size-Vector2(16,16) if portrait else size
	var width:float=minf(available.x,available.y*16.0/9.0)
	var height:float=width*9.0/16.0
	field=Rect2(Vector2((size.x-width)/2,8 if portrait else (size.y-height)/2),Vector2(width,height))
	for button:Button in controls.values():button.hide()
	# Portrait is a rotation fallback, not a miniature interactive stage.
	if portrait:
		controls.RehearsalExit.show()
		_place("RehearsalExit",Rect2((size.x-156)/2,field.end.y+164,156,44))
	rotation_label.visible=portrait;rotation_label.position=Vector2(24,field.end.y+40);rotation_label.size=Vector2(size.x-48,100)
	feedback_label.add_theme_color_override("font_color",INK);feedback_label.visible=not portrait
	_layout_reading()
	menu_panel.position=Vector2((size.x-minf(360,size.x-32))/2,(size.y-326)/2);menu_panel.size=Vector2(minf(360,size.x-32),326)
	_layout_stage_hud();_hide_under_performance();queue_redraw()

func _layout_reading() -> void:
	if size.x<=80 or size.y<=80:return
	var width:float=minf(960 if notebook_open else 720,size.x-32)
	var stacked:bool=width<620
	var height:float=minf(610 if stacked and notebook_open else 540 if notebook_open else 460,size.y-32)
	help_content.vertical=stacked
	help_content.add_theme_constant_override("separation",12 if stacked else 28)
	notebook.visible=notebook_open;help_navigation.visible=notebook_open
	notebook.custom_minimum_size=Vector2(0,176 if stacked else 0)
	notebook.size_flags_stretch_ratio=.94
	notebook.size_flags_vertical=Control.SIZE_FILL if stacked else Control.SIZE_EXPAND_FILL
	help_body.add_theme_font_size_override("normal_font_size",17 if height<400 else 18)
	help_body.add_theme_font_size_override("bold_font_size",19 if height<400 else 22)
	help_body.add_theme_constant_override("line_separation",4 if height<400 else 6)
	help_title.add_theme_font_size_override("font_size",22 if stacked else 24)
	help_panel.divided=notebook_open and not stacked
	help_panel.position=(size-Vector2(width,height))/2;help_panel.size=Vector2(width,height)
	help_panel.queue_redraw()

func _layout_stage_hud()->void:
	if field.size.x<=0:return
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
	if disposed or done or paused or help_open or menu_open or model==null or not stage_action.is_empty() or is_instance_valid(performance):return false
	var accepted: bool=model.apply(action)
	if accepted:
		if action.kind in ["move","spread","lamp"]:
			if not drag_id.is_empty():drag_steps+=1
			else:undo_groups.append(1)
		elif action.kind=="restart":undo_groups.append(1)
		elif action.kind=="try":trial_records[int(model.state.round)]=model.snapshot()
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
	if paused or help_open or menu_open or not stage_action.is_empty():return
	stage_hover=""
	var objects: Array=state.objects.duplicate()
	objects.append({"id":"lamp"})
	for id:String in StageObjects.IDS:objects.append({"id":id})
	for i in objects.size():
		if objects[i].id==selected:selected=objects[(i+1)%objects.size()].id;queue_redraw();return
func _nudge(delta: Vector2) -> void:
	if selected=="lamp":_move_lamp(Vector2(float(state.lampX),float(state.lampDepth))+delta);return
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

func _move_lamp(value:Vector2)->void:
	if not state.get("lampMovable",false):return
	value=value.clamp(Vector2(-Model.LAMP_LIMIT,Model.LAMP_DEPTH_MIN),Vector2(Model.LAMP_LIMIT,Model.LAMP_DEPTH_MAX))
	var start:=Vector2(float(state.lampX),float(state.lampDepth))
	if start.is_equal_approx(value):return
	var steps:int=ceili(start.distance_to(value)/.5)
	for i:int in range(1,steps+1):
		var next:Vector2=start.lerp(value,float(i)/steps)
		if not _apply({"kind":"lamp","x":next.x,"depth":next.y}):break

func lamp_rect()->Rect2:
	return Rect2(StagePlate.REHEARSAL_LAMP.position+Vector2(float(state.get("lampX",0.0))*56,-float(state.get("lampDepth",0.0))*22),StagePlate.REHEARSAL_LAMP.size)

func _begin_lamp(id:int,local:Vector2)->void:
	pointer_id=id;lamp_armed=true;drag_id="lamp";drag_kind="lamp"
	drag_offset=Vector2(float(state.lampX)*56,-float(state.lampDepth)*22)-_logical(local)
	held.clear();grab_focus();queue_redraw()

func _intro() -> void:
	_clear_input();help_open=true;notebook_open=false;help_title.text="借扇成蝶"
	help_body.text="扇影要合上幕上的旧痕。\n\n拖底座移动道具，拉扇骨铜扣开合；台灯可左右、前后拖动，点灯试演。\n\n桌上节目册可翻阅线索，右侧拉绳开启合演，左侧幕缝退场。\n\n手机横屏，双指轻触撤回、按住打开排练单；键盘 Tab 选物、空格操作，方向键移动，Shift＋左右键开合，Esc 暂停。"
	help_close.text="开始排练";help_panel.show();_layout_reading();help_panel.move_to_front()
	help_body.scroll_to_line(0)
func _help() -> void:
	if disposed or done:return
	_clear_input();help_open=true;notebook_open=true
	if int(state.hintTier)==0 and state.screen=="playing":model.apply({"kind":"hint"});state=model.snapshot()
	notebook_page=int(notebook_pages.get(int(state.round),0))
	_render_notebook()
	help_panel.show();help_panel.move_to_front()
func _render_notebook()->void:
	var record:Dictionary=trial_records.get(int(state.round),{})
	help_title.text="排练手记";help_close.text="掩卷"
	help_body.text=Notebook.page_text(int(state.round),notebook_page,record)
	notebook.show_page(int(state.round),notebook_page,record)
	help_page_label.text="%s / 三"%[ ["一","二","三"][notebook_page] ]
	help_previous.disabled=notebook_page==0;help_next.disabled=notebook_page==2
	notebook_pages[int(state.round)]=notebook_page
	_layout_reading();help_body.scroll_to_line(0)
func _next_hint() -> void:
	if model==null or not help_open or not notebook_open or notebook_page>=2:return
	notebook_page+=1
	help_panel.turn_page(1,bool(config.get("settings",{}).get("reducedMotion",false)))
	if notebook_page>=int(state.hintTier) and state.screen=="playing":model.apply({"kind":"hint"});state=model.snapshot()
	_render_notebook()
func _previous_hint()->void:
	if not help_open or not notebook_open or notebook_page<=0:return
	notebook_page-=1;help_panel.turn_page(-1,bool(config.get("settings",{}).get("reducedMotion",false)));_render_notebook()
func _close_help() -> void:
	help_open=false;help_panel.turn_amount=0.0;help_panel.hide();_clear_input();_layout();grab_focus()
	if paused:_open_menu()
func _open_menu() -> void:
	if disposed or done or help_open:return
	_clear_input();menu_open=true;menu_panel.show();menu_panel.move_to_front()
	menu_controls.RehearsalMenuPause.text="继续" if paused else "暂停"
	menu_controls.RehearsalMenuUndo.disabled=not state.undoAvailable or state.screen!="playing"
	menu_controls.RehearsalMenuRestart.disabled=state.screen!="playing";queue_redraw()
func _close_menu() -> void:
	menu_open=false;paused=false;menu_panel.hide();_clear_input();grab_focus();queue_redraw()
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
	_clear_input();paused=not paused;queue_redraw()
func _focus_out() -> void:
	_clear_input()
	if is_instance_valid(performance):return
	if not done and not disposed:paused=true;queue_redraw()
	if not help_open:_open_menu()
func _visibility_changed() -> void:
	if not visible:_focus_out()
func _clear_input() -> void:
	if drag_steps>0:undo_groups.append(drag_steps);drag_steps=0
	held.clear();pointer_id=-99;drag_id="";drag_kind="move";fold_keys=false;key_clock=0.0;fingers.clear();gesture_age=0;gesture_moved=false;gesture_consumed=false;two_fingers=false;lamp_armed=false
	stage_pressed="";stage_hover="";stage_pull=0.0;stage_action="";stage_action_age=0.0;mouse_default_cursor_shape=Control.CURSOR_ARROW
func _process(delta: float) -> void:
	if is_instance_valid(performance):return
	if not fingers.is_empty() and not gesture_moved and not gesture_consumed:
		gesture_age+=delta
		if gesture_age>=HOLD_SECONDS:
			if two_fingers:_open_menu()
			elif not drag_id.is_empty() and not paused and not help_open and not menu_open:_help()
	if model==null or paused or help_open or menu_open or done or disposed:return
	if not stage_action.is_empty():
		stage_action_age+=minf(delta,.1);queue_redraw()
		if stage_action_age>=STAGE_ACTION_SECONDS:
			var action:String=stage_action;stage_action="";stage_action_age=0.0
			match action:
				"programme":_help()
				"curtain":_watch_performance()
				"exit":_cancel()
		return
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
func stage_object_rect(id:String)->Rect2:
	var visual:Rect2=StageObjects.rect(id)
	var minimum:float=44.0*LOGICAL.x/field.size.x
	var extent:=Vector2(maxf(visual.size.x,minimum),maxf(visual.size.y,minimum))
	return Rect2(visual.get_center()-extent/2,extent)

func _stage_object_at(local:Vector2)->String:
	if not field.has_point(local) or size.x<size.y:return ""
	for id:String in StageObjects.IDS:
		if stage_object_rect(id).has_point(_logical(local)):return id
	return ""

func _begin_stage_object(id:int,local:Vector2)->bool:
	if paused or help_open or menu_open or not stage_action.is_empty():return false
	var object:String=_stage_object_at(local)
	if object.is_empty():return false
	pointer_id=id;stage_pressed=object;stage_press_origin=local;stage_pull=0.0;selected=object
	held.clear();grab_focus();queue_redraw();return true

func _drag_stage_object(local:Vector2)->void:
	var delta:Vector2=local-stage_press_origin
	if delta.length()>TOUCH_SLOP:gesture_moved=true
	stage_pull=clampf(delta.y/(28.0*field.size.x/LOGICAL.x),0,1) if stage_pressed=="curtain" else 0.0
	queue_redraw()

func _release_stage_object(local:Vector2)->String:
	if stage_pressed.is_empty():return ""
	var delta:Vector2=local-stage_press_origin
	if not field.has_point(local):return ""
	if stage_pressed=="curtain":
		# A tap or short downward pull can engage the toggle. Sideways drags cancel.
		if absf(delta.x)<=TOUCH_SLOP and delta.y>=-TOUCH_SLOP and delta.y<=64:return stage_pressed
	elif not gesture_moved and delta.length()<=TOUCH_SLOP and _stage_object_at(local)==stage_pressed:return stage_pressed
	return ""

func _activate_stage_object(id:String)->void:
	if id not in StageObjects.IDS or paused or help_open or menu_open or disposed or done or is_instance_valid(performance) or not stage_action.is_empty() or size.x<size.y:return
	_clear_input();selected=id;stage_action=id
	if config.get("settings",{}).get("reducedMotion",false):stage_action_age=STAGE_ACTION_SECONDS
	queue_redraw()

func _start_pointer(id: int,local: Vector2) -> bool:
	if paused or help_open or menu_open or done or disposed or not stage_action.is_empty() or size.x<size.y or state.get("screen")!="playing" or not field.has_point(local):return false
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
	if drag_kind=="lamp":
		selected="lamp"
		var source:Vector2=_logical(local)+drag_offset
		_move_lamp(Vector2(source.x/56,-source.y/22));return
	var point: Vector2=_logical(local)+drag_offset
	_move_prop(drag_id,Vector2((point.x-480)/56,(450-point.y)/22))
func _touch_begin(index: int,local: Vector2) -> bool:
	if help_open or menu_open or not stage_action.is_empty() or not touch_landscape():return false
	if paused:_open_menu();return true
	if pointer_id==-1:_clear_input()
	fingers[index]={"start":local,"current":local}
	if gesture_consumed:return true
	if fingers.size()==1:
		gesture_age=0;gesture_moved=false;gesture_consumed=false;two_fingers=false
		if _begin_stage_object(index,local):return true
		if field.has_point(local) and lamp_rect().has_point(_logical(local)):
			_begin_lamp(index,local);return true
		return _start_pointer(index,local)
	# A second finger owns a new gesture. End the previous drag as one undo
	# group; neither remaining finger may resume it after the other lifts.
	if drag_steps>0:undo_groups.append(drag_steps);drag_steps=0
	held.clear();pointer_id=-99;drag_id="";lamp_armed=false;stage_pressed="";stage_pull=0.0
	two_fingers=true;gesture_age=0;gesture_moved=false;gesture_consumed=fingers.size()>2
	return true
func _touch_drag(index: int,local: Vector2) -> bool:
	if not fingers.has(index):return false
	fingers[index].current=local
	if Vector2(fingers[index].start).distance_to(local)>TOUCH_SLOP:gesture_moved=true
	if not two_fingers and not gesture_consumed and index==pointer_id:
		if not stage_pressed.is_empty():_drag_stage_object(local)
		elif gesture_moved:_drag_pointer(local)
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
	var stage_id:String=_release_stage_object(local)
	var activate_lamp: bool=lamp_armed and not gesture_moved and field.has_point(local) and lamp_rect().has_point(_logical(local))
	_clear_input()
	if not stage_id.is_empty():_activate_stage_object(stage_id)
	elif activate_lamp:_lamp_action()
	return true
func _input(event: InputEvent) -> void:
	if is_instance_valid(performance):return
	if disposed or done or not visible or model==null:return
	if event is InputEventKey:
		if event.echo:return
		if help_open and notebook_open and event.keycode in [KEY_PAGEUP,KEY_PAGEDOWN]:
			if event.pressed:
				if event.keycode==KEY_PAGEUP:_previous_hint()
				else:_next_hint()
			get_viewport().set_input_as_handled();return
		if not stage_action.is_empty():
			if event.pressed and event.keycode==KEY_ESCAPE:_clear_input();_open_menu()
			get_viewport().set_input_as_handled();return
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
			_activate_stage_object("curtain");get_viewport().set_input_as_handled();return
		if event.keycode==KEY_ESCAPE:
			if help_open:_close_help()
			elif menu_open:_close_menu()
			else:_open_menu()
		elif paused or help_open or menu_open:return
		elif event.keycode==KEY_TAB:_cycle_selection()
		elif event.keycode==KEY_Z:_undo()
		elif event.keycode==KEY_R:_apply({"kind":"restart"})
		elif event.keycode in [KEY_ENTER,KEY_KP_ENTER,KEY_SPACE]:
			if selected in StageObjects.IDS:_activate_stage_object(selected)
			elif state.screen=="round_complete":_continue_stage()
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
			if pointer_id==-99 and _begin_stage_object(-1,local):get_viewport().set_input_as_handled()
			elif pointer_id==-99 and size.x>=size.y and not paused and not help_open and not menu_open and stage_action.is_empty() and field.has_point(local) and lamp_rect().has_point(_logical(local)):
				_begin_lamp(-1,local);fingers[-1]={"start":local,"current":local};get_viewport().set_input_as_handled()
			elif pointer_id==-99 and _start_pointer(-1,local):get_viewport().set_input_as_handled()
		elif pointer_id==-1:
			var local:Vector2=_local(event.position)
			var stage_id:String=_release_stage_object(local)
			var activate_lamp:bool=lamp_armed and not gesture_moved and fingers.has(-1) and Vector2(fingers[-1].start).distance_to(local)<=TOUCH_SLOP and field.has_point(local) and lamp_rect().has_point(_logical(local))
			_clear_input()
			if not stage_id.is_empty():_activate_stage_object(stage_id)
			elif activate_lamp:_lamp_action()
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion:
		var local:Vector2=_local(event.position)
		stage_hover=_stage_object_at(local) if not paused and not help_open and not menu_open else ""
		mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND if not stage_hover.is_empty() else Control.CURSOR_ARROW
		if pointer_id!=-1:queue_redraw();return
		if not stage_pressed.is_empty():_drag_stage_object(local);get_viewport().set_input_as_handled();return
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
func light_geometry()->Dictionary:
	# A fixed-divergence beam expands with source-to-receiver distance.
	# Prop magnification uses that same distance in Model.project().
	var distance:float=Model.SCREEN_DEPTH-float(state.get("lampDepth",0.0))
	var origin:Vector2=lamp_rect().position+Vector2(46,10)
	return {"origin":origin,"center":Vector2(480+float(state.get("lampX",0.0))*64,148),"halfWidth":distance*40.0,"halfHeight":distance*13.0}

func _draw_light()->void:
	var light:Dictionary=light_geometry()
	var receiver:Rect2=StagePlate.REHEARSAL_RECEIVER
	# Warm, broad bands retain the original hard-edged pixel art underneath.
	for band:int in range(6):
		var inset:float=float(band)*.045
		var half_width:float=float(light.halfWidth)*(1.0-inset)
		var left:float=maxf(receiver.position.x,float(light.center.x)-half_width)
		var right:float=minf(receiver.end.x,float(light.center.x)+half_width)
		draw_colored_polygon(PackedVector2Array([Vector2(left,receiver.end.y),Vector2(right,receiver.end.y),light.origin+Vector2(9,0),light.origin-Vector2(9,0)]),Color(.96,.82,.53,.012))
	var clip:=PackedVector2Array([receiver.position,Vector2(receiver.end.x,receiver.position.y),receiver.end,Vector2(receiver.position.x,receiver.end.y)])
	for band:int in range(8):
		var ratio:float=1.0-float(band)*.045
		var ellipse:=PackedVector2Array()
		for point:int in range(64):
			var angle:float=TAU*float(point)/64.0
			ellipse.append(Vector2(light.center)+Vector2(cos(angle)*float(light.halfWidth),sin(angle)*float(light.halfHeight))*ratio)
		for piece:PackedVector2Array in Geometry2D.intersect_polygons(ellipse,clip):
			if piece.size()>2:draw_colored_polygon(piece,Color(.96,.87,.62,.045))
	draw_circle(light.origin,6,Color("ead4a6"))

func _draw_stage() -> void:
	if not StagePlate.draw(self,textures.get("stage"),true):
		draw_rect(Rect2(Vector2.ZERO,LOGICAL),Color("352d3a"));draw_rect(Rect2(50,250,860,260),Color("826449"))
	# The gauze is a physical receiver; all silhouettes share its single plane.
	draw_style_box(Ui.box(Color("b8b092"),Color("7b6e52"),5,2,Vector2.ZERO),StagePlate.REHEARSAL_RECEIVER)
	_draw_light()
	var reduced:bool=bool(config.get("settings",{}).get("reducedMotion",false))
	for target: Dictionary in state.targets:_wing(Vector2(480+float(target.center)*64,148),float(target.radius)*64,int(target.side),Color("aa9b70"),true,true,float(target.spread))
	for shadow: Dictionary in state.projections:
		if shadow.kind=="fan":_wing(Vector2(480+float(shadow.center)*64,148),float(shadow.radius)*64,int(shadow.side),Color("34312bed"),false,true,float(shadow.spread))
		else:
			var shadow_rect:=Rect2(480+(float(shadow.center)-float(shadow.radius))*64,61,float(shadow.radius)*128,176).intersection(StagePlate.REHEARSAL_RECEIVER)
			if shadow_rect.has_area():draw_rect(shadow_rect,Color("34312bd9"))
	if not state.witness.is_empty():
		var target_x:float=480+float(state.witnessTarget)*64
		var cast_x:float=480+float(state.witness.center)*64
		var cast_top:float=140.0-31.0*float(state.witness.magnification)
		for y:float in [78.0,140.0]:
			draw_line(Vector2(target_x-9,y),Vector2(target_x+9,y),Color("9A514A"),2)
			draw_line(Vector2(target_x-9,y-4),Vector2(target_x-9,y+4),Color("9A514A"),2)
			draw_line(Vector2(target_x+9,y-4),Vector2(target_x+9,y+4),Color("9A514A"),2)
		var receiver:Rect2=StagePlate.REHEARSAL_RECEIVER
		if cast_x>=receiver.position.x+3 and cast_x<=receiver.end.x-3:
			draw_line(Vector2(cast_x,maxf(cast_top,receiver.position.y)),Vector2(cast_x,140),Color("34312b"),5)
			if receiver.grow(-4).has_point(Vector2(cast_x,cast_top)):draw_circle(Vector2(cast_x,cast_top),4,Color("34312b"))
		var pin:Vector2=prop_foot(Model.WITNESS)
		draw_line(pin,pin-Vector2(0,42),Color("665C42"),5)
		draw_circle(pin-Vector2(0,42),5,Color("C2A46F"))
		draw_line(pin-Vector2(13,0),pin+Vector2(13,0),Color("665C42"),4)
	if trial_age<1.25:
		var alpha:float=1.0-trial_age/1.25
		var edge_color:Color=Color("E5D7B4") if str(state.failure).is_empty() else Color("9A514A")
		edge_color.a=alpha
		if state.failure=="light_axis":draw_arc(Vector2(480+float(state.witnessTarget)*64,109),34,0,TAU,32,edge_color,2)
		else:
			for target:Dictionary in state.targets:_wing(Vector2(480+float(target.center)*64,148),float(target.radius)*64,int(target.side),edge_color,true,true,float(target.spread))
	for prop:Dictionary in StagePlate.furniture_entries("rehearsal"):StagePlate.draw_prop(self,textures,prop,true)
	if state.screen=="complete":
		# A small body joins the two earned wings; it has no puzzle hit area.
		draw_line(Vector2(480,121),Vector2(480,177),Color("292820"),4,true)
		draw_polyline(PackedVector2Array([Vector2(480,127),Vector2(474,115),Vector2(470,113)]),Color("292820"),1.5,true)
		draw_polyline(PackedVector2Array([Vector2(480,127),Vector2(486,115),Vector2(490,113)]),Color("292820"),1.5,true)
	# Props interrupt the visible cone; their silhouettes use model-owned rays.
	for object: Dictionary in _sorted_props():
		var foot: Vector2=prop_foot(object)
		if object.kind=="screen":
			if not _draw_texture_fit("side_screen",prop_rect(object)):draw_style_box(Ui.box(Color("483b49"),Color("a8875d"),3,2,Vector2.ZERO),Rect2(foot+Vector2(-46,-126),Vector2(92,128)))
		else:
			FanView.draw(self,foot,object,object.id==selected,presentation_clock,reduced)
		if object.id==selected:
			# A subtle brass mark names current manipulation, not a target/range box.
			draw_line(foot+Vector2(-13,13),foot+Vector2(13,13),Color("e3c18b"),3,true)
	# Two short dolly runners make both physical travel axes readable.
	for side:float in [-1.0,1.0]:
		var x:float=480.0+side*Model.LAMP_LIMIT*56.0
		draw_line(Vector2(x,517-Model.LAMP_DEPTH_MAX*22),Vector2(x,517-Model.LAMP_DEPTH_MIN*22),Color("665C42"),3)
	var lamp_base:=Vector2(lamp_rect().get_center().x,lamp_rect().end.y-7)
	draw_line(Vector2(480-Model.LAMP_LIMIT*56,lamp_base.y),Vector2(480+Model.LAMP_LIMIT*56,lamp_base.y),Color("665C42"),3)
	if selected=="lamp":
		draw_line(lamp_base+Vector2(-20,5),lamp_base+Vector2(20,5),Color("e3c18b"),3)
	var lamp:Rect2=lamp_rect()
	if state.screen in ["round_complete","complete"]:
		var pulse:float=1.0 if reduced else .7+.3*sin(presentation_clock*3)
		draw_circle(lamp.get_center()-Vector2(0,8),34,Color(.89,.76,.55,.18*pulse))
	if not _draw_texture_fit("lantern",lamp):
		draw_circle(lamp.get_center(),19,Color("e4c483"));draw_rect(Rect2(lamp.position+Vector2(24,44),Vector2(36,25)),Color("40363b"))
	var active:String=stage_hover if not stage_hover.is_empty() else selected
	var pressed:String=stage_action if not stage_action.is_empty() else stage_pressed
	var amount:float=smoothstep(0,STAGE_ACTION_SECONDS,stage_action_age) if not stage_action.is_empty() else (maxf(.2,stage_pull) if not stage_pressed.is_empty() else 0.0)
	StageObjects.draw(self,active,pressed,amount,presentation_clock,reduced)
	_draw_cue_sheet(cue_sheet)
	if feedback_label.visible and not feedback_label.text.is_empty():_draw_cue_sheet(feedback_sheet)
	if stage_action=="curtain" and not reduced:
		var closure:float=440*smoothstep(.08,STAGE_ACTION_SECONDS,stage_action_age)
		for side:int in 2:
			var x:float=0 if side==0 else 960-closure
			draw_rect(Rect2(x,0,closure,426),Color("594147"))
			for fold:int in range(0,int(closure),18):draw_rect(Rect2(x+fold,0,3,426),Color("453B43"))
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
	if size.x<size.y:draw_style_box(Ui.box(PAPER,Color("8d6b45"),1,3),Rect2(rotation_label.position-Vector2(0,12),rotation_label.size+Vector2(0,24)))
func geometry_snapshot() -> Dictionary:
	var props: Array=[]
	for object: Dictionary in state.get("objects",[]):
		var rect: Rect2=prop_rect(object);var actual=Rect2(field.position+rect.position/LOGICAL*field.size,rect.size/LOGICAL*field.size)
		var grip:Vector2=field.position+FanView.grip(prop_foot(object),object)/LOGICAL*field.size if object.kind=="fan" else Vector2.ZERO
		props.append({"id":object.id,"rect":[actual.position.x,actual.position.y,actual.size.x,actual.size.y],"grip":[grip.x,grip.y],"foot":[(field.position+prop_foot(object)/LOGICAL*field.size).x,(field.position+prop_foot(object)/LOGICAL*field.size).y]})
	var stage_objects:Dictionary={}
	for id:String in StageObjects.IDS:
		var rect:Rect2=stage_object_rect(id)
		var actual:=Rect2(field.position+rect.position/LOGICAL*field.size,rect.size/LOGICAL*field.size)
		stage_objects[id]=[actual.position.x,actual.position.y,actual.size.x,actual.size.y]
	var lamp=Rect2(field.position+lamp_rect().position/LOGICAL*field.size,lamp_rect().size/LOGICAL*field.size)
	return {"field":[field.position.x,field.position.y,field.size.x,field.size.y],"props":props,"stageObjects":stage_objects,"stageAction":stage_action,"lamp":[lamp.position.x,lamp.position.y,lamp.size.x,lamp.size.y],"notebook":{"open":notebook_open and help_open,"page":notebook_page,"recordedTrial":trial_records.has(int(state.round))},"light":light_geometry(),"selected":selected,"paused":paused,"helpOpen":help_open,"menuOpen":menu_open,"touchLayout":touch_layout(),"rotationRequired":touch_layout() and size.x<size.y,"state":state.duplicate(true),"stagePlate":StagePlate.TEXTURE_PATH if StagePlate.valid_texture(textures.get("stage")) else "diagnostic","cueSheet":[cue_sheet.position.x,cue_sheet.position.y,cue_sheet.size.x,cue_sheet.size.y],"hudOwner":str(stage_hud.get_path()),"hudVisible":stage_hud.visible,"performance":performance.geometry_snapshot() if is_instance_valid(performance) else null}
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
		_clear_input();curtain_age=0.0;_layout()
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
