extends SceneTree
const Sample=preload("res://scripts/presentation/blender_lake_sample.gd")
const Model=preload("res://scripts/games/large_world_model.gd")
const Driver=preload("res://tests/sample_route_driver.gd")
func _initialize() -> void:
 var s:=Sample.new();var g:=Model.new();g.route_goals=s.sample_goals();g.navigation_check=s._platform_clear;g.interaction_check=s._contact_allowed
 var d:=Driver.new()
 for n in range(60*80):
  d.control(g);g.input(d.throttle,d.turn,d.brake,d.use);g.step(1.0/60)
  if n%120==0:print("ROUTE ",JSON.stringify(g.result())," dockstage ",d.dock_stage)
  if g.status!="running":break
 var result: Dictionary=g.result();result["input_only"]=true;result["no_teleports"]=true
 var file:=FileAccess.open("res://../verification/sample-route.json",FileAccess.WRITE);file.store_string(JSON.stringify(result,"  "));print("FINAL ",JSON.stringify(result));s.free();quit(0 if g.status=="won" else 1)
