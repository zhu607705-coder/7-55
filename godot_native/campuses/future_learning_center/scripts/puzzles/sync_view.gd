extends "res://campuses/future_learning_center/scripts/puzzles/collab_view.gd"
const Sync=preload("res://campuses/future_learning_center/scripts/puzzles/sync_model.gd")
var tape_drag:=-1
var start_offset:=0.0
var gesture_revision:=0
var last_drag_revision:=0
var roll_angle:=0.0
var roll_remaining:=0.0
const RecordingArt=preload("res://campuses/future_learning_center/scripts/puzzles/recording_scene_art.gd")
const RecordingVisuals=preload("res://campuses/future_learning_center/scripts/puzzles/recording_scene_visuals.gd")
func _ready()->void:
 super._ready()
 if RecordingArt.complete():
  visuals=RecordingVisuals.new();visuals.art=RecordingArt.parts();visuals.z_index=-1;add_child(visuals)
  var backdrop:=ColorRect.new();backdrop.color=Color("c7ccc8");backdrop.size=Vector2(960,540);backdrop.z_index=-2;backdrop.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(backdrop)
func _process(dt:float)->void:
 if not visible:return
 if roll_remaining>0:
  roll_remaining=maxf(0,roll_remaining-dt);roll_angle=0.0 if reduced_motion else roll_remaining/.16*.2
 super._process(dt)

func _init()->void:
 model=Sync.new();hints=["同一动作，在两条纸带上是否出现在同一位置？","对齐一次闪光后，再看看远处的碰停事件。","比较相机图帧与碰停纸带中两处共同事件的间隔。"]
func _cancel_pointer()->void:
 if tape_drag>=0:
  model.offsets[tape_drag]=start_offset
  if model.revision==last_drag_revision:model.revision=gesture_revision
  model.outcome=""
 roll_remaining=0;roll_angle=0
 tape_drag=-1;super._cancel_pointer()
func _press(at:Vector2)->void:
 pointer=at;pressed_at=at;action=""
 if Rect2(35,440,150,70).has_point(at):action="hint";return
 if at.distance_to(Vector2(850,464))<44:action="roll";return
 if model.paused:action="resume";return
 for i:int in 2:
  if Rect2(85,118+i*108,790,83).has_point(at):tape_drag=i;selected=i;start_offset=model.offsets[i];gesture_revision=model.revision;last_drag_revision=model.revision;return
 if at.distance_to(Vector2(740,383))<38:action="run";return
func _input(event:InputEvent)->void:
 if ApparatusStyle.navigation_event(self,event):return
 super._input(event)
 if not is_visible_in_tree():return
 if event is InputEventKey and event.pressed and not event.echo and touch_id<0 and not mouse_owned:
  match event.keycode:
   KEY_UP:selected=0
   KEY_DOWN:selected=1
   KEY_LEFT:model.shift(1 if selected<0 else selected,maxf(-230,model.offsets[1 if selected<0 else selected]-2))
   KEY_RIGHT:model.shift(1 if selected<0 else selected,minf(230,model.offsets[1 if selected<0 else selected]+2))
   KEY_ENTER:
    if model.paused:model.resume()
    else:model.start()
   KEY_R:model.replace_roll()
   _:return
  _sync_visuals(0);queue_redraw();get_viewport().set_input_as_handled();return
 if visible and tape_drag>=0 and (event is InputEventMouseMotion or event is InputEventScreenDrag):
  if event is InputEventMouseMotion and (touch_id>=0 or event.device==InputEvent.DEVICE_ID_EMULATION):return
  if event is InputEventScreenDrag and event.index!=touch_id:return
  model.shift(tape_drag,clampf(start_offset+pointer.x-pressed_at.x,-230,230));last_drag_revision=model.revision;_sync_visuals(0);queue_redraw()
func _release(at:Vector2)->void:
 if tape_drag>=0:model.shift(tape_drag,clampf(start_offset+at.x-pressed_at.x,-230,230));tape_drag=-1;_sync_visuals(0);queue_redraw();return
 if at.distance_to(pressed_at)>18:action="";return
 match action:
  "close":close()
  "hint":hint_level=(hint_level+1)%4;if_hint()
  "roll":model.replace_roll();roll_remaining=.16;roll_angle=0.0 if reduced_motion else .2
  "run":model.start()
  "resume":model.resume()
 action="";queue_redraw()
func _draw()->void:
 if font==null or visuals==null:return
 var ink:=Color("253e46")
 text("两份记录差了一个节拍",Vector2(35,38),22,ink)
 for i:int in 2:
  var y:=118+i*108
  text("相机" if i==0 else "传感",Vector2(36,y+48),13,ink)
 text("对照笔记",Vector2(65,484),17,ink)
 for i:int in 2:ApparatusStyle.grip(self,Vector2(110,158+i*108),"horizontal",tape_drag==i)
 ApparatusStyle.grip(self,Vector2(850,464),"rotate",action=="roll")
 ApparatusStyle.grip(self,Vector2(740,372),"press",model.running)
 if hint_level>=0:text(hints[hint_level],Vector2(35,75),15,ink)
 if not model.outcome.is_empty():text(model.outcome,Vector2(205,475),14,ink)
 if model.paused:text("已暂停 · 触碰装置继续",Vector2(260,507),15,ink)
