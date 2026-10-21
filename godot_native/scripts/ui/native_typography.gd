extends RefCounted
## Two explicit roles; never changes world textures or progression state.
const BODY_PATH := "res://ui_assets/fonts/CampusUISans-Regular.otf"
const DISPLAY_PATH := "res://assets/rpg/fonts/fusion_pixel_12px_proportional_zh_hans.ttf"
static var _body: FontVariation
static var _display: Font

static func display_font() -> Font:
	if _display == null:
		var pixel: FontFile = load(DISPLAY_PATH).duplicate()
		pixel.allow_system_fallback = false
		_display = pixel
	return _display

static func body_font() -> FontVariation:
	if _body == null:
		_body = FontVariation.new()
		var regular: FontFile = load(BODY_PATH).duplicate()
		regular.allow_system_fallback = false
		_body.base_font = regular
		_body.fallbacks = [display_font()]
		# Explicit bundled fonts only. The subset/fallback still cannot promise
		# every arbitrary user glyph; no hidden platform font dependency.
	return _body

static func apply_body(control: Control) -> void:
	control.add_theme_font_override("font",body_font())
	control.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

static func apply_display(control: Control) -> void:
	control.add_theme_font_override("font",display_font())
	control.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

static func apply_body_text_tree(node: Node) -> void:
	# Scope filtering to text controls, never the page or its pixel artwork.
	if node is Label or node is BaseButton or node is LineEdit or node is TextEdit:
		apply_body(node)
	for child: Node in node.get_children(): apply_body_text_tree(child)
