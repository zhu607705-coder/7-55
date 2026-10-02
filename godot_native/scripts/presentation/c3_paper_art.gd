extends RefCounted
## Literal source-generated 64x50 paper and four walking frames from
## CanteenInteriorScene.ensureCanteenTextures / generatePaperRunTexture.
static func draw(c: CanvasItem, point: Vector2, factor: float, angle: float, frame: int=-1, alpha: float=1.0) -> void:
	c.draw_set_transform(point,deg_to_rad(angle),Vector2.ONE*factor)
	var lift: float=2.0 if frame>=0 and frame%2==0 else 0.0
	var left: float=-5.0 if frame==1 else 4.0 if frame==3 else 0.0
	var right: float=4.0 if frame==1 else -5.0 if frame==3 else 0.0
	var ellipse:=PackedVector2Array()
	var width: float=54.0 if frame<0 else 48.0 if frame%2==0 else 55.0
	for i in range(33):
		var a: float=TAU*i/32.0
		ellipse.append(Vector2(cos(a)*width/2,sin(a)*(5 if frame<0 else 4)+(18 if frame<0 else 20)))
	c.draw_colored_polygon(ellipse,Color(0.051,0.11,0.176,alpha*(0.34 if frame<0 else 0.3)))
	if frame>=0:
		_poly(c,[[16,36-lift],[24,38-lift],[21+left,47],[14+left,46]],"41535e",alpha)
		_poly(c,[[39,34-lift],[48,33-lift],[50+right,44],[43+right,46]],"41535e",alpha)
	_poly(c,[[7,9-lift],[48,6-lift],[58,34-lift],[17,46-lift],[5,36-lift]],"60717c",alpha)
	var outline: Array=[[5,5-lift],[46,2-lift],[55,30-lift],[15,41-lift],[3,32-lift]]
	_poly(c,outline,"d7e0e3",alpha)
	_poly(c,[[5,5-lift],[25,8-lift],[15,41-lift],[3,32-lift]],"f3f6f3",alpha)
	_poly(c,[[25,8-lift],[46,2-lift],[55,30-lift],[34,27-lift],[15,41-lift]],"e5ebec",alpha)
	_poly(c,[[46,2-lift],[55,30-lift],[41,18-lift]],"c1ced4",alpha)
	var points:=PackedVector2Array()
	for p: Array in outline: points.append(Vector2(p[0]-32,p[1]-25))
	points.append(points[0]); c.draw_polyline(points,Color("4a6371",0.95*alpha),2)
	for edge: Array in [[[25,8-lift],[15,41-lift]],[[34,27-lift],[55,30-lift]]]:
		c.draw_line(Vector2(edge[0][0]-32,edge[0][1]-25),Vector2(edge[1][0]-32,edge[1][1]-25),Color("91a4ae",0.88*alpha),2)
	if frame<0:
		c.draw_line(Vector2(9,-7),Vector2(14,-23),Color("91a4ae",0.88*alpha),2)
		var pixels: Dictionary={"0":["111","101","101","101","111"],"5":["111","100","111","001","111"],"7":["111","001","010","010","010"]}
		for digit in range(4):
			for y in range(5):
				for x in range(3):
					if pixels["0755"[digit]][y][x]=="1": _rect(c,13+digit*8+x*2,12+y*2,2,2,"236f9d",alpha*0.98)
		_rect(c,13,24,27,2,"58c7ff",alpha*0.9); _rect(c,13,29,18,2,"58c7ff",alpha*0.9)
	else:
		for r: Array in [[13,13-lift,30,3],[13,20-lift,24,2],[13,25-lift,29,2]]: _rect(c,r[0],r[1],r[2],r[3],"236f9d",alpha*0.98)
	for r: Array in ([[44,23,3,3],[48,22,3,3],[45,28,6,2]] if frame<0 else [[45,22-lift,3,3],[49,21-lift,3,3],[46,28-lift,6,2]]): _rect(c,r[0],r[1],r[2],r[3],"2f86b4" if frame<0 else "58c7ff",alpha*0.92)
	c.draw_set_transform(Vector2.ZERO)
static func _poly(c: CanvasItem, points: Array, color: String, alpha: float) -> void:
	var out:=PackedVector2Array()
	for p: Array in points: out.append(Vector2(p[0]-32,p[1]-25))
	c.draw_colored_polygon(out,Color(color,alpha))
static func _rect(c: CanvasItem,x: float,y: float,w: float,h: float,color: String,alpha: float) -> void:
	c.draw_rect(Rect2(x-32,y-25,w,h),Color(color,alpha))
