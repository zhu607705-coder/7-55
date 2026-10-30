extends SceneTree
const FloorSpace=preload("res://campuses/future_learning_center/scripts/floor_space.gd")
const Body=preload("res://scripts/player_metrics.gd")
const Space=preload("res://scripts/space/spatial_rules.gd")
const ANCHORS=["koala_desk_94","machinery_workbench_77","electrical_assembly_bench","seminar_discussion_table_49","platform_discussion_table_38","robotics_workbench_30","team_desk_6","formula_workbench_0","formula_workbench_1","robotics_workbench_31","team_desk_18"]
var checks:=0
var failures:=0
func check(value:bool,label:String)->void:
 checks+=1
 if not value:failures+=1;push_error(label)
func _initialize()->void:
 var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://campuses/future_learning_center/data/floor_2.json"))
 var space=FloorSpace.new();space.configure(data)
 var origin:=Vector2(data.spawn[0],data.spawn[1])-Body.FOOT_CENTER_OFFSET
 for anchor:String in ANCHORS:
  var found:Array=data.objects.filter(func(o:Dictionary)->bool:return o.id==anchor)
  check(found.size()==1,"One existing object: "+anchor)
  if found.size()!=1:continue
  var box:Rect2=Space.rect(found[0].footprint)
  var reachable:=false
  for offset:Vector2 in [Vector2(0,65),Vector2(-65,0),Vector2(65,0),Vector2(0,-65)]:
   var target:Vector2=box.get_center()+offset+Vector2(signf(offset.x)*box.size.x/2,signf(offset.y)*box.size.y/2)-Body.FOOT_CENTER_OFFSET
   if space.can_stand(target) and not space.route(origin,target).is_empty() and not space.route(target,origin).is_empty():reachable=true;break
  check(reachable,"Complete feet and round-trip approach: "+anchor)
 print("FLC_2F_PLACEMENT: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
