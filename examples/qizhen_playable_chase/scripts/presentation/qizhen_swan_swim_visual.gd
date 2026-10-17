extends RefCounted
## Presentation-only swim study. Original entrance / chase models are unchanged.
## Four redrawn folded-wing headings; generated middle-column head dips are not
## cycled as normal swimming. Displacement, not wall-clock time, emits a wake.
const REGIONS: Array[Rect2] = [Rect2(41,117,318,233),Rect2(53,467,295,233),Rect2(69,823,273,231),Rect2(77,1151,241,237),Rect2(453,1175,236,213)]
const ANCHORS: Array[Vector2] = [Vector2(154,226),Vector2(137.8,226),Vector2(122.8,224),Vector2(113.7,230),Vector2(110.2,206)]
const BODY_SCALE: float = 0.24
const WAKE_SPACING: float = 10.0
var texture: Texture2D
var wakes: Array[Dictionary] = []
var previous: Vector2
var speed: float = 0
var elapsed: float = 0
var distance_travelled: float = 0
var residual_distance: float = 0
var emitted: int = 0
var row: int = 0
var accelerated_pose: bool = false

func reset(point: Vector2) -> void:
	previous=point
	speed=0
	elapsed=0
	distance_travelled=0
	residual_distance=0
	emitted=0
	row=0
	accelerated_pose=false
	wakes.clear()

func update(dt: float, point: Vector2, heading: float, state: String) -> void:
	if dt<=0 or not is_finite(dt):return
	elapsed+=dt
	var distance: float=previous.distance_to(point)
	speed=distance/dt
	distance_travelled+=distance
	var count: int=int(floor((residual_distance+distance)/WAKE_SPACING))
	if distance>0.0001:
		var direction: Vector2=(point-previous).normalized()
		for i: int in range(count):
			var along: float=(WAKE_SPACING-residual_distance+float(i)*WAKE_SPACING)/distance
			wakes.append({"point":previous.lerp(point,clampf(along,0,1))-direction*26,"heading":direction.angle(),"age":0.0,"strength":clampf(speed/85.0,0.15,1)})
			emitted+=1
		residual_distance=fmod(residual_distance+distance,WAKE_SPACING)
	for wake: Dictionary in wakes:wake.age=float(wake.age)+dt
	while not wakes.is_empty() and float(wakes[0].age)>2.4:wakes.pop_front()
	previous=point
	# Hysteresis prevents a threshold wobble from flickering between directions.
	var coordinate: float=clampf((PI-heading)/(PI/8.0),0,3)
	if coordinate>float(row)+0.62:row=mini(row+1,3)
	elif coordinate<float(row)-0.62:row=maxi(row-1,0)
	accelerated_pose=state=="accelerate" and row==3 and speed>60

func body_bob() -> float:
	# Under one source pixel; no neck pumping and no full-frame rolling.
	return sin(distance_travelled/20.0*TAU)*0.35*clampf(speed/40,0,1)

func draw(canvas: CanvasItem, point: Vector2, origin: Vector2, zoom: float, alpha: float=1.0) -> void:
	if texture==null:texture=load("res://assets/native/chapter3/black_swan_swim_atlas_v2.png")
	for wake: Dictionary in wakes:
		var age: float=float(wake.age)
		var strength: float=float(wake.strength)
		var fade: float=(1-age/2.4)*0.40*strength*alpha
		var direction: Vector2=Vector2.from_angle(float(wake.heading))
		var across: Vector2=direction.orthogonal()
		for side: float in [-1.0,1.0]:
			var center: Vector2=wake.point-direction*age*5
			var a: Vector2=center+across*side*(13+age*7)
			var b: Vector2=center-direction*(5+age*2)+across*side*(20+age*10)
			canvas.draw_line(origin+a*zoom,origin+b*zoom,Color(.70,.91,.90,fade),maxf(1,zoom*0.45),false)
	var index: int=4 if accelerated_pose else row
	var rect: Rect2=REGIONS[index]
	var anchor: Vector2=ANCHORS[index]
	var center: Vector2=origin+point*zoom
	var body_width: float=rect.size.x*BODY_SCALE
	# Dark contact ellipse is under the body, never a floating drop-shadow.
	_ellipse(canvas,center,Vector2(body_width*.39,4)*zoom,Color(.025,.15,.17,.20*alpha),zoom*.7)
	var body_height: float=anchor.y+body_bob()/BODY_SCALE
	var source:=Rect2(rect.position,Vector2(rect.size.x,body_height))
	var target:=Rect2(center-Vector2(anchor.x,body_height)*BODY_SCALE*zoom,source.size*BODY_SCALE*zoom)
	canvas.draw_texture_rect_region(texture,target,source,Color(1,1,1,alpha))
	# Front surface seam obscures the belly at exactly the water anchor. The
	# flat waterline is stable while the torso rises only a fraction of a pixel.
	var seam:=PackedVector2Array()
	for i: int in range(17):
		var x: float=(float(i)/16.0-.5)*body_width*.76
		seam.append(center+Vector2(x,sin(float(i)*.8+elapsed*1.3)*.45)*zoom)
	canvas.draw_polyline(seam,Color(.14,.38,.40,.80*alpha),maxf(1,zoom*1.15),false)
	if speed>1:
		var ripple_strength: float=clampf(speed/85,0,1)*alpha
		_ellipse(canvas,center+Vector2(0,1.2)*zoom,Vector2(body_width*.43,4.0)*zoom,Color(.72,.92,.89,.28*ripple_strength),maxf(1,zoom*.38))

func _ellipse(canvas: CanvasItem, point: Vector2, radii: Vector2, color: Color, width: float) -> void:
	var line:=PackedVector2Array()
	for i: int in range(25):line.append(point+Vector2(cos(TAU*i/24),sin(TAU*i/24))*radii)
	canvas.draw_polyline(line,color,width,false)
