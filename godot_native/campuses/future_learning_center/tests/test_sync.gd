extends SceneTree
const M=preload("res://campuses/future_learning_center/scripts/puzzles/sync_model.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func run_all(m)->void:
 m.start()
 for i:int in 34:m.step(.1)
func _initialize()->void:call_deferred("run")
func run()->void:
 var m=M.new()
 check(not m.aligned(),"origins initially different")
 check(not m.shift(-1,0) and not m.shift(0,INF),"bad offsets")
 m.shift(1,-5*M.UNIT)
 check(is_equal_approx(m.event_x(0,0),m.event_x(1,1)) and not m.aligned(),"repeated wrong flash fails second anchor")
 run_all(m);check(not m.completed,"wrong flash trial no completion")
 m.shift(1,-3*M.UNIT);check(m.aligned() and not m.completed,"alignment alone not completion")
 m.start();m.step(.1);m.pause();var before:float=m.elapsed;m.step(.1);check(m.elapsed==before,"paused trial")
 m.resume();m.shift(0,20);check(not m.running,"paper shift cancels pending proof")
 m.shift(0,0);run_all(m);check(m.completed and m.receipts.back().passed,"full aligned actual trial")
 check(m.travel==1 and m.gate==1,"carriage and gate finished")
 m.replace_roll();check(not m.aligned() and m.completed and not m.transfer_completed,"fresh roll and monotonic base")
 m.shift(1,2*M.UNIT);run_all(m);check(m.transfer_completed,"new origin transfer")
 var n=M.new();n.shift(0,3*M.UNIT);run_all(n);check(n.completed,"move other strip legal equivalent")
 n.start();n.step(.1);n.cancel();check(not n.running,"close cancels trial")
 var v=load("res://campuses/future_learning_center/scripts/puzzles/sync_view.gd").new();root.add_child(v);v.open()
 v._press(Vector2(450,260));v._release(Vector2(312,260));check(v.model.aligned(),"actual strip drag sets origin")
 v._press(Vector2(740,383));v._release(Vector2(740,383));check(v.model.running,"physical handle starts trial")
 v._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT);check(v.model.paused,"view focus pause")
 v._press(Vector2(500,380));v._release(Vector2(500,380));check(not v.model.paused,"touch apparatus resumes")
 v.close();v.open();check(v.model.aligned() and not v.model.running,"reopen preserves strips but not partial run")
 v._press(Vector2(300,160));v._cancel_pointer();check(v.tape_drag==-1,"cancel drag")
 v.queue_free();print("FLC_SYNC: ",checks," checks, ",failures," failures");quit(1 if failures else 0)
