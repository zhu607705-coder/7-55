extends "res://campuses/future_learning_center/scripts/puzzles/collab_view.gd"
const Platform=preload("res://campuses/future_learning_center/scripts/puzzles/platform_model.gd")
var board_drag:=false
var offset:=Vector2.ZERO
func _init()->void:
 model=Platform.new()
 hints=["桌面变暗以后，相机还看见完整标记吗？","只挪白板，比较阴影与相机纸片。","两张废片中，亮斑与白板分别挡住了什么？"]
func _cancel_pointer()->void:board_drag=false;super._cancel_pointer()
func _input(event:InputEvent)->void:
 if ApparatusStyle.navigation_event(self,event):return
 if event is InputEventScreenTouch and event.canceled:
  if event.index==touch_id:_cancel_pointer();queue_redraw()
  return
 super._input(event)
func _process(dt:float)->void:
 if visible and board_drag:model.move_board(pointer-offset)
 super._process(dt)
func _press(at:Vector2)->void:
 pressed_at=at;pointer=at;action=""
 if Rect2(32,444,160,65).has_point(at):action="hint";return
 if Rect2(25,80,200,85).has_point(at):action="records";return
 if at.distance_to(Vector2(480,414))<35:action="photo";return
 for i:int in 2:
  if at.distance_to(Vector2(90 if i==1 else 870,190))<35:action="lamp_%d"%i;return
 if Rect2(model.board-Vector2(80,105),Vector2(160,125)).has_point(at):board_drag=true;offset=at-model.board;model.cancel()
func _release(at:Vector2)->void:
 if board_drag:model.move_board(at-offset);board_drag=false;return
 if at.distance_to(pressed_at)>18:action="";return
 match action:
  "close":close()
  "hint":hint_level=(hint_level+1)%4;if_hint()
  "records":show_records=not show_records
  "photo":model.shutter()
  "lamp_0":model.set_condition(0)
  "lamp_1":model.set_condition(1)
 action=""
func _draw()->void:
 if font==null:return
 draw_rect(Rect2(0,0,960,540),Color("c0c5bc"))
 text("开放平台",Vector2(30,35),22,Color("293d42"))
 for y:int in range(90,530,35):draw_line(Vector2(25,y),Vector2(935,y),Color("b0b6af"),1)
 draw_colored_polygon(model.shadow(),Color("7c8f91",.58))
 for r:Rect2 in Platform.SCENERY:
  box(r,Color("9b8e72"),8)
 # Four separately visible corners are the actual target used by the ray test.
 var a:Dictionary=model.assess()
 box(Rect2(460,286,40,40),Color("4b6c70") if a.clear else Color("eee6c8"),3)
 for d:Vector2 in [Vector2(-10,-8),Vector2(10,-8),Vector2(10,8),Vector2(-10,8)]:draw_circle(Platform.TARGET+d,3,Color("293d42"))
 for i:int in 2:
  var p:=Vector2(870 if i==0 else 90,190)
  draw_line(p,p+Vector2(-17,35),Color("3c5054"),5);draw_line(p,p+Vector2(17,35),Color("3c5054"),5)
  box(Rect2(p-Vector2(23,19),Vector2(46,32)),Color("697b7a"),5);draw_circle(p,12,Color("e8d6a7") if model.condition==i else Color("485d64"))
  text("甲" if i==0 else "乙",p+Vector2(-6,51),16,Color("293d42"))
 if hint_level>=0:
  draw_dashed_line(Platform.CAMERA,Platform.TARGET,Color("e6e2ca"),2,6)
  text("挡光，不挡镜头。"+hints[hint_level],Vector2(30,70),16,Color("293d42"))
 # Whiteboard face and its wheels share one movable footprint.
 var b:Vector2=model.board
 draw_line(b+Vector2(-60,-16),b+Vector2(-60,-92),Color("46585d"),5);draw_line(b+Vector2(60,-16),b+Vector2(60,-92),Color("46585d"),5)
 box(Rect2(b-Vector2(72,100),Vector2(144,75)),Color("d9ded2"),5)
 ApparatusStyle.grip(self,b-Vector2(0,50),"drag",board_drag)
 draw_line(b-Vector2(72,0),b+Vector2(72,0),Color("4a5a5e"),7)
 for dx:int in [-65,65]:draw_circle(b+Vector2(dx,9),7,Color("34474d"))
 if model.contact.is_finite():draw_arc(model.contact,20,0,TAU,24,Color("9c6956"),3)
 draw_line(Vector2(480,420),Vector2(457,452),Color("46575b"),5);draw_line(Vector2(480,420),Vector2(503,452),Color("46575b"),5)
 box(Rect2(456,395,48,30),Color("46575b"),7);draw_circle(Vector2(480,410),13,Color("24383f"));draw_circle(Vector2(480,410),6,Color("98ada9"))
 ApparatusStyle.grip(self,Vector2(480,414),"press",model.photographing)
 if model.photographing:draw_arc(Vector2(480,410),20,0,model.exposure/.5*TAU,20,Color("e6d8b7"),3)
 box(Rect2(25,80,200,85),Color("e2ddc9"),3);text("甲 / 乙 · 试拍相册",Vector2(36,104),16,Color("293d42"))
 for i:int in 2:
  var p:=Vector2(70+i*90,135);draw_rect(Rect2(p-Vector2(25,17),Vector2(50,34)),Color("4e6e70") if model.records.has(i) else Color("b9b9aa"))
 if show_records and not model.shot.is_empty():
  box(Rect2(570,435,345,70),Color("e2ddc9"),3)
  text(model.outcome,Vector2(585,467),16,Color("293d42"));text("四角可见 %d / 4"%model.shot.visible_corners,Vector2(585,490),14,Color("293d42"))
 box(Rect2(35,450,155,55),Color("e2ddc9"),3);text("两张废片",Vector2(60,482),17,Color("293d42"))
 if model.completed:text("两侧来光都已拍清",Vector2(220,510),17,Color("293d42"))
