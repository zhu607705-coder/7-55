extends RefCounted
## Articulated paper leaves; the opening is the model's physical variable.
static func factor(object:Dictionary)->float:return float(object.get("radius",.45))/.45
static func pivot(foot:Vector2,object:Dictionary)->Vector2:return foot+Vector2(0,-24)*factor(object)
static func grip(foot:Vector2,object:Dictionary)->Vector2:
	var angle:float=deg_to_rad(15+60*float(object.get("spread",1.0)))
	return pivot(foot,object)+Vector2(sin(angle),-cos(angle))*58*factor(object)

static func draw(canvas:CanvasItem,foot:Vector2,object:Dictionary,selected:bool,clock:float,reduced:bool)->void:
	var size:float=factor(object);var center:Vector2=pivot(foot,object)
	var extent:float=deg_to_rad(15+60*float(object.spread))
	var radius:float=58*size
	var paper:PackedColorArray=PackedColorArray([Color("E5D7B4"),Color("C5C1A9"),Color("E5D7B4"),Color("F4EAD5")])
	canvas.draw_line(foot,center,Color("665C42"),5*size)
	for index:int in 10:
		var first:float=lerpf(-extent,extent,float(index)/10)
		var second:float=lerpf(-extent,extent,float(index+1)/10)
		var a:Vector2=center+Vector2(sin(first),-cos(first))*radius
		var b:Vector2=center+Vector2(sin(second),-cos(second))*radius
		canvas.draw_colored_polygon(PackedVector2Array([center,a,b]),paper[index%4])
		canvas.draw_line(center,a,Color("9D875E"),maxf(1,.9*size))
		canvas.draw_line(a,b,Color("665C42"),1.5*size)
		# A broad red stitch travels with its leaf; no noisy stipple.
		if index in [2,3,6,7]:canvas.draw_line(center.lerp(a,.72),center.lerp(b,.72),Color("9A514A"),2.0*size)
	var outer:Vector2=grip(foot,object)
	canvas.draw_line(center,outer,Color("665C42"),3*size)
	canvas.draw_circle(center,3.5*size,Color("C2A46F"))
	canvas.draw_circle(outer,6.0*size,Color("665C42"))
	canvas.draw_circle(outer,3.5*size,Color("E5D7B4"))
	if selected:
		var glow:float=1.0 if reduced else .75+.25*sin(clock*3)
		canvas.draw_arc(outer,10*size,0,TAU,24,Color(0.89,.76,.55,glow),1.2)
	canvas.draw_line(foot+Vector2(-24,1),foot+Vector2(24,1),Color("362E35"),6)
	canvas.draw_circle(foot+Vector2(-18,6),4,Color("9D875E"));canvas.draw_circle(foot+Vector2(18,6),4,Color("9D875E"))
