extends ColorRect
## The press owns presentation and gestures; the controller owns the plate and facts.
signal submit_requested(action:String,value:Dictionary,serial:int)
signal press_event_requested(event:Dictionary)
signal close_requested
const Session=preload("res://scripts/ui/chapter4_device_session.gd")
const Model=preload("res://scripts/objects/room201_press_model.gd")
const View=preload("res://scripts/objects/room201_press_view.gd")
const Ui=preload("res://scripts/ui/native_ui_theme.gd")
const FACT:="a2_positioning_plate_calibrated"
var session:RefCounted
var frame:PanelContainer # Fullscreen lifecycle compatibility; deliberately no inner panel.
var header:HBoxContainer
var safe_area:=Rect2()
var view:Control
var title:Label
var hint:Label
var feedback:Label
var close_button:Button
var checkpoint:Dictionary=Model.initial()
var pending_event:Dictionary={}
var reduced:=false
var plate_available:=false
var input_mode:="keyboard"
var _safe_insets:=Vector4.ZERO
var _layout_pending:=false
func configure(id:String,state:Dictionary,font:Font=null)->bool:
	session=Session.new()
	if id!="positioning_calibration" or not _authority_context(state) or not session.open(id,state):return false
	checkpoint=_checkpoint_from(state)
	if not Model.valid(checkpoint):return false
	plate_available=_plate_ready(state)
	reduced=bool(state.native.settings.get("reduced_motion",false))
	session.draft.calibration=checkpoint.calibration.duplicate()
	if font!=null:theme=Ui.font_theme(font)
	name="Room201Press";color=Color("222a29");mouse_filter=Control.MOUSE_FILTER_STOP;z_index=100;clip_contents=true;focus_mode=Control.FOCUS_ALL
	set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	view=View.new();view.plate_available=plate_available;add_child(view)
	view.press_event_requested.connect(_event);view.press_requested.connect(_submit);view.motion_finished.connect(_refresh_view)
	header=HBoxContainer.new();header.add_theme_constant_override("separation",10);add_child(header)
	title=_label("定位片，请坐好",21);title.autowrap_mode=TextServer.AUTOWRAP_OFF;title.clip_text=true;title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;header.add_child(title)
	close_button=Button.new();close_button.text="返回工坊";close_button.custom_minimum_size=Vector2(108,48);close_button.size_flags_horizontal=Control.SIZE_SHRINK_END
	Ui.apply_button(close_button,Color("485651"),Color("f4e5bd"),Color("89978b"),4,2,15,Vector2(8,6),Color("edca76"))
	close_button.pressed.connect(func():if can_close():close_requested.emit());header.add_child(close_button)
	hint=_label("",14);add_child(hint)
	feedback=_label("",14);add_child(feedback)
	view.present(checkpoint,session.completed and plate_available,{},true)
	_refresh_view();return true
func _ready()->void:
	resized.connect(_layout)
	if size.is_zero_approx():layout_fullscreen(get_viewport_rect(),_safe_insets)
	else:_layout()
	grab_focus.call_deferred()
func uses_exclusive_game_viewport()->bool:return true
func set_input_mode(mode:String)->void:
	if mode not in ["keyboard","touch"] or mode==input_mode:return
	cancel_input();input_mode=mode
	if view!=null:view.touch_mode=mode=="touch";_refresh_view()
func _layout()->void:layout_fullscreen(Rect2(position,size),_safe_insets)
func layout_panel(available:Vector2)->void:layout_fullscreen(Rect2(Vector2.ZERO,available),_safe_insets)
func layout_fullscreen(viewport_rect:Rect2,safe_insets:Vector4=Vector4.ZERO)->void:
	if view==null or header==null:return
	if _safe_insets!=safe_insets or position!=viewport_rect.position or size!=viewport_rect.size:cancel_input()
	_safe_insets=safe_insets;position=viewport_rect.position;size=viewport_rect.size
	var margin:=14.0
	safe_area=Rect2(Vector2(safe_insets.x+margin,safe_insets.y+margin),Vector2(maxf(1,size.x-safe_insets.x-safe_insets.z-2*margin),maxf(1,size.y-safe_insets.y-safe_insets.w-2*margin)))
	header.position=safe_area.position;header.size=Vector2(safe_area.size.x,48)
	title.add_theme_font_size_override("font_size",18 if size.x<500 else 21)
	var compact:bool=size.y<560
	hint.position=safe_area.position+Vector2(0,55);hint.size=Vector2(safe_area.size.x,34 if compact else 52)
	feedback.position=Vector2(safe_area.position.x,safe_area.end.y-40);feedback.size=Vector2(safe_area.size.x,40)
	view.position=Vector2.ZERO;view.size=size;view.touch_mode=input_mode=="touch"
	var top:float=hint.position.y+(38 if compact else 56)
	view.layout_scene(Rect2(Vector2(safe_area.position.x,top),Vector2(safe_area.size.x,maxf(80,feedback.position.y-top-8))))
func _schedule_layout()->void:
	if _layout_pending or not is_inside_tree():return
	_layout_pending=true;_finish_layout.call_deferred()
func _finish_layout()->void:
	_layout_pending=false
	if is_inside_tree():_layout()
func _label(text:String,pixels:int)->Label:
	var label:=Label.new();label.text=text;label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	label.add_theme_color_override("font_color",Color("e4dfc7"));label.add_theme_font_size_override("font_size",pixels);label.mouse_filter=Control.MOUSE_FILTER_IGNORE;return label
func _editable()->bool:return session!=null and session.editable() and plate_available and pending_event.is_empty() and (view==null or view.motion.is_empty())
func _refresh_view()->void:
	if view==null:return
	var current_stage:String=Model.stage(checkpoint,session.completed and plate_available)
	title.text="定位片，请坐好" if current_stage=="insert" else ("压一下，别嘴硬" if current_stage=="adjust" else "定位片终于服帖了")
	if not plate_available:hint.text="卡槽空着。先从 204 讲台抽屉取出钟面定位片，再把它送进压床。"
	elif session.completed:hint.text="三处压印已经咬合。原件可以带走，A1 旧钟正等着它。"
	elif session.mode=="dark":hint.text="旧伤还在：看三处触点的磨痕和弹簧上的亮槽。切回浅色后可以动手。"
	elif current_stage=="insert":hint.text="把手边的定位片推入压床。机器已经等得有点不耐烦了。" if input_mode=="touch" else "把手边的定位片拖进卡槽，或点它入座。Enter / 空格装板。"
	else:hint.text="拖定位片对上旧痕，转手轮收紧弹簧，再拉下木柄压杆。" if input_mode=="touch" else "拖板对旧痕，转手轮蓄压，再拉压杆。方向键移轨 · Q/E收放弹簧 · Enter压印 · R复位。"
	if view.interactive and not _editable():cancel_input()
	view.interactive=_editable();view.plate_available=plate_available;view.touch_mode=input_mode=="touch"
	close_button.disabled=session.pending or not pending_event.is_empty()
	_schedule_layout()
func _event(event:Dictionary)->void:
	if not _editable():return
	pending_event=event.duplicate();_refresh_view();press_event_requested.emit(event)
func _submit()->void:
	if not _editable():return
	if not checkpoint.inserted:_event({"kind":"insert"});return
	session.draft.calibration=checkpoint.calibration.duplicate()
	var request:Dictionary=session.begin_submit()
	if not request.is_empty():
		view.begin_press();_refresh_view();submit_requested.emit(request.action,request.value,request.serial)
func handle_key(event:InputEventKey)->bool:
	if input_mode!="keyboard" or not event.pressed or event.echo or not is_visible_in_tree():return false
	if close_button.has_focus() and event.keycode in [KEY_ENTER,KEY_KP_ENTER,KEY_SPACE]:return false
	if event.keycode in [KEY_ENTER,KEY_KP_ENTER,KEY_SPACE]:_submit();return true
	if not checkpoint.inserted:return false
	match event.keycode:
		KEY_LEFT:_event({"kind":"step","axis":"horizontal","delta":-1})
		KEY_RIGHT:_event({"kind":"step","axis":"horizontal","delta":1})
		KEY_UP:_event({"kind":"step","axis":"vertical","delta":-1})
		KEY_DOWN:_event({"kind":"step","axis":"vertical","delta":1})
		KEY_Q:_event({"kind":"step","axis":"pressure","delta":-1})
		KEY_E:_event({"kind":"step","axis":"pressure","delta":1})
		KEY_R:_event({"kind":"reset"})
		_:return false
	return true
func set_feedback(message:String)->void:
	if feedback!=null:feedback.text=message
func resolve_press_event(state:Dictionary,result:Dictionary)->void:
	if session==null or not session.opened:return
	if not _authority_context(state) or not session.compatible(state):cancel_input();return
	session.update_authority(state);plate_available=_plate_ready(state)
	_sync_checkpoint(state);set_feedback(str(result.get("message","")));view.show_feedback(str(result.get("press_motion","")));pending_event.clear();_refresh_view()
func _checkpoint_from(state:Dictionary)->Dictionary:
	if not _plate_ready(state):return Model.initial()
	if FACT in state.get("chapter4",{}).get("factIds",[]):
		return {"version":1,"inserted":true,"calibration":Model.source().registration.calibration.duplicate(),"imprinted":true}
	var stored:Variant=state.get("native",{}).get("c4_plate_press",Model.initial())
	return stored.duplicate(true) if stored is Dictionary else {}
func _sync_checkpoint(state:Dictionary)->void:
	var next:Dictionary=_checkpoint_from(state)
	if not Model.valid(next):return
	if next!=checkpoint:
		checkpoint=next;session.draft.calibration=next.calibration.duplicate();view.present(checkpoint,session.completed and plate_available,pending_event,reduced)
func sync_authority(state:Dictionary)->bool:
	if session==null or not _authority_context(state) or not session.compatible(state):cancel_input();return false
	session.update_authority(state);plate_available=_plate_ready(state);_sync_checkpoint(state)
	if session.completed:view.present(checkpoint,plate_available,{},reduced)
	_refresh_view();return true
func resolve_submission(serial:int,state:Dictionary,result:Dictionary)->void:
	if not _authority_context(state) or not session.compatible(state):cancel_input();return
	if session.resolve(serial,state,result):
		_sync_checkpoint(state)
		set_feedback("定位片带着三枚整齐压印弹了起来。旧钟还缺这块原件。" if session.completed else session.feedback)
		view.show_feedback("success" if session.completed else "bounce")
		_refresh_view()
func can_close()->bool:return session==null or (not session.pending and pending_event.is_empty())
func owns_feedback()->bool:return session!=null and (session.pending or not pending_event.is_empty())
func cancel_input()->void:
	if view!=null:view.cancel_gesture()
func _notification(what:int)->void:
	if what==NOTIFICATION_WM_WINDOW_FOCUS_OUT or what==NOTIFICATION_EXIT_TREE or (what==NOTIFICATION_VISIBILITY_CHANGED and not is_visible_in_tree()):cancel_input()
func _plate_ready(state:Dictionary)->bool:
	return bool(state.get("items",{}).get("clockPositioningPlate",false)) and "positioning_plate_collected" in state.get("chapter4",{}).get("factIds",[])
func _authority_context(state:Dictionary)->bool:
	var native:Dictionary=state.get("native",{});var chapter:Dictionary=state.get("chapter4",{})
	return native.get("chapter",0)==4 and native.get("scene","")=="duan_yongping_temporal_maze" and native.get("mode","")==chapter.get("mode","") and chapter.get("phase","")=="room204_restore" and chapter.get("floor","")=="A2" and chapter.get("timeState","")=="1850_evening" and native.get("c4_context","")=="positioning_calibration" and bool(chapter.get("prologueSeen",false)) and "misaligned_stair_solved" in chapter.get("factIds",[])
func dispose_session()->void:
	cancel_input();pending_event.clear()
	if view!=null:view.interactive=false
	if session!=null:session.pending=false;session.pending_serial=0;session.close()
