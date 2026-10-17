extends SceneTree
const Model=preload("res://scripts/games/large_world_model.gd")
const Driver=preload("res://tests/route_driver.gd")
func _initialize() -> void:
 var game=Model.new()
 var driver=Driver.new()
 for n in range(30*240):
  driver.control(game);game.step(1.0/30)
  if game.status!="running":break
 print("30HZ ",JSON.stringify(game.result()))
 quit(0 if game.status=="won" and game.elapsed>=90 else 1)
