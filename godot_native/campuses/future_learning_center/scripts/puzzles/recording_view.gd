extends "res://campuses/future_learning_center/scripts/puzzles/collab_view.gd"
const Recording=preload("res://campuses/future_learning_center/scripts/puzzles/recording_model.gd")
var baffle_drag:=false
var baffle_origin:=300.0
var baffle_offset:=0.0
var gesture_revision:=0
var last_drag_revision:=0
var drive_offset:=0.0
var drive_preview:=210.0
var wheel_angle:=0.0
var wheel_remaining:=0.0
const RecordingArt=preload("res://campuses/future_learning_center/scripts/puzzles/recording_scene_art.gd")
const RecordingVisuals=preload("res://campuses/future_learning_center/scripts/puzzles/recording_scene_visuals.gd")
func _ready()->void:
 super._ready()
 if RecordingArt.complete():
  visuals=RecordingVisuals.new();visuals.art=RecordingArt.parts();visuals.z_index=-1;add_child(visuals)
  var backdrop:=ColorRect.new();backdrop.color=Color("c7ccc8");backdrop.size=Vector2(960,540);backdrop.z_index=-2;backdrop.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(backdrop)
func _process(dt:float)->void:
 if not visible:return
 if wheel_remaining>0:
  wheel_remaining=maxf(0,wheel_remaining-dt)
  wheel_angle=0.0 if reduced_motion else signf(wheel_angle)*.28*wheel_remaining/.12
 super._process(dt)
func baffle_position()->Vector2:return Vector2(441,model.baffle_y)
func drive_handle_y()->float:return drive_preview if action=="drive" else 210+model.direction*49

func _init()->void:
 model=Recording.new()
 hints=["送料件停住的位置，和挡片在哪里相交？","只移动挡片，分别看看送料与试拍发生什么。","碰停条与清楚照片，各记录了过程中的哪一刻？"]
func _cancel_pointer()->void:
 if baffle_drag:
  model.baffle_y=baffle_origin
  if model.revision==last_drag_revision:model.revision=gesture_revision
  model.contact=Vector2.INF;model.outcome=""
 wheel_angle=0;wheel_remaining=0
 baffle_drag=false;super._cancel_pointer()
func _input(event:InputEvent)->void:
 if ApparatusStyle.navigation_event(self,event):return
 super._input(event)
 if not is_visible_in_tree():return
 if event is InputEventKey and event.pressed and not event.echo and touch_id<0 and not mouse_owned:
  match event.keycode:
   KEY_LEFT:model.nudge(-1)
   KEY_RIGHT:model.nudge(1)
   KEY_UP:model.pause();model.move_baffle(maxf(150,model.baffle_y-10))
   KEY_DOWN:model.pause();model.move_baffle(minf(300,model.baffle_y+10))
   KEY_ENTER:model.shutter()
   _:return
  _sync_visuals(0);queue_redraw();get_viewport().set_input_as_handled();return
 if baffle_drag and (event is InputEventMouseMotion and touch_id<0 and event.device!=InputEvent.DEVICE_ID_EMULATION or event is InputEventScreenDrag and event.index==touch_id):
  model.move_baffle(clampf(pointer.y-baffle_offset,150,300));last_drag_revision=model.revision;_sync_visuals(0);queue_redraw()
 if action=="drive" and (event is InputEventMouseMotion and touch_id<0 and event.device!=InputEvent.DEVICE_ID_EMULATION or event is InputEventScreenDrag and event.index==touch_id):
  drive_preview=clampf(pointer.y-drive_offset,161,259);_sync_visuals(0);queue_redraw()
func _press(at:Vector2)->void:
 pressed_at=at;pointer=at;action=""
 if Rect2(35,425,155,80).has_point(at):action="hint";return
 if Rect2(765,285,170,215).has_point(at):action="records";return
 if model.baffle(model.baffle_y).grow(15).has_point(at):baffle_drag=true;baffle_origin=model.baffle_y;baffle_offset=at.y-model.baffle_y;gesture_revision=model.revision;last_drag_revision=model.revision;model.pause();return
 if at.distance_to(Vector2(670,185))<38:action="photo";return
 if Rect2(708,105,50,215).has_point(at):action="drive";drive_offset=at.y-(210+model.direction*49) if absf(at.y-(210+model.direction*49))<=18 else 0.0;drive_preview=clampf(at.y-drive_offset,161,259);return
 if at.distance_to(Vector2(665,445))<45:action="crank";return
func _release(at:Vector2)->void:
 if baffle_drag:
  baffle_drag=false;model.move_baffle(clampf(at.y-baffle_offset,150,300));_sync_visuals(0);queue_redraw();return
 if action=="drive" and Rect2(708,105,50,215).has_point(at):
  var y:=at.y-drive_offset
  model.drive(-1 if y<185 else (1 if y>235 else 0));action="";_sync_visuals(0);return
 if action=="crank" and at.distance_to(Vector2(665,445))<50:
  model.nudge(-1 if at.x<665 else 1);wheel_angle=0.0 if reduced_motion else (-1 if at.x<665 else 1)*.28;wheel_remaining=.12;action="";_sync_visuals(0);return
 if at.distance_to(pressed_at)>18:action="";return
 match action:
  "close":close()
  "hint":hint_level=(hint_level+1)%4;if_hint()
  "records":show_records=not show_records
  "photo":model.shutter()
 action="";queue_redraw()
func _draw()->void:
 if font==null or visuals==null:return
 draw_style_feedback()
func draw_style_feedback()->void:
 var ink:=Color("253e46")
 text("先送到，再遮住",Vector2(35,38),22,ink)
 # Printed fiducial data, not a substitute physical object.
 draw_line(Vector2(model.x-5,289),Vector2(model.x+5,299),ink,2)
 draw_line(Vector2(model.x-5,299),Vector2(model.x+5,289),ink,2)
 var ray_end:=Vector2(670,300)
 if model.light_blocked():ray_end=Vector2(430,260+110*40.0/350)
 draw_line(Vector2(320,260),ray_end,Color("d6b46f"),3)
 draw_dashed_line(Vector2(670,208),Vector2(670,275),Color("6b8585"),2,6)
 if model.photographing:draw_arc(Vector2(670,185),29,0,model.exposure/.6*TAU,24,Color("b07c30"),3)
 if model.contact.is_finite():draw_circle(model.contact,7,Color("b97d35"),false,2)
 if baffle_drag:ApparatusStyle.target(self,model.baffle(model.baffle_y),true)
 text("停车位",Vector2(465,147),14,ink);text("遮光位",Vector2(465,252),14,ink)
 text("止挡",Vector2(681,360),14,ink)
 for i:int in 3:text(["退","停","进"][i],Vector2(761,165+i*50),14,ink)
 text("碰停条与照片",Vector2(48,473),16,ink)
 text("试拍纸卡",Vector2(790,328),17,ink)
 if show_records:
  if model.photo_kind=="clear":
   draw_line(Vector2(830,368),Vector2(877,415),ink,5);draw_line(Vector2(830,415),Vector2(877,368),ink,5)
  elif model.photo_kind=="glare":draw_circle(Vector2(850,390),30,Color("f2eed9"))
  elif model.photo_kind=="empty":text("未到位",Vector2(826,395),15,ink)
  var shot_round:int=-1 if model.history.is_empty() else model.history.back().round
  text("照片轮次 %d"%shot_round,Vector2(787,462),13,ink)
  text("当前轮次 %d"%model.round_id,Vector2(787,483),13,ink)
 ApparatusStyle.grip(self,baffle_position(),"vertical",baffle_drag)
 ApparatusStyle.grip(self,Vector2(733,drive_handle_y()-12),"vertical",action=="drive")
 ApparatusStyle.grip(self,Vector2(695,445),"rotate",action=="crank")
 ApparatusStyle.grip(self,Vector2(670,185),"press",model.photographing)
 if hint_level>=0:
  text(hints[hint_level],Vector2(35,76),16,ink)
  text("手轮 · 左退右进",Vector2(606,500),14,ink)
 if not model.outcome.is_empty():text(model.outcome,Vector2(210,526),15,ink)
