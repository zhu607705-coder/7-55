extends Control
## Selected HUD 2 / interaction 1. Screen-space presentation only.
## World motion, targets, camera and progression remain owned by world.gd.
const Selected = preload("res://scripts/ui/selected_ui_theme.gd")
class Scrim extends PanelContainer:
	func _draw()->void:
		# The selected scrim fades left-to-right, not an opaque paper card.
		for x:int in range(ceili(size.x)):
			var edge:float=minf(x,size.x-1-x)
			var cut:float=6-sqrt(maxf(0,36-pow(maxf(0,6-edge),2))) if edge<6 else 0
			var color:=Color("20352d");color.a=.9*maxf(0,1-float(x)/maxf(1,size.x))
			draw_line(Vector2(x+.5,cut),Vector2(x+.5,size.y-cut),color,1)

var task: PanelContainer
var task_scroll: ScrollContainer
var task_column: VBoxContainer
var clock: Label
var location: Label
var objective: Label
var task_tip: Label
var plaque: VBoxContainer
var object_heading: Label
var object_body: Label
var object_hint: Label
var mode: Label
var geometry: Dictionary = {}
var mobile_exploration:=false
var compact_header:HBoxContainer
var compact_clock:Label
var compact_location:Label
var _scroll_touch_id:=-1
var _scroll_touch_point:=Vector2.ZERO
var _scroll_emulation_until:=0
var _settle_queued:=false
var _task_height_budget:=32.0
var _plaque_bottom_limit:=0.0

func _init() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	z_index=85
	visibility_changed.connect(_clear_hidden_scroll_touch)
	task=Scrim.new();task.name="SelectedHud2";task.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(task)
	var material:=StyleBoxFlat.new()
	material.bg_color=Color.TRANSPARENT
	material.set_corner_radius_all(6);material.set_content_margin_all(8)
	task.add_theme_stylebox_override("panel",material)
	task_scroll=ScrollContainer.new();task_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	task_scroll.mouse_filter=Control.MOUSE_FILTER_IGNORE;task_scroll.mouse_force_pass_scroll_events=false;task.add_child(task_scroll)
	task_column=VBoxContainer.new();task_column.mouse_filter=Control.MOUSE_FILTER_IGNORE;task_column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	task_column.add_theme_constant_override("separation",8);task_scroll.add_child(task_column)
	compact_header=HBoxContainer.new();compact_header.add_theme_constant_override("separation",8);compact_header.mouse_filter=Control.MOUSE_FILTER_IGNORE;task_column.add_child(compact_header)
	compact_clock=_label(compact_header,"hud","heading")
	compact_location=_label(compact_header,"hud","tip")
	location=_label(task_column,"hud","tip")
	clock=_label(task_column,"hud","heading")
	objective=_label(task_column,"hud","body")
	task_tip=_label(task_column,"hud","tip");task_column.move_child(task_tip,3)
	plaque=VBoxContainer.new();plaque.name="SelectedInteraction1";plaque.mouse_filter=Control.MOUSE_FILTER_IGNORE
	plaque.add_theme_constant_override("separation",8);add_child(plaque)
	object_heading=_label(plaque,"interaction","heading")
	object_heading.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	object_body=_label(plaque,"interaction","body")
	object_body.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	object_hint=_label(plaque,"interaction","button")
	object_hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	mode=_label(self,"hud","button");mode.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	task_column.minimum_size_changed.connect(_schedule_settle)
	task_scroll.resized.connect(_schedule_settle)
	task_scroll.get_v_scroll_bar().changed.connect(_schedule_settle)
	plaque.minimum_size_changed.connect(_schedule_settle)

func _schedule_settle()->void:
	if _settle_queued or not is_inside_tree():return
	_settle_queued=true
	# Container signals may fire again during settlement. Never recursively
	# enqueue in the same idle flush: one-shot next-frame ownership bounds it.
	get_tree().process_frame.connect(_settle_layout,CONNECT_ONE_SHOT)

func _settle_layout()->void:
	_settle_queued=false
	if not is_inside_tree():return
	# Container minimum sizes settle after text/font/width changes. Do not
	# depend on Main's next process tick to release a stale input-blocking HUD.
	task.size.y=minf(_task_height_budget,maxf(32,task_column.get_combined_minimum_size().y+16))
	task_scroll.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var plaque_height:float=plaque.get_combined_minimum_size().y
	plaque.position.y=clampf(size.y*.5-plaque_height*.5,task.position.y+task.size.y+8,maxf(task.position.y+task.size.y+8,_plaque_bottom_limit-plaque_height-8))

func _clear_hidden_scroll_touch()->void:
	if is_visible_in_tree() or _scroll_touch_id<0:return
	var release:=InputEventMouseButton.new();release.position=_scroll_touch_point;release.global_position=_scroll_touch_point;release.button_index=MOUSE_BUTTON_LEFT;release.pressed=false
	_scroll_touch_id=-1
	if is_inside_tree():get_viewport().push_input(release,true)

func _input(event:InputEvent)->void:
	# Text is not a world interaction target. Only the native scrollbar owns
	# pointer drags; wheel inside overflowing text scrolls without world zoom.
	var scrollbar:=task_scroll.get_v_scroll_bar()
	# The project enables platform touch-to-mouse emulation. Our owned finger
	# already forwards one native drag, so discard its duplicate emulated events.
	if event is InputEventMouse and event.device==InputEvent.DEVICE_ID_EMULATION and Time.get_ticks_msec()<_scroll_emulation_until and (_scroll_touch_id>=0 or scrollbar.get_global_rect().has_point(event.position)):
		get_viewport().set_input_as_handled();return
	if not is_visible_in_tree():return
	# ScrollBar handles mouse drags natively, but not raw ScreenDrag events.
	# Translate only a touch that begins on its visible thumb/track; never
	# capture world touches that began on the transparent text column.
	if event is InputEventScreenTouch:
		if event.pressed and _scroll_touch_id<0 and scrollbar.visible and scrollbar.get_global_rect().has_point(event.position):_scroll_touch_id=event.index
		if event.index!=_scroll_touch_id:return
		_scroll_touch_point=event.position;_scroll_emulation_until=Time.get_ticks_msec()+100
		var mouse:=InputEventMouseButton.new();mouse.position=event.position;mouse.global_position=event.position;mouse.button_index=MOUSE_BUTTON_LEFT;mouse.pressed=event.pressed
		get_viewport().push_input(mouse,true)
		if not event.pressed:_scroll_touch_id=-1
		get_viewport().set_input_as_handled();return
	if event is InputEventScreenDrag and event.index==_scroll_touch_id:
		_scroll_touch_point=event.position;_scroll_emulation_until=Time.get_ticks_msec()+100
		var motion:=InputEventMouseMotion.new();motion.position=event.position;motion.global_position=event.position;motion.relative=event.relative;motion.button_mask=MOUSE_BUTTON_MASK_LEFT
		get_viewport().push_input(motion,true);get_viewport().set_input_as_handled();return
	if not event is InputEventMouseButton or not event.pressed:return
	if event.button_index not in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:return
	var bar:=task_scroll.get_v_scroll_bar()
	if bar.max_value<=bar.page+.5 or not task_scroll.get_global_rect().has_point(event.position):return
	task_scroll.scroll_vertical+=int((-1 if event.button_index==MOUSE_BUTTON_WHEEL_UP else 1)*maxf(1,event.factor)*32)
	get_viewport().set_input_as_handled()

func _label(parent:Node,surface:String,role:String)->Label:
	var label:=Label.new();label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	Selected.apply_label(label,surface,role);parent.add_child(label)
	return label

func sync_view(extent:Vector2,display_scale:float,title:String,goal:String,prompt:String,mode_text:String,mode_rect:Rect2,bottom:float,clock_text:String="",object_detail:String="")->void:
	var s:=maxf(.01,display_scale)
	scale=Vector2.ONE/s;size=extent*s
	location.text=title;clock.text=clock_text;clock.visible=not clock_text.is_empty();objective.text=goal;task_tip.text="当前任务"
	object_heading.text=prompt;object_body.text=object_detail;object_body.visible=not object_detail.is_empty() and object_detail!=prompt;object_hint.text="交互" if mobile_exploration else "空格 · 交互"
	mode.text=mode_text
	var compact:bool=size.y<450
	compact_header.visible=compact
	compact_clock.text=clock_text;compact_clock.visible=not clock_text.is_empty()
	compact_location.text=title
	location.visible=not compact;clock.visible=not compact and not clock_text.is_empty()
	var inset:=Vector2(size.x*.06,size.y*.06)
	# Same selected left-column composition, bounded scroll for long source goals.
	var width:=minf(300,maxf(1,size.x*.65))
	# A compact header must still leave a complete first objective line.
	# The previous percentage-only cap clipped that line on short landscapes.
	var first_line:float=Selected.font("hud","body").get_height(Selected.size("hud","body"))
	var header_height:float=compact_header.get_combined_minimum_size().y if compact else location.get_combined_minimum_size().y+clock.get_combined_minimum_size().y+8
	var first_goal_budget:float=16+header_height+task_tip.get_combined_minimum_size().y+16+first_line
	var available_height:=maxf(32,minf(maxf(size.y*.36,first_goal_budget),bottom*s-inset.y-8))
	_task_height_budget=available_height;_plaque_bottom_limit=bottom*s
	task.position=inset
	task.custom_minimum_size=Vector2.ZERO
	var minimum:=task_column.get_combined_minimum_size().y+16
	# Apply the final target once; expanding then shrinking every sync causes
	# container minimum/scrollbar feedback even when all inputs are unchanged.
	task.size=Vector2(width,minf(available_height,maxf(32,minimum)))
	# A passive readable HUD must not consume authored world floor taps.
	# Only the scrollbar owns pointer drags; labels/columns stay transparent.
	task_scroll.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var plaque_width:=minf(420,maxf(1,size.x*.76))
	plaque.size=Vector2(plaque_width,0)
	var plaque_height:=plaque.get_combined_minimum_size().y
	plaque.position=Vector2((size.x-plaque_width)/2,clampf(size.y*.5-plaque_height*.5,task.position.y+task.size.y+8,maxf(task.position.y+task.size.y+8,bottom*s-plaque_height-8)))
	plaque.visible=not prompt.is_empty()
	mode.position=mode_rect.position*s;mode.size=mode_rect.size*s
	_schedule_settle()
	geometry={"task":Rect2(task.position,task.size),"interaction":Rect2(plaque.position,Vector2(plaque_width,plaque_height)),"mode":Rect2(mode.position,mode.size),"extent":Rect2(Vector2.ZERO,size)}
