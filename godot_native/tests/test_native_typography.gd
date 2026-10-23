extends SceneTree
const Type=preload("res://scripts/ui/native_typography.gd")
var checks:=0
var failures:=0
func check(ok:bool,message:String)->void:
	checks+=1
	if not ok:failures+=1;push_error("NATIVE TYPE: "+message)
func _initialize()->void:
	var body:FontVariation=Type.body_font()
	var display:FontVariation=Type.display_font()
	check(body==Type.body_font(),"body resource shared")
	check(display==Type.display_font() and display!=body,"display resource is cached independently from the body face")
	for face:FontVariation in [body,display]:
		check(face.base_font is FontFile,"bundled FontFile for each authored role")
		check(face.base_font.get_font_name()=="755 Morning Note","role belongs to the project's pixel family")
		check(not face.base_font.allow_system_fallback,"no implicit system body or display font")
		check(face.fallbacks.size()==1 and face.fallbacks[0]==Type._symbol_fallback_font(),"explicit bundled symbol fallback")
		check(face.variation_embolden==0,"roles use real authored weights without synthetic emboldening")
		check(not face.base_font.multichannel_signed_distance_field and face.base_font.antialiasing==TextServer.FONT_ANTIALIASING_NONE,"native pixel contours are not smoothed into a different outline")
	check(body.base_font.get_font_weight()==400 and display.base_font.get_font_weight()==500,"Regular and Medium are distinct real weights")
	check(body.base_font.get_data()!=display.base_font.get_data(),"display and body retain their own authored glyph bytes")
	check(not Type._symbol_fallback_font().allow_system_fallback,"no implicit system fallback font")
	# A clock or check-in code must not change width as its digits change.
	# This checks imported font metrics, not the appearance of a source matrix.
	for face:FontVariation in [body,display]:
		for pixels:int in [14,18,24]:
			var digit_width:=face.get_string_size("0",HORIZONTAL_ALIGNMENT_LEFT,-1,pixels).x
			for digit:String in "123456789":
				check(is_equal_approx(face.get_string_size(digit,HORIZONTAL_ALIGNMENT_LEFT,-1,pixels).x,digit_width),"clock digits retain tabular width at %dpx" % pixels)
			var clock_width:=face.get_string_size("07:55",HORIZONTAL_ALIGNMENT_LEFT,-1,pixels).x
			for clock:String in ["08:32","12:06","19:48"]:
				check(is_equal_approx(face.get_string_size(clock,HORIZONTAL_ALIGNMENT_LEFT,-1,pixels).x,clock_width),"time updates leave the clock width stable at %dpx" % pixels)
	for text:String in ["当前任务","未同步的七分五十五秒","07:55 ABC xyz","，。！？（）","↶"]:
		for ch:String in text:
			check(body.has_char(ch.unicode_at(0)) and display.has_char(ch.unicode_at(0)),"glyph available in both roles "+ch)
	var parent:=Control.new()
	var art:=TextureRect.new();parent.add_child(art)
	var label:=Label.new();label.text="中文正文";label.position=Vector2(12,16);label.size=Vector2(240,48);parent.add_child(label)
	var before:=Rect2(label.position,label.size)
	Type.apply_body(label)
	check(label.get_theme_font("font")==body,"body control font")
	check(Rect2(label.position,label.size)==before,"font adapter leaves authored geometry")
	check(label.texture_filter==CanvasItem.TEXTURE_FILTER_NEAREST,"body text uses scoped pixel filtering")
	check(art.texture_filter==CanvasItem.TEXTURE_FILTER_PARENT_NODE and parent.texture_filter==CanvasItem.TEXTURE_FILTER_PARENT_NODE,"unrelated art filtering untouched")
	Type.apply_display(label)
	check(label.get_theme_font("font")==Type.display_font(),"explicit display role")
	check(label.texture_filter==CanvasItem.TEXTURE_FILTER_NEAREST,"display text uses the same scoped pixel filtering")
	parent.free()
	print("NATIVE_TYPOGRAPHY: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
