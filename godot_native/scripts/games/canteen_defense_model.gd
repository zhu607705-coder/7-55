extends RefCounted
## CanteenDefenseRuntime.ts: source-pixel simulation and replay proof.
const HZ: int=60
const DT: float=1.0/60.0
const DURATION: float=60000.0
const GRID_X=[126,301,450,600,753,908,1064,1225]
const GRID_Y=[278,414,520,628]
const EXITS={"northwest":Vector2(82,250),"south_gap":Vector2(500,914),"southeast":Vector2(1380,852)}
const GATEWAYS={"northwest":[Vector2(126,278),Vector2(82,250)],"south_gap":[Vector2(450,628),Vector2(500,650),Vector2(500,914)],"southeast":[Vector2(1225,628),Vector2(1225,820),Vector2(1380,820),Vector2(1380,852)]}
# Source shared 96x128 actor, scale .65, origin .5; offset(33,101.5), size(30,22.5).
const BODY_OFFSET=Vector2(-9.75,24.375)
const BODY_SIZE=Vector2(19.5,14.625)
const BODY_CENTER=Vector2(0,31.6875)
const WORLD=Rect2(28,16,1616,907)
var seed_text: String=""
var status: String="running"
var tick: int=0
var elapsed_ms: float=0
var player: Vector2=Vector2(908,628)
var paper: Vector2=Vector2(836,520)
var velocity: Vector2=Vector2.ZERO
var facing: Vector2=Vector2(0,-1)
var paper_angle: float=0
var paper_flip: bool=false
var current_exit: String="northwest"
var route: Array[Vector2]=[]
var route_index: int=0
var dash_remaining: float=0
var dash_cooldown: float=0
var paper_hit_cooldown: float=500
var paper_frame_ms: float=0
var paper_frame: int=0
var push_frame_ms: float=0
var push_frame: int=0
var turnarounds: int=0
var route_flash: float=0
var failure_exit: String=""
var inputs: Array=[]
var prior_attempts: Array=[]
var graph: Array=[]
var colliders: Array[Rect2]=[]
# Phaser RandomDataGenerator (Alea), MIT, Phaser Studio Inc. Algorithm parity.
var rng_n: float=4022871197.0
var rng_s0: float=0
var rng_s1: float=0
var rng_s2: float=0
var rng_c: int=1

func configure(seed_value: String) -> void:
	seed_text=seed_value
	var data: Variant=JSON.parse_string(FileAccess.get_file_as_string("res://data/worlds.json"))
	for rect: Dictionary in data.worlds.canteen_interior.collisions:
		colliders.append(Rect2(rect.left,rect.top,rect.right-rect.left,rect.bottom-rect.top))
	for row: int in range(4):
		for column: int in range(8):
			var links: Array[int]=[]
			if column>0: links.append(row*8+column-1)
			if column<7: links.append(row*8+column+1)
			if row>0: links.append((row-1)*8+column)
			if row<3: links.append((row+1)*8+column)
			graph.append({"point":Vector2(GRID_X[column],GRID_Y[row]),"links":links})
	rng_s0=seed_hash(" ")
	rng_s1=seed_hash(" ")
	rng_s2=seed_hash(" ")
	rng_s0-=seed_hash(seed_value)
	if rng_s0<0: rng_s0+=1
	rng_s1-=seed_hash(seed_value)
	if rng_s1<0: rng_s1+=1
	rng_s2-=seed_hash(seed_value)
	if rng_s2<0: rng_s2+=1
	current_exit=pick_exit("")
	rebuild_route()

func restart_attempt(record: bool=true) -> void:
	if record and not inputs.is_empty(): prior_attempts.append(inputs.duplicate(true))
	status="running"
	tick=0
	elapsed_ms=0
	player=Vector2(908,628)
	paper=Vector2(836,520)
	velocity=Vector2.ZERO
	facing=Vector2(0,-1)
	paper_angle=0
	paper_flip=false
	dash_remaining=0
	dash_cooldown=0
	paper_hit_cooldown=500
	paper_frame_ms=0
	paper_frame=0
	push_frame_ms=0
	push_frame=0
	turnarounds=0
	route_flash=0
	failure_exit=""
	inputs.clear()
	current_exit=pick_exit("")
	rebuild_route()

func seed_hash(value: String) -> float:
	var n: float=rng_n
	for i: int in range(value.length()):
		n+=value.unicode_at(i)
		var h: float=0.02519603282416938*n
		n=float(int(h)&0xffffffff)
		h-=n
		h*=n
		n=float(int(h)&0xffffffff)
		h-=n
		n+=h*4294967296.0
	rng_n=n
	return float(int(n)&0xffffffff)*2.3283064365386963e-10

func random_value() -> float:
	var t: float=2091639*rng_s0+rng_c*2.3283064365386963e-10
	rng_c=int(t)
	rng_s0=rng_s1
	rng_s1=rng_s2
	rng_s2=t-rng_c
	return rng_s2

func pick_exit(exclude: String) -> String:
	var options: Array[String]=[]
	for id: String in ["northwest","south_gap","southeast"]:
		if id!=exclude: options.append(id)
	var first: float=random_value()
	var fraction: float=first+int(random_value()*2097152)*1.1102230246251565e-16
	return options[mini(options.size()-1,int(floor(fraction*options.size())))]

func body_at(at: Vector2) -> Rect2: return Rect2(at+BODY_OFFSET,BODY_SIZE)

func move_player() -> void:
	var proposed: Vector2=player
	# Deterministic axis separation against the unchanged authored solids.
	proposed.x+=velocity.x*DT
	var body: Rect2=body_at(proposed)
	body.position.x=clampf(body.position.x,WORLD.position.x,WORLD.end.x-body.size.x)
	proposed.x=body.position.x-BODY_OFFSET.x
	for rect: Rect2 in colliders:
		if body.intersects(rect):
			if velocity.x>0: proposed.x=rect.position.x-BODY_SIZE.x-BODY_OFFSET.x
			elif velocity.x<0: proposed.x=rect.end.x-BODY_OFFSET.x
			body=body_at(proposed)
	proposed.y+=velocity.y*DT
	body=body_at(proposed)
	body.position.y=clampf(body.position.y,WORLD.position.y,WORLD.end.y-body.size.y)
	proposed.y=body.position.y-BODY_OFFSET.y
	for rect: Rect2 in colliders:
		if body.intersects(rect):
			if velocity.y>0: proposed.y=rect.position.y-BODY_SIZE.y-BODY_OFFSET.y
			elif velocity.y<0: proposed.y=rect.end.y-BODY_OFFSET.y
			body=body_at(proposed)
	player=proposed

func step(input: Dictionary, record: bool=true) -> void:
	if status!="running": return
	if record: inputs.append({"x":float(input.get("x",0)),"y":float(input.get("y",0)),"dash":bool(input.get("dash",false))})
	# Arcade integrates the previous update's velocity before scene.update.
	move_player()
	tick+=1
	elapsed_ms=minf(DURATION,tick*1000.0/HZ)
	dash_remaining=maxf(0,dash_remaining-1000.0/HZ)
	dash_cooldown=maxf(0,dash_cooldown-1000.0/HZ)
	paper_hit_cooldown=maxf(0,paper_hit_cooldown-1000.0/HZ)
	route_flash=maxf(0,route_flash-1000.0/HZ)
	var direction: Vector2=Vector2(input.get("x",0),input.get("y",0))
	if input.get("dash",false) and dash_cooldown<=0 and direction.length_squared()>0:
		dash_remaining=430
		dash_cooldown=1650
	velocity=direction.normalized()*(264 if dash_remaining>0 else 154)
	if direction.length_squared()>0:
		facing=direction.normalized()
		push_frame_ms+=1000.0/HZ
		var duration: float=72 if dash_remaining>0 else 104
		if push_frame_ms>=duration:
			push_frame_ms=fmod(push_frame_ms,duration)
			push_frame=(push_frame+1)%4
	else:
		push_frame_ms=0
		push_frame=0
	update_paper()
	if elapsed_ms>=DURATION and status=="running":
		status="won"
		velocity=Vector2.ZERO

func update_paper() -> void:
	if route_index>=route.size():
		fail_run()
		return
	var target: Vector2=route[route_index]
	var to_target: Vector2=target-paper
	var distance: float=to_target.length()
	var progress: float=elapsed_ms/DURATION
	var speed: float=lerpf(78,118,progress)
	paper_frame_ms+=1000.0/HZ
	var duration: float=lerpf(112,82,progress)
	if paper_frame_ms>=duration:
		paper_frame_ms=fmod(paper_frame_ms,duration)
		paper_frame=(paper_frame+1)%4
	var advance: float=speed*DT
	if distance<=advance:
		paper=target
		route_index+=1
	elif distance>0:
		to_target*=advance/distance
		paper+=to_target
		paper_flip=to_target.x<0
		paper_angle=clampf(to_target.y/advance*9,-9,9)
	var body: Rect2=body_at(player)
	var angle: float=deg_to_rad(paper_angle)
	var paper_size: Vector2=Vector2(absf(cos(angle))*64+absf(sin(angle))*50,absf(sin(angle))*64+absf(cos(angle))*50)*1.16
	var bounds: Rect2=Rect2(paper-paper_size/2,paper_size)
	if bounds.intersects(body,true) and paper_hit_cooldown<=0:
		paper_hit_cooldown=720
		var away: Vector2=paper-body.get_center()
		if away.length_squared()==0: away=-facing
		paper+=away.normalized()*34
		current_exit=pick_exit(current_exit)
		rebuild_route()
		turnarounds+=1
		route_flash=760
		return
	if route_index>=route.size() or paper.distance_to(EXITS[current_exit])<=24: fail_run()

func fail_run() -> void:
	status="lost"
	failure_exit=current_exit
	velocity=Vector2.ZERO

func nearest_node(at: Vector2) -> int:
	var nearest: int=0
	var distance: float=INF
	for i: int in range(graph.size()):
		var candidate: float=at.distance_squared_to(graph[i].point)
		if candidate<distance:
			nearest=i
			distance=candidate
	return nearest

func node_path(start: int, end: int) -> Array[int]:
	var queue: Array[int]=[start]
	var previous: Dictionary={start:-1}
	while not queue.is_empty():
		var id: int=queue.pop_front()
		if id==end: break
		for next: int in graph[id].links:
			if previous.has(next): continue
			previous[next]=id
			queue.append(next)
	var path: Array[int]=[]
	var cursor: int=end
	while cursor>=0:
		path.push_front(cursor)
		cursor=int(previous.get(cursor,-1))
	return path if not path.is_empty() else [start]

func rebuild_route() -> void:
	route.clear()
	var gateways: Array=GATEWAYS[current_exit]
	for id: int in node_path(nearest_node(paper),nearest_node(gateways[0])): route.append(graph[id].point)
	for i: int in range(1,gateways.size()): route.append(gateways[i])
	route_index=0
	while route_index<route.size()-1 and paper.distance_to(route[route_index])<12: route_index+=1

func result() -> Dictionary:
	return {"protocol":"canteen-defense-v1","seed":seed_text,"success":status=="won","elapsed_ms":elapsed_ms,"ticks":tick,"turnarounds":turnarounds,"inputs":inputs.duplicate(true),"attempts":prior_attempts.duplicate(true),"paper":[paper.x,paper.y],"player":[player.x,player.y],"exit":current_exit}

static func validate_result(value: Dictionary, expected_seed: String) -> bool:
	if value.get("protocol")!="canteen-defense-v1" or value.get("seed")!=expected_seed or value.get("success")!=true or value.get("elapsed_ms")!=60000 or value.get("ticks")!=3600: return false
	if not value.get("inputs") is Array or value.inputs.size()!=3600: return false
	var replay: RefCounted=load("res://scripts/games/canteen_defense_model.gd").new()
	replay.configure(expected_seed)
	var attempts: Variant=value.get("attempts",[])
	if not attempts is Array or attempts.size()>64: return false
	for attempt: Variant in attempts:
		if not attempt is Array or attempt.is_empty() or attempt.size()>3600: return false
		if not replay_inputs(replay,attempt) or replay.status!="lost": return false
		replay.restart_attempt(false)
	if not replay_inputs(replay,value.inputs): return false
	return replay.status=="won" and replay.turnarounds==value.get("turnarounds") and replay.current_exit==value.get("exit")

static func replay_inputs(replay: RefCounted, trace: Array) -> bool:
	for input: Variant in trace:
		if not input is Dictionary or not input.get("dash") is bool: return false
		for axis: String in ["x","y"]:
			if not (input.get(axis) is int or input.get(axis) is float) or not is_finite(float(input[axis])) or absf(float(input[axis]))>1: return false
		if replay.status!="running": return false
		replay.step(input,false)
	return true
