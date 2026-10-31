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
  for key:String in ["recording","studio_3"]:
   var floor_view=host.floor_view
   floor_view.load_floor(3)
   var item:Dictionary=floor_view.puzzle_anchor(key);var box:Rect2=floor_view.Space.rect(item.footprint)
   for offset:Vector2 in [Vector2(0,65),Vector2(-65,0),Vector2(65,0),Vector2(0,-65)]:
    if floor_view.set_foot(box.get_center()+offset+Vector2(signf(offset.x)*box.size.x/2,signf(offset.y)*box.size.y/2)):break
   check(floor_view.open_puzzle(key),key+" host opens");await frames()
   var view=floor_view.active_puzzle;view.set_process(false)
   if key=="recording":
    var rev:int=view.model.revision
    touch(view,10,Vector2(441,280),true);motion(view,10,Vector2(441,130));touch(view,11,Vector2(441,130),false)
    check(view.touch_id==10 and view.baffle_drag,key+" foreign touch cannot release")
    check(view.model.baffle_y==150,key+" exact baffle grab offset")
    check(view.visuals.object_at("Baffle",Vector2.ZERO)==Vector2(441,150),key+" same-event direct sprite follow")
    touch(view,10,Vector2(441,130),false,true);touch(view,10,Vector2(441,130),false)
    check(view.model.baffle_y==300 and view.model.revision==rev,key+" cancel restores only gesture state")
    touch(view,12,Vector2(441,280),true);motion(view,12,Vector2(441,130));touch(view,12,Vector2(441,130),false)
    touch(view,13,Vector2(733,210),true);motion(view,13,Vector2(733,259));touch(view,13,Vector2(733,259),false)
    check(view.model.running and view.model.direction==1,key+" root touch starts real feed")
    for i:int in 70:view._process(.1)
    check(view.model.x==670,key+" feed reaches stop")
    touch(view,14,Vector2(441,150),true);motion(view,14,Vector2(441,300));touch(view,14,Vector2(441,300),false)
    touch(view,15,Vector2(670,185),true);touch(view,15,Vector2(670,185),false)
    for i:int in 7:view._process(.1)
    check(view.model.completed and view.model.photo_kind=="clear",key+" full touch sequence completes")
   else:
    var rev:int=view.model.revision
    touch(view,20,Vector2(450,260),true);motion(view,20,Vector2(312,260));touch(view,21,Vector2(312,260),false)
    check(view.touch_id==20 and view.tape_drag==1,key+" foreign touch cannot release")
    check(is_equal_approx(view.model.offsets[1],-138),key+" paper exact drag delta")
    check(is_equal_approx(view.visuals.objects.Paper1Tile1.position.x,view.visuals.PAPER_APERTURE_SIZE.x*.5-138),key+" paper pixels follow in same event")
    touch(view,20,Vector2(312,260),false,true);touch(view,20,Vector2(312,260),false)
    check(view.model.offsets[1]==0 and view.model.revision==rev,key+" canceled strip restores origin")
    touch(view,22,Vector2(450,260),true);motion(view,22,Vector2(312,260));touch(view,22,Vector2(312,260),false)
    touch(view,23,Vector2(740,383),true);touch(view,23,Vector2(740,383),false)
    for i:int in 34:view._process(.1)
    check(view.model.completed and view.model.receipts.back().passed,key+" full touch sequence completes")
    touch(view,24,Vector2(850,464),true);touch(view,24,Vector2(850,464),false)
    check(view.model.dataset==1 and not view.model.transfer_completed,key+" visible roll selects second data")
   view.close();check(floor_view.open_puzzle(key),key+" reopens")
   check(floor_view.active_puzzle.model.completed,key+" reentry retains completion")
   floor_view.active_puzzle.close()
  host.queue_free();await frames()
 print("FLC_RECORDING_SCALED_HOST %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
