extends RefCounted
static var _cache: Dictionary={}
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
