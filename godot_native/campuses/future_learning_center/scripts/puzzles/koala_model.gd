extends RefCounted
const VECTORS:=[[0,2,4,6],[5,0,7,2]]
# Eight separate physical modules; repeated operators are deliberately available.
const OPERATORS:=[0,0,0,1,2,3,2,3]
var chain:Array[int]=[]
var revision:=0
var card:=0
var custom:Array[int]=[0,2,4,6]
var receipts:Dictionary={}
var history:Array[Array]=[]
var running:=false
var paused:=false
var elapsed:=0.0
var step_index:=0
var work:Array[int]=[]
var frames:Array[Array]=[]
var trial_revision:=-1
var trial_card:=0
var completed:=false
var outcome:=""
static func transform(input:Array,operator:int)->Array[int]:
 var result:Array[int]=[];result.assign(input)
 match operator:
  0:result.append(result.pop_front())
  1:result.push_front(result.pop_back())
  2:result.reverse()
  3:result[0]=result[0]^1;result[1]=result[1]^1
 return result
static func forward(input:Array)->Array[int]:return transform(transform(transform(input,0),2),3)
func original()->Array:return custom if card<0 else VECTORS[card]
func attach(module:int,index:int)->bool:
 if module<0 or module>=8 or index< -1 or index>chain.size():return false
 history.append(chain.duplicate());chain.erase(module)
 if index>=0:chain.insert(mini(index,chain.size()),module)
 revision+=1;receipts.clear();cancel();outcome="";return true
func undo()->bool:
 if history.is_empty():return false
 chain.assign(history.pop_back());revision+=1;receipts.clear();cancel();return true
func insert_card(value:int)->bool:
 if value not in [-1,0,1]:return false
 card=value;cancel();work=forward(original());frames.clear();outcome="";return true
func edit_token(slot:int,fill_only:bool=false)->bool:
 if slot<0 or slot>3:return false
 if card>=0:custom.assign(VECTORS[card])
 card=-1
 custom[slot]=custom[slot]^1 if fill_only else ((custom[slot]/2+1)%4)*2+custom[slot]%2
 cancel();work=forward(custom);return true
func start()->bool:
 if running:return false
 running=true;paused=false;elapsed=0;step_index=0;trial_revision=revision;trial_card=card;work=forward(original());frames=[work.duplicate()];outcome="";return true
func cancel()->void:running=false;paused=false;elapsed=0
func pause()->void:paused=true
func resume()->void:paused=false
func step(dt:float)->void:
 if not running or paused or not is_finite(dt) or dt<=0:return
 elapsed+=minf(dt,.1)
 if elapsed<.45:return
 elapsed=0
 if step_index<chain.size():
  work=transform(work,OPERATORS[chain[step_index]]);frames.append(work.duplicate());step_index+=1;return
 running=false
 if trial_revision!=revision:return
 var passed:=work==original()
 outcome="形状与填纹都已还原" if passed else "图形或填纹仍不同"
 if trial_card>=0:receipts[trial_card]={"revision":revision,"passed":passed}
 if current_passed():completed=true
func current_passed()->bool:
 for id:int in 2:
  var r:Dictionary=receipts.get(id,{})
  if r.is_empty() or r.revision!=revision or not r.passed:return false
 return true
