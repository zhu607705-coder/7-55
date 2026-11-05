extends SceneTree
## Real rendering fixture. Uses the same legal pointer driver as model tests;
## screenshots are visual evidence, not a physical-phone acceptance claim.
const Game=preload("res://scripts/games/prologue_interception.gd")
const Driver=preload("res://tests/prologue_word_driver.gd")
var out=OS.get_environment("UI_CAPTURE_DIR")
var game
var frames=[]
func _initialize():call_deferred("run")
func shot(label):
 game.queue_redraw()
 for i in range(4):await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(out.path_join(label+".png"))
 var cards=[]
 for c in game.session.cards:
  cards.append({"id":c.id,"word":c.text,"age":c.age,"position":[c.position.x,c.position.y],"angle":c.angle,"velocity":[c.velocity.x,c.velocity.y]})
 frames.append({"file":label+".png","phase":game.phase,"stage":game.session.stage,"cards":cards,"line":game._retained_sentence(),"captures":game.session.captures.duplicate(true)})
func run():
 if out.is_empty():push_error("UI_CAPTURE_DIR must name the evidence directory");quit(1);return
 DirAccess.make_dir_recursive_absolute(out)
 for extent in [Vector2i(390,844),Vector2i(1440,900)]:
  root.size=extent;DisplayServer.window_set_size(extent)
  game=Game.new();game.size=Vector2(extent);root.add_child(game);game.set_process(false);game.start({})
  var prefix="%dx%d-"%[extent.x,extent.y]
  for tick in range(230):game._process(.01)
  await shot(prefix+"receipt")
  game._continue_success();game._process(.01)
  await shot(prefix+"location-error")
  var target_id=-1
  var snapshots=[.05,.20,.42,.64]
  var frame_index=0
  for tick in range(16000):
   if game.phase=="lock":break
   if game.session.phase=="hint":push_error("Capture driver missed a target");quit(1);return
   Driver.steer(game);game._process(.01)
   if game.session.stage==0 and frame_index<snapshots.size():
    for card in game.session.cards:
     if card.target and not card.resolved and (target_id<0 or card.id==target_id):
      target_id=card.id
      if card.age>=snapshots[frame_index]:
       await shot(prefix+"same-word-%d"%frame_index);frame_index+=1
      break
  if game.phase!="lock" or frame_index!=snapshots.size():push_error("Capture did not reach the genuine final hold or all same-word frames");quit(1);return
  game._pointer_end(-1)
  for tick in range(60):game._process(.01)
  await shot(prefix+"earned-sentence-before-hold")
  game.queue_free();await process_frame
  game=Game.new();game.size=Vector2(extent);root.add_child(game);game.set_process(false);game.start({"resume":true})
  for tick in range(6000):
   game._process(.01)
   if game.session.phase=="hint":break
  if game.session.phase!="hint":push_error("Idle capture did not reach the real missed-target feedback");quit(1);return
  for tick in range(50):game._process(.01)
  await shot(prefix+"minimal-retry")
  game.queue_free();await process_frame
 var f=FileAccess.open(out.path_join("narrator_revision_frames.json"),FileAccess.WRITE);f.store_string(JSON.stringify(frames,"  "));f.close()
 quit()
