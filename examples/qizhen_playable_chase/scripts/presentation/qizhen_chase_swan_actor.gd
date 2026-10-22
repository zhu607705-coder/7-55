extends Node2D
## Shared PR144 art, independent scene. The actor never moves the game model.
const Swim=preload("res://scripts/presentation/qizhen_swan_swim_visual.gd")
const Hop=preload("res://scripts/presentation/qizhen_swan_hop_study.gd")
var swim: RefCounted=Swim.new()
var hop_texture: Texture2D
var point:=Vector2.ZERO
var heading: float=PI
var state: String="tracking"
var intro_time: float=-1
var zoom: float=1
var origin:=Vector2.ZERO
var time: float=0

func reset(at: Vector2) -> void:
	point=at;swim.reset(at);intro_time=0;time=0;queue_redraw()

func advance(dt: float, at: Vector2, direction: float, phase: String, initial_time: float) -> void:
	point=at;heading=direction;state=phase;intro_time=initial_time;time+=dt
	swim.update(dt,at,direction,"accelerate" if phase=="charge" else "swim")
	queue_redraw()

func _ellipse(p: Vector2, radii: Vector2, color: Color, width: float) -> void:
	var line:=PackedVector2Array()
	for i: int in range(33):line.append(p+Vector2(cos(TAU*i/32),sin(TAU*i/32))*radii)
	draw_polyline(line,color,width,false)

func _draw() -> void:
	if intro_time<0:
		swim.draw(self,point,origin,zoom)
		if state=="charge_warning":
			_ellipse(origin+point*zoom,Vector2(42,10)*zoom,Color(1,.66,.27,.7),2*zoom)
		return
	if hop_texture==null:hop_texture=load("res://assets/native/chapter3/black_swan_hop_keyframes_v3.png")
	var frame: int=0
	for i: int in range(Hop.Timeline.KEY_TIMES.size()):
		if intro_time>=Hop.Timeline.KEY_TIMES[i]:frame=i
	var air: float=clampf((intro_time-2.52)/.86,0,1)
	var height: float=4*32*air*(1-air)
	var center: Vector2=origin+point*zoom
	_ellipse(center,Vector2(34+height*.22,5+height*.08)*zoom,Color(.025,.10,.14,.3-height*.003),3*zoom)
	var parts: Array[Rect2]=[Hop.REGIONS[frame]]
	if frame==8:parts=[Rect2(19,766,310,3),Rect2(19,769,333,165)]
	if frame==9:parts=[Rect2(327,678,295,132),Rect2(352,810,270,88)]
	var root: Vector2=Hop.ROOTS[frame]
	var water_y: float=root.y+(14.5+height)/.30
	for part: Rect2 in parts:
		part.size.y=maxf(0,minf(part.end.y,water_y)-part.position.y)
		if part.size.y>0:draw_texture_rect_region(hop_texture,Rect2(center-Vector2(0,14.5+height)*zoom+(part.position-root)*.30*zoom,part.size*.30*zoom),part)
	var splash_age: float=intro_time-3.38
	if splash_age>0 and splash_age<1.1:
		for n: int in range(16):
			var v:=Vector2((-1 if n%2==0 else 1)*(22+(n%7)*7),-(36+(n%4)*10))
			var p: Vector2=center+(v*splash_age+Vector2(0,100*splash_age*splash_age))*zoom
			draw_rect(Rect2(p,Vector2(2,3)*zoom),Color(.79,.95,.92,1-splash_age/1.1))
