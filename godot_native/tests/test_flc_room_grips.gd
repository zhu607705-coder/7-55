extends SceneTree
## Every new visual grip must lie inside the existing physical input region.
const PATH="res://campuses/future_learning_center/scripts/puzzles/"
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;printerr("FLC_GRIP_FAIL: "+label)
func view(id:String):
 var v=load(PATH+id+"_view.gd").new();root.add_child(v);v.open();return v
func _initialize()->void:run.call_deferred()
func run()->void:
 root.size=Vector2i(960,540)
 var v=view("focus")
 v.press_at(v.plug_position(0));check(v.drag==0,"focus orange plug is draggable")
 v.cancel_pointer();check(v.drag==-1,"focus grip cancellation")
 v._paper();check(v.paper_open,"focus goal remains available on paper");v.close();v.free()
 v=view("perspective")
 v.press_at(v.PHOTOS[0]+Vector2(48,43));check(v.photo_drag==0,"photo corner turns actual paper")
 v.cancel_pointer();v.press_at(Vector2(839,406));check(v.model.running,"camera grip exposes actual model")
 v.close();check(not v.model.running,"camera return cancels trial");v.free()
 v=view("perspective");v.size=Vector2(960,540);await process_frame
 for source:int in [0,1,2]:
  var destination:int=(source+1)%4
  var expected:int=v.model.slots[source]
  if source>0:
   await touch(7,v.CELLS[source],true);await touch(7,v.CELLS[source],false)
   check(v.selected>=0,"perspective tap retains accessible selection")
  await touch(8,v.CELLS[source],true)
  var move:=InputEventScreenDrag.new();move.index=8;move.position=v.CELLS[destination];move.relative=v.CELLS[destination]-v.CELLS[source]
  root.push_input(move);await process_frame
  check(v.drag==expected,"perspective occupied piece follows real touch after selection")
  await touch(8,v.CELLS[destination],false)
  check(v.model.slots[destination]==expected,"perspective real drag swaps occupied slots")
 v.close();v.free()
 v=view("projection")
 v.press_at(v.slot_point(0,v.model.depths[0]));check(v.drag==0 and v.drag_kind=="slider","projection horizontal grip selects depth")
 v.cancel_pointer();v.press_at(v.height_point(1));check(v.drag==1 and v.drag_kind=="height","projection vertical grip selects height")
 v.close();v.free()
 v=view("coupled")
 v.press_at(v.model.positions[0]);check(v.drag==0,"coupled piece grip moves real block")
 v.cancel_pointer();check(v.drag==-1,"coupled grip cancellation");v.close();v.free()
 v=view("rail")
 v.press_at(v.cart_position(0)+Vector2(0,15));check(v.drag==0,"cart grip sits inside cart hit area")
 v.cancel_pointer();var initial:bool=v.model.siding
 v.press_at(Vector2(559,181) if initial else Vector2(603,181));check(v.model.siding!=initial,"switch grip toggles physical switch")
 v.close();v.free()
 v=view("rail");v.size=Vector2(960,540);await process_frame
 for side:bool in [false,true]:
  v.model.siding=side
  var cue:Vector2=(Vector2(559,181) if side else Vector2(603,181))+Vector2(0,-24)
  await touch(0,cue,true)
  check(v.touch_action_pending and v.model.siding==side,"rail visible switch cue waits for release")
  await touch(0,cue,false,true)
  check(v.model.siding==side,"rail visible switch cue cancellation")
  await touch(1,cue,true);await touch(1,cue,false)
  check(v.model.siding!=side,"rail visible switch cue outer edge toggles")
 v.close();v.free()
 v=view("access")
 v.press(v.support_at(0)+Vector2(0,12));check(v.action=="support" and v.support==0,"support grip lies inside support hit area")
 v.cancel_pointer();v.press(v.shaft_handle());check(v.action=="shaft","shaft grip selects shaft")
 v.cancel_pointer();v.press(v.cover_handle());check(v.action=="lid","cover front grip opens lid")
 v.close();v.free()
 v=view("recording")
 v._press(Vector2(441,v.model.baffle_y));check(v.baffle_drag,"baffle grip moves baffle")
 v._cancel_pointer();v._press(Vector2(695,445));check(v.action=="crank","handwheel grip reaches crank")
 v.close();v.free()
 v=view("sync")
 v._press(Vector2(110,158));check(v.tape_drag==0,"first tape grip moves first tape")
 v._cancel_pointer();v._press(Vector2(110,266));check(v.tape_drag==1,"second tape grip moves second tape")
 v._cancel_pointer();v._press(Vector2(850,440));check(v.action=="roll","roll grip reaches record roll")
 v.close();v.free()
 await real_touch_actions()
 print("FLC_ROOM_GRIPS: ",checks," checks, ",failures," failures");quit(1 if failures else 0)

func touch(index:int,at:Vector2,pressed:bool,canceled:=false)->void:
 var e:=InputEventScreenTouch.new();e.index=index;e.position=at;e.pressed=pressed;e.canceled=canceled
 root.push_input(e);await process_frame
func real_touch_actions()->void:
 root.size=Vector2i(960,540)
 # Real viewport dispatch: no direct view event-handler call in these checks.
 for id:String in ["focus","perspective","projection","coupled","rail"]:
  var v=view(id);v.size=Vector2(960,540);await process_frame
  var at:Vector2={"focus":Vector2(720,385),"perspective":Vector2(130,485),"projection":Vector2(130,485),"coupled":Vector2(110,490),"rail":Vector2(130,475)}[id]
  await touch(0,at,true)
  check(v.touch_id==0 and v.touch_action_pending,id+" real touch owns pending action")
  check(not v.model.running if id=="focus" else not v.paper_open,id+" press alone does not commit")
  await touch(1,at,true);await touch(1,at,false)
  check(v.touch_id==0 and v.touch_action_pending,id+" second finger cannot commit or steal")
  await touch(0,at,false,true)
  check(not v.model.running if id=="focus" else not v.paper_open,id+" cancelled discrete action unchanged")
  check(v.touch_id==-1 and not v.touch_action_pending,id+" canceled owner retired")
  await touch(2,at,true);await touch(2,at+Vector2(70,0),false)
  check(not v.model.running if id=="focus" else not v.paper_open,id+" release away does not activate")
  await touch(3,at,true);await touch(3,at,false)
  check(v.model.running if id=="focus" else v.paper_open,id+" ordinary owner release activates")
  v.close();v.free();await process_frame

 # The remaining three views already defer discrete actions; exercise their real input path.
 for id:String in ["access","recording","sync"]:
  var v=view(id);v.size=Vector2(960,540);await process_frame
  var at:Vector2={"access":Vector2(110,460),"recording":Vector2(110,460),"sync":Vector2(110,475)}[id]
  await touch(0,at,true);await touch(1,at,true);await touch(1,at,false)
  check(v.touch_id==0,id+" existing release path retains first finger")
  await touch(0,at,false,true)
  check(not v.notebook if id=="access" else v.hint_level==-1,id+" canceled help unchanged")
  await touch(2,at,true);await touch(2,at,false)
  check(v.notebook if id=="access" else v.hint_level==0,id+" help opens on owner release")
  v.close();v.free();await process_frame
 var v=view("sync");v.size=Vector2(960,540);await process_frame
 var before:float=v.model.offsets[0]
 await touch(0,Vector2(300,158),true)
 var drag:=InputEventScreenDrag.new();drag.index=0;drag.position=Vector2(365,158);drag.relative=Vector2(65,0)
 root.push_input(drag);await process_frame
 check(v.model.offsets[0]!=before,"sync drag visibly moves paper before release")
 await touch(0,Vector2(365,158),false,true)
 check(v.model.offsets[0]==before and v.tape_drag==-1,"sync cancel returns paper to pickup position")
 v.close();v.free();await process_frame
