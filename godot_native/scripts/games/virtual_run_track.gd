extends Control
## Native vector reconstruction of the source's sports-track board.
## This renderer never handles input, increments a fix, or emits a result.
var points: Array = []
var completed := 0
var route_rect := Rect2()
var target_extent := 48.0
var display_scale := 1.0
const Ui = preload("res://scripts/ui/native_ui_theme.gd")

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE

func _at(point: Vector2) -> Vector2:
	return route_rect.position+point*route_rect.size

func _curve(out: PackedVector2Array,a: Vector2,b: Vector2,c: Vector2,d: Vector2) -> PackedVector2Array:
	for step in range(1,25):
		var t := step/24.0
		out.append(_at(a.bezier_interpolate(b,c,d,t)))
	return out

func _draw() -> void:
	if route_rect.size == Vector2.ZERO: return
	draw_style_box(Ui.box(Color("b6d599"),Color("74986b"),2,12),Rect2(Vector2.ZERO,size))
	var oval := PackedVector2Array([_at(Vector2(.44,.85)),_at(Vector2(.28,.85))])
	oval = _curve(oval,Vector2(.28,.85),Vector2(.04,.85),Vector2(.04,.18),Vector2(.28,.18))
	oval.append(_at(Vector2(.70,.18)))
	oval = _curve(oval,Vector2(.70,.18),Vector2(.96,.18),Vector2(.96,.85),Vector2(.70,.85))
	oval.append(_at(Vector2(.44,.85)))
	var lane_width := minf(route_rect.size.x*.15,58)
	draw_polyline(oval,Color("f2d2b4"),lane_width+8,true)
	draw_polyline(oval,Color("bb574b"),lane_width,true)
	draw_polyline(oval,Color("efbfa4"),1.5,true)
	var field := Rect2(_at(Vector2(.30,.29)),route_rect.size*Vector2(.40,.40))
	draw_style_box(Ui.box(Color("619d59"),Color("f0f7d9"),2,4),field)
	draw_line(Vector2(field.position.x,field.get_center().y),Vector2(field.end.x,field.get_center().y),Color("cce5b4"),1.5,true)
	draw_arc(field.get_center(),minf(field.size.x,field.size.y)*.22,0,TAU,40,Color("cce5b4"),1.5,true)
	var font := get_theme_default_font()
	var title := "ZJU SPORTS"
	var title_size := maxi(13,ceili(12/maxf(.1,display_scale)))
	draw_string(font,Vector2(field.get_center().x-font.get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,title_size).x/2,field.position.y+29),title,HORIZONTAL_ALIGNMENT_LEFT,-1,title_size,Color("173d36"))
	var laps := "%.2f / 7.50 圈" % (completed*.75)
	var lap_size := maxi(15,ceili(13/maxf(.1,display_scale)))
	draw_string(font,Vector2(field.get_center().x-font.get_string_size(laps,HORIZONTAL_ALIGNMENT_LEFT,-1,lap_size).x/2,field.end.y-22),laps,HORIZONTAL_ALIGNMENT_LEFT,-1,lap_size,Color("173d36"))
	# The accepted segment joins actual visited fixes. It never implies that a
	# future fix has been recorded, even when the full route is visible.
	if completed > 1:
		var visited := PackedVector2Array()
		for i in range(completed): visited.append(_at(points[i]))
		draw_polyline(visited,Color("164d38"),8,true)
		draw_polyline(visited,Color("8fea8b"),4,true)
	if completed < points.size():
		var target: Vector2 = _at(points[completed])
		draw_circle(target,target_extent/2+7,Color("fff2a0"))
		draw_arc(target,target_extent/2+9,-.5,TAU-.9,48,Color("6e581c"),2,true)
	# A small running silhouette moves to the last genuine fix, inward from
	# its button so the checked target remains unobscured.
	if completed > 0:
		var anchor: Vector2 = _at(points[completed-1])
		anchor += (_at(Vector2(.5,.5))-anchor).normalized()*(target_extent/2+20)
		draw_circle(anchor+Vector2(0,-12),4,Color("ffe0b3"))
		draw_line(anchor+Vector2(0,-7),anchor+Vector2(-2,3),Color("174d88"),5,true)
		draw_polyline(PackedVector2Array([anchor+Vector2(-8,-2),anchor+Vector2(0,-6),anchor+Vector2(8,-1)]),Color("174d88"),3,true)
		draw_polyline(PackedVector2Array([anchor+Vector2(-10,10),anchor+Vector2(-2,3),anchor+Vector2(7,10)]),Color("173b42"),3,true)
