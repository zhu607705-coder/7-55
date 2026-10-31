extends RefCounted
## Isolated optical teaching model. No chapter, inventory or save writes.
## Coordinates are apparatus coordinates; the room/camera never rotates.
const SLOT_POINTS:=[Vector2(-110,0),Vector2(0,-110),Vector2(110,0),Vector2(0,110)]
var slots:Array[int]=[-1,-1]
var configuration_revision:=0
var fixture_revision:=0
var quarter_turn:=0
var condition:=0
var receipts:Dictionary={}
var history:Array[Dictionary]=[]
var completed:=false
var running:=false
var paused:=false
var trial:=""
var elapsed:=0.0
var travel:=0.0
var outcome:=""
var trial_revision:=Vector2i.ZERO
var trial_condition:=0

func version()->Vector2i:return Vector2i(configuration_revision,fixture_revision)
func rotate_point(point:Vector2)->Vector2:return point.rotated(quarter_turn*PI/2)
func slot_segment(index:int)->Array[Vector2]:
	var p:Vector2=SLOT_POINTS[index]
	var tangent:=Vector2(0,58) if index%2==0 else Vector2(58,0)
	return [p-tangent,p+tangent]
func path_blocker(from:Vector2,to:Vector2)->int:
	for i:int in 2:
		if slots[i]<0:continue
		var edge:=slot_segment(slots[i])
		if Geometry2D.segment_intersects_segment(from,to,edge[0],edge[1])!=null:return i
	return -1
func light_blocked(side:int)->bool:
	return path_blocker(rotate_point(Vector2(-210 if side==0 else 210,0)),Vector2.ZERO)>=0
func camera_clear()->bool:
	return path_blocker(rotate_point(Vector2(0,-210)),Vector2.ZERO)<0
func feed_clear()->bool:
	# The carriage width is checked at both swept edges, not only its centre.
	for offset:float in [-18.0,0.0,18.0]:
		if path_blocker(rotate_point(Vector2(offset,210)),rotate_point(Vector2(offset,0)))>=0:return false
	return true
func feed_stop_fraction()->float:return (210.0-110.0-18.0)/210.0
func _invalidate()->void:
	cancel();receipts.clear();outcome="";travel=0
func place(baffle:int,slot:int)->bool:
	if baffle not in [0,1] or slot not in [-1,0,1,2,3]:return false
	if slots[baffle]==slot:return true
	if slot>=0 and slots[1-baffle]==slot:return false
	slots[baffle]=slot;configuration_revision+=1;_invalidate();return true
func rotate_fixture()->void:
	quarter_turn=(quarter_turn+1)%4;fixture_revision+=1;_invalidate()
func set_condition(side:int)->bool:
	if side not in [0,1] or running:return false
	condition=side;return true
func start(kind:String)->bool:
	if running or kind not in ["photo","feed"]:return false
	running=true;paused=false;trial=kind;elapsed=0;outcome=""
	trial_revision=version();trial_condition=condition
	if kind=="feed":travel=0
	return true
func pause()->void:
	if running:paused=true
func resume()->void:paused=false
func cancel()->void:running=false;paused=false;trial="";elapsed=0
func step(dt:float)->void:
	if not running or paused or not is_finite(dt) or dt<=0:return
	elapsed+=minf(dt,.1)
	if trial=="feed":
		travel=minf(elapsed/2.4,1.0 if feed_clear() else feed_stop_fraction())
		if elapsed>=2.4 or (not feed_clear() and travel>=feed_stop_fraction()):_finish("feed",feed_clear())
	elif elapsed>=.65:
		_finish("photo_a" if trial_condition==0 else "photo_b",light_blocked(trial_condition) and camera_clear())
func _finish(kind:String,passed:bool)->void:
	if trial_revision!=version():cancel();return
	var result:={"kind":kind,"passed":passed,"configuration_revision":configuration_revision,"fixture_revision":fixture_revision,"condition":trial_condition,"camera_clear":camera_clear(),"light_blocked":light_blocked(trial_condition)}
	history.append(result.duplicate(true));receipts[kind]=result
	if kind=="feed":outcome="送料到达标记" if passed else "送料件碰到挡片"
	else:outcome="画面清晰" if passed else ("挡片遮住镜头" if not camera_clear() else "侧光落在标记上")
	running=false;trial=""
	completed=completed or current_passed()
func current_passed()->bool:
	for key:String in ["photo_a","photo_b","feed"]:
		if not receipts.has(key):return false
		var r:Dictionary=receipts[key]
		if not r.passed or r.configuration_revision!=configuration_revision or r.fixture_revision!=fixture_revision:return false
	return camera_clear()
