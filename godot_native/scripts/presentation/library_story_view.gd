extends Control
## One story reader with the layout of the active phone or world surface.
const Typography=preload("res://scripts/ui/native_typography.gd")
const Notice=preload("res://scripts/ui/native_phone_notice.gd")
const Ui=preload("res://scripts/ui/native_ui_theme.gd")
const DialogueLayout=preload("res://scripts/ui/selected_dialogue_layout.gd")
const OverflowText=preload("res://scripts/ui/overflow_text.gd")
const Overlay=preload("res://scripts/ui/world_overlay_layout.gd")
const PHONE_BODY_PX=18
signal advance
var text_scale:=1.0
var session: RefCounted
var panel: Panel
var speaker: Label
var body: Label
var body_scroll: ScrollContainer
var prompt: Label
var last_sequence: String=""
var on_phone := false
var phone_card := Ui.box(Color.WHITE,Color("8297a4"),1,4)
var world_card := Notice.card_style()
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_STOP; focus_mode=Control.FOCUS_ALL
	panel=Panel.new(); panel.clip_contents=true; panel.mouse_filter=Control.MOUSE_FILTER_IGNORE; add_child(panel)
	panel.add_theme_stylebox_override("panel",world_card)
	for field: String in ["speaker","body","prompt"]:
		var label:=Label.new(); label.mouse_filter=Control.MOUSE_FILTER_IGNORE;label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		Typography.apply_body(label)
		panel.add_child(label); set(field,label)
	body_scroll=OverflowText.new();panel.add_child(body_scroll);body_scroll.setup(body)
	prompt.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	visible=false
func tick() -> void:
	visible=session!=null
	if not visible: return
	var v: Dictionary=session.snapshot()
	speaker.text=str(v.speaker); body.text=str(v.text)
	var region:=Rect2(16,64,size.x-32,maxf(1,size.y-80))
	var shell:Node=get_parent().get_parent() if get_parent()!=null else null
	var world:Variant=shell.get("world") if is_instance_valid(shell) else null
	var on_map:bool=is_instance_valid(world) and shell.world_frame.is_visible_in_tree()
	var phone_visible:bool=is_instance_valid(world) and shell.phone_scroll.is_visible_in_tree()
	if on_phone!=phone_visible:
		on_phone=phone_visible
		panel.add_theme_stylebox_override("panel",phone_card if on_phone else world_card)
		var wrap_mode:=TextServer.AUTOWRAP_OFF if on_phone else TextServer.AUTOWRAP_WORD_SMART
		speaker.autowrap_mode=wrap_mode
		prompt.autowrap_mode=wrap_mode
	var ui_scale:=Overlay.ui_scale(size)
	var min_body_px:=Overlay.BODY_PX if on_map else 0
	var portrait := size.x < size.y
	if on_phone:
		ui_scale=shell.phone.scale.x
		min_body_px=PHONE_BODY_PX
		region=get_global_transform().affine_inverse() * shell.phone_scroll.get_global_rect()
		var inset:=Vector2(12,8)*ui_scale
		region=Rect2(region.position+inset,region.size-2*inset)
		prompt.text="点击确认" if v.requiresConfirmation else "点击继续"
	else:
		prompt.text="点击 / 空格 / 回车确认" if v.requiresConfirmation else "点击 / 空格 / 回车继续"
	if on_map:
		var safe_top := region.position.y
		var view_rect: Rect2 = get_global_transform().affine_inverse() * shell.world_view.get_global_rect()
		ui_scale=Overlay.ui_scale(view_rect.size)
		region = view_rect.grow(-8*ui_scale)
		var bottom:float=region.end.y
		for control: Control in [shell.inventory_handle, shell.inventory_dock, shell.world_tasks]:
			if not control.is_visible_in_tree(): continue
			var control_rect: Rect2 = get_global_transform().affine_inverse() * control.get_global_rect()
			if control_rect.intersects(view_rect): bottom = minf(bottom, control_rect.position.y - 8*ui_scale)
		# A portrait letterbox can be shorter than a readable dialogue. Keep
		# its horizontal center and use the blank space above for long lines.
		if portrait: region.position.y = minf(region.position.y, safe_top)
		region.size.y=maxf(1,bottom-region.position.y)
	if on_map and not portrait and not world.subtitle.is_empty():
		# One minimum readable feedback row and the dialogue share this budget.
		# Otherwise a large dialogue can leave no space in which to stack HUD.
		var scale:float=world.hud_display_scale()
		var hud:=Overlay.hud(world.hud_font,world.size,scale,world.subtitle,world.mobile_exploration,text_scale)
		var minimum_row:float=world.hud_font.get_height(hud.body_font)+hud.body_inset*2
		var top:float=maxf(region.position.y,shell.world_view.get_global_rect().position.y+(hud.header_height+minimum_row+hud.body_gap*2)*scale)
		region=Rect2(region.position.x,top,region.size.x,maxf(1,region.end.y-top))
	var metrics:=DialogueLayout.metrics(region,1.0,speaker.text,body.text,prompt.text,text_scale,min_body_px,ui_scale)
	panel.position=metrics.panel.position; panel.size=metrics.panel.size
	DialogueLayout.apply_role(speaker,"heading",metrics.speaker_font)
	DialogueLayout.apply_role(body,"body",metrics.body_font)
	DialogueLayout.apply_role(prompt,"tip",metrics.prompt_font)
	if on_phone:
		speaker.add_theme_color_override("font_color",Color("234e62"))
		prompt.add_theme_color_override("font_color",Color("475a66"))
	speaker.position=metrics.speaker.position; speaker.size=metrics.speaker.size
	body_scroll.layout_body(metrics.body_viewport,metrics.body.size.y)
	prompt.position=metrics.prompt.position; prompt.size=metrics.prompt.size
	if last_sequence!=str(v.sequenceId): grab_focus(); last_sequence=str(v.sequenceId)
	queue_redraw()
func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or session==null: return
	if event is InputEventKey:
		get_viewport().set_input_as_handled()
		if event.pressed and not event.echo:
			if event.keycode==KEY_TAB: grab_focus()
			elif event.keycode in [KEY_SPACE,KEY_ENTER,KEY_KP_ENTER]: advance.emit()
	elif event is InputEventMouseButton or event is InputEventScreenTouch:
		if body_scroll.get_v_scroll_bar().visible and body_scroll.get_global_rect().has_point(event.position):return
		# Capture globally so underlying buttons, item drags and world movement
		# cannot act even on the same pointer event that closes the last line.
		get_viewport().set_input_as_handled()
		if on_phone and not panel.get_global_rect().has_point(event.position): return
		if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed and event.device!=-1: advance.emit()
		elif event is InputEventScreenTouch and event.pressed: advance.emit()
	elif event is InputEventMouseMotion or event is InputEventScreenDrag:
		if body_scroll.get_v_scroll_bar().visible and body_scroll.get_global_rect().has_point(event.position):return
		get_viewport().set_input_as_handled()
