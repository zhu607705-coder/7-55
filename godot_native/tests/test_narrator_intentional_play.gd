extends SceneTree
const Game=preload("res://scripts/games/prologue_interception.gd")
const Driver=preload("res://tests/prologue_word_driver.gd")
var checks=[]
var failures=[]
func _initialize():call_deferred("run")
func check(ok,label):
 checks.append({"name":label,"passed":ok})
 if not ok:failures.append(label)
func key(g,code,down):
 var e=InputEventKey.new();e.physical_keycode=code;e.pressed=down;g._gui_input(e)
func run():
 for x in [104.,215.,326.]:
  var g=Game.new();g.size=Vector2(430,820);root.add_child(g);g.set_process(false);g.start({"resume":true})
  g.session.set_target(x)
  for i in range(18000):g._process(.01)
  check(g.blocks<3 and g.session.phase=="hint","fixed %s cannot auto-complete; error awaits input"%x)
  var misses=g.misses
  for i in range(1000):g._process(.01)
  check(g.misses==misses,"fixed %s no automatic retry"%x)
  g.queue_free();await process_frame
 var g=Game.new();g.size=Vector2(430,820);root.add_child(g);g.set_process(false);g.start({"resume":true});var results=[];g.finished.connect(func(r):results.append(r))
 var retries=0
 for i in range(30000):
  if g.phase=="lock":break
  if g.session.phase=="hint" and g.retry_wait>.4:
   key(g,KEY_SPACE,true);key(g,KEY_SPACE,false);retries+=1
  Driver.steer(g);g._process(.01)
 check(g.phase=="lock","deliberate pointer steering reaches final hold")
 print("Driver retries: ",retries," stages: ",g.blocks," phase: ",g.phase)
 for i in range(1000):g._process(.01)
 check(g.hold_ms==0 and results.is_empty(),"idle lock cannot complete")
 key(g,KEY_SPACE,true)
 for i in range(100):g._process(.01)
 key(g,KEY_SPACE,false)
 check(g.hold_ms==0 and g.phase=="lock","early release resets hold")
 key(g,KEY_SPACE,true)
 for i in range(139):g._process(.01)
 check(g.phase=="lock","1390ms does not complete")
 g._process(.01)
 check(g.phase=="caught","1400ms reaches narrative")
 for i in range(1100):g._process(.01)
 check(results.size()==1 and results[0].interceptedCount==3 and results[0].dialogueCount==4 and results[0].whiteoutCompleted,"unchanged narrative proof emitted once")
 g.queue_free();await process_frame
 # Current-round reset and explicit retry preserve prior completed rounds.
 var m=load("res://scripts/games/prologue_word_model.gd").new()
 var content=JSON.parse_string(FileAccess.get_file_as_string("res://data/native/prologue-interception.content.json"))
 m.setup(content)
 m.stage=1;m.completed_stages=1;m.phase="search";m.collected=[content.stages[1].targets[0]];m.captures=[{"stage":0,"word":content.stages[0].targets[0]},{"stage":1,"word":content.stages[1].targets[0]}]
 m._fail("meaning",{"text":content.stages[1].distractors[0]})
 m.continue_stage()
 check(m.collected.is_empty() and m.completed_stages==1 and m.stage==1 and m.captures.size()==1,"retry clears only failed round and keeps completed round")
 var out={"checks":checks,"failed":failures,"passed":failures.is_empty()}
 var f=FileAccess.open(("user://REGRESSION_RESULTS.json" if OS.get_environment("NARRATOR_AUDIT_DIR").is_empty() else OS.get_environment("NARRATOR_AUDIT_DIR").path_join("REGRESSION_RESULTS.json")),FileAccess.WRITE);f.store_string(JSON.stringify(out,"  "));f.close()
 print(JSON.stringify(out,"  "));quit(0 if failures.is_empty() else 1)
