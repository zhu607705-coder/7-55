extends ColorRect
## Full-viewport physical studio. Only the controller writes checkpoints or facts.
signal submit_requested(action:String,value:Dictionary,serial:int)
signal studio_event_requested(event:Dictionary)
signal close_requested
const Session=preload("res://scripts/ui/chapter4_device_session.gd")
const Model=preload("res://scripts/objects/room302_studio_model.gd")
const View=preload("res://scripts/objects/room302_studio_view.gd")
const Ui=preload("res://scripts/ui/native_ui_theme.gd")
var session:RefCounted
var frame:PanelContainer # Compatibility property: no nested panel is created.
var header:HBoxContainer
var safe_area:=Rect2()
var view:Control
var title:Label
var hint:Label
var feedback:Label
var close_button:Button
var checkpoint:Dictionary=Model.initial()
var pending_event:Dictionary={}
var selected:=-1
var reduced:=false
var input_mode:="keyboard"
var _safe_insets:=Vector4.ZERO
var _layout_pending:=false
func configure(id:String,state:Dictionary,font:Font=null)->bool:
	session=Session.new()
	if id!="media_alignment" or not _authority_context(state) or not session.open(id,state):return false
	checkpoint=_checkpoint_from(state)
	if not Model.valid(checkpoint):return false
	reduced=bool(state.native.settings.get("reduced_motion",false))
	session.draft.mediaAlignment=checkpoint.alignment.duplicate()
	if font!=null:theme=Ui.font_theme(font)
	name="Room302Studio";color=Color("c4b594");mouse_filter=Control.MOUSE_FILTER_STOP;z_index=100;clip_contents=true;focus_mode=Control.FOCUS_ALL
	set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	view=View.new();view.film_available=session.prerequisite_ready;add_child(view)
	view.lamp_pressed.connect(_lamp);view.motion_finished.connect(_refresh_view)
	view.studio_event_requested.connect(_event);view.check_requested.connect(_submit)
	header=HBoxContainer.new();header.add_theme_constant_override("separation",12);add_child(header)
	title=_label("灯罩抢岗位",21);title.autowrap_mode=TextServer.AUTOWRAP_OFF;title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;header.add_child(title)
	close_button=Button.new();close_button.text="返回房间";close_button.custom_minimum_size=Vector2(112,48);close_button.size_flags_horizontal=Control.SIZE_SHRINK_END
	Ui.apply_button(close_button,Color("52614b"),Color("f1e7cc"),Color("ad9f78"),4,2,15,Vector2(8,6),Color("edca76"))
	close_button.pressed.connect(func():if can_close():close_requested.emit());header.add_child(close_button)
	hint=_label("",14);add_child(hint)
	feedback=_label("",14);add_child(feedback)
	view.present(checkpoint,session.completed,{},true)
	_refresh_view();return true
func _ready()->void:
	resized.connect(_layout)
	if size.is_zero_approx():layout_fullscreen(get_viewport_rect(),_safe_insets)
	else:_layout()
	grab_focus.call_deferred()
func uses_exclusive_game_viewport()->bool:return true
func set_input_mode(mode:String)->void:
	if mode not in ["keyboard","touch"] or mode==input_mode:return
	if input_mode!=mode:cancel_input()
	input_mode=mode
	if view!=null:view.touch_mode=mode=="touch";_refresh_view()
func _layout()->void:layout_fullscreen(Rect2(position,size),_safe_insets)
func layout_panel(available:Vector2)->void:layout_fullscreen(Rect2(Vector2.ZERO,available),_safe_insets)
func layout_fullscreen(viewport_rect:Rect2,safe_insets:Vector4=Vector4.ZERO)->void:
	if view==null or header==null:return
	if _safe_insets!=safe_insets or position!=viewport_rect.position or size!=viewport_rect.size:cancel_input()
	_safe_insets=safe_insets;position=viewport_rect.position;size=viewport_rect.size
	var margin:=16.0
	safe_area=Rect2(Vector2(safe_insets.x+margin,safe_insets.y+margin),Vector2(maxf(1,size.x-safe_insets.x-safe_insets.z-2*margin),maxf(1,size.y-safe_insets.y-safe_insets.w-2*margin)))
	header.position=safe_area.position;header.size=Vector2(safe_area.size.x,48)
	var compact:bool=size.y<560
	hint.position=safe_area.position+Vector2(0,56);hint.size=Vector2(safe_area.size.x,32 if compact else 48)
	feedback.position=Vector2(safe_area.position.x,safe_area.end.y-34);feedback.size=Vector2(safe_area.size.x,34)
	view.position=Vector2.ZERO;view.size=size;view.touch_mode=input_mode=="touch"
	var top:float=hint.position.y+(38 if compact else 54)
	view.layout_scene(Rect2(Vector2(safe_area.position.x,top),Vector2(safe_area.size.x,maxf(80,feedback.position.y-top-10))))
func _schedule_layout()->void:
	if _layout_pending or not is_inside_tree():return
	_layout_pending=true;_finish_layout.call_deferred()
func _finish_layout()->void:
	_layout_pending=false
	if is_inside_tree():_layout()
func _label(text:String,pixels:int)->Label:
	var label:=Label.new();label.text=text;label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	label.add_theme_color_override("font_color",Color("243326"));label.add_theme_font_size_override("font_size",pixels);label.mouse_filter=Control.MOUSE_FILTER_IGNORE;return label
func _editable()->bool:return session!=null and session.editable() and pending_event.is_empty() and (view==null or view.motion.is_empty())
func _refresh_view()->void:
	if view==null:return
	var current_stage:String=Model.stage(checkpoint,session.completed)
	title.text="灯罩抢岗位" if current_stage=="wardrobe" else ("幕布吞影" if current_stage=="curtain" else "影子收工了")
	if session.operation_locked():hint.text="扫描台还没有底片。301的索引抽屉存着旧导视胶片。"
	elif session.mode=="dark":hint.text=session.definition.darkPrompt
	elif session.completed:hint.text="入口、楼梯和荣誉墙都留在了胶片里。可以返回房间了。"
	elif current_stage=="wardrobe":
		hint.text="点一顶灯罩，再点另一顶交换。缺口决定影子，点扫描台核对。" if input_mode=="touch" else "点两顶灯罩交换，让缺口的影子回到虚线。1/2/3选灯，Enter核对。"
	else:
		hint.text="拖幕布一格，或点绳扣、布边；点两角把手翻面，点扫描台核对。" if input_mode=="touch" else "拉绳或拖幕布移影，点角把手翻面，点扫描台核对。方向键移动 · Q/E翻面 · Enter核对 · R重铺。"
	if view.interactive and not _editable():cancel_input()
	view.interactive=_editable() and not session.operation_locked();view.film_available=session.prerequisite_ready;view.touch_mode=input_mode=="touch"
	close_button.disabled=session.pending
	_schedule_layout()
func _lamp(index:int)->void:
	if not _editable() or Model.stage(checkpoint,session.completed)!="wardrobe":return
	if selected==index:selected=-1;view.choose(-1);set_feedback("这顶帽子先放下了。");return
	if selected<0:selected=index;view.choose(index);set_feedback("再点另一顶帽子，两顶会交换。");return
	var previous:int=selected;selected=-1;view.choose(-1);_event({"kind":"swap","a":previous,"b":index})
func _event(event:Dictionary)->void:
	if not _editable():return
	pending_event=event.duplicate();_refresh_view();studio_event_requested.emit(event)
func _submit()->void:
	if session.completed or session.operation_locked() or session.mode=="dark":return
	if not _editable():return
	if not Model.hats_ready(checkpoint):_event({"kind":"inspect"});return
	session.draft.mediaAlignment=checkpoint.alignment.duplicate()
	var request:Dictionary=session.begin_submit()
	if not request.is_empty():_refresh_view();submit_requested.emit(request.action,request.value,request.serial)
func handle_key(event:InputEventKey)->bool:
	if input_mode!="keyboard" or not event.pressed or event.echo or not is_visible_in_tree():return false
	if close_button.has_focus() and event.keycode in [KEY_ENTER,KEY_KP_ENTER,KEY_SPACE]:return false
	var handled:=true
	if event.keycode in [KEY_ENTER,KEY_KP_ENTER]:_submit()
	elif Model.stage(checkpoint,session.completed)=="wardrobe" and event.keycode in [KEY_1,KEY_2,KEY_3]:_lamp(int(event.keycode)-KEY_1)
	elif Model.stage(checkpoint,session.completed)=="curtain":
		match event.keycode:
			KEY_LEFT:_event({"kind":"step","axis":"xOffset","delta":-1})
			KEY_RIGHT:_event({"kind":"step","axis":"xOffset","delta":1})
			KEY_UP:_event({"kind":"step","axis":"yOffset","delta":-1})
			KEY_DOWN:_event({"kind":"step","axis":"yOffset","delta":1})
			KEY_Q:_event({"kind":"step","axis":"rotationQuarterTurns","delta":-1})
			KEY_E:_event({"kind":"step","axis":"rotationQuarterTurns","delta":1})
			KEY_R:_event({"kind":"reset_alignment"})
			_:handled=false
	else:handled=false
	return handled
func set_feedback(message:String)->void:
	if feedback!=null:feedback.text=message
func resolve_studio_event(state:Dictionary,result:Dictionary)->void:
	_sync_checkpoint(state);set_feedback(str(result.get("message","")));view.show_feedback(str(result.get("studio_motion","")));pending_event.clear();_refresh_view()
func _checkpoint_from(state:Dictionary)->Dictionary:
	if "a3_media_alignment_completed" in state.chapter4.factIds:return {"version":1,"hats":Model.HATS.duplicate(),"alignment":Model.source().registration.media.duplicate()}
	return state.native.get("c4_media_studio",Model.initial()).duplicate(true)
func _sync_checkpoint(state:Dictionary)->void:
	var next:Dictionary=_checkpoint_from(state)
	if not Model.valid(next):return
	if next!=checkpoint:
		checkpoint=next;session.draft.mediaAlignment=next.alignment.duplicate();view.present(checkpoint,session.completed,pending_event,reduced)
func sync_authority(state:Dictionary)->bool:
	if not _authority_context(state) or not session.compatible(state):cancel_input();return false
	session.update_authority(state);_sync_checkpoint(state)
	if session.completed:view.present(checkpoint,true,{},reduced)
	_refresh_view();return true
func resolve_submission(serial:int,state:Dictionary,result:Dictionary)->void:
	if session.resolve(serial,state,result):
		set_feedback(session.feedback)
		if session.completed:view.present(checkpoint,true,{},reduced)
		else:view.show_feedback("hiccup")
		_refresh_view()
func can_close()->bool:return session==null or not session.pending
func owns_feedback()->bool:return session!=null and (session.pending or not pending_event.is_empty())
func cancel_input()->void:
	selected=-1
	if view!=null:view.cancel_gesture();view.choose(-1)
func _notification(what:int)->void:
	if what==NOTIFICATION_WM_WINDOW_FOCUS_OUT or what==NOTIFICATION_EXIT_TREE or (what==NOTIFICATION_VISIBILITY_CHANGED and not is_visible_in_tree()):cancel_input()
func _authority_context(state:Dictionary)->bool:
	var native:Dictionary=state.get("native",{})
	var chapter:Dictionary=state.get("chapter4",{})
	return native.get("chapter",0)==4 and native.get("scene","")=="duan_yongping_temporal_maze" and native.get("mode","")==chapter.get("mode","")
func dispose_session()->void:
	cancel_input();pending_event.clear()
	if view!=null:view.interactive=false
	if session!=null:
		# Retirement invalidates only this ephemeral request, never controller facts.
		session.pending=false;session.pending_serial=0;session.close()
