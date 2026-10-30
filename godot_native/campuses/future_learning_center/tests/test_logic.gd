extends SceneTree
const M=preload("res://campuses/future_learning_center/scripts/puzzles/logic_model.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func finish(m)->void:
 m.start()
 for i:int in 15:m.step(.1)
func suite(m)->void:
 for part:int in [-1,0,1,2]:m.place(part,Vector2(500,300));finish(m)
func _initialize()->void:call_deferred("run")
func run()->void:
 var m=M.new()
 check(not m.start(),"missing board cannot run")
 check(not m.install(6),"invalid board")
 check(not m.place(3,Vector2(500,300)),"invalid specimen")
 check(not m.place(1,Vector2.INF),"nonfinite move")
 m.install(0)
 var expected:=[[false,false],[true,false],[false,true],[true,true]]
 for part:int in [-1,0,1,2]:
  m.place(part,Vector2(500,300))
  check(m.contacts()==expected[part+1],"geometry yields state "+str(part))
  check(m.revision==1,"observation is not wiring edit")
  finish(m)
 check(m.completed and m.receipts.size()==4,"four actual trials complete")
 var old:int=m.history.size()
 m.exchange_inputs()
 check(m.receipts.is_empty() and m.history.size()==old,"swap invalidates proof but keeps history")
 check(m.completed and not m.transfer_completed,"base completion monotonic")
 suite(m);check(m.transfer_completed,"swapped physical inputs solve")
 for card:int in [1,2]:
  var wrong=M.new();wrong.install(card);suite(wrong)
  check(not wrong.completed,"other network cannot pass all states "+str(card))
 m.install(1);m.place(0,Vector2(500,300));finish(m)
 check(m.jaw>0 and not m.receipts["10"].stable,"parallel wire closes unsteady")
 m.install(0);m.place(2,Vector2(500,300));m.start();m.step(.1);m.pause();var elapsed:float=m.elapsed;m.step(.1)
 check(m.elapsed==elapsed,"focus pause freezes time")
 m.resume();m.step(.1);check(m.elapsed>elapsed,"resume")
 m.place(-1,Vector2(500,300));m.step(10)
 check(not m.running and m.receipts.is_empty(),"moved specimen cancels pending proof")
 m.place(2,Vector2(500,300));m.start();m.install(2);m.step(2)
 check(m.receipts.is_empty(),"changed wiring rejects stale trial")
 m.install(0);m.place(0,Vector2(590,300));check(m.contacts()==[false,false],"shape outside sensor is no contact")
 m.place(2,Vector2(500,280));check(m.contacts()==[true,false],"raised solid is not supported")
 var view=load("res://campuses/future_learning_center/scripts/puzzles/logic_view.gd").new();root.add_child(view);view.open()
 view.press(Vector2(75,155));view.release(Vector2(275,270));check(view.model.card==0,"drag physical wiring into socket")
 view.press(Vector2(290,440));view.release(Vector2(500,300));check(view.model.block==0 and view.model.contacts()==[true,false],"drag side-only test block")
 view.press(Vector2(680,335));view.release(Vector2(680,335));check(view.model.running,"physical trial lever")
 view._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT);check(view.model.paused,"view focus loss")
 view.close();check(not view.model.running and view.model.block==0,"close retains specimen and wiring")
 view.open();check(view.model.card==0,"reopen preserves assembly")
 var e=InputEventScreenTouch.new();e.index=0;e.pressed=true;e.position=Vector2(500,300);view._input(e)
 e=InputEventScreenTouch.new();e.index=0;e.pressed=false;e.canceled=true;e.position=Vector2(500,300);view._input(e)
 check(view.drag.is_empty() and view.touch_id==-1,"touch cancellation clears capture")
 owner_cancel(view,"_input")
 view.queue_free()
 print("FLC_LOGIC: ",checks," checks, ",failures," failures");quit(1 if failures else 0)

func owner_cancel(view:Control,method:String)->void:
 if not view.is_inside_tree():root.add_child(view)
 view.show()
 var contact:=InputEventScreenTouch.new();contact.index=8;contact.position=Vector2(700,75);contact.pressed=true
 view.call(method,contact);contact.canceled=true;view.call(method,contact)
 check(view.touch_id==-1,"pressed cancellation releases owner")
 view.call(method,contact);check(view.touch_id==-1,"orphan canceled press cannot reacquire")
 contact.canceled=false;contact.index=9;view.call(method,contact)
 check(view.touch_id==9,"next finger can acquire after cancellation")
 var foreign:=InputEventScreenTouch.new();foreign.index=10;foreign.pressed=true;foreign.canceled=true;view.call(method,foreign)
 check(view.touch_id==9,"non-owner cancellation cannot steal capture")
 contact.pressed=false;contact.canceled=true;view.call(method,contact)
