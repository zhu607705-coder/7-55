extends RefCounted
const PlayerMetrics=preload("res://scripts/player_metrics.gd")
static var _cache: Dictionary={}
static var _blocked_cache:Array=[]
static func data() -> Dictionary:
	if _cache.is_empty(): _cache=JSON.parse_string(FileAccess.get_file_as_string("res://data/native/chapter4-native-source.json")).stair
	return _cache
static func point(value: Dictionary) -> Vector2: return Vector2(value.x,value.y)
static func inside(p: Vector2,r: Dictionary) -> bool: return p.x>=float(r.x) and p.x<=float(r.x)+float(r.width) and p.y>=float(r.y) and p.y<=float(r.y)+float(r.height)
static func walkable(p: Vector2) -> bool:
	for r in data().walkable:
		if inside(p,r): return true
	return false
static func foot_open(p: Vector2,half_width: float=10,half_height: float=7) -> bool:
	for x in [-half_width,0,half_width]:
		for y in [-half_height,0,half_height]:
			if not walkable(p+Vector2(x,y)): return false
	return true
static func line_open(a: Vector2,b: Vector2) -> bool:
	var steps: int=maxi(1,int(ceil(a.distance_to(b)/6)))
	for i in range(steps+1):
		if not foot_open(a.lerp(b,float(i)/steps)): return false
	return true
static func _anchor(p: Vector2) -> Vector2:
	if foot_open(p): return p
	for radius in [1,2,4]:
		for direction in [Vector2.RIGHT,Vector2.LEFT,Vector2.DOWN,Vector2.UP,Vector2(1,1),Vector2(-1,1),Vector2(1,-1),Vector2(-1,-1)]:
			if foot_open(p+direction*radius): return p+direction*radius
	return p
static func path(from: Vector2,to: Vector2) -> Array:
	from=_anchor(from); to=_anchor(to)
	if line_open(from,to): return [to]
	var nodes: Array=[]
	for p in data().route: nodes.append(point(p))
	var count: int=nodes.size(); nodes.append(from); nodes.append(to); var source: int=nodes.size()-2; var target: int=nodes.size()-1
	var adjacent: Array=[]; var distance: Array=[]; var previous: Array=[]; var open: Array=[]
	for i in range(nodes.size()): adjacent.append([]); distance.append(INF); previous.append(-1); open.append(i)
	for edge in data().edges:
		var a: int=int(edge[0]); var b: int=int(edge[1])
		if line_open(nodes[a],nodes[b]): adjacent[a].append(b); adjacent[b].append(a)
	for i in range(count):
		for end in [source,target]:
			if line_open(nodes[i],nodes[end]): adjacent[i].append(end); adjacent[end].append(i)
	distance[source]=0.0
	while not open.is_empty():
		var current: int=-1
		for id in open:
			if current<0 or float(distance[id])<float(distance[current]): current=id
		if current<0 or not is_finite(float(distance[current])): break
		open.erase(current)
		if current==target: break
		for id in adjacent[current]:
			var cost: float=float(distance[current])+Vector2(nodes[current]).distance_to(nodes[id])
			if cost<float(distance[id]): distance[id]=cost; previous[id]=current
	if int(previous[target])<0: return []
	var result: Array=[]; var cursor: int=target
	while cursor!=source:
		if cursor<0: return []
		result.push_front(nodes[cursor]); cursor=previous[cursor]
	return result
static func distance(from: Vector2,to: Vector2) -> float:
	var route: Array=path(from,to); var total: float=0; var last: Vector2=from
	for p in route: total+=last.distance_to(p); last=p
	return total if not route.is_empty() else 120.0

## Source chaseStairBlockedRects: exact rectangle-complement decomposition.
## Navigation's source nine-point guard test above remains unchanged.
static func blocked_rects()->Array:
	if not _blocked_cache.is_empty():return _blocked_cache
	var xs:Array=[0.0,1672.0];var ys:Array=[0.0,941.0]
	for r:Dictionary in data().walkable:
		for x:float in [float(r.x),float(r.x)+float(r.width)]:
			if not xs.has(x):xs.append(x)
		for y:float in [float(r.y),float(r.y)+float(r.height)]:
			if not ys.has(y):ys.append(y)
	xs.sort();ys.sort()
	for row:int in range(ys.size()-1):
		var start:=INF
		for col:int in range(xs.size()-1):
			var solid:=not walkable(Vector2((xs[col]+xs[col+1])/2,(ys[row]+ys[row+1])/2))
			if solid and not is_finite(start):start=xs[col]
			if is_finite(start) and (not solid or col==xs.size()-2):
				var right:float=xs[col+1] if solid else xs[col]
				_blocked_cache.append(Rect2(start,ys[row],right-start,ys[row+1]-ys[row]));start=INF
	return _blocked_cache

static func body_open(at:Vector2,dimensions:Vector2)->bool:
	if not at.is_finite() or not dimensions.is_finite() or dimensions.x<=0 or dimensions.y<=0:return false
	var body:=Rect2(at-dimensions/2,dimensions)
	if not Rect2(0,0,1672,941).encloses(body):return false
	for obstacle:Rect2 in blocked_rects():
		if obstacle.intersects(body):return false
	return true

static func player_open(at:Vector2)->bool:
	return body_open(at,PlayerMetrics.FOOT_SIZE)

static func guard_entry(landing:int,lead_distance:float=650.0)->Dictionary:
	var entry:Dictionary=data().landings[clampi(landing,0,2)]
	var spawn:=point(entry.spawn);var guard:=point(entry.guard)
	var lead:=clampf(lead_distance,650,2000) if is_finite(lead_distance) else 650.0
	var local_distance:=spawn.distance_to(guard)
	if lead<local_distance:guard=spawn.lerp(guard,lead/local_distance)
	return {"player":spawn,"guard":guard,"leadDistance":lead,"delayMs":maxf(0,(lead-local_distance)/174.0*1000.0)}

static func exit_lead(guard:Vector2,player:Vector2,remaining_delay_ms:float)->float:
	return distance(guard,player)+maxf(0,remaining_delay_ms)*174.0/1000.0

## Native session proof retained for partial commits and source reload spawns.
## A short resumed segment need not have ten samples; every step still proves
## positive bounded time, source speed, full-body legality and required gates.
static func valid_trace(path:Variant,start_landing:int,required_landing:int,exit_required:bool,elapsed_ms:float,accepted_prefix:Array=[])->bool:
	if not path is Array or path.is_empty() or path.size()>20000 or not is_finite(elapsed_ms):return false
	if start_landing<0 or start_landing>2 or required_landing>2:return false
	if required_landing>=0 and required_landing<start_landing:return false
	if path.size()<accepted_prefix.size():return false
	for i:int in accepted_prefix.size():
		if path[i]!=accepted_prefix[i]:return false
	var last:=point(data().landings[start_landing].spawn);var last_time:=0.0;var gate:=start_landing
	for record:Variant in path:
		if not record is Dictionary:return false
		for key:String in ["x","y","t"]:
			if typeof(record.get(key)) not in [TYPE_INT,TYPE_FLOAT]:return false
		var next:=Vector2(float(record.get("x",INF)),float(record.get("y",INF)))
		var time:=float(record.get("t",-1));var dt:=time-last_time
		if not next.is_finite() or not is_finite(time) or dt<=0 or dt>250 or last.distance_to(next)>208.0*dt/1000.0+1.0:return false
		if not player_open(next):return false
		if gate<2 and inside(next,data().gates[gate]):gate+=1
		last=next;last_time=time
	if elapsed_ms<last_time:return false
	if required_landing<0:return true
	if gate!=required_landing:return false
	if exit_required:return gate==2 and inside(last,data().exit)
	return required_landing>start_landing and inside(last,data().gates[required_landing-1])
