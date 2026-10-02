extends RefCounted
## Exact two-frame source presentation from QizhenKayakTextures.ts.
## Original art is uniformly scaled by .52 and oriented heading + PI/2.
var frames: Array=[]
func _load() -> void:
	if not frames.is_empty(): return
	for suffix in ["a","b"]: frames.append(load("res://assets/rpg/qizhen/kayak_overhead_frame_"+suffix+".png"))
func _ellipse(canvas: CanvasItem, center: Vector2, dimensions: Vector2, color: Color, width: float=2) -> void:
	var points:=PackedVector2Array()
	for i in range(33): points.append(center+Vector2(cos(TAU*i/32),sin(TAU*i/32))*dimensions/2)
	canvas.draw_polyline(points,color,width,true)
func draw(canvas: CanvasItem, point: Vector2, zoom: float, pose: Dictionary, elapsed_ms: float) -> void:
	_load()
	var heading: float=float(pose.get("heading",-PI/2))
	var speed: float=float(pose.get("speed",0))
	var forward: float=clampf(maxf(0,speed)/360,0,1)
	var reverse: float=clampf(maxf(0,-speed)/230,0,1)
	var ratio: float=maxf(forward,reverse)
	var unit: float=zoom*.52
	var alpha: float=float(pose.get("alpha",1))
	canvas.draw_set_transform(point,heading+PI/2,Vector2.ONE*unit)
	_ellipse(canvas,Vector2(0,72),Vector2(46,112)*(.68+forward*.9),Color(.66,.92,1,.3*forward*.44*alpha))
	_ellipse(canvas,Vector2(0,58),Vector2(32,78)*(.76+forward*.7),Color(.84,.98,1,.46*forward*.66*alpha))
	_ellipse(canvas,Vector2(0,-66),Vector2(44,94)*(.62+reverse*.96),Color(.74,.94,1,.36*reverse*.5*alpha))
	_ellipse(canvas,Vector2(0,-54),Vector2(30,68)*(.7+reverse*.82),Color(.91,.99,1,.5*reverse*.72*alpha))
	var frame: int=int(elapsed_ms/(150 if ratio>.08 else 420))%2
	if float(pose.get("strokeAgeMs",1000))<180: frame=1 if pose.get("side")=="left" else 0
	var texture: Texture2D=frames[frame]
	var roll: float=clampf(float(pose.get("roll",0)),-1,1)
	var body_y: float=float(pose.get("bodyY",roll*5))
	var offset: Vector2=Vector2(0,body_y).rotated(heading+PI/2)*unit
	var body_scale: Vector2=pose.get("bodyScale",Vector2.ONE)
	canvas.draw_set_transform(point+offset,heading+PI/2+deg_to_rad(float(pose.get("bodyAngle",0))),body_scale*unit)
	canvas.draw_texture_rect(texture,Rect2(-Vector2(texture.get_size())/2,texture.get_size()),false,Color(1,1,1,alpha*float(pose.get("bodyAlpha",1))))
	canvas.draw_set_transform(Vector2.ZERO)
