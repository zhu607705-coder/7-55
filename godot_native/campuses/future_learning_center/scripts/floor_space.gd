extends RefCounted
## A single architectural ground union, shared by feet, path edges and review.
const Body=preload("res://scripts/player_metrics.gd")
const Space=preload("res://scripts/space/spatial_rules.gd")
const Ground=preload("res://scripts/space/polygon_ground.gd")
var data:Dictionary
var ground=Ground.new()
var world_bounds:Rect2
var graph:=AStar2D.new()
var point_ids:Dictionary={}
var invalid_links:Array[String]=[]
const BIN:=256.0
var polygon_bins:Dictionary={}
var edge_bins:Dictionary={}

func configure(definition:Dictionary)->void:
	data=definition
	world_bounds=Rect2(Vector2.ZERO,Vector2(data.world[0],data.world[1]))
	var polygons:Array[PackedVector2Array]=[]
	for region:Dictionary in data.ground:polygons.append(Space.polygon(region.polygon))
	ground.configure(polygons,0.0)
	polygon_bins.clear();edge_bins.clear()
	for i:int in ground.polygons.size():
		var poly:PackedVector2Array=ground.polygons[i];var bounds:=Rect2(poly[0],Vector2.ZERO)
		for p:Vector2 in poly:bounds=bounds.expand(p)
		_bin(polygon_bins,bounds.grow(.01),i)
	for i:int in ground.edges.size():_bin(edge_bins,Rect2(ground.edges[i][0],Vector2.ZERO).expand(ground.edges[i][1]).grow(24),i)
	graph.clear();point_ids.clear();invalid_links.clear()
	for item:Dictionary in data.waypoints:
		var p:=Vector2(item.point[0],item.point[1])-Body.FOOT_CENTER_OFFSET
		if not can_stand(p):continue
		var id:=graph.get_available_point_id();graph.add_point(id,p);point_ids[item.id]=id
	for edge:Array in data.links:
		if not point_ids.has(edge[0]) or not point_ids.has(edge[1]):
			invalid_links.append(str(edge));continue
		var a:int=point_ids[edge[0]];var b:int=point_ids[edge[1]]
		if segment_clear(graph.get_point_position(a),graph.get_point_position(b)):graph.connect_points(a,b)
		else:invalid_links.append(str(edge))

func _bin(target:Dictionary,bounds:Rect2,index:int)->void:
	for y:int in range(floori(bounds.position.y/BIN),floori(bounds.end.y/BIN)+1):
		for x:int in range(floori(bounds.position.x/BIN),floori(bounds.end.x/BIN)+1):
			var key:=Vector2i(x,y)
			if not target.has(key):target[key]=[]
			target[key].append(index)

func _contains(point:Vector2)->bool:
	for index:int in polygon_bins.get(Vector2i(floori(point.x/BIN),floori(point.y/BIN)),[]):
		if Geometry2D.is_point_in_polygon(point,ground.polygons[index]):return true
	return false

func can_stand(anchor:Vector2)->bool:
	if not anchor.is_finite() or not world_bounds.encloses(Body.visual_rect(anchor)):return false
	var body:Rect2=Body.foot_rect(anchor)
	var corners:=PackedVector2Array([body.position,Vector2(body.end.x,body.position.y),body.end,Vector2(body.position.x,body.end.y)])
	for corner:Vector2 in corners:
		if not _contains(corner):return false
	# Corner-only tests miss small holes or a diagonal wall crossing a foot box.
	for index:int in edge_bins.get(Vector2i(floori(body.get_center().x/BIN),floori(body.get_center().y/BIN)),[]):
		var edge:PackedVector2Array=ground.edges[index]
		if not body.grow(.001).intersects(Rect2(edge[0],Vector2.ZERO).expand(edge[1]).grow(.001)):continue
		if body.grow(-.001).has_point(edge[0]) or body.grow(-.001).has_point(edge[1]):return false
		for i:int in 4:
			if Geometry2D.segment_intersects_segment(edge[0],edge[1],corners[i],corners[(i+1)%4])!=null:return false
	return true

func move(anchor:Vector2,motion:Vector2)->Vector2:
	var next:Vector2=Space.sweep_axis(anchor,Vector2(motion.x,0),can_stand,4.0)
	return Space.sweep_axis(next,Vector2(0,motion.y),can_stand,4.0)

func segment_clear(a:Vector2,b:Vector2)->bool:
	var steps:=maxi(1,ceili(a.distance_to(b)/6.0))
	for i:int in range(steps+1):
		if not can_stand(a.lerp(b,float(i)/steps)):return false
	return true

func route(start:Vector2,destination:Vector2)->PackedVector2Array:
	if not can_stand(start) or not can_stand(destination):return PackedVector2Array()
	if segment_clear(start,destination):return PackedVector2Array([destination])
	var from_id:=graph.get_available_point_id();graph.add_point(from_id,start)
	var to_id:=graph.get_available_point_id();graph.add_point(to_id,destination)
	for id:int in graph.get_point_ids():
		if id==from_id or id==to_id:continue
		var p:=graph.get_point_position(id)
		if segment_clear(start,p):graph.connect_points(from_id,id)
		if segment_clear(destination,p):graph.connect_points(to_id,id)
	var result:=graph.get_point_path(from_id,to_id)
	graph.remove_point(from_id);graph.remove_point(to_id)
	if result.size()>0:result.remove_at(0)
	return result

func room_at(foot:Vector2)->Dictionary:
	# Internal acoustic room takes priority over the enclosing lab wing.
	for i:int in range(data.rooms.size()-1,-1,-1):
		var room:Dictionary=data.rooms[i]
		if not Space.rect(room.bounds).has_point(foot):continue
		if room.id=="xlab_box":
			for region:Dictionary in data.ground:
				if region.id=="xlab_box" and Geometry2D.is_point_in_polygon(foot,Space.polygon(region.polygon)):return room
			continue
		for region:Dictionary in data.ground:
			if str(region.id).begins_with(str(room.id)+"_floor_") and Geometry2D.is_point_in_polygon(foot,Space.polygon(region.polygon)):return room
	return {}

func focus_bounds(room:Dictionary)->Rect2:
	if room.is_empty():return world_bounds
	var bounds:Rect2=Space.rect(room.bounds)
	if room.get("group","")=="xlab" and room.id!="xlab_box":
		for other:Dictionary in data.rooms:
			if other.get("group","")=="xlab":bounds=bounds.merge(Space.rect(other.bounds))
	return bounds
