extends RefCounted
## QA-only earned-input trace. Never included in a production export.
const Model=preload("res://scripts/games/theater_shadow_rehearsal_model.gd")
static func move(model: RefCounted,id: String,at: Vector2) -> bool:
	var object: Dictionary={}
	for candidate: Dictionary in model.snapshot().objects:
		if candidate.id==id:object=candidate;break
	if object.is_empty():return false
	var start=Vector2(float(object.x),float(object.depth));var steps: int=maxi(1,ceili(start.distance_to(at)/0.4))
	for i in range(1,steps+1):
		var p: Vector2=start.lerp(at,float(i)/steps)
		if not model.apply({"kind":"move","id":id,"x":p.x,"depth":p.y}):return false
	return true
static func solve_round(model: RefCounted) -> bool:
	match int(model.snapshot().round):
		0: if not move(model,"left_fan",Vector2(0,5)):return false
		1: if not move(model,"left_fan",Vector2(0,6)):return false
		2:
			if not move(model,"side_screen",Vector2(4.4,8)):return false
			if not move(model,"left_fan",Vector2(0,4)):return false
			if not move(model,"right_fan",Vector2(0,6)):return false
	return model.apply({"kind":"try"}) and model.snapshot().screen in ["round_complete","complete"]
static func proof(config: Dictionary={}) -> Dictionary:
	var model=Model.new()
	for round_id in 3:
		if not solve_round(model):return {}
		if round_id<2 and not model.apply({"kind":"continue"}):return {}
	return model.proof(config.get("session",{}))
