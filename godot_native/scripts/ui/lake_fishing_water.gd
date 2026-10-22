extends RefCounted
## Bounded, read-only water events. The fishing model owns time and results.
const MAX_SPLASHES := 3
const MAX_DROPS := 4
var clock := 0.0
var splashes: Array[Dictionary] = []
var drops: Array[Dictionary] = []
var emitted := {"bite":0,"struggle":0,"retrieval":0,"catch":0}
var initialized := false
var previous_elapsed := 0.0
var previous_success := 0
var previous_phase := ""
var bitten := false
var thrust_cycle := -1
var drop_serial := 0

func reset() -> void:
	clock=0; splashes.clear(); drops.clear()
	emitted={"bite":0,"struggle":0,"retrieval":0,"catch":0}
	initialized=false; previous_elapsed=0; previous_success=0
	previous_phase=""; bitten=false; thrust_cycle=-1; drop_serial=0

func observe(delta: float, model: RefCounted, depth: Dictionary, motion: Dictionary, paused: bool, reduced: bool, origin: Vector2, safe: Rect2, exclusions: Array[Rect2]) -> void:
	if paused: return
	if initialized and model.elapsed<previous_elapsed-.001: reset()
	var success: int=int(depth.successful_notes)
	var cycle: int=int(floor(maxf(0,model.elapsed-model.cast_at-4*model.beat_sec)/(4*model.beat_sec)))
	if not initialized:
		initialized=true; previous_elapsed=model.elapsed; previous_success=success; previous_phase=model.phase
		bitten=model.stage=="fighting" or model.phase in ["completed","failed"]
		if model.stage=="fighting": thrust_cycle=cycle
		return # Attaching to an existing state must not replay historical events.
	clock+=maxf(0,delta); previous_elapsed=model.elapsed
	for index in range(splashes.size()-1,-1,-1):
		if reduced: splashes[index].still=true; splashes[index].duration=.42
		if clock-float(splashes[index].born)>=float(splashes[index].duration): splashes.remove_at(index)
	for index in range(drops.size()-1,-1,-1):
		if reduced or clock-float(drops[index].born)>=float(drops[index].duration) or not clear_path(drop_bounds(drops[index]),safe,exclusions): drops.remove_at(index)
	var failed: bool=model.phase=="failed" or (model.phase=="completed" and not bool(model.final_result.get("passed",false)))
	if failed:
		splashes.clear(); drops.clear(); previous_phase=model.phase; previous_success=success
		return
	if model.phase=="running":
		if not bitten and model.stage=="count_in" and float(depth.bite)>.12:
			bitten=true; _splash("bite",origin,.28,true)
		if model.stage=="fighting" and int(motion.beat)==1 and float(motion.fish_force)>.45 and cycle!=thrust_cycle:
			thrust_cycle=cycle
			# A submerged thrust cannot throw a large spray at the camera.
			var shallow: float=float(depth.surface_wake)
			if shallow>.20:
				_splash("struggle",origin,clampf(.35+shallow*.35+float(motion.stress)*.25,0,1),reduced)
		if success>previous_success and float(depth.progress)>=.70:
			_splash("retrieval",origin,.8,reduced)
			if not reduced: _camera_drops(safe,exclusions,2)
	elif model.phase=="completed" and previous_phase!="completed" and bool(model.final_result.get("passed",false)):
		_splash("catch",origin,1.0,reduced)
		if not reduced: _camera_drops(safe,exclusions,2)
	previous_success=success; previous_phase=model.phase

func _splash(kind: String, origin: Vector2, strength: float, still: bool) -> void:
	if splashes.size()>=MAX_SPLASHES: splashes.pop_front()
	splashes.append({"kind":kind,"origin":origin,"strength":strength,"still":still,"born":clock,"duration":.42 if still else .72})
	emitted[kind]=int(emitted[kind])+1

static func clear_path(bounds: Rect2, safe: Rect2, exclusions: Array[Rect2]) -> bool:
	if not safe.encloses(bounds): return false
	for rect: Rect2 in exclusions:
		if bounds.intersects(rect): return false
	return true

static func drop_bounds(drop: Dictionary) -> Rect2:
	var radius:=Vector2(float(drop.radius),float(drop.radius)*1.55)
	return Rect2(Vector2(drop.origin)-radius,2*radius+Vector2(0,float(drop.slide)))

func _camera_drops(safe: Rect2, exclusions: Array[Rect2], count: int) -> void:
	if safe.size.x<70 or safe.size.y<36: return
	var radius: float=clampf(safe.size.y*.065,6,13)
	var slide: float=minf(36,safe.size.y*.17)
	for index in range(count):
		var side: int=drop_serial%2; drop_serial+=1
		var x: float=safe.position.x+radius+5 if side==0 else safe.end.x-radius-5
		for fraction: float in [.08,.34,.57,.76]:
			var origin:=Vector2(x,safe.position.y+radius*1.55+4+safe.size.y*fraction)
			var drop: Dictionary={"origin":origin,"radius":radius,"slide":slide,"born":clock,"duration":1.12}
			if not clear_path(drop_bounds(drop),safe,exclusions): continue
			var overlap:=false
			for other: Dictionary in drops:
				if drop_bounds(drop).intersects(drop_bounds(other)): overlap=true; break
			if overlap: continue
			if drops.size()>=MAX_DROPS: drops.pop_front()
			drops.append(drop)
			break

func lens_samples() -> Array[Vector4]:
	var result: Array[Vector4]=[]
	for drop: Dictionary in drops:
		var age: float=clock-float(drop.born)
		var slide: float=smoothstep(.18,float(drop.duration),age)
		var point: Vector2=Vector2(drop.origin)+Vector2(0,float(drop.slide)*slide)
		var opacity: float=(1-smoothstep(.65,float(drop.duration),age))*minf(1,age/.045)
		result.append(Vector4(point.x,point.y,float(drop.radius),opacity))
	return result
