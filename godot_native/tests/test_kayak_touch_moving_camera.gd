extends "res://tests/test_lake_paddle_pointer.gd"
## Keep actual world ticks enabled while a finger holds the moving paddle.
func finger(point:Vector2,down:bool,index:int=7)->void:
 var event:=InputEventScreenTouch.new();event.index=index;event.position=point;event.pressed=down
 root.push_input(event,true)
func moving_fixture()->void:
 await reset(Vector2i(390,844))
 var world:Control=shell.world
 var placed:=false
 for y:int in range(260,700,40):
  for x:int in range(320,1300,40):
   if world.can_stand(Vector2(x,y)):
    world.player=Vector2(x,y);world.kayak.position=world.player;placed=true;break
  if placed:break
 check(placed,"fixture has legal water for real movement")
 state.lake_module().live_session=null;world.lake_session=state.lake_module().bind_world(state.d,world)
 world._sync_player();world._process(0);await frames()
 var first:Vector2=center("left")
 finger(first,true);finger(first,false)
 check(count()==1,"first ordinary paddle stroke starts actual kayak motion")
 world.set_process(true)
func run()->void:
 if not load("res://tests/native_test_isolation.gd").is_isolated_save():quit(2);return
 state=root.get_node("State");state.developer_mode=false
 await moving_fixture()
 var world:Control=shell.world
 var point:Vector2=center("right")
 var old_camera:Vector2=world.camera;var old_player:Vector2=world.player
 finger(point,true)
 check(world.direct_gestures.has_active(),"second finger owns the right paddle before movement")
 await frames(8)
 check(world.player.distance_to(old_player)>0 and world.camera.distance_to(old_camera)>0,"ordinary processing advances both boat and following camera during hold")
 check(world.direct_gestures.has_active(),"following camera does not cancel held paddle")
 finger(point,false)
 check(count()==2 and world.kayak.last_side=="right","release after moving frames records exactly the second stroke")
 finger(point,false);check(count()==2,"duplicate release remains neutral")
 await moving_fixture();world=shell.world
 var left:Vector2=center("left");var right:Vector2=center("right")
 finger(left,true,1);finger(left,true,2);finger(right,true,3);await frames(3)
 finger(left,false,1);await frames(3);finger(right,false,3);finger(left,false,2)
 check(count()==3,"ignored competing finger cannot cancel the other paddle after original owner lifts")
 for reason:String in ["focus","zoom","pan","mode","phone","modal","scene"]:
  await moving_fixture();world=shell.world
  var held_model:RefCounted=world.kayak
  point=center("right");finger(point,true)
  check(world.direct_gestures.has_active(),reason+" case owns a finger before interruption")
  match reason:
   "focus":world._notification(Control.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
   "zoom":world.zoom*=1.1
   "pan":world.pan_offset+=Vector2(10,0);world._update_camera()
   "mode":state.toggle_mode()
   "phone":shell._show_phone_surface()
   "modal":shell._show_world_journal()
   "scene":state.d.native.scene="campus_bootstrap"
  await frames(3);finger(point,false)
  check(held_model.inputs.size()==1,reason+" change cancels old stroke without transferring ownership")
  if reason=="modal":shell._close_modal()
 await shell.shutdown();shell.free();await frames()
 print("KAYAK_TOUCH_MOVING_CAMERA: ",checks," checks; ",failures," failures")
 quit(1 if failures else 0)
