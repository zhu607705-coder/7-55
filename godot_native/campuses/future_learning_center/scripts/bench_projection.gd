extends RefCounted
## A single orthographic apparatus plane. World X is horizontal, Y is depth,
## Z is height; yaw stays zero. No per-object perspective or vanishing point.
const ELEVATION := PI/4.0
const DEPTH := 0.7071067811865476
const HEIGHT := 0.7071067811865476

static func project(point: Vector3) -> Vector2:
	return Vector2(point.x,point.y*DEPTH-point.z*HEIGHT)

static func floor_point(screen: Vector2, height:=0.0) -> Vector3:
	return Vector3(screen.x,(screen.y+height*HEIGHT)/DEPTH,height)

static func offset(x: float, depth: float, height:=0.0) -> Vector2:
	return project(Vector3(x,depth,height))

static func ring(center: Vector2, radius: float, start:=0.0, finish:=TAU, segments:=40) -> PackedVector2Array:
	var points:=PackedVector2Array()
	for i: int in segments+1:
		var a:=lerpf(start,finish,float(i)/segments)
		points.append(center+offset(cos(a)*radius,sin(a)*radius))
	return points

static func plate(canvas: CanvasItem, bounds: Rect2, thickness: float, top: Color, front: Color) -> void:
	# bounds describes the projected top face. Depth is inverted once here.
	var origin:=floor_point(bounds.position)
	var width:=bounds.size.x
	var depth:=bounds.size.y/DEPTH
	var a:=project(origin);var b:=project(origin+Vector3(width,0,0))
	var c:=project(origin+Vector3(width,depth,0));var d:=project(origin+Vector3(0,depth,0))
	var drop:=offset(0,0,-thickness)
	canvas.draw_colored_polygon(PackedVector2Array([d,c,c+drop,d+drop]),front)
	canvas.draw_colored_polygon(PackedVector2Array([a,b,c,d]),top)
	canvas.draw_line(d,c,top.lightened(.18),1)

static func box(canvas: CanvasItem, foot: Vector2, extent: Vector3, top: Color, side: Color) -> void:
	var origin:=floor_point(foot)-Vector3(extent.x/2,extent.y/2,0)
	var a:=project(origin+Vector3(0,0,extent.z))
	var b:=project(origin+Vector3(extent.x,0,extent.z))
	var c:=project(origin+Vector3(extent.x,extent.y,extent.z))
	var d:=project(origin+Vector3(0,extent.y,extent.z))
	var drop:=offset(0,0,-extent.z)
	canvas.draw_colored_polygon(PackedVector2Array([d,c,c+drop,d+drop]),side)
	canvas.draw_colored_polygon(PackedVector2Array([a,b,c,d]),top)
	canvas.draw_line(d,c,top.lightened(.18),1)

static func panel(center: Vector2, width: float, depth: float, tilt: float, height: float) -> PackedVector2Array:
	# Rotation around the real X hinge: depth and height change together.
	var base:=floor_point(center)
	var near:=base+Vector3(-width/2,depth/2,height)
	var far:=near+Vector3(0,-depth*cos(tilt),depth*sin(tilt))
	return PackedVector2Array([project(near),project(near+Vector3(width,0,0)),project(far+Vector3(width,0,0)),project(far)])
