extends CanvasLayer
## One presentation-only pause surface. The activity remains the clock, audio,
## input-cancellation and progression authority; this view only asks to resume.
const NativeUi=preload("res://scripts/ui/native_ui_theme.gd")
const Typography=preload("res://scripts/ui/native_typography.gd")
var resume_button: Button
var surface: Control
var panel: Panel
var title: Label
var body: Label
var action_buttons:Array[Button]=[]
var _actions:Array[Dictionary]=[]
var _resume: Callable
var _owner: WeakRef
var _resume_keys: Dictionary={}
var _can_resume:=true
var _requested_active:=false
var _opened_order:=0
static var _next_order:=0
static var _environment_blocked:=false
const GROUP:="native_pause_surfaces"

static func mount(owner: Node,on_resume: Callable) -> CanvasLayer:
	var view=load("res://scripts/ui/native_pause_overlay.gd").new()
	view._resume=on_resume;view._owner=weakref(owner)
	owner.get_tree().root.add_child(view)
	owner.tree_exiting.connect(view._retire,CONNECT_ONE_SHOT)
	if owner is CanvasItem:owner.visibility_changed.connect(view._refresh_all)
	return view

func _ready() -> void:
	name="NativePauseOverlay";layer=120;process_mode=Node.PROCESS_MODE_ALWAYS;add_to_group(GROUP)
	surface=Control.new();surface.name="PauseSurface"
	surface.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	surface.mouse_filter=Control.MOUSE_FILTER_STOP;surface.set_meta("phone_ui_scope",true)
	surface.theme=NativeUi.make_theme(Typography.body_font(),16,16);add_child(surface)
	var backdrop:=ColorRect.new();backdrop.name="PauseBackdrop";backdrop.color=Color(0,0,0,.38)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);backdrop.mouse_filter=Control.MOUSE_FILTER_STOP;surface.add_child(backdrop)
	panel=Panel.new();panel.name="PausePanel";surface.add_child(panel)
	panel.add_theme_stylebox_override("panel",NativeUi.box(Color("e9e5da"),NativeUi.INK,2,0,Vector2(22,20)))
	title=Label.new();title.name="PauseTitle";title.text="已暂停"
	Typography.apply_body(title);title.add_theme_font_size_override("font_size",16)
	title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;title.mouse_filter=Control.MOUSE_FILTER_IGNORE;panel.add_child(title)
	body=Label.new();body.name="PauseExplanation";Typography.apply_body(body)
	body.add_theme_font_size_override("font_size",14);body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	body.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;body.mouse_filter=Control.MOUSE_FILTER_IGNORE;panel.add_child(body)
	resume_button=Button.new();resume_button.name="PauseContinue";resume_button.text="继续"
	resume_button.set_meta("phone_ui_scope",true);Typography.apply_body(resume_button)
	NativeUi.apply_button(resume_button,NativeUi.PAPER,NativeUi.INK,NativeUi.INK,0,2,16,Vector2(12,8))
	resume_button.custom_minimum_size=Vector2(0,48);resume_button.pressed.connect(_request_resume);panel.add_child(resume_button)
	get_viewport().size_changed.connect(_layout)
	surface.hide();_layout()

func _layout() -> void:
	if not is_instance_valid(surface) or not is_instance_valid(panel):return
	var extent:=get_viewport().get_visible_rect().size
	surface.position=Vector2.ZERO;surface.size=extent
	# Match the phone's 430px shell and 424/378 authored overlay scale in
	# portrait/desktop. Very short landscapes retain a legible common minimum.
	var fit:=minf((extent.x-24)/430.0,(extent.y-36)/860.0)*424.0/378.0
	var ui_scale:=maxf(.875,fit)
	ui_scale=minf(ui_scale,(extent.x-24)/378.0)
	var primary_height:=maxf(48,44/ui_scale)
	var action_height:=maxf(44,44/ui_scale)
	var action_top:=110+primary_height+12
	var content_bottom:=action_top+action_height if not action_buttons.is_empty() else 110+primary_height
	panel.size=Vector2(378,content_bottom+20);panel.scale=Vector2.ONE*ui_scale
	panel.position=(extent-panel.size*ui_scale)/2
	# Fixed role rectangles make the first visible frame and first pointer hit
	# agree; Container sorting must not move Continue after a pause arrives.
	title.position=Vector2(20,14);title.size=Vector2(338,27)
	body.position=Vector2(20,52);body.size=Vector2(338,42)
	resume_button.position=Vector2(20,110);resume_button.size=Vector2(338,primary_height)
	for index:int in action_buttons.size():
		var width:float=(338-10*(action_buttons.size()-1))/action_buttons.size()
		action_buttons[index].position=Vector2(20+index*(width+10),action_top)
		action_buttons[index].size=Vector2(width,action_height)
	for label:Label in [title,body]:label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER

func set_actions(actions: Array) -> void:
	# Optional actions are supplied by the original owner; this view never
	# invents restart/exit behavior or bypasses the owner's confirmations.
	_actions.clear()
	for action:Variant in actions:
		if action is Dictionary:_actions.append(action)
	while action_buttons.size()>actions.size():
		var removed:Button=action_buttons.pop_back();removed.queue_free()
	while action_buttons.size()<actions.size():
		var index:=action_buttons.size()
		var button:=Button.new();button.name="PauseAction%d"%index
		button.set_meta("phone_ui_scope",true);Typography.apply_body(button)
		NativeUi.apply_button(button,NativeUi.PAPER,NativeUi.INK,NativeUi.INK,0,2,16,Vector2(8,6))
		button.pressed.connect(func():_request_secondary(index));panel.add_child(button);action_buttons.append(button)
	for index:int in actions.size():
		action_buttons[index].text=str(actions[index].get("text",""))
		action_buttons[index].disabled=bool(actions[index].get("disabled",false)) or _environment_blocked
	_layout()

func _request_secondary(index: int) -> void:
	if not is_open() or _environment_blocked or get_tree().paused or index<0 or index>=_actions.size() or action_buttons[index].disabled:return
	var callback:Callable=_actions[index].get("callback",Callable())
	if callback.is_valid():callback.call()

static func set_environment_blocked(tree: SceneTree,blocked: bool) -> void:
	_environment_blocked=blocked
	for view:Node in tree.get_nodes_in_group(GROUP):view._refresh_all()

func _owner_available() -> bool:
	var owner:Node=_owner.get_ref() if _owner!=null else null
	return is_instance_valid(owner) and owner.is_inside_tree() and not owner.is_queued_for_deletion() and (not owner is CanvasItem or owner.is_visible_in_tree())

func _refresh_all() -> void:
	if not is_inside_tree():return
	var winner:Node
	var views:=get_tree().get_nodes_in_group(GROUP)
	for view:Node in views:
		if not view._requested_active or not view._owner_available():continue
		if winner==null:winner=view;continue
		var current_owner:Node=winner._owner.get_ref()
		var candidate_owner:Node=view._owner.get_ref()
		# Nested activity wins over its paused parent. Otherwise the most recent
		# live pause owns the only surface, never stacked dimmers/buttons.
		if current_owner.is_ancestor_of(candidate_owner) or (not candidate_owner.is_ancestor_of(current_owner) and view._opened_order>winner._opened_order):winner=view
	for view:Node in views:view._set_surface_visible(view==winner)

func _set_surface_visible(active: bool) -> void:
	if not is_instance_valid(surface):return
	var opening:=active and not surface.visible
	var was_blocked:=resume_button.disabled
	resume_button.disabled=not _can_resume or _environment_blocked
	for index:int in action_buttons.size():action_buttons[index].disabled=bool(_actions[index].get("disabled",false)) or _environment_blocked
	surface.visible=active
	if active:
		_layout()
		if not resume_button.disabled and not get_tree().paused and (opening or was_blocked):resume_button.grab_focus()

func is_requested_for(owner: Node) -> bool:
	var current:Node=_owner.get_ref() if _owner!=null else null
	return _requested_active and _owner_available() and (current==owner or owner.is_ancestor_of(current))

func is_open() -> bool:
	return is_instance_valid(surface) and surface.visible and _owner_available()

func present(active: bool,reason: String="manual",can_resume: bool=true) -> void:
	if not is_instance_valid(surface):return
	if active and not _requested_active:
		_next_order+=1;_opened_order=_next_order
	_requested_active=active;_can_resume=can_resume
	body.text="离开画面时已自动暂停。" if reason=="focus" else ""
	body.visible=reason=="focus"
	_refresh_all()

func _retire() -> void:
	_requested_active=false
	if is_instance_valid(surface):surface.hide()
	_refresh_all();queue_free()

func _request_resume() -> void:
	if not is_open() or not _can_resume or _environment_blocked or get_tree().paused or not _resume.is_valid():return
	_resume.call()

func _input(event: InputEvent) -> void:
	if not event is InputEventKey:return
	var code: int=event.physical_keycode if event.physical_keycode else event.keycode
	# The same key that resumes must not immediately skip a receipt, begin a
	# hold, dash, or leak to a parent. Consume its repeats and final key-up.
	if _resume_keys.has(code):
		if not event.pressed:_resume_keys.erase(code)
		get_viewport().set_input_as_handled();return
	# Higher-level Cloud/content leases own keyboard input while Tree is paused.
	# Do not consume their keys; only retire our already-consumed key-up above.
	if get_tree().paused or not is_open():return
	if code in [KEY_ENTER,KEY_KP_ENTER,KEY_SPACE,KEY_ESCAPE]:
		if event.pressed and not event.echo and _can_resume and not _environment_blocked:
			_resume_keys[code]=true
			var focused:Control=get_viewport().gui_get_focus_owner()
			var index:=action_buttons.find(focused)
			if code!=KEY_ESCAPE and index>=0:_request_secondary(index)
			else:_request_resume()
		get_viewport().set_input_as_handled()
	elif code==KEY_TAB:
		var controls:Array[Button]=[]
		for button:Button in [resume_button]+action_buttons:
			if not button.disabled:controls.append(button)
		if event.pressed and not controls.is_empty():
			var current:=controls.find(get_viewport().gui_get_focus_owner())
			controls[posmod(current+(-1 if event.shift_pressed else 1),controls.size())].grab_focus()
		get_viewport().set_input_as_handled()
