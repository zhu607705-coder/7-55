extends Button
var item_id: String = ""
func _get_drag_data(_at_position: Vector2) -> Variant:
	if item_id.is_empty(): return null
	var label := Label.new()
	label.text = text
	label.modulate = Color("e9deac")
	set_drag_preview(label)
	return {"kind":"inventory_item","item":item_id}
