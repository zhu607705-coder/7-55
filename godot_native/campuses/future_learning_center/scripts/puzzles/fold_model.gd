extends RefCounted
## Continuous cross-section of one folding sample. All distances are apparatus pixels.
const HINGES := [Vector2(300,300),Vector2(550,288)]
const LENGTHS := [130.0,250.0]
const HALF_THICKNESS := 3.0
const CABLE_RADIUS := 3.0
const ATTACHMENT := Rect2(410,307,34,16)
const TEMPLATE := Rect2(294,282,262,62)
var angles: Array[float] = [0.0,0.0]
var route := 0
var connected := true
var attachment := false
var revision := 0
var trial_revision := -1
var operated := false
var running := false
var elapsed := 0.0
var completed := false
var extension_completed := false
var contact := Vector2.INF
var contact_kind := ""
var outcome := ""
var history: Array[Dictionary] = []
var proofs: Array[Dictionary] = []
var _gesture: Dictionary = {}

func tip(leaf:int,angle:float=-1)->Vector2:
	var a:float=angles[leaf] if angle<0 else angle
	return HINGES[leaf]+Vector2((-1 if leaf==0 else 1)*cos(a),-sin(a))*LENGTHS[leaf]
func cable_path(which:int=-1)->PackedVector2Array:
	var r:int=route if which<0 else which
	if r==0:return PackedVector2Array([Vector2(315,318),Vector2(350,270),Vector2(535,318)])
	if r==1:return PackedVector2Array([Vector2(315,318),Vector2(535,318)])
	return PackedVector2Array([Vector2(315,318),Vector2(315,340),Vector2(535,340),Vector2(535,318)])
func _segment_gap(a:Vector2,b:Vector2,c:Vector2,d:Vector2)->float:
	var hit=Geometry2D.segment_intersects_segment(a,b,c,d)
	if hit!=null:return 0.0
	return minf(minf(a.distance_to(Geometry2D.get_closest_point_to_segment(a,c,d)),b.distance_to(Geometry2D.get_closest_point_to_segment(b,c,d))),minf(c.distance_to(Geometry2D.get_closest_point_to_segment(c,a,b)),d.distance_to(Geometry2D.get_closest_point_to_segment(d,a,b))))
func _contact_between(a:Vector2,b:Vector2,c:Vector2,d:Vector2)->Vector2:
	var hit=Geometry2D.segment_intersects_segment(a,b,c,d)
	if hit!=null:return hit
	var best:=INF
	var point:=c
	for pair:Array in [[a,Geometry2D.get_closest_point_to_segment(a,c,d)],[b,Geometry2D.get_closest_point_to_segment(b,c,d)],[Geometry2D.get_closest_point_to_segment(c,a,b),c],[Geometry2D.get_closest_point_to_segment(d,a,b),d]]:
		var distance:float=pair[0].distance_to(pair[1])
		if distance<best:best=distance;point=(pair[0]+pair[1])/2
	return point
func _rect_hit(a:Vector2,b:Vector2,rect:Rect2,radius:float)->bool:
	var r:=rect.grow(radius)
	if r.has_point(a) or r.has_point(b):return true
	var p:=[r.position,Vector2(r.end.x,r.position.y),r.end,Vector2(r.position.x,r.end.y)]
	for i:int in 4:
		if Geometry2D.segment_intersects_segment(a,b,p[i],p[(i+1)%4])!=null:return true
	return false
func cable_pinched()->bool:
	if not connected or not attachment:return false
	var path:=cable_path()
	for i:int in range(1,path.size()):
		if _rect_hit(path[i-1],path[i],ATTACHMENT,CABLE_RADIUS):return true
	return false
func legal(leaf:int,angle:float)->bool:
	var start:Vector2=HINGES[leaf];var end:=tip(leaf,angle)
	var other:=1-leaf
	if _segment_gap(start,end,HINGES[other],tip(other))<=HALF_THICKNESS*2:
		contact=_contact_between(start,end,HINGES[other],tip(other));contact_kind="leaf";return false
	if attachment and _rect_hit(start,end,ATTACHMENT,HALF_THICKNESS):
		contact=ATTACHMENT.get_center();contact_kind="attachment";return false
	if connected:
		var path:=cable_path()
		for i:int in range(1,path.size()):
			if _segment_gap(start,end,path[i-1],path[i])<=HALF_THICKNESS+CABLE_RADIUS:
				contact=_contact_between(start,end,path[i-1],path[i]);contact_kind="cable";return false
	return true
func snapshot()->Dictionary:return {"angles":angles.duplicate(),"route":route,"connected":connected,"attachment":attachment}
func begin_gesture()->void:
	if _gesture.is_empty():_gesture=snapshot()
func end_gesture()->void:
	if not _gesture.is_empty() and _gesture!=snapshot():
		history.append(_gesture)
		if history.size()>40:history.pop_front()
	_gesture={}
func cancel_pointer()->void:end_gesture()
func stop()->void:running=false;elapsed=0;end_gesture()
func _invalidate()->void:
	revision+=1;trial_revision=-1;operated=false;running=false;elapsed=0;outcome=""
func fully_open()->bool:return angles[0]<.015 and angles[1]<.015
func change_route(value:int)->bool:
	if value not in [0,1,2] or not fully_open():return false
	if route==value:return true
	begin_gesture();route=value;_invalidate();end_gesture();return true
func set_connected(value:bool)->bool:
	if value==connected:return true
	# A cable can only be fitted while its full route is accessible.
	if value and not fully_open():return false
	begin_gesture();connected=value;_invalidate();end_gesture();return true
func set_attachment(value:bool)->bool:
	if not fully_open():return false
	if value==attachment:return true
	begin_gesture();attachment=value;_invalidate();end_gesture();return true
func undo()->bool:
	end_gesture()
	if history.is_empty():return false
	var old:Dictionary=history.pop_back()
	angles.assign(old.angles);route=old.route;connected=old.connected;attachment=old.attachment
	_invalidate();contact=Vector2.INF;contact_kind="";return true
func start()->bool:
	if running:return false
	operated=false;trial_revision=-1;contact=Vector2.INF;contact_kind=""
	if not connected:outcome="连接带已拔下";return false
	if not fully_open():outcome="盖片尚未完全展开";return false
	if cable_pinched():contact=ATTACHMENT.get_center();contact_kind="cable";outcome="附件压住连接带";return false
	if not legal(0,angles[0]) or not legal(1,angles[1]):outcome="物件发生接触";return false
	running=true;elapsed=0;outcome="";return true
func step(dt:float)->void:
	if not running or not is_finite(dt) or dt<=0:return
	elapsed=minf(.6,elapsed+dt)
	if elapsed>=.6:
		running=false;operated=true;trial_revision=revision;outcome="展开试验：灯亮"
func envelope_fits()->bool:
	for leaf:int in 2:
		for point:Vector2 in [HINGES[leaf],tip(leaf)]:
			if not TEMPLATE.grow(-HALF_THICKNESS).has_point(point):return false
	return true
func swing_to(leaf:int,target:float)->bool:
	if leaf not in [0,1] or not is_finite(target):return false
	if running:stop()
	var delta:=clampf(target,0,PI)-angles[leaf]
	var count:=ceili(absf(delta)/.002)
	if count==0:return false
	contact=Vector2.INF;contact_kind=""
	var increment:=delta/count
	var moved:=false
	for i:int in count:
		var next:=angles[leaf]+increment
		if not legal(leaf,next):break
		angles[leaf]=next;moved=true
	if operated and trial_revision==revision and connected and not cable_pinched() and envelope_fits():
		completed=true
		if attachment:extension_completed=true
		if proofs.is_empty() or proofs[-1].revision!=revision:
			proofs.append({"revision":revision,"attachment":attachment,"angles":angles.duplicate(),"route":route})
		outcome="同一样机已通过收纳模板"
	return moved
