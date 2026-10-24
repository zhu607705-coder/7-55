extends Control
## Optional, silent stage presentation. Closing it never emits a game intent.
signal closed(reason:String)
const Model=preload("res://scripts/presentation/liangzhu_performance_model.gd")
const ActorRig=preload("res://scripts/presentation/liangzhu_actor_rig.gd")
const StagePlate=preload("res://scripts/presentation/liangzhu_stage_plate.gd")
const Ui=preload("res://scripts/ui/native_ui_theme.gd")
const TheaterUi=preload("res://scripts/ui/theater_typography.gd")
const ASSET_ROOT="res://assets/native/liangzhu_performance_20261021/"
const PAPER=Color("F4EAD5")
const INK=Color("202B35")
var model:RefCounted
var read_state:Callable
var is_blocked:Callable
var bound_state:Dictionary={}
var bound_context:Dictionary={}
var textures:Dictionary={}
var asset_issues:Array[String]=[]
var assets_ready:=false
var diagnostic:=false
var disposed:=false
var built:=false
var stage_viewport:SubViewport
var stage_canvas:Node2D
var stage_image:TextureRect
var stage_frame:Control
var title_background:ColorRect
var caption_background:ColorRect
var title:Label
var caption:Label
var pause_button:Button
var return_button:Button
var qte_label:Label
var retry_button:Button
var help_button:Button
var help_panel:Panel
var help_body:Label
var help_next:Button
var help_close:Button
var passive_button:Button
var help_open:=false
var help_restore:Dictionary={}
var qte_target:=Rect2()
var qte_pointer:=""
var qte_pointer_start:=Vector2.ZERO
var qte_pointer_current:=Vector2.ZERO
var qte_pointer_moved:=false
var last_touch_ms:=-1000
var layout_extent:=Vector2.ZERO
var blocked_last:=false
var field:=Rect2()
var title_paper:=Rect2()
var caption_paper:=Rect2()
var capture_pose:Dictionary={}
var stage_pose:Dictionary={}
var actor_rigs:Dictionary={}

class StageCanvas extends Node2D:
	var presenter:Control
	func _draw()->void:
		if is_instance_valid(presenter):presenter.draw_stage(self)

func _ready()->void:
	name="LiangzhuPerformance";mouse_filter=Control.MOUSE_FILTER_STOP;focus_mode=Control.FOCUS_ALL
	_build();resized.connect(_layout);visibility_changed.connect(_visibility_changed)
	get_window().focus_exited.connect(_focus_out)
	_layout();grab_focus.call_deferred()

func setup(config:Dictionary)->bool:
	disposed=false;capture_pose={};textures={};asset_issues=[]
	read_state=config.get("read_state",Callable());is_blocked=config.get("is_blocked",Callable())
	if not read_state.is_valid():return _reject("missing_context")
	var value:Variant=read_state.call()
	if not value is Dictionary or value.is_empty():return _reject("missing_context")
	bound_state=value;bound_context=_context(value)
	if not valid_context():return _reject("invalid_context")
	var assets:Dictionary=config.get("assets",{})
	_load_asset("stage",assets.get("stage",ASSET_ROOT+"stage.png"),Vector2i(1200,675))
	_load_asset("actors",assets.get("actors",ASSET_ROOT+"actors.png"),Vector2i(480,320))
	for id:String in StagePlate.FURNITURE_IDS:
		var spec:Dictionary=StagePlate.furniture().get("props",{}).get(id,{})
		var expected:Array=spec.get("nativeSize",[0,0])
		_load_asset(id,assets.get(id,spec.get("texture",ASSET_ROOT+id+".png")),Vector2i(expected[0],expected[1]))
	assets_ready=asset_issues.is_empty() and textures.size()==5 and StagePlate.furniture_ready(textures)
	diagnostic=not assets_ready and bool(config.get("allow_placeholder",false))
	if not assets_ready and not diagnostic:return _reject("assets_unavailable")
	model=Model.new(bool(value.get("native",{}).get("settings",{}).get("reduced_motion",false)),str(config.get("playback_mode","interactive")))
	if is_inside_tree():_build();_layout();_refresh();show();grab_focus()
	set_meta("blocks_input",true);set_process(true)
	return true

func _reject(reason:String)->bool:
	disposed=true;set_meta("setup_rejection",reason);hide();return false

func _context(value:Dictionary)->Dictionary:
	return {"runtime":value.get("runtimeMode",""),"scene":value.get("rpgScene",""),"nativeScene":value.get("native",{}).get("scene",""),"phase":value.get("theaterHunt",{}).get("phase",""),"mode":value.get("native",{}).get("mode",""),"checkpoint":value.get("rpgCheckpoint","")}

func valid_context()->bool:
	if not read_state.is_valid():return false
	var value:Variant=read_state.call()
	if not value is Dictionary or not is_same(value,bound_state) or _context(value)!=bound_context:return false
	return bound_context.runtime=="rpg" and bound_context.scene=="theater_interior" and bound_context.nativeScene=="theater_interior" and bool(value.get("theaterHunt",{}).get("active",false)) and bool(value.get("theaterHunt",{}).get("admitted",false))

func _load_asset(id:String,value:Variant,expected:Vector2i)->void:
	var texture:Texture2D
	if value is Texture2D:texture=value
	elif value is String and ResourceLoader.exists(value):texture=load(value) as Texture2D
	if texture==null:asset_issues.append(id+":missing");return
	if Vector2i(texture.get_size())!=expected:asset_issues.append(id+":size");return
	textures[id]=texture

func _label(id:String,pixels:int)->Label:
	var node:=Label.new();node.name=id;TheaterUi.text(node);node.mouse_filter=Control.MOUSE_FILTER_IGNORE
	node.add_theme_color_override("font_color",INK);node.add_theme_font_size_override("font_size",pixels)
	node.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;add_child(node);return node

func _button(id:String,text:String,action:Callable)->Button:
	var node:=Button.new();node.name=id;node.text=text;node.focus_mode=Control.FOCUS_NONE
	TheaterUi.button(node,id=="PerformanceQteRetry")
	node.pressed.connect(action);add_child(node);return node

func _build()->void:
	if built:return
	built=true;TheaterUi.apply(self)
	stage_viewport=SubViewport.new();stage_viewport.name="PerformancePixels";stage_viewport.size=Model.RASTER_SIZE
	stage_viewport.disable_3d=true;stage_viewport.gui_disable_input=true;stage_viewport.handle_input_locally=false
	stage_viewport.render_target_update_mode=SubViewport.UPDATE_ONCE;add_child(stage_viewport)
	stage_canvas=StageCanvas.new();stage_canvas.presenter=self;stage_canvas.scale=Vector2(Model.PIXELS_PER_UNIT,Model.PIXELS_PER_UNIT);stage_canvas.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;stage_viewport.add_child(stage_canvas)
	for id:String in ["scholar","yingtai"]:
		var rig:=ActorRig.new();rig.name=id+"Rig";stage_canvas.add_child(rig);actor_rigs[id]=rig
	stage_frame=Control.new();stage_frame.name="PerformanceStageFrame";stage_frame.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(stage_frame)
	stage_image=TextureRect.new();stage_image.name="PerformanceStage";stage_image.texture=stage_viewport.get_texture()
	stage_image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;stage_image.stretch_mode=TextureRect.STRETCH_SCALE
	stage_image.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;stage_image.mouse_filter=Control.MOUSE_FILTER_IGNORE;stage_frame.add_child(stage_image)
	title_background=ColorRect.new();title_background.color=PAPER;title_background.mouse_filter=Control.MOUSE_FILTER_IGNORE;stage_frame.add_child(title_background)
	caption_background=ColorRect.new();caption_background.color=PAPER;caption_background.mouse_filter=Control.MOUSE_FILTER_IGNORE;stage_frame.add_child(caption_background)
	title=_label("PerformanceTitle",20);title.text="梁祝 · 扇影";TheaterUi.heading(title)
	caption=_label("PerformanceCaption",16)
	pause_button=_button("PerformancePause","暂停",_toggle_pause)
	return_button=_button("PerformanceReturn","返回排练",skip)
	help_button=_button("PerformanceQteHelp","观察",_open_help)
	retry_button=_button("PerformanceQteRetry","再接这一拍",_retry_qte)
	qte_label=_label("PerformanceQtePrompt",16)
	qte_label.add_theme_color_override("font_color",Color("FFF0B2"))
	qte_label.add_theme_color_override("font_outline_color",INK)
	for node:Control in [title,caption,pause_button,return_button,help_button,retry_button,qte_label]:node.reparent(stage_frame)
	_build_help()
	_refresh()

func _build_help()->void:
	help_panel=Panel.new();help_panel.name="PerformancePaperMenu";help_panel.add_theme_stylebox_override("panel",Ui.box(PAPER,Color("70503B"),1,0,Vector2(14,12)));stage_frame.add_child(help_panel)
	help_body=Label.new();help_body.name="PerformanceHelpBody";TheaterUi.text(help_body);help_body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;help_body.add_theme_color_override("font_color",INK);help_body.mouse_filter=Control.MOUSE_FILTER_IGNORE;help_panel.add_child(help_body)
	for spec:Array in [["PerformanceHelpNext","再观察一层",_more_help],["PerformancePassive","从头观看",_start_passive],["PerformanceHelpClose","回到演出",_close_help]]:
		var button:=Button.new();button.name=spec[0];button.text=spec[1];button.focus_mode=Control.FOCUS_ALL;TheaterUi.button(button,spec[0]=="PerformanceHelpClose");button.pressed.connect(spec[2]);help_panel.add_child(button)
		if spec[0]=="PerformanceHelpNext":help_next=button
		elif spec[0]=="PerformancePassive":passive_button=button
		else:help_close=button
	help_panel.hide()

func uses_activity_layout()->bool:return true
func configure_activity_layout(available:Vector2,_compact:bool=false)->void:
	custom_minimum_size=Vector2.ZERO;scale=Vector2.ONE;position=Vector2.ZERO;size=available.max(Vector2(280,200));_layout()

func _layout()->void:
	if not built or size.x<=0 or size.y<=0:return
	if layout_extent!=Vector2.ZERO and layout_extent!=size:_interrupt_qte("resize")
	layout_extent=size
	var width:float=minf(size.x,size.y*16.0/9.0)
	field=Rect2((size-Vector2(width,width*9.0/16.0))/2.0,Vector2(width,width*9.0/16.0))
	var portrait:bool=size.x<size.y
	var fit:float=field.size.x/StagePlate.WORLD_SIZE.x
	var title_px:int=ceili(20.0/fit);var body_px:int=ceili(16.0/fit)
	title.add_theme_font_size_override("font_size",title_px);caption.add_theme_font_size_override("font_size",body_px)
	var measured:float=caption.get_theme_font("font").get_multiline_string_size(caption.text,HORIZONTAL_ALIGNMENT_LEFT,maxf(1,(field.size.x-44)/fit),body_px).y*fit
	var caption_height:float=maxf(52 if portrait else 46,ceilf(measured)+8)
	var pause_rect:=Rect2();var return_rect:=Rect2();var help_rect:=Rect2()
	if portrait:
		# The complete frame and its adjoining caption form one centred unit.
		# Text stays readable without drifting to the screen's distant edges.
		var group_height:float=44+8+field.size.y+8+caption_height+8+44
		var top:float=maxf(8,(size.y-group_height)/2.0)
		field.position.y=top+52
		title_paper=Rect2(field.position.x+12,top,field.size.x-24,44)
		caption_paper=Rect2(field.position.x+12,field.end.y+8,field.size.x-24,caption_height)
		pause_rect=Rect2(field.position.x+12,caption_paper.end.y+8,96,44)
		var gap:float=(field.size.x-24-304)/2.0
		help_rect=Rect2(pause_rect.end.x+gap,pause_rect.position.y,84,44)
		return_rect=Rect2(field.end.x-136,caption_paper.end.y+8,124,44)
	else:
		title_paper=Rect2(field.position+Vector2(12,12),Vector2(minf(230,maxf(100,field.size.x-384)),44))
		pause_rect=Rect2(field.end.x-260,field.position.y+12,108,44)
		help_rect=Rect2(field.end.x-356,field.position.y+12,84,44)
		return_rect=Rect2(field.end.x-140,field.position.y+12,124,44)
		caption_paper=Rect2(field.position.x+12,field.end.y-caption_height-12,field.size.x-24,caption_height)
	stage_frame.position=field.position;stage_frame.size=StagePlate.WORLD_SIZE;stage_frame.scale=Vector2.ONE*fit
	stage_image.position=Vector2.ZERO;stage_image.size=StagePlate.WORLD_SIZE
	_frame_rect(title_background,title_paper,fit);_frame_rect(title,title_paper.grow_individual(-10,-7,-10,-5),fit)
	_frame_rect(caption_background,caption_paper,fit);_frame_rect(caption,caption_paper.grow_individual(-10,-4,-10,-4),fit)
	_frame_rect(pause_button,pause_rect,fit);_frame_rect(return_button,return_rect,fit)
	_frame_rect(help_button,help_rect,fit);_frame_rect(retry_button,pause_rect,fit)
	for button:Button in [pause_button,return_button,help_button,retry_button]:button.add_theme_font_size_override("font_size",body_px)
	# Measure at a finite width before placing the paper. A wrapping Label's
	# transient minimum height must never push the actions below the viewport.
	var menu_width:float=minf(360,size.x-32)
	help_body.add_theme_font_size_override("font_size",body_px)
	var help_height:float=maxf(24,ceilf(help_body.get_theme_font("font").get_multiline_string_size(help_body.text,HORIZONTAL_ALIGNMENT_LEFT,(menu_width-28)/fit,body_px).y*fit))
	var help_actions:Array[Button]=[]
	for button:Button in [help_next,passive_button,help_close]:
		button.custom_minimum_size=Vector2.ZERO;button.add_theme_font_size_override("font_size",body_px)
		if button.visible:help_actions.append(button)
	var menu_size:=Vector2(menu_width,24+help_height+float(help_actions.size())*52)
	var menu_origin:Vector2=field.get_center()-menu_size/2
	menu_origin.x=clampf(menu_origin.x,16,size.x-menu_size.x-16);menu_origin.y=clampf(menu_origin.y,16,size.y-menu_size.y-16)
	_frame_rect(help_panel,Rect2(menu_origin,menu_size),fit)
	help_body.position=Vector2(14,12)/fit;help_body.size=Vector2(menu_width-28,help_height)/fit
	var action_y:float=12+help_height+8
	for button:Button in help_actions:
		button.position=Vector2(14,action_y)/fit;button.size=Vector2(menu_width-28,44)/fit;action_y+=52
	queue_redraw();_redraw_stage()

func _frame_rect(control:Control,screen:Rect2,fit:float)->void:
	control.position=(screen.position-field.position)/fit;control.size=screen.size/fit

func _draw()->void:
	draw_rect(Rect2(Vector2.ZERO,size),INK)

func _process(delta:float)->void:
	tick(delta,get_window().has_focus())

func tick(delta:float,focused:bool=true,host_blocked:bool=false)->void:
	if disposed or model==null:return
	if not valid_context():cancel("context_changed");return
	var blocked:bool=host_blocked or bool(bound_state.get("ui",{}).get("controlCenterOpen",false))
	if is_blocked.is_valid():blocked=blocked or bool(is_blocked.call())
	if blocked and not blocked_last:_interrupt_qte("overlay")
	blocked_last=blocked
	if not capture_pose.is_empty():return
	model.reduced_motion=bool(bound_state.get("native",{}).get("settings",{}).get("reduced_motion",false))
	var completed:bool=model.tick(delta,focused,blocked or help_open)
	_refresh()
	if completed:_finish("finished")

func _refresh()->void:
	if not built or model==null:return
	var pose:Dictionary=capture_pose if not capture_pose.is_empty() else model.snapshot()
	var qte:Dictionary=_qte()
	var next_caption:String=str(qte.get("feedback","")) if model.status=="failure" else str(pose.caption)
	var text_changed:bool=caption.text!=next_caption
	caption.text=next_caption
	title.text="梁祝 · 扇影"+(" · 观看" if model.playback_mode=="passive" else "")
	pause_button.text="继续" if model.manually_paused or model.focus_paused else "暂停"
	pause_button.visible=model.status!="failure";retry_button.visible=model.status=="failure"
	retry_button.text=str(qte.get("retryLabel","再接这一拍"))
	help_panel.visible=help_open;caption.visible=not help_open;caption_background.visible=not help_open
	if qte_pointer!="" and model.status!="waiting":qte_pointer=""
	if text_changed:_layout()
	_redraw_stage()

func _redraw_stage()->void:
	if not built:return
	if model!=null:
		stage_pose=capture_pose if not capture_pose.is_empty() else model.snapshot()
		for actor:Dictionary in stage_pose.actors:
			actor_rigs[actor.id].configure_pose(int(actor.frame),int(actor.row),actor.foot,bool(actor.flip),float(stage_pose.elapsedMs),bool(stage_pose.reducedMotion))
	_update_qte_target()
	stage_canvas.queue_redraw();stage_viewport.render_target_update_mode=SubViewport.UPDATE_ONCE

func pause()->void:
	if model==null or disposed:return
	model.pause();_refresh()

func resume()->void:
	if model==null or disposed:return
	if not valid_context():cancel("context_changed");return
	model.resume();_refresh();grab_focus()

func _toggle_pause()->void:
	if model==null or disposed or help_open:return
	var was_paused:bool=model.manually_paused or model.focus_paused
	_clear_pointer();model.interrupt_input("pause")
	if was_paused:resume()
	else:pause()

func _focus_out()->void:
	if model!=null and not disposed:_interrupt_qte("focus_lost");model.focus_paused=true;_refresh()

func _visibility_changed()->void:
	if not is_visible_in_tree():_focus_out()

func _gui_input(event:InputEvent)->void:
	if disposed:return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_SPACE,KEY_ENTER,KEY_KP_ENTER]:_toggle_pause();accept_event()
		elif event.keycode==KEY_ESCAPE:
			if help_open:_close_help()
			else:skip()
			accept_event()

func _qte()->Dictionary:
	return model.qte_snapshot() if model!=null and capture_pose.is_empty() else {}

func _host_blocks_input()->bool:
	return bool(bound_state.get("ui",{}).get("controlCenterOpen",false)) or (is_blocked.is_valid() and bool(is_blocked.call()))

func _clear_pointer()->void:qte_pointer="";qte_pointer_start=Vector2.ZERO;qte_pointer_current=Vector2.ZERO;qte_pointer_moved=false

func _interrupt_qte(reason:String)->void:
	_clear_pointer()
	if model!=null:model.interrupt_input(reason)

func _open_help()->void:
	if disposed or model==null or help_open:return
	help_restore={"manual":model.manually_paused,"focus":model.focus_paused}
	_interrupt_qte("help");model.pause();help_open=true
	var qte:Dictionary=_qte()
	help_body.text=model.request_qte_help() if not qte.is_empty() else "留意手里的扇与回身的脚步。\n在停下的那一拍，把动作接过去。"
	help_next.visible=not qte.is_empty() and int(qte.get("hintTier",0))<2
	_refresh();_layout();help_close.grab_focus.call_deferred()

func _more_help()->void:
	if not help_open:return
	help_body.text=model.request_qte_help();help_next.visible=int(_qte().get("hintTier",0))<2;_layout()

func _close_help()->void:
	if not help_open:return
	help_open=false;model.resume()
	if help_restore.get("manual",false):model.pause()
	if help_restore.get("focus",false):model.focus_paused=true
	help_restore={};_refresh();grab_focus()

func _start_passive()->void:
	if disposed or model==null:return
	_clear_pointer();model.cancel()
	model=Model.new(bool(bound_state.get("native",{}).get("settings",{}).get("reduced_motion",false)),"passive")
	capture_pose={};help_open=false;help_restore={};blocked_last=false
	_refresh();_layout();grab_focus()

func _retry_qte()->void:
	if disposed or model==null or help_open or _host_blocks_input():return
	_clear_pointer();model.resume();model.retry_qte();_refresh();grab_focus()

func _submit_qte(phase:String,direction:String="",owner:String="keyboard")->Dictionary:
	var qte:Dictionary=_qte()
	if qte.is_empty():return {"accepted":false,"reason":"inactive"}
	var result:Dictionary=model.qte_input(str(qte.action),phase,direction,owner)
	_refresh();return result

func _update_qte_target()->void:
	qte_target=Rect2()
	if not built:return
	var qte:Dictionary=_qte()
	qte_label.visible=not qte.is_empty() and not help_open
	if qte.is_empty() or field.size.x<=0:return
	var attachment:Dictionary=qte.get("targetAttachment",{})
	var rig:Node2D=actor_rigs.get(str(attachment.get("actor","")))
	if not is_instance_valid(rig):return
	var anchor:Vector2=rig.attachment_local(str(attachment.get("socket","FanSocket"))).origin
	var offset:Array=attachment.get("offset",[0,0]);anchor+=Vector2(float(offset[0]),float(offset[1]))
	var point:Vector2=field.position+anchor/StagePlate.COMPOSITION_SIZE*field.size
	qte_target=Rect2(point-Vector2(22,22),Vector2(44,44))
	# Only the expanded grip is interactive; visible words remain display-only.
	var fit:float=field.size.x/StagePlate.WORLD_SIZE.x
	qte_label.add_theme_font_size_override("font_size",ceili(16.0/fit))
	qte_label.add_theme_constant_override("outline_size",maxi(1,ceili(1.0/fit)))
	qte_label.text="稳住了 · 松手" if qte.get("holding",false) and float(qte.get("holdProgress",0))>=1 else str(qte.get("prompt",qte.get("title","")))
	if model.status=="failure":qte_label.text="错过一拍"
	var label_size:=Vector2(140,30)
	var label_point:Vector2=point-Vector2(70,54)
	label_point.x=clampf(label_point.x,field.position.x+8,field.end.x-label_size.x-8)
	label_point.y=clampf(label_point.y,field.position.y+72,caption_paper.position.y-label_size.y-6 if caption_paper.position.y<field.end.y else field.end.y-label_size.y-6)
	_frame_rect(qte_label,Rect2(label_point,label_size),fit)

func _input(event:InputEvent)->void:
	if disposed or model==null or not visible or not capture_pose.is_empty():return
	if _host_blocks_input():
		if qte_pointer!="":_interrupt_qte("overlay")
		return
	var qte:Dictionary=_qte()
	if help_open or qte.is_empty():return
	if event is InputEventKey:
		var key:Key=event.keycode
		var owner:String="key:"+str(key)
		if event.echo:return
		if event.pressed:
			if key==KEY_H:_open_help()
			elif model.status=="failure" and key in [KEY_R,KEY_ENTER,KEY_KP_ENTER]:_retry_qte()
			elif model.manually_paused or model.focus_paused:
				if key in [KEY_SPACE,KEY_ENTER,KEY_KP_ENTER]:resume()
				else:return
			elif model.status!="waiting":return
			elif qte.action=="catch" and key in [KEY_SPACE,KEY_ENTER,KEY_KP_ENTER]:_submit_qte("tap","",owner)
			elif qte.action=="turn" and key in [KEY_LEFT,KEY_RIGHT]:_submit_qte("swipe","left" if key==KEY_LEFT else "right",owner)
			elif qte.action=="butterfly" and key==KEY_SPACE:
				if _submit_qte("press","",owner).get("accepted",false):qte_pointer=owner
			else:return
		elif qte.action=="butterfly" and key==KEY_SPACE and qte_pointer==owner:
			_clear_pointer();_submit_qte("release","",owner)
		else:return
		get_viewport().set_input_as_handled();return
	if event is InputEventScreenTouch:
		last_touch_ms=Time.get_ticks_msec()
		var owner:String="touch:"+str(event.index)
		var point:Vector2=get_global_transform_with_canvas().affine_inverse()*event.position
		if event.pressed:
			if not _pointer_begin(owner,point):return
		elif qte_pointer==owner:
			if event.canceled:_interrupt_qte("pointer_cancelled");_refresh()
			else:_pointer_end(owner,point)
		else:return
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and qte_pointer=="touch:"+str(event.index):
		_pointer_motion(get_global_transform_with_canvas().affine_inverse()*event.position);get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.device!=-1 and (qte_pointer=="mouse" or Time.get_ticks_msec()-last_touch_ms>600):
		# Godot's first-touch mouse emulation uses device -1 and can arrive
		# before ScreenTouch. Only the actual finger may own that gesture.
		var point:Vector2=get_global_transform_with_canvas().affine_inverse()*event.position
		if event.pressed:
			if not _pointer_begin("mouse",point):return
		elif qte_pointer=="mouse":_pointer_end("mouse",point)
		else:return
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and event.device!=-1 and qte_pointer=="mouse":
		_pointer_motion(get_global_transform_with_canvas().affine_inverse()*event.position);get_viewport().set_input_as_handled()

func _pointer_begin(owner:String,point:Vector2)->bool:
	if qte_pointer!="" or model.status!="waiting" or model.manually_paused or model.focus_paused or not qte_target.has_point(point):return false
	qte_pointer=owner;qte_pointer_start=point;qte_pointer_current=point;qte_pointer_moved=false
	if _qte().action=="butterfly":_submit_qte("press","",owner)
	return true

func _pointer_motion(point:Vector2)->void:
	qte_pointer_current=point
	if point.distance_to(qte_pointer_start)>12:qte_pointer_moved=true
	if _qte().get("action","")=="butterfly" and not qte_target.grow(10).has_point(point):_interrupt_qte("pointer_left");_refresh()

func _pointer_end(owner:String,point:Vector2)->void:
	var delta:Vector2=point-qte_pointer_start
	var qte:Dictionary=_qte()
	var moved:bool=qte_pointer_moved
	_clear_pointer()
	if qte.is_empty() or model.status!="waiting":return
	if qte.action=="catch":
		if not moved and qte_target.has_point(point) and delta.length()<=12:_submit_qte("tap","",owner)
	elif qte.action=="turn":
		if absf(delta.x)>=16 and absf(delta.x)>=absf(delta.y):_submit_qte("swipe","left" if delta.x<0 else "right",owner)
	elif qte.action=="butterfly":
		if qte_target.grow(10).has_point(point):_submit_qte("release","",owner)
		else:_interrupt_qte("pointer_left");_refresh()

func skip()->void:_finish("skipped")
func cancel(reason:String="cancelled")->void:_finish(reason)
func dispose_presentation()->void:_finish("disposed",false)

func _finish(reason:String,emit_signal:bool=true)->void:
	if disposed:return
	disposed=true;capture_pose={};_clear_pointer()
	if model!=null:model.cancel()
	set_meta("blocks_input",false);hide();set_process(false)
	if emit_signal:closed.emit(reason)

func _exit_tree()->void:
	if model!=null:model.cancel()
	disposed=true;bound_state={};read_state=Callable();is_blocked=Callable()

## Offline capture uses the same draw path without advancing the runtime clock.
func render_at(time_ms:float)->void:
	if model==null or disposed:return
	capture_pose=Model.pose_at(time_ms,model.reduced_motion);_refresh()

func stage_texture()->Texture2D:
	return stage_viewport.get_texture() if is_instance_valid(stage_viewport) else null

func geometry_snapshot()->Dictionary:
	var rig_data:Dictionary={}
	for id:String in actor_rigs:
		var rig:Node2D=actor_rigs[id]
		var socket:Vector2=rig.attachment_local("FanSocket").origin
		rig_data[id]={"bones":_count_bones(rig),"fanSocket":{"x":socket.x,"y":socket.y}}
	var fan_data:Array=[]
	if not stage_pose.is_empty():
		for fan:Dictionary in _resolved_fans(stage_pose):fan_data.append({"kind":fan.kind,"side":fan.side,"point":{"x":fan.point.x,"y":fan.point.y}})
	var furniture_data:Array=[]
	for prop:Dictionary in StagePlate.furniture_entries("performance",stage_pose.get("stageProps",[])):
		furniture_data.append({"id":prop.id,"rect":_rect_data(prop.rect),"foot":{"x":prop.foot.x,"y":prop.foot.y},"alpha":prop.alpha})
	var result:Dictionary={"assetsReady":assets_ready,"furnitureReady":StagePlate.furniture_ready(textures),"furnitureCount":StagePlate.FURNITURE_IDS.filter(func(id:String)->bool:return textures.has(id)).size(),"furnitureLayout":"performance","furnitureManifest":StagePlate.FURNITURE_PATH,"furniture":furniture_data,"diagnostic":diagnostic,"assetIssues":asset_issues.duplicate(),"disposed":disposed,"logicalSize":{"x":240,"y":135},"rasterSize":{"x":1200,"y":675},"worldViewport":{"x":960,"y":540},"field":_rect_data(field),"frameOwner":str(stage_frame.get_path()) if is_instance_valid(stage_frame) else "","captionRect":_rect_data(caption_paper),"titleRect":_rect_data(title_paper),"elapsedMs":model.elapsed_ms if model!=null else 0.0,"paused":model.manually_paused or model.focus_paused if model!=null else false,"capture":not capture_pose.is_empty(),"actorRigs":rig_data,"fans":fan_data,"qteTarget":_rect_data(qte_target),"helpOpen":help_open,"pointerOwner":qte_pointer,"audioMode":"subtitle-only"}
	if model!=null:result.merge({"status":model.status,"playbackMode":model.playback_mode,"qte":model.qte_snapshot(),"qteCompleted":model.qte_completed.keys(),"qteResults":model.qte_results.duplicate(true)},true)
	return result

func _rect_data(rect:Rect2)->Dictionary:return {"x":rect.position.x,"y":rect.position.y,"width":rect.size.x,"height":rect.size.y}

func _count_bones(node:Node)->int:
	var count:int=1 if node is Bone2D else 0
	for child:Node in node.get_children():count+=_count_bones(child)
	return count

func _resolved_fans(pose:Dictionary)->Array:
	var fans:Array=pose.fans.duplicate(true)
	for fan:Dictionary in fans:
		var point:Vector2=fan.point
		var angle:=0.0
		var attachment:Dictionary=fan.get("attachment",{})
		match str(attachment.get("kind","fixed")):
			"socket":
				var rig:Node2D=actor_rigs[str(attachment.actor)]
				var socket:String=str(attachment.get("socket","FanSocket"))
				point=rig.attachment_local(socket).origin;angle=_fan_angle(rig,socket)
			"handoff":
				var from_rig:Node2D=actor_rigs[str(attachment.fromActor)];var to_rig:Node2D=actor_rigs[str(attachment.toActor)]
				var from_socket:String=str(attachment.fromSocket);var to_socket:String=str(attachment.toSocket)
				var transfer:float=clampf(float(attachment.amount),0,1)
				point=from_rig.attachment_local(from_socket).origin.lerp(to_rig.attachment_local(to_socket).origin,transfer)+Vector2(0,-float(attachment.get("arc",0))*sin(transfer*PI))
				angle=lerpf(_fan_angle(from_rig,from_socket),_fan_angle(to_rig,to_socket),transfer)
			"release":
				var launch:Dictionary=Model.pose_at(float(attachment.launchMs),bool(pose.reducedMotion))
				for actor:Dictionary in launch.actors:
					if actor.id!=attachment.actor:continue
					var socket:Vector2=ActorRig.sample_socket(int(actor.frame),int(actor.row),actor.foot,bool(actor.flip),float(attachment.launchMs),bool(pose.reducedMotion),str(attachment.socket))
					point+=(socket-Vector2(attachment.start))*(1.0-float(attachment.progress))
		var qte:Dictionary=pose.get("qte",{})
		if fan.kind=="fan" and qte.get("action","")=="butterfly" and qte.get("holding",false):fan.spread=clampi(roundi(float(qte.get("holdProgress",0))*3),0,3)
		fan.point=Model._point(point.x,point.y)
		fan["angle"]=angle
	return fans

func _fan_angle(rig:Node2D,socket:String)->float:
	var right:bool=socket!="LeftFanSocket"
	return -PI if bool(rig.flipped)==right else 0.0

func draw_stage(canvas:Node2D)->void:
	if model==null:return
	var pose:Dictionary=stage_pose if not stage_pose.is_empty() else model.snapshot()
	if textures.has("stage"):StagePlate.draw(canvas,textures.stage)
	else:_diagnostic_stage(canvas)
	var entries:Array=[]
	for actor:Dictionary in pose.actors:entries.append({"kind":"actor","foot":actor.foot,"value":actor})
	for prop:Dictionary in StagePlate.furniture_entries("performance",pose.get("stageProps",[])):entries.append({"kind":"prop","foot":prop.foot,"value":prop})
	entries.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return a.foot.y<b.foot.y)
	for entry:Dictionary in entries:
		if entry.kind=="actor":_actor(canvas,entry.value)
		else:StagePlate.draw_prop(canvas,textures,entry.value)
	for fan:Dictionary in _resolved_fans(pose):
		if fan.kind=="butterfly":_butterfly(canvas,fan)
		else:_fan(canvas,fan.point,int(fan.spread),int(fan.side),float(fan.angle))
	_draw_qte_hint(canvas,pose)
	_draw_curtain(canvas,float(pose.curtain))

func _draw_qte_hint(canvas:Node2D,pose:Dictionary)->void:
	var qte:Dictionary=pose.get("qte",{})
	if qte.is_empty() or help_open or model.status=="failure":return
	if qte.action=="turn":
		var rig:Node2D=actor_rigs[str(qte.targetAttachment.actor)]
		var foot:Vector2=rig.attachment_local("FootAnchor").origin+Vector2(0,2)
		var points:=PackedVector2Array([foot+Vector2(5,0),foot+Vector2(0,1.2),foot+Vector2(-7,1.6),foot+Vector2(-12,.2)])
		canvas.draw_polyline(points,Color("C77964"),.4,false)
		canvas.draw_line(foot+Vector2(-12,.2),foot+Vector2(-9.4,-1.4),PAPER,.2,false)
		canvas.draw_line(foot+Vector2(-12,.2),foot+Vector2(-9.4,2),PAPER,.2,false)
	else:
		for fan:Dictionary in _resolved_fans(pose):
			if fan.kind!="fan":continue
			var direction:=Vector2(cos(float(fan.angle)),sin(float(fan.angle)))
			var normal:=Vector2(-direction.y,direction.x)
			var p:Vector2=fan.point
			var ready:bool=qte.get("holding",false) and float(qte.get("holdProgress",0))>=1
			var distance:float=6.6 if ready else 6.2
			var edge:Vector2=_fine_point(p+direction*distance)
			canvas.draw_line(edge-normal*1.2,edge+normal*1.2,Color("F4CD77"),.2,false)
			if ready:
				canvas.draw_line(edge+normal*1.2,_fine_point(edge+direction*.6+normal*.6),PAPER,.2,false)
				canvas.draw_line(edge-normal*1.2,_fine_point(edge+direction*.6-normal*.6),PAPER,.2,false)

func _draw_curtain(canvas:Node2D,opening:float)->void:
	# At full opening the photographed/rebuilt stage owns its own curtain legs.
	# Moving front cloth uses one fine-pixel seams, never a coarse permanent frame.
	var columns:int=int(roundf(120.0*(1.0-clampf(opening,0,1))*5.0))
	if columns<=0:return
	var cloth:Array[Color]=[Color("6F483E"),Color("9A514A"),Color("A76A4C"),Color("C77964")]
	var ramp:Array[int]=[0,1,1,2,3,3,3,2,2,1,1,0]
	var travel:int=int(roundf(opening*600.0))
	for side in 2:
		var start:float=0.0 if side==0 else 240.0-columns*.2
		for column in columns:
			var thread:int=column+travel if side==0 else column-travel
			var fold:int=posmod(thread,12)
			var hem:float=116.0+snappedf(sin(float(thread)*.065)*.4,.2)
			var x:float=start+column*.2
			canvas.draw_rect(Rect2(x,0,.2,hem),cloth[ramp[fold]])
			# Sparse grouped stitches follow a material seam, without random noise.
			if posmod(thread,60)==5:
				for row in range(8,110,8):canvas.draw_rect(Rect2(x,row,.2,1.2),Color("A76A4C"))
		var edge:float=start+columns*.2-.4 if side==0 else start+.2
		canvas.draw_rect(Rect2(edge,0,.2,116),Color("D3A451"))
		canvas.draw_rect(Rect2(start,115.8,columns*.2,.2),Color("C79B62"))

func _diagnostic_stage(canvas:Node2D)->void:
	canvas.draw_rect(Rect2(0,0,240,135),INK)
	canvas.draw_rect(Rect2(15,30,210,92),Color("70503B"))
	for y in range(34,122,8):canvas.draw_rect(Rect2(15,y,210,1),Color("A1744E"))
	canvas.draw_rect(Rect2(15,122,210,5),Color("44332D"))

func _actor(canvas:Node2D,actor:Dictionary)->void:
	if float(actor.alpha)<=0:return
	var foot:Vector2=actor.foot
	if textures.has("actors"):
		# Atlas metadata anchors each complete 120×160 cel at (60,150).
		var anchor:Vector2=ActorRig.NATIVE_FOOT/ActorRig.PIXELS_PER_UNIT
		canvas.draw_set_transform(foot+Vector2(anchor.x if actor.flip else -anchor.x,-anchor.y),0,Vector2(-1 if actor.flip else 1,1))
		canvas.draw_texture_rect_region(textures.actors,Rect2(0,0,24,32),Rect2(int(actor.frame)*120,int(actor.row)*160,120,160),Color(1,1,1,float(actor.alpha)))
		canvas.draw_set_transform(Vector2.ZERO)
	else:
		# Untextured figures are an explicit diagnostic, never release fallback.
		canvas.draw_rect(Rect2(foot+Vector2(-5,-27),Vector2(10,8)),INK)
		canvas.draw_rect(Rect2(foot+Vector2(-6,-19),Vector2(12,15)),Color("385B79") if int(actor.row)==0 else Color("C77964"))
		canvas.draw_rect(Rect2(foot+Vector2(-5,-4),Vector2(4,4)),INK);canvas.draw_rect(Rect2(foot+Vector2(1,-4),Vector2(4,4)),INK)

func _fine_point(point:Vector2)->Vector2:return Model._point(point.x,point.y)

func _paper_polygon(canvas:Node2D,points:PackedVector2Array,color:Color)->void:
	var compact:=PackedVector2Array()
	for point:Vector2 in points:
		if compact.is_empty() or not compact[-1].is_equal_approx(point):compact.append(point)
	if compact.size()<3:return
	var area:=0.0
	for i in compact.size():area+=compact[i].cross(compact[(i+1)%compact.size()])
	if absf(area)>.001:canvas.draw_colored_polygon(compact,color)

func _fan(canvas:Node2D,point:Vector2,spread:int,side:int,angle:float)->void:
	var direction:=Vector2(cos(angle),sin(angle))
	var hinge:Vector2=_fine_point(point+direction*.6)
	var radius:=5.8
	var arc:float=lerpf(.12,PI,float(clampi(spread,0,3))/3.0)
	var edge:=PackedVector2Array()
	for step in 21:
		var theta:float=angle-arc/2.0+float(step)/20.0*arc
		edge.append(_fine_point(hinge+Vector2(cos(theta),sin(theta))*radius))
	for fold in 10:
		var a:Vector2=edge[fold*2];var mid:Vector2=edge[fold*2+1];var b:Vector2=edge[fold*2+2]
		_paper_polygon(canvas,PackedVector2Array([hinge,a,mid,b]),PAPER if fold%3!=1 else Color("D8C7A0"))
		# A short inner paper crease keeps each fold finer than the whole blade.
		canvas.draw_line(_fine_point(hinge.lerp(mid,.53)),_fine_point(hinge.lerp(mid,.82)),Color("E8E0C8"),.2,false)
	for rib in 11:canvas.draw_line(hinge,edge[rib*2],Color("70503B"),.2,false)
	for step in 20:
		canvas.draw_line(edge[step],edge[step+1],Color("C79B62"),.2,false)
		if step%2==0:canvas.draw_line(_fine_point(hinge.lerp(edge[step],.9)),_fine_point(hinge.lerp(edge[step+1],.9)),Color("D8C7A0"),.2,false)
	# The wrist is on the handle, rather than underneath an upturned paper blade.
	canvas.draw_line(_fine_point(point-direction*1.6),_fine_point(hinge+direction*.2),Color("44332D"),.4,false)
	var knot:Vector2=_fine_point(point-direction*1.2)
	canvas.draw_rect(Rect2(knot-Vector2(.2,.2),Vector2(.4,.4)),Color("385B79") if side==0 else Color("C77964"))

func _butterfly(canvas:Node2D,fan:Dictionary)->void:
	var p:Vector2=fan.point
	var width:int=[2,6,9,6][int(fan.flap)%4]
	for side in [-1,1]:
		# Two paper lobes retain the fan-wing span, with stepped curved edges.
		var lobes:Array=[
			{"tip":Vector2(side*width,-7),"control":Vector2(side*(width+1),-7),"end":Vector2(side*(width+1),-2)},
			{"tip":Vector2(side*(width+1),-2),"control":Vector2(side*maxi(2,width-2),9.4),"end":Vector2(side*2,2)}]
		for lobe_index in 2:
			var lobe:Dictionary=lobes[lobe_index]
			var root:Vector2=_fine_point(p+Vector2(side*.4,-.6 if lobe_index==0 else .6))
			var edge:=PackedVector2Array()
			for step in 13:
				var t:float=float(step)/12.0
				var curve:Vector2=(1-t)*(1-t)*lobe.tip+2*(1-t)*t*lobe.control+t*t*lobe.end
				edge.append(_fine_point(p+curve))
			var polygon:=PackedVector2Array([root]);polygon.append_array(edge)
			_paper_polygon(canvas,polygon,PAPER if lobe_index==0 else Color("D8C7A0"))
			for step in range(0,13,2):
				var tip:Vector2=edge[step]
				canvas.draw_line(root,tip,Color("A39B87"),.2,false)
				var branch:Vector2=_fine_point(root.lerp(tip,.72))
				if step<12:canvas.draw_line(branch,_fine_point(root.lerp(edge[step+1],.9)),Color("C79B62"),.2,false)
			for step in 12:canvas.draw_line(edge[step],edge[step+1],Color("C79B62"),.2,false)
			# Tiny colored knots recall the actors' fan ties; paper stays dominant.
			var fleck:Vector2=_fine_point(root.lerp(edge[7],.73))
			canvas.draw_rect(Rect2(fleck,Vector2(.4,.2)),Color("385B79") if int(fan.side)==0 else Color("C77964"))
	canvas.draw_rect(Rect2(p+Vector2(-.4,-3),Vector2(.8,7)),INK)
	canvas.draw_line(p+Vector2(-.2,-3),p+Vector2(-1.4,-5),INK,.2,false);canvas.draw_line(p+Vector2(.2,-3),p+Vector2(1.4,-5),INK,.2,false)
