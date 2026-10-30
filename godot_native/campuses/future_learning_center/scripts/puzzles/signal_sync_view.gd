extends "res://campuses/future_learning_center/scripts/puzzles/collab_view.gd"
const SignalSync=preload("res://campuses/future_learning_center/scripts/puzzles/signal_sync_model.gd")
var cable_input:=""
var screen_drag:=-1
var screen_offset:=Vector2.ZERO
func _init()->void:
 model=SignalSync.new()
 hints=["两屏相同时，下次源端改动还会跟上吗？","只改源卡一个角标，看它沿哪条线抵达。","对照旧稿与接收纸条，找出没有更新的一段。"]
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
func _cancel_pointer()->void:cable_input="";screen_drag=-1;super._cancel_pointer()
func _input(event:InputEvent)->void:
 if ApparatusStyle.navigation_event(self,event):return
 if event is InputEventScreenTouch and event.canceled:
  if event.index==touch_id:_cancel_pointer();queue_redraw()
  return
 super._input(event)
func _process(dt:float)->void:
 if visible and screen_drag>=0:model.move_screen(screen_drag,pointer-screen_offset)
 super._process(dt)
func _press(at:Vector2)->void:
 pressed_at=at;pointer=at;action=""
 if Rect2(35,445,155,65).has_point(at):action="hint";return
 if Rect2(300,440,225,75).has_point(at):action="records";return
 for input:String in SignalSync.INPUTS:
  if at.distance_to(port_at(input))<25:cable_input=input;return
 if Rect2(85,175,135,100).has_point(at):action="source";return
 for i:int in 2:
  if Rect2(model.positions[i]-Vector2(70,50),Vector2(150,90)).has_point(at):screen_drag=i;screen_offset=at-model.positions[i];return
func _release(at:Vector2)->void:
 if not cable_input.is_empty():
  var found:=false
  for output:String in SignalSync.OUTPUTS:
   if at.distance_to(port_at(output))<28:model.connect_ports(cable_input,output);found=true;break
  if not found and at.distance_to(pressed_at)>20:model.unplug(cable_input)
  cable_input="";return
 if screen_drag>=0:model.move_screen(screen_drag,at-screen_offset);screen_drag=-1;return
 if at.distance_to(pressed_at)>18:action="";return
 match action:
  "close":close()
  "hint":hint_level=(hint_level+1)%4;if_hint()
  "records":show_records=not show_records
  "source":model.change_source()
 action=""
func pattern(at:Vector2,value:int)->void:
 draw_rect(Rect2(at-Vector2(43,29),Vector2(86,58)),Color("c9cdbf"))
 draw_circle(at-Vector2(13,0),14,Color("688b88"));draw_rect(Rect2(at+Vector2(9,-14),Vector2(25,28)),Color("ad956d"))
 var corner:=at+Vector2(29 if value%2 else -29,-20)
 draw_circle(corner,5,Color("34484d"))
 if value==2:draw_line(at+Vector2(-32,20),at+Vector2(32,20),Color("34484d"),4)
func _draw()->void:
 if font==null:return
 draw_rect(Rect2(0,0,960,540),Color("28373b"))
 text("团队工作室 · 两个版本",Vector2(35,36),23)
 box(Rect2(30,100,895,320),Color("9d8d71"),12)
 # Socket identity, not left/right screen position, determines the signal.
 for input:String in model.cables:
  var a:=port_at(input);var b:=port_at(str(model.cables[input]))
  draw_line(a+Vector2(0,4),b+Vector2(0,4),Color("3f4544"),7);draw_line(a,b,Color("9cbaa9"),4)
  if model.running:
   var t:=clampf(model.elapsed/(.7 if input=="bus_in" else 1.05),0,1)
   draw_circle(b.lerp(a,t),6,Color("eee1b5"))
 box(Rect2(80,170,145,110),Color("475c60"),8);pattern(Vector2(150,225),model.source_pattern)
 text("当前源卡 · 翻一页",Vector2(80,155),16)
 box(Rect2(345,170,132,130),Color("526868"),10)
 text("分配盒",Vector2(368,192),17)
 box(Rect2(350,325,127,72),Color("77796d"),7);pattern(Vector2(405,360),model.cache_pattern)
 for p:String in SignalSync.OUTPUTS+SignalSync.INPUTS:
  var at:=port_at(p)
  if p in ["source","bus_in"]:
   draw_rect(Rect2(at-Vector2(10,10),Vector2(20,20)),Color("d0c9af"));draw_rect(Rect2(at-Vector2(5,5),Vector2(10,10)),Color("24353a"))
  else:draw_circle(at,10,Color("d0c9af"));draw_circle(at,5,Color("24353a"))
 text("输入",Vector2(306,234),13);text("实时 1",Vector2(488,190),13);text("实时 2",Vector2(488,260),13);text("缓存",Vector2(490,362),13)
 for i:int in 2:
  var at:Vector2=model.positions[i]
  draw_line(at+Vector2(0,32),at+Vector2(0,62),Color("3b5055"),8);draw_line(at+Vector2(-37,63),at+Vector2(37,63),Color("34474c"),7)
  box(Rect2(at-Vector2(70,50),Vector2(145,90)),Color("42575d"),8);pattern(at-Vector2(0,4),model.screens[i])
  text("接收甲" if i==0 else "接收乙",at+Vector2(-32,35),13)
  var socket:=port_at("screen_a" if i==0 else "screen_b")
  draw_circle(socket,10,Color("d0c9af"));draw_circle(socket,5,Color("24353a"))
 if not cable_input.is_empty():draw_line(port_at(cable_input),pointer,Color("ddd4b5"),5);draw_circle(pointer,9,Color("d0c9af"))
 box(Rect2(35,450,155,55),Color("ddd6bf"),4);text("修改前后的稿纸",Vector2(48,481),16,Color("30454b"))
 box(Rect2(300,450,220,55),Color("ddd6bf"),4);text("接收时刻纸条 · 翻看",Vector2(312,480),15,Color("30454b"))
 if hint_level>=0:text(hints[hint_level],Vector2(35,74),16)
 if show_records:
  text("不同改动已验证：%d / 2"%model.receipts.size(),Vector2(560,470),16)
  text(model.outcome,Vector2(550,500),15)
 if model.completed:text("两屏持续跟随源端",Vector2(580,530),16)
