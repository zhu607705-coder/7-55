extends RefCounted
## User-selected surface layouts, now using the project Morning Note family.
## Sizes are logical UI pixels; opacity applies to BACKGROUND ONLY.
## Never modulate the whole container: no-background roles retain full text alpha.
const SURFACES := ["hud", "interaction", "dialogue", "journal", "theater"]
const ROLES := ["heading", "body", "button", "tip"]
const Typography=preload("res://scripts/ui/native_typography.gd")
const PaperInk=preload("res://scripts/ui/paper_ink_material.gd")
const PAPER_SURFACES := ["hud", "dialogue", "journal"]

class ButtonTextShadow extends Label:
	# Button does not implement Label's shadow theme constants in Godot 4.6.
	# A behind-parent, input-transparent label renders only its shadow.
	func _process(_delta: float) -> void:
		var button := get_parent() as Button
		if button == null: return
		if text != button.text: text = button.text
		horizontal_alignment = button.alignment
		autowrap_mode = button.autowrap_mode
		clip_text = button.clip_text
		text_overrun_behavior = button.text_overrun_behavior
		self_modulate.a = 0.7 if button.disabled else 1.0


static func role(surface: String, text_role: String) -> Dictionary:
	assert(surface in SURFACES and text_role in ROLES, "Only explicitly selected UI roles are supported")
	var hud := surface == "hud"
	var on_paper := surface in PAPER_SURFACES
	return {
		"family": "morning_note",
		"size": 18 if text_role == "heading" else (11 if text_role == "tip" else (13 if hud and text_role == "body" else 14)),
		"weight": 500 if text_role == "heading" else 400,
		"color": ("#4a4038" if text_role == "tip" else "#1d1a1e") if on_paper else ("#cbd6bb" if text_role == "tip" else "#f1efdd"),
		"shadow": not on_paper, "outline": 0, "tracking": 0,
		"leading": 1.7 if hud and text_role == "body" else 1.6,
	}

static func panel(surface: String) -> Dictionary:
	assert(surface in SURFACES)
	return {"background": "paper" if surface in PAPER_SURFACES else "none", "spacing": 8, "opacity": 1.0 if surface in PAPER_SURFACES else 0.9, "corner": 2 if surface in PAPER_SURFACES else 6}

static func paper_style(padding: Vector2 = Vector2.ZERO) -> StyleBoxFlat:
	# Explicit margins preserve the caller's measured content and hit rectangles.
	var style := StyleBoxFlat.new()
	style.bg_color = PaperInk.PAPER
	style.set_border_width_all(0)
	style.set_corner_radius_all(2)
	style.content_margin_left = padding.x; style.content_margin_right = padding.x
	style.content_margin_top = padding.y; style.content_margin_bottom = padding.y
	return style

static func apply_paper_panel(control: Control, padding: Vector2 = Vector2.ZERO) -> void:
	control.add_theme_stylebox_override("panel",paper_style(padding))
	if bool(control.get_meta("paper_ink_edge_bound",false)): return
	control.set_meta("paper_ink_edge_bound",true)
	control.draw.connect(func(): PaperInk.draw_panel(control.get_canvas_item(),Rect2(Vector2.ZERO,control.size)))
	control.resized.connect(control.queue_redraw)

static func font(surface: String, text_role: String) -> Font:
	role(surface,text_role)
	return Typography.display_font() if text_role=="heading" else Typography.body_font()

static func size(surface: String, text_role: String) -> int:
	return int(role(surface, text_role).size)

static func color(surface: String, text_role: String) -> Color:
	return Color(role(surface, text_role).color)

static func line_height(surface: String, text_role: String) -> float:
	return float(size(surface, text_role)) * float(role(surface, text_role).leading)

static func apply_label(control: Control, surface: String, text_role: String) -> void:
	var face := font(surface, text_role)
	var px := size(surface, text_role)
	control.add_theme_font_override("font", face)
	control.add_theme_font_size_override("font_size", px)
	control.add_theme_color_override("font_color", color(surface, text_role))
	control.add_theme_constant_override("outline_size", 0)
	# Floating world prompts retain their readable shadow. Paper-supported copy
	# uses plain ink; never put a black halo behind the same dark letterforms.
	var shadow := bool(role(surface,text_role).shadow)
	control.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9 if shadow else 0.0))
	control.add_theme_constant_override("shadow_offset_x", 0)
	control.add_theme_constant_override("shadow_offset_y", 1)
	control.add_theme_constant_override("shadow_outline_size", 3 if shadow else 0)
	control.add_theme_constant_override("line_spacing", roundi(line_height(surface, text_role) - face.get_height(px)))
	control.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	preload("res://scripts/ui/native_ui_theme.gd").enable_scale_aware_text(control)

static func apply_button(button: Button, surface: String) -> void:
	apply_label(button, surface, "button")
	button.set_meta("tactile_paper_ink",true)
	for state: String in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	for state: String in ["font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, color(surface, "button"))
	button.add_theme_color_override("font_disabled_color", color(surface, "tip").darkened(0.3))
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color.TRANSPARENT
	focus.border_color = PaperInk.FOCUS
	focus.set_border_width_all(1)
	focus.set_corner_radius_all(2)
	button.add_theme_stylebox_override("focus", focus)
	var shadow := button.get_node_or_null("SelectedTextShadow") as Label
	if shadow == null:
		shadow = ButtonTextShadow.new()
		shadow.name = "SelectedTextShadow"
		shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		shadow.focus_mode = Control.FOCUS_NONE
		shadow.show_behind_parent = true
		shadow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		shadow.clip_text = true
		button.add_child(shadow)
		shadow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	apply_label(shadow, surface, "button")
	shadow.text = button.text
	shadow.horizontal_alignment = button.alignment
	shadow.autowrap_mode = button.autowrap_mode
	shadow.clip_text = button.clip_text
	shadow.text_overrun_behavior = button.text_overrun_behavior
	shadow.add_theme_color_override("font_color", Color.TRANSPARENT)
