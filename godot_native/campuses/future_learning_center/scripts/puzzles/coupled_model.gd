extends RefCounted
## Swept rigid bodies on a tray. Widths are 1, 2 and 1.4 units.
const UNIT:=60.0
const TARGETS:=[Vector2(450,170),Vector2(510,170)]
var positions:Array[Vector2]=[Vector2(450,400),Vector2(510,400)]
var angle:=0.0
var connected:=false
var revision:=0
var completed:=false
var paused:=false
var running:=false
var outcome:=""
var blocked_at:=Vector2.ZERO
var history:Array[Dictionary]=[]
func snapshot()->Dictionary:return {"positions":positions.duplicate(),"angle":angle,"connected":connected}
func restore(s:Dictionary)->void:
 positions.assign(s.positions);angle=s.angle;connected=s.connected;blocked_at=Vector2.ZERO
func remember()->void:history.append(snapshot())
func undo()->void:
 if not history.is_empty():restore(history.pop_back());revision+=1
func midpoint()->Vector2:return (positions[0]+positions[1])*.5
func corners(center:Vector2,rotation:float)->PackedVector2Array:
 var result:=PackedVector2Array()
 for v:Vector2 in [Vector2(-30,-30),Vector2(30,-30),Vector2(30,30),Vector2(-30,30)]:result.append(center+v.rotated(rotation))
 return result
func supported(center:Vector2,rotation:float)->bool:
 var poly:=corners(center,rotation)
 var probes:=Array(poly)
 # Clip each edge at every change of tray width, not just the four corners.
 for i:int in 4:
  var a:Vector2=poly[i];var b:Vector2=poly[(i+1)%4]
  for y:float in [250.001,329.999]:
   if (a.y-y)*(b.y-y)<0:probes.append(a.lerp(b,(y-a.y)/(b.y-a.y)))
 for v:Vector2 in probes:
  if v.y<90-.001 or v.y>470+.001 or v.x<180-.001 or v.x>780+.001:return false
  if v.y>250 and v.y<330 and (v.x<438-.001 or v.x>522+.001):return false
 return true
func valid_pose(points:Array[Vector2],rotation:float)->bool:
 for point:Vector2 in points:
  if not supported(point,rotation):blocked_at=point;return false
 # Separating axes for two equally oriented square blocks; touching is allowed.
 var delta:Vector2=(points[1]-points[0]).rotated(-rotation)
 if absf(delta.x)<59.999 and absf(delta.y)<59.999:blocked_at=(points[0]+points[1])*.5;return false
 return true
func move_piece(index:int,target:Vector2)->bool:
 if paused or index<0 or index>1 or not target.is_finite():return false
 var delta:=target-positions[index]
 if delta.length()<.001:return false
 var n:=maxi(1,ceili(delta.length()/2.0))
 for step:int in range(1,n+1):
  var candidate:Array[Vector2]=positions.duplicate()
  if connected:
   candidate[0]+=delta*float(step)/n;candidate[1]+=delta*float(step)/n
  else:candidate[index]+=delta*float(step)/n
  if not valid_pose(candidate,angle):outcome="边缘碰到托盘窄颈。";return false
 if connected:positions[0]+=delta;positions[1]+=delta
 else:positions[index]=target
 revision+=1;blocked_at=Vector2.ZERO;outcome="";return true
func rotate_to(value:float)->bool:
 if paused or not connected or not is_finite(value):return false
 var delta:=wrapf(value-angle,-PI,PI)
 if absf(delta)<.001:return false
 var center:=midpoint();var n:=maxi(1,ceili(absf(delta)/.015))
 for step:int in range(1,n+1):
  var turn:=delta*float(step)/n
  var candidate:Array[Vector2]=[center+(positions[0]-center).rotated(turn),center+(positions[1]-center).rotated(turn)]
  if not valid_pose(candidate,angle+turn):outcome="转动时边角碰到托盘。";return false
 positions=[center+(positions[0]-center).rotated(delta),center+(positions[1]-center).rotated(delta)]
 angle=wrapf(value,-PI,PI);revision+=1;blocked_at=Vector2.ZERO;return true
func insert_pin()->bool:
 if paused or connected:return false
 var d:Vector2=(positions[1]-positions[0]).rotated(-angle)
 if not ((absf(absf(d.x)-60)<1 and absf(d.y)<1) or (absf(absf(d.y)-60)<1 and absf(d.x)<1)):
  outcome="两个插孔还没有贴合。";return false
 connected=true;revision+=1;outcome="";return true
func remove_pin()->void:connected=false;revision+=1;outcome=""
func contact(index:int)->bool:
 return positions[index].distance_to(TARGETS[0])<5 or positions[index].distance_to(TARGETS[1])<5
func circuit_closed()->bool:
 return connected and contact(0) and contact(1) and positions[0].distance_to(positions[1])>55
func finish_gesture()->void:
 if circuit_closed():completed=true;outcome="两端与中间插销同时导通。"
 elif contact(0) and contact(1):outcome="两端已接触，中间仍断开。"
func cancel()->void:paused=false
func pause()->void:paused=true
func resume()->void:paused=false
func step(_dt:float)->void:pass
