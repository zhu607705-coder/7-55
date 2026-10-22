extends RefCounted
## Font-independent interface marks. Keep the source text for accessibility;
## only the decorative rendering is replaced. No system-font dependency.
const PATTERNS := {
	"⌂": ["....#....","...###...","..##.##..",".##...##.","##.....##",".#.....#.",".#.###.#.",".#.#.#.#.",".###.###."],
	"✦": ["....#....","....#....","...###...","..#####..","#########","..#####..","...###...","....#....","....#...."],
	"✱": ["....##....",".#..##..#.",".##.##.##.","..######..","##########","##########","..######..",".##.##.##.",".#..##..#.","....##...."],
	"≋": [".........",".##..##..","#..##..#.",".........",".##..##..","#..##..#.",".........",".##..##..","#..##..#."],
	"⟳": ["..####...",".##..##.#","##....###","#....####","#........","#.......#","##.....##",".##...##.","..#####.."],
	"❚❚": [".###.###.",".###.###.",".###.###.",".###.###.",".###.###.",".###.###.",".###.###.",".###.###.",".###.###."],
	"⌫": ["...######","..#.....#",".#.#..#.#","#...##..#",".#.#..#.#","..#.....#","...######"],
	"⬢": ["..#####..",".#######.","#########","#########","#########",".#######.","..#####.."]
}
class SymbolMark extends Control:
	var rows: Array=[]
	var ink := Color.WHITE
	var extent := 20.0
	func _init() -> void:
		mouse_filter=Control.MOUSE_FILTER_IGNORE
		focus_mode=Control.FOCUS_NONE
		texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	func _draw() -> void:
		if rows.is_empty(): return
		var factor := minf(minf(size.x,size.y),extent)/maxf(str(rows[0]).length(),rows.size())
		var origin := (size-Vector2(str(rows[0]).length(),rows.size())*factor)/2
		var color := ink
		if get_parent() is BaseButton and get_parent().disabled: color.a *= .5
		for y in rows.size():
			for x in str(rows[y]).length():
				if str(rows[y])[x]!="#": continue
				var a := (origin+Vector2(x,y)*factor).round()
				var b := (origin+Vector2(x+1,y+1)*factor).round()
				draw_rect(Rect2(a,b-a),color)
static func apply(control: Control, text: String, color: Color, extent: float) -> bool:
	var parts := text.split("\n",false,1)
	if parts.size()==2 and PATTERNS.has(parts[0]):
		return _apply_stacked(control,parts[0],parts[1],color)
	if not PATTERNS.has(text): return false
	# Text is retained verbatim, including button accessible text and callbacks.
	for role in ["font_color","font_hover_color","font_pressed_color","font_focus_color","font_disabled_color"]:
		control.add_theme_color_override(role,Color.TRANSPARENT)
	var mark := SymbolMark.new()
	mark.name="NativeSymbolIcon"
	mark.rows=PATTERNS[text]; mark.ink=color; mark.extent=extent
	control.add_child(mark)
	mark.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	control.resized.connect(mark.queue_redraw)
	return true

static func _apply_stacked(control: Control, symbol: String, caption: String, color: Color) -> bool:
	# A navigation label is not one glyph: retain button.text for accessibility,
	# then draw its symbol and readable caption in two independent fixed rows.
	apply(control,symbol,color,18)
	var mark: Control=control.get_node("NativeSymbolIcon")
	mark.anchor_bottom=0; mark.offset_top=4; mark.offset_bottom=27
	var label:=Label.new(); label.name="NativeSymbolCaption"; label.text=caption
	preload("res://scripts/ui/native_typography.gd").apply_body(label)
	label.add_theme_font_size_override("font_size",12)
	label.add_theme_color_override("font_color",color)
	label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	control.add_child(label)
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.offset_top=28; label.offset_bottom=-3
	return true
