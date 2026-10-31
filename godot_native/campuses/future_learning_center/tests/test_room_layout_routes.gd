extends SceneTree
# Every old puzzle anchor must retain a doorway-to-approach-and-back path.
const Body = preload("res://scripts/player_metrics.gd")
const Space = preload("res://scripts/space/spatial_rules.gd")
const FloorSpace = preload("res://campuses/future_learning_center/scripts/floor_space.gd")
var checks := 0
var failures := 0
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func _initialize()->void:call_deferred("run")
func reachable(space:RefCounted,a:Vector2,b:Vector2)->bool:
 if not space.can_stand(a) or not space.can_stand(b):return false
 if a.distance_to(b)<.1:return true
 var path:PackedVector2Array=space.route(a,b)
 if path.is_empty():return false
 var previous:=a
 for point:Vector2 in path:
  if not space.segment_clear(previous,point):return false
  previous=point
 return previous.distance_to(b)<.1
func run()->void:
 if not preload("res://tests/native_test_isolation.gd").is_isolated_save():quit(2);return
 var registry:Array=[]
 var source:=FileAccess.get_file_as_string("res://campuses/future_learning_center/scripts/floor_view.gd")
 var block:=source.split("const PuzzleAnchors = {")[1].split("\n}")[0]
 var pattern:=RegEx.new();pattern.compile('"([^"]+)":\\s*\\["[^"]+",\\s*"([^"]+)",\\s*(\\d+)\\]')
 for match:RegExMatch in pattern.search_all(block):registry.append({"key":match.get_string(1),"id":match.get_string(2),"floor":int(match.get_string(3))})
 for row:Array in [[2,"electrical_assembly_bench"],[2,"formula_workbench_0"],[2,"robotics_workbench_30"],[2,"team_desk_6"],[3,"pantry_pantry_island_250"]]:registry.append({"floor":row[0],"id":row[1]})
 check(registry.size()==29,"all 24 registered plus five independent activity anchors are included")
 for floor_number:int in [2,3,4]:
  var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://campuses/future_learning_center/data/floor_%d.json"%floor_number))
  var space=FloorSpace.new();space.configure(data)
  for row:Dictionary in registry:
   if int(row.floor)!=floor_number:continue
   var objects:Array=data.objects.filter(func(o:Dictionary)->bool:return o.id==row.id)
   check(objects.size()==1,"stable unique anchor "+str(row.id))
   if objects.size()!=1:continue
   var object:Dictionary=objects[0]
   var seeds:Array=[]
   for door:Dictionary in data.doors:
    if door.room==object.room:seeds.append({"name":door.id,"point":door.inside,"outside":door.outside})
   if object.room=="platform":
    var room:Dictionary=data.rooms.filter(func(r:Dictionary)->bool:return r.id=="platform")[0]
    var bounds:=Space.rect(room.bounds)
    seeds.append({"name":"platform_west_open","point":[bounds.position.x-80,bounds.get_center().y]})
    seeds.append({"name":"platform_east_open","point":[bounds.end.x+80,bounds.get_center().y]})
   elif object.room=="xlab_box":
    seeds.append({"name":"xlab_box_existing_door","point":data.projectionReference.doorSweep[0],"outside":data.projectionReference.doorSweep[1]})
   check(not seeds.is_empty(),"explicit doorway/open entrance for "+str(row.id))
   var box:=Space.rect(object.footprint)
   var candidates:Array[Vector2]=[]
   for offset:Vector2 in [Vector2(0,65),Vector2(-65,0),Vector2(65,0),Vector2(0,-65)]:
    candidates.append(box.get_center()+offset+Vector2(signf(offset.x)*box.size.x/2,signf(offset.y)*box.size.y/2)-Body.FOOT_CENTER_OFFSET)
   for seed:Dictionary in seeds:
    var start:=Vector2(seed.point[0],seed.point[1])-Body.FOOT_CENTER_OFFSET
    check(space.can_stand(start),"full feet at entrance "+str(seed.name))
    var good:=false
    for target:Vector2 in candidates:
     if not reachable(space,start,target) or not reachable(space,target,start):continue
     if seed.has("outside") and not reachable(space,target,Vector2(seed.outside[0],seed.outside[1])-Body.FOOT_CENTER_OFFSET):continue
     good=true;break
    check(good,"entrance to actual interaction approach and back: "+str(seed.name)+" -> "+str(row.id))
 print("FLC_ROOM_LAYOUT_ROUTES: %d checks, %d failures"%[checks,failures])
 quit(1 if failures else 0)
