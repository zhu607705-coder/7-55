extends RefCounted
## Passive switch networks, evaluated by reachability; input comes from specimen geometry.
const NEAR:=Rect2(428,250,16,90)
const SUPPORT:=Rect2(470,350,100,12)
const SHAPES:=[Rect2(-60,-30,100,35),Rect2(-15,0,65,60),Rect2(-60,-30,110,90)]
const NETWORKS:=[[[0,1,0],[1,2,1]],[[0,2,0],[0,2,1]],[[0,1,0],[3,2,1]]]
var card:=-1
var swapped:=false
var revision:=0
var observation_revision:=0
var block:=-1
var position:=Vector2(500,300)
var receipts:Dictionary={}
var history:Array[Dictionary]=[]
var completed:=false
var transfer_completed:=false
var running:=false
var paused:=false
var elapsed:=0.0
var jaw:=0.0
var outcome:=""
var trial:Dictionary={}
func specimen()->Rect2:
 return Rect2() if block<0 else Rect2(position+SHAPES[block].position,SHAPES[block].size)
func contacts()->Array[bool]:
 if block<0:return [false,false]
 var r:=specimen()
 var near:=r.intersects(NEAR)
 var supported:=r.end.y>=SUPPORT.position.y and r.end.y<=SUPPORT.end.y and r.end.x>SUPPORT.position.x and r.position.x<SUPPORT.end.x
 return [near,supported]
func output(inputs:Array)->bool:
 if card<0:return false
 var active:Array=inputs.duplicate()
 if swapped:active.reverse()
 var reached:Dictionary={0:true}
 for _i:int in 4:
  for edge:Array in NETWORKS[card]:
   if not active[edge[2]]:continue
   if reached.has(edge[0]):reached[edge[1]]=true
   if reached.has(edge[1]):reached[edge[0]]=true
 return reached.has(2)
func install(value:int)->bool:
 if value< -1 or value>=NETWORKS.size() or value==card:return false
 card=value;invalidate();return true
func exchange_inputs()->void:
 swapped=not swapped;invalidate()
func invalidate()->void:
 revision+=1;receipts.clear();cancel();outcome=""
func place(index:int,at:Vector2)->bool:
 if index< -1 or index>2 or not at.is_finite():return false
 if index>=0 and not Rect2(390,210,230,190).has_point(at):return false
 block=index;position=at;observation_revision+=1;cancel();outcome="";return true
func start()->bool:
 if running or card<0:return false
 var inputs:=contacts()
 trial={"revision":revision,"observation":observation_revision,"inputs":inputs,"output":output(inputs)}
 elapsed=0;running=true;paused=false;outcome="";jaw=0;return true
func pause()->void:
 if running:paused=true
func resume()->void:paused=false
func cancel()->void:running=false;paused=false;elapsed=0;jaw=0;trial={}
func step(dt:float)->void:
 if not running or paused or not is_finite(dt) or dt<=0:return
 elapsed+=minf(dt,.1)
 jaw=minf(elapsed/.6,1.0) if trial.output else 0.0
 if elapsed<1.3:return
 running=false
 if trial.revision!=revision or trial.observation!=observation_revision:return
 var inputs:Array=trial.inputs
 var expected:bool=inputs[0] and inputs[1]
 var good:bool=trial.output==expected
 var key:="%d%d"%[int(inputs[0]),int(inputs[1])]
 var record:Dictionary={"revision":revision,"state":key,"output":trial.output,"passed":good,"stable":trial.output and expected}
 history.append(record);receipts[key]=record
 outcome="稳稳夹住" if record.stable else ("夹爪合拢，试件没有托稳" if trial.output else "夹爪保持张开")
 var all_pass:=receipts.size()==4
 for receipt:Dictionary in receipts.values():all_pass=all_pass and receipt.passed and receipt.revision==revision
 if all_pass:
  completed=true
  if swapped:transfer_completed=true
