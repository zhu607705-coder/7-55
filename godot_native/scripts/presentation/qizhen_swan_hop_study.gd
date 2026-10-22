extends Control
## Independent articulated key-pose review; swimming and original entrance remain intact.
const Timeline=preload("res://scripts/presentation/qizhen_swan_hop_timeline.gd")
const SCALE: float=.30
const BODY_HALF_HEIGHT: float=14.5
const REGIONS: Array[Rect2]=[
	Rect2(34,152,256,170),Rect2(320,188,308,134),Rect2(640,165,299,158),Rect2(953,152,290,170),
	Rect2(14,407,299,203),Rect2(326,379,298,233),Rect2(630,358,281,255),Rect2(922,466,321,160),
	Rect2(19,766,333,168),Rect2(327,678,295,220),Rect2(626,637,283,243),Rect2(925,712,320,194),
	Rect2(15,1024,326,161),Rect2(349,1014,279,165),Rect2(660,1029,267,149),Rect2(975,1014,257,164)]
# Body-root anchors, not bounding-box corners. Wing extent never re-centers the bird.
const ROOTS: Array[Vector2]=[
	Vector2(175,275),Vector2(523,273),Vector2(823,273),Vector2(1117,270),
	Vector2(207,562),Vector2(514,566),Vector2(813,562),Vector2(1119,528),
	Vector2(198,829),Vector2(493,798),Vector2(795,780),Vector2(1103,800),
	Vector2(197,1127),Vector2(520,1124),Vector2(811,1126),Vector2(1116,1127)]
var timeline: RefCounted=Timeline.new()
var texture: Texture2D
var lake: Texture2D
var font: Font
var capture_mode: bool=false
var replay_hold: float=0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	texture=load("res://assets/native/chapter3/black_swan_hop_keyframes_v3.png")
	lake=load("res://assets/rpg/interiors/qizhen_lake_swan_cove.png")
	font=preload("res://scripts/ui/native_typography.gd").body_font()

func _process(dt: float) -> void:
	if timeline.paused:return
	timeline.advance(minf(dt,.05))
	if timeline.elapsed>=Timeline.DURATION:
		replay_hold+=dt
		if not capture_mode and replay_hold>.25:timeline.reset();replay_hold=0
	queue_redraw()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode==KEY_R:timeline.reset();replay_hold=0
		elif event.keycode in [KEY_SPACE,KEY_P]:timeline.paused=not timeline.paused
		queue_redraw()

func _ellipse(p: Vector2,radii: Vector2,color: Color,width: float) -> void:
	var line:=PackedVector2Array()
	for i: int in range(33):line.append(p+Vector2(cos(TAU*i/32),sin(TAU*i/32))*radii)
	draw_polyline(line,color,width,false)

func _sprite(frame: int,center: Vector2,height: float,zoom: float) -> void:
	var parts: Array[Rect2]=[REGIONS[frame]]
	# Two generated subjects overhang their nominal grid cell. Atlas sampling
	# excludes only neighboring pixels; original RGBA artwork is unmodified.
	if frame==8:parts=[Rect2(19,766,310,3),Rect2(19,769,333,165)]
	if frame==9:parts=[Rect2(327,678,295,132),Rect2(352,810,270,88)]
	var root: Vector2=ROOTS[frame]
	var water_y: float=root.y+(BODY_HALF_HEIGHT+height)/SCALE
	for part: Rect2 in parts:
		part.size.y=maxf(0,minf(part.end.y,water_y)-part.position.y)
		if part.size.y<=0:continue
		var rect:=Rect2(center+(part.position-root)*SCALE*zoom,part.size*SCALE*zoom)
		draw_texture_rect_region(texture,rect,part)

func _splash(age: float,point: Vector2,zoom: float,landing: bool,particles: bool=true,rings: bool=true) -> void:
	var duration: float=1.15 if landing else .65
	if age<0 or age>duration:return
	var power: float=1.0 if landing else .65
	for n: int in range((20 if landing else 14) if particles else 0):
		var side: float=-1.0 if n%2==0 else 1.0
		var vx: float=side*(18+(n%7)*7)*power
		var vy: float=-(34+(n%5)*11)*power
		var offset:=Vector2(vx*age,vy*age+100*age*age)
		var fade: float=clampf(1-age/duration,0,1)
		draw_rect(Rect2(point+offset*zoom,Vector2(1.2+(n%3)*.45,1.7+(n%2)*.6)*zoom),Color(.79,.95,.92,fade*.90))
	for ring: int in range(3 if rings else 0):
		var radii:=Vector2(16+age*50+ring*7,3+age*10+ring*2)*zoom
		_ellipse(point,radii,Color(.65,.88,.86,(1-age/duration)*.35),maxf(1,zoom*.45))

func _draw() -> void:
	if lake==null:return
	var zoom: float=2.7*minf(size.x/1280,size.y/720)
	var origin: Vector2=size/2-Vector2(830,393)*zoom
	draw_rect(Rect2(Vector2.ZERO,size),Color("10252a"))
	draw_texture_rect(lake,Rect2(origin,Vector2(1672,941)*zoom),false)
	var pose: Dictionary=timeline.pose()
	var p: Vector2=origin+pose.point*zoom
	var height: float=pose.height
	# The shadow remains on the water while the articulated whole body rises.
	var shadow:=PackedVector2Array()
	for i: int in range(32):shadow.append(p+Vector2(cos(TAU*i/32)*(34+height*.22),sin(TAU*i/32)*(5+height*.08))*zoom)
	draw_colored_polygon(shadow,Color(.025,.10,.14,.23-height*.003))
	_splash(float(pose.launch_age),origin+(timeline.position_at(Timeline.TAKEOFF)+Vector2(20,3))*zoom,zoom,false)
	_splash(float(pose.landing_age),origin+timeline.position_at(Timeline.LANDING)*zoom,zoom,true,false,true)
	_sprite(int(pose.frame),p-Vector2(0,BODY_HALF_HEIGHT+height)*zoom,height,zoom)
	if height<1:
		_ellipse(p,Vector2(34,3.4)*zoom,Color(.43,.72,.73,.48),maxf(1,zoom*.55))
	_splash(float(pose.landing_age),origin+timeline.position_at(Timeline.LANDING)*zoom,zoom,true,true,false)
	var fade: float=smoothstep(6.6,7,timeline.elapsed)
	if fade>0:draw_rect(Rect2(Vector2.ZERO,size),Color(.035,.09,.11,fade))
	draw_rect(Rect2(0,0,size.x,58),Color(.035,.09,.11,.95))
	draw_string(font,Vector2(24,37),"启真湖 · 展翅短扑动作审看",HORIZONTAL_ALIGNMENT_LEFT,-1,23,Color("e2eee7"))
	draw_string(font,Vector2(size.x-370,37),pose.state,HORIZONTAL_ALIGNMENT_RIGHT,345,21,Color("c1dbd3"))
	draw_rect(Rect2(0,size.y-48,size.x,48),Color(.035,.09,.11,.95))
	draw_string(font,Vector2(24,size.y-18),"16 个完整姿态 · 水面短扑 · 视觉待审",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("c6d8d6"))
	if not capture_mode:draw_string(font,Vector2(size.x-235,size.y-18),"R 重播 · 空格暂停",HORIZONTAL_ALIGNMENT_RIGHT,210,17,Color("c6d8d6"))
