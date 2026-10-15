extends RefCounted
## Pure native equivalents of ChapterFourGuardModel / ChapterFourFinalChaseModel.
## Returned velocities are intentions. World must apply its exact foot collisions;
## feed the real physics position back on every next step. This model owns no save.
const EPS: float=0.0000001
static var _cache: Dictionary={}
static func data() -> Dictionary:
	if _cache.is_empty(): _cache=JSON.parse_string(FileAccess.get_file_as_string("res://data/native/chapter4-native-source.json")).guard
	return _cache
static func vec(p: Variant) -> Vector2:
	return p if p is Vector2 else Vector2(float(p.x),float(p.y))
static func rect(r: Variant) -> Rect2:
	if r is Rect2: return r
	if r is Array: return Rect2(r[0],r[1],r[2],r[3])
	return Rect2(r.x,r.y,r.width,r.height)
static func line_of_sight(from: Vector2,to: Vector2,walls: Array) -> bool:
	for wall in walls:
		var r: Rect2=rect(wall)
		if r.size.x<=0 or r.size.y<=0: continue
		if r.has_point(from) or r.has_point(to): return false
		var change: Vector2=to-from; var min_t: float=0; var max_t: float=1; var outside: bool=false
		for axis in range(2):
			var start: float=from[axis]; var delta: float=change[axis]; var low: float=r.position[axis]; var high: float=r.end[axis]
			if absf(delta)<=EPS:
				if start<low or start>high: outside=true; break
				continue
			var a: float=(low-start)/delta; var b: float=(high-start)/delta
			min_t=maxf(min_t,minf(a,b)); max_t=minf(max_t,maxf(a,b))
			if min_t-max_t>EPS: outside=true; break
		if outside: continue
		for t in [min_t,(min_t+max_t)/2,max_t,minf(max_t,min_t+EPS)]:
			if r.has_point(from+change*t): return false
	return true
static func can_see(state: Dictionary,player: Vector2,walls: Array) -> bool:
	var position: Vector2=vec(state.position)
	if not line_of_sight(position,player,walls): return false
	var offset: Vector2=player-position; var distance: float=offset.length()
	if distance<=56: return true
	if distance>220 or distance<=EPS: return false
	var heading: Vector2=vec(state.heading)
	return heading.length()>EPS and offset.normalized().dot(heading.normalized())+EPS>=cos(deg_to_rad(36.0))
static func maintenance_state(seed: int=0x7552245,recovery: bool=false) -> Dictionary:
	var out: Dictionary={"mode":"patrol","position":Vector2(1105,560),"heading":Vector2.LEFT,"previousWaypointId":"east_south","targetWaypointId":"west_south","pauseRemainingMs":0.0,"visibleForMs":0.0,"sightLostForMs":0.0,"lastVisiblePosition":null,"rngState":maxi(1,seed&0xffffffff)}
	if recovery: out.position=Vector2(588,220); out.heading=(Vector2(1001,240)-out.position).normalized(); out.previousWaypointId="west_north"; out.targetWaypointId="stair_north"
	return out
static func _move(state: Dictionary,target: Vector2,speed: float,ms: float) -> void:
	var offset: Vector2=target-vec(state.position)
	if offset.length()<=EPS: state.position=target; return
	state.heading=offset.normalized(); state.position=vec(state.position)+vec(state.heading)*minf(offset.length(),speed*ms/1000)
static func _random(state: Dictionary) -> float:
	state.rngState=(int(state.rngState)*1664525+1013904223)&0xffffffff
	return float(state.rngState)/4294967296.0
static func _nearest_visible(position: Vector2,walls: Array,points: Dictionary) -> String:
	var nearest: String="east_south"; var distance: float=INF; var best_visible: bool=false
	for id in points:
		var p: Vector2=vec(points[id]); var visible: bool=line_of_sight(position,p,walls); var d: float=position.distance_to(p)
		if (visible and not best_visible) or visible==best_visible and d<distance: nearest=id; distance=d; best_visible=visible
	return nearest
static func _patrol(state: Dictionary,ms: float,points: Dictionary,walls: Array,returning: bool=false) -> void:
	if not returning and float(state.pauseRemainingMs)>0: state.pauseRemainingMs=maxf(0,float(state.pauseRemainingMs)-ms); return
	var target: Dictionary=points[state.targetWaypointId]
	if returning and not line_of_sight(vec(state.position),vec(target),walls): state.targetWaypointId=_nearest_visible(vec(state.position),walls,points); return
	_move(state,vec(target),96 if returning else 84,ms)
	if vec(state.position).distance_to(vec(target))>EPS: return
	var value: float=_random(state); var candidates: Array=[]
	for id in target.neighborIds:
		if returning or id!=state.previousWaypointId: candidates.append(id)
	if candidates.is_empty(): candidates=target.neighborIds
	state.previousWaypointId=target.id; state.targetWaypointId=candidates[mini(candidates.size()-1,int(floor(value*candidates.size())))]; state.pauseRemainingMs=round(1000+value*1000)
	if returning: state.mode="patrol"; state.visibleForMs=0; state.sightLostForMs=0
static func maintenance_step(source: Dictionary,delta_ms: float,guard_position: Vector2,player_position: Vector2,walls: Array) -> Dictionary:
	var state: Dictionary=source.duplicate(true); state.position=guard_position
	var remaining: float=maxf(0,delta_ms) if is_finite(delta_ms) else 0.0; var total: float=remaining
	var visible: bool=can_see(state,player_position,walls); var entered: bool=false; var disengaged: bool=false
	var points: Dictionary=data().patrol
	while remaining>0:
		var step: float=minf(50,remaining); remaining-=step; visible=can_see(state,player_position,walls)
		if state.mode in ["patrol","returning"]:
			if visible: state.mode="confirming"; state.visibleForMs=step; state.sightLostForMs=0; state.lastVisiblePosition=player_position; state.pauseRemainingMs=0
			else: _patrol(state,step,points,walls,state.mode=="returning")
		elif state.mode=="confirming":
			if not visible: state.mode="patrol"; state.visibleForMs=0; state.sightLostForMs=0; state.lastVisiblePosition=null
			else:
				state.visibleForMs=float(state.visibleForMs)+step; state.lastVisiblePosition=player_position; state.heading=(player_position-vec(state.position)).normalized()
				if float(state.visibleForMs)+EPS>=400: state.mode="pursuit"; state.visibleForMs=400; state.sightLostForMs=0; entered=true
		else:
			if visible: state.sightLostForMs=0; state.lastVisiblePosition=player_position
			else: state.sightLostForMs=float(state.sightLostForMs)+step
			if state.lastVisiblePosition!=null: _move(state,player_position if visible else vec(state.lastVisiblePosition),140,step)
			if float(state.sightLostForMs)+EPS>=900: state.mode="returning"; state.targetWaypointId=_nearest_visible(vec(state.position),walls,points); state.previousWaypointId=null; state.visibleForMs=0; state.sightLostForMs=0; state.pauseRemainingMs=0; disengaged=true
	return {"state":state,"desiredVelocity":(vec(state.position)-guard_position)*1000/total if total>0 else Vector2.ZERO,"playerVisible":visible,"enteredPursuit":entered,"disengaged":disengaged}
static func maintenance_contact(guard: Vector2,player_bounds: Rect2) -> bool:
	return Rect2(guard-Vector2(10,8),Vector2(20,16)).intersects(player_bounds)
static func chase_state(attempt: int) -> Dictionary:
	return {"phase":"arming","attempt":maxi(0,attempt),"stableCommittedFrames":0,"floor":"A1","guardFloor":"A1","guardTargetWaypointId":"a1_chase_start","portalApplied":false,"portalRemainingDistance":0.0,"finishRequestIssued":false,"failureRequestIssued":false,"elapsedMs":0.0}
static func _waypoints() -> Dictionary:
	var out: Dictionary={}
	for w in data().chaseWaypoints: out[w.id]=w
	return out
static func _nearest(floor: String,p: Vector2,points: Dictionary) -> String:
	var result: String=""; var best: float=INF
	for id in points:
		if points[id].floor!=floor: continue
		var distance: float=p.distance_to(vec(points[id]))
		if distance<best: result=id; best=distance
	return result
static func _shortest(from: String,to: String,points: Dictionary) -> Array:
	if from==to or points[from].floor!=points[to].floor: return [from]
	var open: Array=[]; var distance: Dictionary={from:0.0}; var previous: Dictionary={}
	for id in points:
		if points[id].floor==points[from].floor: open.append(id)
	while not open.is_empty():
		var current: String=""; var best: float=INF
		for id in open:
			if float(distance.get(id,INF))<best: current=id; best=distance[id]
		if current.is_empty(): break
		open.erase(current)
		if current==to: break
		for neighbor in points[current].neighborIds:
			if neighbor not in open: continue
			var cost: float=best+vec(points[current]).distance_to(vec(points[neighbor]))
			if cost<float(distance.get(neighbor,INF)): distance[neighbor]=cost; previous[neighbor]=current
	if not distance.has(to): return [from]
	var path: Array=[to]; var cursor: String=to
	while cursor!=from:
		if not previous.has(cursor): return [from]
		cursor=previous[cursor]; path.push_front(cursor)
	return path
static func _distance(floor: String,p: Vector2,target: String,points: Dictionary) -> float:
	var nearest: String=_nearest(floor,p,points); var path: Array=_shortest(nearest,target,points); var total: float=p.distance_to(vec(points[nearest]))
	for i in range(1,path.size()): total+=vec(points[path[i-1]]).distance_to(vec(points[path[i]]))
	return total
static func _remaining(floor: String,p: Vector2,points: Dictionary) -> float:
	return _distance("A1",p,"a1_main_stair",points)+_distance("A2",Vector2(966,214),"a2_room202_finish",points) if floor=="A1" else _distance("A2",p,"a2_room202_finish",points)
static func _result(state: Dictionary,velocity: Vector2=Vector2.ZERO,visible: bool=false,portal: bool=false,finish: bool=false,failure: bool=false,arrival: bool=false,distance: float=0) -> Dictionary:
	return {"state":state,"desiredGuardVelocity":velocity,"guardVisible":visible,"portalRequested":portal,"finishRequested":finish,"failureRequested":failure,"guardPortalArrival":arrival,"remainingRouteDistance":distance}
static func chase_step(source: Dictionary,input: Dictionary) -> Dictionary:
	var raw_ms: float=float(input.get("deltaMs",0)); var ms: float=clampf(raw_ms,0,1000) if is_finite(raw_ms) else 0.0; var state: Dictionary=source.duplicate(true); state.elapsedMs=float(state.elapsedMs)+ms
	var floor: String=input.floor; var player: Vector2=vec(input.playerPosition); var guard: Vector2=vec(input.guardPosition); var points: Dictionary=_waypoints()
	if source.phase in ["complete","finish_pending","failure_pending"]: return _result(state)
	if source.phase=="arming":
		state.stableCommittedFrames=mini(4,int(source.stableCommittedFrames)+1) if input.get("committedAndApplied",false) else 0
		var armed: bool=state.stableCommittedFrames>=4 and float(state.elapsedMs)>=2000
		state.phase="running" if armed else "arming"; return _result(state,Vector2.ZERO,armed,false,false,false,false,_remaining(floor,player,points))
	var finished_before: bool=bool(source.finishRequestIssued) if input.get("playerInsideFinish",false) else false
	if floor=="A2" and input.get("playerInsideFinish",false) and not finished_before:
		state.phase="finish_pending"; state.floor="A2"; state.finishRequestIssued=true; return _result(state,Vector2.ZERO,false,false,true)
	if source.phase=="portal_transfer":
		if not source.portalApplied:
			state.guardTargetWaypointId="a1_main_stair"; return _result(state,guard.direction_to(Vector2(1001,214))*174,true,false,false,false,false,float(source.portalRemainingDistance))
		state.portalRemainingDistance=maxf(0,float(source.portalRemainingDistance)-174*ms/1000); var arrived: bool=state.portalRemainingDistance==0
		if arrived: state.phase="running"; state.floor="A2"; state.guardFloor="A2"; state.guardTargetWaypointId="a2_core_east"
		return _result(state,Vector2.ZERO,arrived,false,false,false,arrived,state.portalRemainingDistance)
	var failed_before: bool=bool(source.failureRequestIssued) if input.get("guardContact",false) else false
	if input.get("guardContact",false) and not failed_before:
		state.phase="failure_pending"; state.failureRequestIssued=true; return _result(state,Vector2.ZERO,false,false,false,true,false,_remaining(floor,player,points))
	if floor=="A1" and input.get("playerEnteredMainStair",false):
		state.phase="portal_transfer"; state.floor="A1"; state.guardFloor="A1"; state.guardTargetWaypointId="a1_main_stair"; state.portalApplied=false; state.portalRemainingDistance=_distance("A1",guard,"a1_main_stair",points)
		return _result(state,guard.direction_to(Vector2(1001,214))*174,true,true,false,false,false,state.portalRemainingDistance)
	var guard_node: String=_nearest(floor,guard,points); var player_node: String=_nearest(floor,player,points); var path: Array=_shortest(guard_node,player_node,points); var target: String=path[1] if path.size()>1 else player_node
	state.floor=floor; state.guardFloor=floor; state.guardTargetWaypointId=target; state.finishRequestIssued=finished_before; state.failureRequestIssued=failed_before
	return _result(state,guard.direction_to(vec(points[target]))*174,true,false,false,false,false,_remaining(floor,player,points))
static func resolve_portal(source: Dictionary,accepted: bool) -> Dictionary:
	var state: Dictionary=source.duplicate(true)
	if state.phase!="portal_transfer" or state.portalApplied: return state
	if accepted: state.portalApplied=true; state.floor="A2"
	else: state.phase="running"; state.portalApplied=false; state.portalRemainingDistance=0
	return state
static func resolve_finish(source: Dictionary,accepted: bool) -> Dictionary:
	var state: Dictionary=source.duplicate(true)
	if state.phase!="finish_pending": return state
	state.phase="complete" if accepted else "running"; state.floor="A2"; state.guardFloor="A2"
	if not accepted: state.finishRequestIssued=false
	return state
static func resolve_failure(source: Dictionary,accepted: bool) -> Dictionary:
	var state: Dictionary=source.duplicate(true)
	if state.phase=="failure_pending": state.phase="complete" if accepted else "running"
	return state
static func chase_contact(guard: Vector2,player_bounds: Rect2) -> bool:
	return guard.distance_to(Vector2(clampf(guard.x,player_bounds.position.x,player_bounds.end.x),clampf(guard.y,player_bounds.position.y,player_bounds.end.y)))<=22
