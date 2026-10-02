extends RefCounted
## Presentation-only shared primitives. Authored app palettes, fonts, sizes and
## world art remain local. Source: base.css and ui-motion-typography-standard.md.
const FONT_MICRO := 9
const FONT_CAPTION := 11
const FONT_BODY := 13
const FONT_LABEL := 14
const FONT_TITLE := 18
const FONT_DISPLAY := 24
const INK := Color("222322")
const PAPER := Color("fff6df")
const PAPER_ALT := Color("fff0cc")
const FOCUS := Color("1d3f8f")
const EDGE := 2
const SPACE_SMALL := 8
const SPACE_MEDIUM := 12
const SPACE_LARGE := 16
const MIN_TARGET := 44.0

static func box(fill: Color, border: Color = Color.TRANSPARENT, width: int = 0, radius: int = 0, padding: Vector2 = Vector2.ZERO) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	# Explicit margins prevent border-dependent or inherited minimum-size jumps.
	style.content_margin_left = padding.x
	style.content_margin_right = padding.x
	style.content_margin_top = padding.y
	style.content_margin_bottom = padding.y
	return style

static func _luminance(color: Color) -> float:
	var linear := color.srgb_to_linear()
	return 0.2126*linear.r + 0.7152*linear.g + 0.0722*linear.b

static func _contrast(a: Color, b: Color) -> float:
	return (maxf(_luminance(a),_luminance(b))+0.05)/(minf(_luminance(a),_luminance(b))+0.05)

static func button_styles(fill: Color, ink: Color, border: Color, radius: int = 0, width: int = EDGE, padding: Vector2 = Vector2(12,8), focus: Color = FOCUS) -> Dictionary:
	# A variant owns every state. A dark app button must never inherit the
	# light shell's hover/pressed/disabled background or its corner radius.
	var hover_fill := fill.lerp(ink,0.06) if fill.a > 0.0 else Color(ink,0.06)
	var pressed_fill := fill.lerp(ink,0.12) if fill.a > 0.0 else Color(ink,0.12)
	var disabled_fill := fill.lerp(ink,0.06) if fill.a > 0.0 else fill
	var focus_ink := ink if fill.a > 0.0 and _contrast(focus,fill) < 3.0 else focus
	return {
		"normal": box(fill,border,width,radius,padding),
		"hover": box(hover_fill,border,width,radius,padding),
		"pressed": box(pressed_fill,border,width,radius,padding),
		"hover_pressed": box(pressed_fill,border,width,radius,padding),
		"disabled": box(disabled_fill,border,width,radius,padding),
		"focus": box(Color.TRANSPARENT,focus_ink,EDGE,radius),
	}

static func apply_button(button: Button, fill: Color = PAPER, ink: Color = INK, border: Color = INK, radius: int = 0, width: int = EDGE, font_size: int = FONT_LABEL, padding: Vector2 = Vector2(12,8), focus: Color = FOCUS) -> void:
	button.add_theme_font_size_override("font_size",font_size)
	for state: String in ["font_color","font_hover_color","font_pressed_color","font_hover_pressed_color","font_focus_color"]:
		button.add_theme_color_override(state,ink)
	button.add_theme_color_override("font_disabled_color",ink.lerp(fill,0.38) if fill.a > 0.0 else Color(ink,0.62))
	var styles := button_styles(fill,ink,border,radius,width,padding,focus)
	for state: String in styles:
		button.add_theme_stylebox_override(state,styles[state])
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	# Font family is inherited so the authored Library platform-font exception
	# survives. This helper does not resize controls or add interaction handlers.

static func apply_input(input: Control, fill: Color = Color("fffaf0"), ink: Color = INK, border: Color = INK, radius: int = 0, font_size: int = FONT_LABEL, padding: Vector2 = Vector2(10,6), focus: Color = FOCUS) -> void:
	input.add_theme_font_size_override("font_size",font_size)
	input.add_theme_color_override("font_color",ink)
	input.add_theme_color_override("font_placeholder_color",ink.lerp(fill,0.28))
	input.add_theme_color_override("font_uneditable_color",ink.lerp(fill,0.30))
	input.add_theme_color_override("font_readonly_color",ink.lerp(fill,0.30))
	input.add_theme_color_override("caret_color",ink)
	input.add_theme_color_override("selection_color",Color(focus,0.24))
	input.add_theme_color_override("font_selected_color",ink)
	input.add_theme_stylebox_override("normal",box(fill,border,EDGE,radius,padding))
	input.add_theme_stylebox_override("read_only",box(fill.lerp(ink,0.05),border,EDGE,radius,padding))
	input.add_theme_stylebox_override("focus",box(Color.TRANSPARENT,focus,EDGE,radius))

static func font_size_for_scale(logical_pixels: int, content_scale: float) -> int:
	# Round upward: the 14px label role becomes 13 authored pixels at 424/378,
	# or 14.58 logical phone pixels, with at least 12 physical pixels at 390x844.
	return maxi(1,ceili(float(logical_pixels)/maxf(content_scale,0.01)))

static func font_theme(font: Font, body_size: int = 16) -> Theme:
	# SubViewport boundaries do not inherit Control themes. Font-only scope
	# keeps world/game default sizes and their own presentation styles separate.
	var design := Theme.new()
	design.default_font = font
	design.default_font_size = body_size
	return design

static func make_theme(font: Font, body_size: int = FONT_BODY, button_size: int = FONT_LABEL) -> Theme:
	var design := Theme.new()
	design.default_font = font
	design.default_font_size = body_size
	design.set_color("font_color","Label",INK)
	for type: String in ["Button","OptionButton"]:
		design.set_font_size("font_size",type,button_size)
		for state: String in ["font_color","font_hover_color","font_pressed_color","font_hover_pressed_color","font_focus_color"]:
			design.set_color(state,type,INK)
		design.set_color("font_disabled_color",type,INK.lerp(PAPER,0.38))
		var styles := button_styles(PAPER,INK,INK)
		for state: String in styles: design.set_stylebox(state,type,styles[state])
	for type: String in ["LineEdit","TextEdit"]:
		design.set_font_size("font_size",type,button_size)
		design.set_color("font_color",type,INK)
		design.set_color("font_placeholder_color",type,Color("605b4e"))
		design.set_color("font_uneditable_color",type,Color("605b4e"))
		design.set_color("font_readonly_color",type,Color("605b4e"))
		design.set_color("caret_color",type,INK)
		design.set_color("selection_color",type,Color(FOCUS,0.24))
		design.set_color("font_selected_color",type,INK)
		design.set_stylebox("normal",type,box(Color("fffaf0"),INK,EDGE,0,Vector2(10,6)))
		design.set_stylebox("read_only",type,box(Color("eee8d9"),INK,EDGE,0,Vector2(10,6)))
		design.set_stylebox("focus",type,box(Color.TRANSPARENT,FOCUS,EDGE))
	for role: String in ["NativeCaption","NativeBody","NativeTitle","NativeDisplay"]:
		design.set_type_variation(role,"Label")
		design.set_font_size("font_size",role,{"NativeCaption":FONT_CAPTION,"NativeBody":FONT_BODY,"NativeTitle":FONT_TITLE,"NativeDisplay":FONT_DISPLAY}[role])
	return design
