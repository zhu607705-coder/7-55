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
