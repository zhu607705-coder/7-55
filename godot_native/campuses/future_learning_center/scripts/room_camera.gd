extends RefCounted
## The Camera2D receives one smoothed room/corridor framing state. Variable
## room bounds and zoom blend together; no frame-dependent lerp constants.
const Body=preload("res://scripts/player_metrics.gd")
const VIEW:=Vector2(960,540)
var center:=Vector2.ZERO
var zoom:=.9
var bounds:=Rect2()
var focus:=Vector2.ZERO
var room_id:=""
var initialized:=false

func clamp_center(point:Vector2,area:Rect2,value:float)->Vector2:
	var half:=VIEW/(2.0*value)
	var result:=point
	for axis:int in 2:
		if area.size[axis]<=half[axis]*2:result[axis]=area.get_center()[axis]
		else:result[axis]=clampf(result[axis],area.position[axis]+half[axis],area.end[axis]-half[axis])
	return result

func update(dt:float,anchor:Vector2,space:RefCounted,snap:=false,overview:=false)->void:
	var foot:=anchor+Body.FOOT_CENTER_OFFSET
	var room:Dictionary=space.room_at(foot)
	var target_bounds:Rect2=space.focus_bounds(room)
	var target_zoom:=.82
	if not room.is_empty():target_zoom=maxf(VIEW.x/target_bounds.size.x,VIEW.y/target_bounds.size.y)*1.02
	# A furnished room may request a closer view; the same bounds, deadzone and
	# foot-anchored follow still apply. Other rooms keep their original framing.
	if room.has("cameraZoom"):target_zoom=maxf(target_zoom,float(room.cameraZoom))
	if overview:
		target_bounds=space.world_bounds;target_zoom=minf(VIEW.x/target_bounds.size.x,VIEW.y/target_bounds.size.y)*.94
	if not initialized or snap:
		bounds=target_bounds;zoom=target_zoom;focus=anchor;center=clamp_center(anchor,bounds,zoom);initialized=true
	if room_id!=str(room.get("id","")):
		room_id=str(room.get("id",""));focus=anchor
	var t:=1.0-exp(-8.0*dt)
	zoom=lerpf(zoom,target_zoom,t)
	bounds=Rect2(bounds.position.lerp(target_bounds.position,t),bounds.size.lerp(target_bounds.size,t))
	var diff:=anchor-focus
	var dead:=Vector2(72,44)/zoom
	for axis:int in 2:focus[axis]+=maxf(0,absf(diff[axis])-dead[axis])*signf(diff[axis])
	var desired:Vector2=target_bounds.get_center() if overview else clamp_center(focus,bounds,zoom)
	center=center.lerp(desired,1.0-exp(-10.0*dt))
	center=clamp_center(center,bounds,zoom)
	if not overview:
		# Even during a door blend, the complete visual actor stays in view.
		var actor:Rect2=Body.visual_rect(anchor).grow(18)
		var half:=VIEW/(2.0*zoom)
		center.x=clampf(center.x,actor.end.x-half.x,actor.position.x+half.x)
		center.y=clampf(center.y,actor.end.y-half.y,actor.position.y+half.y)
		center=clamp_center(center,space.world_bounds,zoom)

func visible_rect()->Rect2:return Rect2(center-VIEW/(2*zoom),VIEW/zoom)
