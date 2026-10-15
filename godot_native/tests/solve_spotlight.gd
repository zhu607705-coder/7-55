extends SceneTree
const Model=preload("res://scripts/games/c3_spotlight_model.gd")
func _initialize() -> void:
	var rules: RefCounted=Model.new()
	for round_id: int in range(3):
		var success: bool=false
		for attempt: int in range(30):
			var s: Dictionary=rules.create(round_id,attempt)
			var trace: Array=[]
			while s.status=="running":
				var aim: Vector2=rules.mouth(s)
				var distance: float=100000.0
				for i: int in range(int(Model.ACTS[round_id].count)):
					if not s.collected.has(i) and s.head.distance_to(Model.FOOD[i])<distance:
						distance=s.head.distance_to(Model.FOOD[i]); aim=Model.FOOD[i]
				var direction: Vector2=(aim-s.head).normalized()
				var dash: bool=false
				for hazard: Dictionary in rules.hazards(s):
					if s.head.distance_to(hazard.position)<100 and s.invulnerable==0:
						if s.dashCooldown<=1: dash=true
						elif s.dashTicks==0 and s.head.distance_to(hazard.position)<65:
							var away: Vector2=(s.head-hazard.position).normalized()
							direction=(direction+away*1.6).normalized()
				var input: Dictionary={"x":direction.x,"y":direction.y,"dash":dash}
				trace.append(input)
				s=rules.step(s,input)
			if s.status=="won":
				var proof: Dictionary={"version":2,"round":round_id,"attempt":attempt,"inputs":trace}
				var verified: Dictionary=rules.validate(proof,round_id,attempt)
				assert(verified.status=="won")
				var file: FileAccess=FileAccess.open("res://tests/fixtures/spotlight_"+str(round_id)+".json",FileAccess.WRITE)
				file.store_string(JSON.stringify(proof))
				print("Spotlight ",round_id," solved ticks=",s.tick," attempt=",attempt)
				success=true
				break
		assert(success)
	quit()
