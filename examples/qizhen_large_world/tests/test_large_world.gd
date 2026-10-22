extends SceneTree
const Model=preload("res://scripts/games/large_world_model.gd")
const Geo=preload("res://scripts/games/lake_geometry.gd")
const Driver=preload("res://tests/route_driver.gd")
var failures: Array[String]=[]
func check(value: bool,label: String) -> void:
	if not value:failures.append(label);push_error(label)
	else:print("PASS: "+label)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var game: RefCounted=Model.new()
	check(Geo.SIZE.x>=5000 and Geo.SIZE.y>=10000,"real world dimensions exceed old fixed viewport")
	check(Geo.water(game.position,31),"spawn is on navigable water")
	for goal in Geo.goals():check(Geo.water(goal.point,31),"goal on clear water: "+goal.title)
	var still: Vector2=game.position
	for n in range(600):game.step(1.0/60)
	check(game.position==still and game.progress==0,"idle cannot progress or auto-complete")
	game.reset();game.paused=true;game.input(true,1,false,true)
	for n in range(600):game.step(1.0/60)
	check(game.elapsed==0 and game.position==still,"pause freezes physics and objectives")
	game.reset();var driver:=Driver.new()
	for n in range(60*240):
		driver.control(game);game.step(1.0/60)
		if n%600==0:print("ROUTE ",JSON.stringify(game.result()))
		if game.status!="running":break
	check(game.status=="won","input-only full route succeeds")
	check(game.elapsed>=90,"successful route has at least 90 seconds of natural duration")
	check(game.active_time/game.elapsed>.90,"route duration is active control, not idle padding")
	check(game.travel>=19000,"route traverses expanded physical world")
	check(game.inspected and game.recovered,"both meaningful stop-and-interact objectives completed")
	check(game.completed_at.size()==9,"all nine stages earned in order")
	check(game.collisions<10,"successful route does not rely on scraping shoreline")
	var file:=FileAccess.open("user://route-result.json",FileAccess.WRITE)
	if file==null:
		push_error("Cannot write user://route-result.json");quit(1);return
	file.store_string(JSON.stringify({"result":game.result(),"failures":failures,"test_kind":"deterministic input-only controller, no model teleportation"},"  "))
	print("FINAL ",JSON.stringify(game.result()));quit(0 if failures.is_empty() else 1)
