extends SceneTree
const Game=preload("res://scripts/games/prologue_interception.gd")
const Driver=preload("res://tests/prologue_word_driver.gd")
var out=OS.get_environment("UI_CAPTURE_DIR")
var game
func _initialize():call_deferred("run")
func shot(label):
 game.queue_redraw()
 for i in range(4):await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(out.path_join(label+".png"))
func run():
 DirAccess.make_dir_recursive_absolute(out)
 for extent in [Vector2i(390,844),Vector2i(1440,900)]:
  root.size=extent;DisplayServer.window_set_size(extent)
  game=Game.new();game.size=Vector2(extent);root.add_child(game);game.set_process(false);game.start({"resume":true})
  var prefix="%dx%d-"%[extent.x,extent.y]
  for i in range(1200):
   game._process(.01)
   if game.phase=="intercept" and not game.session.cards.is_empty():break
  await shot(prefix+"goal-first-round")
  for i in range(5000):
   game._process(.01)
   if game.session.phase=="hint":break
  for i in range(50):game._process(.01)
  await shot(prefix+"error-explicit-retry")
  game.retry_button.pressed.emit()
  var second=false
  for i in range(20000):
   Driver.steer(game);game._process(.01)
   if not second and game.session.stage==1 and game.session.phase=="search" and game.session.cards.any(func(c):return not c.resolved and c.target and c.position.y>450):
    await shot(prefix+"second-round-word-size");second=true
   if game.phase=="lock":break
  game._pointer_end(-1)
  for i in range(60):game._process(.01)
  await shot(prefix+"hold-instruction")
  game.queue_free();await process_frame
 quit()
