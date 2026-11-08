extends SceneTree
const Planner=preload("res://scripts/mobile_floor_route.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func _initialize()->void:
 var planner:=Planner.new()
 var bounds:=Rect2(0,0,100,100)
 var root:=Rect2(40,40,20,20)
 var stand:Callable=func(p:Vector2)->bool:return bounds.has_point(p) and not root.has_point(p)
 var clear:Callable=func(a:Vector2,b:Vector2)->bool:return not Planner.segment_hits(a,b,root)
 var corners:Array[Vector2]=[Vector2(39.75,39.75),Vector2(60.25,39.75),Vector2(60.25,60.25),Vector2(39.75,60.25)]
 var start:=Vector2(50,20);var goal:=Vector2(50,80)
 check(planner.plan(start,goal,[],bounds,stand,clear).is_empty(),"old graph reproduces missing-campus-corner failure")
 var route:Array[Vector2]=planner.plan_with_candidates(start,goal,[],bounds,stand,clear,corners)
 check(route.size()>1 and route[-1]==goal,"extra nodes provide real detour and exact goal")
 var previous:=start
 for p:Vector2 in route:
  check(stand.call(p) and clear.call(previous,p),"detour respects original collision authority");previous=p
 check(planner.plan_with_candidates(start,Vector2(50,50),[],bounds,stand,clear,corners).is_empty(),"solid endpoint still blocked")
 var direct:Array[Vector2]=planner.plan_with_candidates(Vector2(20,20),Vector2(80,20),[],bounds,stand,clear,corners)
 check(direct==[Vector2(80,20)],"candidate bounding corners do not become collision boxes")
 check(planner.plan_with_candidates(Vector2(-1,20),goal,[],bounds,stand,clear,corners).is_empty(),"world bounds retained")
 print("V10 detour candidates: ",checks," checks, ",failures," failures")
 quit(0 if failures==0 else 1)
