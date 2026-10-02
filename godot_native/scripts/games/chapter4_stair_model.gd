extends RefCounted
## Source-faithful projection graph. Rendering never creates an edge.
const VIEWS = ["south_east", "south_west", "top_oblique"]
static func data() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://data/native/chapter4-native-source.json"))
static func v3(value: Variant) -> Vector3:
	if value is Array: return Vector3(value[0], value[1], value[2])
	return Vector3(value.x, value.y, value.z)
static func initial(level: Dictionary) -> Dictionary:
	var values: Dictionary = {}
	for m in level.mechanisms: values[m.id] = int(m.initialState)
	return {"values":values, "view":"south_east", "node":level.startNodeId}
static func transform_point(level: Dictionary, values: Dictionary, owner: String, point: Vector3, direction: bool = false) -> Vector3:
	if owner == "level": return point
	for m in level.mechanisms:
		if m.id != owner: continue
		var state: int = int(values.get(owner, m.initialState))
		if m.kind == "rotate":
			var pivot: Vector3 = Vector3.ZERO if direction else v3(m.pivot)
			return pivot + (point - pivot).rotated(Vector3.UP, state * PI / 2.0)
		if direction: return point
		var offset: Vector3 = Vector3.ZERO
		offset[{"x":0,"y":1,"z":2}[m.axis]] = float(m.stepSize) * state
		return point + offset
	return point
static func position(level: Dictionary, state: Dictionary, id: String) -> Vector3:
	for n in level.nodes:
		if n.id == id: return transform_point(level, state.values, n.ownerId, v3(n.position))
	return Vector3.ZERO
static func project(point: Vector3, camera: Dictionary, view: String) -> Vector2:
	var origin: Vector3 = v3(camera.views[view].position)
	var forward: Vector3 = (v3(camera.center) - origin).normalized()
	var right: Vector3 = forward.cross(Vector3.UP).normalized()
	var up: Vector3 = right.cross(forward).normalized()
	var relative: Vector3 = point - v3(camera.center)
	return Vector2(240.0 + relative.dot(right) / float(camera.halfWidth) * 240.0, 135.0 - relative.dot(up) / float(camera.halfHeight) * 135.0)
static func edges(level: Dictionary, state: Dictionary, camera: Dictionary, include_invalid: bool=false) -> Array:
	var out: Array = []
	for e in level.physicalEdges: out.append({"a":e.a,"b":e.b,"kind":"physical","id":e.id})
	for e in level.mechanismEdges:
		if int(state.values[e.mechanismId]) == int(e.requiredState): out.append({"a":e.a,"b":e.b,"kind":"mechanism","id":e.id})
	var by_id: Dictionary = {}
	for c in level.connectors: by_id[c.id] = c
	var groups: Dictionary = {}
	for link in level.perspectiveLinks:
		var a: Dictionary = by_id[link.connectorA]
		var b: Dictionary = by_id[link.connectorB]
		if state.view not in a.views or state.view not in b.views or a.linkGroup != b.linkGroup or a.linkGroup != link.linkGroup: continue
		var pa: Vector3 = transform_point(level,state.values,a.ownerId,v3(a.worldPosition))
		var pb: Vector3 = transform_point(level,state.values,b.ownerId,v3(b.worldPosition))
		var sa: Vector2 = project(pa,camera,state.view)
		var sb: Vector2 = project(pb,camera,state.view)
		var distance: float = sa.distance_to(sb)
		if distance > 6.0: continue
		if _occluded(level,state,v3(camera.views[state.view].position),pa) or _occluded(level,state,v3(camera.views[state.view].position),pb): continue
		var ta: Vector3 = transform_point(level,state.values,a.ownerId,v3(a.worldTangent),true)
		var tb: Vector3 = transform_point(level,state.values,b.ownerId,v3(b.worldTangent),true)
		var da: Vector2 = project(pa+ta,camera,state.view)-sa
		var db: Vector2 = project(pb+tb,camera,state.view)-sb
		var valid: bool = da.length()>0.000001 and db.length()>0.000001 and da.normalized().dot(db.normalized()) <= -cos(deg_to_rad(20.0))
		var edge: Dictionary = {"a":a.nodeId,"b":b.nodeId,"kind":"perspective","id":link.id,"distance":distance,"valid":valid}
		if not groups.has(link.linkGroup) or float(groups[link.linkGroup].distance)>distance: groups[link.linkGroup]=edge
	for edge in groups.values():
		if edge.valid or include_invalid: out.append(edge)
	return out
static func _occluded(level: Dictionary,state: Dictionary,origin: Vector3,target: Vector3) -> bool:
	var direction: Vector3=target-origin; var distance: float=direction.length()
	if distance<=0.3: return false
	var end: Vector3=origin+direction.normalized()*(distance-0.3)
	for platform in level.geometry.platforms:
		if platform.walkable: continue
		# Every currently authored occluder is a static back wall. This inverse
		# additionally supports a future mechanism-owned occluder without new edges.
		var from: Vector3=_inverse(level,state.values,platform.ownerId,origin)
		var to: Vector3=_inverse(level,state.values,platform.ownerId,end)
		var half: Vector3=v3(platform.size)/2; var center: Vector3=v3(platform.center)
		var low: Vector3=center-half; var high: Vector3=center+half; var move: Vector3=to-from
		var entry: float=0; var leave: float=1; var miss: bool=false
		for axis in range(3):
			if absf(move[axis])<0.0000001:
				if from[axis]<low[axis] or from[axis]>high[axis]: miss=true; break
				continue
			var a: float=(low[axis]-from[axis])/move[axis]; var b: float=(high[axis]-from[axis])/move[axis]
			entry=maxf(entry,minf(a,b)); leave=minf(leave,maxf(a,b))
			if entry>leave: miss=true; break
		if not miss: return true
	return false
static func _inverse(level: Dictionary,values: Dictionary,owner: String,point: Vector3) -> Vector3:
	if owner=="level": return point
	for m in level.mechanisms:
		if m.id!=owner: continue
		var state: int=int(values.get(owner,m.initialState))
		if m.kind=="rotate": return v3(m.pivot)+(point-v3(m.pivot)).rotated(Vector3.UP,-state*PI/2)
		var offset: Vector3=Vector3.ZERO; offset[{"x":0,"y":1,"z":2}[m.axis]]=float(m.stepSize)*state
		return point-offset
	return point
static func path(level: Dictionary,state: Dictionary,camera: Dictionary,target: String) -> Array:
	var graph: Dictionary = {}
	for n in level.nodes: graph[n.id] = []
	for e in edges(level,state,camera):
		graph[e.a].append(e.b)
		graph[e.b].append(e.a)
	if not graph.has(target): return []
	var queue: Array = [state.node]
	var seen: Dictionary = {state.node:""}
	while not queue.is_empty():
		var node: String = queue.pop_front()
		if node == target:
			var result: Array = []
			while node != state.node:
				result.push_front(node)
				node = seen[node]
			return result
		for next in graph[node]:
			if not seen.has(next):
				seen[next]=node
				queue.append(next)
	return []
static func apply(level: Dictionary,state: Dictionary,camera: Dictionary,action: Dictionary) -> bool:
	match str(action.get("type","")):
		"view":
			if action.get("value","") not in VIEWS: return false
			state.view=action.value
			return true
		"step":
			var delta: int = int(action.get("delta",0))
			if delta not in [-1,1]: return false
			for m in level.mechanisms:
				if m.id == action.get("id",""):
					state.values[m.id] = posmod(int(state.values[m.id])+delta,int(m.stateCount))
					return true
		"walk":
			var route: Array = path(level,state,camera,str(action.get("node","")))
			if route.is_empty(): return false
			state.node=action.node
			return true
	return false
static func validate_result(result: Variant) -> bool:
	if not result is Dictionary or result.get("kind","") != "chapter4_stair_campaign" or not result.get("doorTraversed",false): return false
	var source: Dictionary = data()
	var records: Array = result.get("levels",[])
	if records.size()!=4: return false
	for index in range(4):
		var level: Dictionary = source.levels[index]
		var record: Dictionary = records[index]
		if record.get("id","")!=level.id: return false
		var state: Dictionary = initial(level)
		var actions: Array = record.get("actions",[])
		if actions.is_empty() or actions.size()>4096: return false
		for action in actions:
			if not action is Dictionary or not apply(level,state,source.cameras[level.id],action): return false
		if state.node!=level.exitNodeId: return false
	return true
