extends RefCounted
## Each beat snapshots prerequisites and tool occupancy before any output exists.
const NEEDS=[[ ],[ ],[1],[0,2]]
var slots:Array[int]=[0,0,0,1]
# 0/1 = individual cameras, 2 = workbench, -1 = hands.
var tools:Array[int]=[0,2,0,-1]
var cameras:=1
var revision:=0
var running:=false
var paused:=false
var beat:=0
var progress:=0.0
var artifacts:Array[bool]=[false,false,false,false]
var errors:Array[String]=["","","",""]
var current_tasks:Array[int]=[]
var records:Array[Dictionary]=[]
var completed:=false
var extension_completed:=false
var _trial_revision:=-1
var _invalid:=false
var _undo:Array[Dictionary]=[]
func place(task:int,slot:int)->bool:
 if task<0 or task>3 or slot<0 or slot>2:return false
 if slots[task]==slot:return true
 _remember();slots[task]=slot;_changed();return true
func connect_tool(task:int,tool:int)->bool:
 if task<0 or task>3 or tool< -1 or tool>2:return false
 if tool==1 and cameras<2:return false
 if tools[task]==tool:return true
 _remember();tools[task]=tool;_changed();return true
func set_second_camera(value:bool)->void:
 var count:=2 if value else 1
 if cameras==count:return
 _remember();cameras=count
 if cameras==1:
  for i:int in 4:
   if tools[i]==1:tools[i]=-1
 _changed()
func _remember()->void:
 _undo.append({"slots":slots.duplicate(),"tools":tools.duplicate(),"cameras":cameras})
 if _undo.size()>24:_undo.pop_front()
func undo()->bool:
 if _undo.is_empty():return false
 var previous:Dictionary=_undo.pop_back();slots.assign(previous.slots);tools.assign(previous.tools);cameras=previous.cameras;_changed();return true
func _changed()->void:
 revision+=1;cancel();artifacts=[false,false,false,false];errors=["","","",""];beat=0;progress=0
func start()->bool:
 if running:return false
 artifacts=[false,false,false,false];errors=["","","",""]
 _invalid=false;beat=0;progress=0;running=true;paused=false;_trial_revision=revision
 _begin_beat();return true
func _begin_beat()->void:
 current_tasks.clear()
 var occupied:Dictionary={}
 # First claim all tools. Conflicts reject both owners, not whichever runs last.
 for task:int in 4:
  if slots[task]!=beat:continue
  var tool:=tools[task]
  if tool>=0:
   if not occupied.has(tool):occupied[tool]=[]
   occupied[tool].append(task)
 for task:int in 4:
  if slots[task]!=beat:continue
  var reason:=""
  for prerequisite:int in NEEDS[task]:
   if not artifacts[prerequisite]:reason="missing_input"
  var tool:=tools[task]
  if task in [0,2] and (tool<0 or tool>=cameras):reason="camera_missing"
  elif task==1 and tool!=2:reason="bench_missing"
  elif task==3 and tool!=-1:reason="hands_needed"
  if tool>=0 and occupied.get(tool,[]).size()>1:reason="tool_busy"
  errors[task]=reason
  if reason.is_empty():current_tasks.append(task)
  else:_invalid=true
func step(dt:float)->void:
 if not running or paused:return
 progress=minf(1,progress+clampf(dt,0,.1)/.85)
 if progress<1:return
 if _trial_revision!=revision:cancel();return
 for task:int in current_tasks:artifacts[task]=true
 beat+=1;progress=0
 if beat<3:_begin_beat();return
 running=false;current_tasks.clear()
 var success:=not _invalid and artifacts.all(func(value:bool)->bool:return value)
 completed=completed or success
 extension_completed=extension_completed or (success and cameras==2)
 records.append({"revision":revision,"cameras":cameras,"slots":slots.duplicate(),"tools":tools.duplicate(),"artifacts":artifacts.duplicate(),"errors":errors.duplicate(),"success":success})
 if records.size()>24:records.pop_front()
func pause()->void:
 if running:paused=true
func resume()->void:
 if running:paused=false
func cancel()->void:running=false;paused=false;current_tasks.clear()
