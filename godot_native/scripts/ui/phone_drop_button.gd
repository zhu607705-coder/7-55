extends Button
signal item_dropped(item_id: String)
## Optional semantic surface in original artwork pixels. Empty polygons preserve
## existing native-control bounds. Regions are never rendered or item-filtered.
var hit_texture: TextureRect
var hit_polygons: Array=[]
var subtle_hover := false
var focus_anchor_source := Vector2.INF
var _focus_drawn := false
var _hover_lit := false
const HitRegion=preload("res://scripts/ui/item_hit_region.gd")
func _has_point(point: Vector2) -> bool:
	if not Rect2(Vector2.ZERO,size).has_point(point): return false
	if hit_polygons.is_empty(): return true
	return HitRegion.contains(HitRegion.texture_point(hit_texture,get_global_transform_with_canvas()*point),hit_polygons)
func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	return not disabled and _has_point(at_position) and data is Dictionary and data.get("kind")=="inventory_item" and data.get("item") is String
func _drop_data(at_position: Vector2, data: Variant) -> void:
	if _can_drop_data(at_position,data): item_dropped.emit(str(data.item))
func _process(_delta: float) -> void:
	if not is_instance_valid(hit_texture): return
	if has_focus() or _focus_drawn: queue_redraw()
	# A static, neutral material response only under the pointer. Wrong items get
	# exactly the same cue; no pulse, global answer scan or accepted-item oracle.
	var lit:=subtle_hover and is_visible_in_tree() and not disabled and get_viewport().gui_is_dragging() and _has_point(get_local_mouse_position())
	if lit!=_hover_lit:
		_hover_lit=lit
		hit_texture.self_modulate=Color(1.035,1.035,1.035) if lit else Color.WHITE

func _draw() -> void:
	_focus_drawn=has_focus() and focus_anchor_source.is_finite() and not get_viewport().gui_is_dragging()
	if not _focus_drawn: return
	var center:=get_global_transform_with_canvas().affine_inverse()*HitRegion.texture_global_point(hit_texture,focus_anchor_source)
	var pixel:=1.0/maxf(.001,get_global_transform_with_canvas().get_scale().x)
	# Keyboard focus is a tiny static object-anchored diamond, never a region box.
	var diamond:=PackedVector2Array([center+Vector2(0,-4)*pixel,center+Vector2(4,0)*pixel,center+Vector2(0,4)*pixel,center+Vector2(-4,0)*pixel,center+Vector2(0,-4)*pixel])
	draw_polyline(diamond,Color("fff7d7"),2*pixel,true)
