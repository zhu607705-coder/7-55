extends RefCounted
## Original vector glyphs for existing phone launchers; no routes or app state.
const FILES={"wechat":"messages","tiyi":"sports","zjuding":"campus","settings":"settings","photos":"album","timeline_recovery":"recovery","voice_memos":"voice","cc98":"forum","control_center":"controls","clock":"clock"}
static func add_to(button:Control,id:String)->TextureRect:
	var glyph:=TextureRect.new()
	glyph.name="LauncherGlyph"
	glyph.texture=load("res://ui_assets/phone_icons/"+str(FILES[id])+".svg")
	glyph.position=Vector2(12,12);glyph.size=Vector2(24,24)
	glyph.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	glyph.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	glyph.mouse_filter=Control.MOUSE_FILTER_IGNORE
	button.add_child(glyph)
	return glyph
