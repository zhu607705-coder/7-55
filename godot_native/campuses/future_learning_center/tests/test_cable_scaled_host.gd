extends SceneTree
## Native root-dispatched input at three screen sizes, not physical-phone QA.
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
func tap(view,id:int,at:Vector2)->void:touch(view,id,at,true);touch(view,id,at,false)
func tick(view,count:int)->void:
 for i:int in count:view._process(.1)
func run()->void:
 for viewport_size:Vector2i in [Vector2i(1280,720),Vector2i(844,390),Vector2i(390,844)]:
  root.size=viewport_size
  host=load("res://scripts/games/future_learning_center/view.gd").new();root.add_child(host)
  host.configure_activity_layout(Vector2(viewport_size),viewport_size.x<900);host.floor_view.persistence_enabled=false;await frames()
  for key:String in ["team","flex_c"]:
   var floor_view=host.floor_view;floor_view.load_floor(2 if key=="team" else 4)
   var item:Dictionary=floor_view.puzzle_anchor(key);var box:Rect2=floor_view.Space.rect(item.footprint)
   for offset:Vector2 in [Vector2(0,65),Vector2(-65,0),Vector2(65,0),Vector2(0,-65)]:
    if floor_view.set_foot(box.get_center()+offset+Vector2(signf(offset.x)*box.size.x/2,signf(offset.y)*box.size.y/2)):break
   check(floor_view.open_puzzle(key),key+" host opens actual anchor");await frames()
   var view=floor_view.active_puzzle;view.set_process(false)
   check(view.get_script().resource_path.ends_with("/puzzles/signal_sync_view.gd" if key=="team" else "/puzzles/flex_view.gd"),key+" exact intended view")
   check(view.is_visible_in_tree() and view.visuals!=null,key+" generated apparatus actually visible")
   if key=="team":
    var start:Vector2=view.model.positions[0]
    touch(view,10,start+Vector2(10,-5),true);motion(view,10,start+Vector2(70,35));touch(view,11,start,false)
    check(view.touch_id==10 and view.screen_drag==0,key+" foreign finger cannot release")
    check(view.model.positions[0].is_equal_approx(start+Vector2(60,40)),key+" exact same-event grasp offset")
    check(view.visuals.objects.Socket_screen_a.position.is_equal_approx(view.port_at("screen_a")),key+" socket visual stays on moving model port")
    touch(view,10,start+Vector2(70,35),false,true);touch(view,10,start,false)
    check(view.model.positions[0].is_equal_approx(start),key+" cancellation and late release restore screen")
    touch(view,12,view.port_at("screen_b")+Vector2(5,3),true);motion(view,12,view.port_at("live_b")+Vector2(5,3));touch(view,12,view.port_at("live_b")+Vector2(5,3),false)
    check(view.model.cables.screen_b=="live_b",key+" real touch rewires live socket")
    tap(view,13,Vector2(150,225));tick(view,14)
    check(view.model.receipts.size()==1 and not view.model.completed,key+" one change insufficient")
    tap(view,14,Vector2(150,225));tick(view,14)
    check(view.model.completed and view.model.receipts.size()==2,key+" full touch signal sequence completes")
   else:
    var board_id:int=view.visuals.board.get_instance_id()
    touch(view,20,Vector2(610,232),true);motion(view,20,Vector2(450,420));touch(view,21,Vector2(450,420),false)
    check(view.touch_id==20 and view.model.connections==[0,1,2],key+" foreign finger cannot commit pending unplug")
    touch(view,20,Vector2(450,420),false,true);touch(view,20,Vector2(450,420),false)
    check(view.model.connections==[0,1,2],key+" canceled cable preserves connectivity")
    for i:int in 2:tap(view,22+i,Vector2(730,300));tick(view,16)
    check(view.model.station_proofs[0] and not view.model.completed,key+" first station needs actual two trials")
    touch(view,24,Vector2(490,122),true);motion(view,24,Vector2(530,152))
    check(view.board_offset().is_equal_approx(Vector2(40,30)),key+" board follows off-center grip")
    check(view.visuals.board.position.is_equal_approx(view.board_offset()),key+" entire board follows same-event transform")
    touch(view,24,Vector2(530,152),false,true)
    check(view.model.station==0 and view.board_offset().is_equal_approx(Vector2.ZERO),key+" cancel restores same station")
    touch(view,25,Vector2(480,122),true);motion(view,25,Vector2(794,205));touch(view,25,Vector2(794,205),false);tick(view,4)
    check(view.model.station==1 and view.model.connections==[0,1,2],key+" station transfer preserves cables")
    check(view.visuals.board.get_instance_id()==board_id,key+" no duplicated board")
    tap(view,26,view.from_board(Vector2(275,164)));tap(view,27,view.from_board(Vector2(275,164)))
    check(view.model.orientation==2,key+" transformed adapter is touchable")
    for i:int in 2:tap(view,28+i,Vector2(730,300));tick(view,16)
    check(view.model.completed and view.model.station_proofs==[true,true],key+" full touch two-station sequence completes")
   view.close();check(floor_view.open_puzzle(key),key+" reopens")
   check(floor_view.active_puzzle.model.completed,key+" same model proof survives reentry")
   floor_view.active_puzzle.close()
  host.queue_free();await frames()
 print("FLC_CABLE_SCALED_HOST %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
