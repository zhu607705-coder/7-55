extends Control
## Non-modal source subtitles: dialogue locks interaction, never ordinary walking.
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
	panel=Panel.new(); panel.clip_contents=true; panel.mouse_filter=Control.MOUSE_FILTER_IGNORE; add_child(panel)
	var box:=StyleBoxFlat.new(); box.bg_color=Color("101f29",.95); box.border_color=Color("86b6c4",.8); box.set_border_width_all(2); box.set_corner_radius_all(3)
	panel.add_theme_stylebox_override("panel",box)
	for field: String in ["speaker","body"]:
		var label:=Label.new(); label.mouse_filter=Control.MOUSE_FILTER_IGNORE
		label.add_theme_font_override("font",load("res://assets/rpg/fonts/fusion_pixel_12px_proportional_zh_hans.ttf"))
		panel.add_child(label); set(field,label)
	body_scroll=OverflowText.new();panel.add_child(body_scroll);body_scroll.setup(body)
	body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; body.add_theme_color_override("font_color",Color("f7f1dc"))
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
	speaker.add_theme_color_override("font_color",Color("c0d59d") if v.speaker=="玩家" else Color("8ed2e4"))
	body.text=str(v.text); body.add_theme_font_size_override("font_size",metrics.body_font)
	body_scroll.layout_body(metrics.body_viewport,metrics.body.size.y)

func _input(event: InputEvent) -> void:
	if session==null or not is_visible_in_tree(): return
	# Phaser dialogueLocked ignores Space/Tab interactions but intentionally
	# does not suppress movement, camera panning, or source subtitle timers.
	if event is InputEventKey and event.keycode in [KEY_SPACE,KEY_ENTER,KEY_KP_ENTER,KEY_TAB]: get_viewport().set_input_as_handled()
