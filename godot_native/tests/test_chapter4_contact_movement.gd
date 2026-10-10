extends SceneTree
const Metrics=preload("res://scripts/player_metrics.gd")
var checks:=0
var failures:=0
func _initialize():run.call_deferred()
func check(value:bool,label:String):
 checks+=1
 if not value:failures+=1;push_error(label)
func run():
 create_timer(15).timeout.connect(func():push_error("Contact test watchdog");quit(2))
 var state=root.get_node("State");state.developer_mode=true;state.d=state.initial()
 var s:Dictionary=state.d
 s.runtimeMode="rpg";s.rpgScene="duan_yongping_temporal_maze"
 s.native.chapter=4;s.native.scene=s.rpgScene;s.native.page="c4_notes";s.native.mode="light"
 s.chapter4.prologueSeen=true;s.chapter4.phase="bakery_hour_hand";s.chapter4.floor="A1";s.chapter4.timeState="1225_bakery";s.chapter4.mode="light";s.chapter4.worldTimeSeconds=44700;s.chapter4.factIds=["hall_clock_inspected"]
 var world=load("res://scripts/world.gd").new();world.size=Vector2(960,540);root.add_child(world);world.set_process(false);world.refresh_world();await process_frame
 var counter:=Rect2();var rope:=Rect2()
 for obstacle:Dictionary in world.collisions:
  if obstacle.get("id","")=="a1_air_wall_bakery_counter":counter=world._rect(obstacle)
  if obstacle.get("id","")=="a1_midday_queue_rope":rope=world._rect(obstacle)
 var feet:Rect2=Metrics.foot_rect(Vector2.ZERO)
 check(counter==Rect2(80,292,397,90) and rope==Rect2(129,398,325,10),"Exact original occupied geometry")
 check(feet.size==Vector2(19.5,14.625),"Full source foot box retained")
 var low:float=counter.end.y-feet.position.y;var high:float=rope.position.y-feet.end.y
 check(is_equal_approx(high-low,1.375),"Original gap has 1.375px legal anchor band")
 var lamp:Dictionary={}
 for target:Dictionary in world.targets:
  if target.id=="a1_bakery_inspection_lamp":lamp=target
 check(not lamp.is_empty() and float(lamp.get("radius",0))==56,"Original lamp proximity retained")
 var before:String=JSON.stringify(state.d)
 for dt:float in [1.0/120,1.0/60,1.0/30,0.05]:
  var p:=Vector2(467.114685,359.449463)
  check(world.can_stand(p),"Actual stalled pose remains legal")
  for i in range(4):
   var step:=Vector2(0,-176*dt);var next:Vector2=world._c4_axis_destination(p,step)
   check(world.can_stand(next) and next.distance_to(p)<=step.length()+.001,"No overlap or excess movement at contact")
   p=next
  check(absf(p.y-low)<.002,"Reach the source counter contact at dt="+str(dt))
  var traversed:=true
  for i in range(90):
   if p.x<=374.001:break
   var step:=Vector2(-minf(176*dt,p.x-374),0);var next:Vector2=world._c4_axis_destination(p,step)
   if not world.can_stand(next) or next.distance_to(p)>step.length()+.001:traversed=false
   p=next
  check(traversed and absf(p.x-374)<.002 and p.y>=low-.001 and p.y<=high+.001,"Traverse unchanged narrow lane")
  world.player=p
  check(not lamp.is_empty() and world._distance(lamp)<=float(lamp.radius),"Original lamp remains reachable without radius change")
 var below:=Vector2(345,450)
 var stopped:Vector2=world._c4_axis_destination(below,Vector2(0,-200))
 check(world.can_stand(stopped) and Metrics.foot_rect(stopped).position.y>=rope.end.y-.001,"Long component cannot tunnel across the rope")
 check(stopped.y<below.y and stopped.y>counter.end.y,"Stops at the first full-foot contact")
 check(world._c4_axis_destination(Vector2(345,381),Vector2(0,4))==Vector2(345,385),"A bounded move may escape an already-overlapped dynamic start")
 check(world._c4_axis_destination(Vector2(345,350),Vector2(0,1))==Vector2(345,350),"No automatic teleport from an invalid start")
 check(JSON.stringify(state.d)==before,"Contact calculation never writes story/save state")
 world.queue_free();await process_frame
 print("CHAPTER4_CONTACT_MOVEMENT ",checks," checks; ",failures," failures")
 quit(1 if failures else 0)
