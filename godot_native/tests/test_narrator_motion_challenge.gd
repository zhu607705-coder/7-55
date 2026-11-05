extends SceneTree
const Model=preload("res://scripts/games/prologue_word_model.gd")
const Flow=preload("res://scripts/games/prologue_character_flow.gd")
const Driver=preload("res://tests/prologue_word_driver.gd")
var checks=[]
var failures=[]
func _initialize():call_deferred("run")
func check(ok,label):
 checks.append({"name":label,"passed":ok})
 if not ok:failures.append(label)
func run():
 var content=JSON.parse_string(FileAccess.get_file_as_string("res://data/native/prologue-interception.content.json"))
 check(Model.SPAWN_INTERVAL==.95,"authored 950ms stream cadence restored")
 check(Flow.ASSEMBLY_DURATION>.28 and Flow.ASSEMBLY_DURATION<.6,"visible assembly completes before collision")
 for stage in range(3):
  var m=Model.new();m.setup(content);m.stage=stage
  check(m.fall_speed()==360+stage*30,"stage %d restores reaction speed"%stage)
  m.begin_search();m.beat_index=Model.TARGET_BEATS[stage][0];m._spawn()
  var c=m.cards[0]
  check(absf(c.velocity.x)==12 and absf(c.angle)>0,"stage %d uses physical diagonal motion and tilt"%stage)
  var reaction=(Model.BOARD_Y-Model.BOARD_SIZE.y/2-Model.rotated_extent(c.size/2,c.angle).y-c.position.y)/c.velocity.y
  check(reaction>Flow.ASSEMBLY_DURATION+.30,"stage %d leaves readable reaction time after assembly"%stage)
 # A visible-state player makes decisions at 100ms intervals, rather than
 # updating an omniscient collision solution every physics tick.
 for fps in [30,60,120]:
  for keyboard in [false,true]:
   var m=Model.new();m.setup(content)
   var decision=0.0;var goal=215.0;var direction=0.0
   for i in range(fps*90):
    if m.phase in ["hint","complete"]:break
    decision-=1.0/fps
    if decision<=0:
     goal=Driver.goal_model(m);decision=.1
    if keyboard:
     direction=signf(goal-m.board_x) if absf(goal-m.board_x)>5 else 0.0
     m.stop_pointer()
    else:m.set_target(goal)
    m.advance(1.0/fps,direction)
   check(m.phase=="complete" and m.total_misses==0,"%dfps %s avoids every decoy and captures six words"%[fps,"keyboard" if keyboard else "pointer"])
   print("RUN ",fps," keyboard=",keyboard," seconds=",m.clock," captures=",m.captures.size()," misses=",m.total_misses," phase=",m.phase)
 var out={"checks":checks,"failures":failures,"passed":failures.is_empty()}
 var audit_dir=OS.get_environment("NARRATOR_AUDIT_DIR")
 if not audit_dir.is_empty():
  var f=FileAccess.open(audit_dir.path_join("MOTION_RESULTS.json"),FileAccess.WRITE)
  if f==null:push_error("Cannot write narrator motion audit result");quit(2);return
  f.store_string(JSON.stringify(out,"  "));f.close()
 print(JSON.stringify(out,"  "));quit(0 if failures.is_empty() else 1)
