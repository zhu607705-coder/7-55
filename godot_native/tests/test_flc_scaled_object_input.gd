extends SceneTree
var checks:=0
var failures:=0
var host:Control
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error("SCALED_OBJECT_INPUT "+label)
func frames()->void:
 for i:int in 3:await process_frame
func screen(at:Vector2)->Vector2:return host.surface.get_global_transform_with_canvas()*at
func touch(id:int,at:Vector2,down:bool,cancelled:=false)->void:
 var e:=InputEventScreenTouch.new();e.index=id;e.position=screen(at);e.pressed=down;e.canceled=cancelled;root.push_input(e)
func motion(id:int,at:Vector2)->void:
 var e:=InputEventScreenDrag.new();e.index=id;e.position=screen(at);root.push_input(e)
func open_room(key:String,floor_number:int)->Node:
 if is_instance_valid(host.floor_view.active_puzzle) and host.floor_view.active_puzzle.visible:host.floor_view.active_puzzle.close()
 host.floor_view.load_floor(floor_number);host.floor_view.set_foot(host.floor_view.puzzle_approach(key));host.floor_view.open_puzzle(key)
 await frames();return host.floor_view.active_puzzle
func run()->void:
 for viewport_size:Vector2i in [Vector2i(1280,720),Vector2i(844,390),Vector2i(390,844)]:
  root.size=viewport_size
  host=load("res://scripts/games/future_learning_center/view.gd").new();root.add_child(host);host.configure_activity_layout(Vector2(viewport_size),viewport_size.x<900);host.floor_view.persistence_enabled=false;await frames()
  var prefix:=str(viewport_size)+" "
  var formula=await open_room("formula",2)
  var tilt:int=formula.model.tilt
  touch(2,formula.TILT_KNOB,true);motion(2,formula.TILT_KNOB-Vector2(0,24));touch(3,formula.GATE,true);touch(3,formula.GATE,false)
  check(formula.touch_id==2 and not formula.model.running,prefix+"formula second touch cannot steal or launch")
  touch(2,formula.TILT_KNOB-Vector2(0,24),false,true);touch(2,formula.TILT_KNOB-Vector2(0,24),false);await frames()
  check(formula.model.tilt==tilt and formula.action.is_empty(),prefix+"formula cancel and late release preserve tilt")
  touch(4,formula.TILT_KNOB,true);motion(4,formula.TILT_KNOB-Vector2(0,24));touch(4,formula.TILT_KNOB-Vector2(0,24),false);await frames()
  check(formula.model.tilt==1,prefix+"formula root pointer sets30degree")
  formula.close();formula=await open_room("formula",2)
  check(formula.model.tilt==1,prefix+"formula reentry retains edit")
  var focus=await open_room("focus_a",4)
  var plug:Vector2=focus.plug_position(0);var original:int=focus.model.assignments[0];var dest:Vector2=focus.BRANCH_POS[0]+Vector2(0,28)
  touch(5,plug,true);motion(5,dest);touch(6,dest,false);check(focus.touch_id==5,prefix+"focus second finger cannot release")
  touch(5,dest,false,true);touch(5,dest,false);await frames()
  check(focus.model.assignments[0]==original and focus.drag<0,prefix+"focus cancel preserves circuit")
  touch(7,plug,true);motion(7,dest);touch(7,dest,false);await frames()
  check(focus.model.assignments[0]==0,prefix+"focus root pointer attaches actual plug")
  var schedule=await open_room("seminar",3)
  var card:Vector2=schedule.card_point(0);var slot:int=schedule.model.slots[0];var target:=Vector2(545,card.y)
  touch(8,card,true);motion(8,target);touch(8,target,false,true);touch(8,target,false);await frames()
  check(schedule.model.slots[0]==slot and schedule.held_task<0,prefix+"schedule cancel preserves beat")
  touch(9,card,true);motion(9,target);touch(9,target,false);await frames()
  check(schedule.model.slots[0]==1,prefix+"schedule root pointer moves artifact card")
  var before:Array=schedule.model.slots.duplicate()
  touch(10,Vector2(110,460),true);touch(10,Vector2(110,460),false);await frames()
  check(schedule.paper_open and schedule.model.slots==before,prefix+"schedule help opens without progression")
  var room_at:Vector2=host.room_back.get_global_rect().get_center()
  for down:bool in [true,false]:
   var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=down;event.position=room_at;root.push_input(event)
  await frames();check(not schedule.visible,prefix+"actual shared room return closes once")
  host.queue_free();await frames()
 print("FLC_SCALED_OBJECT_INPUT %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
