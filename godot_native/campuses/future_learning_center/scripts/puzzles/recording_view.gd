extends "res://campuses/future_learning_center/scripts/puzzles/collab_view.gd"
const Recording=preload("res://campuses/future_learning_center/scripts/puzzles/recording_model.gd")
var baffle_drag:=false
var baffle_origin:=300.0
var baffle_offset:=0.0
func _init()->void:
 model=Recording.new()
 hints=["送料件停住的位置，和挡片在哪里相交？","只移动挡片，分别看看送料与试拍发生什么。","碰停条与清楚照片，各记录了过程中的哪一刻？"]
func _cancel_pointer()->void:
 if baffle_drag:model.move_baffle(baffle_origin)
 baffle_drag=false;super._cancel_pointer()
func _input(event:InputEvent)->void:
 if ApparatusStyle.navigation_event(self,event):return
 super._input(event)
 if baffle_drag and (event is InputEventMouseMotion and touch_id<0 and event.device!=InputEvent.DEVICE_ID_EMULATION or event is InputEventScreenDrag and event.index==touch_id):
  model.move_baffle(clampf(pointer.y-baffle_offset,150,300));queue_redraw()
func _press(at:Vector2)->void:
 pressed_at=at;pointer=at;action=""
 if Rect2(35,425,155,80).has_point(at):action="hint";return
 if Rect2(765,285,170,215).has_point(at):action="records";return
 if model.baffle(model.baffle_y).grow(15).has_point(at):baffle_drag=true;baffle_origin=model.baffle_y;baffle_offset=at.y-model.baffle_y;model.pause();return
 if at.distance_to(Vector2(670,185))<38:action="photo";return
 if Rect2(710,135,45,150).has_point(at):action="drive";return
 if at.distance_to(Vector2(665,445))<45:action="crank";return
func _release(at:Vector2)->void:
 if baffle_drag:
  baffle_drag=false;model.move_baffle(clampf(at.y-baffle_offset,150,300));queue_redraw();return
 if action=="drive" and Rect2(710,135,45,150).has_point(at):
  model.drive(-1 if at.y<185 else (1 if at.y>235 else 0));action="";return
 if action=="crank" and at.distance_to(Vector2(665,445))<50:
  model.nudge(-1 if at.x<665 else 1);action="";return
 if at.distance_to(pressed_at)>18:action="";return
 match action:
  "close":close()
  "hint":hint_level=(hint_level+1)%4;if_hint()
  "records":show_records=not show_records
  "photo":model.shutter()
 action="";queue_redraw()
func _draw()->void:
 if font==null:return
 draw_rect(Rect2(0,0,960,540),Color("26323a"))
 text("先送到，再遮住",Vector2(35,38),22)
 box(Rect2(30,90,720,310),Color("95846a"),15)
 for y:float in [278,322]:draw_line(Vector2(195,y),Vector2(695,y),Color("46565b"),7);draw_line(Vector2(195,y-2),Vector2(695,y-2),Color("b5b8ad"),2)
 box(Rect2(690,270,12,65),Color("667574"),5);text("止挡",Vector2(681,360),14)
 # Lateral lamp shares the same path used by the model's segment intersection.
 var ray_end:=Vector2(670,300)
 if model.light_blocked():ray_end=Vector2(430,260+110*40.0/350)
 draw_line(Vector2(320,260),ray_end,Color("d6c08e"),3)
 box(Rect2(300,235,38,30),Color("54666a"),8);draw_circle(Vector2(320,252),9,Color("d6c08e"))
 draw_line(Vector2(441,125),Vector2(441,360),Color("45565a"),8)
 draw_line(Vector2(437,125),Vector2(437,360),Color("c3c5b7"),2)
 var by:float=model.baffle_y
 box(model.baffle(by),Color("737f7d"),12);draw_circle(Vector2(441,by),8,Color("c5b597"))
 text("停车位",Vector2(465,147),14);text("遮光位",Vector2(465,252),14)
 box(model.carriage(model.x),Color("af9c7b"),10)
 draw_line(Vector2(model.x-8,292),Vector2(model.x+8,308),Color("34474e"),3);draw_line(Vector2(model.x-8,308),Vector2(model.x+8,292),Color("34474e"),3)
 if model.contact.is_finite():draw_circle(model.contact,8,Color("c39b70"))
 box(Rect2(646,163,48,34),Color("43545d"),10);draw_circle(Vector2(670,185),14,Color("26343c"));draw_circle(Vector2(670,185),6,Color("9eb2b4"));draw_dashed_line(Vector2(670,205),Vector2(670,275),Color("8fa6a7"),2,6)
 if model.photographing:draw_arc(Vector2(670,185),22,0,model.exposure/.6*TAU,24,Color("ddd6bb"),3)
 # A three-detent physical lever: reverse / stop / forward, plus a handwheel for short strokes.
 box(Rect2(714,142,37,140),Color("596b6d"),5);draw_line(Vector2(733,156),Vector2(733,267),Color("27373f"),6)
 var lever_y:float=210+model.direction*49
 draw_line(Vector2(733,210),Vector2(733,lever_y),Color("c4c8bc"),8);draw_circle(Vector2(733,lever_y),12,Color("a98f6e"))
 text("退",Vector2(761,165),14);text("停",Vector2(761,215),14);text("进",Vector2(761,266),14)
 draw_arc(Vector2(665,445),33,0,TAU,32,Color("9aaca7"),6);draw_circle(Vector2(665,445),7,Color("506368"));draw_line(Vector2(665,445),Vector2(695,445),Color("a9b9b1"),6);draw_circle(Vector2(695,445),8,Color("aa9274"))
 text("手轮 · 左退右进",Vector2(606,500),14)
 box(Rect2(775,300,155,196),Color("d7d1bc"),4);text("试拍纸卡",Vector2(790,328),17,Color("35464d"))
 if show_records:
  box(Rect2(792,345,120,95),Color("b4b8a7"),2)
  if model.photo_kind=="clear":
   draw_line(Vector2(830,368),Vector2(877,415),Color("34474e"),7);draw_line(Vector2(830,415),Vector2(877,368),Color("34474e"),7)
  elif model.photo_kind=="glare":draw_circle(Vector2(850,390),38,Color("f2eed9"))
  var shot_round:int=-1 if model.history.is_empty() else model.history.back().round
  text("照片轮次 %d"%shot_round,Vector2(787,462),13,Color("35464d"))
  text("当前轮次 %d"%model.round_id,Vector2(787,483),13,Color("35464d"))
 else:text("翻开查看",Vector2(800,375),14,Color("35464d"))
 box(Rect2(35,435,155,65),Color("d7d1bc"),4);text("碰停条与照片",Vector2(48,463),16,Color("35464d"));text("翻开对照",Vector2(60,485),13,Color("35464d"))
 if hint_level>=0:text(hints[hint_level],Vector2(35,76),16)
 if not model.outcome.is_empty():text(model.outcome,Vector2(210,526),15)
