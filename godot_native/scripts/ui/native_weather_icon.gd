extends Control
## Original geometry, informed by conventional weather semantics.
## No font glyphs, downloaded icon paths, brand assets or animation state.
var kind: String="rain"
var ink:=Color("31566b")
var cloud_fill:=Color("f4fbff")
var blue:=Color("388dcc")
var sun_color:=Color("f1bd4b")
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
func _stroke(points: PackedVector2Array,color: Color,width: float=2.6) -> void:
	draw_polyline(points,color,width,true)
func _cloud(offset: Vector2=Vector2.ZERO,scale_value:float=1.0) -> void:
	# One continuous silhouette: three rounded lobes and a calm flat base.
	var curve=Curve2D.new()
	curve.add_point(Vector2(23,61),Vector2.ZERO,Vector2(-15,0))
	curve.add_point(Vector2(20,34),Vector2(-14,0),Vector2(3,-5))
	curve.add_point(Vector2(35,33),Vector2(-6,-3),Vector2(0,-17))
	curve.add_point(Vector2(67,27),Vector2(-7,-16),Vector2(12,-1))
	curve.add_point(Vector2(79,39),Vector2(0,-8),Vector2(19,-1))
	curve.add_point(Vector2(78,61),Vector2(20,0),Vector2(-18,0))
	curve.add_point(Vector2(23,61),Vector2(16,0),Vector2.ZERO)
	var path:PackedVector2Array=curve.tessellate(5,3)
	for i in path.size():path[i]=offset+path[i]*scale_value
	draw_colored_polygon(path,cloud_fill);_stroke(path,ink,2.2)
func _sun(center:Vector2=Vector2(50,44),radius:float=18) -> void:
	for i in 8:
		var v=Vector2.from_angle(i*TAU/8)
		draw_line(center+v*(radius+7),center+v*(radius+14),sun_color,3.6,true)
	draw_circle(center,radius,sun_color,true,-1,true)
func _drop(center: Vector2,scale_value:float=1.0) -> void:
	var curve=Curve2D.new()
	curve.add_point(Vector2(0,-14),Vector2.ZERO,Vector2(3,7))
	curve.add_point(Vector2(8,6),Vector2(0,-5),Vector2(0,10))
	curve.add_point(Vector2(-8,6),Vector2(0,10),Vector2(0,-5))
	curve.add_point(Vector2(0,-14),Vector2(-3,7),Vector2.ZERO)
	var path:PackedVector2Array=curve.tessellate(4,3)
	for i in path.size():path[i]=center+path[i]*scale_value
	draw_colored_polygon(path,blue)
func _wind() -> void:
	for spec in [[28.0,70.0,-1.0],[44.0,86.0,1.0],[61.0,62.0,-1.0]]:
		var y:float=spec[0];var x:float=spec[1];var sign_value:float=spec[2]
		var curve=Curve2D.new()
		curve.add_point(Vector2(13,y),Vector2.ZERO,Vector2(20,0))
		curve.add_point(Vector2(x,y),Vector2(-15,0),Vector2(12,0))
		curve.add_point(Vector2(x+3,y+sign_value*13),Vector2(11,0),Vector2(-6,0))
		curve.add_point(Vector2(x-4,y+sign_value*9),Vector2(0,5*sign_value),Vector2.ZERO)
		_stroke(curve.tessellate(5,3),blue,3)
func _draw() -> void:
	var factor:float=minf(size.x/100.0,size.y/90.0)
	if factor<=0:return
	draw_set_transform((size-Vector2(100,90)*factor)/2,0,Vector2.ONE*factor)
	match kind:
		"sun":_sun()
		"cloud":_cloud()
		"partly_cloudy":_sun(Vector2(68,28),13);_cloud(Vector2(0,12),.88)
		"rain":
			_cloud()
			for x in [33,51,69]:draw_line(Vector2(x,69),Vector2(x-5,79),blue,3.5,true)
		"snow":
			_cloud()
			for x in [32,53,74]:
				for i in 3:
					var v=Vector2.from_angle(i*PI/3)*5
					draw_line(Vector2(x,75)-v,Vector2(x,75)+v,blue,1.8,true)
		"wind":_wind()
		"drop":_drop(Vector2(50,44),2.2)
	draw_set_transform(Vector2.ZERO)
