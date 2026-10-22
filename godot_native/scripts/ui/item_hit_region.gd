extends RefCounted
## Invisible source-art geometry. Ancestor scales, pivots, animated growth and
## aspect-cover cropping are inverted from the actual TextureRect transform.
static func texture_point(view: TextureRect, global_point: Vector2) -> Vector2:
	if not is_instance_valid(view) or view.texture==null: return Vector2.INF
	var local:=view.get_global_transform_with_canvas().affine_inverse()*global_point
	var source:=view.texture.get_size()
	var factor:=maxf(view.size.x/source.x,view.size.y/source.y) if view.stretch_mode==TextureRect.STRETCH_KEEP_ASPECT_COVERED else minf(view.size.x/source.x,view.size.y/source.y)
	return (local-(view.size-source*factor)/2.0)/factor
static func contains(point: Vector2, polygons: Array) -> bool:
	for polygon in polygons:
		if Geometry2D.is_point_in_polygon(point,polygon): return true
	return false
static func texture_global_point(view: TextureRect, source_point: Vector2) -> Vector2:
	if not is_instance_valid(view) or view.texture==null: return Vector2.INF
	var source:=view.texture.get_size()
	var factor:=maxf(view.size.x/source.x,view.size.y/source.y) if view.stretch_mode==TextureRect.STRETCH_KEEP_ASPECT_COVERED else minf(view.size.x/source.x,view.size.y/source.y)
	return view.get_global_transform_with_canvas()*((view.size-source*factor)/2.0+source_point*factor)
