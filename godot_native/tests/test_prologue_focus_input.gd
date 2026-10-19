extends SceneTree
## All progression is earned with root Viewport keyboard/touch/pointer input.
const Game=preload("res://scripts/games/prologue_interception.gd")
const Driver=preload("res://tests/prologue_word_driver.gd")
var checks=0
var failures=0
var game:Control
var events:Array=[]
var results:Array=[]
var observations:Array=[]
var held=0
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
 checks+=1;observations.append({"check":label,"pass":ok,"phase":game.phase,"stages":game.blocks,"collected":game.session.collected.duplicate()})
 if not ok:failures+=1;push_error("PROLOGUE INPUT: "+label)
func frames(n:int=2)->void:
 for i in n:await process_frame
func key(code:Key,down:bool)->void:
 var e=InputEventKey.new();e.keycode=code;e.physical_keycode=code;e.pressed=down;root.push_input(e,true)
func keyboard(direction:int)->void:
 if direction==held:return
 if held:key(KEY_A if held<0 else KEY_D,false)
 held=direction
 if held:key(KEY_A if held<0 else KEY_D,true)
func click(point:Vector2)->void:
 # Human press/release spans frames; every intervening frame lays out the view.
 var e=InputEventMouseButton.new();e.position=point;e.global_position=point;e.button_index=MOUSE_BUTTON_LEFT;e.pressed=true;root.push_input(e,true)
 for i in 3:
  game._process(.01)
  await process_frame
 e=InputEventMouseButton.new();e.position=point;e.global_position=point;e.button_index=MOUSE_BUTTON_LEFT;e.pressed=false;root.push_input(e,true)
 await frames()
func touch(point:Vector2,down:bool,index:int=0,cancelled:bool=false)->void:
 var e=InputEventScreenTouch.new();e.position=point;e.pressed=down;e.index=index;e.canceled=cancelled;root.push_input(e,true)
func drag(point:Vector2,index:int=0)->void:
 var e=InputEventScreenDrag.new();e.position=point;e.index=index;root.push_input(e,true)
func tick(seconds:float)->void:
 for i in int(ceil(seconds/.01)):game._process(.01)
func until_phase(target:String,seconds:float=90)->bool:
 for i in int(seconds/.01):
  if game.phase==target:return true
  if game.phase=="failed":keyboard(0);return false
  var difference=Driver.goal(game)-game.session.board_x
  keyboard(-1 if difference < -3 else 1 if difference>3 else 0)
  game._process(.01)
 keyboard(0);return game.phase==target
func run()->void:
 root.size=Vector2i(430,820);game=Game.new();game.size=Vector2(430,820);root.add_child(game);game.set_process(false)
 game.finished.connect(func(r):results.append(r));game.presentation_requested.connect(func(id,p):events.append({"id":id,"payload":p}))
 game.start({"resume":true});game._process(0);await frames()
 check(root.gui_get_focus_owner()==game,"ordinary startup owns root keyboard focus")
 tick(7.1);check(game.phase=="deploy","source blackout leads to readable semantic fragments")
 var baseline=game.session.board_x
 key(KEY_D,true);tick(.12);key(KEY_D,false)
 check(game.session.board_x>baseline+30,"real root keyboard moves the physical error window")
 check(absf(game.session.board_angle)>0,"window movement changes its visible and physical tilt")
 await click(game.review_button.get_global_rect().get_center());game._process(0)
 check(game.session.reviewing,"real review control opens the complete authored clue")
 var frozen=game.session.clock;var x=game.session.board_x
 key(KEY_A,true);tick(8);key(KEY_A,false)
 check(game.session.clock==frozen and game.session.board_x==x and game.misses==0,"reading a clue cannot move, expire or punish words")
 await click(game.close_review.get_global_rect().get_center());game._process(0)
 check(not game.session.reviewing and root.gui_get_focus_owner()==game,"closing review restores root gameplay focus")
 key(KEY_R,true);key(KEY_R,false);tick(.04)
 check(game.session.reviewing,"R reopens the clue after a real cross-frame button click")
 key(KEY_R,true);key(KEY_R,false);tick(.04)
 check(not game.session.reviewing and root.gui_get_focus_owner()==game,"R closes the clue and retains root gameplay focus")
 # A touch must start on the rendered window and retain its initiating finger.
 touch(Vector2(20,220),true);drag(Vector2(300,660));tick(.1)
 check(not game.dragging,"touching empty space does not teleport the window")
 touch(Vector2(20,220),false)
 var center=game.board_center();touch(center,true);drag(center+Vector2(-85,0),1);tick(.05)
 check(is_equal_approx(game.session.board_x,x),"a different finger cannot steal a window drag")
 drag(center+Vector2(-85,0));tick(.2)
 check(game.session.board_x<x-50,"root touch drag moves the actual rendered window")
 touch(center,false,0,true);var stopped=game.session.board_x;drag(center+Vector2(90,0));tick(.1)
 check(not game.dragging and is_equal_approx(game.session.board_x,stopped),"touch cancellation releases ownership and stops stale drag movement")
 key(KEY_ESCAPE,true);key(KEY_ESCAPE,false);game._process(0)
 check(game.paused,"Escape pauses the semantic game through root input")
 frozen=game.session.clock;tick(1)
 check(game.session.clock==frozen,"pause freezes the word simulation")
 await click(game.resume_button.get_global_rect().get_center());game._process(0)
 check(not game.paused and root.gui_get_focus_owner()==game,"pointer Continue restores keyboard ownership")
 # Deliberately stay opposite each target to earn a semantic failure.
 for i in 2200:
  if game.phase=="failed":break
  var desired=104.0
  for card:Dictionary in game.session.cards:
   if card.target and not card.resolved:desired=104 if card.position.x>215 else 326
  var difference=desired-game.session.board_x
  keyboard(-1 if difference < -3 else 1 if difference>3 else 0);game._process(.01)
 keyboard(0);game._process(0)
 check(game.phase=="failed" and game.blocks==0 and results.is_empty(),"missing a real required word reaches a branch without fabricated proof")
 var before=game.session.collected.duplicate();var stage=game.session.stage
 await click(game.retry.get_global_rect().get_center());game._process(0)
 check(game.phase=="intercept" and game.session.stage==stage and game.session.collected==before,"real branch Continue retains the current stage and collection")
 check(root.gui_get_focus_owner()==game,"branch Continue immediately restores root focus")
 var started=game.session.clock
 var reached=until_phase("lock",140);keyboard(0)
 check(reached and game.blocks==3,"real root keyboard selection earns all three semantic stages")
 check(game.session.contacts.size()>=6 and game.session.captures.size()==6,"completion requires exactly six authored word captures through actual contact")
 check(game.session.clock-started>30,"readable finding and interception are longer than three endpoint checks")
 if not reached:finish();return
 key(KEY_SPACE,true);tick(.7);key(KEY_SPACE,false)
 check(game.hold_ms==0 and results.is_empty(),"short root Space hold resets without completing")
 key(KEY_SPACE,true);tick(.6);key(KEY_ESCAPE,true);key(KEY_ESCAPE,false);key(KEY_SPACE,false);game._process(0)
 check(game.paused and game.hold_ms==0 and not game.holding,"pausing a hold clears the held input")
 await click(game.resume_button.get_global_rect().get_center());game._process(0)
 key(KEY_SPACE,true);tick(1.39)
 check(game.phase=="lock" and results.is_empty(),"source hold threshold remains exactly 1400ms")
 tick(.02);key(KEY_SPACE,false)
 check(game.phase=="caught" and game.hold_ms==1400,"root Space completes the earned lock after resume")
 tick(8.8);check(results.is_empty(),"all four source dialogue lines still precede completion")
 tick(2);check(results.size()==1 and results[0].interceptedCount==3 and results[0].dialogueCount==4 and results[0].whiteoutCompleted,"ordinary completion emits the original proof exactly once")
 # Uniform source viewport mapping keeps the physical hit target under its art.
 for dimensions:Vector2 in [Vector2(390,780),Vector2(800,820),Vector2(320,640)]:
  game.size=dimensions;game._process(0)
  check(is_equal_approx(game.field.size.x/game.field.size.y,430.0/820.0),"viewport preserves the source aspect ratio at "+str(dimensions))
  check(Rect2(Vector2.ZERO,dimensions).encloses(game.field),"source viewport fits entirely within "+str(dimensions))
  check(game._logical(game.board_center()).distance_to(Vector2(game.session.board_x,658))<.001,"scaled pointer geometry matches the drawn board at "+str(dimensions))
 finish()
func finish()->void:
 var report=OS.get_environment("PROLOGUE_FOCUS_REPORT")
 if not report.is_empty():
  var file=FileAccess.open(report,FileAccess.WRITE);file.store_string(JSON.stringify({"checks":checks,"failures":failures,"observations":observations,"events":events,"results":results},"  "))
 game.queue_free();await process_frame
 print("NATIVE_PROLOGUE_FOCUS_INPUT: %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
