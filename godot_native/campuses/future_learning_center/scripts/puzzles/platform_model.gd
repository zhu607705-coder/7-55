extends RefCounted
## Native migration of review/gameplay.mjs: board sweep + projected footprint.
const TARGET:=Vector2(480,306)
const CAMERA:=Vector2(480,443)
const SCENERY:=[Rect2(84.8,140,70.4,35),Rect2(174.28,212,121.44,48),Rect2(216.52,299,36.96,28),Rect2(82.12,278,45.76,32),Rect2(813.04,242,73.92,38),Rect2(774.28,392,121.44,48),Rect2(893,466,44,24),Rect2(419.28,274,121.44,48),Rect2(454.92,405,50.16,38)]
var board:=Vector2(740,210)
var condition:=0
var revision:=0
var records:Dictionary={}
var history:Array[Dictionary]=[]
var completed:=false
var photographing:=false
var exposure:=0.0
var trial_revision:=-1
var trial_condition:=-1
var shot:Dictionary={}
var outcome:=""
var contact:=Vector2.INF
func move_board(to:Vector2)->bool:
 if not to.is_finite():return false
 to=to.clamp(Vector2(140,170),Vector2(820,470))
 if to.is_equal_approx(board):return true
 var start:=board
 var steps:=maxi(1,ceili(start.distance_to(to)/4.0))
 var blocked:=false
 contact=Vector2.INF
 for i:int in range(1,steps+1):
  var at:=start.lerp(to,float(i)/steps)
  if not _board_clear(at):
   var low:=board;var high:=at
   for _refine:int in 16:
    var mid:Vector2=(low+high)*.5
    if _board_clear(mid):low=mid
    else:high=mid
   board=low;contact=high;blocked=true;break
  board=at
 if not board.is_equal_approx(start):revision+=1;cancel();shot={}
 outcome="轮架碰到物件，从旁边绕过去。" if blocked else ""
 return not blocked
func _board_clear(at:Vector2)->bool:
 for obstacle:Rect2 in SCENERY:
  if Rect2(at-Vector2(72,14),Vector2(144,28)).intersects(obstacle):return false
 return true
func set_condition(value:int)->void:
 if value not in [0,1] or value==condition:return
 condition=value;cancel();shot={};outcome=""
func shadow()->PackedVector2Array:
 var points:=PackedVector2Array()
 var shift:=Vector2(-290 if condition==0 else 290,-145)
 for corner:Vector2 in [Vector2(-72,-14),Vector2(72,-14),Vector2(72,14),Vector2(-72,14)]:points.append(board+corner);points.append(board+corner+shift)
 return Geometry2D.convex_hull(points)
func assess()->Dictionary:
 var shaded:=true
 var visible_corners:=0
 var shadow_poly:=shadow()
 var occluder:=Rect2(board-Vector2(76,24),Vector2(152,48))
 for corner:Vector2 in [Vector2(-10,-8),Vector2(10,-8),Vector2(10,8),Vector2(-10,8)]:
  var target:=TARGET+corner
  shaded=shaded and Geometry2D.is_point_in_polygon(target,shadow_poly)
  if not _ray_blocked(CAMERA,target,occluder):visible_corners+=1
 return {"clear":shaded,"blocked":visible_corners<4,"visible_corners":visible_corners,"success":shaded and visible_corners==4}
func _ray_blocked(a:Vector2,b:Vector2,r:Rect2)->bool:
 if r.has_point(a) or r.has_point(b):return true
 var c:=[r.position,Vector2(r.end.x,r.position.y),r.end,Vector2(r.position.x,r.end.y)]
 for i:int in 4:
  if Geometry2D.segment_intersects_segment(a,b,c[i],c[(i+1)%4])!=null:return true
 return false
func shutter()->bool:
 if photographing:return false
 photographing=true;exposure=0;trial_revision=revision;trial_condition=condition;return true
func step(dt:float)->void:
 if not photographing:return
 exposure+=clampf(dt,0,.1)
 if exposure<.5:return
 photographing=false
 if revision!=trial_revision or condition!=trial_condition:return
 shot=assess();shot["condition"]=condition;shot["board"]=board;shot["revision"]=revision;history.append(shot.duplicate(true))
 if shot.success:records[condition]=shot.duplicate(true)
 completed=completed or records.size()==2
 outcome="白板挡住取景。" if shot.blocked else ("标记清楚可见。" if shot.clear else "亮斑覆盖标记。")
func cancel()->void:photographing=false;exposure=0
func pause()->void:cancel()
