extends SceneTree
const Type=preload("res://scripts/ui/native_typography.gd")
const Specimen=preload("res://tests/ui_design_specimen.gd")
var checks:=0
var failures:=0
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error(message)
func inspect(node: Node, width: float) -> void:
	if node is Label or node is Button:
		check(node.get_theme_font("font")==Type.body_font(),"same UI font at every size and state")
		check(node.texture_filter==CanvasItem.TEXTURE_FILTER_LINEAR,"same text rasterization, no pixel-font branch")
		check(node.size.x<=width,"specimen text wraps inside page")
	for child in node.get_children(): inspect(child,width)
func run() -> void:
	check(Type.body_font()==Type.display_font(),"display/time/number/body role shares exact font resource")
	for ch in "校园调查时间按钮数字07:55Aa0123，。":
		check(Type.body_font().base_font.has_char(ch.unicode_at(0)),"main UI glyph belongs to Campus, not fallback: "+ch)
	for dimensions in [Vector2i(390,844),Vector2i(1440,900)]:
		root.size=dimensions
		var sample:=Specimen.new(); sample.size=Vector2(dimensions)
		root.add_child(sample)
		for i in 6: await process_frame
		inspect(sample,sample.size.x)
		for pixels in [15,18,28]:
			var label: Label=sample.find_child("TypeSample"+str(pixels),true,false)
			check(label.get_theme_font_size("font_size")==pixels,"specimen authored size preserved")
		sample.queue_free(); await process_frame
	print("UNIFIED_TYPOGRAPHY: %d checks; %d failures" % [checks,failures]); quit(1 if failures else 0)
