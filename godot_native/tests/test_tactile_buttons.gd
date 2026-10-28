extends SceneTree
## Presentation contract and synthetic native input, not physical-device proof.
const MaterialStyle=preload("res://scripts/ui/tactile_button_material.gd")
class DrawProbe extends "res://scripts/ui/tactile_button_material.gd":
 var called := false
 func _draw(canvas: RID,rect: Rect2) -> void:
  called=true
  super._draw(canvas,rect)

var checks:=0
var failures:=0
var presses:=0
func _initialize() -> void:run.call_deferred()
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error("TACTILE: "+message)
func frames() -> void:
 for unused in 3:await process_frame
func run() -> void:
 var probe:=DrawProbe.new();probe.configure("primary",1.0)
 var canvas:=RenderingServer.canvas_item_create()
 probe.draw(canvas,Rect2(0,0,160,40))
 check(probe.called,"engine draw dispatches native material hook, not Flat draw")
 RenderingServer.free_rid(canvas)
 var host:=Control.new();root.add_child(host)
 var button: Button
 for variant: String in MaterialStyle.VARIANTS:
  for size_name: String in ["md","lg"]:
   button=Button.new();button.text="确认 Continue";button.position=Vector2(20,20)
   button.set_meta("tactile_variant",variant);button.set_meta("tactile_size",size_name)
   var focus:=StyleBoxFlat.new();focus.bg_color=Color.TRANSPARENT;focus.set_border_width_all(2)
   button.add_theme_stylebox_override("focus",focus)
   host.add_child(button);await frames()
   var state: Node=button.get_node_or_null("TactileMaterialState")
   check(state!=null,"adopt "+variant+" "+size_name)
   var material: StyleBox=button.get_theme_stylebox("normal")
   var u: float=1.0 if size_name=="md" else 16.0/14.0
   check(material is MaterialStyle,"native material owned by button")
   check(material.variant==variant,"explicit variant is honored: "+variant)
   check(is_equal_approx(material.unit,u),"proportional material unit")
   check(is_equal_approx(button.custom_minimum_size.y,40*u),"40u minimum key height")
   check(is_equal_approx(material.content_margin_left,18*u),"18u horizontal padding")
   check(button.get_theme_font_size("font_size")== (14 if size_name=="md" else 16),"label scale")
   check(button.get_theme_stylebox("focus")==focus,"existing focus retained")
   for key: String in ["hover","pressed","hover_pressed","disabled"]:
    check(button.get_theme_stylebox(key)==material,"same layer stack "+key)
   var before:=Rect2(button.position,button.size)
   button.toggle_mode=true;button.button_pressed=true
   state._process(.160)
   check(is_equal_approx(material.press_amount,1),"pressed offset reaches 1u")
   check(is_equal_approx(material.shadow_press,1) and is_equal_approx(material.color_press,1),"independent shadow/color timing")
   check(Rect2(button.position,button.size)==before,"press does not move hit rect")
   button.disabled=true;await frames()
   check(button.disabled,"disabled remains controller-owned")
   button.queue_free();await frames()
 var physical:=Button.new();physical.text="纸片";physical.set_meta("tactile_exempt",true)
 host.add_child(physical);await frames()
 check(physical.get_node_or_null("TactileMaterialState")==null,"physical paper not buttonized")
 physical.queue_free()
 var dock=load("res://scripts/ui/home_charging_dock.gd").new();host.add_child(dock)
 var contact: Button=dock._target("Contact",Rect2(0,0,76,58),"连接充电座")
 await frames()
 check(contact.get_node_or_null("TactileMaterialState")==null,"real charging contact stays an object hotspot")
 dock.queue_free();await frames()
 for script_path: String in ["phone_drop_button.gd","inventory_item.gd","clock_visual_card.gd"]:
  var object_button: Button=load("res://scripts/ui/"+script_path).new()
  host.add_child(object_button);await frames()
  check(object_button.get_node_or_null("TactileMaterialState")==null,"real object exclusion: "+script_path)
  object_button.queue_free();await frames()
 var row:=Button.new();row.name="PhoneNav_Test";row.text="导航";row.size=Vector2(80,32)
 host.add_child(row);await frames()
 check(row.get_meta("tactile_variant")=="ghost","dedicated navigation uses ghost")
 check(row.size==Vector2(80,32),"navigation keeps hit layout")
 row.queue_free();await frames()
 button=Button.new();button.text="确认";button.position=Vector2(20,20);button.size=Vector2(160,48)
 host.add_child(button);button.pressed.connect(func():presses+=1);await frames()
 button.grab_focus()
 var key:=InputEventKey.new();key.keycode=KEY_ENTER;key.pressed=true;root.push_input(key)
 key=InputEventKey.new();key.keycode=KEY_ENTER;root.push_input(key);await frames()
 check(presses==1,"keyboard signal unchanged")
 var mouse:=InputEventMouseButton.new();mouse.button_index=MOUSE_BUTTON_LEFT;mouse.position=Vector2(40,40);mouse.pressed=true;root.push_input(mouse)
 mouse=InputEventMouseButton.new();mouse.button_index=MOUSE_BUTTON_LEFT;mouse.position=Vector2(40,40);root.push_input(mouse);await frames()
 check(presses==2,"pointer signal unchanged")
 button.disabled=true
 mouse=InputEventMouseButton.new();mouse.button_index=MOUSE_BUTTON_LEFT;mouse.position=Vector2(40,40);mouse.pressed=true;root.push_input(mouse)
 mouse=InputEventMouseButton.new();mouse.button_index=MOUSE_BUTTON_LEFT;mouse.position=Vector2(40,40);root.push_input(mouse);await frames()
 check(presses==2,"disabled refuses pointer activation")
 host.queue_free();await frames()
 print("TACTILE_BUTTONS: ",checks," checks; ",failures," failures")
 quit(1 if failures else 0)
