extends RefCounted
## Replacement native implementation; prior isolated example was not available.
## Cables map input port -> output port. Port identities survive device movement.
const INPUTS:=["bus_in","screen_a","screen_b"]
const OUTPUTS:=["source","live_a","live_b","cache"]
var cables:Dictionary={"bus_in":"source","screen_a":"live_a","screen_b":"cache"}
var revision:=0
var source_pattern:=0
var cache_pattern:=2
var screens:Array[int]=[0,2]
var receipts:Dictionary={}
var history:Array[Dictionary]=[]
var completed:=false
var running:=false
var elapsed:=0.0
var trial_revision:=-1
var trial_pattern:=-1
var delivered:Array[bool]=[false,false]
var positions:Array[Vector2]=[Vector2(680,180),Vector2(680,350)]
var outcome:=""
func connect_ports(input:String,output:String)->bool:
 if input not in INPUTS or output not in OUTPUTS:return false
 if (input=="bus_in" and output!="source") or (input!="bus_in" and output=="source"):
  outcome="插头形状与插口不合。";return false
 if str(cables.get(input,""))==output:return true
 for receiver:String in cables:
  if receiver!=input and cables[receiver]==output:outcome="这个插口已有一根线。";return false
 cables[input]=output;_edit();return true
func unplug(input:String)->bool:
 if not cables.has(input):return false
 cables.erase(input);_edit();return true
func _edit()->void:revision+=1;receipts.clear();cancel();outcome=""
func move_screen(id:int,to:Vector2)->bool:
 if id not in [0,1] or not to.is_finite():return false
 positions[id]=to.clamp(Vector2(610,145),Vector2(800,400));return true
func output_pattern(port:String)->int:
 if port=="source":return source_pattern
 if port=="cache":return cache_pattern
 if port in ["live_a","live_b"]:
  var upstream:String=str(cables.get("bus_in",""))
  if upstream=="source":return source_pattern
  if upstream=="cache":return cache_pattern
 return -1 # A bus-to-own-input loop has no source.
func reaches_live(input:String)->bool:
 var port:String=str(cables.get(input,""))
 return port in ["live_a","live_b"] and str(cables.get("bus_in",""))=="source"
func change_source()->bool:
 if running:return false
 source_pattern=(source_pattern+1)%3
 trial_pattern=source_pattern;trial_revision=revision;elapsed=0;running=true;delivered.assign([false,false]);outcome="";return true
func step(dt:float)->void:
 if not running:return
 elapsed+=clampf(dt,0,.1)
 for i:int in 2:
  if not delivered[i] and elapsed>=.7+i*.35:
   delivered[i]=true
   var value:=output_pattern(str(cables.get(INPUTS[i+1],"")))
   if value>=0:screens[i]=value
 if elapsed<1.25:return
 running=false
 var passed:=trial_revision==revision and reaches_live("screen_a") and reaches_live("screen_b") and screens[0]==trial_pattern and screens[1]==trial_pattern
 history.append({"revision":trial_revision,"pattern":trial_pattern,"screens":screens.duplicate(),"passed":passed})
 if passed:receipts[trial_pattern]=revision
 completed=completed or receipts.size()>=2
 outcome="两屏都收到本次改动。" if passed else "对照两屏，哪一处角标还停在旧稿？"
func cancel()->void:running=false;elapsed=0;delivered.assign([false,false])
func pause()->void:cancel()
