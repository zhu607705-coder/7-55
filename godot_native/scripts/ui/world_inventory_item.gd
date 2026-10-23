extends "res://scripts/ui/inventory_item.gd"
## The existing world bag is also an item target. The controller owns recipes.
signal combination_requested(from_id: String,to_id: String)
var can_combine: Callable

func _make_drag_preview()->Control:
	var preview:=Control.new()
	preview.custom_minimum_size=Vector2(44,44);preview.size=Vector2(44,44)
	var art:Control=get_node_or_null("WorldItemArtwork")
	if is_instance_valid(art):
		var copy:Control=art.duplicate()
		copy.position=Vector2(8,8);copy.mouse_filter=Control.MOUSE_FILTER_IGNORE
		preview.add_child(copy)
	return preview

func _can_drop_data(at_position: Vector2,data: Variant) -> bool:
	if disabled or not allow_drag or not is_visible_in_tree() or not Rect2(Vector2.ZERO,size).has_point(at_position): return false
	if not data is Dictionary or data.get("kind")!="inventory_item" or not data.get("item") is String: return false
	var from_id: String=data.item
	return from_id!=item_id and can_combine.is_valid() and can_combine.call(from_id,item_id)

func _drop_data(at_position: Vector2,data: Variant) -> void:
	if _can_drop_data(at_position,data): combination_requested.emit(str(data.item),item_id)
