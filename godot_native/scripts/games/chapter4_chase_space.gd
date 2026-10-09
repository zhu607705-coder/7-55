extends RefCounted
## Candidate shared geometry for the approved independent chase space.
## Pure whitebox model only: no scene route, save, reward, or story writes.
const SOURCE_PATH := "res://data/native/chapter4-chase-space.json"
const PLAYER_BODY := Vector2(19.5, 14.625)
const GUARD_BODY := Vector2(20, 14)
const PLAYER_SPEED := 208.0
const GUARD_SPEED := 174.0
const TRACE_DISTANCE_TOLERANCE := 1.0
var layout: Dictionary = {}
var world := Rect2()
var floors: Array[Rect2] = []
var walls: Array[Rect2] = []
var obstacles: Array[Rect2] = []
var route: Array[Vector2] = []
var gates: Array[Rect2] = []
var exit := Rect2()
var navigation: Array[Vector2] = []
var adjacent: Array = []

func _init() -> void:
	layout = JSON.parse_string(FileAccess.get_file_as_string(SOURCE_PATH))
	world = Rect2(Vector2.ZERO, vec(layout.world_size))
	for value in layout.walkable:floors.append(rect(value))
	for value in layout.obstacles:obstacles.append(rect(value.rect))
	for value in layout.route:route.append(vec(value))
	for value in layout.gates:gates.append(rect(value))
	exit = rect(layout.exit)
	_build_walls()
	_build_navigation()

static func vec(value: Variant) -> Vector2:
	if value is Vector2:return value
	if value is Dictionary:return Vector2(float(value.x),float(value.y))
	return Vector2(float(value[0]),float(value[1]))

static func rect(value: Array) -> Rect2:
	return Rect2(float(value[0]),float(value[1]),float(value[2]),float(value[3]))

func floor_open(at: Vector2) -> bool:
	for floor_rect in floors:
		if floor_rect.has_point(at):return true
	return false

func _build_walls() -> void:
	var xs:Array=[0.0,world.end.x]
	var ys:Array=[0.0,world.end.y]
	for floor_rect in floors:
		for x in [floor_rect.position.x,floor_rect.end.x]:
			if not xs.has(x):xs.append(x)
		for y in [floor_rect.position.y,floor_rect.end.y]:
			if not ys.has(y):ys.append(y)
	xs.sort();ys.sort()
	for row in range(ys.size()-1):
		var start:=INF
		for col in range(xs.size()-1):
			var solid:=not floor_open(Vector2((xs[col]+xs[col+1])*.5,(ys[row]+ys[row+1])*.5))
			if solid and not is_finite(start):start=float(xs[col])
			if is_finite(start) and (not solid or col==xs.size()-2):
				var right:float=xs[col+1] if solid else xs[col]
				walls.append(Rect2(start,ys[row],right-start,ys[row+1]-ys[row]));start=INF
	walls.append_array(obstacles)

func body_open(at: Vector2, dimensions: Vector2=PLAYER_BODY) -> bool:
	if not at.is_finite() or not dimensions.is_finite() or dimensions.x<=0 or dimensions.y<=0:return false
	var body:=Rect2(at-dimensions*.5,dimensions)
	if not world.encloses(body):return false
	for wall in walls:
		if wall.grow(0.001).intersects(body):return false
	return true

static func _hits_rectangle(a: Vector2,b: Vector2,rectangle: Rect2) -> bool:
	var low:=0.0;var high:=1.0;var difference:=b-a
	for axis in 2:
		if absf(difference[axis])<0.000001:
			if a[axis]<rectangle.position[axis] or a[axis]>rectangle.end[axis]:return false
		else:
			var first:float=(rectangle.position[axis]-a[axis])/difference[axis]
			var second:float=(rectangle.end[axis]-a[axis])/difference[axis]
			low=maxf(low,minf(first,second));high=minf(high,maxf(first,second))
			if high<low:return false
	return true

func segment_open(a: Vector2,b: Vector2,dimensions: Vector2=PLAYER_BODY) -> bool:
	if not body_open(a,dimensions) or not body_open(b,dimensions):return false
	var half:=dimensions*.5
	for wall in walls:
		if _hits_rectangle(a,b,wall.grow_individual(half.x,half.y,half.x,half.y)):return false
	return true

func _add_navigation(point: Vector2) -> void:
	if body_open(point,GUARD_BODY) and not navigation.has(point):navigation.append(point)

func _build_navigation() -> void:
	for point in route:_add_navigation(point)
	# Clearance corners make the path solver useful for arbitrary legal player
	# positions, rather than only a scripted reference line through the obstacles.
	for obstacle in obstacles:
		var expanded:=obstacle.grow_individual(12,10,12,10)
		for corner in [expanded.position,Vector2(expanded.end.x,expanded.position.y),expanded.end,Vector2(expanded.position.x,expanded.end.y)]:_add_navigation(corner)
	for landing in layout.landings:_add_navigation(vec(landing.guard))
	for i in navigation.size():adjacent.append([])
	for i in navigation.size():
		for j in range(i+1,navigation.size()):
			if segment_open(navigation[i],navigation[j],GUARD_BODY):
				adjacent[i].append(j);adjacent[j].append(i)

func path(from: Vector2,to: Vector2) -> Array[Vector2]:
	# The player's width is 0.5 px narrower. Guard targets must not become
	# unreachable just because the player presses against a legal wall edge.
	if not body_open(to,GUARD_BODY) and body_open(to,PLAYER_BODY):
		var found:=false
		for radius in [1,2,4]:
			for direction in [Vector2.RIGHT,Vector2.LEFT,Vector2.DOWN,Vector2.UP,Vector2(1,1),Vector2(-1,1),Vector2(1,-1),Vector2(-1,-1)]:
				if body_open(to+direction*radius,GUARD_BODY):to+=direction*radius;found=true;break
			if found:break
	if not body_open(from,GUARD_BODY) or not body_open(to,GUARD_BODY):return []
	if segment_open(from,to,GUARD_BODY):return [to]
	var nodes:=navigation.duplicate();var edges:=adjacent.duplicate(true)
	var source:=nodes.size();nodes.append(from);edges.append([])
	var target:=nodes.size();nodes.append(to);edges.append([])
	for i in navigation.size():
		for endpoint in [source,target]:
			if segment_open(nodes[i],nodes[endpoint],GUARD_BODY):edges[i].append(endpoint);edges[endpoint].append(i)
	var distance:Array=[];var previous:Array=[];var open:Array=[]
	for i in nodes.size():distance.append(INF);previous.append(-1);open.append(i)
	distance[source]=0.0
	while not open.is_empty():
		var current:=-1
		for i in open:
			if current<0 or float(distance[i])<float(distance[current]):current=i
		if current<0 or not is_finite(float(distance[current])):break
		open.erase(current)
		if current==target:break
		for i in edges[current]:
			var cost:float=distance[current]+nodes[current].distance_to(nodes[i])
			if cost<float(distance[i]):distance[i]=cost;previous[i]=current
	if int(previous[target])<0:return []
	var result:Array[Vector2]=[];var cursor:=target
	while cursor!=source:
		if cursor<0:return []
		result.push_front(nodes[cursor]);cursor=previous[cursor]
	return result

func distance(from: Vector2,to: Vector2) -> float:
	var points:=path(from,to)
	if points.is_empty():return INF
	var total:=0.0;var last:=from
	for point in points:total+=last.distance_to(point);last=point
	return total

func guard_entry(landing:int,lead_distance:float=650.0) -> Dictionary:
	var entry:Dictionary=layout.landings[clampi(landing,0,2)]
	var player:=vec(entry.spawn);var guard:=vec(entry.guard)
	var lead:=clampf(lead_distance,650,2000) if is_finite(lead_distance) else 650.0
	var physical_distance:=distance(guard,player)
	return {"player":player,"guard":guard,"leadDistance":lead,"delayMs":maxf(0,lead-physical_distance)/GUARD_SPEED*1000}

func valid_trace(trace:Variant,start_landing:int,required_landing:int,exit_required:bool,elapsed_ms:float,accepted_prefix:Array=[]) -> bool:
	if not trace is Array or trace.is_empty() or trace.size()>20000 or not is_finite(elapsed_ms):return false
	if start_landing<0 or start_landing>2 or required_landing>2 or required_landing<-1:return false
	if required_landing>=0 and required_landing<start_landing:return false
	if trace.size()<accepted_prefix.size():return false
	for i in accepted_prefix.size():
		if trace[i]!=accepted_prefix[i]:return false
	var last:=vec(layout.landings[start_landing].spawn);var last_time:=0.0;var gate:=start_landing
	var distance_error:=0.0
	for record:Variant in trace:
		if not record is Dictionary:return false
		for key in ["x","y","t"]:
			if typeof(record.get(key)) not in [TYPE_INT,TYPE_FLOAT]:return false
		var point:=Vector2(float(record.x),float(record.y));var time:=float(record.t);var dt:=time-last_time
		if not point.is_finite() or not is_finite(time) or dt<=0 or dt>250:return false
		# One rounding budget belongs to the complete trace, never to each sample.
		# Waiting cannot refill it. Dense tiny-dt samples must not buy extra travel.
		distance_error+=maxf(0,last.distance_to(point)-PLAYER_SPEED*dt/1000.0)
		if distance_error>TRACE_DISTANCE_TOLERANCE or not segment_open(last,point):return false
		if gate<2 and gates[gate].has_point(point):gate+=1
		last=point;last_time=time
	if elapsed_ms<last_time:return false
	if required_landing<0:return true
	if gate!=required_landing:return false
	return (gate==2 and exit.has_point(last)) if exit_required else (required_landing>start_landing and gates[required_landing-1].has_point(last))
