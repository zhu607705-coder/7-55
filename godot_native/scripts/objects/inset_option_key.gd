extends Control
## One object owns the brass face, inset label rectangles and rendered text.
## Its parent uses this exact outer rectangle for gesture ownership.
const Type=preload("res://scripts/ui/native_typography.gd")
var caption_label:Label
var value_label:Label
var left_arrow:Label
var right_arrow:Label
var caption:=""
var value:=""
var arrows:=false
var highlighted:=false
var handle_style:=false
var text_bounds:=Rect2()
var label_bounds:=Rect2()
var _signature:Array=[]
func _ready()->void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE;clip_contents=true
	caption_label=make_label(Color("735833"));value_label=make_label(Color("332c20"))
	left_arrow=make_label(Color("92754c"));left_arrow.text="‹"
	right_arrow=make_label(Color("92754c"));right_arrow.text="›"
	resized.connect(layout_inset);layout_inset()
func make_label(ink:Color)->Label:
	var label:=Label.new();Type.apply_body(label);label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	label.clip_text=true;label.add_theme_color_override("font_color",ink);add_child(label);return label
func present(rect:Rect2,title:String,text:String,can_cycle:bool,selected:bool,handle:=false)->void:
	var signature:Array=[rect,title,text,can_cycle,selected,handle]
	if signature==_signature:return
	_signature=signature;position=rect.position;size=rect.size;caption=title;value=text;arrows=can_cycle;highlighted=selected;handle_style=handle
	layout_inset();queue_redraw()
func fit(label:Label,rect:Rect2,text:String,desired:int)->void:
	var points:=desired;var font:=Type.body_font()
	while points>12 and (font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,points).x>rect.size.x or font.get_height(points)>rect.size.y):points-=1
	label.text=text;label.position=rect.position;label.size=rect.size;label.add_theme_font_size_override("font_size",points)
func layout_inset()->void:
	if value_label==null:return
	var inset:float=maxf(5,size.y*.12)
	var inner:=Rect2(Vector2(inset,inset),size-Vector2.ONE*inset*2)
	caption_label.visible=not caption.is_empty()
	left_arrow.visible=arrows;right_arrow.visible=arrows
	var label_width:float=0 if caption.is_empty() else size.x*.22
	label_bounds=Rect2(inner.position,Vector2(maxf(0,label_width-inset),inner.size.y))
	if not caption.is_empty():fit(caption_label,label_bounds,caption,clampi(roundi(size.y*.42),20,48))
	var arrow_width:float=maxf(16,size.y*.38) if arrows else 0
	text_bounds=Rect2(Vector2(maxf(inset,label_width)+arrow_width,inset),Vector2(size.x-maxf(inset,label_width)-inset-arrow_width*2,inner.size.y))
	fit(value_label,text_bounds,value,clampi(roundi(size.y*.49),24,56))
	if arrows:
		fit(left_arrow,Rect2(Vector2(label_width,inset),Vector2(arrow_width,inner.size.y)),"‹",clampi(roundi(size.y*.5),24,48))
		fit(right_arrow,Rect2(Vector2(size.x-inset-arrow_width,inset),Vector2(arrow_width,inner.size.y)),"›",clampi(roundi(size.y*.5),24,48))
func _draw()->void:
	var face:=StyleBoxFlat.new();face.bg_color=Color("c5ab71") if handle_style else Color("e0d1aa");face.border_color=Color("997a48");face.set_border_width_all(3);face.set_corner_radius_all(2)
	draw_style_box(face,Rect2(Vector2.ZERO,size))
	var inner:=Rect2(Vector2(4,4),size-Vector2(8,8));draw_rect(inner,Color("f1e3c0"),false,1)
	if not caption.is_empty():draw_line(Vector2(size.x*.22,7),Vector2(size.x*.22,size.y-7),Color("bca67e"),1)
	if highlighted:draw_line(Vector2(9,size.y-4),Vector2(size.x-9,size.y-4),Color("947331"),2)
