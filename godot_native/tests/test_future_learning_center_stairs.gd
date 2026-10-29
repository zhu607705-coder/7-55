extends SceneTree
const Stair=preload("res://campuses/future_learning_center/scripts/stair_traversal.gd")
const Body=preload("res://scripts/player_metrics.gd")
var checks:=0
var failures:Array[String]=[]
func _initialize()->void:run.call_deferred()
func check(value:bool,label:String)->void:
	checks+=1
	if not value:failures.append(label);printerr("STAIR_FAIL: "+label)
func run()->void:
	if not preload("res://tests/native_test_isolation.gd").is_isolated_save():quit(2);return
	var model=Stair.new()
	check(not model.start(2,4,"northeast_stair"),"stairs cannot skip a floor")
	check(not model.start(3,4,"elevator"),"elevator is not a staircase")
	check(not model.start(2,1,"southwest_stair"),"no invented first-floor destination")
	for i:int in 1500:check(model.foot_supported(model.point_at(model.total*i/1499.0)),"whole foot supported on tread %d"%i)
	check(not model.foot_supported(Vector2(800,500)),"open stairwell rejects feet")
	check(not model.foot_supported(Vector2(1280,500)),"outer stair wall rejects feet")
	var up_center:=Vector2.ZERO
	for direction:int in [1,-1]:
		check(model.start(3,3+direction,"northeast_stair"),"paired stair begins")
		check(not model.start(3,3+direction,"northeast_stair"),"duplicate activation rejected")
		model.step(.5);model.pause();var paused:float=model.distance;model.step(10)
		check(is_equal_approx(model.distance,paused),"focus pause preserves physical position")
		model.resume()
		model.distance=model.total*.25
		model.center=model.camera_target()
		if direction==1:up_center=model.camera_target()
		else:check(model.camera_target().distance_to(up_center)>100,"look-ahead differs at same position in opposite directions")
		var complete:=0
		for i:int in 1100:
			if model.step(1.0/60):complete+=1
			var visible:=Rect2(model.center-model.VIEW/(2*model.zoom),model.VIEW/model.zoom)
			check(visible.grow(.1).encloses(Body.visual_rect(model.foot()-Body.FOOT_CENTER_OFFSET)),"full actor inside camera")
		check(complete==1,"one physical arrival per traversal")
		var receipt:Dictionary=model.take_arrival()
		check(receipt.get("floor")==3+direction,"arrival identifies paired floor")
		check(model.take_arrival().is_empty(),"arrival cannot be delivered twice")
	check(model.start(2,3,"southwest_stair"),"other staircase uses same projection")
	model.step(.5);model.cancel();check(model.take_arrival().is_empty(),"cancel cannot change floor")
	var positions:Array[Vector2]=[]
	for fps:int in [30,60,144]:
		var sample=Stair.new();sample.start(2,3,"southwest_stair")
		for i:int in fps*3:sample.step(1.0/fps)
		positions.append(sample.foot())
	check(positions[0].distance_to(positions[1])<.01 and positions[1].distance_to(positions[2])<.01,"motion independent of frame rate")
	print("FLC_STAIRS: %d checks, %d failures"%[checks,failures.size()]);quit(0 if failures.is_empty() else 1)
