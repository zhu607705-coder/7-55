extends RefCounted
const WEIGHTS:=[1,1,2,2]
const ARMS:=[-2.0,-1.0,1.0,2.0]
const TOLERANCE:=.2
var slots:Array[int]=[0,1,2,3]
var pivot:=0.0
var revision:=0
var lift_revision:=-1
var completed:=false
var extension_completed:=false
var held:=false
var delivered:=false
var running:=false
var paused:=false
var stage:=""
var elapsed:=0.0
var tilt:=0.0
var elevation:=0.0
var travel:=0.0
var outcome:=""
var history:Array[Dictionary]=[]
func torque()->float:
	var result:=0.0
	for i:int in 4:result+=WEIGHTS[slots[i]]*(ARMS[i]-pivot)
	return result
func balanced()->bool:return absf(torque())<=TOLERANCE
func place(cup:int,slot:int)->bool:
	if cup<0 or cup>3 or slot<0 or slot>3:return false
	var old:int=slots.find(cup)
	if old==slot:return true
	history.append({"slots":slots.duplicate(),"pivot":pivot})
	slots[old]=slots[slot];slots[slot]=cup;_invalidate();return true
func set_extension(value:bool)->void:
	var next:=1.0/6.0 if value else 0.0
	if is_equal_approx(pivot,next):return
	history.append({"slots":slots.duplicate(),"pivot":pivot});pivot=next;_invalidate()
func _invalidate()->void:revision+=1;cancel();delivered=false;travel=0;outcome=""
func undo()->bool:
	if history.is_empty():return false
	var old:Dictionary=history.pop_back();slots.assign(old.slots);pivot=old.pivot;_invalidate();return true
func start_lift()->bool:
	if running or drag_active:return false
	running=true;paused=false;stage="lift";elapsed=0;held=false;delivered=false;travel=0;lift_revision=-1;outcome="";return true
func start_delivery()->bool:
	if running or drag_active or not held or lift_revision!=revision or not balanced():return false
	running=true;paused=false;stage="carry";elapsed=0;travel=0;outcome="";return true
func pause()->void:paused=true
func resume()->void:paused=false
func cancel()->void:
	cancel_drag()
	running=false;paused=false;held=false;stage="";elapsed=0;lift_revision=-1;tilt=0;elevation=0
	if not delivered:travel=0
func step(dt:float)->void:
	if paused or not running or not is_finite(dt) or dt<=0:return
	elapsed+=minf(dt,.1)
	if stage=="lift":
		elevation=minf(elapsed/.8,1)*22
		tilt=clampf(torque()*.085,-.3,.3)*minf(elapsed/.6,1)
		if elapsed>=.8:
			running=false
			if balanced():held=true;lift_revision=revision;outcome="提手受力稳定"
			else:held=false;lift_revision=-1;outcome="托盘倾斜，先停住"
	elif stage=="settle":
		if lift_revision!=revision or not balanced():cancel();return
		if elapsed>=.18:
			running=false;held=false;delivered=true;elevation=0;travel=1;stage="";completed=true;outcome="四杯稳稳落在茶几上"
			if pivot>0:extension_completed=true
	elif stage=="carry":
		if lift_revision!=revision or not balanced():cancel();outcome="摆位改变，重新试提";return
		travel=minf(elapsed/1.1,1)
		if travel>=1:
			running=false;held=false;delivered=true;elevation=0;completed=true;outcome="四杯稳稳送达"
			if pivot>0:extension_completed=true

const SOURCE_CENTER:=Vector2(315,310)
const TARGET_CENTER:=Vector2(750,308)
var drag_active:=false
var dragged_center:=SOURCE_CENTER
var carry_origin:=SOURCE_CENTER
var carry_travel:=0.0
var settle_origin:=SOURCE_CENTER
func display_center()->Vector2:
	if drag_active:return dragged_center
	if stage=="settle":return settle_origin.lerp(TARGET_CENTER,minf(elapsed/.18,1))
	return SOURCE_CENTER.lerp(TARGET_CENTER,travel)-Vector2(0,elevation)
func begin_drag()->bool:
	if running or not held or lift_revision!=revision or not balanced():return false
	carry_origin=display_center();carry_travel=travel;dragged_center=carry_origin;drag_active=true;return true
func move_drag(at:Vector2)->bool:
	if not drag_active or not at.is_finite() or not Rect2(205,170,620,230).has_point(at):return false
	dragged_center=at;travel=clampf((at.x-SOURCE_CENTER.x)/(TARGET_CENTER.x-SOURCE_CENTER.x),0,1);return true
func cancel_drag()->void:
	if not drag_active:return
	drag_active=false;travel=carry_travel
func settle_drag()->bool:
	if not drag_active or dragged_center.distance_to(TARGET_CENTER)>18 or lift_revision!=revision or not balanced():return false
	settle_origin=dragged_center;drag_active=false;stage="settle";elapsed=0;running=true;paused=false;return true
