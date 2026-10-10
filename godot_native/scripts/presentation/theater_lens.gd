extends RefCounted
## Fixed funhouse lens. The same display->source polynomial is used by the
## shader and input. No time dependence, camera shake, or gameplay mutation.
const CENTER:=Vector2(480,270)
const EXTENT:=Vector2(480,270)
static func sample_point(display:Vector2)->Vector2:
	var p:Vector2=(display-CENTER)/EXTENT
	var x:float=p.x*(1.0+0.075*p.y*p.y)+0.026*p.y*p.y+0.014*p.x*p.x
	var y:float=p.y+0.16*p.x*p.x*(0.34+p.y)+0.033*p.x*p.x*p.x
	return CENTER+Vector2(x,y)*EXTENT
static func display_point(source:Vector2)->Vector2:
	var p:Vector2=source
	for i in 9:
		var residual:Vector2=sample_point(p)-source
		if residual.length_squared()<0.0000001:break
		var dx:Vector2=(sample_point(p+Vector2(.1,0))-sample_point(p-Vector2(.1,0)))/.2
		var dy:Vector2=(sample_point(p+Vector2(0,.1))-sample_point(p-Vector2(0,.1)))/.2
		var determinant:float=dx.x*dy.y-dy.x*dx.y
		if absf(determinant)<.001:break
		p-=Vector2(dy.y*residual.x-dy.x*residual.y,-dx.y*residual.x+dx.x*residual.y)/determinant
	return p
