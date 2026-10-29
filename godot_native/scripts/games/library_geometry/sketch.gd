extends Control
## Native vector geometry. Only the ink moves; card bounds never change.
var kind: int=0
var reduced:=false
var intro_age:=0.0
var intro_delay:=0.0
var intro_play:=true
var hovered:=false
var active:=false
var clock:=0.0
var activation_age:=10.0
var hold_left:=0.0
var amount:=0.0
var from_amount:=0.0
var target:=0.0
var transition_age:=1.0
var transition_duration:=1.0
var orbit_offset:=0.0
var dot_mesh:=ArrayMesh.new()
var dot_vertices:=PackedVector3Array()
var dot_uvs:=PackedVector2Array()
var dot_colors:=PackedColorArray()
static var dot_texture:GradientTexture2D
const INK=Color("393c38")
const PAPER=Color("fdfdfb")

func _ready()->void:
	custom_minimum_size=Vector2(202,202);size=custom_minimum_size
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	if dot_texture==null:
		dot_texture=GradientTexture2D.new();dot_texture.width=32;dot_texture.height=32
		dot_texture.fill=GradientTexture2D.FILL_RADIAL;dot_texture.fill_from=Vector2(.5,.5);dot_texture.fill_to=Vector2(1,.5)
		var fade=Gradient.new();fade.offsets=PackedFloat32Array([0,.70,1]);fade.colors=PackedColorArray([Color.WHITE,Color.WHITE,Color(1,1,1,0)])
		dot_texture.gradient=fade

static func ease_curve(t:float,move:bool=false)->float:
	# Solve the authored cubic-bezier x before evaluating its y.
	var a=.65 if move else .32
	var b=.35 if move else 0.0
	var lo=0.0;var hi=1.0
	for iteration:int in 12:
		var x=(lo+hi)/2
		var at=3*(1-x)*(1-x)*x*a+3*(1-x)*x*x*b+x*x*x
		if at<t:lo=x
		else:hi=x
	var u=(lo+hi)/2
	return 3*(1-u)*u*u+u*u*u

func ready_for_input()->bool:return reduced or not intro_play or intro_age>=1.45

func activate(timed:bool=false)->void:
	if reduced or not ready_for_input():return
	if active and not timed:return
	active=true;activation_age=0;hold_left=1.5 if timed else 0.0
	_transition(1.0)

func release()->void:
	active=false;hold_left=0;activation_age=10
	_transition(0.0);queue_redraw()

func _transition(value:float)->void:
	from_amount=amount;target=value;transition_age=0
	transition_duration=(.9 if kind==1 else 1.0) if value>0 else (.56 if kind==1 else .62)

func quiet()->void:
	var changed=hovered or active or amount!=0 or target!=0 or hold_left>0 or intro_age<2
	hovered=false;active=false;amount=0;target=0;hold_left=0;activation_age=10
	intro_age=2;transition_age=transition_duration
	if changed:queue_redraw()

func _needs_redraw()->bool:
	return (intro_play and intro_age<1.45) or transition_age<transition_duration or (active and (kind==0 or activation_age<(1.3 if kind==1 else 1.4)))

func tick(delta:float)->void:
	var was_moving=_needs_redraw()
	intro_age+=delta;clock+=delta
	if reduced:quiet();return
	if hovered and ready_for_input() and not active:activate()
	if active:activation_age+=delta
	if hold_left>0:
		hold_left=maxf(0,hold_left-delta)
		if hold_left==0:release()
	transition_age=minf(transition_duration,transition_age+delta)
	amount=lerpf(from_amount,target,ease_curve(clampf(transition_age/transition_duration,0,1),kind==1))
	if active and kind==0:orbit_offset+=delta*16.04
	if was_moving or _needs_redraw():queue_redraw()

func _ellipse(center:Vector2,rx:float,ry:float,tilt:float=0.0)->PackedVector2Array:
	var points=PackedVector2Array()
	for step:int in 129:
		var angle=TAU*step/128.0
		points.append(center+Vector2(cos(angle)*rx,sin(angle)*ry).rotated(tilt))
	return points

func _prefix(path:PackedVector2Array,portion:float)->PackedVector2Array:
	if portion>=.999:return path
	var total=0.0
	for i:int in range(1,path.size()):total+=path[i].distance_to(path[i-1])
	var left=total*maxf(0,portion);var result=PackedVector2Array()
	if left<=0:return result
	result.append(path[0])
	for i:int in range(1,path.size()):
		var length=path[i].distance_to(path[i-1])
		if length>left:
			result.append(path[i-1].lerp(path[i],left/maxf(.0001,length)));break
		result.append(path[i]);left-=length
	return result

func _solid(path:PackedVector2Array)->void:
	var ink=path
	if intro_play and not reduced:ink=_prefix(path,ease_curve(clampf((intro_age-intro_delay)/1.1,0,1)))
	if ink.size()>1:draw_polyline(ink,INK,.75,true)

func _dots(path:PackedVector2Array,alpha:float=1.0,offset:float=0.0)->void:
	var appear=1.0 if reduced or not intro_play else ease_curve(clampf((intro_age-intro_delay-.65)/.45,0,1))
	var color=Color(INK,.52*appear*alpha)
	if color.a<.001:return
	var next=fposmod(offset,4.0)
	for i:int in range(1,path.size()):
		var length=path[i].distance_to(path[i-1])
		while next<=length:
			_dot(path[i-1].lerp(path[i],next/maxf(.0001,length)),color)
			next+=4
		next-=length

func _dot(point:Vector2,color:Color)->void:
	# One shared radial primitive, batched into a single mesh for all guide dots.
	for corner:Vector2 in [Vector2(-1,-1),Vector2(1,-1),Vector2(1,1),Vector2(-1,-1),Vector2(1,1),Vector2(-1,1)]:
		var p=point+corner*.625
		dot_vertices.append(Vector3(p.x,p.y,0));dot_uvs.append((corner+Vector2.ONE)/2);dot_colors.append(color)

func _flush_dots()->void:
	if dot_vertices.is_empty():return
	var arrays=[];arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=dot_vertices;arrays[Mesh.ARRAY_TEX_UV]=dot_uvs;arrays[Mesh.ARRAY_COLOR]=dot_colors
	dot_mesh.clear_surfaces();dot_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	draw_mesh(dot_mesh,dot_texture)
	dot_vertices=PackedVector3Array();dot_uvs=PackedVector2Array();dot_colors=PackedColorArray()

func _draw()->void:
	if kind==0:_sphere()
	elif kind==1:_plates()
	else:_spiral()
	_flush_dots()

func _sphere()->void:
	var center=Vector2(101,101);var tilt=deg_to_rad(-18)
	_solid(_ellipse(center,88,88))
	for longitude:float in [30.0,150.0]:
		_solid(_ellipse(center,88*absf(sin(deg_to_rad(longitude)+amount*PI)),88,tilt))
	_solid(_ellipse(center,88,24,tilt))
	for y:float in [-48.0,48.0]:_solid(_ellipse(center+Vector2(0,y).rotated(tilt),72,20,tilt))
	_dots(_ellipse(center,97,26.5,tilt),1,orbit_offset)
	_dots(PackedVector2Array([center+Vector2(0,-99).rotated(tilt),center+Vector2(0,99).rotated(tilt)]))

func _plate_point(p:Vector2,layer:int,kick:float=0)->Vector2:
	return Vector2(101,101)+(p-Vector2(101,101))*.86+Vector2(kick,layer*14*amount)

func _plates()->void:
	for x_y:Vector2 in [Vector2(15,55),Vector2(131,55),Vector2(187,19),Vector2(71,19)]:
		_dots(PackedVector2Array([_plate_point(x_y,-1),_plate_point(x_y+Vector2(0,122),1)]))
	_flush_dots()
	for layer:int in 3:
		var y=55.0+layer*61.0
		var t=clampf((activation_age-layer*.06)/1.1,0,1)
		var wave=ease_curve(t/.32,true) if t<.32 else 1-ease_curve((t-.32)/.68,true)
		var kick=float([-12,14,-8][layer])*wave if active and t<1 else 0.0
		var front=_plate_point(Vector2(15,y),layer-1,kick)
		var right=_plate_point(Vector2(131,y),layer-1,kick)
		var back=_plate_point(Vector2(187,y-36),layer-1,kick)
		var left=_plate_point(Vector2(71,y-36),layer-1,kick)
		draw_colored_polygon(PackedVector2Array([front,right,back,left]),PAPER)
		_solid(PackedVector2Array([front,right,back,left,front]))
		_solid(PackedVector2Array([front,front+Vector2(0,5.16),right+Vector2(0,5.16),back+Vector2(0,5.16),back]))
		_solid(PackedVector2Array([right,right+Vector2(0,5.16)]))

func _spiral()->void:
	var center=Vector2(101,101)
	var tip=center+(Vector2(101,185)-center)*1.04
	var rim=center+(Vector2(101,31)-center)*1.04
	_dots(PackedVector2Array([rim+Vector2(-82*1.04,0),tip,rim+Vector2(82*1.04,0)]))
	_dots(PackedVector2Array([tip,center+(Vector2(101,8)-center)*1.04]))
	var progress=ease_curve(clampf(activation_age/1.4,0,1)) if active else 0.0
	var rim_alpha=1.0
	if active:
		rim_alpha=1.0-smoothstep(0.0,.24,progress) if progress<.55 else smoothstep(.55,.90,progress)
	var rim_scale=lerpf(.94,1.0,rim_alpha)
	_dots(_ellipse(rim,82*1.04*rim_scale,22.96*1.04*rim_scale),rim_alpha)
	_flush_dots()
	var path=PackedVector2Array()
	for step:int in 641:
		var t=step/640.0
		# Exact authored parametric helix, sampled finely for native vector ink.
		var angle=PI/2+t*TAU*5
		var radius=lerpf(6,82,t)
		var p=Vector2(101+cos(angle)*radius,183-152*t-sin(angle)*radius*.28)
		path.append(center+(p-center)*1.04)
	if active and progress<1:
		# Equivalent to the normalized SVG dash moving through two lengths:
		# remove from the bottom, then grow from that same bottom again.
		if progress<.5:
			var removed=_prefix(path,progress*2)
			if removed.size()>0:
				var start=maxi(0,removed.size()-1)
				_solid(path.slice(start))
		else:_solid(_prefix(path,(progress-.5)*2))
	else:_solid(path)
