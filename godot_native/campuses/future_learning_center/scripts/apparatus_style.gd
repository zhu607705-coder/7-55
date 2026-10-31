extends RefCounted
## Shared closeup materials from design/miniatures/DESIGN.md. Not world/phone UI.
const INK:=Color("253e46")
const PAPER:=Color("f6edd7")
const TEAL:=Color("36777b")
const GRIP:=Color("db8248")
const GRAPHITE:=Color("263f47")
const METAL:=Color("a5b4b1")
const SURROUND:=Color("c7ccc8")
const BENCH:=Color("e2e2d5")
const NAVIGATION:=Color("344452")
const NAV_LABEL:=Color("e8e0c8")
const EXIT_RECT:=Rect2(808,7,144,40)
static var _font:Font
class NavigationButton extends Button:
 var touch_owner:=-1
 func _input(event:InputEvent)->void:
  if not is_visible_in_tree() or disabled:return
  if event is InputEventScreenTouch:
   var inside:bool=Rect2(Vector2.ZERO,size).has_point(get_global_transform_with_canvas().affine_inverse()*event.position)
   if event.pressed and not event.canceled and inside:
    if touch_owner<0:touch_owner=event.index;grab_focus();set_pressed_no_signal(true)
    get_viewport().set_input_as_handled()
   elif event.index==touch_owner:
    var activate:bool=not event.pressed and not event.canceled and inside
    touch_owner=-1;set_pressed_no_signal(false);get_viewport().set_input_as_handled()
    if activate:pressed.emit()
  elif event is InputEventScreenDrag and event.index==touch_owner:get_viewport().set_input_as_handled()
  elif event is InputEventMouse and event.device==InputEvent.DEVICE_ID_EMULATION and touch_owner>=0:get_viewport().set_input_as_handled()
 func _notification(what:int)->void:
  if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_APPLICATION_PAUSED,NOTIFICATION_VISIBILITY_CHANGED]:
   touch_owner=-1;set_pressed_no_signal(false)
   # Native mouse press attempts must also be retired before a later release.
   var was_disabled:=disabled;disabled=true;disabled=was_disabled
static func font()->Font:
 if _font==null:
  var face:FontFile=load("res://ui_assets/fonts/SelectedSans-Regular.otf").duplicate()
  face.antialiasing=TextServer.FONT_ANTIALIASING_GRAY;face.allow_system_fallback=false
  var coverage:FontFile=load("res://campuses/future_learning_center/assets/fonts/flc_coverage_regular.otf").duplicate()
  coverage.antialiasing=TextServer.FONT_ANTIALIASING_GRAY;coverage.allow_system_fallback=false
  var variation:=FontVariation.new();variation.base_font=face;variation.fallbacks=[coverage];_font=variation
 return _font
static func apply_navigation(button:Button)->void:
 # Apparatus chrome keeps its authored 20px coverage font and dark workbench
 # palette; the shared adapter still owns normal floor/phone/menu buttons.
 button.set_meta("tactile_exempt",true)
 button.add_theme_font_override("font",font());button.add_theme_font_size_override("font_size",20)
 button.focus_mode=Control.FOCUS_ALL
 button.mouse_filter=Control.MOUSE_FILTER_STOP
 for state:String in ["normal","hover","pressed","disabled"]:
  var box:=StyleBoxFlat.new()
  box.bg_color=NAVIGATION.lightened(.08) if state=="hover" else (NAVIGATION.darkened(.12) if state=="pressed" else NAVIGATION)
  box.border_color=Color("7993a1");box.set_border_width_all(1)
  button.add_theme_stylebox_override(state,box)
 var focus:=StyleBoxFlat.new();focus.bg_color=Color.TRANSPARENT;focus.border_color=NAV_LABEL;focus.set_border_width_all(2)
 button.add_theme_stylebox_override("focus",focus)
 for role:String in ["font_color","font_hover_color","font_pressed_color","font_focus_color","font_disabled_color"]:button.add_theme_color_override(role,NAV_LABEL)
static func configure_exit(owner:Control,callback:Callable)->Button:
 var previous:=owner.get_node_or_null("ApparatusExit")
 if previous is Button:return previous
 var button:=NavigationButton.new();button.name="ApparatusExit";button.text="离开操作台"
 button.accessibility_name="离开操作台，返回当前房间";button.tooltip_text="返回当前房间，保留已完成的操作"
 button.position=EXIT_RECT.position;button.size=EXIT_RECT.size;button.z_index=100
 apply_navigation(button);button.pressed.connect(callback);owner.add_child(button)
 return button
static func navigation_event(owner:Control,event:InputEvent)->bool:
 var button:=owner.get_node_or_null("ApparatusExit")
 if not button is Button or not button.is_visible_in_tree():return false
 if event is InputEventKey:
  return button.has_focus() and event.keycode in [KEY_ENTER,KEY_KP_ENTER,KEY_SPACE]
 if event is InputEventScreenTouch or event is InputEventScreenDrag:
  if button is NavigationButton and event.index==button.touch_owner:return true
 if event is InputEventMouse or event is InputEventScreenTouch or event is InputEventScreenDrag:
  return Rect2(Vector2.ZERO,button.size).has_point(button.get_global_transform_with_canvas().affine_inverse()*event.position)
 return false

## Marks belong to real handles, never invisible screen actions. They stay static
## until held; the same strokes survive reduced-motion and monochrome viewing.
static func grip(owner:CanvasItem,at:Vector2,kind:String="drag",active:bool=false)->void:
 var color:Color=PAPER if active else GRIP
 var width:=3.0
 if kind=="rotate":
  owner.draw_arc(at,17,-PI*.8,PI*.65,20,color,width,true)
  var end:=at+Vector2(cos(PI*.65),sin(PI*.65))*17
  owner.draw_line(end,end+Vector2(8,-1),color,width,true)
  owner.draw_line(end,end+Vector2(0,-8),color,width,true)
 elif kind=="press":
  owner.draw_arc(at,19,PI*1.12,PI*1.88,16,color,width,true)
  owner.draw_line(at+Vector2(-6,-24),at+Vector2(0,-19),color,width,true)
  owner.draw_line(at+Vector2(6,-24),at+Vector2(0,-19),color,width,true)
 elif kind=="book":
  owner.draw_polyline(PackedVector2Array([at+Vector2(-12,-12),at+Vector2(12,-12),at+Vector2(12,12),at+Vector2(-12,12),at+Vector2(-12,-12)]),color,2,true)
  owner.draw_line(at+Vector2(0,-11),at+Vector2(0,11),color,2,true)
  owner.draw_line(at+Vector2(5,-6),at+Vector2(9,-6),color,2,true)
 else:
  # Ribbed orange material is a grip, not an extra arrow button.
  var vertical:=kind=="vertical"
  for offset:int in [-6,0,6]:
   var delta:=Vector2(offset,0) if vertical else Vector2(0,offset)
   var axis:=Vector2(0,7) if vertical else Vector2(7,0)
   owner.draw_line(at+delta-axis,at+delta+axis,INK,5,true)
   owner.draw_line(at+delta-axis,at+delta+axis,color,2.5,true)
 if active:owner.draw_arc(at,24,0,TAU,32,PAPER,2,true)

## Corner brackets show a destination boundary without filling/covering its part.
## Call while holding the relevant part; no green 'correct answer' coloring.
static func target(owner:CanvasItem,rect:Rect2,active:bool=false)->void:
 var color:Color=PAPER if active else GRIP
 var length:=minf(12,minf(rect.size.x,rect.size.y)*.25)
 for corner:Vector2 in [Vector2.ZERO,Vector2(1,0),Vector2(0,1),Vector2.ONE]:
  var at:Vector2=rect.position+rect.size*corner
  var direction:=Vector2(1-2*corner.x,1-2*corner.y)
  owner.draw_line(at,at+Vector2(direction.x*length,0),INK,5,true)
  owner.draw_line(at,at+Vector2(0,direction.y*length),INK,5,true)
  owner.draw_line(at,at+Vector2(direction.x*length,0),color,2.5,true)
  owner.draw_line(at,at+Vector2(0,direction.y*length),color,2.5,true)
