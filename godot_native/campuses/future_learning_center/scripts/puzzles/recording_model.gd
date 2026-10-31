extends RefCounted
## A round tracks real travel. Moving the light baffle after arrival is allowed.
const START:=220.0
const END:=670.0
var x:=START
var baffle_y:=300.0
var direction:=0
var running:=false
var paused:=false
var photographing:=false
var exposure:=0.0
var round_id:=0
var round_started:=false
var reached_round:=-1
var photo_round:=-1
var revision:=0
var completed:=false
var history:Array[Dictionary]=[]
var outcome:=""
var contact:=Vector2.INF
var photo_kind:=""
func carriage(at:float)->Rect2:return Rect2(at-18,284,36,32)
func baffle(at:float)->Rect2:return Rect2(430,at-60,22,120)
func light_blocked()->bool:
 var r:=baffle(baffle_y)
 var a:=Vector2(320,260);var b:=Vector2(END,300)
 var pts:=[r.position,Vector2(r.end.x,r.position.y),r.end,Vector2(r.position.x,r.end.y)]
 for i:int in 4:
  if Geometry2D.segment_intersects_segment(a,b,pts[i],pts[(i+1)%4])!=null:return true
 return false
func move_baffle(value:float)->bool:
 if not is_finite(value) or value<150 or value>300:return false
 var start:=baffle_y
 var steps:=maxi(1,ceili(absf(value-start)/2))
 var blocked:=false
 contact=Vector2.INF
 for i:int in range(1,steps+1):
  var next:=lerpf(start,value,float(i)/steps)
  if baffle(next).intersects(carriage(x)):
   var low:=baffle_y;var high:=next
   for _refine:int in 16:
    var mid:float=(low+high)*.5
    if baffle(mid).intersects(carriage(x)):high=mid
    else:low=mid
   baffle_y=low;contact=Vector2(441,high+(60 if value>start else -60));blocked=true;break
  baffle_y=next
 if not is_equal_approx(baffle_y,start):revision+=1;photographing=false;exposure=0
 outcome="挡片碰到送料件，不能穿过去。" if blocked else ""
 return not blocked
func drive(value:int)->void:
 if value not in [-1,0,1]:return
 photographing=false;exposure=0;direction=value;running=value!=0;paused=false;contact=Vector2.INF
 if value>0 and not round_started and is_equal_approx(x,START):
  round_id+=1;round_started=true;reached_round=-1;photo_round=-1
 if value<0:
  reached_round=-1;photo_round=-1;round_started=false
func advance(distance:float)->void:
 if not is_finite(distance) or distance==0:return
 var target:=clampf(x+distance,START,END)
 var steps:=maxi(1,ceili(absf(target-x)/2))
 var old:=x
 for i:int in range(1,steps+1):
  var next:=lerpf(old,target,float(i)/steps)
  if carriage(next).intersects(baffle(baffle_y)):
   running=false;direction=0;contact=Vector2(430,300);outcome="送料件停在挡片前。";return
  x=next
 if is_equal_approx(x,END):
  running=false;direction=0
  if round_started:reached_round=round_id
  outcome="送料件抵住终端止挡。"
 elif is_equal_approx(x,START):running=false;direction=0;round_started=false;outcome="送料件已退回起点。"
func nudge(value:int)->void:
 drive(value);advance(value*18);running=false;direction=0
func pause()->void:
 # Focus loss cancels motion; the workpiece remains at its physical position.
 running=false;direction=0;photographing=false;paused=false;exposure=0
func resume()->void:paused=false
func cancel()->void:pause()
func shutter()->bool:
 if running or photographing:return false
 photographing=true;exposure=0;outcome="";return true
func step(dt:float)->void:
 if not is_finite(dt) or dt<=0:return
 var delta:=minf(dt,.1)
 if running:advance(direction*70*delta)
 if photographing:
  exposure+=delta
  if exposure>=.6:
   photographing=false
   var arrived:=is_equal_approx(x,END) and reached_round==round_id and round_started
   var shaded:=light_blocked()
   var good:=arrived and shaded
   photo_kind="clear" if good else ("glare" if not shaded else "empty")
   outcome="标记清楚，本轮送料与拍摄完成。" if good else ("照片有亮斑，标记过曝。" if not shaded else "照片中没有到位的试件。")
   history.append({"round":round_id,"arrived":arrived,"shaded":shaded,"passed":good,"kind":photo_kind})
   if good:photo_round=round_id;completed=true
