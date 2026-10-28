extends RefCounted
## Adapts existing grid samples to explicit native AStar connections. Every
## connection sweeps the full original circle across the actual ground union.
var graph:=AStar2D.new()
var grid:AStarGrid2D
var built:=false

func invalidate()->void:built=false;graph.clear()
func point_id(cell:Vector2i)->int:
	var local:=cell-grid.region.position
	return local.y*grid.region.size.x+local.x
func build(source:AStarGrid2D,cells:Array,clear_segment:Callable)->void:
	grid=source;graph.clear()
	for cell:Vector2i in cells:graph.add_point(point_id(cell),grid.get_point_position(cell))
	for cell:Vector2i in cells:
		for offset:Vector2i in [Vector2i(1,0),Vector2i(0,1),Vector2i(1,1),Vector2i(-1,1)]:
			var other:=cell+offset
			if not grid.is_in_boundsv(other) or grid.is_point_solid(other):continue
			if offset.x!=0 and offset.y!=0 and (grid.is_point_solid(cell+Vector2i(offset.x,0)) or grid.is_point_solid(cell+Vector2i(0,offset.y))):continue
			if clear_segment.call(grid.get_point_position(cell),grid.get_point_position(other)):graph.connect_points(point_id(cell),point_id(other))
	built=true
func path(a:Vector2i,b:Vector2i)->PackedVector2Array:
	return graph.get_point_path(point_id(a),point_id(b))

static func segment_hits_polygon(a:Vector2,b:Vector2,poly:PackedVector2Array)->bool:
	if Geometry2D.is_point_in_polygon(a,poly) or Geometry2D.is_point_in_polygon(b,poly):return true
	for index:int in poly.size():
		if Geometry2D.segment_intersects_segment(a,b,poly[index],poly[(index+1)%poly.size()])!=null:return true
	return false
