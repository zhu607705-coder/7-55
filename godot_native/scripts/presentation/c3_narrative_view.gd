extends Control
## Non-modal source subtitles: dialogue locks interaction, never ordinary walking.
var session: RefCounted
var panel: Panel
var speaker: Label
var body: Label
# Scale of the containing RPG surface in the real window, not world camera zoom.
var display_scale: float=1.0
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	panel=Panel.new(); panel.mouse_filter=Control.MOUSE_FILTER_IGNORE; add_child(panel)
	var box:=StyleBoxFlat.new(); box.bg_color=Color("101f29",.95); box.border_color=Color("86b6c4",.8); box.set_border_width_all(2); box.set_corner_radius_all(3)
	panel.add_theme_stylebox_override("panel",box)
	for field: String in ["speaker","body"]:
		var label:=Label.new(); label.mouse_filter=Control.MOUSE_FILTER_IGNORE
		label.add_theme_font_override("font",load("res://assets/rpg/fonts/fusion_pixel_12px_proportional_zh_hans.ttf"))
		panel.add_child(label); set(field,label)
	body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; body.add_theme_color_override("font_color",Color("f7f1dc"))
	visible=false
func tick() -> void:
	if not is_instance_valid(panel): return
	var v: Dictionary=session.snapshot() if session!=null else {}
	visible=not str(v.get("rawText","")).is_empty()
	if not visible: return
	# Preserve the established desktop layout. Only compressed world surfaces
	# need physical-size compensation; camera zoom never changes text sizing.
	if size.x*display_scale>=620:
		var desktop_w: float=minf(920,size.x-32)
		panel.position=Vector2((size.x-desktop_w)/2,maxf(0,size.y-166)); panel.size=Vector2(desktop_w,136)
		speaker.text=str(v.speaker); speaker.position=Vector2(18,12); speaker.size=Vector2(desktop_w-36,26)
		speaker.add_theme_font_size_override("font_size",20)
		speaker.add_theme_color_override("font_color",Color("c0d59d") if v.speaker=="玩家" else Color("8ed2e4"))
		body.text=str(v.text); body.position=Vector2(18,44 if not speaker.text.is_empty() else 18); body.size=Vector2(desktop_w-36,136-body.position.y-12)
		body.add_theme_font_size_override("font_size",22)
		return
	var physical_scale: float=clampf(display_scale,.15,1.0)
	var body_font: int=maxi(22,int(ceil(15.0/physical_scale)))
	var speaker_font: int=maxi(20,int(ceil(13.0/physical_scale)))
	var padding: float=maxf(18,ceil(7.0/physical_scale))
	var gap: float=maxf(6,ceil(3.0/physical_scale))
	var w: float=minf(920,size.x-32)
	speaker.text=str(v.speaker); body.text=str(v.text)
	speaker.add_theme_font_size_override("font_size",speaker_font)
	speaker.add_theme_color_override("font_color",Color("c0d59d") if v.speaker=="玩家" else Color("8ed2e4"))
	body.add_theme_font_size_override("font_size",body_font)
	var font: Font=body.get_theme_font("font")
	var speaker_h: float=ceil(font.get_height(speaker_font)) if not speaker.text.is_empty() else 0
	var body_h: float=ceil(font.get_multiline_string_size(body.text,HORIZONTAL_ALIGNMENT_LEFT,w-padding*2,body_font).y)
	var body_y: float=padding+speaker_h+(gap if speaker_h>0 else 0)
	var h: float=minf(size.y-52,maxf(136,body_y+body_h+padding))
	panel.position=Vector2((size.x-w)/2,maxf(0,size.y-h-30)); panel.size=Vector2(w,h)
	speaker.position=Vector2(padding,padding); speaker.size=Vector2(w-padding*2,speaker_h)
	body.position=Vector2(padding,body_y); body.size=Vector2(w-padding*2,maxf(0,h-body_y-padding))

func _input(event: InputEvent) -> void:
	if session==null: return
	# Phaser dialogueLocked ignores Space/Tab interactions but intentionally
	# does not suppress movement, camera panning, or source subtitle timers.
	if event is InputEventKey and event.keycode in [KEY_SPACE,KEY_ENTER,KEY_KP_ENTER,KEY_TAB]: get_viewport().set_input_as_handled()
