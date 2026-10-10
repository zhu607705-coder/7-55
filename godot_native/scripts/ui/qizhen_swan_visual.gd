extends RefCounted
## Native drawing port of createQizhenBlackSwanVisual, QizhenKayakTextures.ts.
func ellipse(canvas: CanvasItem,center: Vector2,radii: Vector2,color: Color,width: float=0,rotation: float=0) -> void:
	var points: PackedVector2Array=[]
	for index: int in range(49):
		var angle: float=TAU*index/48
		points.append(center+Vector2(cos(angle)*radii.x,sin(angle)*radii.y).rotated(rotation))
	if width>0: canvas.draw_polyline(points,color,width,true)
	else: canvas.draw_colored_polygon(points,color)
func poly(canvas: CanvasItem,center: Vector2,coords: Array,color: Color,stroke: Color,width: float=2,rotation: float=0) -> void:
	var points: PackedVector2Array=[]
	for i: int in range(0,coords.size(),2): points.append(center+Vector2(coords[i],coords[i+1]).rotated(rotation))
	canvas.draw_colored_polygon(points,color)
	points.append(points[0]); canvas.draw_polyline(points,stroke,width,true)
func shape(canvas: CanvasItem,center: Vector2,radii: Vector2,color: String,stroke: String="",width: float=2) -> void:
	ellipse(canvas,center,radii,Color(color))
	if not stroke.is_empty(): ellipse(canvas,center,radii,Color(stroke),width)
func draw(canvas: CanvasItem,at: Vector2,zoom: float,heading: float,wing_beat: float,intensity: float) -> void:
	var power: float=clampf(intensity,0,1)
	var beat: float=absf(wing_beat)
	canvas.draw_set_transform(at,heading,Vector2.ONE*zoom*(1+power*0.09))
	ellipse(canvas,Vector2(-46,0),Vector2(63*(0.88+power*0.44),23*(0.86+power*0.22)),Color(0.855,0.98,1,0.3*(0.12+power*0.42)),2)
	ellipse(canvas,Vector2(-30,0),Vector2(46,15)*(0.9+beat*0.35+power*0.28),Color(0.855,0.98,1,0.48*(0.24+beat*0.28+power*0.26)),2)
	ellipse(canvas,Vector2(-34,-17),Vector2(33*(0.82+power*0.7),8*(0.84+beat*0.28)),Color(0.945,1,1,0.34*(0.12+power*0.5)),2,deg_to_rad(-12))
	ellipse(canvas,Vector2(-34,17),Vector2(33*(0.82+power*0.7),8*(0.84+(1-minf(1,beat))*0.18)),Color(0.945,1,1,0.34*(0.12+power*0.5)),2,deg_to_rad(12))
	poly(canvas,Vector2(-31,0),[15,-14,15,14,-18,0],Color("10151c"),Color("344652"))
	shape(canvas,Vector2(-2,0),Vector2(32,19),"10151c","3b4d58",3)
	shape(canvas,Vector2(15,0),Vector2(13.5,15),"1b232c")
	poly(canvas,Vector2(-5,-10),[-21,3,-10,-14,8,-18,25,-9,14,0,-3,4],Color("1a222b"),Color("445660"),2,deg_to_rad(-16-wing_beat*(24+power*11)))
	poly(canvas,Vector2(-5,10),[-21,-3,-10,14,8,18,25,9,14,0,-3,-4],Color("1a222b"),Color("445660"),2,deg_to_rad(16+wing_beat*(24+power*11)))
	for entry: Array in [[-8,-16,28,-16,0.58],[-1,-20,23,-9,0.46],[-8,16,28,16,0.58],[-1,20,23,9,0.46]]:
		var center: Vector2=Vector2(entry[0],entry[1])
		var direction: Vector2=Vector2.from_angle(deg_to_rad(entry[3]))*entry[2]*0.5
		canvas.draw_line(center-direction,center+direction,Color(0.333,0.392,0.42,entry[4]),3,true)
	canvas.draw_polyline(PackedVector2Array([Vector2(18,1),Vector2(24,-8),Vector2(31,-14),Vector2(39,-12),Vector2(44,-7)]),Color("0e141a"),12,true)
	canvas.draw_polyline(PackedVector2Array([Vector2(20,3),Vector2(26,-6),Vector2(33,-11)]),Color("3c4b53"),2,true)
	shape(canvas,Vector2(46,-7),Vector2(8.5,7.5),"0e141a","3c4b53")
	poly(canvas,Vector2(53,-6),[-2.5,-5,2.5,-5,2.5,5,-2.5,5],Color("e8edf0"),Color("e8edf0"),0.1,deg_to_rad(3))
	poly(canvas,Vector2(61,-5),[-8,-6,9,0,-8,6],Color("e34b32"),Color("71231e"),1)
	shape(canvas,Vector2(48,-11),Vector2(2,2),"f6e37a","050608",1)
	canvas.draw_set_transform(Vector2.ZERO)
