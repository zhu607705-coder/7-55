extends RefCounted
const TRAY:=Vector3i(-1,-1,-1)
const BASE:=[Vector3i(0,0,0),Vector3i(1,0,0),Vector3i(1,0,1),Vector3i(1,1,0)]
const EXTRA:=[Vector3i(0,0,0),Vector3i(0,1,0),Vector3i(0,1,1),Vector3i(1,1,0)]
var poses:Array[Vector3i]=[TRAY,TRAY,TRAY]
var bar_turn:=0
var observation:=0
var extension:=false
var revision:=0
var receipts:Dictionary={}
var history:Array[Dictionary]=[]
var completed:=false
var extension_completed:=false
var running:=false
var paused:=false
var elapsed:=0.0
var trial_revision:=-1
var outcome:=""
func cells(piece:int,at:Vector3i,turn:int)->Array[Vector3i]:
 if at==TRAY:return []
 var result:Array[Vector3i]=[at]
 if piece==0:result.append(at+(Vector3i(1,0,0) if turn==0 else Vector3i(0,1,0)))
 return result
func voxels()->Array[Vector3i]:
 var result:Array[Vector3i]=[]
 for piece:int in 3:result.append_array(cells(piece,poses[piece],bar_turn))
 return result
func valid(candidate:Array[Vector3i],turn:int)->bool:
 var occupied:Dictionary={}
 for piece:int in 3:
  for cell:Vector3i in cells(piece,candidate[piece],turn):
   if cell.x<0 or cell.x>1 or cell.y<0 or cell.y>1 or cell.z<0 or cell.z>1 or occupied.has(cell):return false
   occupied[cell]=true
 for cell:Vector3i in occupied:
  if cell.z>0 and not occupied.has(cell-Vector3i(0,0,1)):return false
 return true
func place(piece:int,at:Vector3i)->bool:
 if piece<0 or piece>2:return false
 var next:=poses.duplicate();next[piece]=at
 if not valid(next,bar_turn):return false
 if poses[piece]==at:return true
 _remember();poses=next;_changed();return true
func drop(piece:int,x:int,y:int)->bool:
 for z:int in 2:
  if place(piece,Vector3i(x,y,z)):return true
 return false
func rotate_bar()->bool:
 if not valid(poses,1-bar_turn):return false
 _remember();bar_turn=1-bar_turn;_changed();return true
func _remember()->void:history.append({"poses":poses.duplicate(),"turn":bar_turn})
func undo()->bool:
 if history.is_empty():return false
 var old:Dictionary=history.pop_back();poses.assign(old.poses);bar_turn=old.turn;_changed();return true
func _changed()->void:revision+=1;receipts.clear();cancel();outcome=""
func rotate_holder()->void:observation=(observation+1)%4
func set_extension(value:bool)->void:
 if value==extension:return
 extension=value;_changed()
static func project(cubes:Array,view:int)->Dictionary:
 var image:Dictionary={}
 for cell:Vector3i in cubes:
  var p:=Vector2i(cell.x,cell.y) if view==0 else (Vector2i(cell.x,cell.z) if view==1 else Vector2i(cell.y,cell.z))
  image[p]=true
 return image
func target(view:int)->Dictionary:return project(EXTRA if extension else BASE,view)
func visible_cell(view:int,p:Vector2i)->bool:return not(extension and view==2 and p==Vector2i(1,0))
func matches(view:int)->bool:
 var actual:=project(voxels(),view);var wanted:=target(view)
 for x:int in 2:
  for y:int in 2:
   var p:=Vector2i(x,y)
   if visible_cell(view,p) and actual.has(p)!=wanted.has(p):return false
 return true
func start()->bool:
 if running:return false
 running=true;paused=false;elapsed=0;trial_revision=revision;outcome="";return true
func cancel()->void:running=false;paused=false;elapsed=0
func pause()->void:paused=true
func resume()->void:paused=false
func step(dt:float)->void:
 if not running or paused or not is_finite(dt) or dt<=0:return
 elapsed+=minf(dt,.1)
 if elapsed<.6:return
 running=false
 if revision!=trial_revision:return
 var passed:=voxels().size()==4 and valid(poses,bar_turn)
 for view:int in 3:
  var match_value:=matches(view);receipts[view]={"revision":revision,"passed":match_value};passed=passed and match_value
 outcome="三个视图与实体一致" if passed else "还有一个方向的轮廓不同"
 if passed:
  completed=true
  if extension:extension_completed=true
