extends RefCounted
## Exposed edges of the complete ground union, never edges between adjacent
## paving pieces. The physical circle stays the map's original radius.
var polygons:Array[PackedVector2Array]=[]
var edges:Array[PackedVector2Array]=[]
var edge_bounds:Array[Rect2]=[]
var radius:=3.0
var source_hash:=0

func configure(source:Array,body_radius:float)->void:
	polygons.assign(source);source_hash=source.hash();radius=body_radius;edges.clear();edge_bounds.clear()
	var segments:Array[PackedVector2Array]=[]
	for poly:PackedVector2Array in polygons:
		for index:int in poly.size():
			var a:=poly[index];var b:=poly[(index+1)%poly.size()]
			if a.distance_squared_to(b)>.000001:segments.append(PackedVector2Array([a,b]))
	for edge:PackedVector2Array in segments:
		var a:=edge[0];var delta:=edge[1]-a;var length_squared:=delta.length_squared()
		var cuts:Array[float]=[0.0,1.0]
		var bounds:=Rect2(a,Vector2.ZERO).expand(edge[1]).grow(.001)
		for other:PackedVector2Array in segments:
			if not bounds.intersects(Rect2(other[0],Vector2.ZERO).expand(other[1]).grow(.001)):continue
			var hit:Variant=Geometry2D.segment_intersects_segment(a,edge[1],other[0],other[1])
			if hit!=null:cuts.append(clampf((Vector2(hit)-a).dot(delta)/length_squared,0,1))
			elif absf(delta.cross(other[0]-a))<.001 and absf(delta.cross(other[1]-a))<.001:
				cuts.append(clampf((other[0]-a).dot(delta)/length_squared,0,1))
				cuts.append(clampf((other[1]-a).dot(delta)/length_squared,0,1))
		cuts.sort()
		var normal:=Vector2(-delta.y,delta.x).normalized()*.0005
		for index:int in range(cuts.size()-1):
			if cuts[index+1]-cuts[index]<.000001:continue
			var midpoint:=a+delta*((cuts[index]+cuts[index+1])*.5)
			if _strict_contains(midpoint+normal)==_strict_contains(midpoint-normal):continue
			var first:=a+delta*cuts[index];var last:=a+delta*cuts[index+1]
			edges.append(PackedVector2Array([first,last]));edge_bounds.append(Rect2(first,Vector2.ZERO).expand(last).grow(radius+.001))

func contains_point(point:Vector2)->bool:
	for poly:PackedVector2Array in polygons:
		if Geometry2D.is_point_in_polygon(point,poly):return true
	return false

func _strict_contains(point:Vector2)->bool:
	# Geometry2D's inclusive edge tolerance is useful for actor contact, but can
	# classify BOTH sides of a narrow oblique edge as inside during compilation.
	for poly:PackedVector2Array in polygons:
		var inside:=false
		for index:int in poly.size():
			var a:=poly[index];var b:=poly[(index+1)%poly.size()]
			if (a.y>point.y)!=(b.y>point.y) and point.x<float(b.x-a.x)*float(point.y-a.y)/float(b.y-a.y)+a.x:inside=not inside
		if inside:return true
	return false

func allows_circle(point:Vector2)->bool:
	if not contains_point(point):return false
	for index:int in edges.size():
		if edge_bounds[index].has_point(point) and point.distance_squared_to(Geometry2D.get_closest_point_to_segment(point,edges[index][0],edges[index][1]))<pow(radius-.00001,2):return false
	return true

func allows_segment(a:Vector2,b:Vector2)->bool:
	if not allows_circle(a) or not allows_circle(b):return false
	var bounds:=Rect2(a,Vector2.ZERO).expand(b).grow(.001)
	for index:int in edges.size():
		if not bounds.intersects(edge_bounds[index]):continue
		var c:=edges[index][0];var d:=edges[index][1]
		if Geometry2D.segment_intersects_segment(a,b,c,d)!=null:return false
		var distance_squared:=minf(minf(a.distance_squared_to(Geometry2D.get_closest_point_to_segment(a,c,d)),b.distance_squared_to(Geometry2D.get_closest_point_to_segment(b,c,d))),minf(c.distance_squared_to(Geometry2D.get_closest_point_to_segment(c,a,b)),d.distance_squared_to(Geometry2D.get_closest_point_to_segment(d,a,b))))
		if distance_squared<pow(radius-.00001,2):return false
	return true
