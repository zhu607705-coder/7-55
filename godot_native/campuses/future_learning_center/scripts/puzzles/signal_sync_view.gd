extends "res://campuses/future_learning_center/scripts/puzzles/collab_view.gd"
const SignalSync=preload("res://campuses/future_learning_center/scripts/puzzles/signal_sync_model.gd")
const CableArt=preload("res://campuses/future_learning_center/scripts/puzzles/cable_scene_art.gd")
const CableVisuals=preload("res://campuses/future_learning_center/scripts/puzzles/cable_scene_visuals.gd")
var cable_grab_offset:=Vector2.ZERO
var screen_origin:=Vector2.ZERO
var keyboard_active:=false
var keyboard_index:=0
var keyboard_output:=0
var cable_input:=""
var screen_drag:=-1
var screen_offset:=Vector2.ZERO
func _init()->void:
 model=SignalSync.new()
 hints=["两屏相同时，下次源端改动还会跟上吗？","只改源卡一个角标，看它沿哪条线抵达。","对照旧稿与接收纸条，找出没有更新的一段。"]
func _ready()->void:
 super._ready()
 if CableArt.complete():
  visuals=CableVisuals.new();visuals.art=CableArt.parts();visuals.z_index=-20;add_child(visuals)
  var backdrop:=ColorRect.new();backdrop.color=Color("c7ccc8");backdrop.size=Vector2(960,540);backdrop.z_index=-30;backdrop.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(backdrop)
func _sync_visuals(dt:float)->void:
 if screen_drag>=0:model.move_screen(screen_drag,pointer-screen_offset)
 super._sync_visuals(dt)
func port_at(port:String)->Vector2:
 match port:
  "source":return Vector2(225,245)
  "bus_in":return Vector2(350,245)
  "live_a":return Vector2(475,200)
  "live_b":return Vector2(475,270)
  "cache":return Vector2(475,365)
  "screen_a":return model.positions[0]+Vector2(-80,25)
  "screen_b":return model.positions[1]+Vector2(-80,25)
 return Vector2.ZERO
func _cancel_pointer()->void:
 if screen_drag>=0:model.move_screen(screen_drag,screen_origin)
 cable_input="";cable_grab_offset=Vector2.ZERO;screen_drag=-1;super._cancel_pointer()
func _input(event:InputEvent)->void:
 if ApparatusStyle.navigation_event(self,event):return
 if event is InputEventScreenTouch and event.canceled:
  if event.index==touch_id:_cancel_pointer();queue_redraw()
  return
 if is_visible_in_tree() and event is InputEventKey and event.pressed and not event.echo and event.keycode!=KEY_ESCAPE:
  if event.keycode not in [KEY_TAB,KEY_ENTER,KEY_SPACE,KEY_LEFT,KEY_RIGHT,KEY_UP,KEY_DOWN,KEY_DELETE,KEY_BACKSPACE]:return
  if mouse_owned or touch_id>=0 or screen_drag>=0 or not cable_input.is_empty():return
  keyboard_active=true
  if event.keycode==KEY_TAB:keyboard_index=(keyboard_index+1)%6
  elif keyboard_index==0 and event.keycode in [KEY_ENTER,KEY_SPACE]:model.change_source()
  elif keyboard_index in [1,2] and event.keycode in [KEY_LEFT,KEY_RIGHT,KEY_UP,KEY_DOWN]:
   var delta:=Vector2(-10 if event.keycode==KEY_LEFT else 10 if event.keycode==KEY_RIGHT else 0,-10 if event.keycode==KEY_UP else 10 if event.keycode==KEY_DOWN else 0)
   model.move_screen(keyboard_index-1,model.positions[keyboard_index-1]+delta)
  elif keyboard_index>=3:
   var input:String=SignalSync.INPUTS[keyboard_index-3]
   if event.keycode in [KEY_LEFT,KEY_RIGHT]:keyboard_output=posmod(keyboard_output+(-1 if event.keycode==KEY_LEFT else 1),SignalSync.OUTPUTS.size())
   elif event.keycode in [KEY_ENTER,KEY_SPACE]:model.connect_ports(input,SignalSync.OUTPUTS[keyboard_output])
   elif event.keycode in [KEY_DELETE,KEY_BACKSPACE]:model.unplug(input)
  else:return
  _sync_visuals(0);queue_redraw();get_viewport().set_input_as_handled();return
 super._input(event)
func _process(dt:float)->void:
 if visible and screen_drag>=0:model.move_screen(screen_drag,pointer-screen_offset)
 super._process(dt)
func _press(at:Vector2)->void:
 keyboard_active=false;pressed_at=at;pointer=at;action=""
 if Rect2(35,445,155,65).has_point(at):action="hint";return
 if Rect2(300,440,225,75).has_point(at):action="records";return
 for input:String in SignalSync.INPUTS:
  if visuals!=null and visuals.hit("Plug_"+input,at) and model.cables.has(input):
   cable_input=input;cable_grab_offset=port_at(str(model.cables[input]))-at;return
 for input:String in SignalSync.INPUTS:
  if at.distance_to(port_at(input))<25:cable_input=input;cable_grab_offset=port_at(input)-at;return
 if Rect2(85,175,135,100).has_point(at):action="source";return
 for i:int in 2:
  if Rect2(model.positions[i]-Vector2(70,50),Vector2(150,90)).has_point(at) or (visuals!=null and visuals.hit("Monitor%d"%i,at)):screen_drag=i;screen_origin=model.positions[i];screen_offset=at-model.positions[i];return
func _release(at:Vector2)->void:
 pointer=at
 if not cable_input.is_empty():
  var found:=false
  for output:String in SignalSync.OUTPUTS:
   if (at+cable_grab_offset).distance_to(port_at(output))<28:model.connect_ports(cable_input,output);found=true;break
  if not found and Rect2(0,0,960,540).has_point(at) and at.distance_to(pressed_at)>20:model.unplug(cable_input)
  cable_input="";cable_grab_offset=Vector2.ZERO;_sync_visuals(0);return
 if screen_drag>=0:model.move_screen(screen_drag,at-screen_offset);screen_drag=-1;_sync_visuals(0);return
 if at.distance_to(pressed_at)>18:action="";return
 match action:
  "close":close()
  "hint":hint_level=(hint_level+1)%4;if_hint()
  "records":show_records=not show_records
  "source":model.change_source()
 action=""
func pattern(at:Vector2,value:int,factor:=1.0)->void:
 # Signal content is a functional screen overlay, not physical object artwork.
 draw_rect(Rect2(at-Vector2(43,29)*factor,Vector2(86,58)*factor),Color("c9cdbf"))
 draw_circle(at-Vector2(13,0)*factor,14*factor,Color("688b88"));draw_rect(Rect2(at+Vector2(9,-14)*factor,Vector2(25,28)*factor),Color("ad956d"))
 draw_circle(at+Vector2(29 if value%2 else -29,-20)*factor,5*factor,Color("34484d"))
 if value==2:draw_line(at+Vector2(-32,20)*factor,at+Vector2(32,20)*factor,Color("34484d"),4*factor)
func _draw()->void:
 if font==null or visuals==null:return
 var ink:=Color("253e46")
 text("团队工作室",Vector2(35,36),23,ink)
 pattern(Vector2(150,225),model.source_pattern,.65);pattern(Vector2(405,360),model.cache_pattern,.60)
 text("源卡",Vector2(80,155),16,ink);text("分配盒",Vector2(368,155),17,ink)
 text("输入",Vector2(306,234),13,ink);text("实时 1",Vector2(488,190),13,ink);text("实时 2",Vector2(488,260),13,ink);text("缓存",Vector2(490,362),13,ink)
 for i:int in 2:
  var at:Vector2=model.positions[i]
  var body:Sprite2D=visuals.objects["Monitor%d"%i]
  var spec:Dictionary=CableArt.PARTS.monitor
  var aperture:=Rect2(at+(Vector2(213,374)-spec.pivot)*body.scale,Vector2(826,404)*body.scale)
  draw_rect(aperture,Color("c9cdbf"));pattern(at-Vector2(0,4),model.screens[i])
  text("接收甲" if i==0 else "接收乙",at+Vector2(-32,80),13,ink)
 for input:String in model.cables:
  if model.running:
   var t:=clampf(model.elapsed/(.7 if input in ["bus_in","screen_a"] else 1.05),0,1)
   draw_circle(port_at(str(model.cables[input])).lerp(port_at(input),t),6,Color("eee1b5"))
 if not cable_input.is_empty():
  for output:String in SignalSync.OUTPUTS:
   var destination:=port_at(output)
   ApparatusStyle.target(self,Rect2(destination-Vector2(16,16),Vector2(32,32)),(pointer+cable_grab_offset).distance_to(destination)<28)
 text("修改前后的稿纸",Vector2(48,481),16,ink);text("接收记录",Vector2(335,480),15,ink)
 if hint_level>=0:text("让两屏持续跟随源卡。"+hints[hint_level],Vector2(35,74),16,ink)
 if show_records:
  text("不同改动已验证：%d / 2"%model.receipts.size(),Vector2(560,455),16,ink)
  text(model.outcome,Vector2(550,500),15,ink)
 if model.completed:text("已留存两屏跟随记录",Vector2(580,530),16,ink)
 if keyboard_active:
  var focus:=Rect2(80,190,145,70)
  if keyboard_index in [1,2]:focus=Rect2(model.positions[keyboard_index-1]-Vector2(74,54),Vector2(153,121))
  elif keyboard_index>=3:
   focus=Rect2(port_at(SignalSync.INPUTS[keyboard_index-3])-Vector2(17,17),Vector2(34,34))
   ApparatusStyle.target(self,Rect2(port_at(SignalSync.OUTPUTS[keyboard_output])-Vector2(17,17),Vector2(34,34)),true)
  ApparatusStyle.target(self,focus,true)
