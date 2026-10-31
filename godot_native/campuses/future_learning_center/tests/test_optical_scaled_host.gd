extends SceneTree
## Root-dispatched touch integration; near-anchor fixture is not walking-route QA.
var checks:=0
var failures:=0
var host:Control
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func frames()->void:
 for i:int in 3:await process_frame
func touch(view,id:int,at:Vector2,down:bool,canceled:=false)->void:
 var e:=InputEventScreenTouch.new();e.index=id;e.position=host.surface.get_global_transform_with_canvas()*view.get_global_transform_with_canvas()*at;e.pressed=down;e.canceled=canceled;root.push_input(e)
func motion(view,id:int,at:Vector2)->void:
 var e:=InputEventScreenDrag.new();e.index=id;e.position=host.surface.get_global_transform_with_canvas()*view.get_global_transform_with_canvas()*at;root.push_input(e)
func run()->void:
 for viewport_size:Vector2i in [Vector2i(1280,720),Vector2i(844,390),Vector2i(390,844)]:
  root.size=viewport_size
  host=load("res://scripts/games/future_learning_center/view.gd").new();root.add_child(host)
  host.configure_activity_layout(Vector2(viewport_size),viewport_size.x<900);host.floor_view.persistence_enabled=false;await frames()
  for key:String in ["collab_b","seminar_3"]:
   var floor_view=host.floor_view
   floor_view.load_floor(4)
   var item:Dictionary=floor_view.puzzle_anchor(key);var box:Rect2=floor_view.Space.rect(item.footprint)
   for offset:Vector2 in [Vector2(0,65),Vector2(-65,0),Vector2(65,0),Vector2(0,-65)]:
    if floor_view.set_foot(box.get_center()+offset+Vector2(signf(offset.x)*box.size.x/2,signf(offset.y)*box.size.y/2)):break
   check(floor_view.open_puzzle(key),key+" host opens");await frames()
   var view=floor_view.active_puzzle;view.set_process(false)
   var start:Vector2=view.logical_position_of(0);var target:Vector2=view.projected(view.Model.SLOT_POINTS[0])
   touch(view,10,start,true);motion(view,10,target);touch(view,11,target,false)
   check(view.touch_id==10 and view.drag==0,key+" foreign touch cannot release")
   check(view.visuals.object_at("Baffle0",Vector2.ZERO).is_equal_approx(target),key+" root drag follows without tween lag")
   touch(view,10,target,false,true);touch(view,10,target,false)
   check(view.model.slots[0]==-1 and view.drag==-1,key+" canceled root touch preserves model")
   touch(view,12,start,true);motion(view,12,target);touch(view,12,target,false)
   check(view.model.slots[0]==0,key+" root touch commits slot")
   if key=="seminar_3":
    var old:float=view.model.bracket_x;var bracket:Vector2=view.bracket_position();var dest:Vector2=view.projected(Vector2(65,65))
    touch(view,13,bracket,true);motion(view,13,dest);touch(view,13,dest,false,true)
    check(view.model.bracket_x==old,key+" bracket cancel preserves position")
    touch(view,14,bracket,true);motion(view,14,dest);touch(view,14,dest,false)
    check(is_equal_approx(view.model.bracket_x,65),key+" root touch commits bracket")
   view.close();check(floor_view.open_puzzle(key),key+" reopens")
   check(floor_view.active_puzzle.model.slots[0]==0,key+" reentry retains placement")
   floor_view.active_puzzle.close()
  host.queue_free();await frames()
 print("FLC_OPTICAL_SCALED_HOST %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
