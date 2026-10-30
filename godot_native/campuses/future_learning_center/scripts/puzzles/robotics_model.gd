extends RefCounted
## Physical traversals are the evidence: a directed edge graph, immutable per run.
const NODES:=[Vector2(165,310),Vector2(350,310),Vector2(620,310),Vector2(620,160),Vector2(350,160),Vector2(620,425)]
const EDGES:=[[0,1],[1,2],[2,3],[3,4],[4,1],[2,5]]
var selector:=0
var return_direction:=0
var target:=2
var revision:=0
var run_id:=0
var trial_revision:=-1
var running:=false
var paused:=false
var phase:="idle"
var node:=0
var next_node:=-1
var progress:=0.0
var position:Vector2=NODES[0]
var loaded:=false
var unloaded:=false
var cargo_position:Vector2=NODES[0]+Vector2(-35,0)
var cargo_id:=0
var completed:=false
var transfer_completed:=false
var outcome:=""
var blocked_edge:Array[int]=[]
var outward:Array[Vector2]=[]
var inward:Array[Vector2]=[]
var receipts:Array[Dictionary]=[]
var history:Array[Dictionary]=[]
func configuration()->Dictionary:return {"selector":selector,"return_direction":return_direction,"target":target}
func edit(part:String,value:int)->bool:
 if part not in ["selector","return_direction","target"]:return false
 if part=="target" and value not in [2,5]:return false
 if part!="target" and value not in [0,1]:return false
 if get(part)==value:return false
 history.append(configuration());set(part,value);revision+=1;cancel();outcome="轨道已改变；本次试件回到安全基座。";return true
func undo()->void:
 if history.is_empty():return
 var previous:Dictionary=history.pop_back()
 selector=previous.selector;return_direction=previous.return_direction;target=previous.target
 revision+=1;cancel()
func cancel()->void:
 running=false;paused=false;phase="idle";node=0;next_node=-1;progress=0;position=NODES[0]
 loaded=false;unloaded=false;cargo_position=NODES[0]+Vector2(-35,0);blocked_edge=[]
func pause()->void:paused=true
func resume()->void:paused=false
func start()->bool:
 if running:return false
 cancel();run_id+=1;cargo_id=run_id;trial_revision=revision;running=true;phase="loading";outward=[NODES[0]];inward=[];outcome="";return true
func single_step()->void:
 if not running:start()
 paused=false;step(.1)
 if running:paused=true
func allowed(a:int,b:int)->bool:
 if [a,b] in [[0,1],[1,0],[1,2],[2,3],[3,2],[3,4],[4,3],[2,5],[5,2]]:return true
 if return_direction==1 and a==4 and b==1:return true
 if return_direction==0 and a==1 and b==4:return true
 return false
func destination()->int:
 match node:
  0:return 1
  1:return 0 if unloaded else 2
  2:return (1 if selector==0 else 3) if unloaded else 5
  3:return 4
  4:return 1
  5:return 2
 return -1
func _depart()->void:
 next_node=destination();progress=0
 if not allowed(node,next_node):
  blocked_edge=[node,next_node];phase="approach_stop";return
 phase="moving"
func step(dt:float)->void:
 if not running or paused or dt<=0 or not is_finite(dt):return
 if revision!=trial_revision:cancel();return
 var advance:=minf(dt,.1)
 if phase=="loading":
  progress=minf(1,progress+advance/.65);cargo_position=(NODES[0]+Vector2(-35,0)).lerp(position,progress)
  if progress>=1:loaded=true;_depart()
 elif phase=="unloading":
  progress=minf(1,progress+advance/.65);cargo_position=position.lerp(NODES[target]+Vector2(40,0),progress)
  if progress>=1:loaded=false;unloaded=true;inward=[position];_depart()
 elif phase=="approach_stop":
  progress=minf(1,progress+advance*4)
  position=NODES[node].lerp(NODES[node].move_toward(NODES[next_node],12),progress)
  if loaded:cargo_position=position
  if progress>=1:running=false;phase="blocked";outcome="车头停在止逆台阶前。"
 elif phase=="moving":
  var distance:float=NODES[node].distance_to(NODES[next_node])
  progress=minf(1,progress+advance*125/distance);position=NODES[node].lerp(NODES[next_node],progress)
  if loaded:cargo_position=position
  if progress>=1:
   node=next_node
   if unloaded:inward.append(position)
   else:outward.append(position)
   if node==target and loaded:phase="unloading";progress=0
   elif node==0 and unloaded:
    running=false;phase="done";completed=true
    if target==5:transfer_completed=true
    receipts.append({"run_id":run_id,"cargo_id":cargo_id,"revision":trial_revision,"target":target,"outward":outward.duplicate(),"inward":inward.duplicate()});outcome="同一试件卸载后，空车已返回装载台。"
   else:_depart()
