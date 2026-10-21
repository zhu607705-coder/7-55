extends RefCounted
## Presentation-only hardware language. Geometry, gestures and permissions belong
## to the caller; this helper never connects input or writes gameplay state.
const INK := Color("233746")
const PAPER := Color("f5efdf")
const EDGE := Color("a99b80")
const CORAL := Color("bd6554")
const TRAY := Color("253b48")

class HardwareDetail extends Control:
	var selected := false
	var grip := false
	var ink := Color("b9ac8d")
	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		focus_mode = Control.FOCUS_NONE
	func _draw() -> void:
		var face: Rect2=get_parent().get_meta("painted_rect",Rect2(Vector2.ZERO,size))
		draw_set_transform(face.position)
		var extent: Vector2=face.size
		if selected:
			draw_rect(Rect2(3,3,3,maxf(0,extent.y-6)),Color("bd6554"))
			draw_line(Vector2(3,3),Vector2(12,3),Color("bd6554"),2)
		elif grip:
			for y: int in [3,6]:
				draw_line(Vector2(extent.x/2-6,y),Vector2(extent.x/2+6,y),ink,1)
		else:
			draw_line(Vector2(4,extent.y-3),Vector2(minf(14,extent.x-4),extent.y-3),Color(ink,.65),1)

static func style(fill: Color, border: Color = EDGE, width: int = 1) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(width)
	box.set_corner_radius_all(1)
	box.content_margin_left=0;box.content_margin_right=0
	box.content_margin_top=0;box.content_margin_bottom=0
	return box

static func apply_states(button: Button, normal: StyleBoxFlat, hover: StyleBoxFlat) -> void:
	button.add_theme_stylebox_override("normal",normal)
	button.add_theme_stylebox_override("hover",hover)
	var pressed: StyleBoxFlat=hover.duplicate()
	pressed.bg_color=hover.bg_color.lerp(INK,.12)
	pressed.border_color=CORAL
	pressed.shadow_offset=Vector2.ZERO
	button.add_theme_stylebox_override("pressed",pressed)
	button.add_theme_stylebox_override("hover_pressed",pressed)
	var disabled: StyleBoxFlat=normal.duplicate()
	disabled.bg_color=normal.bg_color.lerp(Color("7d8585"),.3)
	disabled.border_color=normal.border_color.lerp(disabled.bg_color,.5)
	button.add_theme_stylebox_override("disabled",disabled)
	# Contrast on both light paper and navy hardware, independent of hover.
	var focus: StyleBoxFlat=style(Color.TRANSPARENT,Color("e5ad7c") if normal.bg_color.get_luminance()<.35 else INK,2)
	button.add_theme_stylebox_override("focus",focus)
	button.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND

static func detail(parent: Control, grip: bool=false) -> Control:
	var ornament:=HardwareDetail.new()
	ornament.name="HardwareDetail"
	ornament.grip=grip
	ornament.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(ornament)
	parent.resized.connect(ornament.queue_redraw)
	return ornament

static func set_selected(control: Control, selected: bool) -> void:
	var ornament=control.get_node_or_null("HardwareDetail")
	if ornament==null: ornament=detail(control)
	ornament.selected=selected
	ornament.queue_redraw()
