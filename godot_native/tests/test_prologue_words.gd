extends SceneTree
const Model=preload("res://scripts/games/prologue_word_model.gd")
const Driver=preload("res://tests/prologue_word_driver.gd")
var checks=0
var failures=0
var content:Dictionary
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error("PROLOGUE WORDS: "+label)
func fresh():
 var m=Model.new();m.setup(content);return m
func advance(m,seconds:float,direction:float=0)->void:
 for i in int(ceil(seconds/.01)):m.advance(.01,direction)
func expected(m)->String:
 return str(m.missing()[0]) if not m.missing().is_empty() else ""
func drive(m,seconds:float=80)->void:
 for i in int(seconds/.01):
  if m.phase=="complete" or m.phase=="hint":return
  m.set_target(Driver.goal_model(m))
  m.advance(.01)
func run()->void:
 content=JSON.parse_string(FileAccess.get_file_as_string("res://data/native/prologue-interception.content.json"))
 check(content.stages.size()==3 and content.stages.map(func(s):return s.targets.size())==[1,2,3],"authored three semantic stages contain six distinct required word cards")
 check(content.stages[2].ordered and not content.stages[1].ordered,"only the sentence reconstruction requires order")
 var fast=Model.sweep_rect(Vector2(215,200),Vector2(0,20000),Vector2(40,24),.04,Vector2(215,658),Vector2.ZERO,Model.BOARD_SIZE/2,.09,.1)
 check(not fast.is_empty() and fast.time<.03 and fast.normal.y<-.9,"swept word rectangle catches a complete high-speed pass through the tilted board")
 var missed=Model.sweep_rect(Vector2(20,200),Vector2(0,20000),Vector2(20,24),0,Vector2(215,658),Vector2.ZERO,Model.BOARD_SIZE/2,0,.1)
 check(missed.is_empty(),"swept rectangle rejects the same vertical pass outside the board")
 var moving=Model.sweep_rect(Vector2(215,658),Vector2.ZERO,Vector2(40,24),0,Vector2(40,658),Vector2(3000,0),Model.BOARD_SIZE/2,0,.1)
 check(not moving.is_empty() and moving.normal.x>.9,"relative sweep catches a rapidly moving window rather than tunneling sideways")
 var m=fresh();advance(m,20)
 check(m.phase=="hint" and m.completed_stages==0 and m.collected.is_empty(),"no input cannot collect the first geometrically offset target or finish a stage")
 check(m.hint.reason=="unmoved" and m.hint.tier==1,"first passive miss describes the untouched window without supplying all targets")
 var unattended_contacts=m.contacts.duplicate(true)
 check(unattended_contacts.any(func(c):return c.get("demonstration",false)),"the untouched window visibly rebounds a background word before the target miss")
 var clock=m.clock;var positions=m.cards.duplicate(true);advance(m,10)
 check(m.clock==clock and m.cards==positions,"hint reading freezes word positions and never charges a second failure")
 m.continue_stage();check(m.phase=="search" and m.completed_stages==0,"continuation resumes this stage without granting progress")
 # Complete stages using only target movement and the model's real collision clock.
 for tries in range(20):
  drive(m)
  if m.phase=="complete":break
  if m.phase=="hint":m.continue_stage()
 check(m.phase=="complete" and m.completed_stages==3,"target selection and real swept contact complete exactly three stages")
 check(m.contacts.size()>=6,"successful play has at least six actual word/window contacts")
 check(m.captures.size()==6 and m.captures.map(func(c):return c.stage)==[0,1,1,2,2,2],"only the six authored targets produce captures in three stages")
 check(m.captures.all(func(c):return c.age>=.5 and c.age<1.1),"key targets retain the original 0.5 to 1.1 second reaction interval despite faster paragraph transitions")
 check(m.captures.filter(func(c):return c.stage==2).map(func(c):return c.word)==["旁白","还没","说完"],"the final three captures reconstruct the authored sentence in order")
 var author=ProjectSettings.globalize_path("res://../src/data/prologue-interception.content.json")
 check(FileAccess.get_file_as_string(author)==FileAccess.get_file_as_string("res://data/native/prologue-interception.content.json"),"native clue JSON exactly matches its sole authored Web source")
 var happy=fresh();drive(happy)
 check(happy.phase=="complete" and happy.total_misses==0,"a continuous legal selection strategy avoids background words and completes without failure")
 var n=fresh();advance(n,n.clue_duration()+.1);n.set_review(true)
 var frozen=n.cards.duplicate(true);clock=n.clock;advance(n,30,1)
 check(n.clock==clock and n.cards==frozen and n.board_x==215,"full-clue review pauses emission, movement and target expiry")
 n.set_review(false);n.continue_stage()
 # Fixture local physics only: inject cards to exercise semantic rejection at a real contact.
 var p=fresh();p.stage=2;p.completed_stages=2;p.phase="search";p.moved_distance=10
 var card={"id":90,"text":"还没","target":true,"position":Vector2(215,580),"size":Vector2(80,48),"angle":0.0,"velocity":Vector2(0,5000),"resolved":false,"life":.55,"age":0.0}
 p.cards=[card];p.spawn_clock=0;p.advance(.02)
 check(p.phase=="hint" and p.hint.reason=="order" and p.collected.is_empty(),"blocking a future sentence fragment cannot replace the next required fragment")
 p.collected=["旁白"];p.continue_stage()
 check(p.stage==2 and p.completed_stages==2 and p.collected==["旁白"],"failure continuation keeps both earlier stages and current-stage collected words")
 check(p.missing()==["还没","说完"],"only missing words remain after continuation")
 advance(p,.72)
 check(p.cards.size()==1 and p.cards[0].text=="还没","continuation emits a missing next fragment rather than an already retained word")
 var q=fresh();q.phase="search";q.moved_distance=10
 var wrong=card.duplicate(true);wrong.text="走";wrong.position=Vector2(215,580);wrong.velocity=Vector2(0,5000);wrong.resolved=false;q.cards=[wrong];q.advance(.02)
 check(q.phase=="hint" and q.hint.reason=="meaning" and q.collected.is_empty(),"a real collision with the wrong word does not count as semantic success")
 for tier in [2,3,3]:
  q.continue_stage();wrong=wrong.duplicate(true);wrong.position=Vector2(q.board_x,580);wrong.resolved=false;wrong.velocity=Vector2(0,5000);q.cards=[wrong];q.advance(.02)
  check(q.hint.get("tier",0)==tier and q.completed_stages==0,"hint tier escalates without resetting or auto-completing a stage")
 var retained=q.collected.duplicate();q.continue_stage();q.set_target(-900);advance(q,.5)
 check(q.board_x>=104 and q.board_target==104,"window remains inside source-space arena at its left extreme")
 q.set_target(900);advance(q,1)
 check(q.board_x<=326 and absf(q.board_angle)<=Model.MAX_TILT+.001,"window speed and tilt remain bounded at the right extreme")
 var report=OS.get_environment("PROLOGUE_WORD_REPORT")
 if not report.is_empty():
  var file=FileAccess.open(report,FileAccess.WRITE)
  file.store_string(JSON.stringify({"checks":checks,"failures":failures,"captures":m.captures,"activeClockSeconds":m.clock,"sourceCardStartY":294,"targetSpeeds":[360,390,420],"stageSpawnIntervalsMs":[950,950,950],"firstSpawnMs":350,"retrySpawnMs":700,"stageTransitionMs":280,"minObservedCaptureReadableSeconds":m.captures.map(func(c):return c.age).min(),"initialNoInputContacts":unattended_contacts},"  "))
 print("PROLOGUE_WORD_MODEL: %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
