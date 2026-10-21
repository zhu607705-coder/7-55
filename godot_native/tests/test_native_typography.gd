extends SceneTree
const Type=preload("res://scripts/ui/native_typography.gd")
var checks:=0
var failures:=0
func check(ok:bool,message:String)->void:
	checks+=1
	if not ok:failures+=1;push_error("NATIVE TYPE: "+message)
func _initialize()->void:
	var body:FontVariation=Type.body_font()
	check(body==Type.body_font(),"body resource shared")
	check(body.base_font is FontFile,"bundled regular FontFile")
	check(body.base_font.get_font_name()=="Campus UI Sans","derived licensed family")
	check(not body.base_font.allow_system_fallback,"no implicit system body font")
	check(body.fallbacks.size()==1 and body.fallbacks[0]==Type.display_font(),"bundled pixel fallback")
	check(not Type.display_font().allow_system_fallback,"no implicit system fallback font")
	check(Type.display_font()==Type.display_font(),"display font shared")
	for text:String in ["当前任务","未同步的七分五十五秒","07:55 ABC xyz","，。！？（）","↶"]:
		for ch:String in text:check(body.has_char(ch.unicode_at(0)),"glyph available "+ch)
	var parent:=Control.new()
	var art:=TextureRect.new();parent.add_child(art)
	var label:=Label.new();label.text="中文正文";label.position=Vector2(12,16);label.size=Vector2(240,48);parent.add_child(label)
	var before:=Rect2(label.position,label.size)
	Type.apply_body(label)
	check(label.get_theme_font("font")==body,"body control font")
	check(Rect2(label.position,label.size)==before,"font adapter leaves authored geometry")
	check(label.texture_filter==CanvasItem.TEXTURE_FILTER_LINEAR,"body text filtering scoped")
	check(art.texture_filter==CanvasItem.TEXTURE_FILTER_PARENT_NODE and parent.texture_filter==CanvasItem.TEXTURE_FILTER_PARENT_NODE,"unrelated art filtering untouched")
	Type.apply_display(label)
	check(label.get_theme_font("font")==Type.display_font(),"explicit display role")
	check(label.texture_filter==CanvasItem.TEXTURE_FILTER_NEAREST,"pixel text stays nearest")
	parent.free()
	print("NATIVE_TYPOGRAPHY: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
