extends SceneTree
const Game=preload("res://scripts/games/prologue_interception.gd")
const Model=preload("res://scripts/games/prologue_word_model.gd")
var failures=[]
var checks=[]
func _initialize():call_deferred("run")
func check(ok,label):
 checks.append({"name":label,"passed":ok})
 if not ok:failures.append(label)
func run():
 var content=JSON.parse_string(FileAccess.get_file_as_string("res://data/native/prologue-interception.content.json"))
 var bypasses=[]
 for x in range(104,327,2):
  var m=Model.new();m.setup(content);m.set_target(x)
  for i in range(15000):
   if m.phase=="hint" or m.phase=="complete":break
   m.advance(.01)
  if m.completed_stages==3:bypasses.append(x)
 check(bypasses.is_empty(),"all 112 fixed board positions cannot finish")
 for st in [1,2]:
  var m=Model.new();m.setup(content);m.stage=st;m.completed_stages=st;m.begin_search()
  for i in range(12000):
   if m.phase=="hint" or m.phase=="complete":break
   m.advance(.01)
  check(m.completed_stages==st,"center idle cannot auto-catch round %d"%(st+1))
 var g=Game.new();g.size=Vector2(430,820);root.add_child(g);g.set_process(false);g.start({"resume":true})
 for i in range(800):g._process(.01)
 var touch=InputEventScreenTouch.new();touch.index=4;touch.position=g.board_center();touch.pressed=true;g._gui_input(touch)
 var drag=InputEventScreenDrag.new();drag.index=4;drag.position=g.board_center()+Vector2(100,0);g._gui_input(drag)
 g._process(.1)
 check(g.session.board_x>215 and g.dragging,"touch drag moves window")
 touch.pressed=false;touch.canceled=true;g._gui_input(touch)
 check(not g.dragging and g.pointer_id==-99,"touch cancel releases grip")
 var joy=InputEventJoypadMotion.new();joy.axis=JOY_AXIS_LEFT_X;joy.axis_value=-1;g.grab_focus();root.push_input(joy,true);g._process(.1)
 check(g.left_held and g.session.board_x<259,"gamepad left stick moves window")
 var c=g.session.clock;var x=g.session.board_x
 g._pause()
 for i in range(300):g._process(.01)
 check(g.session.clock==c and g.session.board_x==x and not g.left_held,"pause freezes moving scene and clears held input")
 g._resume();g._process(.1)
 check(not g.paused and g.session.clock>c,"explicit resume continues only after resume")
 g._switch("lock");g.holding=true;g._process(.5);g._pause()
 check(g.hold_ms==0 and not g.holding,"pause clears incomplete lock grip")
 g._resume()
 var button=InputEventJoypadButton.new();button.button_index=JOY_BUTTON_A;button.pressed=true;root.push_input(button,true)
 for i in range(140):g._process(.01)
 check(g.phase=="caught","gamepad A holds final word")
 var out={"checks":checks,"failures":failures,"passed":failures.is_empty()}
 var f=FileAccess.open(("user://INPUT_RESULTS.json" if OS.get_environment("NARRATOR_AUDIT_DIR").is_empty() else OS.get_environment("NARRATOR_AUDIT_DIR").path_join("INPUT_RESULTS.json")),FileAccess.WRITE);f.store_string(JSON.stringify(out,"  "));f.close()
 print(JSON.stringify(out,"  "));quit(0 if failures.is_empty() else 1)
