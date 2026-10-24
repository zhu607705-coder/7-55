extends SceneTree
const KeyObject=preload("res://scripts/objects/inset_option_key.gd")
var checks:=0
var failures:=0
func check(ok:bool,message:String)->void:
	checks+=1
	if not ok:failures+=1;push_error(message)
func _initialize()->void:call_deferred("run")
func run()->void:
	var key:=KeyObject.new();root.add_child(key)
	for dimensions:Vector2 in [Vector2(270,48),Vector2(330,56),Vector2(510,80),Vector2(670,110)]:
		for text:String in ["点按选择","1991–1998","入口导视","齿孔残号"]:
			key.present(Rect2(Vector2(20,20),dimensions),"年代",text,true,true)
			await process_frame
			for label:Label in [key.caption_label,key.value_label,key.left_arrow,key.right_arrow]:
				var font:Font=label.get_theme_font("font");var px:int=label.get_theme_font_size("font_size")
				check(Rect2(Vector2.ZERO,key.size).encloses(label.get_rect()),"Text belongs to inset object bounds")
				check(font.get_string_size(label.text,HORIZONTAL_ALIGNMENT_LEFT,-1,px).x<=label.size.x and font.get_height(px)<=label.size.y,"All glyphs fit inside their inset at "+str(dimensions)+text)
				check(label.horizontal_alignment==HORIZONTAL_ALIGNMENT_CENTER and label.vertical_alignment==VERTICAL_ALIGNMENT_CENTER,"Native text centers in both axes without fixed baseline offsets")
			check(key.value_label.get_theme_font_size("font_size")>=20,"Readable text fits the compact button")
	key.present(Rect2(0,0,140,64),"","拉开",false,false,true)
	check(key.value_label.size.y<=64 and not key.caption_label.visible,"Drawer handle uses the same inset layout")
	key.queue_free();await process_frame
	print("INSET_OPTION_KEY ",checks," checks; ",failures," failures");quit(1 if failures else 0)
