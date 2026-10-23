extends RefCounted
## Morning Note: one project family, actual Regular/Medium pixel-contour faces.
## Source grids, coverage and derivative licenses are recorded with the fonts.
const BODY_PATH := "res://ui_assets/fonts/MorningNote-Regular.ttf"
const DISPLAY_PATH := "res://ui_assets/fonts/MorningNote-Medium.ttf"
const SYMBOL_PATH := "res://assets/rpg/fonts/fusion_pixel_12px_proportional_zh_hans.ttf"
static var _body: FontVariation
static var _display: FontVariation
static var _symbols: FontFile

static func _pixel_file(path: String) -> FontFile:
	var file: FontFile=load(path).duplicate()
	file.allow_system_fallback=false
	file.antialiasing=TextServer.FONT_ANTIALIASING_NONE
	file.hinting=TextServer.HINTING_NONE
	file.subpixel_positioning=TextServer.SUBPIXEL_POSITIONING_DISABLED
	file.multichannel_signed_distance_field=false
	return file

static func _symbol_fallback_font() -> Font:
	if _symbols == null:_symbols=_pixel_file(SYMBOL_PATH)
	return _symbols

static func body_font() -> FontVariation:
	if _body == null:
		_body = FontVariation.new()
		_body.base_font = _pixel_file(BODY_PATH)
		_body.fallbacks = [_symbol_fallback_font()]
		# Explicit bundled fonts only. The subset/fallback still cannot promise
		# every arbitrary user glyph; no hidden platform font dependency.
	return _body

static func display_font() -> FontVariation:
	if _display == null:
		_display=FontVariation.new()
		_display.base_font=_pixel_file(DISPLAY_PATH)
		_display.fallbacks=[_symbol_fallback_font()]
	return _display

static func apply_body(control: Control) -> void:
	control.add_theme_font_override("font",body_font())
	control.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	preload("res://scripts/ui/native_ui_theme.gd").enable_scale_aware_text(control)

static func apply_display(control: Control) -> void:
	control.add_theme_font_override("font",display_font())
	control.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	preload("res://scripts/ui/native_ui_theme.gd").enable_scale_aware_text(control)

static func apply_body_text_tree(node: Node) -> void:
	# Scope filtering to text controls, never the page or its pixel artwork.
	if node is Label or node is BaseButton or node is LineEdit or node is TextEdit:
		apply_body(node)
	for child: Node in node.get_children(): apply_body_text_tree(child)
