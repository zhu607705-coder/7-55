extends RefCounted
## Source-Web CSS shapes adapted to the locked 24px glyph / 48px hit geometry.
## PNG, text wordmark and the interactive gear keep their source renderers in Pages.
const FILES={"wechat":"messages","tiyi":"sports","photos":"album","timeline_recovery":"recovery","voice_memos":"voice","control_center":"controls","clock":"clock"}
const SOURCE_COLORS={"wechat":Color("61b58c"),"tiyi":Color("e8893f"),"zjuding":Color("ece9df"),"settings":Color("777989"),"photos":Color("ece9df"),"timeline_recovery":Color("173948"),"voice_memos":Color("0a0a0c"),"cc98":Color("4d7ed9"),"control_center":Color("756aa9"),"clock":Color("20272f")}
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
