extends RefCounted
## Original event times are immutable; only record origin offsets are manipulated.
const CAMERA:=[{"id":"flash_a","time":0.0,"kind":"flash"},{"id":"flash_b","time":2.0,"kind":"flash"},{"id":"feed","time":5.0,"kind":"feed"},{"id":"stop","time":7.0,"kind":"stop"}]
const UNIT:=46.0
var offsets:Array[float]=[0.0,0.0]
var dataset:=0
var revision:=0
var running:=false
var paused:=false
var elapsed:=0.0
var travel:=0.0
var gate:=0.0
var trial_revision:=-1
var completed:=false
var transfer_completed:=false
var receipts:Array[Dictionary]=[]
var outcome:=""
func bias()->float:return 3.0 if dataset==0 else -2.0
func event_x(tape:int,event_index:int)->float:
 return 210+offsets[tape]+(CAMERA[event_index].time+(bias() if tape==1 else 0.0))*UNIT
func aligned()->bool:
 # Same identity, two separated anchors. Matching the other repeated flash is insufficient.
 return absf(event_x(0,0)-event_x(1,0))<=5 and absf(event_x(0,3)-event_x(1,3))<=5
func shift(tape:int,value:float)->bool:
 if tape<0 or tape>1 or not is_finite(value) or absf(value)>230:return false
 if is_equal_approx(offsets[tape],value):return false
 offsets[tape]=value;revision+=1;cancel();outcome="";return true
func replace_roll()->void:
 dataset=1-dataset;offsets=[0.0,0.0];revision+=1;cancel();outcome="换入另一卷记录。"
func start()->bool:
 if running:return false
 running=true;paused=false;elapsed=0;travel=0;gate=0;trial_revision=revision;outcome="";return true
func cancel()->void:running=false;paused=false
func pause()->void:
 if running:paused=true
func resume()->void:paused=false
func step(dt:float)->void:
 if not running or paused or not is_finite(dt) or dt<=0:return
 elapsed+=minf(dt,.1)
 travel=clampf(elapsed/2.52,0,1)
 gate=clampf((elapsed-2.65)/.35,0,1)
 if elapsed<3.2:return
 running=false
 var valid:=trial_revision==revision and aligned() and travel==1 and gate==1
 receipts.append({"revision":trial_revision,"dataset":dataset,"aligned":aligned(),"passed":valid})
 outcome="两处事件都对齐：试件先到，挡片随后关闭。" if valid else "试件先到，挡片随后关闭；两条记录仍有错位。"
 if valid:
  completed=true
  if dataset==1:transfer_completed=true
