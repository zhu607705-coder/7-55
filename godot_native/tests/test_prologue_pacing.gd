extends SceneTree
## Measure the actual six-contact route, excluding blackout and later dialogue.
const Game=preload("res://scripts/games/prologue_interception.gd")
const Driver=preload("res://tests/prologue_word_driver.gd")
var checks=0
var failures=0
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error("PROLOGUE PACING: "+label)
func game_view()->Control:
 var game=Game.new();game.size=Vector2(430,820);root.add_child(game);game.set_process(false);game.start({"resume":true})
 for tick:int in 800:
  if game.phase=="deploy":break
  game._process(.01)
 return game
func run()->void:
 var game=game_view();var active=0.0;var paused_once=false;var marks:Array=[];var previous=""
 for tick:int in 12000:
  var key=game.phase+":"+str(game.session.stage)
  if key!=previous:marks.append({"phase":game.phase,"stage":game.session.stage,"activeSeconds":active});previous=key
  if game.phase=="caught":break
  if active>=11 and not paused_once:
   game._pause()
   var clock=game.session.clock;var flow=game.text_flow_clock;var beat=game.session.beat_index;var spawn=game.session.spawn_clock
   for frame:int in 200:game._process(.01)
   check(game.session.clock==clock and game.text_flow_clock==flow and game.session.beat_index==beat and game.session.spawn_clock==spawn,"pause freezes the same authored stream instead of consuming the longer route")
   game._resume();paused_once=true
  Driver.steer(game);game._process(.01);active+=.01
 check(game.phase=="caught" and active>=38 and active<=42,"six real contacts and the final grip naturally complete in approximately forty active seconds")
 check(game.misses==0,"the authored decoy combinations have a continuous legal route at the original window speed")
 check(game.session.captures.size()==6 and game.blocks==3 and game.hold_ms==1400,"longer play still requires exactly six targets, three stages and the original held grip")
 check(game.session.captures.all(func(c):return c.age>=.5 and c.age<1.1),"longer route preserves original reaction-critical transit times")
 check(game.session.serial>=26,"the added duration contains physical word encounters rather than an end-of-stage timer")
 var content=game.content.duplicate(true)
 var model=Game.WordModel.new();model.setup(content);model.stage=1;model.phase="search"
 for tick:int in 1000:
  if model.phase=="hint":break
  for card:Dictionary in model.cards:
   if not card.resolved:model.set_target(card.position.x)
  model.advance(.01)
 check(model.phase=="hint" and model.released_words.is_empty(),"an early real decoy contact occurs before future coordinate targets have been introduced")
 model.continue_stage()
 for tick:int in 72:model.advance(.01)
 check(not model.cards.is_empty() and model.cards.all(func(card):return not card.target),"an early mistake cannot skip the encounter deck by forcing a future answer into the next spawn")
 var idle=game_view()
 for tick:int in 7000:idle._process(.01)
 check(idle.blocks==0 and idle.session.captures.is_empty() and idle.misses>0 and not idle.done,"waiting beyond forty seconds never grants targets or completes the activity")
 var report={"checks":checks,"failures":failures,"activeSecondsToCaught":active,"misses":game.misses,"marks":marks,"captures":game.session.captures,"physicalWordsEmitted":game.session.serial}
 var output=OS.get_environment("PROLOGUE_PACING_REPORT")
 if not output.is_empty():var file=FileAccess.open(output,FileAccess.WRITE);file.store_string(JSON.stringify(report,"  "))
 print("PROLOGUE_PACING: %d checks; %d failures; activeSeconds=%.2f"%[checks,failures,active])
 game.queue_free();idle.queue_free();await process_frame;quit(1 if failures else 0)
