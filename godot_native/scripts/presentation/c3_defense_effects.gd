extends RefCounted
## CanteenInteriorScene.flashDefenseRoute/onTurnaround, presentation-only.
## Contact positions are copied after the source model resolves its34px recoil.
const LINE_COLOR=Color("78ddff")
const DOT_COLOR=Color("dff9ff")
const SHAKE_INTENSITY: float=0.0025
var reduced: bool=false
var contact_count: int=0
var points:=PackedVector2Array()
var age_ms: float=0.0
var duration_ms: float=760.0
var shake_age_ms: float=75.0

func reset(reduce: bool=false) -> void:
	reduced=reduce; contact_count=0; points.clear(); age_ms=0
	duration_ms=420.0 if reduced else 760.0
	shake_age_ms=75.0

func observe(run: RefCounted) -> void:
	if int(run.turnarounds)==contact_count: return
	if int(run.turnarounds)<contact_count:
		reset(reduced)
		return
	contact_count=int(run.turnarounds)
	# killTweensOf(graphics) + clear: replace rather than layer repeated flashes.
	points=PackedVector2Array([run.paper])
	for point: Vector2 in run.route: points.append(point)
	age_ms=0
	# Phaser shake(force=false) ignores a second shake while one is running.
	if shake_age_ms>=75.0: shake_age_ms=75.0 if reduced else 0.0

func advance(milliseconds: float) -> void:
	if not is_finite(milliseconds) or milliseconds<=0: return
	age_ms=minf(duration_ms,age_ms+milliseconds)
	shake_age_ms=minf(75.0,shake_age_ms+milliseconds)
	if age_ms>=duration_ms: points.clear()

func snapshot() -> Dictionary:
	var alpha: float=0.95*(1-clampf(age_ms/duration_ms,0,1)) if not points.is_empty() else 0.0
	var dots:=PackedVector2Array()
	# points[0] is the paper; route index0 is points[1].
	for index: int in range(1,points.size(),2): dots.append(points[index])
	return {"points":points.duplicate(),"dots":dots,"alpha":alpha,"line_color":Color(LINE_COLOR,0.88*alpha),"dot_color":Color(DOT_COLOR,0.9*alpha),"width":5.0,"radius":5.0}

func camera_offset(viewport: Vector2,zoom: float) -> Vector2:
	if reduced or shake_age_ms<=0 or shake_age_ms>=75.0: return Vector2.ZERO
	# Same bounded75ms source envelope, without consuming model/global RNG.
	# A fixed visual noise sample is shared by all paints of a simulation frame.
	var frame: float=floorf(shake_age_ms/(1000.0/60.0))
	var x: float=fposmod(sin(frame*12.9898+contact_count*78.233)*43758.5453,1)*2-1
	var y: float=fposmod(sin(frame*39.3467+contact_count*11.135)*24634.6345,1)*2-1
	# Source camera has roundPixels=true: Shake.update rounds its already
	# zoom-scaled translation, then Camera.preRender composes the camera matrix.
	var translation: Vector2=Vector2(x,y)*viewport*SHAKE_INTENSITY*zoom
	translation=Vector2(floorf(translation.x+0.5),floorf(translation.y+0.5))
	return translation*zoom

func draw(canvas: CanvasItem) -> void:
	var pose:=snapshot()
	if pose.points.size()>1: canvas.draw_polyline(pose.points,pose.line_color,pose.width)
	for point: Vector2 in pose.dots: canvas.draw_circle(point,pose.radius,pose.dot_color)
