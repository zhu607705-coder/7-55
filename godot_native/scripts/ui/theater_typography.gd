extends RefCounted
## Theater shares Morning Note with the phone and HUD; stage layout stays local.
const Ui=preload("res://scripts/ui/native_ui_theme.gd")
const Typography=preload("res://scripts/ui/native_typography.gd")
const PAPER=Color("F4EAD5")
const INK=Color("202B35")
const EDGE=Color("A39B87")
const ACCENT=Color("9A514A")
static var regular: Font
static var semibold: Font

static func apply(control: Control) -> void:
	if regular==null:regular=Typography.body_font()
	if semibold==null:semibold=Typography.display_font()
	var design:=Theme.new();design.default_font=regular;design.default_font_size=18
	design.set_font("font","Button",semibold)
	design.set_font("normal_font","RichTextLabel",regular)
	design.set_font("bold_font","RichTextLabel",semibold)
	design.set_constant("line_spacing","Label",4)
	design.set_constant("line_separation","RichTextLabel",6)
	design.set_constant("outline_size","Label",0)
	control.theme=design;Ui.enable_scale_aware_text(control)

static func heading(label: Label) -> void:
	label.add_theme_font_override("font",semibold)
	label.add_theme_constant_override("outline_size",0)
	text(label)

static func text(control: Control) -> void:
	control.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	Ui.enable_scale_aware_text(control)

static func button(control: Button,primary: bool=false) -> void:
	Ui.apply_button(control,ACCENT if primary else PAPER,PAPER if primary else INK,ACCENT if primary else EDGE,2,1,16,Vector2(14,8),Color("C79B62"))
	text(control)
