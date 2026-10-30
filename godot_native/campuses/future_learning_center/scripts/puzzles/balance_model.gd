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
	if running:return false
	running=true;paused=false;stage="lift";elapsed=0;held=false;delivered=false;travel=0;lift_revision=-1;outcome="";return true
func start_delivery()->bool:
	if running or not held or lift_revision!=revision or not balanced():return false
	running=true;paused=false;stage="carry";elapsed=0;travel=0;outcome="";return true
func pause()->void:paused=true
func resume()->void:paused=false
func cancel()->void:
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
	elif stage=="carry":
		if lift_revision!=revision or not balanced():cancel();outcome="摆位改变，重新试提";return
		travel=minf(elapsed/1.1,1)
		if travel>=1:
			running=false;held=false;delivered=true;elevation=0;completed=true;outcome="四杯稳稳送达"
			if pivot>0:extension_completed=true
