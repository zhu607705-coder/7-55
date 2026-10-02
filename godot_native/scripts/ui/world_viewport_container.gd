extends SubViewportContainer
## Root-viewport input is already container-local. Invert the rendered viewport
## mapping once, then the world's actual canvas/local transform once.
var world_surface: Control
func source_position(local: Vector2) -> Vector2:
	if not is_instance_valid(world_surface) or not Rect2(Vector2.ZERO,size).has_point(local): return Vector2.INF
	var viewport:=world_surface.get_viewport()
	if viewport==null: return Vector2.INF
	var pixel:=local
	if stretch: pixel=local*Vector2(viewport.size)/Vector2(maxf(size.x,1),maxf(size.y,1))
	if not Rect2(Vector2.ZERO,Vector2(viewport.size)).has_point(pixel): return Vector2.INF
	return world_surface.get_global_transform_with_canvas().affine_inverse()*pixel
func _can_drop_data(at_position: Vector2,data: Variant) -> bool:
	if not is_instance_valid(world_surface) or not data is Dictionary or data.get("kind") != "inventory_item": return false
	var point:=source_position(at_position)
	return point.is_finite() and world_surface._can_drop_data(point,data)
func _drop_data(at_position: Vector2,data: Variant) -> void:
	if _can_drop_data(at_position,data): world_surface._drop_data(source_position(at_position),data)
