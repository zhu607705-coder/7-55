extends RefCounted
## Source ChapterFourGuardNavigation's 14px graph and expanded foot box.
var walls: Array=[]
var width: float=1672
var height: float=941
var columns: int=120
var rows: int=68
var open: PackedByteArray=PackedByteArray()
func setup(source_walls: Array,source_width: float=1672,source_height: float=941) -> void:
	walls=source_walls; width=source_width; height=source_height; columns=int(ceil(width/14)); rows=int(ceil(height/14)); open.resize(columns*rows)
	for id in range(open.size()): open[id]=1 if foot_open(point(id)) else 0
func point(id: int) -> Vector2: return Vector2((id%columns+0.5)*14,(floori(float(id)/columns)+0.5)*14)
func _rect(value: Variant) -> Rect2:
	if value is Rect2: return value
	if value is Array: return Rect2(value[0],value[1],value[2],value[3])
	return Rect2(value.x,value.y,value.width,value.height)
func foot_open(p: Vector2) -> bool:
	if p.x<12 or p.y<10 or p.x>width-12 or p.y>height-10: return false
	for item in walls:
		var r: Rect2=_rect(item)
		if p.x>r.position.x-10 and p.x<r.end.x+10 and p.y>r.position.y-7 and p.y<r.end.y+7: return false
	return true
func line(a: Vector2,b: Vector2) -> bool:
	var count: int=int(ceil(a.distance_to(b)/5))
	for i in range(count+1):
		if not foot_open(a.lerp(b,float(i)/count if count else 0.0)): return false
	return true
func nearest(p: Vector2) -> int:
	var best: int=-1; var distance: float=INF
	for id in range(open.size()):
		if not open[id]: continue
		var d: float=p.distance_to(point(id))
		if d<distance and line(p,point(id)): best=id; distance=d
	return best
func path(from: Vector2,to: Vector2) -> Array:
	if line(from,to): return [to]
	var start: int=nearest(from); var goal: int=nearest(to)
	if start<0 or goal<0: return []
	var costs: Dictionary={start:0.0}; var previous: Dictionary={}; var closed: Dictionary={}; var queue: Array=[start]
	while not queue.is_empty():
		var current: int=-1; var best: float=INF
		for id in queue:
			var priority: float=float(costs[id])+point(id).distance_to(point(goal))
			if priority<best: best=priority; current=id
		queue.erase(current)
		if current==goal:
			var ids: Array=[current]
			while previous.has(ids[0]): ids.push_front(previous[ids[0]])
			var out: Array=[]
			for id in ids: out.append(point(id))
			out.append(to)
			while out.size()>1 and line(from,out[1]): out.pop_front()
			return out
		if closed.has(current): continue
		closed[current]=true; var x: int=current%columns; var y: int=floori(float(current)/columns)
		for offset in [Vector2i.RIGHT,Vector2i.LEFT,Vector2i.UP,Vector2i.DOWN,Vector2i(1,1),Vector2i(1,-1),Vector2i(-1,1),Vector2i(-1,-1)]:
			var nx: int=x+offset.x; var ny: int=y+offset.y; var neighbor: int=ny*columns+nx
			if nx<0 or nx>=columns or ny<0 or ny>=rows or not open[neighbor] or closed.has(neighbor) or not line(point(current),point(neighbor)): continue
			var cost: float=float(costs[current])+Vector2(offset).length()*14
			if cost<float(costs.get(neighbor,INF)): costs[neighbor]=cost; previous[neighbor]=current; queue.append(neighbor)
	return []
