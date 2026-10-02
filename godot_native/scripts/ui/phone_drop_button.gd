extends Button
signal item_dropped(item_id: String)
func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return not disabled and data is Dictionary and data.get("kind")=="inventory_item" and data.get("item") is String
func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if _can_drop_data(_at_position,data): item_dropped.emit(str(data.item))
