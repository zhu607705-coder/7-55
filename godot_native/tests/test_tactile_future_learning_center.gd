extends SceneTree
## New main533ed6b navigation must retain its authored compact targets.
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
 var controls: Array[Button]=[];buttons(floor,controls)
 check(controls.size()==5,"latest main has one overview and four direction controls")
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
  else:
   check(button.size.is_equal_approx(baseline_size),"direction keeps original engine-resolved 38px target")
   check(button.get_theme_font_size("font_size")==22,"direction glyph retains readable icon size")
   var event:=InputEventMouseButton.new();event.position=button.get_global_rect().get_center();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=true
   root.push_input(event);await frames()
   check(floor.touched_buttons.has(button.text),"press retains direction ownership")
   event=event.duplicate();event.pressed=false;root.push_input(event);await frames()
   check(floor.touched_buttons.is_empty(),"release clears original direction ownership")
 floor.queue_free();await frames()
 print("TACTILE_FLC: ",checks," checks; ",failures," failures")
 quit(1 if failures else 0)
