extends SceneTree
const FloorSpace=preload("res://campuses/future_learning_center/scripts/floor_space.gd")
const Body=preload("res://scripts/player_metrics.gd")
var checks:=0
var failures:=0
func check(value:bool,label:String)->void:
 checks+=1
 if not value:failures+=1;push_error(label)
func _initialize()->void:
 var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://campuses/future_learning_center/data/floor_3.json"))
 var ref:Dictionary=data.projectionReference
 var space=FloorSpace.new();space.configure(data)
 var origin:=Vector2(data.spawn[0],data.spawn[1])-Body.FOOT_CENTER_OFFSET
 check(data.objects.filter(func(o:Dictionary)->bool:return o.id==ref.table).size()==1,"Exactly one portable station")
 for row:Array in ref.approaches:
  var target:=Vector2(row[0],row[1])-Body.FOOT_CENTER_OFFSET
  check(space.can_stand(target),"Full feet fit beside station")
  check(not space.route(origin,target).is_empty(),"Station side reachable from actual floor spawn")
  check(not space.route(target,origin).is_empty(),"Can return from station")
 var a:=Vector2(ref.doorSweep[0][0],ref.doorSweep[0][1])-Body.FOOT_CENTER_OFFSET
 var b:=Vector2(ref.doorSweep[1][0],ref.doorSweep[1][1])-Body.FOOT_CENTER_OFFSET
 check(space.segment_clear(a,b),"Existing small-room threshold remains continuously open")
 check(not space.can_stand(Vector2(4690,5815)-Body.FOOT_CENTER_OFFSET),"Display table has real foot collision")
 print("FLC_PROJECTION_PLACEMENT: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
