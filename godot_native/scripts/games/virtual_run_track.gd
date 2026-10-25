extends Control
## One uniform coordinate space for the visible lane, cursor and input.
const Motion=preload("res://scripts/games/virtual_run_motion.gd")
const Ui=preload("res://scripts/ui/native_ui_theme.gd")
var motion: RefCounted
var display_scale=1.0
var aim=Vector2.ZERO
var dragging=false
var origin=Vector2.ZERO
var fit=1.0

func _ready() -> void:
	mouse_filter=MOUSE_FILTER_IGNORE
	resized.connect(_fit)
	_fit()

func _fit() -> void:
	fit=maxf(.1,minf((size.x-12)/360,(size.y-34)/360))
	origin=(size-Vector2.ONE*360*fit)/2+Vector2(0,6)
	queue_redraw()

func to_route(screen: Vector2) -> Vector2:
	return (get_global_transform_with_canvas().affine_inverse()*screen-origin)/fit

func to_screen(point: Vector2) -> Vector2:
	return get_global_transform_with_canvas()*(origin+point*fit)

func _draw() -> void:
	if motion==null:return
	draw_style_box(Ui.box(Color("eaf1e3"),Color("bdccbb"),1,10),Rect2(Vector2.ZERO,size))
	draw_set_transform(origin,0,Vector2.ONE*fit)
	var lane=Motion.path_between()
	draw_polyline(lane,Color("edceba"),58,true)
	draw_polyline(lane,Color("bb6b5a"),50,true)
	for offset in [-24.0,-12.0,0.0,12.0,24.0]:
		draw_polyline(Motion.path_between(0,Motion.LENGTH,Motion.RADIUS+offset),Color("efd7c2"),1.1,true)
	# Parallel straights and tangent semicircles form a closed running track.
	var field=Rect2(126,111,108,139)
	draw_style_box(Ui.box(Color("84ad70"),Color("dbe7ca"),1.5,0),field)
	draw_line(Vector2(126,180.5),Vector2(234,180.5),Color("dbe7ca"),1.5,true)
	draw_arc(Vector2(180,180.5),22,0,TAU,32,Color("dbe7ca"),1.5,true)
	draw_rect(Rect2(151,111,58,23),Color("dbe7ca"),false,1.5)
	draw_rect(Rect2(151,227,58,23),Color("dbe7ca"),false,1.5)
	for i in range(6):
		draw_rect(Rect2(177,302+i*9,6,9),Color.WHITE if i%2==0 else Color("3b4144"))
	var hazard=motion.interference()
	if not hazard.is_empty():
		var c: Vector2=hazard.center;var r: float=hazard.radius
		draw_circle(c,r,Color(1,.77,.2,.28))
		draw_arc(c,r,0,TAU,40,Color("c48b27"),2,true)
		for i in range(3):draw_arc(c,8+i*7,-1.8,1.8,24,Color("a97021"),1.5,true)
	if motion.trail.size()>1:
		draw_polyline(motion.trail,Color("e4fff5"),8,true)
		draw_polyline(motion.trail,Color("289677"),4,true)
	var font=get_theme_default_font()
	var gates=Motion.gates()
	for i in range(10):
		if i==9 and motion.completed<9:continue
		var p: Vector2=gates[i]*360
		var color=Color("267954") if i<motion.completed else Color("ffdf75") if i==motion.completed else Color("eee1d5")
		draw_circle(p,14,color)
		if i==motion.completed:draw_arc(p,20+2*sin(motion.clock*3),0,TAU,32,Color("fff5bb"),2,true)
		if i<motion.completed:draw_polyline(PackedVector2Array([p+Vector2(-5,0),p+Vector2(-1,5),p+Vector2(7,-5)]),Color.WHITE,2,true)
		else:draw_string(font,p+Vector2(-4 if i<9 else -8,5),str(i+1),HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("614e3f"))
	var cursor: Vector2=motion.position
	if dragging:draw_line(cursor,cursor+(aim-cursor).limit_length(52),Color("2c6dac"),2,true)
	draw_circle(cursor+Vector2(0,4),15,Color(0,.14,.22,.18))
	draw_circle(cursor,13,Color.WHITE);draw_circle(cursor,9,Color("2379bc"))
	draw_arc(cursor,18,-PI/2,-PI/2+TAU*maxf(.01,motion.integrity),40,Color("25a578") if motion.integrity>.5 else Color("d77734"),3,true)
	if absf(motion.pulse)>.01:draw_arc(cursor,24+(1-absf(motion.pulse))*20,0,TAU,40,Color(.2,.65,.45,absf(motion.pulse)),2,true)
	# Pace bars make speed and the safe signal-zone threshold observable.
	for i in range(5):
		var filled=motion.velocity.length()>i*25
		draw_rect(Rect2(145+i*15,211,9,5+i*3),Color("d58a30") if filled and motion.velocity.length()>80 and not hazard.is_empty() else Color("205b74") if filled else Color("b8c7ab"))
