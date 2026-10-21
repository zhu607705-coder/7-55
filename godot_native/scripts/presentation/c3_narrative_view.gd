extends Control
## Non-modal source subtitles: dialogue locks interaction, never ordinary walking.
const Ui=preload("res://scripts/ui/native_ui_theme.gd")
const Typography=preload("res://scripts/ui/native_typography.gd")
const UiMaterial=preload("res://scripts/ui/campus_ui_material.gd")
class DialoguePaper extends Panel:
	var accent:=Color("263c49")
	var rule:=Rect2()
	var status_rect:=Rect2()
	var show_status:=false
	var paused:=false
	var pixel:=1.0
	func _draw()->void:
		if rule.has_area():
			draw_rect(rule,Color("d8cfc0"))
			draw_rect(Rect2(rule.position,Vector2(minf(24*pixel,rule.size.x),rule.size.y)),accent)
		if not show_status:return
		# Timed dialogue is not a Continue button. Reflect only the session's
		# existing paused flag; no clock, text reveal, or input authority here.
		if paused:
			draw_rect(Rect2(status_rect.position,Vector2(2*pixel,status_rect.size.y)),accent)
			draw_rect(Rect2(status_rect.position+Vector2(4*pixel,0),Vector2(2*pixel,status_rect.size.y)),accent)
		else:
			draw_rect(Rect2(status_rect.position+Vector2(0,2*pixel),Vector2(6*pixel,2*pixel)),accent)

const OverflowText=preload("res://scripts/ui/overflow_text.gd")
var body_scroll:ScrollContainer
const Overlay=preload("res://scripts/ui/world_overlay_layout.gd")
var text_scale:=1.0
var screen_rect:=Rect2()
var align_left:=false
var surface_visible:=true
var session: RefCounted
var panel: Panel
var speaker: Label
var body: Label
# Scale of the containing RPG surface in the real window, not world camera zoom.
var display_scale: float=1.0
# Physical-pixel exploration region above the actual movement controls.
var exploration_rect:=Rect2()
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	panel=DialoguePaper.new(); panel.clip_contents=true; panel.mouse_filter=Control.MOUSE_FILTER_IGNORE; add_child(panel)
	var box:=UiMaterial.panel_style("paper",{"paper":Ui.PAPER},Vector2.ZERO)
	panel.add_theme_stylebox_override("panel",box)
	for field: String in ["speaker","body"]:
		var label:=Label.new(); label.mouse_filter=Control.MOUSE_FILTER_IGNORE
		Typography.apply_body(label)
		panel.add_child(label); set(field,label)
	body_scroll=OverflowText.new();panel.add_child(body_scroll);body_scroll.setup(body)
	body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; body.add_theme_color_override("font_color",UiMaterial.INK)
	visible=false
func tick() -> void:
	if not is_instance_valid(panel): return
	var v: Dictionary=session.snapshot() if session!=null else {}
	visible=not str(v.get("rawText","")).is_empty()
	if not visible: return
	visible=visible and surface_visible
	if not visible:return
	var physical_scale:=display_scale
	var region:=exploration_rect
	if screen_rect.has_area():
		region=screen_rect; physical_scale=1.0
	elif not region.has_area():
		var margin:=Overlay.pixels(8,display_scale)
		region=Rect2(margin,margin,size.x-margin*2,size.y-margin*2)
	# A camera-owned room keeps its right-hand exit lane unobscured even
	# when a medium desktop is too narrow to supply a separate letterbox.
	if align_left and not screen_rect.has_area():region.size.x*=.65
	var metrics:=Overlay.dialogue(body.get_theme_font("font"),region,physical_scale,str(v.speaker),str(v.text),"",text_scale)
	panel.position=metrics.panel.position; panel.size=metrics.panel.size
	if screen_rect.has_area():panel.position.y=screen_rect.position.y
	elif align_left:panel.position.x=region.position.x
	speaker.text=str(v.speaker); speaker.add_theme_font_size_override("font_size",metrics.speaker_font)
	speaker.position=metrics.speaker.position; speaker.size=metrics.speaker.size
	var role_color:Color=Color("924a3b") if v.speaker in ["玩家","我"] else Color("6f503d") if v.speaker=="旁白" else UiMaterial.NAVY
	speaker.add_theme_color_override("font_color",role_color)
	panel.accent=role_color
	panel.pixel=Overlay.pixels(1,physical_scale)
	panel.rule=Rect2(Vector2(metrics.speaker.position.x,metrics.body_viewport.position.y-panel.pixel*2),Vector2(metrics.body_viewport.size.x,panel.pixel)) if not speaker.text.is_empty() else Rect2()
	panel.paused=bool(v.get("paused",false))
	var status_width:float=Overlay.pixels(6,physical_scale)
	panel.status_rect=Rect2(metrics.speaker.end.x-status_width,metrics.speaker.position.y+Overlay.pixels(4,physical_scale),status_width,Overlay.pixels(6,physical_scale))
	var speaker_width:float=speaker.get_theme_font("font").get_string_size(speaker.text,HORIZONTAL_ALIGNMENT_LEFT,-1,metrics.speaker_font).x
	panel.show_status=not speaker.text.is_empty() and v.has("paused") and speaker_width+Overlay.pixels(20,physical_scale)<metrics.speaker.size.x
	panel.queue_redraw()
	body.text=str(v.text); body.add_theme_font_size_override("font_size",metrics.body_font)
	body_scroll.layout_body(metrics.body_viewport,metrics.body.size.y)

func _input(event: InputEvent) -> void:
	if session==null or not is_visible_in_tree(): return
	# Phaser dialogueLocked ignores Space/Tab interactions but intentionally
	# does not suppress movement, camera panning, or source subtitle timers.
	if event is InputEventKey and event.keycode in [KEY_SPACE,KEY_ENTER,KEY_KP_ENTER,KEY_TAB]: get_viewport().set_input_as_handled()
