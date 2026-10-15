extends Control
## One global modal surface across both phone and RPG, matching LibraryStoryOverlay.
const OverflowText=preload("res://scripts/ui/overflow_text.gd")
var body_scroll:ScrollContainer
const Overlay=preload("res://scripts/ui/world_overlay_layout.gd")
signal advance
var text_scale:=1.0
var session: RefCounted
var panel: Panel
var speaker: Label
var body: Label
var prompt: Label
var last_sequence: String=""
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_STOP; focus_mode=Control.FOCUS_ALL
	panel=Panel.new(); panel.clip_contents=true; panel.mouse_filter=Control.MOUSE_FILTER_IGNORE; add_child(panel)
	var box:=StyleBoxFlat.new(); box.bg_color=Color("081419",0.97); box.border_color=Color("b6c9bb"); box.set_border_width_all(2); box.set_corner_radius_all(4)
	panel.add_theme_stylebox_override("panel",box)
	for field: String in ["speaker","body","prompt"]:
		var label:=Label.new(); label.mouse_filter=Control.MOUSE_FILTER_IGNORE
		label.add_theme_font_override("font",load("res://assets/rpg/fonts/fusion_pixel_12px_proportional_zh_hans.ttf"))
		panel.add_child(label); set(field,label)
	body_scroll=OverflowText.new();panel.add_child(body_scroll);body_scroll.setup(body)
	body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_color_override("font_color",Color("f4edd6"))
	prompt.add_theme_color_override("font_color",Color("9fafac")); prompt.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	visible=false
func tick() -> void:
	visible=session!=null
	if not visible: return
	var v: Dictionary=session.snapshot()
	speaker.text=str(v.speaker); body.text=str(v.text)
	prompt.text="点击 / 空格 / 回车确认" if v.requiresConfirmation else "点击 / 空格 / 回车继续"
	var region:=Rect2(16,64,size.x-32,maxf(1,size.y-80))
	var shell:Node=get_parent().get_parent() if get_parent()!=null else null
	var world:Variant=shell.get("world") if is_instance_valid(shell) else null
	if is_instance_valid(world) and not world.subtitle.is_empty() and shell.world_frame.is_visible_in_tree():
		# One minimum readable feedback row and the dialogue share this budget.
		# Otherwise a large dialogue can leave no space in which to stack HUD.
		var scale:float=world.hud_display_scale()
		var hud:=Overlay.hud(world.font,world.size,scale,world.subtitle,world.mobile_exploration,text_scale)
		var minimum_row:float=world.font.get_height(hud.body_font)+hud.body_inset*2
		var top:float=maxf(region.position.y,shell.world_view.get_global_rect().position.y+(hud.header_height+minimum_row+hud.body_gap*2)*scale)
		region=Rect2(region.position.x,top,region.size.x,maxf(1,region.end.y-top))
	var metrics:=Overlay.dialogue(body.get_theme_font("font"),region,1.0,speaker.text,body.text,prompt.text,text_scale)
	panel.position=metrics.panel.position; panel.size=metrics.panel.size
	if is_instance_valid(world) and shell.world_frame.is_visible_in_tree() and shell.size.y>shell.size.x:
		var below_film:float=shell.world_view.get_global_rect().end.y+8
		if below_film>=region.position.y and below_film+panel.size.y<=region.end.y:panel.position.y=below_film
	speaker.position=metrics.speaker.position; speaker.size=metrics.speaker.size
	speaker.add_theme_font_size_override("font_size",metrics.speaker_font)
	speaker.add_theme_color_override("font_color",Color("edc36c") if v.speaker=="旁白" else Color("c0d59d") if v.speaker=="玩家" else Color("8ed2e4"))
	body.add_theme_font_size_override("font_size",metrics.body_font); body_scroll.layout_body(metrics.body_viewport,metrics.body.size.y)
	prompt.position=metrics.prompt.position; prompt.size=metrics.prompt.size; prompt.add_theme_font_size_override("font_size",metrics.prompt_font)
	if last_sequence!=str(v.sequenceId): grab_focus(); last_sequence=str(v.sequenceId)
	queue_redraw()
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color(0,0,0,0.22))
func _input(event: InputEvent) -> void:
	if not visible or session==null: return
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
		if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed and event.device!=-1: advance.emit()
		elif event is InputEventScreenTouch and event.pressed: advance.emit()
	elif event is InputEventMouseMotion or event is InputEventScreenDrag:
		if body_scroll.get_v_scroll_bar().visible and body_scroll.get_global_rect().has_point(event.position):return
		get_viewport().set_input_as_handled()
