extends SceneTree
const M=preload("res://campuses/future_learning_center/scripts/puzzles/recording_model.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func run_feed(m,direction:int)->void:
 m.drive(direction)
 for i:int in 80:m.step(.1)
func photo(m)->void:
 m.shutter()
 for i:int in 7:m.step(.1)
func _initialize()->void:call_deferred("run")
func run()->void:
 var m=M.new()
 check(m.light_blocked(),"initial shade intersects light ray")
 photo(m);check(not m.completed and m.photo_kind=="empty","static shade without arrival not enough")
 run_feed(m,1)
 check(m.x<430 and m.x>390 and not m.running,"real collision at crossing")
 var stalled:float=m.x
 m.pause();check(m.x==stalled,"stop retains position")
 check(m.move_baffle(150) and not m.light_blocked(),"clear baffle")
 run_feed(m,1);check(m.x==M.END and m.reached_round==m.round_id,"arrival from continuation")
 photo(m);check(m.photo_kind=="glare" and not m.completed,"open path photograph overexposed")
 var reached:int=m.reached_round
 m.move_baffle(300);check(m.reached_round==reached and m.x==M.END,"baffle edit retains this round travel")
 photo(m);check(m.completed and m.photo_round==m.round_id and m.photo_kind=="clear","same round arrival then shade completes")
 var old_round:int=m.round_id
 run_feed(m,-1);check(m.x>452 and m.x<500 and m.reached_round==-1,"reverse hits shade and invalidates arrival")
 photo(m);check(m.photo_round==-1 and not m.history.back().passed,"old photograph cannot prove new trial")
 m.move_baffle(150);run_feed(m,-1);check(m.x==M.START,"full reverse to origin")
 run_feed(m,1);m.move_baffle(300);photo(m)
 check(m.round_id>old_round and m.photo_round==m.round_id,"second actual round")
 check(not m.move_baffle(NAN) and not m.move_baffle(500),"invalid baffle geometry")
 var n=M.new();n.move_baffle(150)
 for i:int in 25:n.nudge(1)
 check(n.x==M.END and n.reached_round==n.round_id,"25 untimed handwheel strokes suffice")
 n.move_baffle(300);photo(n);check(n.completed,"no timing requirement")
 var p=M.new();p.move_baffle(150);p.drive(1);p.step(.1);var at:float=p.x;p.pause();p.step(1)
 check(p.x==at and not p.running,"focus cancels drive without resetting")
 p.drive(1);p.step(.1);check(p.x>at,"explicit resume")
 p.shutter();p.move_baffle(300);check(not p.photographing,"edits cancel pending exposure")
 var s=M.new();s.move_baffle(150);s.drive(1);s.advance(220)
 check(not s.move_baffle(300) and s.baffle_y==150,"baffle cannot teleport through carriage")
 var v=load("res://campuses/future_learning_center/scripts/puzzles/recording_view.gd").new();root.add_child(v);v.open()
 v._press(Vector2(441,300));v._release(Vector2(441,150));check(v.model.baffle_y==150,"drag physical baffle")
 v._press(Vector2(733,210));v._release(Vector2(733,260));check(v.model.direction==1,"drag actual feed lever")
 v.model.step(.1);var x:float=v.model.x;v.close();v.open();check(v.model.x==x and not v.model.running,"close reopen preserves carriage")
 v._press(Vector2(695,445));v._release(Vector2(695,445));check(v.model.x>x,"handwheel physical click")
 v._press(Vector2(441,150));v._cancel_pointer();check(not v.baffle_drag,"capture cancellation")
 v.queue_free();print("FLC_RECORDING: ",checks," checks, ",failures," failures");quit(1 if failures else 0)
