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
 if drag_piece>=0 or piece<0 or piece>2:return false
 var next:=poses.duplicate();next[piece]=at
 if not valid(next,bar_turn):return false
 if poses[piece]==at:return true
 _remember();poses=next;_changed();return true
func drop(piece:int,x:int,y:int)->bool:
 for z:int in 2:
  if place(piece,Vector3i(x,y,z)):return true
 return false
func rotate_bar()->bool:
 if drag_piece>=0:return false
 if not valid(poses,1-bar_turn):return false
 _remember();bar_turn=1-bar_turn;_changed();return true
func _remember()->void:history.append({"poses":poses.duplicate(),"turn":bar_turn})
func undo()->bool:
 if history.is_empty():return false
 var old:Dictionary=history.pop_back();poses.assign(old.poses);bar_turn=old.turn;_changed();return true
func _changed()->void:revision+=1;receipts.clear();cancel();outcome=""
func rotate_holder()->void:
 if drag_piece<0:observation=(observation+1)%4
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
 if running or drag_piece>=0:return false
 running=true;paused=false;elapsed=0;trial_revision=revision;outcome="";return true
func cancel()->void:running=false;paused=false;elapsed=0
func pause()->void:paused=true
func resume()->void:paused=false
func step(dt:float)->void:
 advance_drag(dt)
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

# Hand-held geometry is separate from the supported assembly and its receipts.
var drag_piece:=-1
var drag_stage:=""
var preview_origin:=Vector3.ZERO
var drag_start:=Vector3.ZERO
var lift_target:=Vector3.ZERO
var drop_target:=TRAY
var lower_from:=Vector3.ZERO
var drag_elapsed:=0.0
func begin_drag(piece:int,rack_origin:Vector3=Vector3.ZERO,lift_pose:Vector3=Vector3.INF)->bool:
 if piece<0 or piece>2 or drag_piece>=0:return false
 var remaining:=poses.duplicate();remaining[piece]=TRAY
 if not valid(remaining,bar_turn):return false # Do not lift the support out from under a block.
 cancel();drag_piece=piece;drag_start=Vector3(poses[piece]) if poses[piece]!=TRAY else rack_origin
 lift_target=lift_pose if lift_pose.is_finite() else Vector3(drag_start.x,drag_start.y,2)
 preview_origin=drag_start;drag_stage="lift";drag_elapsed=0;return true
func carried_clear(at:Vector3)->bool:
 for local:Vector3i in cells(drag_piece,Vector3i.ZERO,bar_turn):
  var p:=at+Vector3(local)
  for other:int in 3:
   if other==drag_piece:continue
   for occupied:Vector3i in cells(other,poses[other],bar_turn):
    var q:=Vector3(occupied)
    if p.x<q.x+.999 and p.x+.999>q.x and p.y<q.y+.999 and p.y+.999>q.y and p.z<q.z+.999 and p.z+.999>q.z:return false
 return true
func move_drag(at:Vector3)->bool:
 if drag_piece<0 or drag_stage not in ["lift","carry"] or not at.is_finite() or at.z<0:return false
 var count:=maxi(1,ceili(preview_origin.distance_to(at)/.08))
 for i:int in range(1,count+1):
  if not carried_clear(preview_origin.lerp(at,float(i)/count)):return false
 preview_origin=at;return true
func request_drop(at:Vector3i)->bool:
 if drag_piece<0 or drag_stage!="carry":return false
 var candidate:=poses.duplicate();candidate[drag_piece]=at
 if not valid(candidate,bar_turn):return false
 if at==TRAY:return false # Rack drop uses cancel/return: no unsupported assembly is committed.
 for i:int in range(1,33):
  if not carried_clear(preview_origin.lerp(Vector3(at),i/32.0)):return false
 lower_from=preview_origin;drop_target=at;drag_stage="lower";drag_elapsed=0;return true
func return_to_rack()->bool:
 if drag_piece<0 or drag_stage!="carry":return false
 var id:=drag_piece;cancel_drag();return place(id,TRAY)
func cancel_drag()->void:drag_piece=-1;drag_stage="";drag_elapsed=0
func advance_drag(dt:float)->void:
 if drag_piece<0 or paused or not is_finite(dt) or dt<=0:return
 drag_elapsed+=minf(dt,.1)
 if drag_stage=="lift":
  preview_origin.z=lerpf(drag_start.z,2,minf(drag_elapsed/.16,1))
  if drag_elapsed>=.16:drag_stage="carry"
 elif drag_stage=="lower":
  preview_origin=lower_from.lerp(Vector3(drop_target),minf(drag_elapsed/.16,1))
  if drag_elapsed>=.16:
   var id:=drag_piece;var target:=drop_target;cancel_drag();place(id,target)
