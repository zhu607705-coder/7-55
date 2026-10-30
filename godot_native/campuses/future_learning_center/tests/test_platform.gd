extends SceneTree
const M=preload("res://campuses/future_learning_center/scripts/puzzles/platform_model.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func photo(m)->void:
 m.shutter()
 for i:int in 6:m.step(.1)
func _initialize()->void:call_deferred("run")
func run()->void:
 var m=M.new()
 check(not m.assess().success,"initial not solved")
 check(m.move_board(Vector2(700,210)) and m.move_board(Vector2(700,430)),"clear east approach")
 photo(m);check(m.shot.success and m.records.size()==1,"east actual exposure")
 photo(m);check(m.records.size()==1,"repeat not second condition")
 check(not m.move_board(Vector2(260,430)) and m.board==Vector2(700,430),"sweep camera no teleport")
 check(m.move_board(Vector2(700,370)) and m.move_board(Vector2(260,370)) and m.move_board(Vector2(260,430)),"go around camera")
 check(not m.assess().success and m.records.has(0),"east old proof retained after layout changed")
 m.set_condition(1);photo(m);check(m.completed and m.records.size()==2,"different layouts accepted")
 check(m.records[0].board!=m.records[1].board,"proof preserves each condition layout")
 check(not m.move_board(Vector2(NAN,300)),"nonfinite rejected")
 var n=M.new();n.move_board(Vector2(700,210));n.move_board(Vector2(700,370));n.move_board(Vector2(480,370))
 check(n.assess().blocked and n.assess().visible_corners<4,"camera obstructed")
 n.shutter();n.set_condition(1);n.step(1);check(n.history.is_empty(),"condition switch cancels exposure")
 n.shutter();n.pause();n.step(1);check(n.history.is_empty(),"pause does not invent photograph")
 var v=load("res://campuses/future_learning_center/scripts/puzzles/platform_view.gd").new();root.add_child(v);v.open()
 var down=InputEventScreenTouch.new();down.index=1;down.pressed=true;down.position=Vector2(740,160);v._input(down)
 check(v.board_drag and v.touch_id==1,"touch selects physical board")
 var second=InputEventScreenTouch.new();second.index=2;second.pressed=true;second.position=Vector2(480,414);v._input(second)
 check(v.touch_id==1 and not v.model.photographing,"second pointer does not hijack")
 down.pressed=true;down.canceled=true;v._input(down);check(not v.board_drag and v.touch_id==-1,"touch cancel releases")
 var at:Vector2=v.model.board;v.close();v.open();check(v.model.board==at,"close reopen retains apparatus")
 v.queue_free();await process_frame
 print("platform: ",checks," checks, ",failures," failures");quit(1 if failures else 0)
