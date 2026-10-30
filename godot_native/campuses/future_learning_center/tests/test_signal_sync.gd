extends SceneTree
const M=preload("res://campuses/future_learning_center/scripts/puzzles/signal_sync_model.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func trial(m)->void:
 m.change_source()
 for i:int in 14:m.step(.1)
func _initialize()->void:call_deferred("run")
func run()->void:
 var m=M.new();check(m.screens[0]!=m.screens[1] and not m.completed,"visible initial version mismatch")
 m.change_source();m.step(.1);check(m.screens==[0,2],"propagation takes time")
 for i:int in 14:m.step(.1)
 check(m.screens==[1,2] and m.receipts.is_empty(),"cache stays old")
 trial(m);check(m.screens==[2,2] and m.receipts.is_empty(),"static equality with cache still not proof")
 check(m.connect_ports("screen_b","live_b"),"rewire live socket")
 trial(m);check(m.receipts.size()==1 and not m.completed,"one change insufficient")
 var rev:int=m.revision;m.move_screen(0,Vector2(790,350));m.move_screen(1,Vector2(620,180))
 check(m.revision==rev and m.receipts.size()==1,"moving hardware preserves cable identity")
 trial(m);check(m.completed and m.receipts.size()==2,"two distinct real changes")
 m.unplug("bus_in");check(m.receipts.is_empty() and m.completed,"editing invalidates receipts not history/success")
 trial(m);check(not m.history.back().passed,"unplugged input fails")
 check(not m.connect_ports("bus_in","cache"),"cache cannot fit keyed source input")
 check(not m.connect_ports("bus_in","live_a"),"self loop rejected by port geometry")
 check(not m.connect_ports("screen_a","source"),"source connector cannot fit screen")
 check(not m.connect_ports("screen_a","live_b"),"one physical cable per output")
 m.connect_ports("bus_in","source");m.change_source();m.pause();m.step(1);check(not m.running and m.receipts.is_empty(),"interruption needs explicit new trial")
 check(not m.connect_ports("fake","source") and not m.connect_ports("screen_a","fake"),"unknown ports rejected")
 check(not m.move_screen(0,Vector2(INF,0)),"invalid screen position")
 var v=load("res://campuses/future_learning_center/scripts/puzzles/signal_sync_view.gd").new();root.add_child(v);v.open()
 var down=InputEventScreenTouch.new();down.index=1;down.pressed=true;down.position=v.port_at("screen_b");v._input(down)
 check(v.cable_input=="screen_b","touch selects socket")
 var other=InputEventScreenTouch.new();other.index=2;other.pressed=true;other.position=Vector2(150,225);v._input(other)
 check(not v.model.running and v.touch_id==1,"second touch cannot change source")
 down.pressed=true;down.canceled=true;v._input(down);check(v.cable_input.is_empty() and v.touch_id==-1,"canceled drag does not unplug")
 check(v.model.cables.screen_b=="cache","cancel preserves connection")
 v._press(v.port_at("screen_b"));v._release(v.port_at("live_b"));check(v.model.cables.screen_b=="live_b","actual socket drag")
 v.close();v.open();check(v.model.cables.screen_b=="live_b","close reopen preserves wiring")
 v.queue_free();await process_frame
 print("signal_sync: ",checks," checks, ",failures," failures");quit(1 if failures else 0)
