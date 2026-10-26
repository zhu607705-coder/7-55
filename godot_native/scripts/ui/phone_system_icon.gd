extends Control
## Original vector glyphs using familiar system meanings; no text-tile icons.
var kind="network"
var ink=Color.WHITE

func _init() -> void: mouse_filter=Control.MOUSE_FILTER_IGNORE
func _draw() -> void:
	var fit=minf(size.x,size.y)/28.0
	draw_set_transform((size-Vector2.ONE*28*fit)/2,0,Vector2.ONE*fit)
	match kind:
		"network":
			for radius in [6.0,11.0,16.0]: draw_arc(Vector2(14,23),radius,PI*1.24,PI*1.76,28,ink,2.2,true)
			draw_circle(Vector2(14,23),1.8,ink)
		"sound":
			draw_colored_polygon(PackedVector2Array([Vector2(4,11),Vector2(9,11),Vector2(15,5),Vector2(15,23),Vector2(9,17),Vector2(4,17)]),ink)
			for radius in [6.0,11.0]:draw_arc(Vector2(13,14),radius,-.85,.85,20,ink,2,true)
		"display":
			draw_arc(Vector2(14,14),5,0,TAU,32,ink,2,true)
			for i in range(8):
				var ray=Vector2.from_angle(i*TAU/8);draw_line(Vector2(14,14)+ray*9,Vector2(14,14)+ray*12,ink,2,true)
		"desktop":
			draw_rect(Rect2(5,3,18,22),ink,false,2)
			for x in [8,15]:
				for y in [7,13]:draw_rect(Rect2(x,y,4,4),ink)
			draw_line(Vector2(10,22),Vector2(18,22),ink,1.5,true)
		"apps":
			for x in [4,16]:
				for y in [4,16]:draw_style_box(preload("res://scripts/ui/native_ui_theme.gd").box(ink,Color.TRANSPARENT,0,2),Rect2(x,y,8,8))
		"privacy":
			draw_arc(Vector2(14,11),6,PI,TAU,24,ink,2.2,true)
			draw_style_box(preload("res://scripts/ui/native_ui_theme.gd").box(ink,Color.TRANSPARENT,0,2),Rect2(5,11,18,14))
			draw_circle(Vector2(14,17),1.8,Color("537dc7"));draw_line(Vector2(14,17),Vector2(14,21),Color("537dc7"),2,true)
		"activity":
			draw_rect(Rect2(2,8,22,12),ink,false,2);draw_rect(Rect2(25,11,2,6),ink)
			draw_rect(Rect2(5,11,15,6),ink)
		"about":
			draw_arc(Vector2(14,14),11,0,TAU,40,ink,2,true)
			draw_circle(Vector2(14,8),1.5,ink);draw_line(Vector2(14,12),Vector2(14,21),ink,2.2,true)
		"back","chevron":
			var direction=-1 if kind=="back" else 1
			draw_polyline(PackedVector2Array([Vector2(14-4*direction,6),Vector2(14+4*direction,14),Vector2(14-4*direction,22)]),ink,2.2,true)
