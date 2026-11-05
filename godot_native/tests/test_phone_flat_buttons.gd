extends SceneTree
## Phone-only material ownership, exact geometry, and native input regression.
## Headless synthetic input is not a claim of physical touchscreen acceptance.
const Ui=preload("res://scripts/ui/native_ui_theme.gd")
const Typography=preload("res://scripts/ui/native_typography.gd")
const Flat=preload("res://scripts/ui/phone_flat_button_material.gd")
const Tactile=preload("res://scripts/ui/tactile_button_material.gd")
const Symbols=preload("res://scripts/ui/native_symbol_icon.gd")
class PuzzleObject extends Button:
 func _draw() -> void:draw_circle(size/2,6,Color.GOLD)
var checks:=0
var failures:=0
var activations:=0
func _initialize() -> void:run.call_deferred()
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error("PHONE FLAT: "+message)
func frames(count: int=4) -> void:
 for unused in count:await process_frame
func make_button(host: Control,text: String="确认",fill: Color=Ui.PAPER,ink: Color=Ui.INK) -> Button:
 var button:=Button.new();button.text=text;button.position=Vector2(20,20);button.size=Vector2(180,48)
 Ui.apply_button(button,fill,ink,Ui.INK,0,2,22,Vector2(8,2))
 Typography.apply_body(button)
 host.add_child(button);return button
func run() -> void:
 if not load("res://tests/native_test_isolation.gd").is_isolated_save():
  push_error("Phone flat tests require an isolated /tmp user profile");quit(2);return
 root.size=Vector2i(430,860)
 var phone:=Control.new();phone.size=Vector2(430,860);phone.set_meta("phone_ui_scope",true);root.add_child(phone)
 var button:=make_button(phone)
 var authored_font: Font=button.get_theme_font("font")
 var authored_size:=button.size
 var authored_minimum:=button.custom_minimum_size
 var authored_margin:=button.get_theme_stylebox("normal").get_minimum_size()
 var authored_focus: StyleBoxFlat=button.get_theme_stylebox("focus")
 await frames()
 check(button.get_theme_stylebox("normal") is Flat,"declared phone scope uses flat material")
 check(button.get_theme_font_size("font_size")==22 and button.get_theme_font("font")==authored_font,"requested large text and font are not clamped or replaced")
 check(button.size==authored_size and button.custom_minimum_size==authored_minimum,"adoption keeps exact hit rect and minimum")
 for key: String in ["normal","hover","pressed","hover_pressed","disabled","focus"]:
  var style: StyleBoxFlat=button.get_theme_stylebox(key)
  check(style is Flat,"native state has flat material: "+key)
  check(style.shadow_size==0 and style.shadow_offset==Vector2.ZERO and style.shadow_color.a==0,"no material elevation: "+key)
  check(style.expand_margin_left==0 and style.expand_margin_top==0 and style.expand_margin_right==0 and style.expand_margin_bottom==0,"state draws inside own bounds: "+key)
 check(button.get_theme_stylebox("normal").get_minimum_size()==authored_margin,"authored content margins unchanged")
 check(button.get_theme_stylebox("normal").bg_color==Ui.PAPER and button.get_theme_color("font_color")==Ui.INK,"warm paper and charcoal ink remain authored")
 check(button.get_theme_stylebox("hover").bg_color!=button.get_theme_stylebox("normal").bg_color,"hover retains a distinct flat fill")
 check(button.get_theme_stylebox("pressed").bg_color!=button.get_theme_stylebox("hover").bg_color,"pressed retains a distinct flat fill")
 check(button.get_theme_stylebox("focus").border_color==authored_focus.border_color,"authored keyboard focus color retained")
 check(Ui._contrast(button.get_theme_color("font_disabled_color"),button.get_theme_stylebox("disabled").bg_color)>=4.5,"disabled native caption remains readable")
 # State changes are native; no transform, content shift or label emboss layer.
 button.toggle_mode=true;button.set_pressed_no_signal(true)
 var controller: Node=button.get_node("TactileMaterialState");controller._process(.2)
 check(button.button_pressed and button.size==authored_size and button.position==Vector2(20,20),"toggle stays pressed without moving geometry")
 check(button.get_theme_stylebox("pressed").get_minimum_size()==authored_margin,"press does not displace content")
 button.set_pressed_no_signal(false);button.toggle_mode=false
 for pixels: int in [14,16,22,28]:
  button.add_theme_font_size_override("font_size",pixels);await frames()
  check(button.get_theme_font_size("font_size")==pixels,"late text scale remains authoritative: "+str(pixels))
 # Late app palette refreshes must be accepted, not recolored by the adapter.
 Ui.apply_button(button,Color("2162a1"),Color.WHITE,Color("102e50"),0,2,22,Vector2(6,3));await frames()
 check(button.get_theme_stylebox("normal").bg_color==Color("2162a1"),"late authored app color survives")
 check(button.get_theme_color("font_color")==Color.WHITE,"late authored ink survives")
 check(button.get_theme_stylebox("normal").content_margin_left==6,"late authored margins survive")
 button.queue_free();await frames()
 # Empty-caption composite controls retain the background their children need.
 var composite:=make_button(phone,"",Color("2162a1"),Color.WHITE);composite.set_meta("phone_button_role","composite")
 var title:=Label.new();title.text="ZJUWLAN";title.add_theme_color_override("font_color",Color.WHITE);composite.add_child(title)
 await frames()
 check(composite.get_theme_stylebox("normal").bg_color==Color("2162a1"),"blank composite is not ghostified")
 check(title.get_theme_color("font_color")==Color.WHITE,"composite child ink stays with its authored background")
 composite.queue_free();await frames()
 # Exact explicit roles protect objects, transparent regions and full masks.
 for role: String in ["object","hit_region","mask"]:
  var target:=make_button(phone,"0" if role=="object" else "",Color("f0d54e") if role=="object" else Color(0,0,0,.72) if role=="mask" else Color.TRANSPARENT)
  target.set_meta("phone_button_role",role);target.size=Vector2(25,25);target.custom_minimum_size=Vector2.ZERO
  var original: StyleBox=target.get_theme_stylebox("normal");var before:=target.size
  await frames()
  check(target.get_node_or_null("TactileMaterialState")==null,"explicit role retains its visual owner: "+role)
  check(target.get_theme_stylebox("normal")==original and target.size==before,"role retains exact resource and geometry: "+role)
  target.queue_free();await frames()
 var custom:=PuzzleObject.new();custom.size=Vector2(23,23);phone.add_child(custom);await frames()
 check(custom.get_node_or_null("TactileMaterialState")==null,"custom puzzle rendering not replaced without an explicit UI role")
 custom.queue_free();await frames()
 var transparent:=make_button(phone,"",Color.TRANSPARENT);await frames()
 check(transparent.get_theme_stylebox("normal").bg_color.a==0,"ordinary transparent target stays transparent without caption heuristics")
 transparent.queue_free();await frames()
 # Explicit selected role adds a static shape cue without changing app blue.
 var segment:=make_button(phone,"列表",Color("39589e"),Color.WHITE)
 segment.set_meta("phone_button_role","segment");segment.set_meta("phone_button_selected",true)
 segment.toggle_mode=true;segment.set_pressed_no_signal(true)
 var segment_rect:=segment.get_rect();await frames()
 check(segment.get_theme_stylebox("normal").border_width_bottom==3,"selected segment has persistent ink rule")
 check(segment.get_theme_stylebox("normal").bg_color==Color("39589e"),"segment keeps app color identity")
 check(segment.get_rect()==segment_rect,"selected rule does not enlarge the target")
 segment.set_meta("phone_button_selected",false);segment.set_pressed_no_signal(false);await frames()
 check(segment.get_theme_stylebox("normal").border_width_bottom==2,"deselection restores authored border")
 segment.queue_free();await frames()
 # Font-independent native symbol owns its ink and invisible accessible label.
 var symbol:=make_button(phone,"▶",Color("222322"),Color.WHITE);Symbols.apply(symbol,"▶",Color.WHITE,20);await frames()
 check(symbol.get_theme_color("font_color").a==0,"flat state does not reveal duplicate native symbol text")
 check(symbol.get_node("NativeSymbolIcon").ink==Color.WHITE,"symbol keeps authored ink")
 symbol.queue_free();await frames()
 # Both shared frame back and C35 intro use this custom navigation subclass.
 var app_frame=load("res://scripts/ui/phone_app_frame.gd")
 var audit=load("res://tests/capture_ui_redesign.gd")
 for back_name: String in ["PhoneAppBack","C35IntroBack"]:
  var page: Control
  if back_name=="PhoneAppBack":page=app_frame.new()
  else:page=load("res://scripts/ui/chapter3_phone_pages.gd").new().recovery_intro()
  phone.add_child(page);await frames()
  var back: Button=page.find_child(back_name,true,false)
  check(back.get_node_or_null("TactileMaterialState")!=null,"custom navigation declares UI ownership: "+back_name)
  check(audit.button_material_contract(back).valid,"actual navigation passes material audit: "+back_name)
  check(back.size==Vector2(44,44),"navigation preserves target geometry: "+back_name)
  for mode: String in ["normal","hover","pressed","hover_pressed","disabled","focus"]:
   var bound: StyleBox=back.get_theme_stylebox(mode)
   check(bound is Flat,"navigation uses flat native state: "+back_name+"/"+mode)
   # Inspect before the deferred adapter repair: a broken state must fail.
   back.add_theme_stylebox_override(mode,StyleBoxEmpty.new())
   check(not audit.button_material_contract(back).valid,"audit rejects broken state: "+back_name+"/"+mode)
   back.add_theme_stylebox_override(mode,bound)
  page.queue_free();await frames()
 # Normal, keyboard, pointer and disabled actions remain native.
 button=make_button(phone);await frames();button.pressed.connect(func():activations+=1);button.grab_focus()
 for down: bool in [true,false]:
  var key:=InputEventKey.new();key.keycode=KEY_ENTER;key.pressed=down;root.push_input(key)
 await frames();check(activations==1,"keyboard activates once")
 for down: bool in [true,false]:
  var mouse:=InputEventMouseButton.new();mouse.button_index=MOUSE_BUTTON_LEFT;mouse.position=Vector2(40,40);mouse.pressed=down;root.push_input(mouse)
 await frames();check(activations==2,"pointer activates once")
 button.disabled=true
 for down: bool in [true,false]:
  var mouse:=InputEventMouseButton.new();mouse.button_index=MOUSE_BUTTON_LEFT;mouse.position=Vector2(40,40);mouse.pressed=down;root.push_input(mouse)
 await frames();check(activations==2 and button.disabled,"disabled state blocks activation")
 phone.queue_free();await frames()
 # A name alone cannot adopt an unrelated world control into the phone theme.
 var world:=Control.new();world.name="PhoneView";root.add_child(world)
 var outside:=make_button(world);await frames()
 check(outside.get_theme_stylebox("normal") is Tactile,"non-phone UI keeps existing tactile material, despite misleading name")
 world.queue_free();await frames()
 # Verify real shell ownership, whose phone PanelContainer is unnamed.
 var state: Node=root.get_node("State");state.developer_mode=true;state.d=state.initial()
 var main: Control=load("res://scenes/main.tscn").instantiate();root.add_child(main);await frames(6)
 var inside:=make_button(main.phone);var sibling:=make_button(main);await frames()
 check(inside.get_theme_stylebox("normal") is Flat,"actual main phone owner is scoped")
 check(sibling.get_theme_stylebox("normal") is Tactile,"same main tree's world sibling is not scoped")
 await main.shutdown();main.queue_free();await frames()
 print("PHONE_FLAT_BUTTONS: ",checks," checks; ",failures," failures")
 quit(1 if failures else 0)
