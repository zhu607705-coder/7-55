extends RefCounted
## Reused input-only solver; callers disable fixture writing.
const Model=preload("res://scripts/games/canteen_defense_model.gd")
func solve(seed_value: String, existing: RefCounted=null, save_snapshots: bool=true) -> RefCounted:
	var run: RefCounted=existing if existing!=null else Model.new()
	if existing==null: run.configure(seed_value)
	var waypoints: Array[Vector2]=[]
	var snapshots: Array=[]
	for tick: int in range(3600):
		if run.status!="running": break
		var center: Vector2=run.player+Model.BODY_CENTER
		if tick%10==0 or waypoints.is_empty(): waypoints=plan(run,center,run.paper)
		while waypoints.size()>1 and center.distance_to(waypoints[0])<8: waypoints.pop_front()
		var target: Vector2=waypoints[0] if not waypoints.is_empty() else run.paper
		var direction: Vector2=(target-center).normalized() if center.distance_to(target)>3 else Vector2.ZERO
		var input: Dictionary={"x":direction.x,"y":direction.y,"dash":run.dash_cooldown<=0 and center.distance_to(target)>80}
		run.step(input)
		snapshots.append({"player":[run.player.x,run.player.y],"paper":[run.paper.x,run.paper.y],"angle":run.paper_angle,"exit":run.current_exit,"turnarounds":run.turnarounds,"route_index":run.route_index,"dash_remaining":run.dash_remaining,"dash_cooldown":run.dash_cooldown})
	if run.status!="won": print("BOT FAILED ",run.tick," ",run.player," ",run.paper," ",run.current_exit)
	elif save_snapshots:
		var file: FileAccess=FileAccess.open("res://tests/fixtures/canteen_defense_snapshots.json",FileAccess.WRITE)
		file.store_string(JSON.stringify(snapshots))
	return run

func visible(run: RefCounted,a: Vector2,b: Vector2) -> bool:
	var count: int=maxi(1,int(ceil(a.distance_to(b)/5)))
	for i: int in range(count+1):
		var body: Rect2=Rect2(a.lerp(b,float(i)/count)-Model.BODY_SIZE/2,Model.BODY_SIZE)
		if not Model.WORLD.encloses(body): return false
		for rect: Rect2 in run.colliders:
			if body.intersects(rect): return false
	return true

func plan(run: RefCounted,start: Vector2,target: Vector2) -> Array[Vector2]:
	if visible(run,start,target): return [target]
	var nodes: Array[Vector2]=[start,target]
	for y: float in [278.0,418.0,525.0,638.0]:
		for x: float in Model.GRID_X: nodes.append(Vector2(x,y))
	var distance: Array[float]=[]
	var previous: Array[int]=[]
	var visited: Dictionary={}
	for i: int in range(nodes.size()):
		distance.append(INF)
		previous.append(-1)
	distance[0]=0
	for loop: int in range(nodes.size()):
		var best: int=-1
		for i: int in range(nodes.size()):
			if not visited.has(i) and (best<0 or distance[i]<distance[best]): best=i
		if best<0 or distance[best]==INF: break
		if best==1: break
		visited[best]=true
		for next: int in range(nodes.size()):
			if visited.has(next): continue
			var trial: float=distance[best]+nodes[best].distance_to(nodes[next])
			if trial<distance[next] and visible(run,nodes[best],nodes[next]):
				distance[next]=trial
				previous[next]=best
	var path: Array[Vector2]=[]
	var cursor: int=1
	while cursor>0 and previous[cursor]>=0:
		path.push_front(nodes[cursor])
		cursor=previous[cursor]
	if path.is_empty(): path.append(start)
	return path
