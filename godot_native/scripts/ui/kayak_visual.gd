extends RefCounted
## Source-art articulated layers. Stroke history is read-only and never drives physics.
const STROKE_MS: float=680.0
var layers: Dictionary={}
func _load() -> void:
	if not layers.is_empty(): return
	for id: String in ["hull","seated_player"]:
		layers[id]=load("res://assets/native/kayak/"+id+".svg")

static func _ease(value: float) -> float:
	var t:=clampf(value,0,1)
	return t*t*(3-2*t)

static func stroke_pose(side: String,age_ms: float,reverse: bool=false,roll: float=0) -> Dictionary:
	var sign_x: float=-1 if side=="left" else 1
	var t:=clampf(age_ms/STROKE_MS,0,1)
	var phase: String="rest"
	var sweep: float=-.72
	var wet: float=0
	var lift: float=0
	if age_ms>=0 and age_ms<STROKE_MS:
		if t<.18:
			phase="entry";sweep=lerpf(-.72,-1.05,_ease(t/.18));wet=_ease(t/.18)
		elif t<.56:
			phase="pull";sweep=lerpf(-1.05,.82,_ease((t-.18)/.38));wet=1
		elif t<.73:
			phase="exit";sweep=lerpf(.82,1.02,_ease((t-.56)/.17));wet=1-_ease((t-.56)/.17);lift=sin((t-.56)/.17*PI/2)*6
		else:
			phase="recovery";sweep=lerpf(1.02,-.72,_ease((t-.73)/.27));lift=sin((1-t)/.27*PI/2)*6
	if reverse: sweep=-sweep
	var grip:=Vector2(sign_x*(17+wet*3),9+sin(sweep)*9-lift)
	var tip:=grip+Vector2(sign_x*cos(sweep),sin(sweep))*58
	var bend: float=(8*wet*sin(clampf((t-.18)/.38,0,1)*PI)) if side=="left" else 0
	if reverse: bend=-bend
	var shoulder:=Vector2(sign_x*11+roll*3,15)
	var elbow:=shoulder.lerp(grip,.55)+Vector2(sign_x*(8+absf(roll)*3),5)
	return {"phase":phase,"grip":grip,"tip":tip,"shaft_mid":grip.lerp(tip,.55)+Vector2(0,bend),"shoulder":shoulder,"elbow":elbow,"wet":wet,"lift":lift,"bend":bend,"reverse":reverse,"ageMs":age_ms}

static func paddle_poses(pose: Dictionary) -> Dictionary:
	var result: Dictionary={}
	for side: String in ["left","right"]:
		var age: float=10000
		var reverse: bool=false
		var events: Array=pose.get("strokeEvents",[])
		if pose.has("strokeEvents"):
			for i in range(events.size()-1,-1,-1):
				var input: Dictionary=events[i]
				if input.get("side")==side:
					age=(float(pose.get("tick",0))-float(input.get("tick",0)))*1000.0/120.0
					reverse=input.get("direction","")=="reverse"
					break
		elif pose.get("side","")==side:
			age=float(pose.get("strokeAgeMs",10000));reverse=pose.get("direction","")=="reverse"
		result[side]=stroke_pose(side,age,reverse,float(pose.get("roll",0)))
	return result

func _ellipse(canvas: CanvasItem,center: Vector2,dimensions: Vector2,color: Color,width: float=2) -> void:
	var points:=PackedVector2Array()
	for i in range(33): points.append(center+Vector2(cos(TAU*i/32),sin(TAU*i/32))*dimensions/2)
	canvas.draw_polyline(points,color,width,true)

func _paddle(canvas: CanvasItem,side: String,p: Dictionary,alpha: float) -> void:
	var grip: Vector2=p.grip;var tip: Vector2=p.tip
	var shaft:=PackedVector2Array([grip,p.shaft_mid,tip])
	canvas.draw_polyline(shaft,Color("2c2118",alpha),10,false)
	canvas.draw_polyline(shaft,Color("bd8750" if side=="left" else "e1e5dd",alpha),5,false)
	var axis: Vector2=(tip-Vector2(p.shaft_mid)).normalized()
	var normal:=Vector2(-axis.y,axis.x)
	var vertices:=PackedVector2Array()
	if side=="left":
		for q: Vector2 in [Vector2(-8,-7),Vector2(7,-10),Vector2(16,-4),Vector2(13,7),Vector2(-5,8)]: vertices.append(tip+axis*q.x+normal*q.y)
	else:
		for q: Vector2 in [Vector2(17,0),Vector2(-9,-15),Vector2(-9,15)]: vertices.append(tip+axis*q.x+normal*q.y)
	canvas.draw_colored_polygon(vertices,Color("9b6a3b" if side=="left" else "f0d856",alpha))
	vertices.append(vertices[0]);canvas.draw_polyline(vertices,Color("3a2a1d" if side=="left" else "d43c31",alpha),3,false)
	if side=="left":
		canvas.draw_line(tip-axis*4,tip-axis*10+normal*13,Color("b3864e",alpha),3)
		canvas.draw_line(tip+axis*5,tip+axis*12-normal*12,Color("b3864e",alpha),3)
	else:
		canvas.draw_circle(tip+axis,3.3,Color("26363d",alpha))
		canvas.draw_line(tip-axis*6-normal*7,tip+axis*7+normal*8,Color("d43c31",alpha),3)
	# The wet blade is visibly submerged; the wake remains on its own side.
	if float(p.wet)>.01:
		_ellipse(canvas,tip+Vector2(0,4),Vector2(25,10),Color(.69,.93,.94,.66*float(p.wet)*alpha),2)
		canvas.draw_line(tip+Vector2(-10,5),tip+Vector2(10,5),Color(.39,.70,.75,.7*float(p.wet)*alpha),3)
	if p.phase=="exit":
		for i in 3: canvas.draw_rect(Rect2(tip+Vector2((i-1)*7,9+i*5),Vector2(2,3)),Color(.75,.96,1,alpha*(1-float(p.lift)/9)))

func draw(canvas: CanvasItem,point: Vector2,zoom: float,pose: Dictionary,_elapsed_ms: float) -> void:
	_load()
	var heading: float=float(pose.get("heading",-PI/2))
	var speed: float=float(pose.get("speed",0))
	var forward:=clampf(maxf(0,speed)/360,0,1)
	var reverse:=clampf(maxf(0,-speed)/230,0,1)
	var unit: float=zoom*.52
	var alpha: float=float(pose.get("alpha",1))
	canvas.draw_set_transform(point,heading+PI/2,Vector2.ONE*unit)
	_ellipse(canvas,Vector2(0,72),Vector2(46,112)*(.68+forward*.9),Color(.66,.92,1,.3*forward*.44*alpha))
	_ellipse(canvas,Vector2(0,58),Vector2(32,78)*(.76+forward*.7),Color(.84,.98,1,.46*forward*.66*alpha))
	_ellipse(canvas,Vector2(0,-66),Vector2(44,94)*(.62+reverse*.96),Color(.74,.94,1,.36*reverse*.5*alpha))
	_ellipse(canvas,Vector2(0,-54),Vector2(30,68)*(.7+reverse*.82),Color(.91,.99,1,.5*reverse*.72*alpha))
	var roll:=clampf(float(pose.get("roll",0)),-1,1)
	var body_y: float=float(pose.get("bodyY",roll*5))
	var offset:=Vector2(0,body_y).rotated(heading+PI/2)*unit
	var body_scale: Vector2=pose.get("bodyScale",Vector2.ONE)
	var body_angle: float=float(pose.get("bodyAngle",roll*8))
	canvas.draw_set_transform(point+offset,heading+PI/2+deg_to_rad(body_angle),body_scale*unit)
	var tint:=Color(1,1,1,alpha*float(pose.get("bodyAlpha",1)))
	canvas.draw_texture_rect(layers.hull,Rect2(-64,-80,128,160),false,tint)
	canvas.draw_texture_rect(layers.seated_player,Rect2(Vector2(-64+roll*3,-80),Vector2(128,160)),false,tint)
	var paddles:=paddle_poses(pose)
	for side: String in ["left","right"]:
		var p: Dictionary=paddles[side]
		_paddle(canvas,side,p,tint.a)
		# Both joints and the gripping hand share the shaft's exact contact point.
		var arm:=PackedVector2Array([p.shoulder,p.elbow,p.grip])
		canvas.draw_polyline(arm,Color("493b32",tint.a),9,false)
		canvas.draw_polyline(arm,Color("e5b891",tint.a),6,false)
		canvas.draw_rect(Rect2(Vector2(p.grip)-Vector2(3,3),Vector2(6,6)),Color("e5b891",tint.a))
	canvas.draw_set_transform(Vector2.ZERO)
