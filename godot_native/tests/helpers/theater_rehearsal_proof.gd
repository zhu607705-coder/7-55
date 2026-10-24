extends RefCounted
## QA-only earned-input trace. Never included in a production export.
const Model=preload("res://scripts/games/theater_shadow_rehearsal_model.gd")
static func move(model: RefCounted,id: String,at: Vector2) -> bool:
	var object: Dictionary={}
	for candidate: Dictionary in model.snapshot().objects:
		if candidate.id==id:object=candidate;break
	if object.is_empty():return false
	var start=Vector2(float(object.x),float(object.depth))
	if start.distance_to(at)<.00001:return true
	var steps: int=maxi(1,ceili(start.distance_to(at)/0.4))
	for i in range(1,steps+1):
		var p: Vector2=start.lerp(at,float(i)/steps)
		if not model.apply({"kind":"move","id":id,"x":p.x,"depth":p.y}):return false
	return true
static func solve_round(model: RefCounted) -> bool:
	match int(model.snapshot().round):
		0:
			if not move(model,"left_fan",Vector2(0,5)) or not spread(model,"left_fan",1.0):return false
		1:
			if not move(model,"left_fan",Vector2(0,6)) or not spread(model,"left_fan",.65):return false
		2:
			if not move(model,"side_screen",Vector2(4.4,8)):return false
			if not lamp(model,.6):return false
			if not move(model,"left_fan",Vector2(.36,4)) or not spread(model,"left_fan",1.0):return false
			if not move(model,"right_fan",Vector2(.24,6)) or not spread(model,"right_fan",.7):return false
	return model.apply({"kind":"try"}) and model.snapshot().screen in ["round_complete","complete"]
static func spread(model:RefCounted,id:String,value:float)->bool:
	var start:float=0.0
	for object:Dictionary in model.snapshot().objects:
		if object.id==id:start=float(object.spread)
	if is_equal_approx(start,value):return true
	var steps:int=ceili(absf(value-start)/.18)
	for i:int in range(1,steps+1):
		if not model.apply({"kind":"spread","id":id,"value":lerpf(start,value,float(i)/steps)}):return false
	return true
static func lamp(model:RefCounted,value:float)->bool:
	var start:float=model.snapshot().lampX
	if is_equal_approx(start,value):return true
	var steps:int=ceili(absf(value-start)/.5)
	for i:int in range(1,steps+1):
		if not model.apply({"kind":"lamp","x":lerpf(start,value,float(i)/steps)}):return false
	return true
static func proof(config: Dictionary={}) -> Dictionary:
	var model=Model.new()
	for round_id in 3:
		if not solve_round(model):return {}
		if round_id<2 and not model.apply({"kind":"continue"}):return {}
	return model.proof(config.get("session",{}))
