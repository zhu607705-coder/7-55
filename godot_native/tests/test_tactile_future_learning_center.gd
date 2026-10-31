extends SceneTree
## Combined FLC navigation retains current controls and single-owner joystick input.
var checks:=0
var failures:=0
func _initialize() -> void:run.call_deferred()
func check(ok: bool, message: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(message)
func frames() -> void:
 for unused in 4:await process_frame
func buttons(node: Node,result: Array[Button]) -> void:
 for child: Node in node.get_children():
  if child is Button:result.append(child)
  buttons(child,result)
func click(button: Button) -> void:
 var point:=button.get_global_rect().get_center()
 for down: bool in [true,false]:
  var event:=InputEventMouseButton.new();event.position=point;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=down
  root.push_input(event);await frames()
func run() -> void:
 root.size=Vector2i(960,540);OS.set_environment("FLC_TOUCH","1")
 var floor=load("res://campuses/future_learning_center/scripts/floor_view.gd").new()
 floor.capture_only=true;root.add_child(floor);await frames()
 var controls: Array[Button]=[];buttons(floor.ui,controls)
 check(controls.size()==6,"current floor has overview, time, transit and three floor choices")
 check(is_instance_valid(floor.joystick),"current analog joystick survives shared-button integration")
 for button: Button in controls:
  check(button.get_meta("tactile_variant","")=="secondary","dark HUD has readable neutral light keys")
  check(button.get_node_or_null("TactileMaterialState")!=null,"latest main control adopted")
  var baseline:=Button.new();baseline.text=button.text
  baseline.size=Vector2(155,30) if button.text.contains("楼层") else Vector2(38,38)
  baseline.add_theme_font_override("font",button.get_theme_font("font"))
  baseline.add_theme_font_size_override("font_size",button.get_theme_font_size("font_size"))
  baseline.set_meta("tactile_exempt",true);baseline.hide();root.add_child(baseline)
  await frames()
  var baseline_size: Vector2=baseline.size
  baseline.free()
  if button.text.contains("楼层"):
   check(button.get_rect().is_equal_approx(Rect2(Vector2(790,5),baseline_size)),"overview keeps original resolved header target")
   await click(button);check(floor.overview,"real pointer invokes original overview callback")
   await click(button);check(not floor.overview,"overview returns without replacing original action")
 var before_time:int=floor.time_index
 await click(floor.time_button)
 check(floor.time_index!=(before_time),"time button keeps its existing lighting action")
 var stick:Control=floor.joystick
 var point:Vector2=stick.get_global_transform_with_canvas()*(stick.CENTER+Vector2(30,0))
 var touch:=InputEventScreenTouch.new();touch.index=4;touch.position=point;touch.pressed=true
 root.push_input(touch);await frames()
 check(floor.touch_vector.x>.2,"joystick receives the real touch independently of buttons")
 touch=touch.duplicate();touch.pressed=false;touch.canceled=true
 root.push_input(touch);await frames()
 check(floor.touch_vector==Vector2.ZERO and stick.pointer_owner==-2,"canceled joystick releases movement ownership")
 touch=touch.duplicate();touch.index=5;touch.pressed=true;touch.canceled=false
 root.push_input(touch);await frames()
 check(floor.touch_vector.x>.2,"next joystick touch works without reloading")
 stick.cancel()
 floor.queue_free();await frames()
 print("TACTILE_FLC: ",checks," checks; ",failures," failures")
 quit(1 if failures else 0)
