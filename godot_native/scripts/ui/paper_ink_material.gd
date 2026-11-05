extends RefCounted
## Scoped story stationery. Rendering only; no layout, input or saved state.
## Inspired by Catch's paper cards, not its artwork, lettering or branding.
const PAPER := Color("f6efe2")
const INK := Color("1d1a1e")
const SOFT_INK := Color("4a4038")
const EDGE := Color("6f655a")
const GOLD := Color("e2b33f")
const FOCUS := Color("a43b32")

static func label_color(variant: String, disabled: bool = false) -> Color:
	if disabled: return SOFT_INK
	return PAPER if variant == "primary" else INK

static func face_color(variant: String, hover: float = 0.0, disabled: float = 0.0) -> Color:
	if variant in ["ghost","text"]: return Color.TRANSPARENT
	var base := INK.lerp(Color("332c30"),hover) if variant == "primary" else PAPER.lerp(Color("fff7df"),hover)
	return base.lerp(Color("ded5c6"),disabled)

static func _contour(rect: Rect2, unit: float) -> PackedVector2Array:
	# Subpixel pen variation stays inside the control. There is no animated wobble.
	var r := rect.grow(-0.7*unit)
	var x := r.position.x; var y := r.position.y
	var w := r.size.x; var h := r.size.y
	var c := minf(2.5*unit,minf(w,h)*0.2)
	return PackedVector2Array([
		Vector2(x+c,y+0.2*unit),Vector2(x+w*0.43,y+0.55*unit),Vector2(x+w-c,y),
		Vector2(x+w,y+c),Vector2(x+w-0.35*unit,y+h*0.57),Vector2(x+w,y+h-c),
		Vector2(x+w-c,y+h),Vector2(x+w*0.49,y+h-0.4*unit),Vector2(x+c,y+h),
		Vector2(x,y+h-c),Vector2(x+0.3*unit,y+h*0.4),Vector2(x,y+c)])

static func _fill(canvas: RID, points: PackedVector2Array, color: Color) -> void:
	RenderingServer.canvas_item_add_polygon(canvas,points,PackedColorArray([color]))

static func _edge(canvas: RID, points: PackedVector2Array, color: Color, width: float) -> void:
	var line := points.duplicate(); line.append(points[0])
	RenderingServer.canvas_item_add_polyline(canvas,line,PackedColorArray([color]),width,true)

static func _grain(canvas: RID, rect: Rect2, unit: float, dark: bool = false) -> void:
	var area := rect.grow(-4.0*unit)
	if area.size.x <= 0.0 or area.size.y <= 0.0: return
	var count := mini(180,maxi(12,roundi(area.get_area()/420.0)))
	var color := Color(PAPER,0.06) if dark else Color(SOFT_INK,0.045)
	for i in count:
		var px := fposmod(float(i)*0.61803398875+0.17,1.0)
		var py := fposmod(float(i)*float(i+3)*0.41421356237+0.31,1.0)
		var start := area.position+Vector2(px,py)*area.size
		RenderingServer.canvas_item_add_line(canvas,start,start+Vector2(0.7,0.15)*unit,color,0.6*unit,true)

static func draw_button(canvas: RID, rect: Rect2, variant: String, unit: float, hover: float, press: float, disabled: float, flat: bool = false) -> void:
	if rect.size.x < 4.0 or rect.size.y < 4.0: return
	if variant in ["ghost","text"]:
		# Icon / navigation hit regions stay transparent. Hover is a quiet ink wash,
		# not a new card covering the authored art or embedded labels.
		var amount := maxf(hover*0.055,press*0.10)*(1.0-disabled)
		if amount>0.0: _fill(canvas,_contour(rect,unit),Color(INK,amount))
		if variant=="text" or press>0.01:
			var y := rect.end.y-2.0*unit
			RenderingServer.canvas_item_add_line(canvas,Vector2(rect.position.x+4*unit,y),Vector2(rect.end.x-4*unit,y),Color(SOFT_INK,0.45*(1.0-disabled)),unit,true)
		return
	var face := rect
	if not flat: face.position.y += press*unit
	var points := _contour(face,unit)
	if not flat:
		var shadow := _contour(face,unit)
		var shift := Vector2(2.0,3.0)*unit*(1.0-press)*(1.0-disabled)
		for i in shadow.size(): shadow[i] += shift
		_fill(canvas,shadow,Color(INK,0.4*(1.0-disabled)))
	_fill(canvas,points,face_color(variant,hover,disabled))
	_grain(canvas,face,unit,variant == "primary" and disabled < 0.5)
	var edge := EDGE.lerp(GOLD,hover*0.3).lerp(Color("a99c89"),disabled)
	_edge(canvas,points,edge,unit)
	# A short inner ink rule gives press feedback without moving the hit target.
	if press > 0.01:
		var ink := label_color(variant,disabled > 0.5)
		ink.a = 0.3*press
		RenderingServer.canvas_item_add_line(canvas,face.position+Vector2(5,3)*unit,Vector2(face.end.x-5*unit,face.position.y+3*unit),ink,unit,true)

static func draw_panel(canvas: RID, rect: Rect2) -> void:
	if rect.size.x < 8.0 or rect.size.y < 8.0: return
	_grain(canvas,rect,1.0)
	_edge(canvas,_contour(rect,1.0),EDGE,1.0)

static func panel_style(padding: Vector2 = Vector2.ZERO, fill: Color = PAPER, border: Color = EDGE) -> StyleBoxFlat:
	# Explicit content margins are independent of the fine pen stroke.
	var style := StyleBoxFlat.new()
	style.bg_color=fill;style.border_color=border
	style.set_border_width_all(1 if border.a>0.0 else 0)
	style.set_corner_radius_all(2);style.anti_aliasing=true
	style.content_margin_left=padding.x;style.content_margin_right=padding.x
	style.content_margin_top=padding.y;style.content_margin_bottom=padding.y
	return style

static func focus_style() -> StyleBoxFlat:
	var style := panel_style(Vector2.ZERO,Color.TRANSPARENT,FOCUS)
	style.set_border_width_all(2)
	return style
