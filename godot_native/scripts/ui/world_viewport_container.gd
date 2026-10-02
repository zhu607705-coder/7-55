extends SubViewportContainer
## Cross-viewport inventory drops stay on the root viewport; coordinates are
## converted to the fixed source-pixel world without moving story ownership.
var world_surface: Control
func source_position(local: Vector2) -> Vector2:
	if world_surface == null: return Vector2.ZERO
	return local * world_surface.size / Vector2(maxf(size.x,1),maxf(size.y,1))
func _can_drop_data(at_position: Vector2,data: Variant) -> bool:
	if not is_instance_valid(world_surface) or not data is Dictionary or data.get("kind") != "inventory_item": return false
	return world_surface._can_drop_data(source_position(at_position),data)
func _drop_data(at_position: Vector2,data: Variant) -> void:
	if _can_drop_data(at_position,data): world_surface._drop_data(source_position(at_position),data)
