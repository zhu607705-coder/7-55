extends RefCounted
## A reversible traversal inside the isolated architecture review. It owns no save.
const Body=preload("res://scripts/player_metrics.gd")
const VIEW:=Vector2(960,540)
var spec:Dictionary
var points:=PackedVector2Array()
var lengths:=PackedFloat32Array()
var total:=0.0
var distance:=0.0
var direction:=1
var active:=false
var paused:=false
var arrived:=false
var delivered:=false
var source_floor:=0
var target_floor:=0
var via:=""
var center:=Vector2.ZERO
var zoom:=.95

func _init()->void:
	spec=JSON.parse_string(FileAccess.get_file_as_string("res://campuses/future_learning_center/data/stair_section.json"))
	for q:Array in spec.points:points.append(Vector2(q[0],q[1]))
	lengths.append(0)
	for i:int in range(1,points.size()):
		total+=points[i-1].distance_to(points[i]);lengths.append(total)
	zoom=float(spec.zoom)

func start(from:int,to:int,landing:String)->bool:
	if active or from not in [2,3,4] or to not in [2,3,4] or absi(to-from)!=1:return false
	if landing not in ["northeast_stair","southwest_stair"]:return false
	source_floor=from;target_floor=to;via=landing;direction=1 if to>from else -1
	distance=0 if direction==1 else total;active=true;paused=false;arrived=false;delivered=false
	center=camera_target();return true

func point_at(value:float)->Vector2:
	value=clampf(value,0,total)
	for i:int in range(1,points.size()):
		if value<=lengths[i]:return points[i-1].lerp(points[i],(value-lengths[i-1])/(lengths[i]-lengths[i-1]))
	return points[-1]

func foot()->Vector2:return point_at(distance)
func tangent()->Vector2:return (point_at(distance+direction*3)-point_at(distance-direction*3)).normalized()
func progress()->float:return distance/total if direction==1 else 1.0-distance/total
func on_upper_flight()->bool:return distance>=lengths[14]

func camera_target()->Vector2:
	# The same plate/zoom for both directions; look along the next flight, never
	# mirror the building or invent a second projection for descent.
	var ahead:=point_at(distance+direction*125)
	var desired:=foot().lerp(ahead,.75)+Vector2(0,-40)
	var half:=VIEW/(2*zoom);var extent:=Vector2(spec.size[0],spec.size[1])
	return desired.clamp(half,extent-half)

func step(dt:float)->bool:
	if not active or paused:return false
	distance=clampf(distance+direction*float(spec.speed)*maxf(0,dt),0,total)
	center=center.lerp(camera_target(),1-exp(-8*maxf(0,dt)))
	if (direction==1 and distance>=total) or (direction==-1 and distance<=0):
		active=false;arrived=true;return true
	return false

func take_arrival()->Dictionary:
	if not arrived or delivered:return {}
	delivered=true
	return {"source":source_floor,"floor":target_floor,"via":via}

func cancel()->void:active=false;paused=false;arrived=false;delivered=true
func pause()->void:
	if active:paused=true
func resume()->void:
	if active:paused=false

func foot_supported(at:Vector2)->bool:
	# Test the full shared foot rectangle against the union of measured treads.
	var half:=Body.FOOT_SIZE/2
	for offset:Vector2 in [Vector2(-half.x,-half.y),Vector2(half.x,-half.y),Vector2(half.x,half.y),Vector2(-half.x,half.y),Vector2.ZERO]:
		var found:=false
		for r:Array in spec.ground:
			if Rect2(r[0],r[1],r[2],r[3]).has_point(at+offset):found=true;break
		if not found:return false
	return true
