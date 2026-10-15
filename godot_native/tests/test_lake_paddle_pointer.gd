extends SceneTree
## Real Main/viewport event routing. This is a fixture, not manual earned play.
var state: Node
var shell: Control
var checks:=0
var failures:=0
func _initialize() -> void:run.call_deferred()
func check(ok: bool,label: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error("PADDLE POINTER: "+label)
func frames(count: int=2) -> void:
 for i in range(count):await process_frame
func screen(point: Vector2) -> Vector2:
 return shell.world_view.get_global_transform_with_canvas()*(point*shell.world_view.size/Vector2(shell.world_viewport.size))
func mouse(point: Vector2,pressed: bool,device: int=0) -> void:
 var e:=InputEventMouseButton.new();e.button_index=MOUSE_BUTTON_LEFT;e.position=point;e.global_position=point;e.pressed=pressed;e.device=device;root.push_input(e,true);await frames()
func motion(point: Vector2) -> void:
 var e:=InputEventMouseMotion.new();e.position=point;e.global_position=point;e.button_mask=MOUSE_BUTTON_MASK_LEFT;root.push_input(e,true);await frames()
func reset(dims: Vector2i=Vector2i(430,860)) -> void:
 if is_instance_valid(shell):await shell.shutdown();shell.free();await frames()
 state.d=state.initial();var s: Dictionary=state.d
 s.native.chapter=3;s.native.scene="qizhen_lake";s.native.page="c3_lake";s.native.mode="light";s.runtimeMode="rpg";s.rpgScene="qizhen_lake"
 s.qizhenLake.merge({"active":true,"phase":"tool_chain","zone":"channel","vehicle":"kayak","boardingTutorialCompleted":true,"rainSafetyCleared":true,"kayakEquipped":true,"leftPaddleEquipped":true,"rightPaddleEquipped":true},true)
 root.size=dims;shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames();shell._show_world_mobile();shell._layout();await frames();shell.set_process(false);shell.world.set_process(false)
func count() -> int:return shell.world.kayak.inputs.size()
func center(side: String) -> Vector2:
 var size: Vector2=shell.world.size
 return screen(Vector2(120 if side=="left" else size.x-120,size.y-130))
func run() -> void:
 if not OS.get_user_data_dir().begins_with("/tmp/"):quit(2);return
 state=root.get_node("State");state.developer_mode=false
 for dims: Vector2i in [Vector2i(390,844),Vector2i(430,860)]:
  await reset(dims)
  for side: String in ["left","right"]:
   var p:=center(side);var n:=count()
   await mouse(p,true);check(count()==n,"press waits for release "+side+str(dims))
   await mouse(p,false);check(count()==n+1,"painted button release strokes once "+side+str(dims))
   check(count()>n and shell.world.kayak.inputs[-1].side==side and shell.world.kayak.inputs[-1].direction=="forward","correct source side and ordinary forward stroke")
  var n:=count();await mouse(center("left"),false);check(count()==n,"duplicate release has no effect")
  var center_gap:=screen(Vector2(shell.world.size.x/2,shell.world.size.y-130))
  await mouse(center_gap,true);await mouse(center_gap,false);check(count()==n,"gap between painted paddles is not an extra button")
 await reset()
 var p:=center("left");await mouse(p,true);await motion(p+Vector2(0,45));await mouse(p+Vector2(0,45),false)
 check(count()==1 and shell.world.kayak.last_direction=="reverse","downward drag keeps existing reverse semantics")
 var n:=count();p=center("right");await mouse(p,true);await motion(Vector2(428,50));await mouse(Vector2(428,50),false)
 check(count()==n+1 and shell.world.kayak.last_side=="right","captured release outside world completes original side exactly once")
 await reset();p=center("left");await mouse(p,true);shell.world._notification(Control.NOTIFICATION_WM_WINDOW_FOCUS_OUT);await mouse(p,false)
 check(count()==0,"focus loss cancels without a late stroke")
 await mouse(center("right"),true);root.size=Vector2i(390,844);shell._layout();await frames();await mouse(center("right"),false)
 check(count()==0,"resize cancels held pointer without transfer")
 await mouse(center("left"),true);shell._show_phone_surface();await frames();await mouse(Vector2(100,100),false);shell._show_world_mobile();await frames()
 check(count()==0,"phone switch cancels held pointer")
 await mouse(center("left"),true);shell._show_world_journal();await frames();await mouse(center("left"),false)
 check(count()==0,"Tasks modal cannot finish an old paddle")
 shell._close_modal();await frames()
 await mouse(center("left"),true);shell.world_effect=Control.new();shell.world_effect.set_meta("blocks_input",true);shell.add_child(shell.world_effect)
 await mouse(center("left"),false);check(count()==0,"blocking world presentation cancels old pointer")
 shell.world_effect.free();shell.world_effect=null
 # A real finger has an existing native route; emulated mouse must not duplicate it.
 var start:=Vector2(120,shell.world.size.y-130);var touch:=InputEventScreenTouch.new();touch.index=7;touch.position=start;touch.pressed=true;shell.world_viewport.push_input(touch,true);await frames()
 n=count();await mouse(screen(start),true,-1);await mouse(screen(start),false,-1);check(count()==n,"touch-emulated mouse grants no paddle")
 await mouse(screen(start),true);await mouse(screen(start),false);check(count()==n,"real mouse cannot steal a finger-owned same-side paddle")
 touch=touch.duplicate();touch.pressed=false;shell.world_viewport.push_input(touch,true);await frames()
 check(count()==n+1 and shell.world.kayak.last_side=="left","existing finger route still strokes exactly once")
 p=center("right");n=count();await mouse(p,true)
 touch=InputEventScreenTouch.new();touch.index=9;touch.position=Vector2(shell.world.size.x-120,shell.world.size.y-130);touch.pressed=true;shell.world_viewport.push_input(touch,true);await frames()
 touch=touch.duplicate();touch.pressed=false;shell.world_viewport.push_input(touch,true);await frames()
 check(count()==n,"finger cannot steal a mouse-owned same-side paddle")
 await mouse(p,false);check(count()==n+1 and shell.world.kayak.last_side=="right","original owner releases once after competing pointer")
 touch=InputEventScreenTouch.new();touch.index=11;touch.position=start;touch.pressed=true;shell.world_viewport.push_input(touch,true);await frames();n=count()
 touch=touch.duplicate();touch.pressed=false;touch.canceled=true;shell.world_viewport.push_input(touch,true);await frames()
 check(count()==n,"native finger cancellation remains neutral")
 await reset(Vector2i(1180,812));var hidden:=center("left");await mouse(hidden,true);await mouse(hidden,false)
 check(count()==0,"desktop hidden controls do not steal ordinary water clicks")
 shell.world.touch_controls=true;await mouse(center("left"),true);await mouse(center("left"),false)
 check(count()==1 and shell.world.kayak.last_side=="left","visible touch-capability fallback also works at desktop width")
 check(shell.world.lake_session.status=="running" and state.d.qizhenLake.capsizeCount==0,"input fixtures retain controller proof and no invented failure")
 await shell.shutdown();shell.free();await frames()
 print("LAKE_PADDLE_POINTER: ",checks," checks; ",failures," failures")
 quit(1 if failures else 0)
